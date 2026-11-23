package com.limelight.wowtouch;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.opengl.EGL14;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLExt;
import android.opengl.EGLSurface;
import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.os.Handler;
import android.os.HandlerThread;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.Surface;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Streaming Touch, Made in Rappace : le filtre d'image, appliqué par le téléphone (le PC et le jeu n'en savent rien).
 *
 * Sans filtre, le décodeur vidéo écrit directement sur l'écran. Avec un filtre, il écrit dans une texture ; à chaque
 * image, la puce graphique du téléphone la relit à travers un petit programme (anti-bandes, netteté, vibrance,
 * contraste, chaleur, vignette) et l'envoie à l'écran. Si le stream est plus petit que l'écran, une deuxième passe
 * l'agrandit avec la Super Résolution Snapdragon (SGSR de Qualcomm, licence BSD 3 clauses). Tout se passe sur un fil à
 * part. Si quoi que ce soit échoue au démarrage, on renvoie null et l'appli garde l'affichage direct d'origine.
 */
public final class FiltreVideo {
    private static final String TAG = "StreamTouchFiltre";
    private static final String CLE = "touch_filtre";

    /** Les ambiances : {vibrance, saturation, contraste, luminosité, gamma, chaleur, netteté, vignette, anti-bandes}. */
    public enum Ambiance {
        AUCUN("aucun", 0f, 1f, 1f, 0f, 1f, 0f, 0f, 0f, 0f),
        CINEMA("cinema", .3f, 1f, 1.08f, .01f, .95f, .25f, .45f, .22f, 1f),
        ECLATANT("eclatant", .55f, 1.08f, 1.06f, .01f, .96f, .06f, .55f, 0f, 1f),
        NET("net", .5f, 1.08f, 1.06f, .015f, .92f, .05f, 1f, 0f, 1f);

        final String cle;
        final float[] reglages;
        Ambiance(String cle, float... reglages) { this.cle = cle; this.reglages = reglages; }

        public Ambiance suivante() { return values()[(ordinal() + 1) % values().length]; }

        static Ambiance de(String cle) {
            for (Ambiance a : values()) if (a.cle.equals(cle)) return a;
            return AUCUN;
        }
    }

    private static volatile FiltreVideo actif;

    public static Ambiance ambiance(Context c) {
        return Ambiance.de(PreferenceManager.getDefaultSharedPreferences(c).getString(CLE, "aucun"));
    }

    /** Enregistre l'ambiance et l'applique tout de suite si le filtre tourne. Rend false s'il faut relancer le stream. */
    public static boolean choisir(Context c, Ambiance a) {
        PreferenceManager.getDefaultSharedPreferences(c).edit().putString(CLE, a.cle).apply();
        FiltreVideo f = actif;
        if (f == null) return a == Ambiance.AUCUN;
        f.reglages = a.reglages;
        return true;
    }

    /**
     * Démarre le filtre vers l'écran donné, si une ambiance est choisie. Rend null sans ambiance ou en cas d'échec :
     * le décodeur écrit alors directement sur l'écran, comme avant.
     */
    public static FiltreVideo demarrer(Context c, Surface ecran, int largeur, int hauteur, boolean agrandir) {
        Ambiance a = ambiance(c);
        // agrandir : le stream est plus petit que l'écran, la Super Résolution sert même sans ambiance.
        if ((a == Ambiance.AUCUN && !agrandir) || ecran == null || !ecran.isValid() || largeur <= 0 || hauteur <= 0) {
            return null;
        }
        FiltreVideo f = new FiltreVideo(a.reglages, largeur, hauteur);
        if (!f.lancer(ecran)) {
            f.arreter();
            return null;
        }
        actif = f;
        return f;
    }

    /**
     * En cours de stream : prépare le filtre sans l'écran (le décodeur l'occupe encore). Le décodeur bascule ensuite
     * vers entree(), puis brancher() fait prendre l'écran au filtre. Rend null sans ambiance ou en cas d'échec.
     */
    public static FiltreVideo sansEcran(Context c, int largeur, int hauteur) {
        Ambiance a = ambiance(c);
        if (a == Ambiance.AUCUN || largeur <= 0 || hauteur <= 0) return null;
        FiltreVideo f = new FiltreVideo(a.reglages, largeur, hauteur);
        if (!f.lancer(null)) {
            f.arreter();
            return null;
        }
        actif = f;
        return f;
    }

