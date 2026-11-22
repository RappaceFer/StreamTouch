package com.limelight.wowtouch;

import android.app.Activity;
import android.app.Dialog;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;

/** Streaming Touch, Made in Rappace : une fenêtre transparente par-dessus le jeu, sans les barres d'Android. */
final class PleinEcran {
    private PleinEcran() {}

    static Dialog ouvrir(Activity activite, View contenu) {
        // Thème plein écran d'Android lui-même ; transparence et animation réglées ici, sans fichier de style.
        Dialog fenetre = new Dialog(activite, android.R.style.Theme_Material_NoActionBar_Fullscreen);
        fenetre.setContentView(contenu, new ViewGroup.LayoutParams(-1, -1));
        Window w = fenetre.getWindow();
        w.setLayout(-1, -1);
        w.setWindowAnimations(android.R.style.Animation_Dialog);
        w.setBackgroundDrawable(new ColorDrawable(0));
        w.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);
        int api = Build.VERSION.SDK_INT;
        if (api >= 28) {
            WindowManager.LayoutParams reglage = w.getAttributes();
            reglage.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
            w.setAttributes(reglage);
        }
        // Sans focus le temps de s'afficher : sinon Android remontre ses barres par-dessus le jeu.
        int sansFocus = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;
        w.addFlags(sansFocus);
        fenetre.show();
        if (api >= 30) {
            w.setDecorFitsSystemWindows(false);
            WindowInsetsController barres = w.getInsetsController();
            if (barres != null) {
                barres.hide(WindowInsets.Type.systemBars());
                barres.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            int jeu = activite.getWindow().getDecorView().getSystemUiVisibility();
            w.getDecorView().setSystemUiVisibility(jeu);
        }
        w.clearFlags(sansFocus);
        return fenetre;
    }
}
