package com.limelight.wowtouch;

import com.limelight.R;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.GridLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

/**
 * CH : fenêtre « Personnaliser les boutons ». On choisit un bouton de l'écran, puis sa forme,
 * sa couleur, son icône (avec des propositions) et si son nom s'affiche. Tout s'applique tout de suite.
 */
final class ButtonStyleDialog {

    private final Activity activite;
    private final String[] labels;
    private final int[] defaultIcons;
    private final Runnable changed;
    private final float densite;
    private final List<Integer> keys = new ArrayList<>();
    private final List<View> tiles = new ArrayList<>();
    private final List<Preview> previews = new ArrayList<>();
    private final Button[] shapes = new Button[3];
    private final List<TextView> swatches = new ArrayList<>();
    private final List<ImageView> suggestCells = new ArrayList<>();
    private final List<ImageView> iconCells = new ArrayList<>();
    private TextView heading;
    private CheckBox showLabel;
    private Preview big;
    private int selected = Commandes.CLAVIER;

    ButtonStyleDialog(Activity activite, String[] labels, int[] defaultIcons, Runnable changed) {
        this.activite = activite;
        this.labels = labels;
        this.defaultIcons = defaultIcons;
        this.changed = changed;
        densite = activite.getResources().getDisplayMetrics().density;
        // Seulement les boutons qui existent encore à l'écran (pas les anciens numéros retirés).
        for (int i = 0; i < labels.length; i++) if (Commandes.existe(i)) keys.add(i);
        if (!keys.contains(selected) && !keys.isEmpty()) selected = keys.get(0);
    }

    private int dp(float v) { return Math.round(v * densite); }

    private Drawable icon(int key) {
        int custom = ButtonStyles.iconId(ButtonStyles.icon(activite, key));
        return activite.getDrawable(custom != 0 ? custom : defaultIcons[key]).mutate();
    }

    private TextView caption(String text) {
        TextView t = new TextView(activite);
        t.setText(text);
        t.setTextSize(14);
        Parure.rubrique(t, densite);
        t.setPadding(0, dp(12), 0, dp(4));
        return t;
    }

