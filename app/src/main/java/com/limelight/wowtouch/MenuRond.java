package com.limelight.wowtouch;

import com.limelight.R;

import android.animation.ValueAnimator;
import android.app.Activity;
import android.app.Dialog;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RadialGradient;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.view.HapticFeedbackConstants;
import android.view.MotionEvent;
import android.view.View;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.OvershootInterpolator;

import java.util.HashMap;
import java.util.Map;

/**
 * Streaming Touch, Made in Rappace : le menu rond de l'appli (bouton Menu), façon sceau d'or et de cuir.
 * Le clavier au milieu, les actions en cercle autour. On touche une icône, ou on glisse le doigt
 * dessus et on le lève. Toucher en dehors du rond le ferme.
 */
final class MenuRond {
    private static final int MILIEU = -1, PLATEAU = -2, DEHORS = -3, RIEN = -100;
    private static final ActionTactile[] ACTIONS = {ActionTactile.MODE_MANETTE, ActionTactile.BOUTONS,
            ActionTactile.DEPLACER, ActionTactile.REGLAGES, ActionTactile.COURSE_AUTO, ActionTactile.PLONGER,
            ActionTactile.MAJ, ActionTactile.CTRL, ActionTactile.ALT, ActionTactile.FILTRE, ActionTactile.GUIDE, ActionTactile.A_PROPOS};

    private final Activity activite;
    private final ActionTactile.Hote hote;
    private final float dp;
    private Dialog fenetre;

    MenuRond(Activity activite, ActionTactile.Hote hote) {
        this.activite = activite;
        this.hote = hote;
        dp = activite.getResources().getDisplayMetrics().density;
    }

    boolean ouvert() { return fenetre != null && fenetre.isShowing(); }

    void fermer() { if (fenetre != null) fenetre.dismiss(); }

    void ouvrir() {
        if (activite.isFinishing() || ouvert()) return;
        // Le cuir des pastilles prend la couleur choisie pour le bouton Menu (sinon celle d'Esc, sinon le cuir).
        int teinte = ButtonStyles.color(activite, Commandes.MENU);
        if (teinte == 0) teinte = ButtonStyles.color(activite, Commandes.ECHAP);
        Roue roue = new Roue(teinte);
        fenetre = PleinEcran.ouvrir(activite, roue);
        roue.deplier();
    }

    private void choisir(ActionTactile action) {
        fermer();
        hote.executer(action);
    }

    private final class Roue extends View {
        private final Paint pinceau = new Paint(Paint.ANTI_ALIAS_FLAG), ecrit = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Typeface simple = Typeface.create("sans-serif-medium", Typeface.NORMAL);
        private final Map<Integer, Drawable> dessins = new HashMap<>();
        private final RectF zone = new RectF(), face = new RectF();
        private final int teinte;
        private int touche = RIEN;
        private float ouverture, ecartement = 1;
        private float cx, cy, rAction, rMilieu, rCercle, rPlateau;

        Roue(int teinte) {
            super(activite);
            this.teinte = teinte;
        }

        void deplier() {
            ValueAnimator entree = ValueAnimator.ofFloat(0f, 1f);
            entree.setDuration(240);
            entree.setInterpolator(new DecelerateInterpolator());
            entree.addUpdateListener(a -> { ouverture = (float) a.getAnimatedValue(); invalidate(); });
            entree.start();
            ValueAnimator etoile = ValueAnimator.ofFloat(0f, 1f);
            etoile.setDuration(340);
            etoile.setInterpolator(new OvershootInterpolator(1.3f));
            etoile.addUpdateListener(a -> { ecartement = (float) a.getAnimatedValue(); invalidate(); });
            etoile.start();
        }

        @Override protected void onSizeChanged(int l, int h, int ancienL, int ancienH) {
            cx = l / 2f;
            cy = h / 2f;
            float place = Math.min(l, h) / 2f - 6 * dp;
            rAction = Math.max(22 * dp, Math.min(34 * dp, place * .15f));
            rCercle = place - rAction - 18 * dp;
            rMilieu = rAction * 1.18f;
            rPlateau = rCercle + rAction + 15 * dp;
        }

        private float angle(int rang) { return (float) Math.toRadians(-90 + rang * 360f / ACTIONS.length); }