    /** Pourquoi le filtre n'a pas pu démarrer la dernière fois (affiché dans la bannière). */
    public static String derniereErreur() { return erreur; }

    /** « 1920×886 → 2576×1189 » quand la Super Résolution agrandit l'image en ce moment, sinon null. */
    public static String superResolution() {
        FiltreVideo f = actif;
        return f != null ? f.etatSR : null;
    }

    private static volatile String erreur = "?";

    // ------------------------------------------------------------------------------------------------ Le programme

    // Passe 1, à la taille du stream : anti-bandes (dans les zones presque unies comme le brouillard et le ciel, on
    // moyenne avec 4 points pris au hasard à 16-64 px, puis un grain très fin casse les marches), netteté adaptative
    // (façon « contrast adaptive sharpening », coupée dans les zones lissées), puis couleurs et vignette.
    private static final String SOMMETS =
            "attribute vec4 aPos;\n" +
            "attribute vec4 aTex;\n" +
            "uniform mat4 uTexMat;\n" +
            "varying vec2 vUv;\n" +
            "void main() {\n" +
            "  gl_Position = aPos;\n" +
            "  vUv = (uTexMat * aTex).xy;\n" +
            "}\n";

    private static final String PIXELS =
            "#extension GL_OES_EGL_image_external : require\n" +
            "#ifdef GL_FRAGMENT_PRECISION_HIGH\n" +
            "  precision highp float;\n" +
            "#else\n" +
            "  precision mediump float;\n" +
            "#endif\n" +
            "uniform samplerExternalOES uImage;\n" +
            "uniform vec2 uPas;\n" +
            "uniform float uVibrance, uSaturation, uContraste, uLumiere, uGamma, uChaleur, uNettete, uVignette, uLissage;\n" +
            "varying vec2 vUv;\n" +
            "const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);\n" +
            "float hasard(vec2 p) {\n" +
            "  vec3 q = fract(vec3(p.xyx) * 0.1031);\n" +
            "  q += dot(q, q.yzx + 33.33);\n" +
            "  return fract((q.x + q.y) * q.z);\n" +
            "}\n" +
            "void main() {\n" +
            "  vec3 c = texture2D(uImage, vUv).rgb;\n" +
            "  float plat = 0.0;\n" +
            "  if (uLissage > 0.0) {\n" +
            "    float angle = hasard(gl_FragCoord.xy) * 6.2831853;\n" +
            "    vec2 rayon = vec2(cos(angle), sin(angle)) * (16.0 + 48.0 * hasard(gl_FragCoord.yx + vec2(5.0, 3.0)));\n" +
            "    vec2 r1 = rayon * uPas;\n" +
            "    vec2 r2 = vec2(-rayon.y, rayon.x) * uPas;\n" +
            "    vec3 m1 = texture2D(uImage, vUv + r1).rgb;\n" +
            "    vec3 m2 = texture2D(uImage, vUv - r1).rgb;\n" +
            "    vec3 m3 = texture2D(uImage, vUv + r2).rgb;\n" +
            "    vec3 m4 = texture2D(uImage, vUv - r2).rgb;\n" +
            "    vec3 ecart = max(max(abs(m1 - c), abs(m2 - c)), max(abs(m3 - c), abs(m4 - c)));\n" +
            "    plat = (1.0 - smoothstep(2.0 / 255.0, 6.0 / 255.0, max(ecart.r, max(ecart.g, ecart.b)))) * uLissage;\n" +
            "    c = mix(c, (c + m1 + m2 + m3 + m4) * 0.2, plat);\n" +
            "  }\n" +
            "  if (uNettete > 0.0) {\n" +
            "    vec3 n = texture2D(uImage, vUv + vec2(0.0, uPas.y)).rgb;\n" +
            "    vec3 s = texture2D(uImage, vUv - vec2(0.0, uPas.y)).rgb;\n" +
            "    vec3 e = texture2D(uImage, vUv + vec2(uPas.x, 0.0)).rgb;\n" +
            "    vec3 o = texture2D(uImage, vUv - vec2(uPas.x, 0.0)).rgb;\n" +
            "    vec3 mn = min(c, min(min(n, s), min(e, o)));\n" +
            "    vec3 mx = max(c, max(max(n, s), max(e, o)));\n" +
            "    vec3 amp = sqrt(clamp(min(mn, 1.0 - mx) / max(mx, 0.0001), 0.0, 1.0));\n" +
            "    vec3 poids = -amp * (0.125 + 0.075 * uNettete) * uNettete * (1.0 - plat);\n" +
            "    c = clamp((c + (n + s + e + o) * poids) / (1.0 + 4.0 * poids), 0.0, 1.0);\n" +
            "  }\n" +
            "  c = (c - 0.35) * uContraste + 0.35 + uLumiere;\n" +
            "  c = pow(clamp(c, 0.0, 1.0), vec3(uGamma));\n" +
            "  c *= vec3(1.0 + 0.08 * uChaleur, 1.0 + 0.015 * uChaleur, 1.0 - 0.08 * uChaleur);\n" +
            "  float l = dot(c, LUMA);\n" +
            "  c = mix(vec3(l), c, uSaturation);\n" +
            "  float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));\n" +
            "  l = dot(c, LUMA);\n" +
            "  c = mix(vec3(l), c, 1.0 + uVibrance * (1.0 - sat));\n" +
            "  vec2 d = vUv - 0.5;\n" +
            "  c *= 1.0 - uVignette * dot(d, d) * 1.4;\n" +
            "  c += (hasard(gl_FragCoord.xy + vec2(17.0, 41.0)) - 0.5) * (1.5 / 255.0) * uLissage;\n" +
            "  gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);\n" +
            "}\n";

