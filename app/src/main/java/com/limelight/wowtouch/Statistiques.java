package com.limelight.wowtouch;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Canvas;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.preference.PreferenceManager;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Streaming Touch, Made in Rappace : les statistiques du stream dans un petit panneau aux couleurs du thème.
 * Chaque valeur a une pastille : vert = parfait, ambre = correct, rouge = à surveiller.
 * On le glisse où on veut (la place est gardée) ; un simple toucher le réduit à une ligne, ou le rouvre.
 */
public final class Statistiques extends View {
    private static final int VERT = 0xFF5BD97A, AMBRE = 0xFFF2C14E, ROUGE = 0xFFFF6A5A;
    private static final Pattern NOMBRE = Pattern.compile("(\\d+(?:[.,]\\d+)?)");

    private final float dp;
    private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final RectF r = new RectF();
    private final List<String> noms = new ArrayList<>(), valeurs = new ArrayList<>();
    private final List<Integer> couleurs = new ArrayList<>();
    private String resume = "";
    private int couleurResume = VERT;
    private boolean reduit;
    private float departX, departY, posX, posY;
    private boolean glisse;

    public Statistiques(Context c) {
        super(c);
        dp = c.getResources().getDisplayMetrics().density;
        reduit = prefs().getBoolean("st_stats_reduit", false);
        setVisibility(GONE);
        setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
    }

    private SharedPreferences prefs() { return PreferenceManager.getDefaultSharedPreferences(getContext()); }

    /** Montre ou cache le panneau (le passe au-dessus des commandes tactiles). */
    public void montrer(int visibilite) {
        setVisibility(visibilite);
        if (visibilite == VISIBLE) { bringToFront(); placer(); }
    }

    /** Remet le panneau en haut à gauche. */
    public void replacer() {
        prefs().edit().remove("st_stats_x").remove("st_stats_y").apply();
        placer();
    }

    private void placer() {
        post(() -> {
            View parent = (View) getParent();
            if (parent == null) return;
            float fx = prefs().getFloat("st_stats_x", -1), fy = prefs().getFloat("st_stats_y", -1);
            float x = fx < 0 ? 10 * dp : fx * parent.getWidth(), y = fy < 0 ? 10 * dp : fy * parent.getHeight();
            bouger(x, y);
        });
    }

    private void bouger(float x, float y) {
        View parent = (View) getParent();
        if (parent == null) return;
        setX(Math.max(0, Math.min(parent.getWidth() - getWidth(), x)));
        setY(Math.max(0, Math.min(parent.getHeight() - getHeight(), y)));
    }

    /** Le texte des statistiques de Moonlight, une ligne « Nom : valeur » par mesure. */
    public void texte(String brut) {
        noms.clear(); valeurs.clear(); couleurs.clear();
        String fps = null, latence = null, pertes = null;
        int cFps = VERT, cLat = VERT, cPer = VERT;
        for (String ligne : brut.split("\n")) {
            ligne = ligne.trim();
            if (ligne.isEmpty()) continue;
            int i = ligne.indexOf(':');
            String nom = i > 0 ? ligne.substring(0, i).trim() : "";
            String val = i > 0 ? ligne.substring(i + 1).trim() : ligne;
            int c = Parure.SABLE;
            if (val.contains("FPS")) {
                float f = dernier(val);
                c = f >= 55 ? VERT : f >= 30 ? AMBRE : ROUGE;
                fps = Math.round(f) + " FPS"; cFps = c;
            } else if (val.contains("%")) {
                float f = premier(val);
                c = f <= .5f ? VERT : f <= 2 ? AMBRE : ROUGE;
                pertes = val; cPer = c;
            } else if (val.contains("ms")) {
                if (val.contains("(")) {
                    float f = premier(val);
                    c = f <= 25 ? VERT : f <= 60 ? AMBRE : ROUGE;
                    latence = Math.round(f) + " ms"; cLat = c;
                } else {
                    float f = dernier(val);
                    c = f <= 8 ? VERT : f <= 16 ? AMBRE : ROUGE;
                }
            }
            noms.add(nom); valeurs.add(val); couleurs.add(c);
        }
        StringBuilder b = new StringBuilder();
        if (fps != null) b.append(fps);
        if (latence != null) b.append(b.length() > 0 ? "   " : "").append(latence);
        if (pertes != null) b.append(b.length() > 0 ? "   " : "").append(pertes);
        resume = b.toString();
        couleurResume = cFps == ROUGE || cLat == ROUGE || cPer == ROUGE ? ROUGE
                : cFps == AMBRE || cLat == AMBRE || cPer == AMBRE ? AMBRE : VERT;
        requestLayout();
        invalidate();
    }

    private static float premier(String s) {
        Matcher m = NOMBRE.matcher(s);
        return m.find() ? Float.parseFloat(m.group(1).replace(',', '.')) : 0;
    }

    private static float dernier(String s) {
        Matcher m = NOMBRE.matcher(s);
        float v = 0;
        while (m.find()) v = Float.parseFloat(m.group(1).replace(',', '.'));
        return v;
    }

    // ---------------------------------------------------------------- Taille et dessin

    private float marge() { return 10 * dp; }
    private float ligneH() { return 17 * dp; }
    private float enteteH() { return 22 * dp; }

