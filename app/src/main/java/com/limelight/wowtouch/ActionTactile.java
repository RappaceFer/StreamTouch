package com.limelight.wowtouch;

import com.limelight.R;

/** Streaming Touch, Made in Rappace : ce que propose le menu rond de l'appli. */
enum ActionTactile {
    MODE_MANETTE(R.string.st_a_manette, R.drawable.st_ic_arrows_in_simple, R.string.st_a_manette_aide),
    BOUTONS(R.string.st_a_boutons, R.drawable.st_ic_squares_four, R.string.st_a_boutons_aide),
    DEPLACER(R.string.st_a_deplacer, R.drawable.st_ic_hand_grabbing, R.string.st_a_deplacer_aide),
    REGLAGES(R.string.st_a_reglages, R.drawable.st_ic_sliders_horizontal, R.string.st_a_reglages_aide),
    COURSE_AUTO(R.string.st_a_course, R.drawable.st_ic_person_simple_run, R.string.st_a_course_aide),
    PLONGER(R.string.st_plonger, R.drawable.st_ic_arrow_fat_line_down, R.string.st_a_plonger_aide),
    MAJ(R.string.st_maj, R.drawable.st_ic_arrow_fat_up, R.string.st_a_modif_aide),
    CTRL(0, R.drawable.st_ic_control, R.string.st_a_modif_aide),
    ALT(0, R.drawable.st_ic_option, R.string.st_a_modif_aide),
    GUIDE(R.string.st_a_guide, R.drawable.st_ic_hand_pointing, R.string.st_a_guide_aide),
    A_PROPOS(R.string.st_a_propos, R.drawable.st_ic_info, 0),
    CLAVIER(R.string.st_clavier, R.drawable.st_ic_keyboard, R.string.st_a_clavier_aide);

    /** Numéros des textes (0 = le même dans toutes les langues : Ctrl, Alt, Made in Rappace). */
    private final int texteNom, texteAide;
    final int icone;
    ActionTactile(int nom, int icone, int aide) { texteNom = nom; this.icone = icone; texteAide = aide; }

    String nom(android.content.Context c) {
        return texteNom != 0 ? c.getString(texteNom) : this == CTRL ? "Ctrl" : "Alt";
    }

    String aide(android.content.Context c) { return texteAide != 0 ? c.getString(texteAide) : "Made in Rappace"; }

    /** Celui qui exécute les actions : l'écran tactile. */
    interface Hote {
        void executer(ActionTactile action);
        /** Ce qui est allumé en ce moment : modificateur armé, plongée, course auto. */
        boolean estActive(ActionTactile action);
    }
}