    // Passe 2, à la taille de l'écran (seulement si le stream est plus petit que l'écran) : Snapdragon Game Super
    // Resolution 1 de Qualcomm (licence BSD 3 clauses, texte complet dans assets/wowtouch/licenses), mode RGBA.
    // Seul changement : sans « highp » dans les constructeurs (refusé par les pilotes stricts).
    private static final String SOMMETS_SR =
            "#version 310 es\n" +
            "in vec4 aPos;\n" +
            "in vec4 aTex;\n" +
            "out highp vec2 vTex;\n" +
            "void main() {\n" +
            "  gl_Position = aPos;\n" +
            "  vTex = aTex.xy;\n" +
            "}\n";

    private static final String PIXELS_SR =
            "#version 310 es\n" +
            "// Snapdragon(TM) Game Super Resolution 1, mode RGBA : Copyright (c) 2023-2025, Qualcomm Innovation Center, Inc.\n" +
            "// All rights reserved. SPDX-License-Identifier: BSD-3-Clause (assets/wowtouch/licenses/Snapdragon-GSR-BSD-3.txt)\n" +
            "precision mediump float; precision highp int;\n" +
            "uniform highp vec4 uInfos;\n" +
            "uniform mediump sampler2D uEntree;\n" +
            "uniform float uTranchant;\n" +
            "in highp vec2 vTex;\n" +
            "layout(location = 0) out vec4 sortie;\n" +
            "float fastLanczos2(float x) {\n" +
            "  float wA = x - 4.0;\n" +
            "  float wB = x * wA - wA;\n" +
            "  wA *= wA;\n" +
            "  return wB * wA;\n" +
            "}\n" +
            "vec2 weightY(float dx, float dy, float c, float std) {\n" +
            "  float x = ((dx * dx) + (dy * dy)) * 0.55 + clamp(abs(c) * std, 0.0, 1.0);\n" +
            "  float w = fastLanczos2(x);\n" +
            "  return vec2(w, w * c);\n" +
            "}\n" +
            "void main() {\n" +
            "  vec4 color;\n" +
            "  color.xyz = textureLod(uEntree, vTex, 0.0).xyz;\n" +
            "  highp vec2 imgCoord = vTex * uInfos.zw + vec2(-0.5, 0.5);\n" +
            "  highp vec2 imgCoordPixel = floor(imgCoord);\n" +
            "  highp vec2 coord = imgCoordPixel * uInfos.xy;\n" +
            "  vec2 pl = imgCoord - imgCoordPixel;\n" +
            "  vec4 left = textureGather(uEntree, coord, 1);\n" +
            "  float edgeVote = abs(left.z - left.y) + abs(color.y - left.y) + abs(color.y - left.z);\n" +
            "  if (edgeVote > 8.0 / 255.0) {\n" +
            "    coord.x += uInfos.x;\n" +
            "    vec4 right = textureGather(uEntree, coord + vec2(uInfos.x, 0.0), 1);\n" +
            "    vec4 upDown;\n" +
            "    upDown.xy = textureGather(uEntree, coord + vec2(0.0, -uInfos.y), 1).wz;\n" +
            "    upDown.zw = textureGather(uEntree, coord + vec2(0.0, uInfos.y), 1).yx;\n" +
            "    float mean = (left.y + left.z + right.x + right.w) * 0.25;\n" +
            "    left = left - vec4(mean);\n" +
            "    right = right - vec4(mean);\n" +
            "    upDown = upDown - vec4(mean);\n" +
            "    color.w = color.y - mean;\n" +
            "    float sum = abs(left.x) + abs(left.y) + abs(left.z) + abs(left.w)\n" +
            "      + abs(right.x) + abs(right.y) + abs(right.z) + abs(right.w)\n" +
            "      + abs(upDown.x) + abs(upDown.y) + abs(upDown.z) + abs(upDown.w);\n" +
            "    float std = 2.181818 / sum;\n" +
            "    vec2 aWY = weightY(pl.x, pl.y + 1.0, upDown.x, std);\n" +
            "    aWY += weightY(pl.x - 1.0, pl.y + 1.0, upDown.y, std);\n" +
            "    aWY += weightY(pl.x - 1.0, pl.y - 2.0, upDown.z, std);\n" +
            "    aWY += weightY(pl.x, pl.y - 2.0, upDown.w, std);\n" +
            "    aWY += weightY(pl.x + 1.0, pl.y - 1.0, left.x, std);\n" +
            "    aWY += weightY(pl.x, pl.y - 1.0, left.y, std);\n" +
            "    aWY += weightY(pl.x, pl.y, left.z, std);\n" +
            "    aWY += weightY(pl.x + 1.0, pl.y, left.w, std);\n" +
            "    aWY += weightY(pl.x - 1.0, pl.y - 1.0, right.x, std);\n" +
            "    aWY += weightY(pl.x - 2.0, pl.y - 1.0, right.y, std);\n" +
            "    aWY += weightY(pl.x - 2.0, pl.y, right.z, std);\n" +
            "    aWY += weightY(pl.x - 1.0, pl.y, right.w, std);\n" +
            "    float finalY = aWY.y / aWY.x;\n" +
            "    float maxY = max(max(left.y, left.z), max(right.x, right.w));\n" +
            "    float minY = min(min(left.y, left.z), min(right.x, right.w));\n" +
            "    finalY = clamp(uTranchant * finalY, minY, maxY);\n" +
            "    float deltaY = clamp(finalY - color.w, -23.0 / 255.0, 23.0 / 255.0);\n" +
            "    color.xyz = clamp(color.xyz + deltaY, 0.0, 1.0);\n" +
            "  }\n" +
            "  sortie = vec4(color.xyz, 1.0);\n" +
            "}\n";

