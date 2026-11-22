package com.limelight.wowtouch;
import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
/** Streaming Touch, Made in Rappace : les réglages des commandes tactiles (mêmes clés qu'avant, rien n'est perdu). */
public final class TouchConfig {
    private TouchConfig() {}
    private static SharedPreferences prefs(Context c) { return PreferenceManager.getDefaultSharedPreferences(c); }
    /** La case « Commandes tactiles Streaming Touch » des paramètres de l'appli. */
    public static boolean tactileActif(Context c) { return prefs(c).getBoolean("wow_touch_enabled", true); }

    // V0.2: independent visual settings, and normalized per-control positions.
    private static float bound(float v,float lo,float hi){ return Math.max(lo,Math.min(hi,v)); }
    public static int getKeyboardOpacity(Context c) {return prefs(c).getInt("touch_keyboard_opacity",30);}
    public static void setKeyboardOpacity(Context c,int v){prefs(c).edit().putInt("touch_keyboard_opacity",Math.round(bound(v,0,100))).apply();}
    public static float getKeyboardScale(Context c){return bound(prefs(c).getFloat("touch_keyboard_size",1.0f),.65f,1.4f);}
    public static void setKeyboardScale(Context c,float v){prefs(c).edit().putFloat("touch_keyboard_size",bound(v,.65f,1.4f)).apply();}
    public static float getKeyboardX(Context c){return prefs(c).getFloat("touch_keyboard_x",-1);}
    public static float getKeyboardY(Context c){return prefs(c).getFloat("touch_keyboard_y",-1);}
    public static void setKeyboardPosition(Context c,float x,float y){
        prefs(c).edit().putFloat("touch_keyboard_x",bound(x,0,1)).putFloat("touch_keyboard_y",bound(y,0,1)).apply();
    }
    public static int getControlsOpacity(Context c){return prefs(c).getInt("touch_controls_opacity",100);}
    public static void setControlsOpacity(Context c,int v){prefs(c).edit().putInt("touch_controls_opacity",Math.round(bound(v,0,100))).apply();}
    public static float getStickScale(Context c){return bound(prefs(c).getFloat("touch_stick_size",1.0f),.5f,2.0f);}
    public static void setStickScale(Context c,float v){prefs(c).edit().putFloat("touch_stick_size",bound(v,.5f,2.0f)).apply();}
    public static float getCameraStickScale(Context c){return bound(prefs(c).getFloat("touch_camera_stick_size",1.0f),.5f,2.0f);}
    public static void setCameraStickScale(Context c,float v){prefs(c).edit().putFloat("touch_camera_stick_size",bound(v,.5f,2.0f)).apply();}
    public static int getStickOpacity(Context c){return prefs(c).getInt("touch_stick_opacity",100);}
    public static void setStickOpacity(Context c,int v){prefs(c).edit().putInt("touch_stick_opacity",Math.round(bound(v,0,100))).apply();}
    public static int getMoveStickOpacity(Context c){return prefs(c).getInt("touch_move_stick_opacity",getStickOpacity(c));}
    public static void setMoveStickOpacity(Context c,int v){prefs(c).edit().putInt("touch_move_stick_opacity",Math.round(bound(v,0,100))).apply();}
    public static int getCameraStickOpacity(Context c){return prefs(c).getInt("touch_camera_stick_opacity",getStickOpacity(c));}
    public static void setCameraStickOpacity(Context c,int v){prefs(c).edit().putInt("touch_camera_stick_opacity",Math.round(bound(v,0,100))).apply();}
    public static boolean isControlEnabled(Context c,int i){return prefs(c).getBoolean("touch_control_visible_"+i,true);}
    public static void setControlEnabled(Context c,int i,boolean enabled){prefs(c).edit().putBoolean("touch_control_visible_"+i,enabled).apply();}
    public static int getButtonOpacity(Context c){return prefs(c).getInt("touch_button_opacity",100);}
    public static void setButtonOpacity(Context c,int v){prefs(c).edit().putInt("touch_button_opacity",Math.round(bound(v,0,100))).apply();}
    public static float getButtonScale(Context c){return bound(prefs(c).getFloat("touch_button_size",1.0f),.7f,1.5f);}
    public static void setButtonScale(Context c,float v){prefs(c).edit().putFloat("touch_button_size",bound(v,.7f,1.5f)).apply();}
    public static float getControlX(Context c,int index){return prefs(c).getFloat("touch_control_"+index+"_x",-1f);}
    public static float getControlY(Context c,int index){return prefs(c).getFloat("touch_control_"+index+"_y",-1f);}
    public static void setControlPosition(Context c,int index,float x,float y){
        prefs(c).edit().putFloat("touch_control_"+index+"_x",bound(x,0,1))
            .putFloat("touch_control_"+index+"_y",bound(y,0,1)).apply();
    }
    /** Quel clavier ouvre le bouton Clavier : auto (selon le pays du téléphone), le suisse de l'appli, ou celui du téléphone. */
    public static final int CLAVIER_AUTO = 0, CLAVIER_SUISSE = 1, CLAVIER_TELEPHONE = 2;
    public static int getClavierChoix(Context c) {
        SharedPreferences p = prefs(c);
        if (!p.contains("touch_keyboard_mode")) {
            // Première fois : une appli déjà installée avant (mise à jour) garde le clavier suisse qu'elle avait.
            int choix = CLAVIER_AUTO;
            try {
                android.content.pm.PackageInfo info = c.getPackageManager().getPackageInfo(c.getPackageName(), 0);
                if (info.lastUpdateTime > info.firstInstallTime) choix = CLAVIER_SUISSE;
            } catch (Exception ignore) {
                // Sans information, on reste en auto.
            }
            p.edit().putInt("touch_keyboard_mode", choix).apply();
            return choix;
        }
        return p.getInt("touch_keyboard_mode", CLAVIER_AUTO);
    }
    public static void setClavierChoix(Context c, int choix) { prefs(c).edit().putInt("touch_keyboard_mode", choix).apply(); }
    /** Vrai si le bouton Clavier doit ouvrir le clavier suisse de l'appli. */
    public static boolean clavierSuisse(Context c) {
        int choix = getClavierChoix(c);
        if (choix == CLAVIER_AUTO) return "CH".equalsIgnoreCase(java.util.Locale.getDefault().getCountry());
        return choix == CLAVIER_SUISSE;
    }
    /** Le mode au lancement du jeu : tactile (par défaut) ou manette. */
    public static boolean demarrageManette(Context c) { return prefs(c).getBoolean("touch_start_controller", false); }
    public static void setDemarrageManette(Context c, boolean v) { prefs(c).edit().putBoolean("touch_start_controller", v).apply(); }
    public static void resetControlPositions(Context c){
        SharedPreferences.Editor e=prefs(c).edit();
        for(int i=-1;i<20;i++){e.remove("touch_control_"+i+"_x");e.remove("touch_control_"+i+"_y");}
        e.apply();
    }
}
