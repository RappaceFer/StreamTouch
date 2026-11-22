package com.limelight.wowtouch;

/**
 * Streaming Touch, Made in Rappace : les commandes à l'écran et leur place par défaut.
 * Les numéros des commandes sont les clés des réglages enregistrés sur le téléphone
 * (place, visible ou non, forme, couleur, icône) : ils ne changent jamais.
 * Tout est en pixels de la vue, sans dépendance Android : on peut le tester sur le PC.
 */
public final class Commandes {
    public static final int ECHAP = 0, CARTE = 1, SACS = 2, MENU = 3, CIBLE = 4, UTILISER = 5, SAUT = 6,
            CLAVIER = 9, METIERS = 12, TALENTS = 13, COUCHE = 14, NOMBRE = 15;
    // 7, 8, 10 et 11 : anciens boutons retirés de l'appli. Leurs numéros restent libres.
    private static final boolean[] RETIRES = new boolean[NOMBRE];
    static { RETIRES[7] = RETIRES[8] = RETIRES[10] = RETIRES[11] = true; }

    /** Vrai pour une commande qui existe encore à l'écran (et se règle). */
    public static boolean existe(int id) { return id >= 0 && id < NOMBRE && !RETIRES[id]; }

    /** Un rectangle, bords gauche, haut, droit et bas. */
    public static final class Cadre {
        public final float gauche, haut, droite, bas;
        public Cadre(float gauche, float haut, float droite, float bas) {
            this.gauche = gauche; this.haut = haut; this.droite = droite; this.bas = bas;
        }
        public boolean contient(float x, float y) { return x >= gauche && x < droite && y >= haut && y < bas; }
        public float largeur() { return droite - gauche; }
        public float hauteur() { return bas - haut; }
    }

    /** Place par défaut de chaque commande (null : pas de place prévue, l'écran lui en trouve une). */
    public final Cadre[] places = new Cadre[NOMBRE];
    /** Joystick de déplacement : centre et rayon. */
    public final float joyX, joyY, rayon;
    /** Taille du nom écrit sous l'icône. */
    public final float police;

    /** Sous ce rapport largeur / hauteur de l'image du jeu, la barre passe en colonne à droite. */
    public static boolean etroit(float rapport) { return rapport < 1.59f; }

    /** Largeur de la barre du haut, en hauteurs d'image, selon le rapport de l'image. */
    static float largeurBarre(float rapport) { return Math.max(.42f, Math.min(.75f, rapport - 1.10f)); }

    /** Une rangée de n boutons : chacun avec son petit écart, plus une place libre à droite (côtés de bouton). */
    static float rangee(int n) { return n * 1.16f + 1.7f; }

    public Commandes(float largeur, float hauteur, float densite,
                     float margeG, float margeH, float margeD, float margeB, Cadre image) {
        float w = Math.max(1, largeur - margeG - margeD), h = Math.max(1, hauteur - margeH - margeB);
        float pouce = Math.min(48 * densite, Math.min(h * .115f, w * .095f));
        float plusPetit = Math.min(40 * densite, pouce);
        float bord = Math.min(22 * densite, w * .025f);
        float haut = margeH + Math.min(12 * densite, h * .018f);
        float droite = margeG + w - bord;
        float imageH = Math.max(1, image.hauteur());
        float rapport = image.largeur() / imageH;
        float bandePouce = margeH + h * .48f;
        int[] barre = {ECHAP, CARTE, SACS, CLAVIER, MENU};
        float cote;
        if (!etroit(rapport)) {
            // En haut à droite, à gauche de la mini-carte, dans la bande que l'addon laisse libre.
            float fin = Math.min(droite, image.droite - .312f * imageH);
            float debut = Math.max(margeG + bord, fin - largeurBarre(rapport) * imageH);
            float bande = image.haut + .14f * imageH - haut;
            float maxi = bande > 0 ? Math.min(pouce, bande) : pouce;
            cote = Math.min(maxi, Math.max(0, fin - debut) / rangee(barre.length));
            if (cote < Math.min(plusPetit, maxi)) {
                barre = new int[]{ECHAP, MENU};
                cote = Math.min(maxi, Math.max(0, fin - debut) / rangee(barre.length));
            }
            float x = fin - cote * rangee(barre.length);
            for (int id : barre) {
                places[id] = new Cadre(x, haut, x + cote, haut + cote);
                x += cote * 1.16f;
            }
        } else {
            // Écran étroit : une colonne contre le bord droit, au-dessus des boutons du pouce.
            float dispo = Math.max(0, bandePouce - pouce * .16f - haut);
            cote = Math.min(pouce, dispo / (barre.length * 1.16f));
            if (cote < plusPetit) {
                barre = new int[]{ECHAP, MENU};
                cote = Math.min(pouce, dispo / (barre.length * 1.16f));
            }
            float y = haut;
            for (int id : barre) {
                places[id] = new Cadre(droite - cote, y, droite, y + cote);
                y += cote * 1.16f;
            }
        }
        // Cible, Utiliser, Sauter : une colonne sous le pouce droit.
        int[] pouces = {CIBLE, UTILISER, SAUT};
        for (int i = 0; i < pouces.length; i++) {
            float y = bandePouce + i * pouce * 1.16f;
            places[pouces[i]] = new Cadre(droite - pouce, y, droite, y + pouce);
        }
        boolean serre = w / h < 1.6f;
        rayon = Math.min(66 * densite, Math.min(h * (serre ? .12f : .13f), w * .13f));
        joyX = margeG + Math.max(rayon * 1.2f + bord, w * .12f);
        joyY = margeH + h * (serre ? .68f : .70f);
        // Couche 2 : à droite du joystick de déplacement.
        float c = pouce * .95f, cx = joyX + rayon * 1.2f + c * .5f + 8 * densite, cy = joyY + rayon * .5f;
        places[COUCHE] = new Cadre(cx - c / 2, cy - c / 2, cx + c / 2, cy + c / 2);
        police = Math.min(11 * densite, cote * .22f);
    }

    /** Où l'image du jeu est dessinée dans la vue (bandes noires comprises), sans étirer l'image. */
    public static Cadre image(float largeur, float hauteur, float largeurJeu, float hauteurJeu) {
        float echelle = Math.min(largeur / largeurJeu, hauteur / hauteurJeu);
        float bandeX = (largeur - largeurJeu * echelle) / 2, bandeY = (hauteur - hauteurJeu * echelle) / 2;
        return new Cadre(bandeX, bandeY, largeur - bandeX, hauteur - bandeY);
    }
}
