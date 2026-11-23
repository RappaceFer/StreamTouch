package com.limelight.wowtouch;

import android.app.AlertDialog;
import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.DashPathEffect;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RadialGradient;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.SystemClock;
import android.view.DisplayCutout;
import android.view.InputDevice;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;
import android.view.WindowInsets;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import com.limelight.Game;
import com.limelight.R;

import java.util.HashSet;
import java.util.Set;
import java.util.function.IntConsumer;

/**
 * Streaming Touch, Made in Rappace : les commandes tactiles par-dessus le jeu.
 * Deux joysticks (déplacement à gauche, caméra « CAM »), des boutons que l'on place où l'on veut,
 * et tout le reste de l'écran comme une souris. En mode manette, seuls Esc et Clavier restent à l'écran.
 */
public final class EcranTactile extends View implements Doigts.Sortie, ActionTactile.Hote {
    // Les couleurs et la façon de dessiner (or et cuir) sont dans Parure.
    private static final long BANNIERE_MS = 3400, ONDE_MS = 260, ECLAT_MS = 380, ANNEAU_APRES_MS = 120,
            CARTE_MS = 4200, DOUBLE_MS = 400;

    /** Icône et nom de chaque commande, par numéro (Commandes). 7, 8, 10 et 11 : anciens boutons. */
    static final int[] ICONES = {R.drawable.st_ic_x, R.drawable.st_ic_map_trifold, R.drawable.st_ic_backpack,
            R.drawable.st_ic_squares_four, R.drawable.st_ic_crosshair, R.drawable.st_ic_hand_grabbing,
            R.drawable.st_ic_arrow_fat_line_up, R.drawable.st_ic_sword, R.drawable.st_ic_cursor_click,
            R.drawable.st_ic_keyboard, R.drawable.st_ic_magnifying_glass, R.drawable.st_ic_app_window,
            R.drawable.st_ic_gear_six, R.drawable.st_ic_tree_structure, R.drawable.st_ic_stack};
    static final int[] NOMS = {R.string.st_esc, R.string.st_carte, R.string.st_sacs, R.string.st_menu, R.string.st_cible,
            R.string.st_utiliser, R.string.st_sauter, 0, 0, R.string.st_clavier, 0, 0, R.string.st_metiers,
            R.string.st_talents, R.string.st_couche};
    private static final Doigts.Endroit[] ENDROITS = {Doigts.Endroit.ECHAP, Doigts.Endroit.CARTE,
            Doigts.Endroit.SACS, Doigts.Endroit.MENU, Doigts.Endroit.CIBLE, Doigts.Endroit.UTILISER,
            Doigts.Endroit.SAUT, null, null, Doigts.Endroit.CLAVIER, null, null, Doigts.Endroit.METIERS,
            Doigts.Endroit.TALENTS, Doigts.Endroit.COUCHE};
    /** Ce que l'on déplace dans « Déplacer les commandes » quand ce n'est pas un bouton. */
    private static final int RIEN = -100, LE_JOYSTICK = -10, LA_CAMERA = -20;

    private final Game jeu;
    private final MoonlightTouchBridge pc;
    private final Doigts doigts;
    private final Paint pinceau = new Paint(Paint.ANTI_ALIAS_FLAG), plume = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Typeface normal = Typeface.create("sans-serif-medium", Typeface.NORMAL);
    private final Typeface gras = Typeface.create("sans-serif-medium", Typeface.BOLD);
    private final Path trace = new Path();
    private final RectF dessus = new RectF(), cadre = new RectF(), carre = new RectF(), badge = new RectF(),
            badgeFace = new RectF(), pommeau = new RectF(), medaillon = new RectF();
    private final RectF[] boutons = new RectF[Commandes.NOMBRE];
    private final Drawable[] icones = new Drawable[Commandes.NOMBRE];
    private final Drawable plongee, crane, coureur, oeil;
    private final float tolerance;
    private final Runnable verifMaintien;
    private final MenuRond menu;
    private Clavier clavier;
    private Commandes commandes;
    private Commandes.Cadre derniereImage;
    private float dp, margeG, margeH, margeD, margeB;
    // Joystick de déplacement : un appui = Utiliser, deux appuis rapides = course auto.
    private float joyX, joyY, rayon, boutonX, boutonY, joyDepartX, joyDepartY;
    private int doigtJoy = -1;
    private final StickTapGesture gesteJoy = new StickTapGesture();
    private final Runnable appuiJoy = this::utiliserDepuisJoystick;
    // Joystick caméra : glisser = tourner, un appui = cibler, deux appuis rapides = sauter.
    private float camX, camY, camRayon, camBoutonX, camBoutonY, camDepartX, camDepartY, camDernierX, camDernierY;
    private int doigtCam = -1;
    private boolean camEnfonce;
    private final StickTapGesture gesteCam = new StickTapGesture();
    private final Runnable appuiCam = this::ciblerDepuisCamera;
    // État.
    private boolean manette = true, plonge, guide, avaleGeste, edition;
    private TouchKey prochainModif, modifTenu;
    private long dernierEchap = -1000, dernierClavier = -1000;
    private int opacite = 100;
    // Retours visuels : bannière, carte « Course auto », onde d'un clic, éclat d'un clic droit.
    private String banTitre, banAide;
    private Drawable banIcone;
    private boolean banCarte;
    private long banDebut = -BANNIERE_MS, ondeDebut = -ONDE_MS, eclatDebut = -ECLAT_MS;
    private float ondeX, ondeY, eclatX, eclatY;
    private final Set<String> dejaVu = new HashSet<>();
    // Déplacer les commandes.
    private int doigtEdition = -1, objetEdition = RIEN;
    private float editionX, editionY;
    private final RectF terminer = new RectF();

    public EcranTactile(Game jeu, MoonlightTouchBridge pc) {
        super(jeu);
        this.jeu = jeu;
        this.pc = pc;
        dp = getResources().getDisplayMetrics().density;
        tolerance = ViewConfiguration.get(jeu).getScaledTouchSlop();
        doigts = new Doigts(this, tolerance);
        pinceau.setTypeface(normal);
        plume.setTypeface(normal);
        verifMaintien = () -> doigts.avance(SystemClock.uptimeMillis());
        for (int i = 0; i < boutons.length; i++) boutons[i] = new RectF();
        plongee = dessin(R.drawable.st_ic_arrow_fat_line_down);
        crane = dessin(R.drawable.st_ic_skull);
        coureur = dessin(R.drawable.st_ic_person_simple_run);
        oeil = dessin(R.drawable.st_ic_compass);
        appliquerStyles();
        ReglagesPartage.reglagesDOrigine(jeu); // nouvelle installation : les réglages d'origine de StreamTouch
        TouchConfig.getClavierChoix(jeu); // fixe le choix du clavier dès la première partie
        menu = new MenuRond(jeu, this);
        // Le jeu se ferme : on lâche tout et le menu rond disparaît avec lui.
        addOnAttachStateChangeListener(new OnAttachStateChangeListener() {
            @Override public void onViewAttachedToWindow(View v) {}
            @Override public void onViewDetachedFromWindow(View v) {
                annuler();
                menu.fermer();
            }
        });
        setLayoutParams(new FrameLayout.LayoutParams(-1, -1));
        setContentDescription(jeu.getString(R.string.st_description));
        setFocusable(false);
        setVisibility(GONE);
    }

    /** Le nom d'un bouton dans la langue du téléphone. */
    private String nom(int id) { return NOMS[id] != 0 ? jeu.getString(NOMS[id]) : ""; }

    private String[] noms() {
        String[] liste = new String[NOMS.length];
        for (int i = 0; i < liste.length; i++) liste[i] = nom(i);
        return liste;
    }

    private Drawable dessin(int id) { return jeu.getDrawable(id).mutate(); }

    private static float borne(float v, float mini, float maxi) { return Math.max(mini, Math.min(maxi, v)); }

    // ---------------------------------------------------------------- Place des commandes

    /** Le jeu commence (ou s'arrête) : les commandes apparaissent, en mode manette. */
    public void montrer(boolean enJeu) {
        boolean voir = enJeu && TouchConfig.tactileActif(getContext());
        if (voir == (getVisibility() == VISIBLE)) return;
        annuler();
        prochainModif = null;
        guide = false;
        if (voir) {
            dejaVu.clear();
            banDebut = -BANNIERE_MS;
            manette = TouchConfig.demarrageManette(getContext());
            rafraichir();
        } else menu.fermer();
        setVisibility(voir ? VISIBLE : GONE);
    }

    @Override protected void onSizeChanged(int l, int h, int ancienL, int ancienH) {
        annuler();
        rafraichir();
    }

    @Override public WindowInsets onApplyWindowInsets(WindowInsets bords) {
        annuler();
        rafraichir();
        return super.onApplyWindowInsets(bords);
    }

    @Override protected void onConfigurationChanged(Configuration nouvelle) {
        super.onConfigurationChanged(nouvelle);
        annuler();
        rafraichir();
    }

    private Commandes.Cadre image() { return pc.viewport(this); }

