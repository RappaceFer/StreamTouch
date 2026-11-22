package com.limelight.wowtouch;

import com.limelight.R;

import android.app.Activity;
import android.content.Context;
import android.text.Editable;
import android.text.InputType;
import android.text.TextWatcher;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * Streaming Touch, Made in Rappace : le clavier du téléphone (Gboard, Samsung...) utilisé comme clavier du PC.
 * Chaque lettre part au jeu comme le caractère qu'elle est, dans n'importe quelle langue, accents compris.
 * Effacer, Entrée et Échap partent comme de vraies touches. Une barre or et cuir en haut montre ce qu'on tape.
 */
final class ClavierTelephone implements Clavier {
    private final Activity activite;
    private final MoonlightTouchBridge pc;
    private final FrameLayout parent;
    private final float dp;
    private LinearLayout barre;
    private EditText saisie;
    /** Ce qui a déjà été envoyé au jeu, pour n'envoyer que la différence quand le texte change. */
    private String envoye = "";
    private boolean silence;

    ClavierTelephone(Activity activite, MoonlightTouchBridge pc, FrameLayout parent) {
        this.activite = activite;
        this.pc = pc;
        this.parent = parent;
        dp = activite.getResources().getDisplayMetrics().density;
    }

    private int dp(float v) { return Math.round(v * dp); }

    @Override public void toggle() { if (barre != null && barre.getParent() != null) hide(); else show(); }

    @Override public void show() {
        if (barre == null) construire();
        if (barre.getParent() == null) parent.addView(barre, place());
        vider();
        saisie.requestFocus();
        InputMethodManager clavier = (InputMethodManager) activite.getSystemService(Context.INPUT_METHOD_SERVICE);
        saisie.post(() -> clavier.showSoftInput(saisie, InputMethodManager.SHOW_IMPLICIT));
    }

    @Override public void hide() {
        if (barre == null || barre.getParent() == null) return;
        InputMethodManager clavier = (InputMethodManager) activite.getSystemService(Context.INPUT_METHOD_SERVICE);
        clavier.hideSoftInputFromWindow(saisie.getWindowToken(), 0);
        saisie.clearFocus();
        parent.removeView(barre);
    }

    @Override public void refresh() {}

    private FrameLayout.LayoutParams place() {
        int largeur = Math.min(activite.getResources().getDisplayMetrics().widthPixels - dp(24), dp(620));
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(largeur, dp(54), Gravity.TOP | Gravity.CENTER_HORIZONTAL);
        lp.topMargin = dp(8);
        return lp;
    }

    private void construire() {
        barre = new LinearLayout(activite);
        barre.setOrientation(LinearLayout.HORIZONTAL);
        barre.setGravity(Gravity.CENTER_VERTICAL);
        barre.setBackground(new Parure.Fond(dp, 14 * dp, 2.8f * dp, false));
        barre.setPadding(dp(12), dp(6), dp(8), dp(8));
        saisie = new EditText(activite);
        saisie.setSingleLine(true);
        saisie.setBackground(null);
        saisie.setTextColor(Parure.CREME);
        saisie.setHintTextColor(0x99C9B48A);
        saisie.setHint(activite.getString(R.string.st_t_aide));
        saisie.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        saisie.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
        saisie.setImeOptions(EditorInfo.IME_ACTION_SEND | EditorInfo.IME_FLAG_NO_EXTRACT_UI | EditorInfo.IME_FLAG_NO_FULLSCREEN);
        saisie.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int debut, int avant, int apres) {}
            @Override public void onTextChanged(CharSequence s, int debut, int avant, int apres) {}
            @Override public void afterTextChanged(Editable s) { if (!silence) envoyer(s.toString()); }
        });
        saisie.setOnEditorActionListener((v, action, evenement) -> {
            boolean entree = action == EditorInfo.IME_ACTION_SEND || action == EditorInfo.IME_ACTION_DONE
                    || (evenement != null && evenement.getKeyCode() == KeyEvent.KEYCODE_ENTER
                    && evenement.getAction() == KeyEvent.ACTION_DOWN);
            if (!entree) return false;
            touche(TouchKey.KEY_ENTER);
            vider();
            return true;
        });
        // Effacer quand le champ est déjà vide : on efface quand même dans le jeu.
        saisie.setOnKeyListener((v, code, evenement) -> {
            if (code != KeyEvent.KEYCODE_DEL || evenement.getAction() != KeyEvent.ACTION_DOWN) return false;
            if (saisie.length() > 0) return false;
            touche(TouchKey.KEY_BACK);
            return true;
        });
        barre.addView(saisie, new LinearLayout.LayoutParams(0, -1, 1));
        barre.addView(bouton("↵", activite.getString(R.string.st_t_entree), () -> { touche(TouchKey.KEY_ENTER); vider(); }), carre());
        barre.addView(bouton("Esc", activite.getString(R.string.st_t_echap), () -> { touche(TouchKey.KEY_ESC); vider(); }), carre());
        barre.addView(bouton("✕", activite.getString(R.string.st_t_fermer), this::hide), carre());
    }

    private LinearLayout.LayoutParams carre() {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(dp(46), dp(38));
        lp.leftMargin = dp(4);
        return lp;
    }

    private TextView bouton(String texte, String description, Runnable quand) {
        TextView b = new TextView(activite);
        b.setText(texte);
        b.setContentDescription(description);
        b.setGravity(Gravity.CENTER);
        b.setTypeface(Parure.LETTRES);
        b.setTextColor(Parure.OR_CLAIR);
        b.setTextSize(TypedValue.COMPLEX_UNIT_SP, texte.length() > 1 ? 13 : 17);
        b.setShadowLayer(2 * dp, 0, dp, 0xD0000000);
        b.setBackground(new Parure.Fond(dp, 9 * dp, 2.2f * dp, true));
        b.setClickable(true);
        b.setOnClickListener(v -> quand.run());
        return b;
    }

    private void touche(TouchKey t) {
        pc.injectKeyPress(t);
        pc.injectKeyRelease(t);
    }

    /** Le champ repart à vide sans rien effacer dans le jeu (après Entrée ou Échap). */
    private void vider() {
        silence = true;
        saisie.setText("");
        silence = false;
        envoye = "";
    }

    /** Envoie seulement ce qui a changé : des effacements pour ce qui a disparu, puis le nouveau texte. */
    private void envoyer(String texte) {
        int commun = 0, max = Math.min(texte.length(), envoye.length());
        while (commun < max && texte.charAt(commun) == envoye.charAt(commun)) commun++;
        int effacer = envoye.codePointCount(commun, envoye.length());
        for (int i = 0; i < effacer; i++) touche(TouchKey.KEY_BACK);
        if (commun < texte.length()) pc.injectText(texte.substring(commun));
        envoye = texte;
    }

    /** Pour EcranTactile : le clavier est-il affiché ? */
    boolean visible() { return barre != null && barre.getParent() != null && barre.getVisibility() == View.VISIBLE; }
}