    @Override protected void onMeasure(int largeur, int hauteur) {
        p.setTypeface(Typeface.DEFAULT);
        p.setTextSize(11.5f * dp);
        float w;
        int h;
        if (reduit) {
            p.setTypeface(Typeface.DEFAULT_BOLD);
            w = 24 * dp + p.measureText(resume.isEmpty() ? "— FPS" : resume) + marge();
            h = Math.round(28 * dp);
        } else {
            float max = 0;
            for (int i = 0; i < noms.size(); i++) {
                p.setTypeface(Typeface.DEFAULT);
                float a = p.measureText(noms.get(i));
                p.setTypeface(Typeface.DEFAULT_BOLD);
                float b = p.measureText(valeurs.get(i));
                max = Math.max(max, a + b + 30 * dp);
            }
            p.setTypeface(Parure.LETTRES);
            p.setTextSize(11 * dp);
            max = Math.max(max, p.measureText("✦ STREAMTOUCH   Made in Rappace") + 6 * dp);
            w = max + 2 * marge();
            h = Math.round(enteteH() + marge() + noms.size() * ligneH() + marge() * .6f);
        }
        int limite = (int) (getResources().getDisplayMetrics().widthPixels * .7f);
        setMeasuredDimension(Math.min(limite, Math.round(w)), h);
    }

    @Override protected void onDraw(Canvas t) {
        float w = getWidth(), h = getHeight(), coin = 12 * dp;
        r.set(dp, dp, w - dp, h - dp);
        // Le fond : cuir du thème un peu transparent, cadre de métal en dégradé.
        p.setShader(new LinearGradient(0, 0, 0, h, ButtonStyles.alpha(Parure.CUIR_HAUT, 0xE0), ButtonStyles.alpha(Parure.CUIR_BAS, 0xE8),
                Shader.TileMode.CLAMP));
        t.drawRoundRect(r, coin, coin, p);
        p.setShader(new LinearGradient(0, 0, 0, h, new int[]{Parure.OR_CLAIR, Parure.OR, Parure.OR_MOYEN}, null, Shader.TileMode.CLAMP));
        p.setStyle(Paint.Style.STROKE);
        p.setStrokeWidth(1.6f * dp);
        t.drawRoundRect(r, coin, coin, p);
        p.setShader(null);
        p.setStyle(Paint.Style.FILL);

        if (reduit) {
            pastille(t, 14 * dp, h / 2, couleurResume);
            p.setTypeface(Typeface.DEFAULT_BOLD);
            p.setTextSize(11.5f * dp);
            p.setColor(Parure.CREME);
            t.drawText(resume.isEmpty() ? "— FPS" : resume, 24 * dp, h / 2 - (p.ascent() + p.descent()) / 2, p);
            return;
        }
        float x = marge(), y = enteteH();
        p.setTypeface(Parure.LETTRES);
        p.setTextSize(11 * dp);
        p.setColor(Parure.OR_CLAIR);
        p.setLetterSpacing(.12f);
        t.drawText("✦ STREAMTOUCH", x, y - 5 * dp, p);
        p.setLetterSpacing(0);
        p.setTypeface(Typeface.create(Typeface.SERIF, Typeface.ITALIC));
        p.setTextSize(10 * dp);
        p.setColor(Parure.OR);
        p.setTextAlign(Paint.Align.RIGHT);
        t.drawText("Made in Rappace", w - marge(), y - 5 * dp, p);
        p.setTextAlign(Paint.Align.LEFT);
        p.setShader(new LinearGradient(x, 0, w - marge(), 0, new int[]{ButtonStyles.alpha(Parure.OR, 0xB0), ButtonStyles.alpha(Parure.OR, 0)},
                null, Shader.TileMode.CLAMP));
        t.drawRect(x, y, w - marge(), y + dp, p);
        p.setShader(null);
        y += marge() * .9f;
        p.setTextSize(11.5f * dp);
        for (int i = 0; i < noms.size(); i++) {
            float base = y + ligneH() * i + ligneH() * .7f;
            pastille(t, x + 4 * dp, base - 4 * dp, couleurs.get(i));
            p.setTypeface(Typeface.DEFAULT);
            p.setColor(ButtonStyles.alpha(Parure.CREME, 0xD0));
            t.drawText(noms.get(i), x + 14 * dp, base, p);
            p.setTypeface(Typeface.DEFAULT_BOLD);
            int c = couleurs.get(i);
            p.setColor(c == Parure.SABLE ? Parure.OR_CLAIR : c);
            p.setTextAlign(Paint.Align.RIGHT);
            t.drawText(valeurs.get(i), w - marge(), base, p);
            p.setTextAlign(Paint.Align.LEFT);
        }
    }

    private void pastille(Canvas t, float cx, float cy, int c) {
        p.setColor(ButtonStyles.alpha(c, 0x55));
        t.drawCircle(cx, cy, 5 * dp, p);
        p.setColor(c);
        t.drawCircle(cx, cy, 3 * dp, p);
    }

    // ---------------------------------------------------------------- Glisser, réduire

    @Override public boolean onTouchEvent(MotionEvent e) {
        switch (e.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                departX = e.getRawX(); departY = e.getRawY(); posX = getX(); posY = getY(); glisse = false;
                return true;
            case MotionEvent.ACTION_MOVE:
                float dx = e.getRawX() - departX, dy = e.getRawY() - departY;
                if (!glisse && Math.hypot(dx, dy) > 8 * dp) glisse = true;
                if (glisse) bouger(posX + dx, posY + dy);
                return true;
            case MotionEvent.ACTION_UP:
                View parent = (View) getParent();
                if (glisse && parent != null && parent.getWidth() > 0) {
                    prefs().edit().putFloat("st_stats_x", getX() / parent.getWidth())
                            .putFloat("st_stats_y", getY() / parent.getHeight()).apply();
                } else if (!glisse) {
                    reduit = !reduit;
                    prefs().edit().putBoolean("st_stats_reduit", reduit).apply();
                    requestLayout();
                    invalidate();
                }
                return true;
            default:
                return true;
        }
    }
}