    /** Recalcule la place et la taille de tout, avec les réglages du téléphone. */
    private void rafraichir() {
        Context c = getContext();
        dp = getResources().getDisplayMetrics().density;
        opacite = TouchConfig.getControlsOpacity(c);
        margeG = margeH = margeD = margeB = 0;
        WindowInsets bords = getRootWindowInsets();
        if (Build.VERSION.SDK_INT >= 28 && bords != null && bords.getDisplayCutout() != null) {
            DisplayCutout encoche = bords.getDisplayCutout();
            margeG = encoche.getSafeInsetLeft();
            margeH = encoche.getSafeInsetTop();
            margeD = encoche.getSafeInsetRight();
            margeB = encoche.getSafeInsetBottom();
        }
        int largeur = Math.max(1, getWidth()), hauteur = Math.max(1, getHeight());
        derniereImage = image();
        commandes = new Commandes(largeur, hauteur, dp, margeG, margeH, margeD, margeB, derniereImage);
        rayon = commandes.rayon * TouchConfig.getStickScale(c);
        joyX = commandes.joyX;
        joyY = commandes.joyY;
        float px = TouchConfig.getControlX(c, -1), py = TouchConfig.getControlY(c, -1);
        if (px >= 0 && py >= 0) {
            joyX = borne(px * largeur, rayon * 1.2f, largeur - rayon * 1.2f);
            joyY = borne(py * hauteur, rayon * 1.2f, hauteur - rayon * 1.2f);
        }
        boutonX = joyX;
        boutonY = joyY;
        camRayon = commandes.rayon * TouchConfig.getCameraStickScale(c);
        camX = joyX;
        camY = Math.max(camRayon * 1.3f, joyY - rayon * 2.6f);
        px = TouchConfig.getControlX(c, -2);
        py = TouchConfig.getControlY(c, -2);
        if (px >= 0 && py >= 0) {
            camX = px * largeur;
            camY = py * hauteur;
        }
        camBoutonX = camX;
        camBoutonY = camY;
        float echelle = TouchConfig.getButtonScale(c);
        for (int i = 0; i < boutons.length; i++) {
            boutons[i].setEmpty();
            if (!Commandes.existe(i)) continue;
            // En mode manette, seuls Esc et Clavier ; Esc reste même décoché si Clavier l'est aussi (pour revenir).
            boolean sansClavier = !TouchConfig.isControlEnabled(c, Commandes.CLAVIER);
            // Sans Clavier ni Menu, on ne pourrait plus ouvrir le menu : Menu reste alors à l'écran.
            boolean voulu = TouchConfig.isControlEnabled(c, i) || (manette && i == Commandes.ECHAP && sansClavier)
                    || (!manette && i == Commandes.MENU && sansClavier);
            if (!voulu || (manette && i != Commandes.ECHAP && i != Commandes.CLAVIER)) continue;
            Commandes.Cadre place = commandes.places[i];
            if (place == null) {
                // Pas de place prévue : une rangée en haut à gauche, à déplacer ensuite où l'on veut.
                float cote = Math.max(34 * dp, Math.min(48 * dp, hauteur * .085f));
                float gx = margeG + 12 * dp + (i % 5) * cote * 1.08f, gy = margeH + 12 * dp + (i / 5) * cote * 1.12f;
                place = new Commandes.Cadre(gx, gy, gx + cote, gy + cote);
            }
            float w = place.largeur() * echelle, h = place.hauteur() * echelle;
            float x = (place.gauche + place.droite) / 2, y = (place.haut + place.bas) / 2;
            px = TouchConfig.getControlX(c, i);
            py = TouchConfig.getControlY(c, i);
            if (px >= 0 && py >= 0) {
                x = px * largeur;
                y = py * hauteur;
            } else if (i == Commandes.COUCHE) {
                x = joyX + rayon * 1.2f + w * .5f + 8 * dp;
                y = joyY + rayon * .5f;
            }
            x = borne(x, w / 2, largeur - w / 2);
            y = borne(y, h / 2, hauteur - h / 2);
            boutons[i].set(x - w / 2, y - h / 2, x + w / 2, y + h / 2);
        }
        invalidate();
    }

    /** Les icônes choisies dans « Boutons » (sinon celles d'origine). */
    private void appliquerStyles() {
        for (int i = 0; i < icones.length; i++) {
            int choisie = ButtonStyles.iconId(ButtonStyles.icon(getContext(), i));
            icones[i] = dessin(choisie != 0 ? choisie : ICONES[i]);
        }
    }

    private Doigts.Endroit endroit(float x, float y) {
        for (int i = 0; i < boutons.length; i++) {
            if (ENDROITS[i] != null && boutons[i].contains(x, y)) return ENDROITS[i];
        }
        if (!manette && Math.hypot(x - joyX, y - joyY) <= rayon * 1.2f) return Doigts.Endroit.JOYSTICK;
        return Doigts.Endroit.ECRAN;
    }

    // ---------------------------------------------------------------- Toucher

    @Override public boolean onTouchEvent(MotionEvent ev) {
        if (ev.isFromSource(InputDevice.SOURCE_MOUSE)) return false;
        if (edition) return deplacement(ev);
        int geste = ev.getActionMasked(), rang = ev.getActionIndex(), id = ev.getPointerId(rang);
        if (!manette && joystickCamera(ev, geste, rang, id)) {
            invalidate();
            return true;
        }
        // Le guide se ferme au premier toucher, qui n'arrive pas jusqu'au jeu.
        if (guide && geste == MotionEvent.ACTION_DOWN) {
            guide = false;
            avaleGeste = true;
            invalidate();
        }
        if (avaleGeste) {
            if (geste == MotionEvent.ACTION_UP || geste == MotionEvent.ACTION_CANCEL) avaleGeste = false;
            return true;
        }
        long maintenant = SystemClock.uptimeMillis();
        if (geste == MotionEvent.ACTION_DOWN || geste == MotionEvent.ACTION_POINTER_DOWN) {
            Commandes.Cadre img = image();
            // L'image du jeu a changé de taille (bandes noires ou non) : tout se recale.
            if (derniereImage == null || img.largeur() != derniereImage.largeur() || img.hauteur() != derniereImage.hauteur()) {
                rafraichir();
            }
            float x = ev.getX(rang), y = ev.getY(rang);
            Doigts.Endroit ou = endroit(x, y);
            if (ou == Doigts.Endroit.JOYSTICK && doigtJoy == -1) {
                doigtJoy = id;
                joyDepartX = x;
                joyDepartY = y;
                removeCallbacks(appuiJoy);
                if (gesteJoy.down(maintenant)) {
                    touche(Doigts.Touche.COURSE, true);
                    touche(Doigts.Touche.COURSE, false);
                    doigts.basculeCourse();
                }
            }
            doigts.pose(id, ou, x, y, maintenant);
            postDelayed(verifMaintien, Doigts.MAINTIEN_MS);
        } else if (geste == MotionEvent.ACTION_MOVE) {
            int n = ev.getPointerCount();
            for (int i = 0; i < n; i++) doigts.placePaire(ev.getPointerId(i), ev.getX(i), ev.getY(i));
            for (int i = 0; i < n; i++) {
                int p = ev.getPointerId(i);
                float x = ev.getX(i), y = ev.getY(i);
                doigts.bouge(p, x, y, joyX, joyY, rayon);
                if (p != doigtJoy) continue;
                if (Math.hypot(x - joyDepartX, y - joyDepartY) > tolerance) gesteJoy.moved();
                float part = Math.min(1, rayon / Math.max(1, (float) Math.hypot(x - joyX, y - joyY)));
                boutonX = joyX + (x - joyX) * part;
                boutonY = joyY + (y - joyY) * part;
            }
        } else if (geste == MotionEvent.ACTION_UP || geste == MotionEvent.ACTION_POINTER_UP) {
            if (id == doigtJoy) doigts.bouge(id, ev.getX(rang), ev.getY(rang), joyX, joyY, rayon);
            doigts.avance(maintenant);
            doigts.leve(id);
            if (id == doigtJoy) {
                doigtJoy = -1;
                boutonX = joyX;
                boutonY = joyY;
                long attente = gesteJoy.up(maintenant);
                if (attente >= 0) postDelayed(appuiJoy, attente);
            }
        } else if (geste == MotionEvent.ACTION_CANCEL) {
            annuler();
        }
        invalidate();
        return true;
    }

