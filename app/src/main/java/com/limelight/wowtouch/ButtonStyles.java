package com.limelight.wowtouch;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;

import com.limelight.R;

/** CH : forme, couleur, icône et nom affiché de chaque bouton à l'écran, enregistrés sur le téléphone. */
final class ButtonStyles {
    static final int SHAPE_ROUNDED = 0, SHAPE_ROUND = 1, SHAPE_SQUARE = 2;
    static final int[] SHAPE_NAMES = {R.string.st_forme_arrondi, R.string.st_forme_rond, R.string.st_forme_carre};

    /** 0 = couleur d'origine (le cuir de Streaming Touch). */
    static final int[] COLORS = {0, 0xFF2F6FD0, 0xFFD9A02B, 0xFFD24545, 0xFF37A65A, 0xFF8A57DA,
            0xFFEE7A1C, 0xFF1FB2C4, 0xFFDD5C97, 0xFF6F7B8C, 0xFF20252E};
    static final String[] COLOR_NAMES = {"Origine", "Bleu", "Or", "Rouge", "Vert", "Violet",
            "Orange", "Cyan", "Rose", "Gris", "Noir"};

    static final String[] ICON_NAMES = {"x", "map_trifold", "backpack", "squares_four", "crosshair", "hand_grabbing",
            "arrow_fat_line_up", "sword", "cursor_click", "keyboard", "magnifying_glass", "gear_six", "tree_structure",
            "app_window", "armchair", "arrow_bend_up_left", "arrow_counter_clockwise", "arrow_fat_line_down",
            "arrow_fat_up", "arrows_in_simple", "book_open", "chart_bar", "chat_circle_text", "control",
            "flag_banner", "footprints", "hand_pointing", "handshake", "heart", "lifebuoy", "option", "paw_print",
            "person_simple_run", "person_simple_walk", "prohibit", "scroll", "skull", "sliders_horizontal", "stack",
            "tag", "terminal_window", "text_aa", "user", "user_circle", "user_switch", "users", "users_three"};
    static final int[] ICON_IDS = {R.drawable.st_ic_x, R.drawable.st_ic_map_trifold,
            R.drawable.st_ic_backpack, R.drawable.st_ic_squares_four,
            R.drawable.st_ic_crosshair, R.drawable.st_ic_hand_grabbing,
            R.drawable.st_ic_arrow_fat_line_up, R.drawable.st_ic_sword,
            R.drawable.st_ic_cursor_click, R.drawable.st_ic_keyboard,
            R.drawable.st_ic_magnifying_glass, R.drawable.st_ic_gear_six,
            R.drawable.st_ic_tree_structure, R.drawable.st_ic_app_window,
            R.drawable.st_ic_armchair, R.drawable.st_ic_arrow_bend_up_left,
            R.drawable.st_ic_arrow_counter_clockwise, R.drawable.st_ic_arrow_fat_line_down,
            R.drawable.st_ic_arrow_fat_up, R.drawable.st_ic_arrows_in_simple,
            R.drawable.st_ic_book_open, R.drawable.st_ic_chart_bar,
            R.drawable.st_ic_chat_circle_text, R.drawable.st_ic_control,
            R.drawable.st_ic_flag_banner,
            R.drawable.st_ic_footprints, R.drawable.st_ic_hand_pointing,
            R.drawable.st_ic_handshake, R.drawable.st_ic_heart,
            R.drawable.st_ic_lifebuoy, R.drawable.st_ic_option,
            R.drawable.st_ic_paw_print, R.drawable.st_ic_person_simple_run,
            R.drawable.st_ic_person_simple_walk, R.drawable.st_ic_prohibit,
            R.drawable.st_ic_scroll, R.drawable.st_ic_skull,
            R.drawable.st_ic_sliders_horizontal, R.drawable.st_ic_stack,
            R.drawable.st_ic_tag, R.drawable.st_ic_terminal_window,
            R.drawable.st_ic_text_aa, R.drawable.st_ic_user,
            R.drawable.st_ic_user_circle, R.drawable.st_ic_user_switch,
            R.drawable.st_ic_users, R.drawable.st_ic_users_three};