    /** Le framebuffer 0 : la surface de l'écran elle-même. */
    private static final int ECRAN = 0;

    private static final float[] CARRE = {-1f, -1f, 0f, 0f, 1f, -1f, 1f, 0f, -1f, 1f, 0f, 1f, 1f, 1f, 1f, 1f};

    // ------------------------------------------------------------------------------------------------ L'état

    private final int largeur, hauteur;
    private volatile float[] reglages;
    private HandlerThread fil;
    private Handler boucle;
    private EGLDisplay affichage = EGL14.EGL_NO_DISPLAY;
    private EGLContext contexte = EGL14.EGL_NO_CONTEXT;
    private EGLSurface fenetre = EGL14.EGL_NO_SURFACE;
    private EGLConfig reglageEgl;
    private SurfaceTexture texture;
    private Surface entree;
    private int programme, idTexture, aPos, aTex, uTexMat, uPas;
    private final int[] uReglages = new int[9];
    // Super Résolution : programme (0 = indisponible), image intermédiaire à la taille du stream.
    private int programmeSR, aPosSR, aTexSR, uInfosSR, uTranchantSR, uEntreeSR, tampon, imageTampon;
    private volatile String etatSR;
    private final float[] matrice = new float[16];
    private FloatBuffer sommets;
    private final AtomicInteger enAttente = new AtomicInteger();
    private boolean dessinPrevu, fini;