    /**
     * Joystick caméra. Vrai quand le geste est entièrement pour lui (un doigt qui s'y pose ou s'en lève).
     * Le clic droit maintenu (qui tourne la caméra) ne part que quand le doigt glisse.
     */
    private boolean joystickCamera(MotionEvent ev, int geste, int rang, int id) {
        if ((geste == MotionEvent.ACTION_DOWN || geste == MotionEvent.ACTION_POINTER_DOWN) && doigtCam == -1
                && Math.hypot(ev.getX(rang) - camX, ev.getY(rang) - camY) <= camRayon * .85f) {
            doigtCam = id;
            camDepartX = camDernierX = ev.getX(rang);
            camDepartY = camDernierY = ev.getY(rang);
            camEnfonce = false;
            removeCallbacks(appuiCam);
            if (gesteCam.down(SystemClock.uptimeMillis())) pression(TouchKey.KEY_SPACE);
            return true;
        }
        if (doigtCam == -1) return false;
        if (geste == MotionEvent.ACTION_MOVE) {
            int i = ev.findPointerIndex(doigtCam);
            if (i < 0) return false;
            float x = ev.getX(i), y = ev.getY(i);
            if (!camEnfonce && Math.hypot(x - camDepartX, y - camDepartY) > tolerance) {
                gesteCam.moved();
                camera(true);
                camEnfonce = true;
                camDernierX = camDepartX;
                camDernierY = camDepartY;
            }
            if (camEnfonce) {
                tournerCamera(x - camDernierX, y - camDernierY);
                camDernierX = x;
                camDernierY = y;
            }
            float dx = x - camX, dy = y - camY;
            float part = Math.min(1, camRayon * .72f / Math.max(1, (float) Math.hypot(dx, dy)));
            camBoutonX = camX + dx * part;
            camBoutonY = camY + dy * part;
            return false;
        }
        if ((geste == MotionEvent.ACTION_UP || geste == MotionEvent.ACTION_POINTER_UP) && id == doigtCam) {
            lacherCamera();
            long attente = gesteCam.up(SystemClock.uptimeMillis());
            if (attente >= 0) postDelayed(appuiCam, attente);
            return true;
        }
        if (geste == MotionEvent.ACTION_CANCEL) {
            lacherCamera();
            gesteCam.reset();
        }
        return false;
    }

    private void lacherCamera() {
        if (camEnfonce) camera(false);
        camEnfonce = false;
        doigtCam = -1;
        camBoutonX = camX;
        camBoutonY = camY;
    }

    /** Appui bref sur le joystick de déplacement : Utiliser (la touche F). */
    private void utiliserDepuisJoystick() {
        if (manette || edition || getVisibility() != VISIBLE) return;
        touche(Doigts.Touche.UTILISER, true);
        touche(Doigts.Touche.UTILISER, false);
        eclat(joyX, joyY);
    }

    /** Appui bref sur le joystick caméra : cibler l'ennemi le plus proche (Tab). */
    private void ciblerDepuisCamera() {
        if (manette || edition || getVisibility() != VISIBLE) return;
        touche(Doigts.Touche.CIBLE, true);
        touche(Doigts.Touche.CIBLE, false);
        eclat(camX, camY);
    }

    /** Tout lâcher : perte du focus, changement de mode, geste annulé. */
    public void annuler() {
        removeCallbacks(verifMaintien);
        doigts.annule();
        relacherModif();
        doigtJoy = -1;
        if (doigtCam != -1) lacherCamera();
        removeCallbacks(appuiCam);
        gesteCam.reset();
        removeCallbacks(appuiJoy);
        gesteJoy.reset();
        boutonX = joyX;
        boutonY = joyY;
        invalidate();
    }

    @Override public void onWindowFocusChanged(boolean aLeFocus) {
        super.onWindowFocusChanged(aLeFocus);
        if (!aLeFocus) annuler();
    }

    // ---------------------------------------------------------------- Vers le jeu

    private TouchKey codeDe(Doigts.Touche t) {
        switch (t) {
            case AVANCER: return TouchKey.KEY_W;
            case RECULER: return TouchKey.KEY_S;
            case GAUCHE: return TouchKey.KEY_A;
            case DROITE: return TouchKey.KEY_D;
            case SAUT: return plonge ? TouchKey.KEY_X : TouchKey.KEY_SPACE;
            case CIBLE: return TouchKey.KEY_TAB;
            case UTILISER: return TouchKey.KEY_F;
            case CARTE: return TouchKey.KEY_M;
            case COURSE: return TouchKey.KEY_NUMLOCK;
            // Couche 2 : l'addon Streaming Touch relie F12 à la deuxième page de l'arc de sorts.
            case COUCHE: return TouchKey.KEY_F12;
            default: return TouchKey.KEY_ESC;
        }
    }

    @Override public void touche(Doigts.Touche t, boolean bas) {
        switch (t) {
            case SACS: if (!bas) post(this::ouvrirSacs); return;
            case METIERS: if (!bas) post(() -> raccourci("SKILLS")); return;
            case TALENTS: if (!bas) post(() -> raccourci("TALENTS")); return;
            case MENU: if (!bas) post(this::ouvrirMenu); return;
            case CLAVIER: if (!bas) post(this::basculerClavier); return;
            case CADAVRE: if (!bas) post(() -> commandeJeu(WoWMenuShortcuts.command("CORPSE"))); return;
            case ECHAP:
                // Deux appuis rapides sur Esc : mode manette <-> mode tactile. Échap part quand même à chaque appui.
                if (!bas) {
                    long maintenant = SystemClock.uptimeMillis();
                    if (maintenant - dernierEchap < DOUBLE_MS) {
                        dernierEchap = -1000;
                        post(this::basculerMode);
                    } else dernierEchap = maintenant;
                }
                break;
            case COURSE:
                if (!bas) post(this::carteCourse);
                break;
            default:
                break;
        }
        if (bas) pc.injectKeyPress(codeDe(t));
        else pc.injectKeyRelease(codeDe(t));
    }

    /** Pose la souris du PC sous le doigt. Faux si le doigt est hors de l'image du jeu. */
    private boolean pointer(float x, float y) {
        Commandes.Cadre img = image();
        if (!img.contient(x, y)) return false;
        int l = pc.ecranJeu.width, h = pc.ecranJeu.height;
        int gx = (int) ((x - img.gauche) * l / img.largeur()), gy = (int) ((y - img.haut) * h / img.hauteur());
        if (gx < 0 || gy < 0 || gx >= l || gy >= h) return false;
        pc.injectPointerMove(gx, gy);
        return true;
    }

    @Override public void clic(float x, float y) {
        if (!pointer(x, y)) return;
        ondeX = x;
        ondeY = y;
        ondeDebut = SystemClock.uptimeMillis();
        presserModif();
        pc.injectPointerButtonPress(MoonlightTouchBridge.Button.BUTTON_LEFT);
        pc.injectPointerButtonRelease(MoonlightTouchBridge.Button.BUTTON_LEFT);
        relacherModif();
    }

    @Override public void clicDroit(float x, float y) {
        if (!pointer(x, y)) return;
        eclat(x, y);
        presserModif();
        pc.injectPointerButtonPress(MoonlightTouchBridge.Button.BUTTON_RIGHT);
        pc.injectPointerButtonRelease(MoonlightTouchBridge.Button.BUTTON_RIGHT);
        relacherModif();
    }

    @Override public void glisser(float x, float y, boolean bouton) {
        boolean dedans = pointer(x, y);
        if (bouton && dedans) {
            presserModif();
            pc.injectPointerButtonPress(MoonlightTouchBridge.Button.BUTTON_LEFT);
        } else if (!bouton) {
            pc.injectPointerButtonRelease(MoonlightTouchBridge.Button.BUTTON_LEFT);
            relacherModif();
        }
    }

    @Override public void survol(float x, float y) { pointer(x, y); }

    @Override public void molette(float x, float y, int crans) {
        if (!pointer(x, y)) return;
        MoonlightTouchBridge.Button sens = crans > 0 ? MoonlightTouchBridge.Button.BUTTON_SCROLL_UP
                : MoonlightTouchBridge.Button.BUTTON_SCROLL_DOWN;
        for (int i = Math.abs(crans); i > 0; i--) {
            pc.injectPointerButtonPress(sens);
            pc.injectPointerButtonRelease(sens);
        }
    }

    /** Caméra : clic droit maintenu au milieu de l'écran du jeu, puis la souris bouge. */
    private void camera(boolean appuie) {
        if (appuie) {
            pc.injectPointerMove(pc.ecranJeu.width / 2, pc.ecranJeu.height / 2);
            pc.injectPointerButtonPress(MoonlightTouchBridge.Button.BUTTON_RIGHT);
        } else pc.injectPointerButtonRelease(MoonlightTouchBridge.Button.BUTTON_RIGHT);
    }

    private void tournerCamera(float dx, float dy) {
        Commandes.Cadre img = image();
        pc.injectPointerMoveDelta(Math.round(dx * pc.ecranJeu.width / img.largeur() * .65f),
                Math.round(dy * pc.ecranJeu.height / img.hauteur() * .65f));
    }

    private void pression(TouchKey code) {
        pc.injectKeyPress(code);
        pc.injectKeyRelease(code);
    }

    /** Un raccourci standard de WoW (WoWMenuShortcuts) : modificateurs, puis la touche. */
    private void raccourci(String nom) {
        TouchKey[] suite = WoWMenuShortcuts.keys(nom);
        if (suite == null || suite.length == 0) return;
        for (int i = 0; i < suite.length - 1; i++) pc.injectKeyPress(suite[i]);
        pression(suite[suite.length - 1]);
        for (int i = suite.length - 2; i >= 0; i--) pc.injectKeyRelease(suite[i]);
    }

    /** Une commande tapée dans le jeu (ex. viser le cadavre le plus proche). */
    private void commandeJeu(String texte) {
        if (texte == null) return;
        annuler();
        prochainModif = null;
        pc.injectSlashCommand(texte);
    }

    private void ouvrirSacs() {
        // Un simple raccourci : les doigts déjà posés (déplacement) continuent.
        if (clavier != null) clavier.hide();
        pression(TouchKey.KEY_B);
    }

