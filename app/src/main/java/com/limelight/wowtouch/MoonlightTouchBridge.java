package com.limelight.wowtouch;

import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.view.View;
import com.limelight.nvstream.NvConnection;
import com.limelight.nvstream.input.KeyboardPacket;
import com.limelight.nvstream.input.MouseButtonPacket;
import com.limelight.nvstream.jni.MoonBridge;
import java.util.EnumMap;
import java.util.EnumSet;

/** Adapts the original touch sink to the existing encrypted Moonlight input channel.
 * No local injection, root access, HTTP endpoint or additional network service.
 * Calls are confined to Android's UI thread. Short taps have a minimum hold time;
 * ordered events preserve release-camera / position / click / resume-camera ordering.
 */
public final class MoonlightTouchBridge {
    public enum Button { BUTTON_LEFT, BUTTON_RIGHT, BUTTON_SCROLL_UP, BUTTON_SCROLL_DOWN }
    public static final class EcranJeu {
        public final int width, height;
        EcranJeu(int w,int h) { width=Math.max(1,Math.min(32000,w)); height=Math.max(1,Math.min(32000,h)); }
    }
    public final EcranJeu ecranJeu;
    private final NvConnection connection;
    private final View streamView;
    private final Handler boucle=new Handler(Looper.getMainLooper());
    private final EnumMap<TouchKey,Long> requestedKeys=new EnumMap<>(TouchKey.class);
    private final EnumMap<Button,Long> requestedButtons=new EnumMap<>(Button.class);
    private final EnumSet<TouchKey> sentKeys=EnumSet.noneOf(TouchKey.class);
    private final EnumSet<Button> sentButtons=EnumSet.noneOf(Button.class);
    private boolean active;
    private long nextAt;
    private static final long MIN_TAP_MS=25;

    public MoonlightTouchBridge(NvConnection connection,View streamView,int width,int height) {
        this.connection=connection; this.streamView=streamView;
        ecranJeu=new EcranJeu(width,height);
    }
    public void activate() { active=true; nextAt=SystemClock.uptimeMillis(); }
    private long enqueue(Runnable event,long notBefore) {
        if (!active) return 0;
        long at=Math.max(Math.max(SystemClock.uptimeMillis(),nextAt),notBefore);
        nextAt=at;
        boucle.postAtTime(() -> { if (active) event.run(); },at);
        return at;
    }
    private byte modifiers() {
        int mask=0;
        if(sentKeys.contains(TouchKey.KEY_SHIFT_L)) mask|=KeyboardPacket.MODIFIER_SHIFT;
        if(sentKeys.contains(TouchKey.KEY_CTRL_L)) mask|=KeyboardPacket.MODIFIER_CTRL;
        if(sentKeys.contains(TouchKey.KEY_ALT_L)) mask|=KeyboardPacket.MODIFIER_ALT;
        return (byte)mask;
    }
    public void injectKeyPress(TouchKey key) {
        if(!active || requestedKeys.containsKey(key)) return;
        long at=enqueue(() -> {
            sentKeys.add(key);
            connection.sendKeyboardInput(key.wireCode,KeyboardPacket.KEY_DOWN,modifiers(),(byte)0 /* CH : touches normalisées pour le clavier suisse */);
        },0);
        requestedKeys.put(key,at);
    }
    public void injectKeyRelease(TouchKey key) {
        Long down=requestedKeys.remove(key);
        if(down==null || !active) return;
        enqueue(() -> {
            sentKeys.remove(key);
            connection.sendKeyboardInput(key.wireCode,KeyboardPacket.KEY_UP,modifiers(),(byte)0 /* CH : touches normalisées pour le clavier suisse */);
        },down+MIN_TAP_MS);
    }
    private byte mouseCode(Button b) {
        return b==Button.BUTTON_LEFT ? MouseButtonPacket.BUTTON_LEFT : MouseButtonPacket.BUTTON_RIGHT;
    }
    public void injectPointerButtonPress(Button button) {
        if(!active) return;
        if(button==Button.BUTTON_SCROLL_UP || button==Button.BUTTON_SCROLL_DOWN) {
            enqueue(() -> connection.sendMouseScroll((byte)(button==Button.BUTTON_SCROLL_UP ? 1 : -1)),0);
            return;
        }
        if(requestedButtons.containsKey(button)) return;
        long at=enqueue(() -> { sentButtons.add(button); connection.sendMouseButtonDown(mouseCode(button)); },0);
        requestedButtons.put(button,at);
    }
    public void injectPointerButtonRelease(Button button) {
        Long down=requestedButtons.remove(button);
        if(down==null || !active) return;
        enqueue(() -> { sentButtons.remove(button); connection.sendMouseButtonUp(mouseCode(button)); },down+MIN_TAP_MS);
    }
    public void injectText(String value) {
        if(!active || value==null || value.isEmpty())return;
        String t=value.length()>2000?value.substring(0,2000):value;
        enqueue(()->connection.sendUtf8Text(t),0);
    }
    /** A user-selected game command, never a background action or arbitrary script. */
    public void injectSlashCommand(String command) {
        if(!active || command==null || command.length()>160 || !command.startsWith("/")
                || command.indexOf('\n')>=0 || command.indexOf('\r')>=0)return;
        // Escape leaves any existing edit field first, so a pending chat draft is not sent.
        injectKeyPress(TouchKey.KEY_ESC);
        injectKeyRelease(TouchKey.KEY_ESC);
        enqueue(()->{},nextAt+80);
        injectKeyPress(TouchKey.KEY_ENTER);
        injectKeyRelease(TouchKey.KEY_ENTER);
        enqueue(()->connection.sendUtf8Text(command),nextAt+120);
        enqueue(()->{},nextAt+120);
        injectKeyPress(TouchKey.KEY_ENTER);
        injectKeyRelease(TouchKey.KEY_ENTER);
    }

