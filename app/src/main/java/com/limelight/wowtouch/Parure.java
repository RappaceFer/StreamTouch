package com.limelight.wowtouch;

import android.app.AlertDialog;
import android.content.res.ColorStateList;
import android.graphics.Bitmap;
import android.graphics.BitmapShader;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ColorFilter;
import android.graphics.DashPathEffect;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.RadialGradient;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.SeekBar;
import android.widget.TextView;

import java.util.Random;

/**
 * Streaming Touch, Made in Rappace : la parure médiévale de l'appli, or et cuir.
 * Cadres d'or biseautés, cuir sombre cousu avec son grain, icônes dorées en relief, lettres à empattements.
 * Tout ce qui se dessine (boutons, joysticks, menu rond, fenêtres) passe par ici, pour un seul style partout.
 */
final class Parure {
    private Parure() {}

    static final int OR_CLAIR = 0xFFFAEAB4, OR = 0xFFD9A84A, OR_MOYEN = 0xFFAE7A26, OR_SOMBRE = 0xFF5A3B0F,
            CUIR_HAUT = 0xFF5E4029, CUIR_BAS = 0xFF1A100A, CUIR_VIF_HAUT = 0xFF8E5C27, CUIR_VIF_BAS = 0xFF2E1909,
            COUTURE = 0xA6DDB466, CREME = 0xFFF4E4B8, SABLE = 0xFFC9B48A, BRAISE = 0xFFFFB23A, ENCRE = 0xFF120A05,
            OMBRE = 0x99000000;
    static final Typeface LETTRES = Typeface.create(Typeface.SERIF, Typeface.BOLD);
    private static final int[] OR_CADRE = {OR_CLAIR, OR, OR_MOYEN, OR_SOMBRE};
    private static final float[] OR_PAS = {0f, .3f, .62f, 1f};
    private static final PorterDuffXfermode DANS = new PorterDuffXfermode(PorterDuff.Mode.SRC_IN);
    private static BitmapShader grain;

    /** Le grain du cuir : un petit motif de bruit doux, répété. Fait une seule fois. */
    private static BitmapShader grain() {
        if (grain != null) return grain;
        int cote = 128, maille = 8;
        Random hasard = new Random(1988);
        float[][] gros = new float[cote / maille + 1][cote / maille + 1];
        for (float[] ligne : gros) for (int i = 0; i < ligne.length; i++) ligne[i] = hasard.nextFloat() * 2 - 1;
        // Les bords se raccordent pour que le motif se répète sans couture visible.
        for (int i = 0; i < gros.length; i++) { gros[i][gros.length - 1] = gros[i][0]; gros[gros.length - 1][i] = gros[0][i]; }
        int[] points = new int[cote * cote];
        for (int y = 0; y < cote; y++) {
            for (int x = 0; x < cote; x++) {
                float gx = x / (float) maille, gy = y / (float) maille;
                int x0 = (int) gx, y0 = (int) gy;
                float fx = gx - x0, fy = gy - y0;
                float doux = (gros[y0][x0] * (1 - fx) + gros[y0][x0 + 1] * fx) * (1 - fy)
                        + (gros[y0 + 1][x0] * (1 - fx) + gros[y0 + 1][x0 + 1] * fx) * fy;
                float n = doux * .6f + (hasard.nextFloat() * 2 - 1) * .4f;
                int alpha = Math.min(255, Math.round(Math.abs(n) * 70));
                points[y * cote + x] = n > 0 ? Color.argb(alpha / 2, 255, 230, 190) : Color.argb(alpha, 0, 0, 0);
            }
        }
        Bitmap motif = Bitmap.createBitmap(points, cote, cote, Bitmap.Config.ARGB_8888);
        grain = new BitmapShader(motif, Shader.TileMode.REPEAT, Shader.TileMode.REPEAT);
        return grain;
    }

    private static void propre(Paint p) {
        p.setShader(null);
        p.setPathEffect(null);
        p.setXfermode(null);
        p.setStyle(Paint.Style.FILL);
        p.setColor(Color.WHITE);
    }

    static int melange(int a, int b, float t) { return ButtonStyles.mix(a, b, t); }

