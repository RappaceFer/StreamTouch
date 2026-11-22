package com.limelight.wowtouch;

import com.limelight.R;

import android.app.Activity;
import android.content.ClipboardManager;
import android.content.ClipData;
import android.content.Context;
import android.widget.Toast;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;

/** Movable, translucent Swiss QWERTZ PC keyboard. Keys are sent through Moonlight, not an Android IME. */
final class PcKeyboardOverlay implements Clavier {
    private final Activity activite;
    private final MoonlightTouchBridge remote;
    private final FrameLayout parent;
    private final LinearLayout board;
    private final EnumSet<TouchKey> latched = EnumSet.noneOf(TouchKey.class);
    private final Map<String, TouchKey> mapping = new HashMap<>();
    private float dragX, dragY, startX, startY;
    private boolean dragging;
    private float scale;
    private int opacity;

    PcKeyboardOverlay(Activity activite, MoonlightTouchBridge remote, FrameLayout parent) {
        this.activite=activite; this.remote=remote; this.parent=parent;
        board=new LinearLayout(activite);
        board.setOrientation(LinearLayout.VERTICAL);
        board.setPadding(dp(5), dp(3), dp(5), dp(4));
        mapKeys();
        rebuild();
    }

    private int dp(float n) { return Math.round(n*activite.getResources().getDisplayMetrics().density); }

    private static TouchKey fromVk(int vk) {
        for(TouchKey key:TouchKey.values()) if ((key.wireCode & 0xFF)==vk) return key;
        return null;
    }
    private void mapKeys() {
        for(char c='A';c<='Z';c++) mapping.put(Character.toString(c),fromVk(c));
        for(int i=0;i<=9;i++) mapping.put(Integer.toString(i),fromVk(0x30+i));
        for(int i=1;i<=12;i++) mapping.put("F"+i,fromVk(0x6F+i));
        mapping.put("Esc",TouchKey.KEY_ESC);
        mapping.put("Tab",TouchKey.KEY_TAB);
        mapping.put("⌫",TouchKey.KEY_BACK);
        mapping.put("↵",TouchKey.KEY_ENTER);
        mapping.put("Espace",TouchKey.KEY_SPACE);
        mapping.put("←",TouchKey.KEY_LEFT); mapping.put("→",TouchKey.KEY_RIGHT);
        mapping.put("↑",TouchKey.KEY_UP); mapping.put("↓",TouchKey.KEY_DOWN);
        mapping.put("è",TouchKey.KEY_OEM_4); mapping.put("é",TouchKey.KEY_OEM_1);
        mapping.put("à",TouchKey.KEY_OEM_7); mapping.put("¨",TouchKey.KEY_OEM_6);
        mapping.put("§",TouchKey.KEY_OEM_3);
        mapping.put("<",TouchKey.KEY_OEM_102); mapping.put(",",TouchKey.KEY_OEM_COMMA);
        mapping.put(".",TouchKey.KEY_OEM_PERIOD);
        mapping.put("Caps",TouchKey.KEY_CAPS);
        // CH : position des touches d'un clavier suisse romand (touches normalisées côté PC).
        mapping.put("'",TouchKey.KEY_OEM_MINUS); mapping.put("-",TouchKey.KEY_OEM_2);
        mapping.put("Z",TouchKey.KEY_Y); mapping.put("Y",TouchKey.KEY_Z);
        mapping.put("^",TouchKey.KEY_OEM_PLUS); mapping.put("$",TouchKey.KEY_OEM_5);
    }

