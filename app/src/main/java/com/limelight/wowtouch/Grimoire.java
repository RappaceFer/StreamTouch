package com.limelight.wowtouch;

import android.animation.ValueAnimator;
import android.app.AlertDialog;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.ColorFilter;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PixelFormat;
import android.graphics.RadialGradient;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.DecelerateInterpolator;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.TextView;

import com.limelight.Game;
import com.limelight.R;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.function.Consumer;
import java.util.function.IntConsumer;

/**
 * Streaming Touch, Made in Rappace : le Grimoire, panneau qui glisse depuis la droite pendant le stream.
 * Trois pages (Commandes, Image, Session), en cuir et or : tout ce qui se règle pendant la partie, sans quitter le jeu.
 * Ouvert par le menu rond ; on le ferme en touchant le jeu à gauche, par la croix ou par le bouton retour.
 */
public final class Grimoire extends FrameLayout {
    private int CUIR_HAUT, CUIR_BAS, CARTE, CARTE_BORD;
    private static final int ROUGE = 0xFFE06A55;

    private void couleurs() {
        CUIR_HAUT = Parure.t(0xFF2B1A0D);
        CUIR_BAS = Parure.t(0xFF120A04);
        CARTE = Parure.t(0xCC24160A);
        CARTE_BORD = Parure.t(0x55D9A84A);
    }

    private final Game jeu;
    private final EcranTactile ecran;
    private final float dp;
    private final boolean francais = Locale.getDefault().getLanguage().equals("fr");
    private LinearLayout panneau, onglets, contenu;
    private ScrollView defile;
    private View voile;
    private final List<View> medaillons = new ArrayList<>();
    private int page;
    private Runnable sousPage;
    private String sousTitre;
    private boolean ouvert;
    private ValueAnimator animation;

    public Grimoire(Game jeu, EcranTactile ecran) {
        super(jeu);
        this.jeu = jeu;
        this.ecran = ecran;
        dp = jeu.getResources().getDisplayMetrics().density;
        setVisibility(GONE);
        construire();
    }

    /** Fabrique tout le panneau (aussi après un changement de thème). */
    private void construire() {
        Game jeu = this.jeu;
        Parure.theme(jeu);
        removeAllViews();
        medaillons.clear();
        couleurs();

        voile = new View(jeu);
        voile.setBackgroundColor(Parure.t(0x99000000));
        voile.setOnClickListener(v -> fermer());
        addView(voile, new LayoutParams(-1, -1));

        panneau = new LinearLayout(jeu);
        panneau.setOrientation(LinearLayout.VERTICAL);
        panneau.setBackground(new Reliure(dp));
        panneau.setClickable(true);
        panneau.setPadding(px(26), px(14), px(16), px(10));
        addView(panneau, new LayoutParams(-2, -1, Gravity.END));

        panneau.addView(entete());
        onglets = new LinearLayout(jeu);
        onglets.setGravity(Gravity.CENTER);
        onglets.setPadding(0, px(10), 0, px(6));
        panneau.addView(onglets, new LinearLayout.LayoutParams(-1, -2));
        String[][] noms = {{"Commandes", "Controls"}, {"Image", "Picture"}, {"Session", "Session"}};
        int[] icones = {R.drawable.st_ic_hand_pointing, R.drawable.st_ic_palette, R.drawable.st_ic_app_window};
        for (int i = 0; i < 3; i++) {
            final int n = i;
            View m = medaillon(icones[i], tr(noms[i][0], noms[i][1]), () -> montrerPage(n));
            medaillons.add(m);
            // Hauteur fixe : une View simple en « wrap_content » prendrait toute la place et cacherait les pages.
            onglets.addView(m, new LinearLayout.LayoutParams(0, px(80), 1));
        }

        defile = new ScrollView(jeu);
        defile.setVerticalScrollBarEnabled(false);
        defile.setOverScrollMode(OVER_SCROLL_NEVER);
        contenu = new LinearLayout(jeu);
        contenu.setOrientation(LinearLayout.VERTICAL);
        contenu.setPadding(0, 0, px(4), px(24));
        defile.addView(contenu);
        panneau.addView(defile, new LinearLayout.LayoutParams(-1, 0, 1));

        TextView signature = texte("StreamTouch · Made in Rappace", 10, Parure.t(0x99FAEAB4), false);
        signature.setGravity(Gravity.CENTER);
        signature.setLetterSpacing(.18f);
        signature.setPadding(0, px(6), 0, 0);
        panneau.addView(signature);
    }

    // ------------------------------------------------------------------------------------------------ Ouvrir, fermer

    public boolean ouvert() { return ouvert; }

    /** Refait tout le panneau dans le nouveau thème, et rouvre la même page ou le même sous-menu. */
    private void rebatir() {
        Runnable sous = sousPage;
        String titre = sousTitre;
        int largeur = panneau.getLayoutParams().width;
        construire();
        panneau.getLayoutParams().width = largeur;
        voile.setAlpha(1f);
        montrerPage(page);
        if (sous != null) ouvrirSous(titre, sous);
    }

    public void ouvrir() {
        if (ouvert) return;
        ouvert = true;
        int large = Math.max(px(380), Math.round(getRootView().getWidth() * .44f));
        if (getRootView().getWidth() > 0) large = Math.min(large, Math.round(getRootView().getWidth() * .92f));
        panneau.getLayoutParams().width = large;
        panneau.requestLayout();
        setVisibility(VISIBLE);
        bringToFront();
        montrerPage(page);
        glisser(1f);
    }

    public void fermer() {
        if (!ouvert) return;
        ouvert = false;
        glisser(0f);
    }

    private void glisser(float vers) {
        if (animation != null) animation.cancel();
        float depuis = voile.getAlpha();
        if (vers == 1f && getVisibility() == VISIBLE && depuis >= 1f) depuis = 0f;
        animation = ValueAnimator.ofFloat(vers == 1f ? 0f : 1f, vers);
        animation.setDuration(vers == 1f ? 320 : 220);
        animation.setInterpolator(new DecelerateInterpolator(2f));
        animation.addUpdateListener(a -> {
            float t = (float) a.getAnimatedValue();
            voile.setAlpha(t);
            int large = panneau.getWidth() > 0 ? panneau.getWidth() : px(420);
            panneau.setTranslationX((1f - t) * (large + px(20)));
        });
        animation.addListener(new android.animation.AnimatorListenerAdapter() {
            @Override public void onAnimationEnd(android.animation.Animator a) {
                if (!ouvert) setVisibility(GONE);
            }
        });
        animation.start();
    }

