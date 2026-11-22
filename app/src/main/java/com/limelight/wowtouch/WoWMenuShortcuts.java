package com.limelight.wowtouch;

/** Standard WoW shortcuts; no companion addon or alteration of the player's saved bindings. */
final class WoWMenuShortcuts {
    private WoWMenuShortcuts() {}

    static TouchKey[] keys(String action) {
        switch(action) {
            case "CHARACTER": return new TouchKey[]{TouchKey.KEY_C};
            case "SPELLBOOK": return new TouchKey[]{TouchKey.KEY_P};
            case "TALENTS": return new TouchKey[]{TouchKey.KEY_N};
            case "QUESTS": return new TouchKey[]{TouchKey.KEY_L};
            case "SKILLS": return new TouchKey[]{TouchKey.KEY_K};
            case "MAP": return new TouchKey[]{TouchKey.KEY_M};
            case "BAGS": return new TouchKey[]{TouchKey.KEY_B};
            case "SOCIAL": return new TouchKey[]{TouchKey.KEY_O};
            case "REPUTATION": return new TouchKey[]{TouchKey.KEY_U};
            case "HONOR": return new TouchKey[]{TouchKey.KEY_H};
            case "PET_SPELLS": return new TouchKey[]{TouchKey.KEY_SHIFT_L,TouchKey.KEY_I};
            case "GAME_MENU": return new TouchKey[]{TouchKey.KEY_ESC};
            case "SELF": return new TouchKey[]{TouchKey.KEY_F1};
            case "PARTY1": return new TouchKey[]{TouchKey.KEY_F2};
            case "PARTY2": return new TouchKey[]{TouchKey.KEY_F3};
            case "PARTY3": return new TouchKey[]{TouchKey.KEY_F4};
            case "PARTY4": return new TouchKey[]{TouchKey.KEY_F5};
            case "FRIEND": return new TouchKey[]{TouchKey.KEY_CTRL_L,TouchKey.KEY_TAB};
            case "ASSIST": return new TouchKey[]{TouchKey.KEY_F};
            case "PREVIOUS": return new TouchKey[]{TouchKey.KEY_SHIFT_L,TouchKey.KEY_TAB};
            case "NAMEPLATES": return new TouchKey[]{TouchKey.KEY_V};
            case "AUTO_RUN": return new TouchKey[]{TouchKey.KEY_NUMLOCK};
            case "WALK": return new TouchKey[]{TouchKey.KEY_DIVIDE};
            case "SIT": return new TouchKey[]{TouchKey.KEY_X};
            case "REPLY": return new TouchKey[]{TouchKey.KEY_R};
            case "PAGE": return new TouchKey[]{TouchKey.KEY_SHIFT_L,TouchKey.KEY_DOWN};
            default: return null;
        }
    }

    /** Commands below affect local UI or the selected target; no player chat message is composed. */
    static String command(String action) {
        switch(action) {
            case "MACROS": return "/macro";
            case "HELP": return "/help";
            case "FOLLOW": return "/follow";
            case "CORPSE": return "/target [@softinteract,exists,dead]";
            default: return null;
        }
    }

    static boolean visibleInMenu(String action) {
        // Map is still an on-screen control. The obsolete addon editor/presets are not menu actions.
        return !action.equals("MAP") && !action.equals("INSPECT") && !action.equals("UNDO")
                && !action.equals("SIZE_125") && !action.equals("SIZE_150") && !action.equals("SIZE_175");
    }

    static String hint(String action) {
        String command=command(action);
        if(command!=null) return action.equals("CORPSE") ? "Cible morte à proximité" : command;
        TouchKey[] keys=keys(action);
        if(keys==null) return "";
        StringBuilder text=new StringBuilder();
        for(TouchKey key:keys) {
            if(text.length()>0) text.append(" + ");
            switch(key) {
                case KEY_SHIFT_L: text.append("Maj");break;
                case KEY_CTRL_L: text.append("Ctrl");break;
                case KEY_ALT_L: text.append("Alt");break;
                case KEY_NUMLOCK: text.append("Verr. Num.");break;
                case KEY_DIVIDE: text.append("/ pavé numérique");break;
                case KEY_ESC: text.append("Échap");break;
                case KEY_DOWN: text.append("↓");break;
                case KEY_TAB: text.append("Tab");break;
                default: text.append(key.name().substring(4));
            }
        }
        return text.toString();
    }
}
