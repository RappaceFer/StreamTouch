-- Streaming Touch : les réglages de base, ceux de Papa Rapace (l'auteur).
-- Un personnage qui n'a encore aucun réglage les prend à sa première connexion : tout le réglage général
-- (barres, chat, menu rond, apparence), et l'arc de sorts. Un chasseur reçoit l'arc complet de Papa Rapace ;
-- les autres classes gardent sa disposition (taille, place, forme) avec les sorts conseillés de leur classe.
-- Un modèle enregistré avec « Enregistrer comme modèle » (/stouch, onglet Commandes) passe avant celui-ci.
local _, ST = ...
local arc = {
            arcFrom = 190,
            arcTo = 119,
            arrowPos = {
                x = -494.8495,
                y = -34.5345,
            },
            arrowsOff = true,
            gap = -16,
            joy = 1,
            keyColor = "aucun",
            keyShape = "round",
            labels = false,
            open = "fixed",
            pages = {
                {
                    color = "aucun",
                    combat = true,
                    icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
                    items = {
                        {
                            a = "TEXT",
                            hold = {
                                a = "TEXT",
                                icon = "Interface\\Icons\\Ability_Tracking",
                                label = "Suivre",
                                text = "/petfollow",
                            },
                            icon = "Interface\\Icons\\Ability_GhoulFrenzy",
                            label = "Attaque",
                            name = "Attaque",
                            text = "/petattack",
                        },
                        {
                            a = "SPELL",
                            hold = {
                                a = "SPELL",
                                spell = 19434,
                            },
                            label = "Arcanes",
                            spell = 3044,
                        },
                        {
                            a = "SPELL",
                            hold = {
                                a = "SPELL",
                                spell = 3043,
                            },
                            label = "Serpent",
                            spell = 1978,
                        },
                        {
                            a = "SPELL",
                            hold = {
                                a = "SPELL",
                                spell = 1510,
                            },
                            label = "Multiples",
                            spell = 2643,
                        },
                        {
                            a = "SPELL",
                            label = "Marque",
                            spell = 1130,
                        },
                        {
                            a = "SPELL",
                            hold = {
                                a = "SPELL",
                                spell = 5384,
                            },
                            label = "Choc",
                            spell = 5116,
                        },
                        {
                            a = "SPELL",
                            label = "Tir rapide",
                            spell = 3045,
                        },
                        {
                            a = "SPELL",
                            label = "Scorpide",
                            spell = 3043,
                        },
                        {
                            a = "FLYOUT",
                            flyout = 253,
                            icon = 132159,
                            label = "Aspect",
                        },
                        {
                            a = "GROUP",
                            uid = 1,
                        },
                        {
                            a = "GROUP",
                            color = "aucun",
                            name = "Piege",
                            uid = 4,
                        },
                    },
                    name = "Tirs",
                },
                {
                    color = "aucun",
                    icon = "Interface\\Icons\\Ability_MeleeDamage",
                    items = {
                        {
                            a = "SPELL",
                            hold = {
                                a = "SPELL",
                                spell = 1495,
                            },
                            label = "Raptor",
                            spell = 2973,
                        },
                        {
                            a = "SPELL",
                            hold = {
                                a = "SPELL",
                                spell = 781,
                            },
                            label = "Coupure",
                            spell = 2974,
                        },
                        {
                            a = "SPELL",
                            label = "Attaque",
                            spell = 6603,
                        },
                        {
                            a = "SPELL",
                            label = "Feindre",
                            spell = 5384,
                        },
                        {
                            a = "SPELL",
                            hold = {
                                a = "SPELL",
                                spell = 19263,
                            },
                            label = "Contre",
                            spell = 19306,
                        },
                        {
                            a = "SPELL",
                            label = "Dissuasion",
                            spell = 19263,
                        },
                        {
                            a = "SPELL",
                            label = "Wyverne",
                            spell = 19386,
                        },
                        {
                            a = "SPELL",
                            hold = {
                                a = "SPELL",
                                spell = 6991,
                            },
                            name = "Guérison du familier",
                            spell = 3111,
                        },
                    },
                    layer = true,
                    name = "Mêlée",
                    uid = 3,
                },
                {
                    color = "aucun",
                    icon = "Interface\\Icons\\Ability_Hunter_BeastCall",
                    items = {
                        {
                            a = "SPELL",
                            hold = {
                                a = "SPELL",
                                spell = 2641,
                            },
                            label = "Appeler",
                            spell = 883,
                        },
                        {
                            a = "SPELL",
                            hold = {
                                a = "SPELL",
                                spell = 136,
                            },
                            label = "Ranimer",
                            spell = 982,
                        },
                        {
                            a = "TEXT",
                            hold = {
                                a = "TEXT",
                                icon = "Interface\\Icons\\Ability_Seal",
                                label = "Passif",
                                text = "/petpassive",
                            },
                            icon = "Interface\\Icons\\Ability_Defend",
                            label = "Défensif",
                            name = "Défensif",
                            text = "/petdefensive",
                        },
                        {
                            a = "TEXT",
                            hold = {
                                a = "TEXT",
                                icon = "Interface\\Icons\\Ability_Tracking",
                                label = "Suivre",
                                text = "/petfollow",
                            },
                            icon = "Interface\\Icons\\Spell_Nature_TimeStop",
                            label = "Rester",
                            name = "Rester",
                            text = "/petstay",
                        },
                        {
                            a = "TEXT",
                            icon = "Interface\\Icons\\Ability_Racial_BloodRage",
                            label = "Agressif",
                            name = "Agressif",
                            text = "/petaggressive",
                        },
                        {
                            a = "PETACTION",
                            name = "Déplacer",
                            slot = 3,
                        },
                        {
                            a = "PETACTION",
                            name = "Aider",
                            slot = 8,
                        },
                    },
                    name = "Familier",
                    uid = 1,
                },
                {
                    color = "bleu",
                    icon = 135840,
                    items = {
                        {
                            a = "SPELL",
                            name = "Piège givrant",
                            spell = 1499,
                        },
                        {
                            a = "SPELL",
                            name = "Piège d'Immolation",
                            spell = 13795,
                        },
                    },
                    name = "Piege",
                    uid = 4,
                },
            },
            pos = {
                x = 1560.9331,
                y = 120.0001,
            },
            rolesV1 = true,
            scale = 1.4,
            setupV2 = true,
            setupV3 = true,
            shape = "round",
            stickR = 205.6667,
            uidNext = 4,
            v = 2,
        }
local forme = {}
for k, v in pairs(arc) do if k ~= "pages" then forme[k] = v end end
ST.DEFAUT = {
    source = "Papa Rapace (réglages de base)",
    integre = true,
    general = {
        bigPos = {
            x = 33.6,
            y = 636,
        },
        bigRows = 6,
        bigWidth = 0.9,
        chatPos = {
            x = 37.2,
            y = 627,
        },
        chatRows = 4,
        chatWidth = 0.9,
        hud = {
            BagsBar = {
                alpha = 1,
                points = {
                    {
                        "BOTTOMLEFT",
                        "MicroMenuContainer",
                        "BOTTOMRIGHT",
                        7.0,
                        -4,
                    },
                },
                scale = 1,
                shown = false,
            },
            BuffFrame = {
                alpha = 1,
                points = {
                    {
                        "TOPRIGHT",
                        "UIParent",
                        "TOPRIGHT",
                        -255,
                        -10,
                    },
                },
                scale = 1,
            },
            ChatAlertFrame = {
                alpha = 1,
                points = {
                    {
                        "BOTTOMLEFT",
                        "ChatFrame1ButtonFrame",
                        "TOPLEFT",
                        0,
                        27.0,
                    },
                },
                scale = 1,
            },
            ChatFrame1ButtonFrame = {
                alpha = 1,
                points = {
                    {
                        "TOPRIGHT",
                        "ChatFrame1Background",
                        "TOPLEFT",
                        -3.0,
                        -3.0,
                    },
                    {
                        "BOTTOMRIGHT",
                        "ChatFrame1Background",
                        "BOTTOMLEFT",
                        -3.0,
                        6.0,
                    },
                },
                scale = 1,
            },
            ChatFrameToggleVoiceDeafenButton = {
                alpha = 1,
                points = {
                    {
                        "TOP",
                        "ChatFrameChannelButton",
                        "BOTTOM",
                        0,
                        -2,
                    },
                },
                scale = 1,
            },
            ChatFrameToggleVoiceMuteButton = {
                alpha = 1,
                points = {
                    {
                        "TOP",
                        "ChatFrameToggleVoiceDeafenButton",
                        "BOTTOM",
                        0,
                        -2,
                    },
                },
                scale = 1,
            },
            DebuffFrame = {
                alpha = 1,
                points = {
                    {
                        "TOPRIGHT",
                        "UIParent",
                        "TOPRIGHT",
                        -270.0,
                        -155,
                    },
                },
                scale = 1,
            },
            ["MainActionBar.ActionBarPageNumber"] = {
                alpha = 1,
                points = {
                    {
                        "BOTTOMRIGHT",
                        "MainActionBar",
                        "BOTTOMLEFT",
                        -4,
                        9,
                    },
                },
                scale = 1,
                shown = true,
            },
            ["MainActionBar.BorderArt"] = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "MainActionBar",
                        "TOPLEFT",
                        -6.0,
                        6.0,
                    },
                    {
                        "BOTTOMRIGHT",
                        "MainActionBar",
                        "BOTTOMRIGHT",
                        4,
                        -5,
                    },
                },
                scale = 1,
                shown = true,
            },
            ["MainActionBar.EndCaps"] = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "MainActionBar",
                        "TOPLEFT",
                        0,
                        0,
                    },
                    {
                        "BOTTOMRIGHT",
                        "MainActionBar",
                        "BOTTOMRIGHT",
                        0,
                        0,
                    },
                },
                scale = 1,
                shown = true,
            },
            MicroButtonAndBagsBar = {
                alpha = 1,
                points = {
                    {
                        "BOTTOMRIGHT",
                        "UIParent",
                        "BOTTOMRIGHT",
                        -6.0,
                        6.0,
                    },
                },
                scale = 1,
                shown = false,
            },
            MicroMenu = {
                alpha = 1,
                points = {
                    {
                        "BOTTOMRIGHT",
                        "MicroMenuContainer",
                        "BOTTOMRIGHT",
                        0,
                        0,
                    },
                },
                scale = 1,
                shown = false,
            },
            MicroMenuContainer = {
                alpha = 1,
                points = {
                    {
                        "BOTTOM",
                        "UIParent",
                        "BOTTOM",
                        116.5,
                        6.0,
                    },
                },
                scale = 1,
                shown = false,
            },
            MinimapCluster = {
                alpha = 1,
                points = {
                    {
                        "TOPRIGHT",
                        "UIParent",
                        "TOPRIGHT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            MultiBar5 = {
                alpha = 1,
                points = {
                    {
                        "TOP",
                        "UIParent",
                        "CENTER",
                        0,
                        0,
                    },
                },
                scale = 1,
                shown = false,
            },
            MultiBar6 = {
                alpha = 1,
                points = {
                    {
                        "TOP",
                        "UIParent",
                        "CENTER",
                        0,
                        -50,
                    },
                },
                scale = 1,
                shown = false,
            },
            MultiBar7 = {
                alpha = 1,
                points = {
                    {
                        "TOP",
                        "UIParent",
                        "CENTER",
                        0,
                        -100,
                    },
                },
                scale = 1,
                shown = false,
            },
            MultiBarBottomLeft = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "UIParent",
                        "TOPLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
                shown = false,
            },
            MultiBarBottomRight = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "UIParent",
                        "TOPLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
                shown = false,
            },
            ObjectiveTrackerFrame = {
                alpha = 1,
                points = {
                    {
                        "TOPRIGHT",
                        "RightManagedFrameContainer",
                        "TOPRIGHT",
                        0,
                        -121,
                    },
                },
                scale = 1,
            },
            ["PartyFrame.Background"] = {
                alpha = 0.502,
                points = {
                    {
                        "TOPLEFT",
                        "PartyFrame",
                        "TOPLEFT",
                        -5,
                        6.0,
                    },
                    {
                        "BOTTOMLEFT",
                        "PartyFrame",
                        "BOTTOMLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            ["PartyFrame.MemberFrame1"] = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "PartyFrame",
                        "TOPLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            ["PartyFrame.MemberFrame2"] = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "PartyFrame",
                        "TOPLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            ["PartyFrame.MemberFrame3"] = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "PartyFrame",
                        "TOPLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            ["PartyFrame.MemberFrame4"] = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "PartyFrame",
                        "TOPLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            PetActionBar = {
                alpha = 1,
                points = {
                    {
                        "BOTTOM",
                        "UIParent",
                        "BOTTOM",
                        0,
                        -4,
                    },
                },
                scale = 1,
            },
            PlayerFrame = {
                alpha = 1,
                points = {
                    {
                        "BOTTOMRIGHT",
                        "UIParent",
                        "BOTTOM",
                        -185,
                        295.0,
                    },
                },
                scale = 1,
            },
            PossessActionBar = {
                alpha = 1,
                points = {
                    {
                        "BOTTOM",
                        "UIParent",
                        "BOTTOM",
                        0,
                        -4,
                    },
                },
                scale = 1,
            },
            QuickJoinToastButton = {
                alpha = 1,
                points = {},
                scale = 1,
            },
            StanceBar = {
                alpha = 1,
                points = {
                    {
                        "BOTTOM",
                        "UIParent",
                        "BOTTOM",
                        0,
                        -4,
                    },
                },
                scale = 1,
            },
            StatusTrackingBarManager = {
                alpha = 1,
                points = {
                    {
                        "BOTTOMLEFT",
                        "UIParent",
                        "BOTTOMLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            SwingTimerMainHandFrame = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "UIParent",
                        "TOPLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            SwingTimerOffHandFrame = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "UIParent",
                        "TOPLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            SwingTimerRangedFrame = {
                alpha = 1,
                points = {
                    {
                        "TOPLEFT",
                        "UIParent",
                        "TOPLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            TargetFrame = {
                alpha = 1,
                points = {
                    {
                        "BOTTOMLEFT",
                        "UIParent",
                        "BOTTOM",
                        185,
                        295.0,
                    },
                },
                scale = 1,
            },
            TextToSpeechButtonFrame = {
                alpha = 1,
                points = {
                    {
                        "BOTTOMLEFT",
                        "ChatAlertFrame",
                        "BOTTOMLEFT",
                        0,
                        0,
                    },
                },
                scale = 1,
            },
            UIWidgetTopCenterContainerFrame = {
                alpha = 1,
                points = {
                    {
                        "TOP",
                        "UIParent",
                        "TOP",
                        0,
                        -15,
                    },
                },
                scale = 1,
            },
        },
        minimapAngle = -162.8001,
        radialPos = {
            x = 1205.9132,
            y = 520.4507,
        },
        ring = {
            labels = true,
            open = "key",
            pages = {
                {
                    color = "vert",
                    icon = "Interface\\Icons\\INV_Misc_Book_09",
                    items = {
                        {
                            a = "CHAR",
                        },
                        {
                            a = "SPELLS",
                        },
                        {
                            a = "TALENTS",
                        },
                        {
                            a = "BAGS",
                        },
                        {
                            a = "MAP",
                        },
                        {
                            a = "SOCIAL",
                        },
                        {
                            a = "PROF",
                        },
                        {
                            a = "REPUT",
                        },
                        {
                            a = "MACROS",
                        },
                        {
                            a = "LFG",
                        },
                        {
                            a = "GUILD",
                        },
                        {
                            a = "STORE",
                        },
                    },
                    name = "Menu",
                },
                {
                    color = "rouge",
                    icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
                    items = {
                        {
                            a = "T_SELF",
                        },
                        {
                            a = "T_P1",
                        },
                        {
                            a = "T_P2",
                        },
                        {
                            a = "T_P3",
                        },
                        {
                            a = "T_P4",
                        },
                        {
                            a = "T_ENEMY",
                        },
                        {
                            a = "T_LAST",
                        },
                        {
                            a = "T_ASSIST",
                        },
                        {
                            a = "T_FOCUS",
                        },
                        {
                            a = "T_CLEAR",
                        },
                        {
                            a = "T_FOLLOW",
                        },
                    },
                    name = "Cibler",
                },
                {
                    color = "violet",
                    icon = "Interface\\Icons\\Spell_Shadow_Charm",
                    items = {
                        {
                            a = "E_WAVE",
                        },
                        {
                            a = "E_DANCE",
                        },
                        {
                            a = "E_LAUGH",
                        },
                        {
                            a = "E_CHEER",
                        },
                        {
                            a = "E_THANK",
                        },
                        {
                            a = "E_CRY",
                        },
                        {
                            a = "E_SLEEP",
                        },
                        {
                            a = "E_BOW",
                        },
                        {
                            a = "E_HUG",
                        },
                        {
                            a = "E_KISS",
                        },
                        {
                            a = "E_ROAR",
                        },
                        {
                            a = "E_FLEX",
                        },
                    },
                    name = "Emotes",
                },
                {
                    color = "bleu",
                    icon = "Interface\\Icons\\Spell_Holy_Silence",
                    items = {
                        {
                            a = "C_SAY",
                        },
                        {
                            a = "C_PARTY",
                        },
                        {
                            a = "C_GUILD",
                        },
                        {
                            a = "C_YELL",
                        },
                        {
                            a = "C_REPLY",
                        },
                        {
                            a = "C_WHISPER",
                        },
                    },
                    name = "Chat",
                },
                {
                    color = "blanc",
                    icon = "Interface\\Icons\\INV_Misc_Gear_01",
                    items = {
                        {
                            a = "S_MOUNT",
                        },
                        {
                            a = "S_HEARTH",
                        },
                        {
                            a = "S_RELOAD",
                        },
                        {
                            a = "S_SHOT",
                        },
                        {
                            a = "S_DICE",
                        },
                        {
                            a = "ACHIEV",
                        },
                        {
                            a = "JOURNAL",
                        },
                        {
                            a = "COLLECT",
                        },
                    },
                    name = "Système",
                },
                {
                    color = "bleu",
                    icon = "Interface\\Icons\\Spell_Nature_Tranquility",
                    items = {
                        {
                            a = "E_SIT",
                        },
                        {
                            a = "E_STAND",
                        },
                        {
                            a = "E_KNEEL",
                        },
                        {
                            a = "E_SLEEP",
                        },
                        {
                            a = "E_DEAD",
                        },
                        {
                            a = "E_SHEATH",
                        },
                        {
                            a = "S_MOUNT",
                        },
                    },
                    name = "Postures",
                },
            },
            pos = {
                x = 1233.3333,
                y = 595.267,
            },
            postureV1 = true,
            postureV2 = true,
            scale = 1.0,
            shape = "round",
            v = 1,
        },
        skin = {
            bars = {
                alpha = 1,
                color = "or",
                hotkey = true,
                name = true,
                shape = "origine",
                size = 1,
            },
            main = {
                alpha = 1,
                color = "vert",
                hotkey = true,
                name = true,
                shape = "rond",
                size = 1,
            },
            pet = {
                alpha = 1,
                color = "noir",
                hotkey = true,
                name = true,
                shape = "rond",
                size = 1.1,
            },
            stance = {
                alpha = 1,
                color = "or",
                hotkey = true,
                name = true,
                shape = "origine",
                size = 1,
            },
            wheel = {
                alpha = 0.8,
                color = "aucun",
                hotkey = true,
                name = true,
                shape = "rond",
                size = 1,
            },
        },
        uiPos = {
            BuffFrame = {
                scale = 1,
                x = 276.3858,
                y = 291.6667,
            },
            DebuffFrame = {
                scale = 1,
                x = 384.119,
                y = 194.4999,
            },
            MinimapCluster = {
                scale = 0.9046,
                x = 668.8988,
                y = 167.0484,
            },
            ObjectiveTrackerFrame = {
                scale = 0.8923,
                x = -501.3186,
                y = -287.1796,
            },
            PetActionBar = {
                scale = 1,
                x = -281.9999,
                y = -377.9667,
            },
            PlayerFrame = {
                scale = 1.25,
                x = -269.9995,
                y = 321.6667,
            },
            StanceBar = {
                scale = 1.0132,
                x = -758.5186,
                y = 396.2714,
            },
            TargetFrame = {
                scale = 1.25,
                x = -17.7658,
                y = 319.6668,
            },
        },
        v2 = true,
        wheelRing = 1,
    },
    classes = {HUNTER = arc},
    arc = forme,
}