    void show() {
        LinearLayout contenu = new LinearLayout(activite);
        contenu.setOrientation(LinearLayout.VERTICAL);
        contenu.setPadding(dp(16), dp(6), dp(16), dp(10));

        TextView hint = new TextView(activite);
        hint.setText(activite.getString(R.string.st_b_aide));
        hint.setTextSize(13);
        contenu.addView(hint);

        // CH : une grille plutôt qu'un ruban qui défile : le dernier bouton (Keyboard) sortait de l'écran.
        GridLayout tileRow = new GridLayout(activite);
        int screen = activite.getResources().getDisplayMetrics().widthPixels;
        int maxCols = Math.max(3, (Math.min(screen, dp(560)) - dp(40)) / dp(72));
        int rows = (keys.size() + maxCols - 1) / maxCols;
        tileRow.setColumnCount(Math.max(1, (keys.size() + rows - 1) / Math.max(1, rows)));
        for (int key : keys) {
            LinearLayout tile = new LinearLayout(activite);
            tile.setOrientation(LinearLayout.VERTICAL);
            tile.setGravity(Gravity.CENTER_HORIZONTAL);
            tile.setPadding(dp(4), dp(4), dp(4), dp(4));
            Preview preview = new Preview(activite, key);
            tile.addView(preview, new LinearLayout.LayoutParams(dp(56), dp(56)));
            TextView name = new TextView(activite);
            name.setText(labels[key]);
            name.setTextSize(11);
            name.setGravity(Gravity.CENTER);
            name.setMaxLines(1);
            tile.addView(name, new LinearLayout.LayoutParams(dp(64), ViewGroup.LayoutParams.WRAP_CONTENT));
            tile.setOnClickListener(v -> { selected = key; actualiser(); });
            tileRow.addView(tile);
            tiles.add(tile);
            previews.add(preview);
        }
        LinearLayout.LayoutParams gridParams = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        gridParams.gravity = Gravity.CENTER_HORIZONTAL;
        contenu.addView(tileRow, gridParams);

        LinearLayout head = new LinearLayout(activite);
        head.setGravity(Gravity.CENTER_VERTICAL);
        head.setPadding(0, dp(10), 0, 0);
        big = new Preview(activite, -1);
        head.addView(big, new LinearLayout.LayoutParams(dp(76), dp(76)));
        heading = new TextView(activite);
        heading.setTextSize(18);
        heading.setTypeface(Typeface.DEFAULT_BOLD);
        heading.setPadding(dp(14), 0, 0, 0);
        head.addView(heading);
        contenu.addView(head);

        contenu.addView(caption(activite.getString(R.string.st_b_forme)));
        LinearLayout shapeRow = new LinearLayout(activite);
        for (int s = 0; s < 3; s++) {
            final int shape = s;
            Button b = new Button(activite);
            b.setText(ButtonStyles.SHAPE_NAMES[s]);
            Parure.habiller(b, densite);
            b.setOnClickListener(v -> { ButtonStyles.setShape(activite, selected, shape); update(); });
            shapeRow.addView(b, new LinearLayout.LayoutParams(0, dp(44), 1));
            shapes[s] = b;
        }
        contenu.addView(shapeRow);

        contenu.addView(caption(activite.getString(R.string.st_b_couleur)));
        HorizontalScrollView colorScroll = new HorizontalScrollView(activite);
        colorScroll.setHorizontalScrollBarEnabled(false);
        LinearLayout colorRow = new LinearLayout(activite);
        colorScroll.addView(colorRow);
        for (int c = 0; c < ButtonStyles.COLORS.length; c++) {
            final int color = ButtonStyles.COLORS[c];
            TextView swatch = new TextView(activite);
            swatch.setGravity(Gravity.CENTER);
            swatch.setTextSize(10);
            swatch.setTextColor(Color.WHITE);
            swatch.setText(c == 0 ? activite.getString(R.string.st_b_origine) : "");
            swatch.setOnClickListener(v -> { ButtonStyles.setColor(activite, selected, color); update(); });
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(dp(c == 0 ? 64 : 40), dp(40));
            params.setMargins(dp(3), dp(3), dp(3), dp(3));
            colorRow.addView(swatch, params);
            swatches.add(swatch);
        }
        contenu.addView(colorScroll);

        contenu.addView(caption(activite.getString(R.string.st_b_proposees)));
        GridLayout suggest = new GridLayout(activite);
        suggest.setColumnCount(6);
        for (int i = 0; i < 6; i++) suggestCells.add(cell(suggest));
        contenu.addView(suggest);

        contenu.addView(caption(activite.getString(R.string.st_b_toutes)));
        GridLayout all = new GridLayout(activite);
        all.setColumnCount(8);
        for (int i = 0; i < ButtonStyles.iconCount(); i++) {
            ImageView cell = cell(all);
            cell.setTag(ButtonStyles.ICON_NAMES[i]);
            cell.setImageResource(ButtonStyles.ICON_IDS[i]);
            iconCells.add(cell);
        }
        contenu.addView(all);

        showLabel = new CheckBox(activite);
        showLabel.setText(activite.getString(R.string.st_b_nom));
        showLabel.setPadding(0, dp(8), 0, dp(8));
        showLabel.setOnClickListener(v -> { ButtonStyles.setLabel(activite, selected, showLabel.isChecked()); update(); });
        contenu.addView(showLabel);

        LinearLayout actions = new LinearLayout(activite);
        Button resetOne = new Button(activite);
        resetOne.setText(activite.getString(R.string.st_b_remettre));
        Parure.habiller(resetOne, densite);
        resetOne.setOnClickListener(v -> { ButtonStyles.reset(activite, selected); update(); });
        actions.addView(resetOne, new LinearLayout.LayoutParams(0, dp(46), 1));
        Button resetAll = new Button(activite);
        resetAll.setText(activite.getString(R.string.st_b_tout));
        Parure.habiller(resetAll, densite);
        resetAll.setOnClickListener(v -> Parure.habiller(new AlertDialog.Builder(activite)
                .setTitle(activite.getString(R.string.st_b_tout_titre))
                .setMessage(activite.getString(R.string.st_b_tout_texte))
                .setPositiveButton(activite.getString(R.string.st_oui), (d, w) -> { ButtonStyles.resetAll(activite); update(); })
                .setNegativeButton(activite.getString(R.string.st_annuler), null).show(), densite));
        actions.addView(resetAll, new LinearLayout.LayoutParams(0, dp(46), 1));
        contenu.addView(actions);

        ScrollView defile = new ScrollView(activite);
        defile.addView(contenu);
        AlertDialog dialog = new AlertDialog.Builder(activite)
                .setTitle(activite.getString(R.string.st_b_titre))
                .setView(defile)
                .setPositiveButton(activite.getString(R.string.st_fermer), null)
                .create();
        dialog.show();
        Parure.habiller(dialog, densite);
        int width = activite.getResources().getDisplayMetrics().widthPixels;
        if (dialog.getWindow() != null) dialog.getWindow().setLayout(Math.min(width, dp(560)), ViewGroup.LayoutParams.WRAP_CONTENT);
        actualiser();
    }

