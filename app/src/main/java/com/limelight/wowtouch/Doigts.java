package com.limelight.wowtouch;

import java.util.HashMap;
import java.util.Map;

/**
 * Streaming Touch, Made in Rappace : ce que fait chaque doigt posé sur l'écran.
 * - Le joystick de déplacement appuie sur avancer, reculer, gauche, droite.
 * - Un bouton « maintenu » (Sauter, Utiliser, Esc, Carte, Couche 2) garde sa touche tant que le doigt reste.
 * - Un bouton « touché » (Cible, Menu, Clavier, Sacs, Métiers, Talents) agit quand le doigt se lève sans glisser.
 *   Cible maintenue une demi-seconde vise plutôt le cadavre le plus proche.
 * - Le reste de l'écran est la souris : appui = clic, maintien = clic droit, glisser = glisser-déposer,
 *   deux doigts = molette (en les écartant ou en les faisant monter et descendre).
 * Aucune dépendance Android : le PC peut le tester.
 */
public final class Doigts {
    public enum Touche { AVANCER, RECULER, GAUCHE, DROITE, SAUT, CIBLE, UTILISER, SACS, CARTE, ECHAP, MENU,
        CADAVRE, CLAVIER, COURSE, METIERS, TALENTS, COUCHE }
    public enum Endroit { JOYSTICK, ECRAN, SAUT, CIBLE, UTILISER, SACS, CARTE, ECHAP, MENU, CLAVIER, METIERS,
        TALENTS, COUCHE }

    /** Ce que les doigts demandent au jeu. */
    public interface Sortie {
        void touche(Touche touche, boolean appuyee);
        void clic(float x, float y);
        void clicDroit(float x, float y);
        void glisser(float x, float y, boolean bouton);
        void survol(float x, float y);
        void molette(float x, float y, int crans);
    }

    /** Un maintien en cours : où, et jusqu'où l'anneau est rempli (0 à 1). */
    public static final class Maintien {
        public final Endroit endroit;
        public final float x, y, avance;
        Maintien(Endroit endroit, float x, float y, float avance) {
            this.endroit = endroit; this.x = x; this.y = y; this.avance = avance;
        }
    }

    /** Durée d'un maintien : clic droit sur l'écran, cadavre sur Cible. */
    public static final long MAINTIEN_MS = 550;
    /** Part du rayon du joystick avant qu'une direction compte. */
    static final float SEUIL = .24f;

    private static final class Doigt {
        final Endroit endroit;
        final float departX, departY;
        final long pose;
        float x, y;
        boolean glisse, utilise;
        Doigt(Endroit endroit, float x, float y, long pose) {
            this.endroit = endroit; this.pose = pose;
            this.x = departX = x;
            this.y = departY = y;
        }
    }

    private final Map<Integer, Doigt> doigts = new HashMap<>();
    private final Sortie sortie;
    private final float tolerance;
    private int joystick = -1, glisseur = -1, paireA = -1, paireB = -1;
    private float ecartDepart, milieuDepart;
    /** Deux doigts : 0 = pas encore décidé, 1 = pincer, 2 = monter ou descendre ensemble. */
    private int geste;
    private boolean course;
    private final boolean[] enfoncees = new boolean[Touche.values().length];

    public Doigts(Sortie sortie, float tolerance) { this.sortie = sortie; this.tolerance = tolerance; }

    private static boolean maintenu(Endroit e) {
        return e == Endroit.SAUT || e == Endroit.UTILISER || e == Endroit.ECHAP || e == Endroit.CARTE || e == Endroit.COUCHE;
    }

    private static Touche toucheDe(Endroit e) {
        switch (e) {
            case SAUT: return Touche.SAUT;
            case CIBLE: return Touche.CIBLE;
            case UTILISER: return Touche.UTILISER;
            case SACS: return Touche.SACS;
            case CARTE: return Touche.CARTE;
            case ECHAP: return Touche.ECHAP;
            case MENU: return Touche.MENU;
            case CLAVIER: return Touche.CLAVIER;
            case METIERS: return Touche.METIERS;
            case TALENTS: return Touche.TALENTS;
            case COUCHE: return Touche.COUCHE;
            default: return null;
        }
    }