        @Override protected void onDraw(Canvas toile) {
            toile.drawColor(Color.argb((int) (175 * ouverture), 8, 4, 2));
            int calque = toile.saveLayerAlpha(0, 0, getWidth(), getHeight(), Math.round(255 * ouverture));
            float zoom = .84f + .16f * ouverture;
            toile.scale(zoom, zoom, cx, cy);
            // Halo de braise derrière le sceau.
            pinceau.setShader(new RadialGradient(cx, cy, rPlateau * 1.22f, new int[]{0x60FFB23A, 0x18FFB23A, 0},
                    new float[]{.6f, .82f, 1f}, Shader.TileMode.CLAMP));
            toile.drawCircle(cx, cy, rPlateau * 1.22f, pinceau);
            pinceau.setShader(null);
            // Le plateau : un grand disque de cuir, double anneau d'or, crans gravés entre les deux.
            Parure.cuir(toile, pinceau, cx, cy, rPlateau, 245);
            Parure.anneau(toile, pinceau, cx, cy, rPlateau, 4.5f * dp);
            Parure.anneau(toile, pinceau, cx, cy, rPlateau - 9 * dp, 1.6f * dp);
            pinceau.setStyle(Paint.Style.FILL);
            for (int i = 0; i < ACTIONS.length * 4; i++) {
                double a = Math.toRadians(-90 + (i + .5f) * 360f / (ACTIONS.length * 4));
                float r = rPlateau - 4.5f * dp;
                pinceau.setColor(i % 4 == 1 ? Parure.OR_CLAIR : 0xC0AE7A26);
                toile.drawCircle(cx + (float) Math.cos(a) * r, cy + (float) Math.sin(a) * r, (i % 4 == 1 ? 1.6f : 1f) * dp, pinceau);
            }
            // L'allée des actions : un sillon sombre bordé d'or pâle.
            pinceau.setStyle(Paint.Style.STROKE);
            pinceau.setStrokeWidth(rAction * 2.5f);
            pinceau.setColor(0x55000000);
            toile.drawCircle(cx, cy, rCercle, pinceau);
            pinceau.setStrokeWidth(1 * dp);
            pinceau.setColor(0x80AE7A26);
            toile.drawCircle(cx, cy, rCercle + rAction * 1.25f, pinceau);
            toile.drawCircle(cx, cy, rCercle - rAction * 1.25f, pinceau);
            Parure.anneau(toile, pinceau, cx, cy, rMilieu + 9 * dp, 1.4f * dp);
            // Les actions se déplient depuis le centre.
            float r = rMilieu + (rCercle - rMilieu) * ecartement;
            float vu = Math.min(1f, Math.max(0f, ecartement));
            for (int i = 0; i < ACTIONS.length; i++) {
                float a = angle(i), x = cx + (float) Math.cos(a) * r, y = cy + (float) Math.sin(a) * r;
                pastille(toile, x, y, rAction, ACTIONS[i].icone, hote.estActive(ACTIONS[i]), touche == i, vu);
                nom(toile, ACTIONS[i].nom(activite), x, y + rAction + 14 * dp, rAction * 2.7f, 11, vu,
                        touche == i ? Parure.OR_CLAIR : Parure.CREME);
            }
            pastille(toile, cx, cy - 5 * dp, rMilieu, ActionTactile.CLAVIER.icone, false, touche == MILIEU, 1);
            nom(toile, activite.getString(R.string.st_clavier), cx, cy + rMilieu + 7 * dp, rMilieu * 2.4f, 11, 1, Parure.OR);
            toile.restoreToCount(calque);
            legendes(toile);
        }

        /** À gauche du sceau : le titre ; à droite : l'action sous le doigt et à quoi elle sert. */
        private void legendes(Canvas toile) {
            float gauche = cx - rPlateau - 28 * dp;
            if (gauche < 120 * dp) return;
            ecrit.setTextAlign(Paint.Align.RIGHT);
            ecrire(toile, activite.getString(R.string.st_m_titre), gauche, cy - 8 * dp, 26, Parure.OR, true);
            filet(toile, gauche - 150 * dp, gauche, cy + 2 * dp);
            ecrire(toile, activite.getString(R.string.st_m_sous_titre), gauche, cy + 20 * dp, 12.5f, Parure.SABLE, false);
            ecrire(toile, activite.getString(R.string.st_m_fermer), gauche, cy + 38 * dp, 12.5f, Parure.SABLE, false);
            if (touche != RIEN) {
                ActionTactile action = touche == MILIEU ? ActionTactile.CLAVIER : ACTIONS[touche];
                float droite = cx + rPlateau + 28 * dp;
                ecrit.setTextAlign(Paint.Align.LEFT);
                ecrire(toile, action.nom(activite), droite, cy - 8 * dp, 22, Parure.OR_CLAIR, true);
                filet(toile, droite, droite + 150 * dp, cy + 2 * dp);
                ecrire(toile, action.aide(activite), droite, cy + 20 * dp, 13, Parure.CREME, false);
            }
        }