    @Override public boolean onTouchEvent(MotionEvent e) { return ouvert; }

    // ------------------------------------------------------------------------------------------------ Les pages

    private void montrerPage(int n) {
        page = n;
        sousPage = null;
        for (int i = 0; i < medaillons.size(); i++) medaillons.get(i).setSelected(i == n);
        for (View m : medaillons) m.invalidate();
        contenu.removeAllViews();
        if (n == 0) pageCommandes();
        else if (n == 1) pageImage();
        else pageSession();
        defile.scrollTo(0, 0);
    }

    /** Ouvre un sous-menu : une barre « ‹ Retour » puis son contenu. Le bouton retour d'Android y revient aussi. */
    private void ouvrirSous(String titre, Runnable construire) {
        sousPage = construire;
        sousTitre = titre;
        dessinerSous();
        defile.scrollTo(0, 0);
    }

    private void dessinerSous() {
        contenu.removeAllViews();
        LinearLayout barre = carte();
        TextView fleche = texte("‹", 26, Parure.OR_CLAIR, true);
        fleche.setPadding(0, 0, px(12), px(3));
        barre.addView(fleche);
        LinearLayout col = new LinearLayout(getContext());
        col.setOrientation(LinearLayout.VERTICAL);
        TextView retour = texte(tr("RETOUR", "BACK"), 10, Parure.OR, true);
        retour.setLetterSpacing(.2f);
        col.addView(retour);
        TextView t = texte(sousTitre, 17, Parure.OR_CLAIR, true);
        t.setTypeface(Parure.LETTRES);
        col.addView(t);
        barre.addView(col, new LinearLayout.LayoutParams(0, -2, 1));
        barre.setOnClickListener(v -> montrerPage(page));
        contenu.addView(barre);
        sousPage.run();
    }

    /** Redessine la page ou le sous-menu ouvert (après un choix qui change les textes). */
    private void redessiner() {
        int y = defile.getScrollY();
        if (sousPage != null) dessinerSous(); else montrerPage(page);
        defile.post(() -> defile.scrollTo(0, y));
    }

    /** Le bouton retour d'Android : sort du sous-menu ; rend false s'il n'y en avait pas. */
    public boolean retour() {
        if (sousPage == null) return false;
        montrerPage(page);
        return true;
    }

    // ---------------------------------------------------------------- Commandes

    private void pageCommandes() {
        Context c = getContext();
        // Tactile d'abord, manette ensuite : maintenant, et au lancement du jeu.
        String[] modes = {tr("Mode tactile", "Touch mode"), tr("Mode manette", "Controller mode")};
        String[] aidesModes = {tr("Joysticks et boutons à l'écran.", "Sticks and buttons on screen."),
                tr("Joysticks et boutons cachés : une vraie manette joue.", "Touch controls hidden: a real controller plays.")};
        rubrique(tr("Mode", "Mode"));
        liste(modes, aidesModes, ecran.modeManette() ? 1 : 0, i -> {
            if ((i == 1) != ecran.modeManette()) { ecran.executer(ActionTactile.MODE_MANETTE); fermer(); }
        });
        rubrique(tr("Au lancement du jeu", "When the game starts"));
        liste(modes, null, TouchConfig.demarrageManette(c) ? 1 : 0, i -> TouchConfig.setDemarrageManette(c, i == 1));

        rubrique(tr("Réglages", "Settings"));
        sousMenu(R.drawable.st_ic_keyboard, GEMME_BLEU, tr("Clavier", "Keyboard"), Disposition.actuelle(c).titre, this::sousClavier);
        sousMenu(R.drawable.st_ic_footprints, GEMME_VERT, tr("Joysticks", "Sticks"),
                tr("Taille et transparence", "Size and opacity"), this::sousJoysticks);
        sousMenu(R.drawable.st_ic_squares_four, GEMME_ORANGE, tr("Boutons", "Buttons"),
                tr("Taille, place, style et couleurs", "Size, place, style and colours"), this::sousBoutons);
        sousMenu(R.drawable.st_ic_cursor_click, GEMME_ROSE, tr("Double tap sur l'écran", "Double tap on the screen"),
                nomsDoubleTap()[TouchConfig.doubleTap(c)], this::sousDoubleTap);
        action(R.drawable.st_ic_hand_pointing, GEMME_VIOLET, tr("Guide des gestes", "Gesture guide"), null,
                false, () -> { fermer(); ecran.executer(ActionTactile.GUIDE); });
    }

    private void sousClavier() {
        Context c = getContext();
        rubrique(tr("Disposition du clavier", "Keyboard layout"));
        Disposition[] dispositions = Disposition.values();
        String[] noms = new String[dispositions.length + 1];
        String[] aides = new String[dispositions.length + 1];
        noms[0] = tr("Automatique", "Automatic");
        aides[0] = tr("Comme le clavier de ton téléphone : ", "Like your phone keyboard: ") + Disposition.deviner(c).titre;
        String r = Disposition.reglage(c);
        int choisi = 0;
        for (int i = 0; i < dispositions.length; i++) {
            noms[i + 1] = dispositions[i].nom;
            aides[i + 1] = dispositions[i].titre;
            if (dispositions[i].cle.equals(r)) choisi = i + 1;
        }
        TextView expl = texte(tr("Ce qui est écrit sur la touche arrive dans le jeu, quelle que soit la langue du clavier Windows.",
                "What a key shows is what reaches the game, whatever your Windows keyboard language."), 12, Parure.t(0xAAF2E6C9), false);
        expl.setPadding(px(4), 0, px(4), px(6));
        contenu.addView(expl);
        liste(noms, aides, choisi, i -> ecran.choisirDisposition(i == 0 ? "auto" : dispositions[i - 1].cle));

        rubrique(tr("Apparence", "Appearance"));
        curseur(tr("Taille", "Size"), 65, 140, Math.round(TouchConfig.getKeyboardScale(c) * 100), "%",
                v -> TouchConfig.setKeyboardScale(c, v / 100f));
        curseur(tr("Transparence", "Opacity"), 0, 100, TouchConfig.getKeyboardOpacity(c), "%",
                v -> TouchConfig.setKeyboardOpacity(c, v));
    }

    private String[] nomsDoubleTap() {
        return new String[]{tr("Double-clic", "Double-click"), tr("Clic droit", "Right-click"), tr("Deux clics simples", "Two single clicks")};
    }