    private GradientDrawable bg(int color, int alpha, int border) {
        GradientDrawable g=new GradientDrawable();
        g.setColor((color & 0xFFFFFF) | (Math.min(255,Math.max(0,alpha))<<24));
        g.setCornerRadius(dp(5));
        g.setStroke(dp(0.65f),border);
        return g;
    }
    private TextView text(String label, int size, boolean bold) {
        TextView t=new TextView(activite);
        t.setText(label); t.setTextSize(size);
        t.setTextColor(Parure.CREME); t.setGravity(Gravity.CENTER);
        if(bold)t.setTypeface(Parure.LETTRES);
        return t;
    }
    private String[][] keys() {
        return new String[][] {
            {"Esc","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10"},
            {"§","1","2","3","4","5","6","7","8","9","0","'","^","⌫"},
            {"Tab","Q","W","E","R","T","Z","U","I","O","P","è","¨"},
            {"Caps","A","S","D","F","G","H","J","K","L","é","à","$","↵"},
            {"⇧","<","Y","X","C","V","B","N","M",",",".","-","⇧"},
            {"Ctrl","Win","Alt","Espace","AltGr","←","↑","↓","→"}
        };
    }
    private TouchKey modifier(String label) {
        switch(label) {
            case "Ctrl":return TouchKey.KEY_CTRL_L;
            case "Win":return TouchKey.KEY_LWIN;
            case "Alt":return TouchKey.KEY_ALT_L;
            case "AltGr":return TouchKey.KEY_ALT_R;
            case "⇧":return TouchKey.KEY_SHIFT_L;
            default:return null;
        }
    }
    private void chord(TouchKey modifier,TouchKey key) {
        remote.injectKeyPress(modifier);
        remote.injectKeyPress(key);
        remote.injectKeyRelease(key);
        remote.injectKeyRelease(modifier);
    }
    private void pastePhoneClipboard(){
        ClipboardManager clipboard=(ClipboardManager)activite.getSystemService(Context.CLIPBOARD_SERVICE);
        if(clipboard==null || !clipboard.hasPrimaryClip())return;
        ClipData clip=clipboard.getPrimaryClip();
        if(clip==null || clip.getItemCount()==0)return;
        CharSequence text=clip.getItemAt(0).coerceToText(activite);
        if(text!=null && text.length()>0)remote.injectText(text.toString());
    }
    private void releaseModifiers() {
        for(TouchKey k:latched) remote.injectKeyRelease(k);
        latched.clear();
        refreshLabels();
    }
    private void refreshLabels() {
        for(int i=0;i<board.getChildCount();i++) {
            View row=board.getChildAt(i);
            if(!(row instanceof LinearLayout))continue;
            LinearLayout linear=(LinearLayout)row;
            for(int j=0;j<linear.getChildCount();j++) {
                View item=linear.getChildAt(j);
                if(item instanceof TextView) {
                    TextView t=(TextView)item;
                    String s=t.getText().toString().replace("●","");
                    TouchKey mod=modifier(s);
                    if(mod!=null) t.setText(latched.contains(mod)?"●"+s:s);
                }
            }
        }
    }
    private void modifierTap(TouchKey mod) {
        if(latched.remove(mod))remote.injectKeyRelease(mod);
        else {latched.add(mod);remote.injectKeyPress(mod);}
        refreshLabels();
    }
    private void addKey(LinearLayout row,String label) {
        TextView t=text(label,label.startsWith("F")&&label.length()>1?8:10,false);
        int alpha=Math.max(18,Math.min(255,Math.round(255*opacity/100f)));
        t.setBackground(bg(0x3A2616,alpha,0xB0C9A15A));
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(0,dp(30*scale),label.equals("Espace")?4:label.equals("Tab")||label.equals("↵")||label.equals("⌫")?1.5f:1);
        p.setMargins(dp(1.5f),dp(1.5f),dp(1.5f),dp(1.5f));
        row.addView(t,p);
        TouchKey mod=modifier(label);
        TouchKey key=mapping.get(label);
        t.setOnTouchListener((v,event)->{
            int action=event.getActionMasked();
            if(action==MotionEvent.ACTION_DOWN) {
                if(mod!=null) return true;
                if(key!=null)remote.injectKeyPress(key);
                t.setAlpha(.65f);
                return true;
            }
            if(action==MotionEvent.ACTION_UP||action==MotionEvent.ACTION_CANCEL){
                if(action==MotionEvent.ACTION_UP && mod!=null) modifierTap(mod);
                else if(key!=null){remote.injectKeyRelease(key); releaseModifiers();}
                t.setAlpha(1f);
                return true;
            }
            return true;
        });
    }
    private void rebuild() {
        scale=TouchConfig.getKeyboardScale(activite);
        opacity=TouchConfig.getKeyboardOpacity(activite);
        board.removeAllViews();
        int bgAlpha=Math.round(255*opacity/100f*.28f);
        board.setBackground(bg(0x1A100A,bgAlpha,0xB0D9A84A));
        LinearLayout head=new LinearLayout(activite);
        head.setOrientation(LinearLayout.HORIZONTAL);
        TextView drag=text("☰  CH-FR  QWERTZ   •   "+activite.getString(R.string.st_s_glisser),10,true);
        drag.setBackground(bg(0x4A3018,Math.max(32,opacity*2),0x99D9A84A));
        head.addView(drag,new LinearLayout.LayoutParams(0,dp(27*scale),1));
        drag.setOnTouchListener((v,e)->{
            // Glisser la barre du haut déplace tout le clavier ; la place est gardée en lâchant.
            int geste=e.getActionMasked();
            if(geste==MotionEvent.ACTION_DOWN){
                dragX=e.getRawX();dragY=e.getRawY();startX=board.getX();startY=board.getY();dragging=true;
            }else if(geste==MotionEvent.ACTION_MOVE){
                if(dragging)move(startX+e.getRawX()-dragX,startY+e.getRawY()-dragY);
            }else if(geste==MotionEvent.ACTION_UP){
                if(dragging){dragging=false;savePosition();}
            }else if(geste==MotionEvent.ACTION_CANCEL)dragging=false;
            return true;
        });
        TextView voice=text("🎤",14,true);
        voice.setContentDescription("Dictée vocale français suisse");
        voice.setBackground(bg(0x2E1D0F,100,0xA6C9A15A));
        head.addView(voice,new LinearLayout.LayoutParams(dp(32*scale),dp(27*scale)));
        voice.setOnClickListener(v->{
            releaseModifiers();
            if(activite instanceof com.limelight.Game)
                ((com.limelight.Game)activite).startWowTouchDictation();
        });
        TextView copy=text(activite.getString(R.string.st_s_copier),9,false);
        copy.setBackground(bg(0x2E1D0F,80,0xA6C9A15A));
        head.addView(copy,new LinearLayout.LayoutParams(dp(45*scale),dp(27*scale)));
        copy.setOnClickListener(v->chord(TouchKey.KEY_CTRL_L,TouchKey.KEY_C));
        TextView paste=text(activite.getString(R.string.st_s_coller),9,false);
        paste.setBackground(bg(0x2E1D0F,80,0xA6C9A15A));
        head.addView(paste,new LinearLayout.LayoutParams(dp(43*scale),dp(27*scale)));
        paste.setOnClickListener(v->chord(TouchKey.KEY_CTRL_L,TouchKey.KEY_V));
        paste.setOnLongClickListener(v->{
            pastePhoneClipboard();
            Toast.makeText(activite,activite.getString(R.string.st_s_presse),Toast.LENGTH_SHORT).show();
            return true;
        });
        TextView android=text("Android",9,false);android.setBackground(bg(0x2E1D0F,80,0xA6C9A15A));
        head.addView(android,new LinearLayout.LayoutParams(dp(57*scale),dp(27*scale)));
        android.setOnClickListener(v->{hide(); if(activite instanceof com.limelight.Game)((com.limelight.Game)activite).toggleKeyboard();});
        TextView close=text("✕",14,true);close.setBackground(bg(0x2E1D0F,100,0xA6C9A15A));
        head.addView(close,new LinearLayout.LayoutParams(dp(31*scale),dp(27*scale)));
        close.setOnClickListener(v->hide());
        board.addView(head,new LinearLayout.LayoutParams(-1,-2));
        for(String[] labels:keys()){
            LinearLayout row=new LinearLayout(activite); row.setOrientation(LinearLayout.HORIZONTAL);
            for(String label:labels)addKey(row,label);
            board.addView(row,new LinearLayout.LayoutParams(-1,-2));
        }
        refreshLabels();
    }
    private void move(float x,float y) {
        float mx=Math.max(0,parent.getWidth()-board.getWidth());
        float my=Math.max(0,parent.getHeight()-board.getHeight());
        board.setX(Math.max(0,Math.min(mx,x)));
        board.setY(Math.max(0,Math.min(my,y)));
    }
    private void savePosition() {
        if(parent.getWidth()>0&&parent.getHeight()>0)
            TouchConfig.setKeyboardPosition(activite,board.getX()/parent.getWidth(),board.getY()/parent.getHeight());
    }
    private int keyboardWidth() {
        float fraction=Math.min(.96f,.94f*TouchConfig.getKeyboardScale(activite));
        return Math.max(dp(270),Math.min(parent.getWidth(),Math.round(parent.getWidth()*fraction)));
    }
    @Override public void toggle() { if(board.getParent()!=null)hide();else show(); }
    @Override public void show() {
        if(board.getParent()!=null)return;
        rebuild();
        int width=keyboardWidth();
        parent.addView(board,new FrameLayout.LayoutParams(width,-2,Gravity.TOP|Gravity.LEFT));
        parent.post(()->{
            float x=TouchConfig.getKeyboardX(activite),y=TouchConfig.getKeyboardY(activite);
            move(x<0?(parent.getWidth()-board.getWidth())/2:x*parent.getWidth(),
                 y<0?parent.getHeight()-board.getHeight()-dp(8):y*parent.getHeight());
        });
    }
    boolean isShowing() {return board.getParent()!=null;}
    @Override public void refresh() {
        if(!isShowing())return;
        float x=board.getX(),y=board.getY();
        releaseModifiers();rebuild();
        FrameLayout.LayoutParams p=(FrameLayout.LayoutParams)board.getLayoutParams();
        p.width=keyboardWidth();board.setLayoutParams(p);
        parent.post(()->move(x,y));
    }
    @Override public void hide() {
        releaseModifiers();
        if(board.getParent()!=null){savePosition();parent.removeView(board);}
    }
}