    /** Un doigt se pose. */
    public void pose(int id, Endroit endroit, float x, float y, long maintenant) {
        if (doigts.containsKey(id)) return;
        Doigt doigt = new Doigt(endroit, x, y, maintenant);
        doigts.put(id, doigt);
        if (endroit == Endroit.JOYSTICK) {
            // Un deuxième pouce sur le joystick ne clique jamais dans le jeu en dessous.
            if (joystick != -1) doigt.utilise = true;
            else joystick = id;
        } else if (endroit == Endroit.ECRAN) {
            if (glisseur != -1) doigt.utilise = true;
            else if (paireA == -1) {
                // Un deuxième doigt sur l'écran : les deux deviennent la molette.
                for (Map.Entry<Integer, Doigt> autre : doigts.entrySet()) {
                    Doigt d = autre.getValue();
                    if (autre.getKey() == id || d.endroit != Endroit.ECRAN || d.utilise) continue;
                    paireA = autre.getKey();
                    paireB = id;
                    ecartDepart = (float) Math.hypot(d.x - x, d.y - y);
                    milieuDepart = (d.y + y) / 2;
                    geste = 0;
                    d.utilise = doigt.utilise = true;
                    break;
                }
            }
        }
        majMaintenues();
    }

    /** Le temps passe : les maintiens arrivés au bout agissent. */
    public void avance(long maintenant) {
        if (glisseur != -1 || paireA != -1) return;
        for (Doigt d : doigts.values()) {
            if (d.glisse || d.utilise || maintenant - d.pose < MAINTIEN_MS) continue;
            if (d.endroit == Endroit.CIBLE) {
                d.utilise = true;
                pression(Touche.CADAVRE);
            } else if (d.endroit == Endroit.ECRAN) {
                d.utilise = true;
                sortie.clicDroit(d.x, d.y);
            } else if (d.endroit == Endroit.CLAVIER) {
                // Maintenir Clavier ouvre le menu rond (utile quand le bouton Menu est caché).
                d.utilise = true;
                pression(Touche.MENU);
            }
        }
    }

    /** Le maintien le plus avancé, ou null. */
    public Maintien maintienEnCours(long maintenant) {
        if (glisseur != -1 || paireA != -1) return null;
        Maintien plus = null;
        for (Doigt d : doigts.values()) {
            if ((d.endroit != Endroit.CIBLE && d.endroit != Endroit.ECRAN && d.endroit != Endroit.CLAVIER) || d.glisse || d.utilise) continue;
            float part = Math.min(1, (maintenant - d.pose) / (float) MAINTIEN_MS);
            if (plus == null || part > plus.avance) plus = new Maintien(d.endroit, d.x, d.y, part);
        }
        return plus;
    }

    /** Un doigt appuie encore sur ce bouton (pour le dessiner enfoncé). */
    public boolean appuye(Endroit endroit) {
        for (Doigt d : doigts.values()) if (d.endroit == endroit && !d.utilise && !d.glisse) return true;
        return false;
    }

    /** Course automatique lancée ici, pas encore arrêtée par avancer ou reculer. */
    public boolean enCourse() { return course; }
    /** Course automatique lancée ou arrêtée ailleurs (double appui, menu). */
    public void basculeCourse() { course = !course; }

    /** Avant de lire un mouvement à deux doigts : la position de chacun. */
    public void placePaire(int id, float x, float y) {
        if (id != paireA && id != paireB) return;
        Doigt d = doigts.get(id);
        if (d != null) { d.x = x; d.y = y; }
    }