    public void injectPointerMove(int x,int y) {
        short px=(short)Math.max(0,Math.min(ecranJeu.width-1,x));
        short py=(short)Math.max(0,Math.min(ecranJeu.height-1,y));
        enqueue(() -> connection.sendMousePosition(px,py,(short)ecranJeu.width,(short)ecranJeu.height),0);
    }
    public void injectPointerMoveDelta(int dx,int dy) {
        short x=(short)Math.max(Short.MIN_VALUE,Math.min(Short.MAX_VALUE,dx));
        short y=(short)Math.max(Short.MIN_VALUE,Math.min(Short.MAX_VALUE,dy));
        if(x!=0 || y!=0) enqueue(() -> connection.sendMouseMove(x,y),0);
    }
    /** Où est l'image du jeu dans les commandes : la vraie vue vidéo, sinon un calcul avec bandes noires. */
    public Commandes.Cadre viewport(View overlay) {
        if(streamView.getWidth()==0 || streamView.getHeight()==0)
            return Commandes.image(Math.max(1,overlay.getWidth()),Math.max(1,overlay.getHeight()),ecranJeu.width,ecranJeu.height);
        int[] video=new int[2], commandes=new int[2];
        streamView.getLocationOnScreen(video); overlay.getLocationOnScreen(commandes);
        float gauche=video[0]-commandes[0], haut=video[1]-commandes[1];
        return new Commandes.Cadre(gauche,haut,gauche+streamView.getWidth(),haut+streamView.getHeight());
    }
    /** Release only inputs owned by this overlay before the existing stream shuts down. */
    public void close() {
        boucle.removeCallbacksAndMessages(null);
        if(active) {
            for(Button b:sentButtons) connection.sendMouseButtonUp(mouseCode(b));
            for(TouchKey k:sentKeys) connection.sendKeyboardInput(k.wireCode,KeyboardPacket.KEY_UP,(byte)0,(byte)0 /* CH : touches normalisées pour le clavier suisse */);
        }
        active=false; requestedKeys.clear(); requestedButtons.clear(); sentKeys.clear(); sentButtons.clear(); nextAt=0;
    }
}