        /** Un filet d'or qui s'efface aux deux bouts, sous un titre. */
        private void filet(Canvas toile, float de, float a, float y) {
            pinceau.setShader(new android.graphics.LinearGradient(de, 0, a, 0, new int[]{0, Parure.OR, 0}, null,
                    Shader.TileMode.CLAMP));
            pinceau.setStyle(Paint.Style.FILL);
            pinceau.setAlpha(Math.round(255 * ouverture));
            toile.drawRect(de, y, a, y + 1.2f * dp, pinceau);
            pinceau.setShader(null);
        }

        private void ecrire(Canvas toile, String texte, float x, float y, float taille, int couleur, boolean titre) {
            if (titre) Parure.lettres(ecrit, taille * dp, couleur, dp);
            else {
                ecrit.setTypeface(simple);
                ecrit.setTextSize(taille * dp);
                ecrit.setColor(couleur);
                ecrit.setShadowLayer(2 * dp, 0, dp, 0xD0000000);
            }
            ecrit.setAlpha((int) (255 * ouverture));
            toile.drawText(texte, x, y, ecrit);
        }

        /** Une pastille : plaque ronde d'or et de cuir, icône dorée en relief, braise si l'action est active. */
        private void pastille(Canvas toile, float x, float y, float r, int icone, boolean allumee, boolean enfoncee, float vu) {
            if (vu <= .01f) return;
            if (enfoncee) r *= 1.06f;
            int calque = toile.saveLayerAlpha(x - r * 1.5f, y - r * 1.5f, x + r * 1.5f, y + r * 1.5f, Math.round(255 * vu));
            zone.set(x - r, y - r, x + r, y + r);
            Parure.plaque(toile, pinceau, zone, r, dp, Math.max(2.6f * dp, r * .12f), teinte, enfoncee, allumee, face);
            Parure.icone(toile, pinceau, dessin(icone), x, face.centerY(), r * 1.08f, dp, allumee || enfoncee, 255);
            toile.restoreToCount(calque);
        }

        private void nom(Canvas toile, String texte, float x, float y, float largeurMax, float taille, float vu, int couleur) {
            if (vu <= .01f) return;
            Parure.lettres(ecrit, taille * dp, couleur, dp);
            ecrit.setTextAlign(Paint.Align.CENTER);
            float large = ecrit.measureText(texte);
            if (large > largeurMax) ecrit.setTextSize(taille * dp * largeurMax / large);
            ecrit.setAlpha((int) (255 * vu));
            toile.drawText(texte, x, y, ecrit);
        }

        private Drawable dessin(int icone) {
            Drawable d = dessins.get(icone);
            if (d == null) {
                d = activite.getDrawable(icone).mutate();
                dessins.put(icone, d);
            }
            return d;
        }

        /** Ce qu'il y a sous le doigt : une action (son rang), le clavier, le plateau ou dehors. */
        private int sous(float x, float y) {
            float ecart = (float) Math.hypot(x - cx, y - cy);
            if (ecart > rPlateau) return DEHORS;
            if (Math.hypot(x - cx, y - cy + 5 * dp) <= rMilieu * 1.1f) return MILIEU;
            for (int i = 0; i < ACTIONS.length; i++) {
                float a = angle(i);
                if (Math.hypot(x - cx - Math.cos(a) * rCercle, y - cy - Math.sin(a) * rCercle) <= rAction * 1.2f) return i;
            }
            return PLATEAU;
        }

        @Override public boolean onTouchEvent(MotionEvent ev) {
            int geste = ev.getActionMasked();
            if (geste == MotionEvent.ACTION_CANCEL) {
                touche = RIEN;
                invalidate();
                return true;
            }
            int ici = sous(ev.getX(), ev.getY());
            if (geste == MotionEvent.ACTION_UP) {
                touche = RIEN;
                invalidate();
                if (ici == DEHORS) fermer();
                else if (ici == MILIEU || ici >= 0) {
                    performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);
                    choisir(ici == MILIEU ? ActionTactile.CLAVIER : ACTIONS[ici]);
                }
                return true;
            }
            if (geste == MotionEvent.ACTION_DOWN || geste == MotionEvent.ACTION_MOVE) {
                int montre = ici == MILIEU || ici >= 0 ? ici : RIEN;
                if (montre != touche) {
                    if (montre != RIEN) performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK);
                    touche = montre;
                    invalidate();
                }
            }
            return true;
        }
    }
}