    private FiltreVideo(float[] reglages, int largeur, int hauteur) {
        this.reglages = reglages;
        this.largeur = largeur;
        this.hauteur = hauteur;
    }

    /** La surface où le décodeur doit écrire. */
    public Surface entree() { return entree; }

    private boolean lancer(final Surface ecran) {
        fil = new HandlerThread("StreamTouch-filtre", android.os.Process.THREAD_PRIORITY_DISPLAY);
        fil.start();
        boucle = new Handler(fil.getLooper());
        final boolean[] ok = {false};
        final CountDownLatch pret = new CountDownLatch(1);
        boucle.post(() -> {
            try {
                preparer(ecran);
                ok[0] = true;
            } catch (Throwable t) {
                noterErreur(t);
            } finally {
                pret.countDown();
            }
        });
        if (!attendre(pret, 2000)) erreur = "délai dépassé";
        return ok[0];
    }

    /** Fait afficher le filtre à l'écran, une fois que le décodeur a quitté l'écran pour l'entrée du filtre. */
    public boolean brancher(final Surface ecran) {
        Handler h = boucle;
        if (h == null || ecran == null || !ecran.isValid()) return false;
        final boolean[] ok = {false};
        final CountDownLatch pret = new CountDownLatch(1);
        h.post(() -> {
            try {
                prendreEcran(ecran);
                ok[0] = true;
            } catch (Throwable t) {
                noterErreur(t);
            } finally {
                pret.countDown();
            }
        });
        if (!attendre(pret, 2000)) erreur = "délai dépassé (écran)";
        return ok[0];
    }

    private static void noterErreur(Throwable t) {
        Log.w(TAG, "Filtre indisponible, affichage direct", t);
        String m = t.getMessage();
        erreur = m != null ? m : t.getClass().getSimpleName();
    }

    private static String codeEgl() { return " (0x" + Integer.toHexString(EGL14.eglGetError()) + ")"; }

    /** Sur le fil du filtre : quitte la petite surface d'attente pour l'écran. */
    private void prendreEcran(Surface ecran) {
        EGLSurface surEcran = EGL14.eglCreateWindowSurface(affichage, reglageEgl, ecran, new int[]{EGL14.EGL_NONE}, 0);
        if (surEcran == EGL14.EGL_NO_SURFACE) throw new IllegalStateException("EGL : écran pris" + codeEgl());
        if (!EGL14.eglMakeCurrent(affichage, surEcran, surEcran, contexte)) {
            String code = codeEgl();
            EGL14.eglDestroySurface(affichage, surEcran);
            throw new IllegalStateException("EGL : écran refusé" + code);
        }
        EGL14.eglSwapInterval(affichage, 0);
        EGL14.eglDestroySurface(affichage, fenetre);
        fenetre = surEcran;
    }