    // ---------------------------------------------------------------- Maj, Ctrl, Alt pour le prochain appui

    private String nomModif(TouchKey t) {
        return t == TouchKey.KEY_SHIFT_L ? jeu.getString(R.string.st_maj) : t == TouchKey.KEY_CTRL_L ? "Ctrl" : "Alt";
    }

    private void armer(TouchKey t) {
        prochainModif = t;
        banniere(icones[Commandes.MENU], jeu.getString(R.string.st_prochain, nomModif(t)), jeu.getString(R.string.st_prochain_aide));
    }

    private void presserModif() {
        if (prochainModif == null) return;
        modifTenu = prochainModif;
        prochainModif = null;
        pc.injectKeyPress(modifTenu);
        invalidate();
    }

    private void relacherModif() {
        if (modifTenu == null) return;
        pc.injectKeyRelease(modifTenu);
        modifTenu = null;
    }

    // ---------------------------------------------------------------- Menu, modes, clavier

    private void ouvrirMenu() {
        if (jeu.isFinishing() || !jeu.hasWindowFocus()) return;
        annuler();
        guide = false;
        if (!menu.ouvert()) menu.ouvrir();
    }

    private void basculerMode() {
        manette = !manette;
        annuler();
        rafraichir();
    }

    private void basculerClavier() {
        // Deux appuis rapides sur Clavier : mode manette <-> mode tactile.
        long maintenant = SystemClock.uptimeMillis();
        if (maintenant - dernierClavier < DOUBLE_MS) {
            dernierClavier = -1000;
            basculerMode();
        } else dernierClavier = maintenant;
        if (clavier == null) clavier = TouchConfig.clavierSuisse(jeu)
                ? new PcKeyboardOverlay(jeu, pc, (FrameLayout) getParent())
                : new ClavierTelephone(jeu, pc, (FrameLayout) getParent());
        clavier.toggle();
    }

    @Override public void executer(ActionTactile action) {
        // Le menu vient de se fermer : laisser au jeu le temps de reprendre la main.
        postDelayed(() -> agir(action), 180);
    }

    @Override public boolean estActive(ActionTactile action) {
        switch (action) {
            case MODE_MANETTE: return manette;
            case COURSE_AUTO: return doigts.enCourse();
            case PLONGER: return plonge;
            case MAJ: return prochainModif == TouchKey.KEY_SHIFT_L;
            case CTRL: return prochainModif == TouchKey.KEY_CTRL_L;
            case ALT: return prochainModif == TouchKey.KEY_ALT_L;
            case FILTRE: return FiltreVideo.ambiance(jeu) != FiltreVideo.Ambiance.AUCUN;
            default: return false;
        }
    }

    private void agir(ActionTactile action) {
        switch (action) {
            case MODE_MANETTE:
                // Le menu bascule : manette <-> tactile.
                prochainModif = null;
                manette = !manette;
                annuler();
                rafraichir();
                break;
            case BOUTONS: post(this::stylesBoutons); break;
            case DEPLACER: commencerDeplacement(); break;
            case REGLAGES: post(this::reglages); break;
            case COURSE_AUTO:
                raccourci("AUTO_RUN");
                doigts.basculeCourse();
                break;
            case PLONGER: plonge = !plonge; break;
            case MAJ: armer(TouchKey.KEY_SHIFT_L); break;
            case CTRL: armer(TouchKey.KEY_CTRL_L); break;
            case ALT: armer(TouchKey.KEY_ALT_L); break;
            case GUIDE:
                annuler();
                banDebut = -BANNIERE_MS;
                guide = true;
                break;
            case FILTRE: changerFiltre(); break;
            case A_PROPOS: post(this::aPropos); break;
            case CLAVIER: basculerClavier(); break;
        }
        invalidate();
    }

    /**
     * Next picture mood (Off → Cinema → Vivid → Sharp → Off), applied live: if the filter is not running yet, the
     * game switches it on mid-stream. When it cannot, the banner says why.
     */
    private void changerFiltre() {
        FiltreVideo.Ambiance a = FiltreVideo.ambiance(jeu).suivante();
        String aide = jeu.getString(R.string.st_a_filtre_aide);
        String sr = FiltreVideo.superResolution();
        if (sr != null) aide = jeu.getString(R.string.st_f_sr, sr);
        if (!FiltreVideo.choisir(jeu, a)) {
            int raison = jeu.allumerFiltre();
            if (raison == R.string.st_f_echec) {
                aide = jeu.getString(raison) + " : " + FiltreVideo.derniereErreur();
            } else if (raison != 0) {
                aide = jeu.getString(raison);
            }
        }
        int nom;
        switch (a) {
            case CINEMA: nom = R.string.st_f_cinema; break;
            case ECLATANT: nom = R.string.st_f_eclatant; break;
            case NET: nom = R.string.st_f_net; break;
            default: nom = R.string.st_f_aucun; break;
        }
        banniere(dessin(R.drawable.st_ic_palette), jeu.getString(R.string.st_f_titre, jeu.getString(nom)), aide);
    }

    private void stylesBoutons() {
        if (jeu.isFinishing()) return;
        new ButtonStyleDialog(jeu, noms(), ICONES, () -> {
            appliquerStyles();
            rafraichir();
        }).show();
    }

    private void aPropos() {
        if (jeu.isFinishing()) return;
        String version = "";
        try {
            version = jeu.getPackageManager().getPackageInfo(jeu.getPackageName(), 0).versionName;
        } catch (Exception ignore) {
            // Pas grave : on affiche sans numéro.
        }
        Parure.habiller(new AlertDialog.Builder(jeu).setTitle(jeu.getString(R.string.st_ap_titre))
                .setMessage(jeu.getString(R.string.st_ap_texte)
                        + (version.isEmpty() ? "" : "\n\n" + jeu.getString(R.string.st_ap_version, version)))
                .setPositiveButton(jeu.getString(R.string.st_fermer), null).show(), dp);
    }

    // ---------------------------------------------------------------- Réglages

