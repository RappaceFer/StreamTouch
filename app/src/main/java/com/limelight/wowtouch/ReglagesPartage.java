package com.limelight.wowtouch;

import android.app.Activity;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Environment;
import android.preference.PreferenceManager;
import android.provider.MediaStore;
import android.widget.Toast;

import com.limelight.R;

import org.json.JSONObject;

import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.Map;

/**
 * Streaming Touch, Made in Rappace : les réglages des commandes en un fichier.
 * Exporter : tailles, transparences, places des boutons et leurs styles → StreamTouch-reglages.json (Téléchargements),
 * puis le menu Partager. Réglages d'origine : à la première partie d'une nouvelle installation, l'appli prend
 * ceux de res/raw/st_reglages_defaut.json s'il existe (une appli déjà réglée garde les siens).
 */
final class ReglagesPartage {
    private static final String STYLES = "wowtouch_button_styles", FAIT = "touch_defaults_v2";

    private ReglagesPartage() {}

    private static boolean aExporter(String cle) {
        // Le choix du clavier dépend du pays de chacun : il ne voyage pas avec les réglages.
        return (cle.startsWith("touch_") || cle.startsWith("wow_touch_")) && !cle.equals(FAIT)
                && !cle.equals("touch_keyboard_mode");
    }

    /** Chaque valeur garde son type : b (oui/non), i (entier), f (décimal), s (texte). */
    private static JSONObject lire(SharedPreferences prefs, boolean tout) throws Exception {
        JSONObject sortie = new JSONObject();
        for (Map.Entry<String, ?> e : prefs.getAll().entrySet()) {
            if (!tout && !aExporter(e.getKey())) continue;
            Object v = e.getValue();
            String type = v instanceof Boolean ? "b" : v instanceof Integer ? "i" : v instanceof Float ? "f" : v instanceof String ? "s" : null;
            if (type == null) continue;
            sortie.put(e.getKey(), new JSONObject().put("t", type).put("v", v));
        }
        return sortie;
    }

    private static void ecrire(SharedPreferences prefs, JSONObject valeurs) throws Exception {
        SharedPreferences.Editor ed = prefs.edit();
        for (Iterator<String> it = valeurs.keys(); it.hasNext(); ) {
            String cle = it.next();
            JSONObject o = valeurs.getJSONObject(cle);
            switch (o.getString("t")) {
                case "b": ed.putBoolean(cle, o.getBoolean("v")); break;
                case "i": ed.putInt(cle, o.getInt("v")); break;
                case "f": ed.putFloat(cle, (float) o.getDouble("v")); break;
                case "s": ed.putString(cle, o.getString("v")); break;
                default: break;
            }
        }
        ed.apply();
    }

    static void exporter(Activity activite) {
        if (android.os.Build.VERSION.SDK_INT < 29) {
            Toast.makeText(activite, "Android 10+", Toast.LENGTH_LONG).show();
            return;
        }
        try {
            JSONObject tout = new JSONObject()
                    .put("format", "StreamTouch-reglages-1")
                    .put("general", lire(PreferenceManager.getDefaultSharedPreferences(activite), false))
                    .put("boutons", lire(activite.getSharedPreferences(STYLES, Context.MODE_PRIVATE), true));
            ContentValues fichier = new ContentValues();
            fichier.put(MediaStore.Downloads.DISPLAY_NAME, "StreamTouch-reglages.json");
            fichier.put(MediaStore.Downloads.MIME_TYPE, "application/json");
            fichier.put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);
            Uri uri = activite.getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, fichier);
            if (uri == null) throw new IllegalStateException("Téléchargements indisponible");
            try (OutputStream out = activite.getContentResolver().openOutputStream(uri)) {
                out.write(tout.toString(2).getBytes(StandardCharsets.UTF_8));
            }
            Toast.makeText(activite, activite.getString(R.string.st_r_exporte), Toast.LENGTH_LONG).show();
            Intent partager = new Intent(Intent.ACTION_SEND).setType("application/json")
                    .putExtra(Intent.EXTRA_STREAM, uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            activite.startActivity(Intent.createChooser(partager, activite.getString(R.string.st_r_exporter)));
        } catch (Exception e) {
            Toast.makeText(activite, e.getMessage(), Toast.LENGTH_LONG).show();
        }
    }

    /** Nouvelle installation : prend les réglages d'origine fournis avec l'appli, une seule fois. */
    static void reglagesDOrigine(Context c) {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(c);
        if (prefs.getBoolean(FAIT, false)) return;
        boolean dejaRegle = false;
        // Réglé à la main = une place, une taille, une transparence ou un bouton caché, ou un style de bouton.
        for (String cle : prefs.getAll().keySet()) {
            if (cle.startsWith("touch_") && !cle.equals("touch_keyboard_mode") && !cle.startsWith("touch_defaults")) dejaRegle = true;
        }
        if (!c.getSharedPreferences(STYLES, Context.MODE_PRIVATE).getAll().isEmpty()) dejaRegle = true;
        int id = c.getResources().getIdentifier("st_reglages_defaut", "raw", c.getPackageName());
        if (!dejaRegle && id != 0) {
            try (InputStream in = c.getResources().openRawResource(id)) {
                java.io.ByteArrayOutputStream lu = new java.io.ByteArrayOutputStream();
                byte[] morceau = new byte[8192];
                for (int n; (n = in.read(morceau)) > 0; ) lu.write(morceau, 0, n);
                JSONObject tout = new JSONObject(lu.toString("UTF-8"));
                ecrire(prefs, tout.getJSONObject("general"));
                ecrire(c.getSharedPreferences(STYLES, Context.MODE_PRIVATE), tout.getJSONObject("boutons"));
            } catch (Exception ignore) {
                // Fichier abîmé : on garde les réglages de base de l'appli.
            }
        }
        prefs.edit().putBoolean(FAIT, true).apply();
    }
}