    /** ecran = null : le filtre démarre sur une petite surface d'attente (pour basculer en cours de stream). */
    private void preparer(Surface ecran) {
        affichage = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
        int[] versionEgl = new int[2];
        if (affichage == EGL14.EGL_NO_DISPLAY || !EGL14.eglInitialize(affichage, versionEgl, 0, versionEgl, 1)) {
            throw new IllegalStateException("EGL : pas d'affichage");
        }
        int typeSurface = ecran != null ? EGL14.EGL_WINDOW_BIT : EGL14.EGL_WINDOW_BIT | EGL14.EGL_PBUFFER_BIT;
        // OpenGL ES 3 d'abord (la Super Résolution en a besoin), sinon ES 2 : couleurs sans Super Résolution.
        boolean es3 = true;
        reglageEgl = configEgl(EGLExt.EGL_OPENGL_ES3_BIT_KHR, typeSurface);
        if (reglageEgl != null) {
            contexte = EGL14.eglCreateContext(affichage, reglageEgl, EGL14.EGL_NO_CONTEXT,
                    new int[]{EGL14.EGL_CONTEXT_CLIENT_VERSION, 3, EGL14.EGL_NONE}, 0);
        }
        if (reglageEgl == null || contexte == EGL14.EGL_NO_CONTEXT) {
            es3 = false;
            reglageEgl = configEgl(EGL14.EGL_OPENGL_ES2_BIT, typeSurface);
            if (reglageEgl == null) throw new IllegalStateException("EGL : pas de configuration" + codeEgl());
            contexte = EGL14.eglCreateContext(affichage, reglageEgl, EGL14.EGL_NO_CONTEXT,
                    new int[]{EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE}, 0);
        }
        if (contexte == EGL14.EGL_NO_CONTEXT) throw new IllegalStateException("EGL : pas de contexte" + codeEgl());
        if (ecran != null) {
            fenetre = EGL14.eglCreateWindowSurface(affichage, reglageEgl, ecran, new int[]{EGL14.EGL_NONE}, 0);
            if (fenetre == EGL14.EGL_NO_SURFACE) throw new IllegalStateException("EGL : pas de surface d'écran" + codeEgl());
        } else {
            fenetre = EGL14.eglCreatePbufferSurface(affichage, reglageEgl,
                    new int[]{EGL14.EGL_WIDTH, 1, EGL14.EGL_HEIGHT, 1, EGL14.EGL_NONE}, 0);
            if (fenetre == EGL14.EGL_NO_SURFACE) throw new IllegalStateException("EGL : pas de surface d'attente" + codeEgl());
        }
        if (!EGL14.eglMakeCurrent(affichage, fenetre, fenetre, contexte)) throw new IllegalStateException("EGL : makeCurrent" + codeEgl());
        // Pas d'attente de l'écran : l'image part dès qu'elle est prête (le plus faible retard possible).
        if (ecran != null) EGL14.eglSwapInterval(affichage, 0);

        programme = programme(SOMMETS, PIXELS);
        aPos = GLES20.glGetAttribLocation(programme, "aPos");
        aTex = GLES20.glGetAttribLocation(programme, "aTex");
        uTexMat = GLES20.glGetUniformLocation(programme, "uTexMat");
        uPas = GLES20.glGetUniformLocation(programme, "uPas");
        String[] noms = {"uVibrance", "uSaturation", "uContraste", "uLumiere", "uGamma", "uChaleur", "uNettete",
                "uVignette", "uLissage"};
        for (int i = 0; i < noms.length; i++) uReglages[i] = GLES20.glGetUniformLocation(programme, noms[i]);
        sommets = ByteBuffer.allocateDirect(CARRE.length * 4).order(ByteOrder.nativeOrder()).asFloatBuffer();
        sommets.put(CARRE).position(0);
        if (es3) preparerSR();

        int[] ids = new int[1];
        GLES20.glGenTextures(1, ids, 0);
        idTexture = ids[0];
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, idTexture);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        verifier("texture");