    private void sousDoubleTap() {
        Context c = getContext();
        TextView note = texte(tr("Deux appuis rapides au même endroit, n'importe où hors des boutons.",
                "Two quick taps in the same spot, anywhere outside the buttons."), 12, Parure.t(0xAAF2E6C9), false);
        note.setPadding(px(4), px(6), px(4), px(6));
        contenu.addView(note);
        String[] aides = {
                tr("Comme un double-clic de souris : ouvrir, équiper, valider.", "Like a mouse double-click: open, equip, confirm."),
                tr("Comme rester appuyé : parler, ramasser, utiliser, attaquer.", "Like a long press: talk, loot, use, attack."),
                tr("Rien de spécial : chaque appui reste un clic.", "Nothing special: each tap stays a click.")};
        liste(nomsDoubleTap(), aides, TouchConfig.doubleTap(c), i -> TouchConfig.setDoubleTap(c, i));
    }

    private void sousJoysticks() {
        Context c = getContext();
        rubrique(tr("Joystick de déplacement", "Movement stick"));
        curseur(tr("Taille", "Size"), 50, 200, Math.round(TouchConfig.getStickScale(c) * 100), "%",
                v -> { TouchConfig.setStickScale(c, v / 100f); ecran.actualiser(); });
        curseur(tr("Transparence", "Opacity"), 0, 100, TouchConfig.getMoveStickOpacity(c), "%",
                v -> { TouchConfig.setMoveStickOpacity(c, v); ecran.actualiser(); });
        rubrique(tr("Joystick de caméra", "Camera stick"));
        curseur(tr("Taille", "Size"), 50, 200, Math.round(TouchConfig.getCameraStickScale(c) * 100), "%",
                v -> { TouchConfig.setCameraStickScale(c, v / 100f); ecran.actualiser(); });
        curseur(tr("Transparence", "Opacity"), 0, 100, TouchConfig.getCameraStickOpacity(c), "%",
                v -> { TouchConfig.setCameraStickOpacity(c, v); ecran.actualiser(); });
    }

    private void sousBoutons() {
        Context c = getContext();
        rubrique(tr("Apparence", "Appearance"));
        curseur(tr("Taille", "Size"), 70, 150, Math.round(TouchConfig.getButtonScale(c) * 100), "%",
                v -> { TouchConfig.setButtonScale(c, v / 100f); ecran.actualiser(); });
        curseur(tr("Transparence", "Opacity"), 0, 100, TouchConfig.getButtonOpacity(c), "%",
                v -> { TouchConfig.setButtonOpacity(c, v); ecran.actualiser(); });
        rubrique(tr("Disposition", "Layout"));
        action(R.drawable.st_ic_hand_grabbing, GEMME_VERT, tr("Déplacer les boutons", "Move buttons"),
                tr("Glisse chaque bouton à sa place.", "Drag each button where you want it."),
                false, () -> { fermer(); ecran.executer(ActionTactile.DEPLACER); });
        action(R.drawable.st_ic_squares_four, GEMME_ORANGE, tr("Style des boutons", "Button style"),
                tr("Forme, couleur, icône et couleur de l'icône.", "Shape, colour, icon and icon colour."),
                false, () -> { fermer(); ecran.executer(ActionTactile.BOUTONS); });
        action(R.drawable.st_ic_arrow_counter_clockwise, GEMME_GRIS, tr("Remettre les places d'origine", "Reset positions"), null,
                false, () -> confirmer(tr("Remettre tous les boutons à leur place d'origine ?", "Put every button back in its original place?"),
                        () -> { TouchConfig.resetControlPositions(c); ecran.actualiser(); }));
    }

    // ---------------------------------------------------------------- Image

    private void pageImage() {
        Context c = getContext();
        rubrique(tr("Image", "Picture"));
        sousMenu(R.drawable.st_ic_palette, GEMME_ROSE, tr("Ambiance", "Look"), FiltreVideo.ambiance(c).nom(c), this::sousAmbiance);
        sousMenu(R.drawable.st_ic_sliders_horizontal, GEMME_TURQUOISE, tr("Mon réglage", "My look"),
                tr("Lumière, couleurs, netteté, rétro…", "Brightness, colours, sharpness, retro…"), this::sousPerso);
        String sr = FiltreVideo.superResolution();
        if (sr != null) {
            TextView t = texte("✦ " + tr("Super Résolution", "Super Resolution") + " : " + sr, 12, Parure.OR, true);
            t.setPadding(px(4), px(2), px(4), px(4));
            contenu.addView(t);
        }

        rubrique(tr("Affichage", "Display"));
        interrupteur(tr("Statistiques à l'écran", "On-screen statistics"),
                tr("Images par seconde, retard, débit. Glisse le panneau pour le déplacer, touche-le pour le réduire.",
                        "Frame rate, latency, bitrate. Drag the panel to move it, tap it to shrink it."),
                jeu.statsVisibles(), jeu::montrerStats);
        action(R.drawable.st_ic_arrows_in_simple, GEMME_GRIS, tr("Remettre les statistiques en haut à gauche", "Put the statistics back top left"),
                null, false, jeu::replacerStats);
    }

    private void sousAmbiance() {
        Context c = getContext();
        FiltreVideo.Ambiance[] toutes = FiltreVideo.Ambiance.values();
        String[] noms = new String[toutes.length];
        for (int i = 0; i < toutes.length; i++) noms[i] = toutes[i].nom(c);
        TextView aide = texte(tr("Appliqué par le téléphone, en direct. Chaque ambiance coûte un peu de batterie.",
                "Applied live by the phone. Each look uses a little battery."), 12, Parure.t(0xAAF2E6C9), false);
        aide.setPadding(px(4), px(6), px(4), px(6));
        contenu.addView(aide);
        liste(noms, descriptions(toutes), FiltreVideo.ambiance(c).ordinal(), i -> {
            String raison = jeu.choisirAmbiance(toutes[i]);
            if (raison != null) message(raison);
        });
    }