    /** Un doigt glisse. */
    public void bouge(int id, float x, float y, float joyX, float joyY, float rayon) {
        Doigt d = doigts.get(id);
        if (d == null) return;
        d.x = x;
        d.y = y;
        if (Math.hypot(x - d.departX, y - d.departY) > tolerance) d.glisse = true;
        if (id == paireA || id == paireB) {
            molette();
            return;
        }
        if (id == joystick) {
            float seuil = rayon * SEUIL;
            appuie(Touche.GAUCHE, x - joyX < -seuil);
            appuie(Touche.DROITE, x - joyX > seuil);
            appuie(Touche.AVANCER, y - joyY < -seuil);
            appuie(Touche.RECULER, y - joyY > seuil);
            return;
        }
        if (d.utilise || d.endroit != Endroit.ECRAN || !d.glisse) return;
        if (glisseur == -1) {
            glisseur = id;
            sortie.glisser(d.departX, d.departY, true);
        }
        if (glisseur == id) sortie.survol(x, y);
    }

    private void molette() {
        Doigt a = doigts.get(paireA), b = doigts.get(paireB);
        if (a == null || b == null) return; // un des deux doigts est déjà levé
        float ecart = (float) Math.hypot(a.x - b.x, a.y - b.y), milieu = (a.y + b.y) / 2;
        if (geste == 0) {
            if (Math.abs(ecart - ecartDepart) > tolerance * 3) geste = 1;
            else if (Math.abs(milieu - milieuDepart) > tolerance * 3) geste = 2;
            else return;
        }
        float ecartement = geste == 1 ? ecart - ecartDepart : milieu - milieuDepart;
        int crans = (int) (ecartement / (tolerance * 4));
        if (crans == 0) return;
        sortie.molette((a.x + b.x) / 2, milieu, Math.max(-4, Math.min(4, crans)));
        if (geste == 1) ecartDepart = ecart;
        else milieuDepart = milieu;
    }

    /** Un doigt se lève. */
    public void leve(int id) {
        Doigt d = doigts.remove(id);
        if (d == null) return;
        if (id == paireA || id == paireB) paireA = paireB = -1;
        if (id == glisseur) {
            sortie.glisser(d.x, d.y, false);
            glisseur = -1;
        }
        if (id == joystick) {
            joystick = -1;
            for (Touche t : new Touche[]{Touche.AVANCER, Touche.RECULER, Touche.GAUCHE, Touche.DROITE}) appuie(t, false);
        }
        if (!d.utilise && !d.glisse) {
            if (d.endroit == Endroit.ECRAN) sortie.clic(d.x, d.y);
            else if (!maintenu(d.endroit) && d.endroit != Endroit.JOYSTICK) pression(toucheDe(d.endroit));
        }
        majMaintenues();
    }

    /** Les boutons maintenus gardent leur touche tant qu'un doigt est dessus. */
    private void majMaintenues() {
        for (Endroit e : Endroit.values()) {
            if (!maintenu(e)) continue;
            boolean dessus = false;
            for (Doigt d : doigts.values()) if (d.endroit == e) dessus = true;
            appuie(toucheDe(e), dessus);
        }
    }

    private void pression(Touche t) {
        if (t == null) return;
        sortie.touche(t, true);
        sortie.touche(t, false);
    }

    private void appuie(Touche t, boolean bas) {
        if (enfoncees[t.ordinal()] == bas) return;
        enfoncees[t.ordinal()] = bas;
        // Le jeu arrête la course automatique quand on avance ou recule (pas en pas de côté).
        if (bas && (t == Touche.AVANCER || t == Touche.RECULER)) course = false;
        sortie.touche(t, bas);
    }

    /** Tout lâcher (perte du focus, geste annulé par Android, changement de mode). */
    public void annule() {
        if (glisseur != -1) {
            Doigt d = doigts.get(glisseur);
            if (d != null) sortie.glisser(d.x, d.y, false);
        }
        doigts.clear();
        joystick = glisseur = paireA = paireB = -1;
        for (Touche t : Touche.values()) appuie(t, false);
    }
}
