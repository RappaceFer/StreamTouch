package com.limelight.wowtouch;

/**
 * CH : appui bref et double appui sur un joystick, sans dépendance Android.
 * Joystick droit : appui bref = cibler un ennemi, deux appuis rapides = sauter.
 * Joystick gauche : appui bref = Use, deux appuis rapides = course auto.
 * L'appui bref attend la fin du délai du double appui, pour ne jamais partir juste avant l'action double.
 */
final class StickTapGesture {
    static final long DOUBLE_MS = 350, TAP_MS = 400;
    private long lastDown = -1000, downAt;
    private boolean second, moved;

    /** Un doigt se pose. Vrai si c'est le deuxième appui rapide : il faut sauter. */
    boolean down(long now) {
        downAt = now;
        moved = false;
        if (now - lastDown < DOUBLE_MS) {
            lastDown = -1000;
            second = true;
            return true;
        }
        lastDown = now;
        second = false;
        return false;
    }

    /** Le doigt glisse : cet appui tourne la caméra. Ce n'est ni un appui bref, ni la moitié d'un double appui. */
    void moved() {
        moved = true;
        lastDown = -1000;
    }

    /** Le doigt se lève. Délai avant l'action d'un appui bref, ou -1 s'il ne faut rien faire. */
    long up(long now) {
        if (second || moved || now - downAt > TAP_MS) return -1;
        return Math.max(0, DOUBLE_MS - (now - downAt));
    }

    /** Tout oublier (perte du focus, changement de mode). */
    void reset() {
        lastDown = -1000;
        second = false;
        moved = false;
    }
}