    private void sousPerso() {
        Context c = getContext();
        TextView perso = texte(tr("Bouger un curseur passe sur « Personnalisé ».", "Moving a slider switches to “Custom”."),
                12, Parure.t(0xAAF2E6C9), false);
        perso.setPadding(px(4), px(6), px(4), px(6));
        contenu.addView(perso);
        float[] p = FiltreVideo.perso(c);
        String[][] reglages = {
                {"Lumière", "Brightness"}, {"Contraste", "Contrast"}, {"Saturation", "Saturation"},
                {"Vibrance", "Vibrance"}, {"Ombres", "Shadows"}, {"Chaleur", "Warmth"}, {"Netteté", "Sharpness"},
                {"Vignette", "Vignette"}, {"Anti-bandes", "Debanding"}, {"Lignes rétro", "Retro lines"},
                {"Contours dessinés", "Ink outlines"}};
        int[][] bornes = {{3, -10, 10}, {2, 80, 130}, {1, 50, 150}, {0, 0, 100}, {4, 80, 120}, {5, -50, 50}, {6, 0, 100},
                {7, 0, 60}, {8, 0, 100}, {9, 0, 100}, {10, 0, 100}};
        String[] groupes = {tr("Lumière", "Light"), null, null, tr("Couleurs", "Colours"), null, null,
                tr("Détails", "Detail"), null, null, tr("Effets", "Effects"), null};
        for (int k = 0; k < bornes.length; k++) {
            if (groupes[k] != null) rubrique(groupes[k]);
            final int idx = bornes[k][0];
            int valeur = Math.round(p[idx] * 100);
            curseur(tr(reglages[k][0], reglages[k][1]), bornes[k][1], bornes[k][2], valeur, "", v -> {
                float[] q = FiltreVideo.perso(c);
                q[idx] = v / 100f;
                FiltreVideo.reglerPerso(c, q);
                if (FiltreVideo.ambiance(c) != FiltreVideo.Ambiance.PERSO) {
                    String raison = jeu.choisirAmbiance(FiltreVideo.Ambiance.PERSO);
                    if (raison != null) message(raison);
                }
            });
        }
        action(R.drawable.st_ic_arrow_counter_clockwise, GEMME_GRIS, tr("Repartir de « Net »", "Start again from “Sharp”"), null, false, () -> {
            FiltreVideo.reglerPerso(c, null);
            redessiner();
        });
    }

    // ---------------------------------------------------------------- Session

    private void pageSession() {
        rubrique(tr("Partie en cours", "Current game"));
        info(R.drawable.st_ic_chart_bar, jeu.infosStream());
        action(R.drawable.st_ic_app_window, GEMME_TURQUOISE, tr("Petite fenêtre maintenant", "Small window now"),
                tr("Le jeu continue en petit, par-dessus tes autres applis.", "The game keeps running on top of your other apps."),
                false, () -> { fermer(); jeu.petiteFenetre(); });
        action(R.drawable.st_ic_keyboard, GEMME_BLEU, tr("Ouvrir le clavier", "Open keyboard"), null,
                false, () -> { fermer(); ecran.executer(ActionTactile.CLAVIER); });

        rubrique(tr("Quand je quitte l'appli", "When I leave the app"));
        interrupteur(tr("Petite fenêtre", "Small window"),
                tr("Le jeu reste en petit au lieu de se déconnecter.", "The game stays small instead of disconnecting."),
                jeu.pipActive(), jeu::reglerPip);

        rubrique(tr("Apparence", "Appearance"));
        sousMenu(R.drawable.st_ic_flag_banner, GEMME_OR, tr("Thème", "Theme"), Parure.theme().nom(getContext()), this::sousTheme);
        sousMenu(R.drawable.st_ic_chat_circle_text, GEMME_BLEU, tr("Langue", "Language"), langueActuelle(), this::sousLangue);

        rubrique("StreamTouch");
        action(R.drawable.st_ic_info, GEMME_OR, tr("À propos", "About"), null, false, () -> { fermer(); ecran.executer(ActionTactile.A_PROPOS); });
        action(R.drawable.st_ic_prohibit, GEMME_ROUGE, tr("Se déconnecter", "Disconnect"), tr("Ferme le stream.", "Ends the stream."),
                true, () -> confirmer(tr("Quitter la partie et te déconnecter du PC ?", "Leave the game and disconnect from the PC?"),
                        jeu::deconnecter));
    }

    private String langueActuelle() {
        String choix = android.preference.PreferenceManager.getDefaultSharedPreferences(getContext()).getString("list_languages", "default");
        for (int i = 1; i < Traduction.CODES.length; i++) if (Traduction.CODES[i].equals(choix)) return Traduction.NOMS[i];
        return tr("Comme le téléphone", "Like the phone");
    }

    private void sousLangue() {
        String[] nomsLangues = Traduction.NOMS.clone();
        nomsLangues[0] = tr("Comme le téléphone", "Like the phone");
        String choixLangue = android.preference.PreferenceManager.getDefaultSharedPreferences(getContext())
                .getString("list_languages", "default");
        int langueChoisie = 0;
        for (int i = 0; i < Traduction.CODES.length; i++) if (Traduction.CODES[i].equals(choixLangue)) langueChoisie = i;
        TextView note = texte(tr("Toute l'appli change au prochain lancement ; ce panneau tout de suite.",
                "The whole app switches at the next launch; this panel right away."), 12, Parure.t(0xAAF2E6C9), false);
        note.setPadding(px(4), px(6), px(4), px(6));
        contenu.addView(note);
        liste(nomsLangues, null, langueChoisie, i -> {
            android.preference.PreferenceManager.getDefaultSharedPreferences(getContext()).edit()
                    .putString("list_languages", Traduction.CODES[i]).apply();
            sousTitre = tr("Langue", "Language");
            redessiner();
        });
    }

    private void sousTheme() {
        TextView note = texte(tr("Change le Grimoire, les boutons, le clavier et les fenêtres.",
                "Changes the Grimoire, buttons, keyboard and windows."), 12, Parure.t(0xAAF2E6C9), false);
        note.setPadding(px(4), px(6), px(4), px(6));
        contenu.addView(note);
        for (Parure.Theme th : Parure.Theme.values()) {
            LinearLayout l = carte();
            boolean on = th == Parure.theme();
            View apercu = new View(getContext()) {
                final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
                @Override protected void onDraw(Canvas t) {
                    int[] c = th.apercu();
                    float w = getWidth(), h = getHeight(), r = Math.min(w, h) / 2f - px(1);
                    p.setShader(new LinearGradient(0, 0, w, h, new int[]{c[1], c[1], c[0], c[2]}, new float[]{0f, .5f, .5f, 1f},
                            Shader.TileMode.CLAMP));
                    t.drawCircle(w / 2, h / 2, r, p);
                    p.setShader(null);
                    p.setStyle(Paint.Style.STROKE);
                    p.setStrokeWidth(px(on ? 2.4f : 1.2f));
                    p.setColor(on ? Parure.OR_CLAIR : c[0]);
                    t.drawCircle(w / 2, h / 2, r - px(1), p);
                    p.setStyle(Paint.Style.FILL);
                }
            };
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(px(34), px(34));
            lp.rightMargin = px(12);
            l.addView(apercu, lp);
            l.addView(textes(th.nom(getContext()), null), new LinearLayout.LayoutParams(0, -2, 1));
            if (on) l.addView(texte("✓", 18, Parure.OR_CLAIR, true));
            GradientDrawable g = new GradientDrawable();
            g.setColor(on ? Parure.t(0xE6402A12) : CARTE);
            g.setCornerRadius(px(14));
            g.setStroke(px(on ? 1.6f : 1f), on ? Parure.OR : CARTE_BORD);
            l.setBackground(g);
            l.setOnClickListener(v -> {
                Parure.choisirTheme(getContext(), th);
                ecran.actualiser();
                rebatir();
            });
            contenu.addView(l);
        }
    }