    private ImageView cell(GridLayout grid) {
        ImageView cell = new ImageView(activite);
        cell.setPadding(dp(9), dp(9), dp(9), dp(9));
        cell.setColorFilter(Parure.OR);
        cell.setOnClickListener(v -> {
            Object name = v.getTag();
            if (name instanceof String) {
                ButtonStyles.setIcon(activite, selected, (String) name);
                update();
            }
        });
        GridLayout.LayoutParams params = new GridLayout.LayoutParams();
        params.width = dp(46);
        params.height = dp(46);
        params.setMargins(dp(2), dp(2), dp(2), dp(2));
        grid.addView(cell, params);
        return cell;
    }

    private GradientDrawable box(int fill, int stroke, float strokeDp, boolean oval) {
        GradientDrawable g = new GradientDrawable();
        g.setShape(oval ? GradientDrawable.OVAL : GradientDrawable.RECTANGLE);
        if (!oval) g.setCornerRadius(dp(8));
        g.setColor(fill);
        if (strokeDp > 0) g.setStroke(dp(strokeDp), stroke);
        return g;
    }

    /** Un réglage a changé : on l'applique à l'écran et on rafraîchit la fenêtre. */
    private void update() {
        changed.run();
        actualiser();
    }

    private void actualiser() {
        heading.setText(labels[selected]);
        big.key = selected;
        big.invalidate();
        for (int i = 0; i < tiles.size(); i++) {
            boolean on = keys.get(i) == selected;
            tiles.get(i).setBackground(on ? box(0x40D9A84A, Parure.OR, 2, false) : null);
            previews.get(i).invalidate();
        }
        int shape = ButtonStyles.shape(activite, selected);
        for (int s = 0; s < 3; s++) shapes[s].setAlpha(s == shape ? 1f : .5f);
        int color = ButtonStyles.color(activite, selected);
        for (int c = 0; c < swatches.size(); c++) {
            int value = ButtonStyles.COLORS[c];
            boolean on = value == color;
            swatches.get(c).setBackground(box(value == 0 ? Parure.CUIR_HAUT : value, on ? Parure.OR_CLAIR : 0x66AE7A26, on ? 3 : 1, value != 0));
        }
        String current = ButtonStyles.icon(activite, selected);
        String[] suggested = selected < ButtonStyles.SUGGESTED.length ? ButtonStyles.SUGGESTED[selected] : new String[0];
        for (int i = 0; i < suggestCells.size(); i++) {
            ImageView cell = suggestCells.get(i);
            String name = i < suggested.length ? suggested[i] : null;
            int id = ButtonStyles.iconId(name);
            cell.setVisibility(id != 0 ? View.VISIBLE : View.INVISIBLE);
            if (id == 0) continue;
            cell.setTag(name);
            cell.setImageResource(id);
            cell.setBackground(box(0xFF24160C, Parure.OR, name.equals(current) ? 2 : 0, false));
        }
        for (ImageView cell : iconCells) {
            boolean on = cell.getTag().equals(current);
            cell.setBackground(box(0xFF24160C, Parure.OR, on ? 2 : 0, false));
        }
        showLabel.setChecked(ButtonStyles.label(activite, selected));
    }

    /** Aperçu d'un bouton dessiné comme à l'écran. */
    private final class Preview extends View {
        int key;
        private final Paint pinceau = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF zone = new RectF(), face = new RectF();

        Preview(Context context, int key) {
            super(context);
            this.key = key;
        }

        @Override protected void onDraw(Canvas toile) {
            if (key < 0) return;
            float side = Math.min(getWidth(), getHeight()) - dp(6);
            float left = (getWidth() - side) / 2f, top = (getHeight() - side) / 2f - dp(1);
            int shape = ButtonStyles.shape(activite, key);
            zone.set(left, top, left + side, top + side);
            Parure.bouton(toile, pinceau, zone, Parure.coin(shape, zone, densite), densite,
                    ButtonStyles.color(activite, key), false, key == selected, face);
            boolean label = ButtonStyles.label(activite, key);
            float size = Math.min(face.width(), face.height()) * (label ? .5f : .66f);
            float cy = label ? face.centerY() - side * .09f : face.centerY();
            Parure.icone(toile, pinceau, icon(key), face.centerX(), cy, size, densite, key == selected, 255);
            if (label) {
                Parure.lettres(pinceau, side * .15f, Parure.CREME, densite);
                pinceau.setTextAlign(Paint.Align.CENTER);
                String text = labels[key];
                float width = pinceau.measureText(text);
                if (width > face.width() * .9f) pinceau.setTextSize(side * .15f * face.width() * .9f / width);
                toile.drawText(text, face.centerX(), cy + size / 2 + pinceau.getTextSize(), pinceau);
                pinceau.clearShadowLayer();
            }
        }
    }
}
