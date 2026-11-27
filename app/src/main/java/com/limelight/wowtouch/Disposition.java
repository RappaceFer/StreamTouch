package com.limelight.wowtouch;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.view.inputmethod.InputMethodManager;
import android.view.inputmethod.InputMethodSubtype;

import java.util.Locale;

/**
 * Streaming Touch, Made in Rappace : la disposition du clavier PC à l'écran.
 *
 * Le clavier envoie la position physique des touches (comme un vrai clavier branché sur le PC) ; c'est la langue du
 * clavier Windows du PC qui décide de la lettre. Les étiquettes affichées doivent donc suivre cette langue. Par défaut,
 * on prend celle du clavier du téléphone (même personne, même langue), et le joueur peut en choisir une autre.
 *
 * Chaque disposition donne les étiquettes des 4 rangées de caractères, dans l'ordre des positions d'un clavier PC :
 * rangée des chiffres (13), rangée Q (12), rangée A (12), rangée Z avec la touche en plus à gauche (11).
 */
public enum Disposition {
    CH_FR("ch_fr", "Suisse romand", "CH-FR  QWERTZ",
            new String[]{"§", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "'", "^"},
            new String[]{"Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P", "è", "¨"},
            new String[]{"A", "S", "D", "F", "G", "H", "J", "K", "L", "é", "à", "$"},
            new String[]{"<", "Y", "X", "C", "V", "B", "N", "M", ",", ".", "-"}),
    CH_DE("ch_de", "Schweiz (Deutsch)", "CH-DE  QWERTZ",
            new String[]{"§", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "'", "^"},
            new String[]{"Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P", "ü", "¨"},
            new String[]{"A", "S", "D", "F", "G", "H", "J", "K", "L", "ö", "ä", "$"},
            new String[]{"<", "Y", "X", "C", "V", "B", "N", "M", ",", ".", "-"}),
    FR("fr", "Français (France)", "FR  AZERTY",
            new String[]{"²", "&", "é", "\"", "'", "(", "-", "è", "_", "ç", "à", ")", "="},
            new String[]{"A", "Z", "E", "R", "T", "Y", "U", "I", "O", "P", "^", "$"},
            new String[]{"Q", "S", "D", "F", "G", "H", "J", "K", "L", "M", "ù", "*"},
            new String[]{"<", "W", "X", "C", "V", "B", "N", ",", ";", ":", "!"}),
    BE("be", "Belgique", "BE  AZERTY",
            new String[]{"²", "&", "é", "\"", "'", "(", "§", "è", "!", "ç", "à", ")", "-"},
            new String[]{"A", "Z", "E", "R", "T", "Y", "U", "I", "O", "P", "^", "$"},
            new String[]{"Q", "S", "D", "F", "G", "H", "J", "K", "L", "M", "ù", "µ"},
            new String[]{"<", "W", "X", "C", "V", "B", "N", ",", ";", ":", "="}),
    DE("de", "Deutsch", "DE  QWERTZ",
            new String[]{"^", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "ß", "´"},
            new String[]{"Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P", "Ü", "+"},
            new String[]{"A", "S", "D", "F", "G", "H", "J", "K", "L", "Ö", "Ä", "#"},
            new String[]{"<", "Y", "X", "C", "V", "B", "N", "M", ",", ".", "-"}),
    US("us", "English (US)", "US  QWERTY",
            new String[]{"`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="},
            new String[]{"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]"},
            new String[]{"A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "\\"},
            new String[]{"\\", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/"}),
    UK("uk", "English (UK)", "UK  QWERTY",
            new String[]{"`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="},
            new String[]{"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]"},
            new String[]{"A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "#"},
            new String[]{"\\", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/"}),
    ES("es", "Español", "ES  QWERTY",
            new String[]{"º", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "'", "¡"},
            new String[]{"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "`", "+"},
            new String[]{"A", "S", "D", "F", "G", "H", "J", "K", "L", "Ñ", "´", "Ç"},
            new String[]{"<", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "-"}),
    IT("it", "Italiano", "IT  QWERTY",
            new String[]{"\\", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "'", "ì"},
            new String[]{"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "è", "+"},
            new String[]{"A", "S", "D", "F", "G", "H", "J", "K", "L", "ò", "à", "ù"},
            new String[]{"<", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "-"}),
    PT("pt", "Português (Portugal)", "PT  QWERTY",
            new String[]{"\\", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "'", "«"},
            new String[]{"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "+", "´"},
            new String[]{"A", "S", "D", "F", "G", "H", "J", "K", "L", "Ç", "º", "~"},
            new String[]{"<", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "-"}),
    BR("br", "Português (Brasil)", "BR  ABNT2",
            new String[]{"'", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="},
            new String[]{"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "´", "["},
            new String[]{"A", "S", "D", "F", "G", "H", "J", "K", "L", "Ç", "~", "]"},
            new String[]{"\\", "Z", "X", "C", "V", "B", "N", "M", ",", ".", ";"});

    /** Les positions PC (touches US) de chaque rangée, dans le même ordre que les étiquettes. */
    static final TouchKey[] CHIFFRES = {TouchKey.KEY_OEM_3, TouchKey.KEY_1, TouchKey.KEY_2, TouchKey.KEY_3, TouchKey.KEY_4,
            TouchKey.KEY_5, TouchKey.KEY_6, TouchKey.KEY_7, TouchKey.KEY_8, TouchKey.KEY_9, TouchKey.KEY_0,
            TouchKey.KEY_OEM_MINUS, TouchKey.KEY_OEM_PLUS};
    static final TouchKey[] RANGEE_Q = {TouchKey.KEY_Q, TouchKey.KEY_W, TouchKey.KEY_E, TouchKey.KEY_R, TouchKey.KEY_T,
            TouchKey.KEY_Y, TouchKey.KEY_U, TouchKey.KEY_I, TouchKey.KEY_O, TouchKey.KEY_P, TouchKey.KEY_OEM_4, TouchKey.KEY_OEM_6};
    static final TouchKey[] RANGEE_A = {TouchKey.KEY_A, TouchKey.KEY_S, TouchKey.KEY_D, TouchKey.KEY_F, TouchKey.KEY_G,
            TouchKey.KEY_H, TouchKey.KEY_J, TouchKey.KEY_K, TouchKey.KEY_L, TouchKey.KEY_OEM_1, TouchKey.KEY_OEM_7, TouchKey.KEY_OEM_5};
    static final TouchKey[] RANGEE_Z = {TouchKey.KEY_OEM_102, TouchKey.KEY_Z, TouchKey.KEY_X, TouchKey.KEY_C, TouchKey.KEY_V,
            TouchKey.KEY_B, TouchKey.KEY_N, TouchKey.KEY_M, TouchKey.KEY_OEM_COMMA, TouchKey.KEY_OEM_PERIOD, TouchKey.KEY_OEM_2};

    public final String cle, nom, titre;
    final String[] chiffres, rangeeQ, rangeeA, rangeeZ;

    Disposition(String cle, String nom, String titre, String[] chiffres, String[] q, String[] a, String[] z) {
        this.cle = cle; this.nom = nom; this.titre = titre;
        this.chiffres = chiffres; this.rangeeQ = q; this.rangeeA = a; this.rangeeZ = z;
    }

    private static final String PREF = "touch_keyboard_layout";

    /** « auto » ou la clé d'une disposition. */
    public static String reglage(Context c) {
        SharedPreferences p = PreferenceManager.getDefaultSharedPreferences(c);
        if (!p.getBoolean("st_clavier_v2", false)) {
            // Tout le monde démarre en « Automatique » (langue du clavier du téléphone) ; on peut choisir ensuite.
            p.edit().putString(PREF, "auto").putBoolean("st_clavier_v2", true).apply();
        }
        return p.getString(PREF, "auto");
    }

    public static void choisir(Context c, String cle) {
        PreferenceManager.getDefaultSharedPreferences(c).edit().putString(PREF, cle).apply();
    }

    /** La disposition à afficher maintenant. */
    public static Disposition actuelle(Context c) {
        String r = reglage(c);
        for (Disposition d : values()) if (d.cle.equals(r)) return d;
        return deviner(c);
    }

    /** D'après la langue du clavier du téléphone (sinon la langue du téléphone). */
    public static Disposition deviner(Context c) {
        Locale l = null;
        try {
            InputMethodManager imm = (InputMethodManager) c.getSystemService(Context.INPUT_METHOD_SERVICE);
            InputMethodSubtype st = imm != null ? imm.getCurrentInputMethodSubtype() : null;
            if (st != null) {
                String tag = st.getLanguageTag();
                if (tag == null || tag.isEmpty()) tag = st.getLocale().replace('_', '-');
                if (tag != null && !tag.isEmpty()) l = Locale.forLanguageTag(tag);
            }
        } catch (Throwable ignore) {}
        if (l == null || l.getLanguage().isEmpty()) l = c.getResources().getConfiguration().getLocales().get(0);
        String langue = l.getLanguage(), pays = l.getCountry();
        switch (langue) {
            case "fr":
                if (pays.equals("CH")) return CH_FR;
                if (pays.equals("BE")) return BE;
                if (pays.equals("CA")) return US;
                return FR;
            case "de":
                return pays.equals("CH") ? CH_DE : DE;
            case "es": return ES;
            case "it": return pays.equals("CH") ? CH_FR : IT;
            case "pt": return pays.equals("BR") ? BR : PT;
            case "en": return pays.equals("GB") || pays.equals("IE") ? UK : US;
            default: return US;
        }
    }
}