    private String[] descriptions(FiltreVideo.Ambiance[] toutes) {
        String[] d = new String[toutes.length];
        for (int i = 0; i < toutes.length; i++) {
            switch (toutes[i]) {
                case AUCUN: d[i] = tr("L'image du PC telle quelle. Aucun coût.", "The PC picture as is. No cost."); break;
                case NET: d[i] = tr("Plus de détails et des couleurs un peu plus vives.", "More detail, slightly richer colours."); break;
                case ECLATANT: d[i] = tr("Couleurs pleines, image lumineuse.", "Full colours, bright picture."); break;
                case CINEMA: d[i] = tr("Chaud et contrasté, bords assombris.", "Warm and contrasted, darker edges."); break;
                case COMPETITIF: d[i] = tr("Ombres éclaircies et contours nets : on voit tout.", "Lifted shadows and crisp edges: see everything."); break;
                case NETTETE: d[i] = tr("Seulement plus net, couleurs d'origine.", "Sharper only, original colours."); break;
                case FILMIQUE: d[i] = tr("Doux et chaud, comme un film.", "Soft and warm, like a film."); break;
                case ARCADE: d[i] = tr("Très saturé et punchy.", "Very saturated and punchy."); break;
                case RETRO: d[i] = tr("Lignes et grille d'un vieil écran cathodique.", "Scanlines and mask of an old CRT."); break;
                case DESSIN: d[i] = tr("Couleurs en aplats et contours à l'encre.", "Flat colours and ink outlines."); break;
                default: d[i] = tr("Tes curseurs, dans « Mon réglage ».", "Your sliders, in “My look”."); break;
            }
        }
        return d;
    }

    // ---------------------------------------------------------------- Gemmes et sous-menus

    // Couleurs des gemmes (émaux vifs, ne suivent pas le thème).
    private static final int GEMME_BLEU = android.graphics.Color.parseColor("#3A86E0"),
            GEMME_VERT = android.graphics.Color.parseColor("#3FAE5C"),
            GEMME_ORANGE = android.graphics.Color.parseColor("#E8892A"),
            GEMME_VIOLET = android.graphics.Color.parseColor("#9A5CE0"),
            GEMME_ROSE = android.graphics.Color.parseColor("#D2489A"),
            GEMME_TURQUOISE = android.graphics.Color.parseColor("#22B3A8"),
            GEMME_ROUGE = android.graphics.Color.parseColor("#D2483C"),
            GEMME_GRIS = android.graphics.Color.parseColor("#7C8696"),
            GEMME_OR = -1;

    /** Une gemme d'émail : pierre ronde colorée, reflet, cerclage de métal, icône claire dessus. */
    private View gemme(int icone, int couleur) {
        Drawable d = getContext().getDrawable(icone);
        if (d != null) d = d.mutate();
        final Drawable dessin = d;
        return new View(getContext()) {
            final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
            @Override protected void onDraw(Canvas t) {
                int c = couleur == -1 ? Parure.OR : couleur;
                float w = getWidth(), h = getHeight(), r = Math.min(w, h) / 2f - px(1.5f), cx = w / 2, cy = h / 2;
                p.setShader(new RadialGradient(cx - r * .35f, cy - r * .45f, r * 1.6f,
                        new int[]{Parure.melange(c, android.graphics.Color.WHITE, .45f), c, Parure.melange(c, android.graphics.Color.BLACK, .55f)},
                        new float[]{0f, .45f, 1f}, Shader.TileMode.CLAMP));
                t.drawCircle(cx, cy, r, p);
                p.setShader(new LinearGradient(0, cy - r, 0, cy, Parure.t(0x66FFFFFF), Parure.t(0x00FFFFFF), Shader.TileMode.CLAMP));
                t.drawOval(cx - r * .7f, cy - r * .92f, cx + r * .7f, cy - r * .05f, p);
                p.setShader(null);
                p.setStyle(Paint.Style.STROKE);
                p.setStrokeWidth(px(1.6f));
                p.setColor(Parure.OR);
                t.drawCircle(cx, cy, r, p);
                p.setStyle(Paint.Style.FILL);
                if (dessin != null) {
                    int s = Math.round(r * 1.05f);
                    dessin.setBounds(Math.round(cx - s / 2f), Math.round(cy - s / 2f + px(1)), Math.round(cx + s / 2f), Math.round(cy + s / 2f + px(1)));
                    dessin.setTint(0x88000000);
                    dessin.draw(t);
                    dessin.setBounds(Math.round(cx - s / 2f), Math.round(cy - s / 2f), Math.round(cx + s / 2f), Math.round(cy + s / 2f));
                    dessin.setTint(0xFFFFFBF0);
                    dessin.draw(t);
                }
            }
        };
    }

    /** Une entrée de menu qui ouvre un sous-menu : gemme, titre, ce qui est choisi, chevron. */
    private void sousMenu(int icone, int couleur, String titre, String resume, Runnable construire) {
        LinearLayout l = carte();
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(px(36), px(36));
        lp.rightMargin = px(12);
        l.addView(gemme(icone, couleur), lp);
        l.addView(textes(titre, resume), new LinearLayout.LayoutParams(0, -2, 1));
        l.addView(texte("›", 24, Parure.OR, true));
        l.setOnClickListener(v -> ouvrirSous(titre, construire));
        contenu.addView(l);
    }

    // ------------------------------------------------------------------------------------------------ Les briques