    /** Icônes proposées en premier pour chaque bouton (numéros des boutons de Commandes). */
    static final String[][] SUGGESTED = {
            {"x", "squares_four", "gear_six", "app_window", "stack", "sliders_horizontal"},
            {"map_trifold", "flag_banner", "footprints", "magnifying_glass", "scroll", "tag"},
            {"backpack", "stack", "squares_four", "tag", "handshake", "app_window"},
            {"squares_four", "arrow_fat_up", "control", "option", "stack", "text_aa"},
            {"crosshair", "skull", "user_switch", "magnifying_glass", "sword", "user_circle"},
            {"hand_grabbing", "hand_pointing", "cursor_click", "handshake", "chat_circle_text", "heart"},
            {"arrow_fat_line_up", "arrow_fat_up", "person_simple_run", "footprints", "arrow_fat_line_down", "stack"},
            {"sword", "crosshair", "skull", "flag_banner", "heart", "person_simple_run"},
            {"cursor_click", "app_window", "hand_pointing", "squares_four", "stack", "sliders_horizontal"},
            {"keyboard", "chat_circle_text", "text_aa", "terminal_window", "control", "arrow_bend_up_left"},
            {"magnifying_glass", "cursor_click", "hand_pointing", "crosshair", "tag", "user"},
            {"gear_six", "sliders_horizontal", "squares_four", "stack", "app_window", "x"},
            {"gear_six", "book_open", "scroll", "handshake", "chart_bar", "tag"},
            {"tree_structure", "book_open", "chart_bar", "stack", "scroll", "flag_banner"},
    };

    private ButtonStyles() {}

    private static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences("wowtouch_button_styles", Context.MODE_PRIVATE);
    }

    static int shape(Context c, int key) { return prefs(c).getInt("shape_" + key, SHAPE_ROUNDED); }
    static int color(Context c, int key) { return prefs(c).getInt("color_" + key, 0); }
    static String icon(Context c, int key) { return prefs(c).getString("icon_" + key, ""); }
    static boolean label(Context c, int key) { return prefs(c).getBoolean("label_" + key, true); }

    static void setShape(Context c, int key, int value) { prefs(c).edit().putInt("shape_" + key, value).apply(); }
    static void setColor(Context c, int key, int value) { prefs(c).edit().putInt("color_" + key, value).apply(); }
    static void setIcon(Context c, int key, String value) { prefs(c).edit().putString("icon_" + key, value).apply(); }
    static void setLabel(Context c, int key, boolean value) { prefs(c).edit().putBoolean("label_" + key, value).apply(); }

    static void reset(Context c, int key) {
        prefs(c).edit().remove("shape_" + key).remove("color_" + key).remove("icon_" + key).remove("label_" + key).apply();
    }

    static void resetAll(Context c) { prefs(c).edit().clear().apply(); }

    static int iconCount() { return Math.min(ICON_NAMES.length, ICON_IDS.length); }

    static int iconId(String name) {
        if (name == null || name.isEmpty()) return 0;
        for (int i = 0; i < iconCount(); i++) if (ICON_NAMES[i].equals(name)) return ICON_IDS[i];
        return 0;
    }

    /** Dégradé du bouton {haut, bas, bord} pour une couleur choisie, ou null pour garder la couleur d'origine. */
    static int[] faceColors(int color, boolean active) {
        if (color == 0) return null;
        if (active) return new int[]{alpha(mix(color, Color.WHITE, .35f), 0xF2), alpha(color, 0xF2), alpha(mix(color, Color.WHITE, .6f), 0xFF)};
        return new int[]{alpha(mix(color, Color.WHITE, .12f), 0xD9), alpha(mix(color, Color.BLACK, .5f), 0xD9),
                alpha(mix(color, Color.WHITE, .45f), 0xCC)};
    }

    static int mix(int a, int b, float t) {
        return Color.rgb(Math.round(Color.red(a) + (Color.red(b) - Color.red(a)) * t),
                Math.round(Color.green(a) + (Color.green(b) - Color.green(a)) * t),
                Math.round(Color.blue(a) + (Color.blue(b) - Color.blue(a)) * t));
    }

    static int alpha(int color, int alpha) { return (color & 0x00FFFFFF) | (alpha << 24); }
}
