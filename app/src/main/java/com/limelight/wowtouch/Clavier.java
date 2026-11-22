package com.limelight.wowtouch;

/** Streaming Touch, Made in Rappace : un clavier pour écrire dans le jeu (le suisse de l'appli, ou celui du téléphone). */
interface Clavier {
    void toggle();
    void show();
    void hide();
    /** Les réglages (taille, opacité) ont changé. */
    void refresh();
}