    private View entete() {
        LinearLayout ligne = new LinearLayout(getContext());
        ligne.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout titres = new LinearLayout(getContext());
        titres.setOrientation(LinearLayout.VERTICAL);
        TextView titre = texte(tr("Grimoire", "Grimoire"), 26, Parure.OR_CLAIR, true);
        titre.setTypeface(Parure.LETTRES);
        titre.setShadowLayer(px(8), 0, 0, Parure.t(0xAAD9A84A));
        titres.addView(titre);
        TextView sous = texte(tr("RÉGLAGES DE LA PARTIE", "GAME SETTINGS"), 10, Parure.OR, false);
        sous.setLetterSpacing(.25f);
        titres.addView(sous);
        ligne.addView(titres, new LinearLayout.LayoutParams(0, -2, 1));
        ligne.addView(rond(R.drawable.st_ic_app_window, false, () -> { fermer(); jeu.petiteFenetre(); }));
        ligne.addView(rond(R.drawable.st_ic_keyboard, false, () -> { fermer(); ecran.executer(ActionTactile.CLAVIER); }));
        ligne.addView(rond(R.drawable.st_ic_prohibit, true, () -> confirmer(
                tr("Quitter la partie et te déconnecter du PC ?", "Leave the game and disconnect from the PC?"), jeu::deconnecter)));
        ligne.addView(rond(R.drawable.st_ic_x, false, this::fermer));
        return ligne;
    }

    /** Petit bouton rond doré de l'en-tête. */
    private View rond(int icone, boolean danger, Runnable quoi) {
        ImageView b = new ImageView(getContext());
        b.setImageResource(icone);
        b.setColorFilter(danger ? ROUGE : Parure.OR_CLAIR);
        int p = px(10);
        b.setPadding(p, p, p, p);
        GradientDrawable fond = new GradientDrawable();
        fond.setShape(GradientDrawable.OVAL);
        fond.setColors(new int[]{Parure.t(0xFF3A2612), Parure.t(0xFF1A1007)});
        fond.setStroke(px(1.5f), danger ? 0xAAE06A55 : Parure.t(0xAAD9A84A));
        b.setBackground(fond);
        b.setOnClickListener(v -> quoi.run());
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(px(42), px(42));
        lp.leftMargin = px(8);
        b.setLayoutParams(lp);
        return b;
    }

    /** Médaillon d'onglet : un sceau d'or avec l'icône, le nom dessous ; celui ouvert brille. */
    private View medaillon(int icone, String nom, Runnable quoi) {
        Drawable d = getContext().getDrawable(icone);
        View v = new View(getContext()) {
            final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
            @Override protected void onDraw(Canvas t) {
                float cx = getWidth() / 2f, r = px(22), cy = r + px(4);
                boolean on = isSelected();
                if (on) {
                    p.setShader(new RadialGradient(cx, cy, r * 2.2f, Parure.t(0x66FAD27A), Parure.t(0x00FAD27A), Shader.TileMode.CLAMP));
                    t.drawCircle(cx, cy, r * 2.2f, p);
                    p.setShader(null);
                }
                p.setShader(new LinearGradient(0, cy - r, 0, cy + r, on ? Parure.t(0xFF6B4A1C) : Parure.t(0xFF3A2612), on ? Parure.t(0xFF2E1D0A) : Parure.t(0xFF170E06), Shader.TileMode.CLAMP));
                t.drawCircle(cx, cy, r, p);
                p.setShader(null);
                p.setStyle(Paint.Style.STROKE);
                p.setStrokeWidth(px(on ? 2.2f : 1.3f));
                p.setColor(on ? Parure.OR_CLAIR : Parure.t(0xAAAE7A26));
                t.drawCircle(cx, cy, r, p);
                p.setStrokeWidth(px(.8f));
                p.setColor(Parure.t(0x66D9A84A));
                t.drawCircle(cx, cy, r - px(4), p);
                p.setStyle(Paint.Style.FILL);
                if (d != null) {
                    int s = Math.round(r * 1.0f);
                    d.setBounds(Math.round(cx - s / 2f), Math.round(cy - s / 2f), Math.round(cx + s / 2f), Math.round(cy + s / 2f));
                    d.setTint(on ? Parure.OR_CLAIR : Parure.t(0xFFC9A55A));
                    d.draw(t);
                }
                p.setTextAlign(Paint.Align.CENTER);
                p.setTypeface(Parure.LETTRES);
                p.setTextSize(px(12));
                p.setColor(on ? Parure.OR_CLAIR : Parure.t(0xCCF2E6C9));
                t.drawText(nom, cx, cy + r + px(17), p);
            }
        };
        v.setMinimumHeight(px(76));
        v.setOnClickListener(x -> quoi.run());
        return v;
    }

    private TextView texte(String s, float taille, int couleur, boolean gras) {
        TextView t = new TextView(getContext());
        t.setText(s);
        t.setTextSize(taille);
        t.setTextColor(couleur);
        if (gras) t.setTypeface(Typeface.DEFAULT_BOLD);
        return t;
    }