    /**
     * Une plaque : ombre portée, cadre d'or biseauté, gorge sombre, cuir avec grain, couture et reflet.
     * @param teinte 0 = cuir d'origine, sinon la couleur choisie dans « Boutons » (le cadre reste en or)
     * @param face   reçoit la place du cuir (pour poser l'icône dessus)
     */
    static void plaque(Canvas t, Paint p, RectF r, float coin, float dp, float cadre, int teinte,
                       boolean enfonce, boolean allume, RectF face) {
        propre(p);
        if (allume) {
            // Braise autour : le bouton est armé ou actif.
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(7 * dp);
            p.setColor(0x40FFB23A);
            t.drawRoundRect(r, coin + 2 * dp, coin + 2 * dp, p);
            p.setStrokeWidth(3 * dp);
            p.setColor(0xB0FFC864);
            t.drawRoundRect(r, coin + 1 * dp, coin + 1 * dp, p);
            p.setStyle(Paint.Style.FILL);
        }
        // Pas d'ombre portée : sur un décor clair, elle faisait une bande grise sous le bouton.
        p.setShader(new LinearGradient(0, r.top, 0, r.bottom, OR_CADRE, OR_PAS, Shader.TileMode.CLAMP));
        t.drawRoundRect(r, coin, coin, p);
        p.setShader(null);
        float gorge = cadre * .55f;
        p.setColor(ENCRE);
        t.drawRoundRect(r.left + gorge, r.top + gorge, r.right - gorge, r.bottom - gorge,
                Math.max(0, coin - gorge), Math.max(0, coin - gorge), p);
        face.set(r.left + cadre, r.top + cadre, r.right - cadre, r.bottom - cadre);
        if (enfonce) face.offset(0, .7f * dp);
        float coinFace = Math.max(0, coin - cadre);
        int haut, fond;
        if (teinte == 0) {
            haut = enfonce || allume ? CUIR_VIF_HAUT : CUIR_HAUT;
            fond = enfonce || allume ? CUIR_VIF_BAS : CUIR_BAS;
        } else {
            haut = melange(teinte, Color.BLACK, enfonce || allume ? .15f : .38f);
            fond = melange(teinte, Color.BLACK, enfonce || allume ? .62f : .8f);
        }
        p.setShader(new RadialGradient(face.centerX(), face.top + face.height() * .28f,
                Math.max(face.width(), face.height()) * .9f, haut, fond, Shader.TileMode.CLAMP));
        t.drawRoundRect(face, coinFace, coinFace, p);
        p.setShader(grain());
        p.setAlpha(150);
        t.drawRoundRect(face, coinFace, coinFace, p);
        p.setAlpha(255);
        // Couture en pointillés dorés, un peu en retrait du cadre.
        float retrait = Math.max(2.2f * dp, Math.min(face.width(), face.height()) * .07f);
        if (Math.min(face.width(), face.height()) > 26 * dp) {
            p.setShader(null);
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(.9f * dp);
            p.setColor(COUTURE);
            p.setPathEffect(new DashPathEffect(new float[]{2.4f * dp, 1.9f * dp}, 0));
            t.drawRoundRect(face.left + retrait, face.top + retrait, face.right - retrait, face.bottom - retrait,
                    Math.max(0, coinFace - retrait), Math.max(0, coinFace - retrait), p);
            p.setPathEffect(null);
            p.setStyle(Paint.Style.FILL);
        }
        // Reflet sur le haut du cuir, ou ombre intérieure quand le bouton s'enfonce.
        p.setShader(enfonce
                ? new LinearGradient(0, face.top, 0, face.top + face.height() * .35f, 0x90000000, 0, Shader.TileMode.CLAMP)
                : new LinearGradient(0, face.top, 0, face.centerY(), 0x30FFF2D0, 0x00FFF2D0, Shader.TileMode.CLAMP));
        t.drawRoundRect(face, coinFace, coinFace, p);
        propre(p);
    }

    /** Un bouton à l'écran : la plaque avec un cadre proportionné à sa taille. */
    static void bouton(Canvas t, Paint p, RectF r, float coin, float dp, int teinte, boolean enfonce, boolean allume, RectF face) {
        float cadre = Math.max(2.4f * dp, Math.min(r.width(), r.height()) * .075f);
        plaque(t, p, r, coin, dp, cadre, teinte, enfonce, allume, face);
    }

    /** Le coin arrondi d'un bouton selon sa forme choisie (arrondi, rond, carré). */
    static float coin(int forme, RectF r, float dp) {
        return forme == ButtonStyles.SHAPE_ROUND ? Math.min(r.width(), r.height()) / 2
                : forme == ButtonStyles.SHAPE_SQUARE ? 3 * dp : Math.min(13 * dp, Math.min(r.width(), r.height()) * .26f);
    }

