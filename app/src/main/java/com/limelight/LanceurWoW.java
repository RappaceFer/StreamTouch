package com.limelight;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Bundle;

/**
 * StreamTouch : l'icône « WoW » de la liste des applis. Une vraie icône d'appli (pas un raccourci épinglé),
 * pour que l'écran d'accueil l'affiche comme StreamTouch, sans rond blanc autour.
 * Elle apparaît quand on choisit « Créer un raccourci » sur une appli du PC, et lance cette appli
 * comme le ferait le raccourci (ShortcutTrampoline).
 */
public class LanceurWoW extends Activity {
    private static final String PREFS = "lanceur_wow";

    /** Retient l'appli du PC à lancer et fait apparaître l'icône « WoW » dans la liste des applis. */
    public static void activer(Context c, String uuid, String nomPc, String appNom, String appId, boolean hdr) {
        c.getSharedPreferences(PREFS, MODE_PRIVATE).edit()
                .putString("uuid", uuid).putString("nomPc", nomPc)
                .putString("appNom", appNom).putString("appId", appId).putBoolean("hdr", hdr).apply();
        c.getPackageManager().setComponentEnabledSetting(new ComponentName(c, LanceurWoW.class),
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        SharedPreferences p = getSharedPreferences(PREFS, MODE_PRIVATE);
        String uuid = p.getString("uuid", null);
        Intent i;
        if (uuid == null) {
            i = new Intent(this, PcView.class);
        } else {
            i = new Intent(this, ShortcutTrampoline.class);
            i.putExtra(AppView.NAME_EXTRA, p.getString("nomPc", ""));
            i.putExtra(AppView.UUID_EXTRA, uuid);
            i.putExtra(Game.EXTRA_APP_NAME, p.getString("appNom", ""));
            i.putExtra(Game.EXTRA_APP_ID, p.getString("appId", ""));
            i.putExtra(Game.EXTRA_APP_HDR, p.getBoolean("hdr", false));
            i.setAction(Intent.ACTION_DEFAULT);
        }
        startActivity(i);
        finish();
    }
}