    /** Titre de rubrique : petites capitales dorées, filet qui s'efface. */
    private void rubrique(String nom) {
        LinearLayout l = new LinearLayout(getContext());
        l.setGravity(Gravity.CENTER_VERTICAL);
        l.setPadding(px(2), px(16), 0, px(8));
        TextView t = texte(nom.toUpperCase(Locale.ROOT), 11, Parure.OR, true);
        t.setLetterSpacing(.22f);
        l.addView(t);
        View filet = new View(getContext());
        GradientDrawable g = new GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT, new int[]{Parure.t(0x99D9A84A), Parure.t(0x00D9A84A)});
        filet.setBackground(g);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, px(1), 1);
        lp.leftMargin = px(10);
        l.addView(filet, lp);
        contenu.addView(l);
    }

    private LinearLayout carte() {
        LinearLayout l = new LinearLayout(getContext());
        l.setGravity(Gravity.CENTER_VERTICAL);
        l.setPadding(px(14), px(11), px(12), px(11));
        GradientDrawable g = new GradientDrawable();
        g.setColor(CARTE);
        g.setCornerRadius(px(14));
        g.setStroke(px(1), CARTE_BORD);
        l.setBackground(g);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
        lp.bottomMargin = px(7);
        l.setLayoutParams(lp);
        return l;
    }

    private LinearLayout textes(String titre, String aide) {
        LinearLayout col = new LinearLayout(getContext());
        col.setOrientation(LinearLayout.VERTICAL);
        col.addView(texte(titre, 15, Parure.CREME, true));
        if (aide != null) {
            TextView a = texte(aide, 12, Parure.t(0xAAF2E6C9), false);
            a.setPadding(0, px(2), 0, 0);
            col.addView(a);
        }
        return col;
    }

    /** Interrupteur doré dessiné (pas celui d'Android). */
    private void interrupteur(String titre, String aide, boolean etat, Consumer<Boolean> quoi) {
        LinearLayout l = carte();
        l.addView(textes(titre, aide), new LinearLayout.LayoutParams(0, -2, 1));
        final boolean[] on = {etat};
        View bascule = new View(getContext()) {
            final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
            float pos = etat ? 1f : 0f;
            @Override protected void onDraw(Canvas t) {
                float w = getWidth(), h = getHeight(), r = h / 2f;
                pos += ((on[0] ? 1f : 0f) - pos) * .35f;
                if (Math.abs((on[0] ? 1f : 0f) - pos) > .01f) postInvalidateOnAnimation();
                p.setShader(new LinearGradient(0, 0, w, 0, Parure.melange(Parure.t(0xFF2A1A0C), Parure.t(0xFF8A6A22), pos), Parure.melange(Parure.t(0xFF1A1007), Parure.t(0xFFD9A84A), pos), Shader.TileMode.CLAMP));
                t.drawRoundRect(new RectF(0, 0, w, h), r, r, p);
                p.setShader(null);
                p.setStyle(Paint.Style.STROKE);
                p.setStrokeWidth(px(1.2f));
                p.setColor(Parure.t(0xAAD9A84A));
                t.drawRoundRect(new RectF(px(.6f), px(.6f), w - px(.6f), h - px(.6f)), r, r, p);
                p.setStyle(Paint.Style.FILL);
                float cx = r + pos * (w - 2 * r);
                p.setShader(new RadialGradient(cx - r * .3f, r * .7f, r, Parure.t(0xFFFFF4D0), Parure.melange(Parure.t(0xFFB8A88A), Parure.t(0xFFF0C860), pos), Shader.TileMode.CLAMP));
                t.drawCircle(cx, r, r - px(3), p);
                p.setShader(null);
            }
        };
        bascule.setOnClickListener(v -> { on[0] = !on[0]; v.invalidate(); quoi.accept(on[0]); });
        l.setOnClickListener(v -> bascule.performClick());
        l.addView(bascule, new LinearLayout.LayoutParams(px(52), px(28)));
        contenu.addView(l);
    }

    private void curseur(String titre, int mini, int maxi, int valeur, String unite, IntConsumer quoi) {
        LinearLayout l = carte();
        l.setOrientation(LinearLayout.VERTICAL);
        LinearLayout haut = new LinearLayout(getContext());
        haut.addView(texte(titre, 14, Parure.CREME, true), new LinearLayout.LayoutParams(0, -2, 1));
        TextView chiffre = texte((valeur) + unite, 13, Parure.OR_CLAIR, true);
        haut.addView(chiffre);
        l.addView(haut);
        SeekBar barre = new SeekBar(getContext());
        Parure.habiller(barre);
        barre.setMax(maxi - mini);
        barre.setProgress(Math.max(0, Math.min(maxi - mini, valeur - mini)));
        barre.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar s, int p, boolean parDoigt) {
                chiffre.setText((p + mini) + unite);
                if (parDoigt) quoi.accept(p + mini);
            }
            @Override public void onStartTrackingTouch(SeekBar s) {}
            @Override public void onStopTrackingTouch(SeekBar s) {}
        });
        l.addView(barre, new LinearLayout.LayoutParams(-1, -2));
        contenu.addView(l);
    }

    private void action(int icone, int couleur, String titre, String aide, boolean danger, Runnable quoi) {
        LinearLayout l = carte();
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(px(36), px(36));
        lp.rightMargin = px(12);
        l.addView(gemme(icone, couleur), lp);
        LinearLayout col = textes(titre, aide);
        if (danger) ((TextView) col.getChildAt(0)).setTextColor(ROUGE);
        l.addView(col, new LinearLayout.LayoutParams(0, -2, 1));
        l.addView(texte("›", 22, Parure.t(0xAAD9A84A), true));
        l.setOnClickListener(v -> quoi.run());
        contenu.addView(l);
    }

    private void info(int icone, String s) {
        LinearLayout l = carte();
        ImageView i = new ImageView(getContext());
        i.setImageResource(icone);
        i.setColorFilter(Parure.OR);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(px(22), px(22));
        lp.rightMargin = px(12);
        l.addView(i, lp);
        l.addView(texte(s, 14, Parure.CREME, false), new LinearLayout.LayoutParams(0, -2, 1));
        contenu.addView(l);
    }

    /** Choix en pastilles, trois par ligne ; la choisie est dorée. */
    private void puces(String[] noms, int choisi, IntConsumer quoi) {
        List<TextView> toutes = new ArrayList<>();
        LinearLayout ligne = null;
        for (int i = 0; i < noms.length; i++) {
            if (i % 3 == 0) {
                ligne = new LinearLayout(getContext());
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
                lp.bottomMargin = px(7);
                contenu.addView(ligne, lp);
            }
            TextView t = texte(noms[i], 13, Parure.CREME, true);
            t.setGravity(Gravity.CENTER);
            t.setSingleLine();
            t.setPadding(px(6), px(10), px(6), px(10));
            toutes.add(t);
            final int n = i;
            t.setOnClickListener(v -> {
                for (int k = 0; k < toutes.size(); k++) puce(toutes.get(k), k == n);
                quoi.accept(n);
            });
            puce(t, i == choisi);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, -2, 1);
            lp.rightMargin = i % 3 == 2 ? 0 : px(7);
            ligne.addView(t, lp);
        }
        int reste = (3 - noms.length % 3) % 3;
        for (int k = 0; k < reste; k++) ligne.addView(new View(getContext()), new LinearLayout.LayoutParams(0, 1, 1));
    }

    /** Choix en liste : une ligne par choix, un sceau d'or coché devant celui retenu. */
    private void liste(String[] noms, String[] aides, int choisi, IntConsumer quoi) {
        List<ImageView> sceaux = new ArrayList<>();
        List<LinearLayout> lignes = new ArrayList<>();
        for (int i = 0; i < noms.length; i++) {
            LinearLayout l = carte();
            ImageView sceau = new ImageView(getContext());
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(px(22), px(22));
            lp.rightMargin = px(12);
            l.addView(sceau, lp);
            l.addView(textes(noms[i], aides == null ? null : aides[i]), new LinearLayout.LayoutParams(0, -2, 1));
            sceaux.add(sceau);
            lignes.add(l);
            final int n = i;
            l.setOnClickListener(v -> {
                for (int k2 = 0; k2 < sceaux.size(); k2++) coche(sceaux.get(k2), lignes.get(k2), k2 == n);
                quoi.accept(n);
            });
            coche(sceau, l, i == choisi);
            contenu.addView(l);
        }
    }

    private void coche(ImageView sceau, LinearLayout ligne, boolean on) {
        GradientDrawable rond = new GradientDrawable();
        rond.setShape(GradientDrawable.OVAL);
        if (on) rond.setColors(new int[]{Parure.t(0xFFF5D27A), Parure.t(0xFF9A6E22)});
        else rond.setColor(Parure.t(0x00000000));
        rond.setStroke(px(1.5f), on ? Parure.OR_CLAIR : Parure.t(0x88D9A84A));
        sceau.setBackground(rond);
        sceau.setImageDrawable(on ? coche : null);
        GradientDrawable g = new GradientDrawable();
        g.setColor(on ? Parure.t(0xE6402A12) : CARTE);
        g.setCornerRadius(px(14));
        g.setStroke(px(on ? 1.6f : 1f), on ? Parure.OR : CARTE_BORD);
        ligne.setBackground(g);
    }

    /** Le petit trait de coche, dessiné. */
    private final Drawable coche = new Drawable() {
        final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        @Override public void draw(Canvas t) {
            android.graphics.Rect b = getBounds();
            float w = b.width(), h = b.height();
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(w * .14f);
            p.setStrokeCap(Paint.Cap.ROUND);
            p.setColor(Parure.t(0xFF1E1206));
            Path c = new Path();
            c.moveTo(b.left + w * .27f, b.top + h * .52f);
            c.lineTo(b.left + w * .44f, b.top + h * .68f);
            c.lineTo(b.left + w * .74f, b.top + h * .34f);
            t.drawPath(c, p);
        }
        @Override public void setAlpha(int a) {}
        @Override public void setColorFilter(ColorFilter f) {}
        @Override public int getOpacity() { return PixelFormat.TRANSLUCENT; }
    };


    private void puce(TextView t, boolean on) {
        GradientDrawable g = on
                ? new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, new int[]{Parure.t(0xFFE9C46A), Parure.t(0xFF9A6E22)})
                : new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, new int[]{Parure.t(0xCC2E1D0C), Parure.t(0xCC1A1007)});
        g.setCornerRadius(px(22));
        g.setStroke(px(on ? 1.5f : 1f), on ? Parure.OR_CLAIR : CARTE_BORD);
        t.setBackground(g);
        t.setTextColor(on ? Parure.t(0xFF1E1206) : Parure.CREME);
    }

    private void confirmer(String question, Runnable oui) {
        AlertDialog f = new AlertDialog.Builder(getContext())
                .setMessage(question)
                .setNegativeButton(tr("Annuler", "Cancel"), null)
                .setPositiveButton(tr("Oui", "Yes"), (d, w) -> oui.run())
                .create();
        f.show();
        Parure.habiller(f, dp);
    }

    private void message(String s) {
        android.widget.Toast.makeText(getContext(), s, android.widget.Toast.LENGTH_LONG).show();
    }

    private String tr(String fr, String en) { return Traduction.texte(getContext(), fr, en); }

    private int px(float v) { return Math.round(v * dp); }

    // ------------------------------------------------------------------------------------------------ La reliure

    /** Le fond du panneau : cuir sombre, tranche d'or à gauche, coins ornés et filets gaufrés. */
    private static final class Reliure extends Drawable {
        private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final float dp;
        Reliure(float dp) { this.dp = dp; }

        @Override public void draw(Canvas t) {
            android.graphics.Rect b = getBounds();
            float w = b.width(), h = b.height(), r = 26 * dp;
            RectF cadre = new RectF(b.left, b.top, b.right + r, b.bottom);
            p.setShader(new LinearGradient(0, b.top, 0, b.bottom, Parure.t(0xFF2B1A0D), Parure.t(0xFF120A04), Shader.TileMode.CLAMP));
            t.drawRoundRect(cadre, r, r, p);
            // grain du cuir
            p.setShader(new RadialGradient(b.left + w * .3f, b.top + h * .2f, Math.max(w, h), Parure.t(0x22FFD58A), Parure.t(0x00000000), Shader.TileMode.CLAMP));
            t.drawRoundRect(cadre, r, r, p);
            p.setShader(null);
            // filets gaufrés
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(dp);
            p.setColor(Parure.t(0x33D9A84A));
            RectF filet = new RectF(b.left + 10 * dp, b.top + 10 * dp, b.right + r, b.bottom - 10 * dp);
            t.drawRoundRect(filet, r - 8 * dp, r - 8 * dp, p);
            p.setColor(Parure.t(0x1FD9A84A));
            RectF filet2 = new RectF(b.left + 15 * dp, b.top + 15 * dp, b.right + r, b.bottom - 15 * dp);
            t.drawRoundRect(filet2, r - 12 * dp, r - 12 * dp, p);
            // tranche d'or
            p.setStyle(Paint.Style.FILL);
            p.setShader(new LinearGradient(0, b.top, 0, b.bottom, new int[]{Parure.t(0xFF6B4A12), Parure.t(0xFFF5D27A), Parure.t(0xFFAE7A26), Parure.t(0xFFF5D27A), Parure.t(0xFF6B4A12)},
                    null, Shader.TileMode.CLAMP));
            Path tranche = new Path();
            tranche.addRoundRect(new RectF(b.left, b.top, b.left + 4 * dp, b.bottom), new float[]{r, r, 0, 0, 0, 0, r, r}, Path.Direction.CW);
            t.drawPath(tranche, p);
            p.setShader(new LinearGradient(b.left, 0, b.left + 18 * dp, 0, Parure.t(0x55F5D27A), Parure.t(0x00F5D27A), Shader.TileMode.CLAMP));
            t.drawRect(b.left + 4 * dp, b.top + r, b.left + 18 * dp, b.bottom - r, p);
            p.setShader(null);
            // coins : losanges d'or
            losange(t, b.left + 22 * dp, b.top + 22 * dp);
            losange(t, b.left + 22 * dp, b.bottom - 22 * dp);
        }

        private void losange(Canvas t, float x, float y) {
            float s = 5 * dp;
            Path l = new Path();
            l.moveTo(x, y - s); l.lineTo(x + s, y); l.lineTo(x, y + s); l.lineTo(x - s, y); l.close();
            p.setColor(Parure.t(0xCCD9A84A));
            t.drawPath(l, p);
            p.setColor(Parure.t(0xFFFAEAB4));
            t.drawCircle(x, y, 1.2f * dp, p);
        }

        @Override public void setAlpha(int a) {}
        @Override public void setColorFilter(ColorFilter f) {}
        @Override public int getOpacity() { return PixelFormat.TRANSLUCENT; }
    }
}