    /** Une icône dorée en relief : liseré clair au-dessus, ombre dessous, or en dégradé. */
    static void icone(Canvas t, Paint p, Drawable d, float cx, float cy, float cote, float dp, boolean vif, int alpha) {
        if (d == null || alpha <= 0) return;
        int demi = Math.round(cote / 2), x = Math.round(cx), y = Math.round(cy);
        int decale = Math.max(1, Math.round(cote * .045f));
        d.setAlpha(alpha);
        d.setTint(0xE0000000);
        d.setBounds(x - demi, y - demi + decale, x + demi, y + demi + decale);
        d.draw(t);
        d.setTint(0x66FFF3D2);
        d.setBounds(x - demi, y - demi - 1, x + demi, y + demi - 1);
        d.draw(t);
        int calque = t.saveLayer(x - demi - 1, y - demi - 1, x + demi + 1, y + demi + 1, null);
        d.setTint(Color.WHITE);
        d.setBounds(x - demi, y - demi, x + demi, y + demi);
        d.draw(t);
        propre(p);
        p.setShader(new LinearGradient(0, y - demi, 0, y + demi,
                vif ? new int[]{0xFFFFFCEB, 0xFFFFDC78, 0xFFE8A030} : new int[]{0xFFFCEBB6, 0xFFE2B252, 0xFF9C6A1A},
                new float[]{0f, .5f, 1f}, Shader.TileMode.CLAMP));
        p.setXfermode(DANS);
        t.drawRect(x - demi - 1, y - demi - 1, x + demi + 1, y + demi + 1, p);
        propre(p);
        t.restoreToCount(calque);
        d.setAlpha(255);
    }

    /** Un anneau d'or (bord d'un joystick, cercles du menu rond). */
    static void anneau(Canvas t, Paint p, float cx, float cy, float r, float epaisseur) {
        propre(p);
        p.setStyle(Paint.Style.STROKE);
        p.setStrokeWidth(epaisseur + 2);
        p.setColor(ENCRE);
        t.drawCircle(cx, cy, r, p);
        p.setStrokeWidth(epaisseur);
        p.setShader(new LinearGradient(0, cy - r, 0, cy + r, OR_CADRE, OR_PAS, Shader.TileMode.CLAMP));
        t.drawCircle(cx, cy, r, p);
        propre(p);
    }

    /** Un disque de cuir (fond d'un joystick, plateau du menu rond). */
    static void cuir(Canvas t, Paint p, float cx, float cy, float r, int alpha) {
        propre(p);
        p.setShader(new RadialGradient(cx, cy - r * .3f, r * 1.3f, CUIR_HAUT, CUIR_BAS, Shader.TileMode.CLAMP));
        p.setAlpha(alpha);
        t.drawCircle(cx, cy, r, p);
        p.setShader(grain());
        p.setAlpha(alpha * 150 / 255);
        t.drawCircle(cx, cy, r, p);
        propre(p);
    }

    /** Texte doré à empattements avec une ombre, pour les noms et les titres. */
    static void lettres(Paint plume, float taille, int couleur, float dp) {
        plume.setTypeface(LETTRES);
        plume.setTextSize(taille);
        plume.setColor(couleur);
        plume.setShadowLayer(2 * dp, 0, dp, 0xD0000000);
    }

    // ------------------------------------------------------------------ Fenêtres (réglages, À propos...)

    /** Le fond d'une fenêtre ou d'un bouton : une plaque dessinée comme les boutons du jeu. */
    static final class Fond extends Drawable {
        private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF r = new RectF(), face = new RectF();
        private final float dp, coin, cadre;
        private final boolean touche;
        private boolean enfonce;

        Fond(float dp, float coin, float cadre, boolean touche) {
            this.dp = dp;
            this.coin = coin;
            this.cadre = cadre;
            this.touche = touche;
        }

        @Override public void draw(Canvas t) {
            Rect b = getBounds();
            r.set(b.left + dp, b.top + dp, b.right - dp, b.bottom - 3 * dp);
            plaque(t, p, r, coin, dp, cadre, 0, enfonce, false, face);
        }

        @Override public boolean isStateful() { return touche; }

        @Override protected boolean onStateChange(int[] etats) {
            boolean avant = enfonce;
            enfonce = false;
            for (int e : etats) if (e == android.R.attr.state_pressed) enfonce = true;
            if (avant != enfonce) invalidateSelf();
            return avant != enfonce;
        }