        texture = new SurfaceTexture(idTexture);
        texture.setDefaultBufferSize(largeur, hauteur);
        texture.setOnFrameAvailableListener(st -> {
            enAttente.incrementAndGet();
            if (!dessinPrevu && !fini) {
                dessinPrevu = true;
                boucle.post(this::dessiner);
            }
        }, boucle);
        entree = new Surface(texture);
    }

    /** Une image (ou plusieurs, si on a pris du retard : on ne garde que la dernière) : filtrer et afficher. */
    private void dessiner() {
        dessinPrevu = false;
        if (fini || texture == null) return;
        try {
            int n = enAttente.getAndSet(0);
            for (int i = 0; i < Math.max(1, n); i++) texture.updateTexImage();
            texture.getTransformMatrix(matrice);
            int[] taille = new int[2];
            EGL14.eglQuerySurface(affichage, fenetre, EGL14.EGL_WIDTH, taille, 0);
            EGL14.eglQuerySurface(affichage, fenetre, EGL14.EGL_HEIGHT, taille, 1);
            int ecranL = taille[0], ecranH = taille[1];
            // Super Résolution seulement si l'écran est vraiment plus grand que le stream.
            boolean sr = programmeSR != 0 && (ecranL > largeur * 1.02f || ecranH > hauteur * 1.02f);
            String etat = sr ? largeur + "×" + hauteur + " → " + ecranL + "×" + ecranH : null;
            if (etat == null ? etatSR != null : !etat.equals(etatSR)) etatSR = etat;

            // Passe 1 : couleurs, anti-bandes, netteté. Vers l'image intermédiaire si on agrandit ensuite.
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, sr ? tampon : ECRAN);
            GLES20.glViewport(0, 0, sr ? largeur : ecranL, sr ? hauteur : ecranH);
            GLES20.glUseProgram(programme);
            GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, idTexture);
            GLES20.glUniformMatrix4fv(uTexMat, 1, false, matrice, 0);
            GLES20.glUniform2f(uPas, 1f / largeur, 1f / hauteur);
            float[] r = reglages;
            for (int i = 0; i < uReglages.length; i++) GLES20.glUniform1f(uReglages[i], r[i]);
            carre(aPos, aTex);
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

            if (sr) {
                // Passe 2 : Super Résolution Snapdragon, de la taille du stream à celle de l'écran.
                GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, ECRAN);
                GLES20.glViewport(0, 0, ecranL, ecranH);
                GLES20.glUseProgram(programmeSR);
                GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, imageTampon);
                GLES20.glUniform1i(uEntreeSR, 0);
                GLES20.glUniform4f(uInfosSR, 1f / largeur, 1f / hauteur, largeur, hauteur);
                GLES20.glUniform1f(uTranchantSR, 2f);
                carre(aPosSR, aTexSR);
                GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
            }
            EGL14.eglSwapBuffers(affichage, fenetre);
        } catch (Throwable t) {
            // Fin du stream en cours (écran parti) : rien à faire, l'arrêt suit.
            Log.w(TAG, "Image non filtrée", t);
        }
    }

    /** Arrête tout (à appeler quand l'écran disparaît). Attend que le fil ait lâché l'écran. */
    public void arreter() {
        if (actif == this) actif = null;
        Handler h = boucle;
        if (h == null) return;
        final CountDownLatch fait = new CountDownLatch(1);
        h.post(() -> {
            fini = true;
            try {
                if (texture != null) {
                    texture.setOnFrameAvailableListener(null);
                    texture.release();
                }
                if (entree != null) entree.release();
                if (affichage != EGL14.EGL_NO_DISPLAY) {
                    EGL14.eglMakeCurrent(affichage, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT);
                    if (fenetre != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(affichage, fenetre);
                    if (contexte != EGL14.EGL_NO_CONTEXT) EGL14.eglDestroyContext(affichage, contexte);
                    EGL14.eglReleaseThread();
                }
            } catch (Throwable t) {
                Log.w(TAG, "Arrêt du filtre", t);
            } finally {
                texture = null;
                entree = null;
                fenetre = EGL14.EGL_NO_SURFACE;
                contexte = EGL14.EGL_NO_CONTEXT;
                fait.countDown();
            }
        });
        attendre(fait, 1000);
        fil.quitSafely();
        boucle = null;
    }

    /** Attend le fil du filtre, au plus ms millisecondes. Rend false si le temps est dépassé ou si on est interrompu. */
    private static boolean attendre(CountDownLatch signal, long ms) {
        try {
            return signal.await(ms, TimeUnit.MILLISECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt(); // l'interruption reste visible pour l'appelant
            return false;
        }
    }

    // ------------------------------------------------------------------------------------------------ Outils GL

    /** Une configuration d'affichage 8 bits par couleur pour ce type de rendu, ou null s'il n'y en a pas. */
    private EGLConfig configEgl(int typeRendu, int typeSurface) {
        int[] demande = {EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8, EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_RENDERABLE_TYPE, typeRendu, EGL14.EGL_SURFACE_TYPE, typeSurface, EGL14.EGL_NONE};
        EGLConfig[] trouvees = new EGLConfig[1];
        int[] combien = new int[1];
        boolean ok = EGL14.eglChooseConfig(affichage, demande, 0, trouvees, 0, 1, combien, 0);
        return ok && combien[0] > 0 ? trouvees[0] : null;
    }

    /** Le carré plein écran pour le programme en cours (positions puis coordonnées d'image). */
    private void carre(int attributPos, int attributTex) {
        sommets.position(0);
        GLES20.glVertexAttribPointer(attributPos, 2, GLES20.GL_FLOAT, false, 16, sommets);
        GLES20.glEnableVertexAttribArray(attributPos);
        sommets.position(2);
        GLES20.glVertexAttribPointer(attributTex, 2, GLES20.GL_FLOAT, false, 16, sommets);
        GLES20.glEnableVertexAttribArray(attributTex);
    }

    /** Super Résolution (OpenGL ES 3.1) et son image intermédiaire. Si le téléphone refuse : agrandissement simple. */
    private void preparerSR() {
        try {
            programmeSR = programme(SOMMETS_SR, PIXELS_SR);
            aPosSR = GLES20.glGetAttribLocation(programmeSR, "aPos");
            aTexSR = GLES20.glGetAttribLocation(programmeSR, "aTex");
            uInfosSR = GLES20.glGetUniformLocation(programmeSR, "uInfos");
            uTranchantSR = GLES20.glGetUniformLocation(programmeSR, "uTranchant");
            uEntreeSR = GLES20.glGetUniformLocation(programmeSR, "uEntree");
            int[] id = new int[1];
            GLES20.glGenTextures(1, id, 0);
            imageTampon = id[0];
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, imageTampon);
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
            GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, largeur, hauteur, 0, GLES20.GL_RGBA,
                    GLES20.GL_UNSIGNED_BYTE, null);
            GLES20.glGenFramebuffers(1, id, 0);
            tampon = id[0];
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, tampon);
            GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0, GLES20.GL_TEXTURE_2D,
                    imageTampon, 0);
            int complet = GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER);
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, ECRAN);
            if (complet != GLES20.GL_FRAMEBUFFER_COMPLETE) throw new IllegalStateException("image intermédiaire " + complet);
            verifier("super résolution");
        } catch (Throwable t) {
            Log.w(TAG, "Super Résolution indisponible, agrandissement simple", t);
            programmeSR = 0;
        }
    }

    private static int programme(String sommets, String pixels) {
        int vs = shader(GLES20.GL_VERTEX_SHADER, sommets), fs = shader(GLES20.GL_FRAGMENT_SHADER, pixels);
        int p = GLES20.glCreateProgram();
        GLES20.glAttachShader(p, vs);
        GLES20.glAttachShader(p, fs);
        GLES20.glLinkProgram(p);
        int[] ok = new int[1];
        GLES20.glGetProgramiv(p, GLES20.GL_LINK_STATUS, ok, 0);
        if (ok[0] == 0) {
            String log = GLES20.glGetProgramInfoLog(p);
            GLES20.glDeleteProgram(p);
            throw new IllegalStateException("Programme : " + log);
        }
        return p;
    }

    private static int shader(int type, String code) {
        int s = GLES20.glCreateShader(type);
        GLES20.glShaderSource(s, code);
        GLES20.glCompileShader(s);
        int[] ok = new int[1];
        GLES20.glGetShaderiv(s, GLES20.GL_COMPILE_STATUS, ok, 0);
        if (ok[0] == 0) {
            String log = GLES20.glGetShaderInfoLog(s);
            GLES20.glDeleteShader(s);
            throw new IllegalStateException("Shader : " + log);
        }
        return s;
    }

    private static void verifier(String etape) {
        int e = GLES20.glGetError();
        if (e != GLES20.GL_NO_ERROR) throw new IllegalStateException(etape + " : erreur GL " + e);
    }
}