    private void curseur(LinearLayout liste, String nom, int mini, int maxi, int valeur, IntConsumer garder) {
        TextView titre = new TextView(jeu);
        titre.setText(nom + " : " + valeur + " %");
        titre.setTextColor(Parure.CREME);
        titre.setTextSize(13);
        liste.addView(titre);
        SeekBar barre = new SeekBar(jeu);
        barre.setMax(maxi - mini);
        barre.setProgress(valeur - mini);
        Parure.habiller(barre);
        liste.addView(barre, new LinearLayout.LayoutParams(-1, Math.round(35 * dp)));
        barre.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onStartTrackingTouch(SeekBar b) {}
            @Override public void onStopTrackingTouch(SeekBar b) {}
            @Override public void onProgressChanged(SeekBar b, int pas, boolean parLeDoigt) {
                if (!parLeDoigt) return;
                int v = mini + pas;
                titre.setText(nom + " : " + v + " %");
                garder.accept(v);
                rafraichir();
                if (clavier != null) clavier.refresh();
            }
        });
    }

    private void bouton(LinearLayout liste, String nom, Runnable quand) {
        Button b = new Button(jeu);
        b.setText(nom);
        Parure.habiller(b, dp);
        b.setOnClickListener(v -> quand.run());
        LinearLayout.LayoutParams place = new LinearLayout.LayoutParams(-1, Math.round(46 * dp));
        place.topMargin = Math.round(6 * dp);
        liste.addView(b, place);
    }

    private void reglages() {
        if (jeu.isFinishing()) return;
        Context c = getContext();
        LinearLayout liste = new LinearLayout(jeu);
        liste.setOrientation(LinearLayout.VERTICAL);
        int cote = Math.round(18 * dp), bord = Math.round(8 * dp);
        liste.setPadding(cote, bord, cote, bord);
        curseur(liste, jeu.getString(R.string.st_r_op_clavier), 0, 100, TouchConfig.getKeyboardOpacity(c), v -> TouchConfig.setKeyboardOpacity(c, v));
        curseur(liste, jeu.getString(R.string.st_r_taille_clavier), 65, 140, Math.round(TouchConfig.getKeyboardScale(c) * 100),
                v -> TouchConfig.setKeyboardScale(c, v / 100f));
        curseur(liste, jeu.getString(R.string.st_r_taille_joy), 50, 200, Math.round(TouchConfig.getStickScale(c) * 100),
                v -> TouchConfig.setStickScale(c, v / 100f));
        curseur(liste, jeu.getString(R.string.st_r_taille_cam), 50, 200, Math.round(TouchConfig.getCameraStickScale(c) * 100),
                v -> TouchConfig.setCameraStickScale(c, v / 100f));
        curseur(liste, jeu.getString(R.string.st_r_op_joy), 0, 100, TouchConfig.getMoveStickOpacity(c),
                v -> TouchConfig.setMoveStickOpacity(c, v));
        curseur(liste, jeu.getString(R.string.st_r_op_cam), 0, 100, TouchConfig.getCameraStickOpacity(c),
                v -> TouchConfig.setCameraStickOpacity(c, v));
        curseur(liste, jeu.getString(R.string.st_r_op_boutons), 0, 100, TouchConfig.getButtonOpacity(c), v -> TouchConfig.setButtonOpacity(c, v));
        curseur(liste, jeu.getString(R.string.st_r_taille_boutons), 70, 150, Math.round(TouchConfig.getButtonScale(c) * 100),
                v -> TouchConfig.setButtonScale(c, v / 100f));
        TextView rubriqueDemarrage = new TextView(jeu);
        rubriqueDemarrage.setText(jeu.getString(R.string.st_r_demarrage));
        rubriqueDemarrage.setPadding(0, Math.round(12 * dp), 0, Math.round(4 * dp));
        Parure.rubrique(rubriqueDemarrage, dp);
        liste.addView(rubriqueDemarrage);
        android.widget.RadioGroup demarrage = new android.widget.RadioGroup(jeu);
        int[] nomsDemarrage = {R.string.st_r_dem_tactile, R.string.st_r_dem_manette};
        for (int k = 0; k < 2; k++) {
            android.widget.RadioButton option = new android.widget.RadioButton(jeu);
            option.setId(View.generateViewId());
            option.setText(jeu.getString(nomsDemarrage[k]));
            option.setTextColor(Parure.CREME);
            option.setButtonTintList(android.content.res.ColorStateList.valueOf(Parure.OR));
            final boolean manetteDabord = k == 1;
            option.setOnCheckedChangeListener((v, coche) -> { if (coche) TouchConfig.setDemarrageManette(c, manetteDabord); });
            demarrage.addView(option);
            if (manetteDabord == TouchConfig.demarrageManette(c)) option.setChecked(true);
        }
        liste.addView(demarrage);
        TextView rubriqueClavier = new TextView(jeu);
        rubriqueClavier.setText(jeu.getString(R.string.st_r_clavier));
        rubriqueClavier.setPadding(0, Math.round(12 * dp), 0, Math.round(4 * dp));
        Parure.rubrique(rubriqueClavier, dp);
        liste.addView(rubriqueClavier);
        android.widget.RadioGroup claviers = new android.widget.RadioGroup(jeu);
        String[] nomsClaviers = {jeu.getString(R.string.st_r_clavier_auto),
                jeu.getString(R.string.st_r_clavier_suisse),
                jeu.getString(R.string.st_r_clavier_tel)};
        int actuel = TouchConfig.getClavierChoix(c);
        for (int k = 0; k < nomsClaviers.length; k++) {
            android.widget.RadioButton option = new android.widget.RadioButton(jeu);
            option.setId(View.generateViewId());
            option.setText(nomsClaviers[k]);
            option.setTextColor(Parure.CREME);
            option.setButtonTintList(android.content.res.ColorStateList.valueOf(Parure.OR));
            final int valeur = k;
            option.setOnCheckedChangeListener((v, coche) -> {
                if (!coche || TouchConfig.getClavierChoix(c) == valeur) return;
                TouchConfig.setClavierChoix(c, valeur);
                // Le prochain appui sur Clavier ouvrira le nouveau clavier.
                if (clavier != null) clavier.hide();
                clavier = null;
            });
            claviers.addView(option);
            if (k == actuel) option.setChecked(true);
        }
        liste.addView(claviers);
        TextView titre = new TextView(jeu);
        titre.setText(jeu.getString(R.string.st_r_boutons));
        Parure.rubrique(titre, dp);
        titre.setPadding(0, Math.round(12 * dp), 0, Math.round(4 * dp));
        liste.addView(titre);
        for (int i = 0; i < Commandes.NOMBRE; i++) {
            if (!Commandes.existe(i)) continue;
            final int numero = i;
            CheckBox caseACocher = new CheckBox(jeu);
            String aide = i == Commandes.CIBLE ? jeu.getString(R.string.st_r_aide_cible)
                    : i == Commandes.UTILISER ? jeu.getString(R.string.st_r_aide_utiliser)
                    : i == Commandes.COUCHE ? jeu.getString(R.string.st_r_aide_couche)
                    : i == Commandes.CLAVIER ? jeu.getString(R.string.st_r_aide_clavier) : "";
            caseACocher.setText(nom(i) + aide);
            caseACocher.setChecked(TouchConfig.isControlEnabled(c, i));
            caseACocher.setOnCheckedChangeListener((v, coche) -> {
                TouchConfig.setControlEnabled(c, numero, coche);
                rafraichir();
            });
            liste.addView(caseACocher);
        }
        ScrollView defile = new ScrollView(jeu);
        defile.addView(liste);
        AlertDialog fenetre = new AlertDialog.Builder(jeu).setTitle(jeu.getString(R.string.st_r_titre))
                .setView(defile).setPositiveButton(jeu.getString(R.string.st_fermer), null).create();
        bouton(liste, jeu.getString(R.string.st_r_deplacer), () -> {
            fenetre.dismiss();
            commencerDeplacement();
        });
        bouton(liste, jeu.getString(R.string.st_r_styles), () -> {
            fenetre.dismiss();
            stylesBoutons();
        });
        bouton(liste, jeu.getString(R.string.st_r_places), () -> Parure.habiller(new AlertDialog.Builder(jeu).setTitle(jeu.getString(R.string.st_r_places_titre))
                .setMessage(jeu.getString(R.string.st_r_places_texte))
                .setPositiveButton(jeu.getString(R.string.st_oui), (d, w) -> {
                    TouchConfig.resetControlPositions(c);
                    rafraichir();
                })
                .setNegativeButton(jeu.getString(R.string.st_annuler), null).show(), dp));
        bouton(liste, jeu.getString(R.string.st_r_exporter), () -> ReglagesPartage.exporter(jeu));
        fenetre.show();
        Parure.habiller(fenetre, dp);
        if (fenetre.getWindow() != null) fenetre.getWindow().setLayout(Math.min(getWidth(), Math.round(430 * dp)), -2);
    }

    // ---------------------------------------------------------------- Déplacer les commandes

    private void commencerDeplacement() {
        annuler();
        if (clavier != null) clavier.hide();
        manette = false;
        edition = true;
        doigtEdition = -1;
        objetEdition = RIEN;
        rafraichir();
        Toast.makeText(jeu, jeu.getString(R.string.st_deplacer_toast), Toast.LENGTH_LONG).show();
    }

    /** Pendant « Déplacer les commandes », rien n'arrive au jeu. */
    private boolean deplacement(MotionEvent ev) {
        int geste = ev.getActionMasked(), rang = ev.getActionIndex(), id = ev.getPointerId(rang);
        if (geste == MotionEvent.ACTION_DOWN || geste == MotionEvent.ACTION_POINTER_DOWN) {
            if (doigtEdition != -1) return true;
            float x = ev.getX(rang), y = ev.getY(rang);
            if (terminer.contains(x, y)) {
                edition = false;
                doigtEdition = -1;
                objetEdition = RIEN;
                Toast.makeText(jeu, jeu.getString(R.string.st_enregistre), Toast.LENGTH_SHORT).show();
                rafraichir();
                return true;
            }
            objetEdition = RIEN;
            if (Math.hypot(x - camX, y - camY) < camRayon * .9f) objetEdition = LA_CAMERA;
            else if (Math.hypot(x - joyX, y - joyY) < rayon * 1.35f) objetEdition = LE_JOYSTICK;
            else {
                for (int i = boutons.length - 1; i >= 0; i--) {
                    if (!boutons[i].isEmpty() && boutons[i].contains(x, y)) {
                        objetEdition = i;
                        break;
                    }
                }
            }
            if (objetEdition != RIEN) {
                doigtEdition = id;
                editionX = x;
                editionY = y;
            }
            return true;
        }
        if (geste == MotionEvent.ACTION_MOVE) {
            int i = doigtEdition == -1 ? -1 : ev.findPointerIndex(doigtEdition);
            if (i < 0) return true;
            float x = ev.getX(i), y = ev.getY(i), dx = x - editionX, dy = y - editionY;
            editionX = x;
            editionY = y;
            if (objetEdition == LA_CAMERA) {
                camX = borne(camX + dx, camRayon, getWidth() - camRayon);
                camY = borne(camY + dy, camRayon, getHeight() - camRayon);
                camBoutonX = camX;
                camBoutonY = camY;
            } else if (objetEdition == LE_JOYSTICK) {
                joyX = borne(joyX + dx, rayon * 1.2f, getWidth() - rayon * 1.2f);
                joyY = borne(joyY + dy, rayon * 1.2f, getHeight() - rayon * 1.2f);
                boutonX = joyX;
                boutonY = joyY;
            } else if (objetEdition >= 0) {
                RectF r = boutons[objetEdition];
                float cx = borne(r.centerX() + dx, r.width() / 2, getWidth() - r.width() / 2);
                float cy = borne(r.centerY() + dy, r.height() / 2, getHeight() - r.height() / 2);
                r.offsetTo(cx - r.width() / 2, cy - r.height() / 2);
            }
            invalidate();
            return true;
        }
        boolean fini = geste == MotionEvent.ACTION_CANCEL
                || ((geste == MotionEvent.ACTION_UP || geste == MotionEvent.ACTION_POINTER_UP) && id == doigtEdition);
        if (fini) {
            float l = Math.max(1, getWidth()), h = Math.max(1, getHeight());
            Context c = getContext();
            if (objetEdition == LA_CAMERA) TouchConfig.setControlPosition(c, -2, camX / l, camY / h);
            else if (objetEdition == LE_JOYSTICK) TouchConfig.setControlPosition(c, -1, joyX / l, joyY / h);
            else if (objetEdition >= 0) {
                RectF r = boutons[objetEdition];
                TouchConfig.setControlPosition(c, objetEdition, r.centerX() / l, r.centerY() / h);
            }
            doigtEdition = -1;
            objetEdition = RIEN;
        }
        return true;
    }

    // ---------------------------------------------------------------- Dessin (parure or et cuir, voir Parure)

    /** Un réglage d'opacité (0 à 100) combiné à l'opacité générale des commandes, en alpha 0 à 255. */
    private int alpha(int reglage) { return reglage * opacite * 255 / 10000; }

    @Override protected void onDraw(Canvas toile) {
        if (commandes == null) return;
        long maintenant = SystemClock.uptimeMillis();
        doigts.avance(maintenant);
        boolean anime = false;
        int l = getWidth(), h = getHeight();
        Context c = getContext();
        if (!manette) {
            int calque = toile.saveLayerAlpha(0, 0, l, h, alpha(TouchConfig.getMoveStickOpacity(c)));
            dessinerJoystick(toile);
            toile.restoreToCount(calque);
            calque = toile.saveLayerAlpha(0, 0, l, h, alpha(TouchConfig.getCameraStickOpacity(c)));
            dessinerCamera(toile);
            toile.restoreToCount(calque);
        }
        int calque = toile.saveLayerAlpha(0, 0, l, h, alpha(TouchConfig.getButtonOpacity(c)));
        for (int i = 0; i < boutons.length; i++) if (!boutons[i].isEmpty()) dessinerBouton(toile, i);
        toile.restoreToCount(calque);
        Doigts.Maintien maintien = doigts.maintienEnCours(maintenant);
        if (maintien != null) {
            // Un doigt immobile n'envoie rien : on redessine nous-mêmes pour remplir l'anneau.
            anime = true;
            if (maintien.avance * Doigts.MAINTIEN_MS >= ANNEAU_APRES_MS) dessinerAnneau(toile, maintien);
        }
        if (maintenant - eclatDebut < ECLAT_MS) {
            // Clic droit ou appui sur un joystick : une braise qui s'éteint.
            float t = (maintenant - eclatDebut) / (float) ECLAT_MS, r = (28 + 26 * t) * dp;
            pinceau.setShader(new RadialGradient(eclatX, eclatY, r, new int[]{0xC0FFD27A, 0x80FFB23A, 0x00FFB23A},
                    new float[]{0f, .45f, 1f}, Shader.TileMode.CLAMP));
            pinceau.setStyle(Paint.Style.FILL);
            pinceau.setAlpha((int) (255 * (1 - t)));
            toile.drawCircle(eclatX, eclatY, r, pinceau);
            pinceau.setShader(null);
            anime = true;
        }
        if (maintenant - ondeDebut < ONDE_MS) {
            // Clic gauche : un petit anneau d'or qui s'ouvre.
            float t = (maintenant - ondeDebut) / (float) ONDE_MS;
            contour(2.5f * dp, Parure.OR_CLAIR);
            pinceau.setAlpha((int) (230 * (1 - t)));
            toile.drawCircle(ondeX, ondeY, (6 + 20 * t) * dp, pinceau);
            anime = true;
        }
        pinceau.setAlpha(255);
        long age = maintenant - banDebut;
        if (age < (banCarte ? CARTE_MS : BANNIERE_MS)) {
            if (banCarte) dessinerCarteCourse(toile, age);
            else dessinerBanniere(toile, age);
            anime = true;
        }
        if (guide) dessinerGuide(toile);
        if (edition) dessinerEdition(toile);
        if (anime) postInvalidateOnAnimation();
    }

    private void contour(float epaisseur, int couleur) {
        pinceau.setShader(null);
        pinceau.setPathEffect(null);
        pinceau.setStyle(Paint.Style.STROKE);
        pinceau.setStrokeWidth(epaisseur);
        pinceau.setColor(couleur);
    }

    private void plein(int couleur) {
        pinceau.setShader(null);
        pinceau.setPathEffect(null);
        pinceau.setStyle(Paint.Style.FILL);
        pinceau.setColor(couleur);
    }

    /** L'anneau d'un maintien : autour du doigt, ou autour du bouton Cible. Il se remplit d'or. */
    private void dessinerAnneau(Canvas toile, Doigts.Maintien m) {
        RectF cible = boutons[Commandes.CIBLE];
        boolean surCible = m.endroit == Doigts.Endroit.CIBLE && !cible.isEmpty();
        float x = surCible ? cible.centerX() : m.x, y = surCible ? cible.centerY() : m.y;
        float r = surCible ? cible.width() * .64f : 34 * dp;
        Paint.Cap bout = pinceau.getStrokeCap();
        contour(8 * dp, 0xB0120A05);
        toile.drawCircle(x, y, r, pinceau);
        contour(1 * dp, 0x80AE7A26);
        toile.drawCircle(x, y, r + 3.5f * dp, pinceau);
        toile.drawCircle(x, y, r - 3.5f * dp, pinceau);
        contour(4.5f * dp, Parure.OR);
        pinceau.setStrokeCap(Paint.Cap.ROUND);
        pinceau.setShader(new LinearGradient(0, y - r, 0, y + r, Parure.OR_CLAIR, Parure.OR_MOYEN, Shader.TileMode.CLAMP));
        cadre.set(x - r, y - r, x + r, y + r);
        toile.drawArc(cadre, -90, 360 * m.avance, false, pinceau);
        pinceau.setShader(null);
        pinceau.setStrokeCap(bout);
        // Une braise au bout de l'arc.
        double a = Math.toRadians(-90 + 360 * m.avance);
        float bx = x + (float) Math.cos(a) * r, by = y + (float) Math.sin(a) * r;
        pinceau.setShader(new RadialGradient(bx, by, 7 * dp, 0xFFFFE6A0, 0x00FFB23A, Shader.TileMode.CLAMP));
        pinceau.setStyle(Paint.Style.FILL);
        toile.drawCircle(bx, by, 7 * dp, pinceau);
        pinceau.setShader(null);
    }

    private boolean allume(int id) {
        return (id == Commandes.MENU && prochainModif != null) || (id == Commandes.SAUT && plonge);
    }

    private void dessinerBouton(Canvas toile, int id) {
        RectF r = boutons[id];
        Context c = getContext();
        int forme = ButtonStyles.shape(c, id);
        if (forme == ButtonStyles.SHAPE_ROUND) {
            float cote = Math.min(r.width(), r.height());
            carre.set(r.centerX() - cote / 2, r.centerY() - cote / 2, r.centerX() + cote / 2, r.centerY() + cote / 2);
            r = carre;
        }
        boolean vif = allume(id), enfonce = ENDROITS[id] != null && doigts.appuye(ENDROITS[id]);
        Parure.bouton(toile, pinceau, r, Parure.coin(forme, r, dp), dp, ButtonStyles.color(c, id), enfonce, vif, dessus);
        Drawable icone = id == Commandes.SAUT && plonge ? plongee : icones[id];
        String nom = id == Commandes.MENU && prochainModif != null ? nomModif(prochainModif)
                : id == Commandes.SAUT && plonge ? jeu.getString(R.string.st_plonger) : nom(id);
        if (ButtonStyles.label(c, id)) dessinerIconeNom(toile, dessus, icone, nom, vif || enfonce);
        else Parure.icone(toile, pinceau, icone, dessus.centerX(), dessus.centerY(),
                Math.min(dessus.width(), dessus.height()) * .66f, dp, vif || enfonce, 255);
        if (id == Commandes.CIBLE) {
            // Maintenir Cible vise le cadavre le plus proche : une petite tête de mort dans le coin le rappelle.
            float rr = r.width() * .19f, cx = r.right - rr * .55f, cy = r.top + rr * .55f;
            badge.set(cx - rr, cy - rr, cx + rr, cy + rr);
            Parure.plaque(toile, pinceau, badge, rr, dp, Math.max(1.4f * dp, rr * .16f), 0, false, false, badgeFace);
            Parure.icone(toile, pinceau, crane, cx, cy, rr * 1.25f, dp, false, 255);
        }
    }

    /** L'icône et le nom en lettres d'or sur le cuir du bouton. */
    private void dessinerIconeNom(Canvas toile, RectF zone, Drawable icone, String nom, boolean vif) {
        float taille = commandes.police * 1.05f;
        Parure.lettres(plume, taille, vif ? Parure.OR_CLAIR : Parure.CREME, dp);
        plume.setTextAlign(Paint.Align.CENTER);
        float large = plume.measureText(nom);
        if (large > zone.width() * .88f) plume.setTextSize(taille * zone.width() * .88f / large);
        float cote = Math.min(zone.width(), zone.height()) * .56f, ecart = zone.height() * .02f;
        float haut = zone.centerY() - (cote + ecart + plume.getTextSize()) / 2;
        Parure.icone(toile, pinceau, icone, zone.centerX(), haut + cote / 2, cote, dp, vif, 255);
        toile.drawText(nom, zone.centerX(), haut + cote + ecart - plume.ascent() * .92f, plume);
    }

    /** Une icône simple, d'une seule couleur (bannières, guide). */
    private void poser(Canvas toile, Drawable icone, float cx, float cy, float cote, int couleur) {
        int demi = Math.round(cote / 2);
        icone.setBounds(Math.round(cx) - demi, Math.round(cy) - demi, Math.round(cx) + demi, Math.round(cy) + demi);
        if (couleur != 0) icone.setTint(couleur);
        icone.draw(toile);
    }

    /** Joystick caméra : un disque de cuir cerclé d'or, quatre crans, un pommeau. */
    private void dessinerCamera(Canvas toile) {
        float r = camRayon * .78f;
        Parure.cuir(toile, pinceau, camX, camY, r, 180);
        Parure.anneau(toile, pinceau, camX, camY, r, 2.4f * dp);
        contour(1 * dp, 0x70D9A84A);
        toile.drawCircle(camX, camY, r * .74f, pinceau);
        plein(0xB0D9A84A);
        for (int cran = 0; cran < 4; cran++) {
            double a = Math.toRadians(45 + 90 * cran);
            toile.drawCircle(camX + (float) Math.cos(a) * r * .87f, camY + (float) Math.sin(a) * r * .87f, 1.6f * dp, pinceau);
        }
        float b = camRayon * .3f;
        pommeau.set(camBoutonX - b, camBoutonY - b, camBoutonX + b, camBoutonY + b);
        Parure.bouton(toile, pinceau, pommeau, b, dp, 0, doigtCam != -1, false, dessus);
        Parure.icone(toile, pinceau, oeil, camBoutonX, camBoutonY, b * 1.05f, dp, doigtCam != -1, 255);
    }

    /** Joystick de déplacement : cuir, anneau d'or gravé, quatre flèches dorées, pommeau en plaque. */
    private void dessinerJoystick(Canvas toile) {
        boolean course = doigts.enCourse();
        Parure.cuir(toile, pinceau, joyX, joyY, rayon, 200);
        if (course) {
            contour(7 * dp, 0x50FFB23A);
            toile.drawCircle(joyX, joyY, rayon + 3 * dp, pinceau);
        }
        Parure.anneau(toile, pinceau, joyX, joyY, rayon, 3.2f * dp);
        contour(1 * dp, 0x70D9A84A);
        toile.drawCircle(joyX, joyY, rayon * .62f, pinceau);
        float pointe = rayon * .9f, base = rayon * .74f, demi = rayon * .1f;
        float[][] sens = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}};
        for (float[] s : sens) {
            trace.reset();
            trace.moveTo(joyX + s[0] * pointe, joyY + s[1] * pointe);
            trace.lineTo(joyX + s[0] * base - s[1] * demi, joyY + s[1] * base + s[0] * demi);
            trace.lineTo(joyX + s[0] * base + s[1] * demi, joyY + s[1] * base - s[0] * demi);
            trace.close();
            pinceau.setShader(new LinearGradient(joyX - rayon, joyY - rayon, joyX + rayon, joyY + rayon,
                    Parure.OR_CLAIR, Parure.OR_MOYEN, Shader.TileMode.CLAMP));
            pinceau.setStyle(Paint.Style.FILL);
            toile.drawPath(trace, pinceau);
            contour(.8f * dp, 0xC0120A05);
            toile.drawPath(trace, pinceau);
        }
        float b = rayon * .4f;
        pommeau.set(boutonX - b, boutonY - b, boutonX + b, boutonY + b);
        Parure.bouton(toile, pinceau, pommeau, b, dp, 0, doigtJoy != -1, course, dessus);
        if (course) Parure.icone(toile, pinceau, coureur, boutonX, boutonY, b * 1.15f, dp, true, 255);
    }

    // ---------------------------------------------------------------- Bannière et carte « Course auto »

    private void banniere(Drawable icone, String titre, String aide) {
        banCarte = false;
        banIcone = icone;
        banTitre = titre;
        banAide = aide;
        banDebut = SystemClock.uptimeMillis();
        invalidate();
    }

    /** La première course automatique de la session : une jolie carte qui explique comment l'arrêter. */
    private void carteCourse() {
        if (!dejaVu.add("carte_course")) return;
        banCarte = true;
        banIcone = coureur;
        banTitre = jeu.getString(R.string.st_a_course);
        banAide = null;
        banDebut = SystemClock.uptimeMillis();
        invalidate();
    }

    /** Un message bref : une plaque de cuir cerclée d'or qui apparaît puis s'efface. */
    private void dessinerBanniere(Canvas toile, long age) {
        float vu = Math.max(0, Math.min(1, Math.min(age / 150f, (BANNIERE_MS - age) / 400f)));
        Commandes.Cadre img = image();
        float tTitre = 16 * dp, tAide = 12.5f * dp, cote = 30 * dp, marge = 14 * dp;
        Parure.lettres(plume, tTitre, Parure.OR_CLAIR, dp);
        plume.setTextAlign(Paint.Align.LEFT);
        float lTitre = plume.measureText(banTitre);
        plume.setTypeface(normal);
        plume.setTextSize(tAide);
        float maxi = img.largeur() * .82f - cote - 3 * marge;
        float lAide = banAide == null ? 0 : plume.measureText(banAide);
        if (lAide > maxi) {
            tAide *= maxi / lAide;
            lAide = maxi;
        }
        float w = 3 * marge + cote + Math.max(lTitre, lAide), h = marge * 1.7f + tTitre + (banAide == null ? 0 : tAide * 1.4f);
        float cx = img.gauche + img.largeur() / 2, haut = img.haut + img.hauteur() * .27f;
        cadre.set(cx - w / 2, haut, cx + w / 2, haut + h);
        int calque = toile.saveLayerAlpha(cadre.left - 12 * dp, cadre.top - 12 * dp, cadre.right + 12 * dp,
                cadre.bottom + 12 * dp, Math.round(255 * vu));
        Parure.plaque(toile, pinceau, cadre, 14 * dp, dp, 3 * dp, 0, false, false, dessus);
        if (banIcone != null) Parure.icone(toile, pinceau, banIcone, cadre.left + marge + cote / 2, cadre.centerY(), cote, dp, true, 255);
        float x = cadre.left + 2 * marge + cote, y = cadre.top + marge * .85f;
        Parure.lettres(plume, tTitre, Parure.OR_CLAIR, dp);
        toile.drawText(banTitre, x, y - plume.ascent(), plume);
        if (banAide != null) {
            plume.setTypeface(normal);
            plume.setTextSize(tAide);
            plume.setColor(Parure.CREME);
            toile.drawText(banAide, x, y + tTitre * 1.2f - plume.ascent(), plume);
        }
        toile.restoreToCount(calque);
    }

    /** Médaillon du coureur, état en pierre gravée, deux lignes d'aide, minuterie dorée qui se vide. */
    private void dessinerCarteCourse(Canvas toile, long age) {
        float entree = Math.min(1f, age / 260f), sortie = Math.min(1f, (CARTE_MS - age) / 450f);
        float vu = Math.max(0f, Math.min(entree, sortie));
        float glisse = 1 - (1 - entree) * (1 - entree) * (1 - entree);
        Commandes.Cadre img = image();
        float w = Math.min(img.largeur() * .8f, 360 * dp), h = 104 * dp, coin = 20 * dp;
        float cx = img.gauche + img.largeur() / 2, haut = img.haut + img.hauteur() * .18f - (1 - glisse) * 22 * dp;
        RectF carte = new RectF(cx - w / 2, haut, cx + w / 2, haut + h);
        int calque = toile.saveLayerAlpha(carte.left - 24 * dp, carte.top - 24 * dp, carte.right + 24 * dp,
                carte.bottom + 24 * dp, Math.round(255 * vu));
        // Halo de braise derrière la carte.
        for (int i = 3; i >= 1; i--) {
            contour(i * 4 * dp, Parure.BRAISE);
            pinceau.setAlpha(46 - 12 * i);
            toile.drawRoundRect(carte, coin, coin, pinceau);
        }
        Parure.plaque(toile, pinceau, carte, coin, dp, 3.4f * dp, 0, false, false, dessus);
        // Le médaillon du coureur, avec des traits de vitesse qui défilent.
        float pr = 31 * dp, px = carte.left + 18 * dp + pr, py = carte.top + h / 2 - 2 * dp;
        medaillon.set(px - pr, py - pr, px + pr, py + pr);
        Parure.plaque(toile, pinceau, medaillon, pr, dp, 3 * dp, 0, false, true, badgeFace);
        Paint.Cap bout = pinceau.getStrokeCap();
        contour(2.4f * dp, Parure.OR_CLAIR);
        pinceau.setStrokeCap(Paint.Cap.ROUND);
        for (int trait = 0; trait < 3; trait++) {
            float phase = (age / 560f + trait / 3f) % 1f;
            float fin = px - pr * .3f - phase * pr * .32f, ly = py - pr * .28f + trait * pr * .28f;
            pinceau.setAlpha(Math.round(200 * (1 - phase)));
            toile.drawLine(fin - pr * .22f, ly, fin, ly, pinceau);
        }
        pinceau.setStrokeCap(bout);
        pinceau.setAlpha(255);
        Parure.icone(toile, pinceau, coureur, px + pr * .12f, py, pr * 1.1f, dp, true, 255);
        // Titre, puis l'état : activée ou arrêtée.
        float tx = px + pr + 16 * dp, largeurMax = carte.right - 16 * dp - tx;
        Parure.lettres(plume, 19 * dp, Parure.OR_CLAIR, dp);
        plume.setTextAlign(Paint.Align.LEFT);
        float ty = carte.top + 16 * dp - plume.ascent();
        toile.drawText(banTitre, tx, ty, plume);
        float milieu = ty + (plume.ascent() + plume.descent()) / 2, ex = tx + plume.measureText(banTitre) + 10 * dp;
        boolean active = doigts.enCourse();
        String etat = active ? jeu.getString(R.string.st_activee) : jeu.getString(R.string.st_arretee);
        Parure.lettres(plume, 10 * dp, Parure.CREME, dp);
        float ew = plume.measureText(etat) + 16 * dp, eh = 19 * dp;
        RectF pastille = new RectF(ex, milieu - eh / 2, ex + ew, milieu + eh / 2);
        plein(active ? 0xFF2D7A4A : 0xFF8E2A22);
        toile.drawRoundRect(pastille, 4 * dp, 4 * dp, pinceau);
        contour(1.2f * dp, Parure.OR);
        toile.drawRoundRect(pastille, 4 * dp, 4 * dp, pinceau);
        toile.drawText(etat, ex + 8 * dp, milieu - (plume.ascent() + plume.descent()) / 2, plume);
        String ligne1 = jeu.getString(R.string.st_course_1), ligne2 = jeu.getString(R.string.st_course_2);
        plume.setTypeface(normal);
        float ta = 12.5f * dp;
        plume.setTextSize(ta);
        float plusLarge = Math.max(plume.measureText(ligne1), plume.measureText(ligne2));
        if (plusLarge > largeurMax) {
            ta *= largeurMax / plusLarge;
            plume.setTextSize(ta);
        }
        plume.setColor(Parure.CREME);
        float y1 = ty + 10 * dp + ta;
        toile.drawText(ligne1, tx, y1, plume);
        toile.drawText(ligne2, tx, y1 + ta * 1.4f, plume);
        // Minuterie : une fine barre d'or dans une rainure, qui se vide.
        float reste = Math.max(0f, 1f - age / (float) CARTE_MS);
        float gauche = dessus.left + 14 * dp, droite = dessus.right - 14 * dp, ligne = dessus.bottom - 8 * dp;
        contour(4 * dp, Parure.ENCRE);
        pinceau.setStrokeCap(Paint.Cap.ROUND);
        toile.drawLine(gauche, ligne, droite, ligne, pinceau);
        pinceau.setStrokeWidth(2.4f * dp);
        pinceau.setShader(new LinearGradient(gauche, 0, droite, 0, Parure.OR_MOYEN, Parure.OR_CLAIR, Shader.TileMode.CLAMP));
        toile.drawLine(gauche, ligne, gauche + (droite - gauche) * reste, ligne, pinceau);
        pinceau.setShader(null);
        pinceau.setStrokeCap(bout);
        toile.restoreToCount(calque);
    }

    // ---------------------------------------------------------------- Guide et déplacement

    /** Une étiquette : petite plaque de cuir cerclée d'or. aX : 0 = centrée sur x, 1 = finit à x, -1 = commence à x. */
    private void etiquette(Canvas toile, String texte, float x, float y, int aX, int aY) {
        float taille = 12.5f * dp, mx = 12 * dp, my = 7 * dp;
        plume.setTypeface(normal);
        plume.setTextSize(taille);
        plume.setTextAlign(Paint.Align.LEFT);
        float maxi = getWidth() * .6f, large = plume.measureText(texte);
        if (large > maxi) {
            plume.setTextSize(taille * maxi / large);
            large = maxi;
        }
        float w = large + 2 * mx, h = plume.getTextSize() + 2 * my;
        float gauche = aX == 0 ? x - w / 2 : aX == 1 ? x - w : x, haut = aY == 0 ? y - h / 2 : aY == 1 ? y - h : y;
        gauche = borne(gauche, margeG + 4 * dp, getWidth() - margeD - 4 * dp - w);
        haut = borne(haut, margeH + 4 * dp, getHeight() - margeB - 4 * dp - h);
        cadre.set(gauche, haut, gauche + w, haut + h);
        Parure.plaque(toile, pinceau, cadre, h / 2, dp, 1.8f * dp, 0, false, false, badgeFace);
        plume.setColor(Parure.CREME);
        plume.setShadowLayer(2 * dp, 0, dp, 0xD0000000);
        toile.drawText(texte, gauche + mx, haut + my - plume.ascent() * .95f, plume);
    }

    /** Ce que fait chaque commande, par-dessus le jeu. Se ferme au premier toucher. */
    private void dessinerGuide(Canvas toile) {
        plein(0xC8120A05);
        toile.drawRect(0, 0, getWidth(), getHeight(), pinceau);
        String[] aides = new String[Commandes.NOMBRE];
        aides[Commandes.ECHAP] = jeu.getString(R.string.st_g_esc);
        aides[Commandes.CLAVIER] = jeu.getString(R.string.st_g_clavier);
        aides[Commandes.MENU] = jeu.getString(R.string.st_g_menu);
        aides[Commandes.CIBLE] = jeu.getString(R.string.st_g_cible);
        aides[Commandes.UTILISER] = jeu.getString(R.string.st_g_utiliser);
        aides[Commandes.SAUT] = jeu.getString(R.string.st_g_sauter);
        aides[Commandes.CARTE] = nom(Commandes.CARTE);
        aides[Commandes.SACS] = nom(Commandes.SACS);
        aides[Commandes.METIERS] = nom(Commandes.METIERS);
        aides[Commandes.TALENTS] = nom(Commandes.TALENTS);
        aides[Commandes.COUCHE] = jeu.getString(R.string.st_g_couche);
        for (int i = 0; i < boutons.length; i++) {
            if (boutons[i].isEmpty()) continue;
            cadre.set(boutons[i]);
            cadre.inset(-4 * dp, -4 * dp);
            contour(5 * dp, 0x50FFB23A);
            toile.drawRoundRect(cadre, 14 * dp, 14 * dp, pinceau);
            dessinerBouton(toile, i);
        }
        for (int i = 0; i < boutons.length; i++) {
            if (boutons[i].isEmpty() || aides[i] == null) continue;
            RectF b = boutons[i];
            // L'étiquette va du côté où il y a le plus de place.
            if (b.centerX() > getWidth() / 2f) etiquette(toile, aides[i], b.left - 10 * dp, b.centerY(), 1, 0);
            else etiquette(toile, aides[i], b.right + 10 * dp, b.centerY(), -1, 0);
        }
        if (!manette) {
            dessinerJoystick(toile);
            etiquette(toile, jeu.getString(R.string.st_g_joystick), joyX,
                    joyY - rayon * 1.2f - 8 * dp, 0, 1);
            dessinerCamera(toile);
            etiquette(toile, jeu.getString(R.string.st_g_camera), camX, camY - camRayon - 8 * dp, 0, 1);
        }
        Commandes.Cadre img = image();
        float cx = img.gauche + img.largeur() / 2;
        etiquette(toile, jeu.getString(R.string.st_g_ailleurs),
                cx, img.haut + img.hauteur() * .5f, 0, 0);
        etiquette(toile, jeu.getString(R.string.st_g_continuer), cx, getHeight() - margeB - 12 * dp, 0, 1);
    }

    /** Pendant « Déplacer les commandes » : pointillés d'or autour de tout ce qui se déplace, et Terminer. */
    private void dessinerEdition(Canvas toile) {
        contour(2 * dp, Parure.OR_CLAIR);
        pinceau.setPathEffect(new DashPathEffect(new float[]{7 * dp, 5 * dp}, 0));
        toile.drawCircle(joyX, joyY, rayon * 1.24f, pinceau);
        toile.drawCircle(camX, camY, camRayon * .9f, pinceau);
        for (RectF b : boutons) if (!b.isEmpty()) toile.drawRoundRect(b.left - 4 * dp, b.top - 4 * dp,
                b.right + 4 * dp, b.bottom + 4 * dp, 10 * dp, 10 * dp, pinceau);
        pinceau.setPathEffect(null);
        terminer.set(10 * dp, 10 * dp, 150 * dp, 48 * dp);
        Parure.plaque(toile, pinceau, terminer, 10 * dp, dp, 2.6f * dp, 0, false, true, badgeFace);
        Parure.lettres(plume, 15 * dp, Parure.OR_CLAIR, dp);
        plume.setTextAlign(Paint.Align.CENTER);
        toile.drawText(jeu.getString(R.string.st_terminer), badgeFace.centerX(),
                badgeFace.centerY() - (plume.ascent() + plume.descent()) / 2, plume);
    }

    private void eclat(float x, float y) {
        eclatX = x;
        eclatY = y;
        eclatDebut = SystemClock.uptimeMillis();
        invalidate(); // onDraw continue l'animation tant que l'éclat dure
    }
}