        @Override public void setAlpha(int alpha) {}
        @Override public void setColorFilter(ColorFilter filtre) {}
        @Override public int getOpacity() { return PixelFormat.TRANSLUCENT; }
    }

    /** Un bouton de fenêtre : plaque de cuir, lettres dorées. */
    static void habiller(Button b, float dp) {
        b.setBackground(new Fond(dp, 10 * dp, 2.4f * dp, true));
        b.setTextColor(OR_CLAIR);
        b.setTypeface(LETTRES);
        b.setAllCaps(false);
        b.setShadowLayer(2 * dp, 0, dp, 0xD0000000);
        b.setStateListAnimator(null);
    }

    static void habiller(SeekBar barre) {
        barre.setProgressTintList(ColorStateList.valueOf(OR));
        barre.setProgressBackgroundTintList(ColorStateList.valueOf(0x80AE7A26));
        barre.setThumbTintList(ColorStateList.valueOf(OR_CLAIR));
    }

    static void habiller(CheckBox caseACocher) {
        caseACocher.setButtonTintList(ColorStateList.valueOf(OR));
        caseACocher.setTextColor(CREME);
    }

    /** Un titre de rubrique dans une fenêtre : lettres dorées et un filet d'or dessous. */
    static TextView rubrique(TextView t, float dp) {
        t.setTypeface(LETTRES);
        t.setTextColor(OR);
        t.setShadowLayer(2 * dp, 0, dp, 0xD0000000);
        GradientDrawable filet = new GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT,
                new int[]{0x00D9A84A, 0xB0D9A84A, 0x00D9A84A});
        filet.setSize(1, Math.max(1, Math.round(dp)));
        t.setCompoundDrawablesRelativeWithIntrinsicBounds(null, null, null, filet);
        t.setCompoundDrawablePadding(Math.round(3 * dp));
        return t;
    }

    /**
     * Une fenêtre déjà affichée prend la parure : fond de cuir dans un cadre d'or, titre et texte dorés,
     * boutons en plaques. Les textes laissés à la couleur du thème deviennent crème.
     */
    static void habiller(AlertDialog fenetre, float dp) {
        if (fenetre.getWindow() == null) return;
        fenetre.getWindow().setBackgroundDrawable(new Fond(dp, 16 * dp, 3.2f * dp, false));
        View racine = fenetre.getWindow().getDecorView();
        int idTitre = racine.getResources().getIdentifier("alertTitle", "id", "android");
        TextView titre = idTitre != 0 ? racine.findViewById(idTitre) : null;
        if (titre != null) {
            titre.setTypeface(LETTRES);
            titre.setTextColor(OR);
            titre.setTextSize(20);
            titre.setShadowLayer(3 * dp, 0, dp, 0xD0000000);
        }
        TextView message = racine.findViewById(android.R.id.message);
        if (message != null) message.setTextColor(CREME);
        for (int quel : new int[]{AlertDialog.BUTTON_POSITIVE, AlertDialog.BUTTON_NEGATIVE, AlertDialog.BUTTON_NEUTRAL}) {
            Button b = fenetre.getButton(quel);
            if (b == null || b.getVisibility() != View.VISIBLE) continue;
            habiller(b, dp);
            ViewGroup.LayoutParams lp = b.getLayoutParams();
            if (lp instanceof ViewGroup.MarginLayoutParams) ((ViewGroup.MarginLayoutParams) lp).setMargins(Math.round(4 * dp), 0, Math.round(4 * dp), 0);
            b.setPadding(Math.round(18 * dp), 0, Math.round(18 * dp), 0);
        }
        recolorer(racine);
    }

    /** Les textes et cases d'une fenêtre, sauf ceux qui ont déjà la parure. */
    private static void recolorer(View v) {
        if (v instanceof CheckBox) {
            habiller((CheckBox) v);
        } else if (v instanceof SeekBar) {
            habiller((SeekBar) v);
        } else if (v instanceof TextView && !(v instanceof Button)) {
            TextView t = (TextView) v;
            if (t.getTypeface() != LETTRES) t.setTextColor(CREME);
        } else if (v instanceof ViewGroup) {
            ViewGroup g = (ViewGroup) v;
            for (int i = 0; i < g.getChildCount(); i++) recolorer(g.getChildAt(i));
        }
    }
}
