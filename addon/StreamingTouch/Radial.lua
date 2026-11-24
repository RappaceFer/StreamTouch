-- Streaming Touch (licence MIT, voir LICENSE.txt).
-- Tout se modifie en jeu : appui long sur Menu, bouton « Modifier » au centre du rond, ou /strond.
-- Les boutons sont sécurisés : cibler, familier, emotes et macros marchent aussi en combat.
local _, addon = ...
if not addon or not addon.enabled then return end

-- Textures : unie (teintée à la demande), masque rond, point d'interrogation.
local WHITE, CIRCLE, QUESTION = "Interface\\Buttons\\WHITE8X8", "Interface\\CharacterFrame\\TempPortraitAlphaMask",
    "Interface\\Icons\\INV_Misc_QuestionMark"
local R = {pool = {}, pages = {}, tabs = {}, MAXPAGES = 8, MAXITEMS = 12}
R.ed = {kind = "page", page = 1, mode = "props", cat = 1, actStart = 0, iconStart = 0}
addon.radial = R

local function I(name)
    if type(name) == "string" and not name:find("\\") then return "Interface\\Icons\\" .. name end
    return name
end
local function Say(text) print("|cffe8c46aStreaming Touch|r : " .. text) end
local function Try(...)
    local list = {...}
    return function()
        for _, f in ipairs(list) do
            if pcall(f) then return true end
        end
        return false
    end
end
local function Chat(prefix)
    return Try(function() ChatFrame_OpenChat(prefix) end, function() ChatFrameUtil.OpenChat(prefix) end)
end
local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return (GetSpellInfo(id)) end
end

-- Ciblage auto : un sort offensif lancé sans cible ennemie vivante prend d'abord l'ennemi le plus
-- proche devant soi, puis part (comme la macro « /targetenemy » du jeu : un seul appui, permis).
local function Harmful(name, id)
    local ok, res = pcall(function()
        if C_Spell and C_Spell.IsSpellHarmful then return C_Spell.IsSpellHarmful(id or name) end
        if IsHarmfulSpell then return IsHarmfulSpell(name) end
    end)
    return ok and res and true or false
end
addon.Harmful = Harmful
function addon.AutoCast(btn, name, id)
    if type(name) ~= "string" or name == "" then return end
    if (StreamingTouchDB or {}).autoTargetOff or not Harmful(name, id) then return end
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macro", nil)
    btn:SetAttribute("macrotext", "/targetenemy [noharm][dead]\n/cast " .. name)
end

R.COLORS = {
    {"or", "Or", 1, .82, .32}, {"bleu", "Bleu", .32, .62, 1}, {"rouge", "Rouge", 1, .32, .32},
    {"vert", "Vert", .38, .9, .45}, {"violet", "Violet", .72, .47, 1}, {"orange", "Orange", 1, .56, .16},
    {"cyan", "Cyan", .3, .9, .95}, {"rose", "Rose", 1, .47, .75}, {"blanc", "Blanc", .95, .95, .95},
    {"noir", "Noir", .12, .12, .14}, {"aucun", "Sans bord"},
}
R.COLOR = {}
for _, c in ipairs(R.COLORS) do R.COLOR[c[1]] = c end

-- Catalogue : k = clé, l = nom, i = icônes proposées, run = fenêtre du jeu, text = macro, spell = sort.
R.CATS = {
    {name = "Fenêtres", icon = "INV_Misc_Book_09", list = {
        {k = "CHAR", l = "Perso", i = {"INV_Shirt_White_01", "INV_Chest_Chain_05", "INV_Helmet_25", "Achievement_Character_Human_Male"},
            click = {"CharacterMicroButton"}, run = Try(function() ToggleCharacter("PaperDollFrame") end)},
        {k = "SPELLS", l = "Sorts", i = {"INV_Misc_Book_09", "INV_Misc_Book_07", "Spell_Holy_MagicalSentry", "INV_Misc_Book_11"},
            click = {"SpellbookMicroButton", "PlayerSpellsMicroButton", "TalentMicroButton"}, run = Try(function() PlayerSpellsUtil.ToggleSpellBookFrame() end, function() ToggleSpellBook(BOOKTYPE_SPELL or "spell") end)},
        {k = "TALENTS", l = "Talents", i = {"Ability_Marksmanship", "Ability_Hunter_SniperShot", "Spell_Holy_SealOfMight", "INV_Misc_Gem_Variety_01"},
            click = {"TalentMicroButton", "PlayerSpellsMicroButton"}, run = Try(function() PlayerSpellsUtil.ToggleClassTalentFrame() end, function() ToggleTalentFrame() end)},
        {k = "QUESTS", l = "Quêtes", i = {"INV_Misc_Note_01", "INV_Misc_Book_08", "INV_Letter_15"},
            click = {"QuestLogMicroButton"}, run = Try(function() ToggleQuestLog() end)},
        {k = "BAGS", l = "Sacs", i = {"INV_Misc_Bag_08", "INV_Misc_Bag_10", "INV_Misc_Bag_07_Black", "INV_Misc_Bag_Felcloth"},
            click = {"MainMenuBarBackpackButton"}, run = Try(function() ToggleAllBags() end)},
        {k = "MAP", l = "Carte", i = {"INV_Misc_Map_01", "INV_Misc_Map02", "INV_Scroll_03"},
            click = {"WorldMapMicroButton"}, run = Try(function() ToggleWorldMap() end)},
        {k = "SOCIAL", l = "Social", i = {"INV_Misc_GroupNeedMore", "INV_Misc_GroupLooking", "Spell_Holy_PrayerOfHealing02"},
            click = {"SocialsMicroButton", "QuickJoinToastButton"}, run = Try(function() ToggleFriendsFrame() end)},
        {k = "GUILD", l = "Guilde", i = {"INV_Shirt_GuildTabard_01", "INV_Misc_TabardSummer01"},
            click = {"GuildMicroButton"}, run = Try(function() ToggleGuildFrame() end, function() GuildMicroButton:Click() end)},
        {k = "LFG", l = "Groupe", i = {"INV_Misc_GroupLooking", "Spell_Holy_PrayerOfFortitude"},
            click = {"LFGMicroButton", "LFDMicroButton"}, run = Try(function() PVEFrame_ToggleFrame() end, function() ToggleLFGParentFrame() end, function() LFDMicroButton:Click() end)},
        {k = "PROF", l = "Métiers", i = {"Trade_BlackSmithing", "Trade_Engineering", "Trade_Alchemy", "Trade_Tailoring"},
            click = {"ProfessionMicroButton"}, run = Try(function() ToggleProfessionsBook() end, function() ProfessionMicroButton:Click() end, function() ToggleSpellBook("professions") end)},
        {k = "REPUT", l = "Réputation", i = {"Achievement_Reputation_01", "INV_Misc_Note_02", "Spell_Holy_SealOfSalvation"},
            run = Try(function() ToggleCharacter("ReputationFrame") end)},
        {k = "MACROS", l = "Macros", i = {"INV_Misc_Note_06", "Trade_Engineering", "INV_Misc_EngGizmos_01"},
            run = Try(function() ShowMacroFrame() end)},
        {k = "ACHIEV", l = "Succès", i = {"Achievement_Quests_Completed_08", "INV_Misc_Trophy_Argent"},
            click = {"AchievementMicroButton"}, run = Try(function() ToggleAchievementFrame() end)},
        {k = "COLLECT", l = "Collection", i = {"INV_Misc_Toy_10", "Ability_Mount_RidingHorse", "INV_Box_PetCarrier_01"},
            click = {"CollectionsMicroButton"}, run = Try(function() ToggleCollectionsJournal() end, function() CollectionsMicroButton:Click() end)},
        {k = "JOURNAL", l = "Donjons", i = {"INV_Misc_Book_11", "INV_Misc_Head_Dragon_01"},
            click = {"EJMicroButton"}, run = Try(function() ToggleEncounterJournal() end, function() EJMicroButton:Click() end)},
        {k = "STORE", l = "Boutique", i = {"INV_Misc_Coin_01", "INV_Misc_Coin_02"},
            click = {"StoreMicroButton"}, run = Try(function() StoreMicroButton:Click() end, function() ToggleStoreUI() end)},
        {k = "CALENDAR", l = "Calendrier", i = {"INV_Misc_Note_04", "Spell_Holy_BorrowedTime"},
            run = Try(function() ToggleCalendar() end)},
    }},
    {name = "Cibler", icon = "Ability_Hunter_SniperShot", list = {
        {k = "T_SELF", l = "Moi", i = {"Spell_Holy_Heal", "Spell_Holy_InnerFire"}, text = "/target player"},
        {k = "T_P1", l = "Groupe 1", i = {"Spell_Holy_PrayerOfHealing02", "INV_Misc_GroupNeedMore"}, text = "/target party1"},
        {k = "T_P2", l = "Groupe 2", i = {"Spell_Holy_PrayerOfHealing02", "INV_Misc_GroupNeedMore"}, text = "/target party2"},
        {k = "T_P3", l = "Groupe 3", i = {"Spell_Holy_PrayerOfHealing02", "INV_Misc_GroupNeedMore"}, text = "/target party3"},
        {k = "T_P4", l = "Groupe 4", i = {"Spell_Holy_PrayerOfHealing02", "INV_Misc_GroupNeedMore"}, text = "/target party4"},
        {k = "T_ENEMY", l = "Ennemi", i = {"Ability_Hunter_SniperShot", "Ability_Hunter_MarkedForDeath"}, text = "/targetenemy"},
        {k = "T_LAST", l = "Précédente", i = {"Ability_Hunter_SniperShot", "Spell_Shadow_Teleport"}, text = "/targetlasttarget"},
        {k = "T_ASSIST", l = "Assister", i = {"Ability_Warrior_Charge", "Ability_Warrior_BattleShout"}, text = "/assist"},
        {k = "T_FOCUS", l = "Focus", i = {"Ability_Hunter_MasterMarksman", "Spell_Holy_MindVision"}, text = "/focus"},
        {k = "T_CLEAR", l = "Effacer", i = {"Spell_Shadow_Teleport", "Spell_Holy_DispelMagic"}, text = "/cleartarget"},
        {k = "T_FOLLOW", l = "Suivre", i = {"Ability_Tracking", "Ability_Rogue_Sprint"}, text = "/follow"},
        {k = "T_SKULL", l = "Crâne", i = {"INV_Misc_Bone_HumanSkull_01", "Ability_Creature_Cursed_02"}, text = "/run SetRaidTarget('target', 8)"},
    }},
    {name = "Familier", icon = "Ability_Hunter_BeastCall", list = {
        {k = "P_ATTACK", l = "Attaque", i = {"Ability_GhoulFrenzy", "Ability_Hunter_Pet_Wolf"}, text = "/petattack"},
        {k = "P_FOLLOW", l = "Au pied", i = {"Ability_Tracking", "Ability_Hunter_Pet_Cat"}, text = "/petfollow"},
        {k = "P_STAY", l = "Reste", i = {"Spell_Nature_TimeStop", "Ability_Hunter_Pet_Bear"}, text = "/petstay"},
        {k = "P_PASSIVE", l = "Passif", i = {"Ability_Seal", "Spell_Nature_Sleep"}, text = "/petpassive"},
        {k = "P_DEF", l = "Défensif", i = {"Ability_Defend", "INV_Shield_05"}, text = "/petdefensive"},
        {k = "P_AGGR", l = "Agressif", i = {"Ability_Racial_BloodRage", "Ability_Druid_Ferociousbite"}, text = "/petaggressive"},
        {k = "P_FEED", l = "Nourrir", i = {"Ability_Hunter_BeastTraining", "INV_Misc_Food_14"}, spell = 6991},
        {k = "P_MEND", l = "Soigner", i = {"Ability_Hunter_MendPet", "Spell_Holy_Heal"}, spell = 136},
        {k = "P_CALL", l = "Appeler", i = {"Ability_Hunter_BeastCall", "Ability_Hunter_Pet_Wolf"}, spell = 883},
        {k = "P_DISMISS", l = "Renvoyer", i = {"Spell_Nature_SpiritWolf", "Ability_Hunter_BeastSoothe"}, spell = 2641},
        {k = "P_REVIVE", l = "Ranimer", i = {"Ability_Hunter_BeastSoothe", "Spell_Holy_Resurrection"}, spell = 982},
    }},
    {name = "Emotes", icon = "Spell_Shadow_Charm", list = {
        {k = "E_WAVE", l = "Salut", i = {"Spell_Holy_PrayerOfHealing", "INV_Misc_Gift_01"}, text = "/wave"},
        {k = "E_DANCE", l = "Danse", i = {"Spell_Nature_Rejuvenation", "INV_Misc_Toy_07"}, text = "/dance"},
        {k = "E_LAUGH", l = "Rire", i = {"Spell_Shadow_Charm", "INV_Misc_Toy_02"}, text = "/laugh"},
        {k = "E_CHEER", l = "Bravo", i = {"Ability_Warrior_BattleShout", "INV_Misc_Trophy_Argent"}, text = "/cheer"},
        {k = "E_THANK", l = "Merci", i = {"INV_Misc_Gift_01", "Spell_Holy_HolyBolt"}, text = "/thank"},
        {k = "E_CRY", l = "Pleurer", i = {"Spell_Shadow_DeathScream", "Spell_Frost_FrostShock"}, text = "/cry"},
        {k = "E_SLEEP", l = "Dormir", i = {"Spell_Nature_Sleep", "INV_Misc_Pillow_01"}, text = "/sleep"},
        {k = "E_BOW", l = "Révérence", i = {"Spell_Holy_SealOfSalvation", "Spell_Holy_Restoration"}, text = "/bow"},
        {k = "E_HUG", l = "Câlin", i = {"INV_ValentinesCard02", "Spell_Holy_Heal"}, text = "/hug"},
        {k = "E_KISS", l = "Bisou", i = {"INV_ValentinesCandy", "INV_ValentinesCard02"}, text = "/kiss"},
        {k = "E_ROAR", l = "Rugir", i = {"Ability_Druid_DemoralizingRoar", "Ability_Hunter_Pet_Cat"}, text = "/roar"},
        {k = "E_FLEX", l = "Muscles", i = {"Ability_Warrior_StrengthOfArms", "Ability_Warrior_BattleShout"}, text = "/flex"},
        {k = "E_SALUTE", l = "Saluer", i = {"Ability_Warrior_RallyingCry", "Ability_Warrior_BattleShout"}, text = "/salute"},
        {k = "E_APPLAUD", l = "Applaudir", i = {"Spell_Holy_Restoration", "INV_Misc_Trophy_Argent"}, text = "/applaud"},
        {k = "E_POINT", l = "Montrer", i = {"Ability_Hunter_SniperShot", "Ability_Marksmanship"}, text = "/point"},
        {k = "E_NO", l = "Non", i = {"Spell_Shadow_SacrificialShield", "Spell_Holy_Silence"}, text = "/no"},
        {k = "E_YES", l = "Oui", i = {"Spell_Holy_Restoration", "Spell_Holy_HolyBolt"}, text = "/yes"},
        {k = "E_SIT", l = "S'asseoir", i = {"Spell_Nature_Tranquility", "Spell_Nature_Sleep"}, text = "/sit"},
        {k = "E_STAND", l = "Se lever", i = {"Ability_Rogue_Sprint", "Ability_Warrior_BattleShout"}, text = "/stand"},
        {k = "E_KNEEL", l = "À genoux", i = {"Spell_Holy_PrayerOfHealing", "Spell_Holy_Restoration"}, text = "/kneel"},
        {k = "E_DEAD", l = "Faire le mort", i = {"Ability_Rogue_FeignDeath", "Spell_Shadow_DeathScream"}, text = "/dead"},
        {k = "E_SHEATH", l = "Arme", i = {"INV_Sword_04", "INV_Sword_27"}, text = "/run ToggleSheath()"},
    }},
    {name = "Chat", icon = "Spell_Holy_Silence", list = {
        {k = "C_SAY", l = "Dire", i = {"Spell_Holy_Silence", "INV_Letter_15"}, run = Chat("/s ")},
        {k = "C_PARTY", l = "Groupe", i = {"INV_Misc_GroupNeedMore", "INV_Letter_15"}, run = Chat("/p ")},
        {k = "C_GUILD", l = "Guilde", i = {"INV_Shirt_GuildTabard_01", "INV_Letter_15"}, run = Chat("/g ")},
        {k = "C_YELL", l = "Crier", i = {"Ability_Warrior_BattleShout", "Spell_Holy_Silence"}, run = Chat("/y ")},
        {k = "C_REPLY", l = "Répondre", i = {"INV_Letter_15", "INV_Letter_02"},
            run = Try(function() ChatFrame_ReplyTell() end, function() ChatFrameUtil.ReplyTell() end)},
        {k = "C_WHISPER", l = "Chuchoter", i = {"INV_Letter_02", "Spell_Holy_Silence"}, run = function()
            local name = UnitName("target")
            if not name then return false end
            return Chat("/w " .. name .. " ")()
        end},
    }},
    {name = "Système", icon = "INV_Misc_Gear_01", list = {
        {k = "S_MOUNT", l = "Monture", i = {"Ability_Mount_RidingHorse", "Ability_Mount_WhiteTiger"}, text = "/run C_MountJournal.SummonByID(0)"},
        {k = "S_HEARTH", l = "Foyer", i = {"INV_Misc_Rune_01", "Spell_Arcane_TeleportStormWind"}, text = "/use item:6948"},
        {k = "S_RELOAD", l = "Recharger", i = {"INV_Misc_PocketWatch_01", "Spell_Nature_TimeStop"}, run = function() ReloadUI() end},
        {k = "S_SHOT", l = "Capture", i = {"INV_Misc_Spyglass_03", "INV_Misc_Spyglass_02"}, run = function() Screenshot() end},
        {k = "S_DICE", l = "Dés", i = {"INV_Misc_Dice_02", "INV_Misc_Dice_01"}, text = "/roll"},
        {k = "S_LOGOUT", l = "Déconnexion", i = {"Spell_Arcane_TeleportStormWind", "Spell_Shadow_Teleport"}, text = "/logout"},
    }},
}
R.ACT = {}
for _, cat in ipairs(R.CATS) do
    for _, def in ipairs(cat.list) do
        def.cat = cat.name
        R.ACT[def.k] = def
    end
end
R.KEYICON = I("INV_Misc_Gear_01")
R.PLUS = I("Spell_ChargePositive")
R.KEYICONS = {"INV_Misc_Gear_01", "INV_Misc_Gear_02", "INV_Misc_Gem_Variety_01", "Ability_Hunter_BeastCall", "INV_Misc_Book_09", "Spell_Holy_MagicalSentry"}
R.GENERIC = {"INV_Misc_Gem_Variety_01", "INV_Misc_Gear_01", "INV_Misc_Rune_01", "Spell_Holy_MagicalSentry", "Ability_Hunter_SniperShot", "Spell_Nature_Rejuvenation"}
R.DEFAULT = {
    {"Fenêtres", "INV_Misc_Book_09", "or", {"CHAR", "SPELLS", "TALENTS", "BAGS", "MAP", "SOCIAL", "PROF", "REPUT", "MACROS", "LFG", "GUILD", "STORE"}},
    {"Cibler", "Ability_Hunter_SniperShot", "rouge", {"T_SELF", "T_P1", "T_P2", "T_P3", "T_P4", "T_ENEMY", "T_LAST", "T_ASSIST", "T_FOCUS", "T_CLEAR", "T_FOLLOW"}},
    {"Familier", "Ability_Hunter_BeastCall", "vert", {"P_ATTACK", "P_FOLLOW", "P_STAY", "P_PASSIVE", "P_DEF", "P_FEED", "P_MEND", "P_CALL", "P_DISMISS", "P_REVIVE"}},
    {"Emotes", "Spell_Shadow_Charm", "violet", {"E_WAVE", "E_DANCE", "E_LAUGH", "E_CHEER", "E_THANK", "E_CRY", "E_SLEEP", "E_BOW", "E_HUG", "E_KISS", "E_ROAR", "E_FLEX"}},
    {"Chat", "Spell_Holy_Silence", "bleu", {"C_SAY", "C_PARTY", "C_GUILD", "C_YELL", "C_REPLY", "C_WHISPER"}},
    {"Système", "INV_Misc_Gear_01", "blanc", {"S_MOUNT", "S_HEARTH", "S_RELOAD", "S_SHOT", "S_DICE", "ACHIEV", "JOURNAL", "COLLECT"}},
}

-- CH : formes arrondies pour les menus. Un rectangle aux coins ronds (une pilule quand le rayon
-- vaut la moitié de la hauteur), fait de bandes et de quarts du disque du portrait du jeu.
local DISC = CIRCLE
local function RoundBox(parent, layer, sub, radius, inset)
    inset = inset or 0
    local box = {parts = {}}
    local function piece(texture)
        local t = parent:CreateTexture(nil, layer, nil, sub)
        t:SetTexture(texture)
        box.parts[#box.parts + 1] = t
        return t
    end
    local mid = piece(WHITE)
    mid:SetPoint("TOPLEFT", inset + radius, -inset)
    mid:SetPoint("BOTTOMRIGHT", -inset - radius, inset)
    local left = piece(WHITE)
    left:SetPoint("TOPLEFT", inset, -inset - radius)
    left:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", inset + radius, inset + radius)
    local right = piece(WHITE)
    right:SetPoint("TOPRIGHT", -inset, -inset - radius)
    right:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", -inset - radius, inset + radius)
    for _, c in ipairs({{"TOPLEFT", 1, -1, 0, .5, 0, .5}, {"TOPRIGHT", -1, -1, .5, 1, 0, .5},
        {"BOTTOMLEFT", 1, 1, 0, .5, .5, 1}, {"BOTTOMRIGHT", -1, 1, .5, 1, .5, 1}}) do
        local t = piece(DISC)
        t:SetSize(radius, radius)
        t:SetPoint(c[1], c[2] * inset, c[3] * inset)
        t:SetTexCoord(c[4], c[5], c[6], c[7])
    end
    function box:SetColor(r, g, b, a)
        for _, t in ipairs(self.parts) do t:SetVertexColor(r, g, b, a or 1) end
    end
    return box
end
-- Bouton en pilule : un bord fin et un fond, plus clair sous le doigt, or quand il est choisi.
local function Capsule(b, height)
    local radius = math.max(4, math.min(height / 2, 18))
    b.edge = RoundBox(b, "BACKGROUND", 1, radius, 0)
    b.fill = RoundBox(b, "BACKGROUND", 2, math.max(2, radius - 1.5), 1.5)
    function b:Look(on, hot, down)
        if on then
            self.edge:SetColor(1, .9, .55, 1)
            self.fill:SetColor(.86, .64, .2, 1)
        else
            if hot then self.edge:SetColor(1, .86, .45, 1) else self.edge:SetColor(.36, .55, .85, .55) end
            if down then self.fill:SetColor(.16, .33, .58, 1) else self.fill:SetColor(.07, .14, .27, .96) end
        end
    end
    b:SetScript("OnEnable", function(self) self:SetAlpha(1) end)
    b:SetScript("OnDisable", function(self) self:SetAlpha(.4) end)
end

-- CH : aides pour les sorts (rond de sorts).
local function SpellIcon(id)
    if not id then return end
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
    if GetSpellTexture then return GetSpellTexture(id) end
end
local function SpellCooldown(spell)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spell)
        if type(info) == "table" then return info.startTime, info.duration end
        return
    end
    if GetSpellCooldown then return GetSpellCooldown(spell) end
end
-- Valeurs « secrètes » du jeu (en combat) : on ne peut ni les comparer ni les tester.
local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) or false end
local function SpellActive(spell)
    local current = (C_Spell and C_Spell.IsCurrentSpell) or IsCurrentSpell
    if current then
        local ok, on = pcall(current, spell)
        if ok and not Secret(on) and on then return true end
    end
    if AuraUtil and AuraUtil.FindAuraByName then
        local ok, aura = pcall(AuraUtil.FindAuraByName, spell, "player")
        if ok and not Secret(aura) and aura then return true end
    end
    return false
end
local function SpellUsable(spell)
    local usable = (C_Spell and C_Spell.IsSpellUsable) or IsUsableSpell
    if not usable then return true end
    local ok, yes = pcall(usable, spell)
    if not ok or Secret(yes) then return true end
    return yes and true or false
end
-- Portée sur la cible : true, false (trop loin) ou nil (pas de cible, sort sans portée, valeur secrète).
local function SpellRange(spell)
    local check = (C_Spell and C_Spell.IsSpellInRange) or IsSpellInRange
    if not check or not (UnitExists and UnitExists("target")) then return nil end
    local ok, inRange = pcall(check, spell, "target")
    if not ok or Secret(inRange) then return nil end
    if inRange == 1 then return true elseif inRange == 0 then return false end
    return inRange
end
-- CH : aides pour les objets des sacs (potions, objets de quête qu'on utilise).
local function ItemName(id)
    if not id then return end
    if C_Item and C_Item.GetItemNameByID then
        local ok, name = pcall(C_Item.GetItemNameByID, id)
        if ok and name then return name end
    end
    if GetItemInfo then return (GetItemInfo(id)) end
end
local function ItemIcon(id)
    if not id then return end
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, id)
        if ok and icon then return icon end
    end
    if GetItemIcon then return GetItemIcon(id) end
end
-- Objets des sacs qui ont un effet « Utiliser : » (potions, nourriture, objets de quête…), un seul par objet.
local function BagChoices()
    local list, seen = {}, {}
    pcall(function()
        local C = C_Container
        local slots = (C and C.GetContainerNumSlots) or GetContainerNumSlots
        local itemId = (C and C.GetContainerItemID) or GetContainerItemID
        local spellOf = (C_Item and C_Item.GetItemSpell) or GetItemSpell
        if not (slots and itemId and spellOf) then return end
        for bag = 0, NUM_BAG_SLOTS or 4 do
            for slot = 1, slots(bag) or 0 do
                local id = itemId(bag, slot)
                if id and not seen[id] and spellOf(id) then
                    seen[id] = true
                    list[#list + 1] = {a = "ITEM", item = id, label = ItemName(id), icon = ItemIcon(id)}
                end
            end
        end
    end)
    return list
end
local function MacroChoices()
    local list = {}
    local global, char = GetNumMacros()
    local function add(i)
        local name, icon = GetMacroInfo(i)
        if name then list[#list + 1] = {a = "MACRO", macro = name, label = name, icon = icon} end
    end
    for i = 1, global or 0 do add(i) end
    local first = (MAX_ACCOUNT_MACROS or 120) + 1
    for i = first, first + (char or 0) - 1 do add(i) end
    return list
end
-- Un groupe du grimoire (les aspects du chasseur, par exemple) : ses sorts déjà appris.
local function FlyoutSpells(flyout)
    local list = {}
    if not flyout or not GetFlyoutInfo or not GetFlyoutSlotInfo then return list end
    local seen = {}
    pcall(function()
        local _, _, slots = GetFlyoutInfo(flyout)
        for slot = 1, slots or 0 do
            local id, override, known, name = GetFlyoutSlotInfo(flyout, slot)
            if id and known then
                local spell = (override and override ~= 0) and override or id
                local entry = {a = "SPELL", spell = spell, label = SpellName(spell) or name, icon = SpellIcon(spell)}
                local key = entry.label or spell
                if seen[key] then list[seen[key]] = entry else list[#list + 1] = entry seen[key] = #list end
            end
        end
    end)
    return list
end
-- Le groupe lui-même, en un seul bouton : il s'ouvre au toucher et montre ses sorts.
local function FlyoutItem(flyout, name, icon)
    if not name and GetFlyoutInfo then
        local ok, found = pcall(GetFlyoutInfo, flyout)
        if ok then name = found end
    end
    local first = FlyoutSpells(flyout)[1]
    return {a = "FLYOUT", flyout = flyout, label = name or "Groupe", icon = icon or (first and first.icon)}
end
-- Une case de la barre du familier, toujours rendue sous la forme : nom, icône, ordre (true/false), actif,
-- automatique permis, automatique activé, sortID. Forme récente : nom, icône, ordre (true, 1 ou nil),
-- actif… ; ancienne : nom, rang, icône, ordre, actif…
local function PetInfo(slot)
    if not GetPetActionInfo then return end
    local a, b, c, d, e, f, g = GetPetActionInfo(slot)
    if a == nil or Secret(a) or Secret(c) then return end
    if c == nil or c == true or c == false or c == 1 then
        return a, b, c and true or false, d, e, f, g
    end
    return a, c, d and true or false, e, f, g, nil
end
-- Ce que le doigt a pris dans le grimoire, la barre du familier ou les macros (glisser-déposer).
local function CursorItems()
    if not GetCursorInfo then return end
    local kind, a, b, c = GetCursorInfo()
    if kind == "spell" then
        local id = type(c) == "number" and c or nil
        if not id and type(a) == "number" then
            pcall(function()
                if C_SpellBook and C_SpellBook.GetSpellBookItemInfo and Enum and Enum.SpellBookSpellBank then
                    local bank = (b == "pet" or b == Enum.SpellBookSpellBank.Pet) and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player
                    local info = C_SpellBook.GetSpellBookItemInfo(a, bank)
                    if info then id = info.spellID or info.actionID end
                elseif GetSpellBookItemInfo then
                    local _, found = GetSpellBookItemInfo(a, b)
                    id = found
                end
            end)
        end
        if id then return {{a = "SPELL", spell = id, label = SpellName(id), icon = SpellIcon(id)}} end
    elseif kind == "flyout" and type(a) == "number" then
        return {FlyoutItem(a)}
    elseif kind == "petaction" and GetPetActionInfo and type(a) == "number" then
        local name, icon, token, _, _, _, id = PetInfo(a)
        if name and not token then return {{a = "SPELL", spell = id or name, label = name, icon = icon}} end
    elseif kind == "macro" and GetMacroInfo then
        local name, icon = GetMacroInfo(a)
        if name then return {{a = "MACRO", macro = name, label = name, icon = icon}} end
    elseif kind == "item" and type(a) == "number" then
        return {{a = "ITEM", item = a, label = ItemName(a), icon = ItemIcon(a)}}
    end
end
-- Le grimoire, lu à un seul endroit. pet = true : celui du familier. Pour chaque entrée, visit(e) avec
-- e.kind = "spell", "flyout" (un groupe de sorts) ou "petaction" (un ordre du familier), e.id, e.name, e.icon,
-- e.sub (rang), e.passive, e.offSpec, e.tab (nom de l'onglet), e.hiddenTab, e.offTab, et pour l'API récente
-- e.index et e.bank (pour prendre l'entrée au curseur). L'API récente d'abord, l'ancienne si elle ne donne rien.
local function WalkBook(pet, visit)
    local found = 0
    local api, enum = C_SpellBook, Enum
    if api and api.GetSpellBookItemInfo and enum and enum.SpellBookSpellBank and enum.SpellBookItemType then
        pcall(function()
            local bank = pet and enum.SpellBookSpellBank.Pet or enum.SpellBookSpellBank.Player
            local types = enum.SpellBookItemType
            local function Entry(index, tab)
                local data = api.GetSpellBookItemInfo(index, bank)
                if not data then return end
                local kind = (data.itemType == types.Spell and "spell") or (types.Flyout and data.itemType == types.Flyout and "flyout")
                    or (types.PetAction and data.itemType == types.PetAction and "petaction") or nil
                if not kind then return end
                found = found + 1
                visit({kind = kind, id = kind == "spell" and (data.spellID or data.actionID) or data.actionID, name = data.name,
                    icon = data.iconID, sub = data.subName, passive = data.isPassive, offSpec = data.isOffSpec, modern = true,
                    tab = tab and tab.name, hiddenTab = tab and tab.shouldHide, offTab = tab and tab.offSpecID, index = index, bank = bank})
            end
            if pet then
                for index = 1, (api.HasPetSpells and api.HasPetSpells()) or 0 do Entry(index) end
            else
                for t = 1, api.GetNumSpellBookSkillLines() do
                    local tab = api.GetSpellBookSkillLineInfo(t)
                    if tab then
                        for index = tab.itemIndexOffset + 1, tab.itemIndexOffset + tab.numSpellBookItems do Entry(index, tab) end
                    end
                end
            end
        end)
    end
    if found > 0 then return end
    pcall(function()
        local bookType = pet and (BOOKTYPE_PET or "pet") or (BOOKTYPE_SPELL or "spell")
        local kinds = {SPELL = "spell", FLYOUT = "flyout", PETACTION = "petaction"}
        local function Entry(index, tabName)
            local what, id = GetSpellBookItemInfo(index, bookType)
            local kind = kinds[what or ""]
            if not kind then return end
            local okPassive, passive = pcall(IsPassiveSpell, index, bookType)
            local name, sub = GetSpellBookItemName(index, bookType)
            visit({kind = kind, id = id, name = name, icon = GetSpellBookItemTexture(index, bookType), sub = sub,
                passive = okPassive and passive or false, tab = tabName})
        end
        if pet then
            for index = 1, (HasPetSpells and HasPetSpells()) or 0 do Entry(index) end
        elseif GetNumSpellTabs then
            for t = 1, GetNumSpellTabs() do
                local tabName, _, first, n = GetSpellTabInfo(t)
                for index = first + 1, first + n do Entry(index, tabName) end
            end
        end
    end)
end
-- Les sorts du familier (Grondement, Morsure…), un seul rang par sort. Vide sans familier.
local function PetSpells()
    local list, seen = {}, {}
    local function add(id, name, icon)
        if not id or not name then return end
        if seen[name] then return end
        list[#list + 1] = {a = "SPELL", spell = id, label = name, icon = icon}
        seen[name] = #list
    end
    -- La barre du familier. Ancienne forme : nom, rang, icône, ordre ; nouvelle : nom, icône, ordre, …, sortID.
    if GetPetActionInfo then
        pcall(function()
            for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
                local name, icon, token, _, _, _, id = PetInfo(slot)
                if name and not token then add(id or name, name, icon) end
            end
        end)
    end
    -- Son grimoire.
    WalkBook(true, function(e)
        if e.kind == "spell" and not e.passive then add(e.id, e.name, e.icon) end
    end)
    return list
end
-- Onglet « Mon familier » de l'éditeur : ses sorts, puis ses ordres (macros du jeu).
local function PetTab()
    local list = {{a = "PETBAR", label = "Barre du familier", icon = I("Ability_Hunter_BeastCall")}}
    local P = addon.spells
    local bar = P and P.PetBar and P.PetBar() or {}
    local names, tokens = {}, {}
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local e = bar[slot]
        if e then
            list[#list + 1] = {a = "PETACTION", slot = slot, label = e.name, icon = e.icon}
            names[e.name or ""] = true
            if e.token then tokens[e.token] = true end
        end
    end
    for _, s in ipairs(PetSpells()) do
        if not names[s.label or ""] then list[#list + 1] = s end
    end
    for _, c in ipairs({
        {"/petattack", "Attaque", "Ability_GhoulFrenzy"}, {"/petfollow", "Suivre", "Ability_Tracking"},
        {"/petstay", "Rester", "Spell_Nature_TimeStop"}, {"/petaggressive", "Agressif", "Ability_Racial_BloodRage"},
        {"/petdefensive", "Défensif", "Ability_Defend"}, {"/petpassive", "Passif", "Ability_Seal"},
        {"/petassist", "Aider", "Ability_Hunter_BeastSoothe"},
    }) do
        local token = P and P.PET_TOKENS and P.PET_TOKENS[c[1]]
        if not (token and (tokens[token] or tokens[token .. "ASSIST"])) and not names[c[2]] then
            list[#list + 1] = {a = "TEXT", text = c[1], label = c[2], icon = I(c[3])}
        end
    end
    return {name = "Mon familier", list = list}
end
-- pet : ajoute l'onglet du familier (rond de sorts).
local function SpellTabs(pet)
    local tabs, byName = {}, {}
    WalkBook(false, function(e)
        if e.hiddenTab then return end
        local key = e.tab or ""
        local tab = byName[key]
        if not tab then
            tab = {name = e.tab, list = {}}
            byName[key] = tab
            tabs[#tabs + 1] = tab
        end
        if e.kind == "spell" and not e.passive then
            tab.list[#tab.list + 1] = {a = "SPELL", spell = e.id, label = e.name, icon = e.icon}
        elseif e.kind == "flyout" and #FlyoutSpells(e.id) > 0 then
            tab.list[#tab.list + 1] = FlyoutItem(e.id, e.name, e.icon)
        end
    end)
    -- L'éditeur a la place pour 6 onglets (+ Mes macros, Macro libre).
    while #tabs > (pet and 5 or 6) do table.remove(tabs) end
    if pet then tabs[#tabs + 1] = PetTab() end
    return tabs
end
-- Rond de sorts par défaut pour un chasseur. V1 : la première version, gardée pour savoir
-- si le joueur l'a modifiée (sinon on passe à la v2, avec la mêlée).
local function SpellPage(name, icon, color, list, extra)
    local items = {}
    for _, e in ipairs(list) do
        items[#items + 1] = {a = "SPELL", spell = e[1], label = e[2], hold = e[3] and {a = "SPELL", spell = e[3]} or nil}
    end
    return {name, icon, color, items, extra}
end
local function SpellDefaultsV1()
    return {
        SpellPage("Aspects", "Spell_Nature_RavenForm", "vert", {{13165, "Faucon"}, {13163, "Singe"}, {5118, "Guépard"},
            {13159, "Meute"}, {13161, "Bête"}, {20043, "Nature"}}),
        SpellPage("Pièges", "Spell_Frost_ChainsOfIce", "cyan", {{1499, "Givrant"}, {13809, "Givre"}, {13795, "Immolation"},
            {13813, "Explosif"}}),
        SpellPage("Tirs", "Ability_Hunter_SniperShot", "rouge", {{1130, "Marque"}, {3044, "Arcanes"}, {1978, "Morsure"},
            {5116, "Choc"}, {2643, "Multiples"}, {3045, "Tir rapide"}}),
        SpellPage("Familier", "Ability_Hunter_BeastCall", "or", {{883, "Appeler"}, {2641, "Renvoyer"}, {136, "Soigner"},
            {6991, "Nourrir"}, {982, "Ranimer"}}),
    }
end
-- V2 : Tirs en premier, la mêlée, puis aspects, pièges, familier. Les sorts pas encore appris
-- restent cachés et apparaissent tout seuls une fois appris.
local function SpellDefaults()
    local _, class = UnitClass("player")
    if class == "HUNTER" then
        return {
            SpellPage("Tirs", "Ability_Hunter_SniperShot", "rouge", {{75, "Tir auto"}, {3044, "Arcanes"}, {1978, "Serpent"},
                {2643, "Multiples"}, {1130, "Marque"}, {5116, "Choc"}, {3045, "Tir rapide"}, {19434, "Visée"},
                {3043, "Scorpide"}, {1510, "Salve"}}),
            SpellPage("Mêlée", "Ability_MeleeDamage", "orange", {{2973, "Raptor"}, {1495, "Mangouste"}, {2974, "Coupure"},
                {6603, "Attaque"}, {781, "Désengager"}, {5384, "Feindre"}, {19306, "Contre"}, {19263, "Dissuasion"},
                {19386, "Wyverne"}}),
            SpellPage("Aspects", "Spell_Nature_RavenForm", "vert", {{13165, "Faucon"}, {13163, "Singe"}, {5118, "Guépard"},
                {13159, "Meute"}, {13161, "Bête"}, {20043, "Nature"}}),
            SpellPage("Pièges", "Spell_Frost_ChainsOfIce", "cyan", {{1499, "Givrant"}, {13809, "Givre"}, {13795, "Immolation"},
                {13813, "Explosif"}}),
            SpellPage("Familier", "Ability_Hunter_BeastCall", "or", {{883, "Appeler"}, {2641, "Renvoyer"}, {136, "Soigner"},
                {6991, "Nourrir"}, {982, "Ranimer"}, {19574, "Courroux"}}),
        }
    end
    -- Les autres classes : sorts conseillés (rang 1 ; l'arc lance toujours le meilleur rang appris et cache
    -- ceux pas encore appris). Page 1 : en combat ; page 2 : couche 2 (maintenir). {sort, nom, sort au maintien}.
    if class == "WARRIOR" then
        return {
            SpellPage("Combat", "Ability_Warrior_OffensiveStance", "rouge", {{100, "Charge", 20252}, {78, "Frappe héroïque"},
                {772, "Pourfendre"}, {7384, "Fulgurance"}, {5308, "Exécution"}, {1715, "Brise-genou"}, {845, "Enchaînement"},
                {6343, "Coup de tonnerre"}, {12294, "Frappe mortelle"}, {23881, "Sanguinaire"}, {1680, "Tourbillon"},
                {6552, "Volée de coups"}}, {forme = {2457, 2458}}),
            SpellPage("Défense", "Ability_Warrior_DefensiveStance", "orange", {{355, "Provocation"}, {7386, "Fracasser"},
                {6572, "Vengeance"}, {2565, "Maîtrise du blocage"}, {72, "Coup de bouclier"}, {23922, "Heurt de bouclier"},
                {871, "Mur protecteur"}, {12975, "Dernier rempart"}, {676, "Désarmement"}, {1161, "Cri de défi"},
                {20230, "Représailles"}}, {forme = {71}}),
            SpellPage("Cris", "Ability_Warrior_BattleShout", "vert", {{6673, "Cri de guerre"}, {1160, "Cri démoralisant"},
                {5246, "Cri d'intimidation"}, {12323, "Hurlement perçant"}, {2687, "Rage sanguinaire"},
                {18499, "Rage de berserker"}, {1719, "Témérité"}, {12328, "Souhait mortel"}, {12292, "Attaques circulaires"}}),
            SpellPage("Postures", "Ability_Warrior_DefensiveStance", "or", {{2457, "Combat"}, {71, "Défensive"},
                {2458, "Berserker"}}),
        }
    elseif class == "PALADIN" then
        return {
            SpellPage("Combat", "Spell_Holy_RighteousFury", "rouge", {{20271, "Jugement"}, {21084, "Piété", 20166},
                {21082, "Croisé", 20165}, {20375, "Autorité"}, {20164, "Justice"}, {853, "Marteau de la justice"},
                {879, "Exorcisme"}, {24275, "Marteau de courroux"}, {26573, "Consécration"}, {2812, "Colère divine"},
                {20473, "Horion sacré"}, {20925, "Bouclier sacré"}}),
            SpellPage("Soins", "Spell_Holy_HolyBolt", "vert", {{635, "Lumière sacrée"}, {19750, "Éclair lumineux"},
                {4987, "Épuration", 1152}, {633, "Imposition des mains"}, {498, "Protection divine"}, {642, "Bouclier divin"},
                {1022, "Bénédiction de protection"}, {1044, "Bénédiction de liberté"}, {7328, "Rédemption"}}),
            SpellPage("Bénédictions", "Spell_Holy_FistOfJustice", "or", {{19740, "Puissance"}, {19742, "Sagesse"},
                {20217, "Rois"}, {1038, "Salut"}, {19977, "Lumière"}, {20911, "Sanctuaire"}, {25780, "Fureur vertueuse"},
                {2878, "Renvoi des morts-vivants"}}),
            SpellPage("Auras", "Spell_Holy_DevotionAura", "cyan", {{465, "Dévotion"}, {7294, "Vindicte"},
                {19746, "Concentration"}, {19876, "Ombre"}, {19888, "Givre"}, {19891, "Feu"}, {20218, "Sanctification"}}),
        }
    elseif class == "ROGUE" then
        return {
            SpellPage("Combat", "Ability_BackStab", "rouge", {{1752, "Attaque pernicieuse"}, {2098, "Éviscération"},
                {53, "Attaque sournoise"}, {5171, "Débiter"}, {1943, "Rupture"}, {408, "Aiguillon perfide"},
                {1766, "Coup de pied"}, {1776, "Suriner"}, {8647, "Exposer l'armure"}, {14251, "Riposte"},
                {16511, "Hémorragie"}, {14278, "Frappe fantomatique"}}),
            SpellPage("Furtivité", "Ability_Stealth", "violet", {{1784, "Camouflage"}, {8676, "Embuscade"}, {703, "Garrot"},
                {1833, "Coup bas"}, {6770, "Assommer"}, {921, "Vol à la tire"}, {1725, "Distraction"}, {1856, "Disparition"},
                {2094, "Cécité"}}, {forme = {1784}}),
            SpellPage("Défense", "Spell_Shadow_ShadowWard", "vert", {{5277, "Évasion"}, {2983, "Sprint"}, {1966, "Feinte"},
                {13750, "Poussée d'adrénaline"}, {13877, "Déluge de lames"}, {14177, "Sang froid"}, {14185, "Préparation"},
                {1804, "Crochetage"}}),
        }
    elseif class == "PRIEST" then
        return {
            SpellPage("Attaque", "Spell_Shadow_ShadowWordPain", "violet", {{585, "Châtiment"}, {589, "Mot de l'ombre : Douleur"},
                {8092, "Attaque mentale"}, {14914, "Flammes sacrées"}, {15407, "Fouet mental"}, {8122, "Cri psychique"},
                {8129, "Brûlure de mana"}, {2944, "Peste dévorante"}, {15473, "Forme d'ombre"}, {15286, "Étreinte vampirique"},
                {586, "Oubli"}}, {forme = {15473}}),
            SpellPage("Soins", "Spell_Holy_FlashHeal", "vert", {{2050, "Soins inférieurs", 2054}, {2061, "Soins rapides"},
                {2060, "Soins supérieurs"}, {139, "Rénovation"}, {17, "Mot de pouvoir : Bouclier"}, {596, "Prière de soins"},
                {527, "Dissipation de la magie"}, {528, "Guérison des maladies", 552}, {10060, "Infusion de puissance"},
                {2006, "Résurrection"}}),
            SpellPage("Soutien", "Spell_Holy_WordFortitude", "or", {{1243, "Robustesse"}, {588, "Feu intérieur"},
                {976, "Protection contre l'ombre"}, {14752, "Esprit divin"}, {6346, "Gardien de peur"}, {605, "Contrôle mental"},
                {9484, "Entraves des morts-vivants"}, {1706, "Lévitation"}, {453, "Apaisement"}}),
        }
    elseif class == "MAGE" then
        return {
            SpellPage("Attaque", "Spell_Fire_FlameBolt", "rouge", {{133, "Boule de feu"}, {116, "Éclair de givre"},
                {5143, "Projectiles des arcanes"}, {2136, "Trait de feu"}, {2948, "Brûlure"}, {11366, "Explosion pyrotechnique"},
                {122, "Nova de givre"}, {120, "Cône de froid"}, {1449, "Explosion des arcanes"}, {2120, "Choc de flammes"},
                {10, "Blizzard"}, {2139, "Contresort"}}),
            SpellPage("Défense", "Spell_Frost_Frost", "cyan", {{1953, "Transfert"}, {118, "Métamorphose"},
                {11958, "Bloc de glace"}, {11426, "Barrière de glace"}, {1463, "Bouclier de mana"}, {543, "Gardien de feu"},
                {6143, "Gardien de givre"}, {12051, "Évocation"}, {12043, "Présence spirituelle"}, {12042, "Pouvoir des arcanes"},
                {11129, "Combustion"}, {12472, "Morsure du froid"}}),
            SpellPage("Utilitaire", "Spell_Holy_MagicalSentry", "bleu", {{1459, "Intelligence des arcanes"},
                {168, "Armure de givre", 7302}, {6117, "Armure du mage"}, {604, "Atténuation de la magie"},
                {1008, "Amplification de la magie"}, {475, "Délivrance de la malédiction"}, {130, "Chute lente"},
                {5504, "Invocation d'eau"}, {587, "Invocation de nourriture"}, {759, "Invocation d'une agate de mana"}}),
        }
    elseif class == "WARLOCK" then
        return {
            SpellPage("Attaque", "Spell_Shadow_ShadowBolt", "violet", {{686, "Trait de l'ombre"}, {348, "Immolation"},
                {172, "Corruption"}, {980, "Malédiction d'agonie"}, {18265, "Siphon de vie"}, {689, "Drain de vie"},
                {1120, "Drain d'âme"}, {5676, "Douleur brûlante"}, {17877, "Brûlure de l'ombre"}, {17962, "Conflagration"},
                {6353, "Feu de l'âme"}, {1454, "Connexion"}}),
            SpellPage("Contrôle", "Spell_Shadow_Possession", "rouge", {{5782, "Peur"}, {5484, "Hurlement de terreur"},
                {6789, "Voile mortel"}, {710, "Bannir"}, {702, "Faiblesse"}, {1714, "Langage"}, {704, "Témérité"},
                {1490, "Éléments"}, {17862, "Ombre"}, {603, "Funeste"}, {5740, "Pluie de feu"}, {1949, "Flammes infernales"}}),
            SpellPage("Démons", "Spell_Shadow_SummonImp", "vert", {{688, "Diablotin"}, {697, "Marcheur du Vide"},
                {712, "Succube"}, {691, "Chasseur corrompu"}, {755, "Captation de vie"}, {1098, "Asservir démon"},
                {18708, "Domination corrompue"}, {18788, "Sacrifice démoniaque"}, {698, "Rituel d'invocation"},
                {126, "Œil de Kilrogg"}}),
            SpellPage("Utilitaire", "Spell_Shadow_RagingScream", "or", {{687, "Peau de démon", 706}, {6201, "Pierre de soins"},
                {693, "Pierre d'âme"}, {5697, "Respiration interminable"}, {5138, "Drain de mana"}, {18288, "Malédiction amplifiée"}}),
        }
    elseif class == "SHAMAN" then
        return {
            SpellPage("Attaque", "Spell_Nature_Lightning", "bleu", {{403, "Éclair"}, {421, "Chaîne d'éclairs"},
                {8042, "Horion de terre"}, {8050, "Horion de flammes"}, {8056, "Horion de givre"}, {17364, "Frappe-tempête"},
                {370, "Purge"}, {324, "Bouclier de foudre"}, {16166, "Maîtrise élémentaire"}}),
            SpellPage("Soins", "Spell_Nature_MagicImmunity", "vert", {{331, "Vague de soins"}, {8004, "Vague de soins inférieurs"},
                {1064, "Salve de guérison"}, {16188, "Rapidité de la nature"}, {526, "Guérison du poison"},
                {2870, "Guérison des maladies"}, {2008, "Esprit ancestral"}, {2645, "Loup fantôme"}}),
            SpellPage("Totems", "Spell_Nature_StoneSkinTotem", "or", {{8071, "Peau de pierre"}, {2484, "Lien terrestre"},
                {8075, "Force de la terre"}, {8143, "Séisme"}, {3599, "Incendiaire"}, {1535, "Nova de feu"}, {8190, "Magma"},
                {5394, "Guérison"}, {5675, "Fontaine de mana"}, {8166, "Purification du poison"}, {8512, "Furie-des-vents"},
                {8177, "Glèbe"}}),
            SpellPage("Armes", "Spell_Nature_RockBiter", "orange", {{8017, "Croque-roc"}, {8024, "Langue de feu"},
                {8033, "Arme de givre"}, {8232, "Arme Furie-des-vents"}, {8835, "Grâce aérienne"}, {16190, "Vague de mana"},
                {556, "Rappel astral"}, {546, "Marche sur l'eau"}}),
        }
    elseif class == "DRUID" then
        return {
            SpellPage("Attaque", "Spell_Nature_StarFall", "violet", {{5176, "Colère"}, {8921, "Éclat lunaire"},
                {2912, "Feu stellaire"}, {5570, "Essaim d'insectes"}, {339, "Sarments"}, {770, "Lucioles"}, {16914, "Ouragan"},
                {2637, "Hibernation"}, {16689, "Emprise de la nature"}, {22812, "Écorce"}, {24858, "Forme de sélénien"}}, {forme = {24858}}),
            SpellPage("Soins", "Spell_Nature_HealingTouch", "vert", {{5185, "Toucher guérisseur"}, {774, "Récupération"},
                {8936, "Rétablissement"}, {18562, "Prompte guérison"}, {740, "Tranquillité"}, {2782, "Délivrance de la malédiction"},
                {8946, "Guérison du poison", 2893}, {20484, "Renaissance"}, {29166, "Innervation"}, {1126, "Marque du fauve"},
                {467, "Épines"}}),
            SpellPage("Ours", "Ability_Racial_BearForm", "orange", {{5487, "Forme d'ours", 9634}, {6807, "Mutilation"},
                {779, "Balayage"}, {6795, "Grondement"}, {99, "Rugissement démoralisant"}, {5211, "Sonner"}, {5229, "Enrager"},
                {16979, "Charge farouche"}, {22842, "Régénération frénétique"}, {16857, "Lucioles (farouche)"}}, {forme = {5487, 9634}}),
            SpellPage("Félin", "Ability_Druid_CatForm", "rouge", {{768, "Forme de félin"}, {1082, "Griffe"}, {1822, "Griffure"},
                {5221, "Lambeau"}, {1079, "Déchirure"}, {22568, "Morsure féroce"}, {5215, "Rôder"}, {6785, "Ravage"},
                {9005, "Traquenard"}, {5217, "Fureur du tigre"}, {1850, "Célérité"}, {783, "Forme de voyage"}}, {forme = {768}}),
        }
    end
    return {{"Sorts", "INV_Misc_Book_09", "bleu", {}}}
end
local function SpellSignature(pages)
    local parts = {}
    for _, p in ipairs(pages) do
        parts[#parts + 1] = tostring(p.name or p[1]) .. "|" .. tostring(p.color or p[3])
        for _, it in ipairs(p.items or p[4] or {}) do
            parts[#parts + 1] = tostring(it.a) .. ":" .. tostring(it.spell) .. ":" .. tostring(it.label) .. ":"
                .. tostring(it.color) .. ":" .. tostring(it.shape) .. ":" .. tostring(it.icon)
        end
    end
    return table.concat(parts, ";")
end
-- Rond de sorts v1 -> v2 : pas modifié = nouvelles pages ; modifié = on ajoute juste la page Mêlée.
local function SpellUpgrade(cfg, fresh)
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end
    if SpellSignature(cfg.pages) == SpellSignature(SpellDefaultsV1()) then
        cfg.pages = fresh().pages
        return
    end
    for _, p in ipairs(cfg.pages) do if p.name == "Mêlée" then return end end
    if #cfg.pages < 8 then table.insert(cfg.pages, math.min(2, #cfg.pages + 1), fresh().pages[2]) end
end

-- CH : fabrique de ronds. Chaque rond (menu, sorts) a ses réglages, ses boutons et son éditeur.
local function NewRing(opts)
local R = setmetatable({pool = {}, pages = {}, tabs = {}, MAXPAGES = 8, MAXITEMS = 12, opts = opts}, {__index = R})
R.ed = {kind = "page", page = 1, mode = "props", cat = 1, actStart = 0, iconStart = 0}
-- Réglages enregistrés par personnage dans StreamingTouchDB[R.opts.db].
function R.Fresh()
    local cfg = {v = R.opts.version or 1, scale = 1, shape = "round", labels = true, open = "key", pages = {},
        setupV3 = R.opts.fixed or nil}
    for _, p in ipairs(R.opts.defaults()) do
        local page = {name = p[1], icon = I(p[2]), color = p[3], items = {}}
        for k, v in pairs(p[5] or {}) do page[k] = v end
        for _, k in ipairs(p[4]) do page.items[#page.items + 1] = type(k) == "table" and k or {a = k} end
        cfg.pages[#cfg.pages + 1] = page
    end
    return cfg
end

function R.Config()
    StreamingTouchDB = StreamingTouchDB or {}
    local db = StreamingTouchDB
    if type(db[R.opts.db]) ~= "table" or type(db[R.opts.db].pages) ~= "table" or #db[R.opts.db].pages == 0 then
        local garde = type(db[R.opts.db]) == "table" and db[R.opts.db] or nil
        db[R.opts.db] = R.Fresh()
        -- Profil du compte : la disposition (taille, place, forme) est gardée, les sorts repartent de ceux de la classe.
        if garde then
            for k, v in pairs(garde) do
                if k ~= "pages" and k ~= "v" and not tostring(k):match("V%d+$") then db[R.opts.db][k] = v end
            end
        end
        if R.opts.migrate and type(db.radialPos) == "table" and db.radialPos.x then db[R.opts.db].pos = {x = db.radialPos.x, y = db.radialPos.y} end
    end
    R.cfg = db[R.opts.db]
    -- 2.3 : les pages par défaut d'avant (Ours, Félin, Furtivité…) apprennent leur forme, une seule fois.
    if R.opts.fixed and not R.cfg.formesV1 then
        R.cfg.formesV1 = true
        for _, np in ipairs(R.Fresh().pages) do
            for _, pg in ipairs(R.cfg.pages) do
                if np.forme and pg.forme == nil and pg.name == np.name then pg.forme = np.forme end
            end
        end
    end
    -- Arc de sorts resté vide (classe sans sorts par défaut avant la 2.2) : on y met les sorts conseillés de la classe.
    local p1 = R.cfg.pages[1]
    if R.opts.fixed and #R.cfg.pages == 1 and p1.name == "Sorts" and #(p1.items or {}) == 0 then
        local neuf = R.Fresh()
        if #neuf.pages > 1 or #neuf.pages[1].items > 0 then
            R.cfg.pages = neuf.pages
            R.cfg.rolesV1, R.cfg.setupV2 = nil, nil
        end
    end
    if R.opts.upgrade and (R.cfg.v or 1) < (R.opts.version or 1) then
        R.opts.upgrade(R.cfg, R.Fresh)
        R.cfg.v = R.opts.version
    end
    return R.cfg
end

-- Nom, icône et commande d'un bouton.
-- Le premier bouton du micro-menu qui existe dans ce jeu (Classic ou moderne).
function R.ClickTarget(names)
    for _, name in ipairs(names or {}) do
        local f = _G and _G[name]
        if type(f) == "table" and f.Click and not (f.IsForbidden and f:IsForbidden()) then return f end
    end
end
function R.Resolve(item)
    local def = R.ACT[item.a]
    local label, icon, text, macro, run, spell, click = "?", nil, nil, nil, nil, nil, nil
    if item.a == "MACRO" then
        macro = item.macro
        label = item.macro or "Macro"
        local _, macroIcon = GetMacroInfo(item.macro or "")
        icon = macroIcon
    elseif item.a == "TEXT" then
        text = item.text
        label = "Macro"
    elseif item.a == "ITEM" then
        text = item.item and ("/use item:" .. item.item) or nil
        label = ItemName(item.item) or item.label or "Objet"
        icon = ItemIcon(item.item)
    elseif item.a == "SPELL" then
        spell = SpellName(item.spell) or item.name
        label = spell or "?"
        icon = SpellIcon(item.spell)
    elseif item.a == "FLYOUT" then
        label = item.label or "Groupe"
        local first = FlyoutSpells(item.flyout)[1]
        icon = first and first.icon
    elseif item.a == "PETBAR" then
        label, icon = "Familier", "Ability_Hunter_BeastCall"
    elseif item.a == "GROUP" then
        local page = R.GroupPage(item)
        label, icon = page and page.name or "Sous-menu", page and I(page.icon)
    elseif item.a == "PETACTION" then
        label, icon = "Familier " .. tostring(item.slot or "?"), "Ability_Hunter_BeastCall"
    elseif def then
        label, icon, run, text = def.l, I(def.i[1]), def.run, def.text
        click = R.ClickTarget(def.click)
        if def.spell then
            local name = SpellName(def.spell)
            text = name and ("/cast " .. name) or nil
        end
    end
    -- Familier : la case de sa barre du jeu (même action, même icône), quand il est là.
    if item.a == "TEXT" or item.a == "SPELL" or item.a == "PETACTION" then
        local pet = R.PetSlotFor and R.PetSlotFor(item)
        if pet then
            return item.label or pet.name or label, I(pet.icon) or I(item.icon or icon) or QUESTION, nil, nil, nil, spell, nil, pet.slot
        end
    end
    return item.label or label, I(item.icon or icon) or QUESTION, text, macro, run, spell, click
end

function R.Describe(item)
    local def = R.ACT[item.a]
    if item.a == "MACRO" then return "Ta macro : " .. (item.macro or "?") end
    if item.a == "TEXT" then return ((item.text or ""):gsub("\n", "  ")) end
    if item.a == "ITEM" then return "Objet du sac : " .. (ItemName(item.item) or item.label or "?") end
    if item.a == "SPELL" then return "Sort : " .. (SpellName(item.spell) or item.name or "?") end
    if item.a == "FLYOUT" then return "Groupe du grimoire : " .. (item.label or "?") .. " (s'ouvre quand on le touche)" end
    if item.a == "PETBAR" then return "La barre du familier du jeu en un bouton (s'ouvre quand on le touche)" end
    if item.a == "GROUP" then
        local page = R.GroupPage(item)
        return "Sous-menu : les boutons de la page « " .. (page and page.name or "?") .. " » (s'ouvre quand on le touche)"
    end
    if item.a == "PETACTION" then return "Case " .. tostring(item.slot or "?") .. " de la barre du familier du jeu" end
    if not def then return "" end
    if def.spell then return "/cast " .. (SpellName(def.spell) or "?") end
    return def.text or ("Fenêtre du jeu (" .. def.cat .. ")")
end

-- Au maintien (l'appli envoie un clic droit après un appui long) : un second sort ou une macro.
function R.HoldName(hold)
    if hold.a == "SPELL" then return SpellName(hold.spell) or hold.name or "Sort" end
    if hold.a == "MACRO" then return hold.macro or "Macro" end
    if hold.a == "ITEM" then return ItemName(hold.item) or hold.label or "Objet" end
    return hold.label or "Macro"
end
function R.HoldIcon(hold)
    if hold.a == "SPELL" then return SpellIcon(hold.spell) or QUESTION end
    if hold.a == "ITEM" then return ItemIcon(hold.item) or QUESTION end
    if hold.a == "MACRO" then
        local _, icon = GetMacroInfo(hold.macro or "")
        if icon then return icon end
    end
    return I(hold.icon) or I("INV_Misc_Note_01")
end
-- Un petit rond doré en haut à droite du bouton montre ce que lance le maintien.
function R.HoldBadge(b, hold, size)
    if not hold then
        if b.holdBadge then
            b.holdBadge:Hide()
            b.holdRim:Hide()
        end
        return
    end
    if not b.holdBadge then
        b.holdRim = b:CreateTexture(nil, "OVERLAY", nil, 5)
        b.holdRim:SetTexture(WHITE)
        b.holdRim:SetVertexColor(1, .82, .32, 1)
        b.holdBadge = b:CreateTexture(nil, "OVERLAY", nil, 6)
        for _, tex in ipairs({b.holdRim, b.holdBadge}) do
            local mask = b:CreateMaskTexture()
            mask:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(tex)
            tex:AddMaskTexture(mask)
        end
    end
    local side = math.max(14, (size or 50) * .4)
    b.holdRim:SetSize(side + 3, side + 3)
    b.holdRim:ClearAllPoints()
    b.holdRim:SetPoint("CENTER", b, "TOPRIGHT", -side * .3, -side * .3)
    b.holdBadge:SetSize(side, side)
    b.holdBadge:ClearAllPoints()
    b.holdBadge:SetPoint("CENTER", b.holdRim, "CENTER")
    b.holdBadge:SetTexture(R.HoldIcon(hold))
    b.holdRim:Show()
    b.holdBadge:Show()
end

-- Habillage commun : halo, bord coloré, icône pleine, nom dessous. Rond ou carré.
function R.Visual(b)
    b.glow = b:CreateTexture(nil, "BACKGROUND", nil, -1)
    b.glow:SetTexture(WHITE)
    b.glow:SetPoint("CENTER")
    b.glow:Hide()
    b.rim = b:CreateTexture(nil, "BACKGROUND", nil, 1)
    b.rim:SetTexture(WHITE)
    b.rim:SetPoint("CENTER")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("CENTER")
    b.icon:SetTexCoord(.07, .93, .07, .93)
    -- Allumé (aspect en cours, ordre du familier, sort automatique, tir automatique) : la surbrillance
    -- des boutons « cochés » des barres du jeu, posée sur l'icône (plus d'anneau jaune autour).
    b.lit = b:CreateTexture(nil, "OVERLAY", nil, 2)
    b.lit:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    if b.lit.SetBlendMode then b.lit:SetBlendMode("ADD") end
    b.lit:SetVertexColor(1, 1, 1, 1)
    b.lit:SetPoint("CENTER")
    b.lit:Hide()
    b.shine = b:CreateTexture(nil, "OVERLAY", nil, 1)
    b.shine:SetTexture(WHITE)
    if b.shine.SetBlendMode then b.shine:SetBlendMode("ADD") end
    b.shine:SetVertexColor(1, .9, .5, .25)
    b.shine:SetPoint("CENTER")
    b.shine:Hide()
    b.masks = {}
    for i, tex in ipairs({b.glow, b.rim, b.icon, b.lit, b.shine}) do
        local mask = b:CreateMaskTexture()
        mask:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(tex)
        b.masks[i] = mask
    end
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.label:SetPoint("TOP", b, "BOTTOM", 0, -1)
    b.label:SetShadowOffset(1, -1)
    b.label:SetWordWrap(false)
    b.round = false
    b:HookScript("OnMouseDown", function(self) self.icon:SetVertexColor(.55, .55, .55) end)
    b:HookScript("OnMouseUp", function(self) R.Tint(self) end)
end

function R.Paint(b, size, icon, color, shape, label)
    local c = R.COLOR[color or ""] or R.COLOR["or"]
    local edge = c[3] and math.max(2, math.floor(size / 16)) or 0
    b:SetSize(size, size)
    b.icon:SetTexture(I(icon) or QUESTION)
    b.rim:SetSize(size, size)
    b.icon:SetSize(size - edge * 2, size - edge * 2)
    b.glow:SetSize(size + 12, size + 12)
    if b.lit then
        b.lit:SetSize(size - edge * 2, size - edge * 2)
        b.shine:SetSize(size - edge * 2, size - edge * 2)
    end
    if c[3] then
        b.rim:SetVertexColor(c[3], c[4], c[5], 1)
        b.rim:Show()
    else
        b.rim:Hide()
    end
    b.glow:SetVertexColor(c[3] or 1, c[4] or .85, c[5] or .4, .5)
    local round = shape ~= "square"
    if round ~= b.round then
        for i, tex in ipairs({b.glow, b.rim, b.icon, b.lit or false, b.shine or false}) do
            if tex and round then tex:AddMaskTexture(b.masks[i]) elseif tex then tex:RemoveMaskTexture(b.masks[i]) end
        end
        b.round = round
    end
    if b.cooldown and b.cooldown.SetSwipeTexture then b.cooldown:SetSwipeTexture(round and CIRCLE or WHITE) end
    b.label:SetWidth(size + 28)
    b.label:SetText(label or "")
end

-- Code sécurisé : la touche Menu ouvre et ferme le rond, les onglets changent de page,
-- un bouton ferme le rond après son action (sur l'appui ou le relâchement, comme les barres du jeu).
R.KEY = [=[
    if self:GetAttribute("swallow") then self:SetAttribute("swallow", nil) return end
    local ring = self:GetFrameRef("ring")
    for i = 1, ring:GetAttribute("pops") or 0 do
        local other = ring:GetFrameRef("pop" .. i)
        if other then other:Hide() end
    end
    if self:GetAttribute("fixed") then
        local count = ring:GetAttribute("pages") or 1
        -- Page suivante, en sautant les pages sans sort appris.
        local current = ring:GetAttribute("current") or 1
        for _ = 1, count do
            current = current % count + 1
            if (ring:GetAttribute("count" .. current) or 1) > 0 then break end
        end
        for i = 1, count do
            local page = ring:GetFrameRef("page" .. i)
            if page then
                if i == current then page:Show() else page:Hide() end
            end
        end
        ring:SetAttribute("current", current)
        ring:Show()
        return
    end
    if ring:IsShown() then ring:Hide() else ring:Show() end
]=]
R.TAB = [=[
    local ring = self:GetFrameRef("ring")
    local mine = self:GetAttribute("index")
    for i = 1, ring:GetAttribute("pages") or 0 do
        local page = ring:GetFrameRef("page" .. i)
        if page then
            if i == mine then page:Show() else page:Hide() end
        end
    end
    ring:SetAttribute("current", mine)
]=]
R.PRE = [=[
    local keydown = owner:GetAttribute("keydown")
    if (down and keydown) or (not down and not keydown) then
        local pop = self:GetAttribute("flyout") and self:GetFrameRef("flypop")
        if pop then
            local open = pop:IsShown()
            local ring = owner:GetFrameRef("ring")
            for i = 1, ring:GetAttribute("pops") or 0 do
                local other = ring:GetFrameRef("pop" .. i)
                if other then other:Hide() end
            end
            if not open then pop:Show() end
            return false
        end
        return nil, "close"
    end
    return false
]=]
R.POST = [=[
    local ring = owner:GetFrameRef("ring")
    for i = 1, ring:GetAttribute("pops") or 0 do
        local other = ring:GetFrameRef("pop" .. i)
        if other then other:Hide() end
    end
    if not owner:GetAttribute("fixed") then ring:Hide() end
]=]
-- Flèches à gauche et à droite du bouton de page (rond toujours affiché) : page précédente / suivante.
R.STEP = [=[
    if self:GetAttribute("swallow") then self:SetAttribute("swallow", nil) return end
    local ring = self:GetFrameRef("ring")
    for i = 1, ring:GetAttribute("pops") or 0 do
        local other = ring:GetFrameRef("pop" .. i)
        if other then other:Hide() end
    end
    local count = ring:GetAttribute("pages") or 1
    local step = self:GetAttribute("step") or 1
    local current = ring:GetAttribute("current") or 1
    for _ = 1, count do
        current = (current - 1 + step) % count + 1
        if (ring:GetAttribute("count" .. current) or 1) > 0 then break end
    end
    for i = 1, count do
        local page = ring:GetFrameRef("page" .. i)
        if page then
            if i == current then page:Show() else page:Hide() end
        end
    end
    ring:SetAttribute("current", current)
    ring:Show()
]=]
-- CH : couche 2. Le bouton « 2 » de l'appli envoie F12 tant qu'il est maintenu : la page « Couche 2 »
-- s'affiche, et l'arc revient à sa page au lâcher. Code sécurisé : marche aussi en combat.
R.LAYER = [=[
    local ring = self:GetFrameRef("ring")
    local target
    if down then
        if self:GetAttribute("held") then return end
        local layer = ring:GetAttribute("layerpage")
        if not layer or (ring:GetAttribute("count" .. layer) or 0) == 0 then return end
        self:SetAttribute("held", true)
        self:SetAttribute("back", ring:GetAttribute("current") or 1)
        target = layer
    else
        if not self:GetAttribute("held") then return end
        self:SetAttribute("held", nil)
        target = self:GetAttribute("back") or 1
    end
    for i = 1, ring:GetAttribute("pops") or 0 do
        local other = ring:GetFrameRef("pop" .. i)
        if other then other:Hide() end
    end
    for i = 1, ring:GetAttribute("pages") or 0 do
        local page = ring:GetFrameRef("page" .. i)
        if page then
            if i == target then page:Show() else page:Hide() end
        end
    end
    ring:SetAttribute("current", target)
]=]
-- CH : page automatique. Le combat commence : page « En combat » ; il finit : page « Hors combat ».
-- Pendant la couche 2, on change seulement la page où l'arc reviendra au lâcher.
R.COMBAT = [=[
    local ring = self:GetFrameRef("ring")
    local form = ring:GetAttribute("formpage") or 0
    if form > 0 and (ring:GetAttribute("count" .. form) or 0) > 0 then return end
    local fight = newstate == "1" or newstate == 1
    local target = ring:GetAttribute(fight and "combatpage" or "peacepage")
    if not target or (ring:GetAttribute("count" .. target) or 0) == 0 then return end
    local layer = self:GetFrameRef("layer")
    if layer and layer:GetAttribute("held") then
        layer:SetAttribute("back", target)
        return
    end
    for i = 1, ring:GetAttribute("pops") or 0 do
        local other = ring:GetFrameRef("pop" .. i)
        if other then other:Hide() end
    end
    for i = 1, ring:GetAttribute("pages") or 0 do
        local page = ring:GetFrameRef("page" .. i)
        if page then
            if i == target then page:Show() else page:Hide() end
        end
    end
    ring:SetAttribute("current", target)
]=]

-- CH : page de la posture / forme. On prend une forme qui a sa page : elle s'affiche ; on la quitte :
-- page « En combat » (ou « Hors combat »). Code sécurisé : marche aussi en combat.
R.FORME = [=[
    local ring = self:GetFrameRef("ring")
    local n = tonumber(newstate) or 0
    if n > 0 and (ring:GetAttribute("count" .. n) or 0) == 0 then n = 0 end
    local was = ring:GetAttribute("formpage") or 0
    ring:SetAttribute("formpage", n)
    local target = n
    if n == 0 then
        if was == 0 then return end
        local fight = self:GetAttribute("state-combat")
        fight = fight == "1" or fight == 1
        target = (fight and ring:GetAttribute("combatpage")) or ring:GetAttribute("peacepage") or ring:GetAttribute("combatpage") or 1
        if (ring:GetAttribute("count" .. target) or 0) == 0 then return end
    end
    local layer = self:GetFrameRef("layer")
    if layer and layer:GetAttribute("held") then
        layer:SetAttribute("back", target)
        return
    end
    for i = 1, ring:GetAttribute("pops") or 0 do
        local other = ring:GetFrameRef("pop" .. i)
        if other then other:Hide() end
    end
    for i = 1, ring:GetAttribute("pages") or 0 do
        local page = ring:GetFrameRef("page" .. i)
        if page then
            if i == target then page:Show() else page:Hide() end
        end
    end
    ring:SetAttribute("current", target)
]=]

local function Disc(parent, layer, r, g, b, a)
    local tex = parent:CreateTexture(nil, "BACKGROUND", nil, layer)
    tex:SetTexture(WHITE)
    tex:SetVertexColor(r, g, b, a)
    tex:SetPoint("CENTER")
    local mask = parent:CreateMaskTexture()
    mask:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(tex)
    tex:AddMaskTexture(mask)
    return tex
end

function R.Build()
    if R.main or InCombatLockdown() then return end
    local main = CreateFrame("Button", "StreamingTouchRingKey" .. R.opts.suffix, UIParent, "SecureHandlerClickTemplate")
    main:SetFrameStrata("HIGH")
    main:SetMovable(true)
    main:SetClampedToScreen(true)
    main:RegisterForClicks("AnyUp")
    main:RegisterForDrag("LeftButton")
    R.Visual(main)
    R.main = main

    local ring = CreateFrame("Frame", "StreamingTouchRing" .. R.opts.suffix, main, "SecureHandlerBaseTemplate")
    ring:SetFrameStrata("DIALOG")
    ring:Hide()
    R.ring = ring
    main:SetFrameRef("ring", ring)
    main:SetAttribute("_onclick", R.KEY)
    -- Rond de sorts : une flèche de chaque côté du bouton de page.
    if R.opts.fixed then
        R.arrows = {}
        for i, step in ipairs({-1, 1}) do
            local b = CreateFrame("Button", "StreamingTouchRingArrow" .. R.opts.suffix .. i, main, "SecureHandlerClickTemplate")
            b:RegisterForClicks("AnyUp")
            b:SetFrameRef("ring", ring)
            b:SetAttribute("step", step)
            b:SetAttribute("_onclick", R.STEP)
            R.Visual(b)
            b.arrow = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            b.arrow:SetPoint("CENTER", step * 12, 0)
            b.arrow:SetText(step < 0 and "<" or ">")
            if STANDARD_TEXT_FONT then pcall(b.arrow.SetFont, b.arrow, STANDARD_TEXT_FONT, 28, "THICKOUTLINE") end
            b:HookScript("OnClick", function() R.Mark(R.ring:GetAttribute("current")) end)
            b:SetScript("OnReceiveDrag", function() R.Drop(R.ring:GetAttribute("current") or 1) end)
            b:RegisterForDrag("LeftButton")
            b:SetMovable(true)
            b:SetClampedToScreen(true)
            b:SetScript("OnDragStart", function(self)
                if InCombatLockdown() then return end
                self:SetAttribute("swallow", true)
                -- Autour du joystick : seules les flèches bougent, l'arc reste calé sur le joystick.
                if R.layoutKind == "joystick" then
                    R.moving = true
                    for _, a in ipairs(R.arrows) do a:SetAttribute("swallow", true) end
                    R.arrows[1]:StartMoving()
                    return
                end
                local start = main:GetScript("OnDragStart")
                if start then start(main) end
            end)
            b:SetScript("OnDragStop", function(self)
                if R.layoutKind == "joystick" then
                    local first = R.arrows[1]
                    first:StopMovingOrSizing()
                    first:SetUserPlaced(false)
                    R.moving = nil
                    if not InCombatLockdown() then
                        local scale = main:GetEffectiveScale() / UIParent:GetEffectiveScale()
                        local ax, ay = first:GetCenter()
                        local mx, my = main:GetCenter()
                        if ax and mx then R.cfg.arrowPos = {x = (ax - mx) * scale, y = (ay - my) * scale} end
                        R.Layout()
                    end
                else
                    local stop = main:GetScript("OnDragStop")
                    if stop then stop(main) end
                end
                C_Timer.After(.2, function()
                    if InCombatLockdown() then return end
                    for _, a in ipairs(R.arrows) do a:SetAttribute("swallow", nil) end
                end)
            end)
            b:HookScript("OnMouseUp", function(self)
                R.hold = nil
                C_Timer.After(.2, function()
                    if not InCombatLockdown() and not R.moving then self:SetAttribute("swallow", nil) end
                end)
            end)
            b:Hide()
            R.arrows[i] = b
        end
        -- CH : couche 2 (bouton « 2 » de l'appli = F12 maintenue) et page automatique en combat.
        local layer = CreateFrame("Button", "StreamingTouchLayer" .. R.opts.suffix, UIParent, "SecureHandlerClickTemplate")
        layer:RegisterForClicks("AnyDown", "AnyUp")
        layer:SetSize(1, 1)
        layer:SetPoint("TOPLEFT")
        layer:SetFrameRef("ring", ring)
        layer:SetAttribute("_onclick", R.LAYER)
        layer:HookScript("OnClick", function() pcall(R.Mark, R.ring:GetAttribute("current")) end)
        layer:Show()
        R.layer = layer
        if SetOverrideBindingClick then SetOverrideBindingClick(layer, true, "F12", layer:GetName(), "LeftButton") end
        local auto = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
        auto:SetFrameRef("ring", ring)
        auto:SetFrameRef("layer", layer)
        auto:SetAttribute("_onstate-combat", R.COMBAT)
        auto:SetAttribute("_onstate-forme", R.FORME)
        auto:HookScript("OnAttributeChanged", function(_, name)
            if (name == "state-combat" or name == "state-forme") and R.ring then pcall(R.Mark, R.ring:GetAttribute("current")) end
        end)
        R.auto = auto
        if RegisterStateDriver then RegisterStateDriver(auto, "combat", "[combat] 1; 0") end
        -- Formes apprises ou changées : on refait la liste « posture -> page » (hors combat).
        local formes = CreateFrame("Frame")
        for _, ev in ipairs({"UPDATE_SHAPESHIFT_FORMS", "SPELLS_CHANGED", "PLAYER_REGEN_ENABLED"}) do
            pcall(formes.RegisterEvent, formes, ev)
        end
        formes:SetScript("OnEvent", function() pcall(R.UpdateForms) end)
    end
    ring.edge = Disc(ring, -8, 1, .82, .32, .95)
    ring.plate = Disc(ring, -7, .03, .05, .09, .9)
    ring.edge2 = Disc(ring, -6, 1, .82, .32, .45)
    ring.inner = Disc(ring, -5, .06, .09, .15, .95)
    ring.title = ring:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ring.title:SetPoint("CENTER", 0, 18)
    ring.title:SetWidth(90)
    ring.title:SetWordWrap(false)

    local close = CreateFrame("Button", "StreamingTouchRingClose" .. R.opts.suffix, ring, "SecureHandlerClickTemplate")
    close:SetSize(30, 30)
    close:SetPoint("CENTER", 0, -4)
    close:RegisterForClicks("AnyUp")
    close:SetFrameRef("ring", ring)
    close:SetAttribute("_onclick", [=[ self:GetFrameRef("ring"):Hide() ]=])
    if R.opts.noClose then
        -- Menu rond : pas de croix dessinée, mais tout le milieu ferme le rond d'un appui.
        close:SetSize(76, 76)
    else
        close:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        close:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        close:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    end

    local edit = CreateFrame("Button", nil, ring)
    edit:SetSize(76, 20)
    edit:SetPoint("CENTER", 0, -30)
    edit.text = edit:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    edit.text:SetAllPoints()
    edit.text:SetText("Modifier")
    edit:SetScript("OnClick", function() R.OpenEditor() end)
    ring.close, ring.edit = close, edit
    -- Rond ouvert : Échap (touche Échap de l'appli comprise) le ferme, même en combat.
    local esc = CreateFrame("Frame", nil, ring, "SecureHandlerShowHideTemplate")
    esc:SetFrameRef("main", main)
    esc:SetAttribute("closer", "StreamingTouchRingClose" .. R.opts.suffix)
    esc:SetAttribute("_onshow", [=[
        self:ClearBindings()
        local main = self:GetFrameRef("main")
        if main and main:GetAttribute("fixed") then return end
        self:SetBindingClick(true, "ESCAPE", self:GetAttribute("closer"))
    ]=])
    esc:SetAttribute("_onhide", [=[ self:ClearBindings() ]=])
    ring.esc = esc
    -- Toujours affiché : la touche change de page, on remet les onglets à jour.
    main:HookScript("OnClick", function()
        if R.cfg and R.cfg.open == "fixed" then R.Mark(R.ring:GetAttribute("current")) end
    end)

    main:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        R.moving = true
        self:SetAttribute("swallow", true)
        ring:Hide()
        self:StartMoving()
    end)
    main:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        R.moving = nil
        if InCombatLockdown() then return end
        self:SetUserPlaced(false)
        local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
        local x, y = self:GetCenter()
        if x then R.cfg.pos = {x = x * scale, y = y * scale} end
        R.PlaceKey()
        R.PlaceRing()
        if R.cfg.open == "fixed" then ring:Show() end
        C_Timer.After(.2, function()
            if not InCombatLockdown() then self:SetAttribute("swallow", nil) end
        end)
    end)
    -- Plus d'appui long : tout se modifie dans les réglages (bouton de la mini-carte).
    main:HookScript("OnMouseUp", function(self)
        R.hold = nil
        C_Timer.After(.2, function()
            if not InCombatLockdown() and not R.moving then self:SetAttribute("swallow", nil) end
        end)
    end)
end

-- Recharge des sorts, ronde comme le bouton, avec les secondes qui restent (lisibles sur un téléphone).
-- CH : l'infobulle du jeu sur un bouton : sort (nom, rang, description), objet, familier, ou son nom.
-- Le doigt sur le petit rond doré du maintien : l'infobulle du second sort (ou objet).
local function OverBadge(b)
    local t = b.holdBadge
    if not (b.hold and t and t:IsShown() and GetCursorPosition and t.GetRect) then return false end
    local l, bottom, w, h = t:GetRect()
    if not l then return false end
    local x, y = GetCursorPosition()
    local s = (t.GetEffectiveScale and t:GetEffectiveScale()) or b:GetEffectiveScale()
    x, y = x / s, y / s
    local m = 4
    return x >= l - m and x <= l + w + m and y >= bottom - m and y <= bottom + h + m
end
local function ShowSpell(tip, spell)
    local W = addon.book
    local id = (W and W.Best and W.Best(spell)) or (type(spell) == "number" and spell) or nil
    if not (id and tip.SetSpellByID) or not pcall(tip.SetSpellByID, tip, id) then return false end
    -- Le rang (« Rang 3 ») en haut à droite, comme dans le grimoire.
    local rank = W and W.Subtext and W.Subtext(id)
    if rank and rank ~= "" then
        local right = _G and _G[(tip.GetName and tip:GetName() or "GameTooltip") .. "TextRight1"]
        if right then
            right:SetText(rank)
            right:SetTextColor(.6, .6, .6)
            right:Show()
        else
            tip:AddLine(rank, .6, .6, .6)
        end
    end
    return true
end
function R.Tooltip(b)
    local tip = GameTooltip
    if not tip or not b or not b:IsVisible() then return end
    R.tipOwner = b
    local onBadge = OverBadge(b)
    R.tipOnBadge = onBadge
    if GameTooltip_SetDefaultAnchor then GameTooltip_SetDefaultAnchor(tip, b) else tip:SetOwner(b, "ANCHOR_LEFT") end
    local done = false
    if onBadge then
        local hold = b.hold
        if hold.a == "SPELL" then
            done = ShowSpell(tip, hold.spell)
        elseif hold.a == "ITEM" and tip.SetItemByID then
            done = pcall(tip.SetItemByID, tip, hold.item)
        end
        if not done then tip:SetText(R.HoldName(hold), 1, .82, .32) end
        tip:AddLine("Au maintien (appui long)", .3, .9, .95)
        tip:Show()
        return
    end
    local item = b.item
    local spell = (item and item.a == "SPELL" and item.spell) or b.spell
    if b.petSlot and tip.SetPetAction then
        done = pcall(tip.SetPetAction, tip, b.petSlot)
    elseif b.itemID and tip.SetItemByID then
        done = pcall(tip.SetItemByID, tip, b.itemID)
    elseif spell then
        done = ShowSpell(tip, spell)
    end
    if not done then tip:SetText(b.name or "?", 1, .82, .32) end
    if b.hold then tip:AddLine("Maintien : " .. R.HoldName(b.hold), .3, .9, .95) end
    tip:Show()
end
function R.HideTooltip(b)
    if R.tipOwner == b then R.tipOwner = nil end
    if GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner() == b then GameTooltip:Hide() end
end
-- Le doigt glisse du bouton au petit rond (ou l'inverse) : l'infobulle change.
function R.WatchTooltip()
    local b = R.tipOwner
    if not b then return end
    if not b:IsVisible() then R.tipOwner = nil return end
    if OverBadge(b) ~= (R.tipOnBadge or false) then R.Tooltip(b) end
end
function R.AddCooldown(b)
    b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cooldown:SetAllPoints(b.icon)
    if b.cooldown.SetUseCircularEdge then b.cooldown:SetUseCircularEdge(true) end
    if b.cooldown.SetHideCountdownNumbers then b.cooldown:SetHideCountdownNumbers(false) end
end
function R.NewItem()
    local n = #R.pool + 1
    local b = CreateFrame("Button", "StreamingTouchRingItem" .. R.opts.suffix .. n, R.ring, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")
    R.Visual(b)
    R.AddCooldown(b)
    b:SetScript("PostClick", function(self, button, down)
        if (down and true or false) ~= (GetCVarBool("ActionButtonUseKeyDown") and true or false) then return end
        if self.run and not self.run() then Say((self.name or "?") .. " n'est pas disponible ici.") end
    end)
    SecureHandlerWrapScript(b, "OnClick", R.main, R.PRE, R.POST)
    b:HookScript("OnEnter", function(self) R.Tooltip(self) end)
    b:HookScript("OnLeave", function(self) R.HideTooltip(self) end)
    -- Un sort lâché sur l'arc depuis le grimoire : il se met à cette place.
    b:SetScript("OnReceiveDrag", function(self) R.DropOn(self) end)
    R.pool[n] = b
    return b
end

function R.NewTab()
    local n = #R.tabs + 1
    local b = CreateFrame("Button", "StreamingTouchRingTab" .. R.opts.suffix .. n, R.ring, "SecureHandlerClickTemplate")
    b:RegisterForClicks("AnyUp")
    b:SetFrameRef("ring", R.ring)
    b:SetAttribute("_onclick", R.TAB)
    R.Visual(b)
    b:HookScript("OnClick", function(self) R.Mark(self:GetAttribute("index")) end)
    R.tabs[n] = b
    return b
end

function R.NewFlyButton(pop)
    R.flyCount = (R.flyCount or 0) + 1
    local btn = CreateFrame("Button", "StreamingTouchFly" .. R.opts.suffix .. R.flyCount, pop, "SecureActionButtonTemplate")
    btn:RegisterForClicks("AnyUp", "AnyDown")
    R.Visual(btn)
    R.AddCooldown(btn)
    SecureHandlerWrapScript(btn, "OnClick", R.main, R.PRE, R.POST)
    return btn
end
function R.FlyPop(k)
    R.flyPool = R.flyPool or {}
    local pop = R.flyPool[k]
    if not pop then
        pop = CreateFrame("Frame", nil, R.ring, "SecureFrameTemplate")
        pop.back = RoundBox(pop, "BACKGROUND", 0, 14, 0)
        pop.back:SetColor(0, 0, 0, 0)
        pop.buttons = {}
        pop:HookScript("OnShow", function() R.FadePops() end)
        pop:HookScript("OnHide", function() R.FadePops() end)
        R.flyPool[k] = pop
    end
    return pop
end
-- Une bulle ouverte : les autres boutons du rond s'effacent (réglage « Fondu derrière » de l'onglet Barre).
function R.FadePops()
    local open
    for _, pop in ipairs(R.flyPool or {}) do
        if pop:IsShown() and R.ring and R.ring:IsShown() then open = pop end
    end
    local fade = addon.Fondu and addon.Fondu() or .35
    for _, b in ipairs(R.pool or {}) do b:SetAlpha((open and b ~= open.owner) and fade or 1) end
end
-- Remplit la bulle du groupe (hors combat) : ses sorts appris, le plus proche du bouton en premier.
function R.FillPop(k, b, item, parent, size, x, color, shape)
    local pop = R.FlyPop(k)
    pop.owner = b
    local entries = {}
    if item.a == "PETBAR" then
        local bar = R.PetBar()
        for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
            if bar[slot] then entries[#entries + 1] = {pet = bar[slot], icon = bar[slot].icon} end
        end
    else
        for _, s in ipairs(FlyoutSpells(item.flyout)) do entries[#entries + 1] = {spell = s.spell, label = s.label, icon = s.icon} end
    end
    if item.a == "GROUP" then
        entries = {}
        for _, sub in ipairs(R.GroupEntries(item)) do
            local label, icon, text, macro, _, spell, _, petSlot = R.Resolve(sub)
            local pe = petSlot and R.PetBar()[petSlot]
            if pe then
                entries[#entries + 1] = {pet = pe, icon = icon, hold = sub.hold}
            elseif spell then
                entries[#entries + 1] = {spell = sub.spell, label = spell, icon = icon, hold = sub.hold}
            elseif text or macro then
                entries[#entries + 1] = {text = text, macro = macro, label = label, icon = icon, hold = sub.hold}
            end
        end
    end
    pop:SetParent(parent)
    pop:SetFrameLevel(parent:GetFrameLevel() + 20)
    pop:Hide()
    local scale = R.main:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local mx = R.main:GetCenter()
    local left = mx ~= nil and (mx + x) * scale > UIParent:GetWidth() / 2
    local dir = left and -1 or 1
    local pitch, rowH = size + 6, size + 10
    local perRow = #entries <= 6 and math.max(1, #entries) or 5
    local rows = math.max(1, math.ceil(#entries / perRow))
    pop:SetSize(math.min(math.max(1, #entries), perRow) * pitch + 6, rows * rowH)
    pop:ClearAllPoints()
    local corner = left and "BOTTOMRIGHT" or "BOTTOMLEFT"
    pop:SetPoint(corner, b, left and "LEFT" or "RIGHT", dir * 4, -rowH / 2)
    b.flySpells = item.a ~= "PETBAR" and {} or nil
    b.petGroup = item.a == "PETBAR" or nil
    for j, e in ipairs(entries) do
        local btn = pop.buttons[j] or R.NewFlyButton(pop)
        pop.buttons[j] = btn
        local col, row = (j - 1) % perRow, math.floor((j - 1) / perRow)
        btn:SetFrameLevel(pop:GetFrameLevel() + 2)
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", pop, corner, dir * (3 + (col + .5) * pitch), rowH / 2 + row * rowH)
        local auto
        if e.pet then
            auto = e.pet.allowed and not e.pet.token and e.pet.name or nil
            btn:SetAttribute("type", "pet")
            btn:SetAttribute("action", e.pet.slot)
            btn:SetAttribute("spell", nil)
            btn.spell, btn.spellID, btn.petSlot = nil, nil, e.pet.slot
            R.Paint(btn, size, e.icon or QUESTION, color, shape, "")
        elseif e.text or e.macro then
            btn:SetAttribute("type", "macro")
            btn:SetAttribute("action", nil)
            btn:SetAttribute("spell", nil)
            btn.spell, btn.spellID, btn.petSlot = nil, nil, nil
            R.Paint(btn, size, e.icon or QUESTION, color, shape, "")
        else
            local name = SpellName(e.spell) or e.label
            btn:SetAttribute("type", "spell")
            btn:SetAttribute("spell", name)
            btn:SetAttribute("action", nil)
            btn.spell, btn.spellID, btn.petSlot = name, e.spell, nil
            R.Paint(btn, size, e.icon, color, shape, "")
            b.flySpells[#b.flySpells + 1] = {name = name, icon = e.icon, id = e.spell}
        end
        btn:SetAttribute("macrotext", e.text)
        btn:SetAttribute("macro", e.macro)
        if btn.spell then addon.AutoCast(btn, btn.spell, btn.spellID) end
        -- Au maintien : le lancement automatique du familier, sinon le second sort de la case (sous-menu).
        local hold = not auto and e.hold and R.Known(e.hold) and e.hold or nil
        local holdSpell = hold and hold.a == "SPELL" and (SpellName(hold.spell) or hold.name) or nil
        local holdMacro = hold and hold.a == "MACRO" and hold.macro or nil
        local holdText = hold and hold.a == "TEXT" and hold.text or nil
        if not (holdSpell or holdMacro or holdText) then hold = nil end
        btn:SetAttribute("type2", auto and "macro" or holdSpell and "spell" or (holdMacro or holdText) and "macro" or nil)
        btn:SetAttribute("spell2", holdSpell)
        btn:SetAttribute("macro2", holdMacro)
        btn:SetAttribute("macrotext2", auto and ("/petautocasttoggle " .. auto) or holdText)
        R.HoldBadge(btn, hold, size)
        btn:Show()
    end
    for j = #entries + 1, #pop.buttons do
        local btn = pop.buttons[j]
        btn:Hide()
        btn:SetAttribute("type", nil)
        btn:SetAttribute("type2", nil)
        R.HoldBadge(btn, nil)
        btn.spell, btn.petSlot = nil, nil
    end
    SecureHandlerSetFrameRef(b, "flypop", pop)
    R.ring:SetFrameRef("pop" .. k, pop)
    b:SetAttribute("flyout", true)
    -- Petite flèche sur le bouton : le côté où la bulle s'ouvre.
    if not b.flyMark then
        b.flyMark = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        if STANDARD_TEXT_FONT then pcall(b.flyMark.SetFont, b.flyMark, STANDARD_TEXT_FONT, 18, "THICKOUTLINE") end
    end
    b.flyMark:ClearAllPoints()
    b.flyMark:SetPoint("CENTER", b, left and "LEFT" or "RIGHT", -dir * 6, 0)
    b.flyMark:SetText(left and "<" or ">")
    b.flyMark:Show()
    return pop
end

function R.PageFrame(i)
    local frame = R.pages[i]
    if not frame then
        frame = CreateFrame("Frame", nil, R.ring, "SecureFrameTemplate")
        frame:SetAllPoints(R.ring)
        R.pages[i] = frame
    end
    return frame
end

function R.PlaceKey()
    local main, cfg = R.main, R.cfg
    local scale = main:GetEffectiveScale() / UIParent:GetEffectiveScale()
    if R.layoutKind == "joystick" and cfg.open == "fixed" then
        local gx, gy = R.StickGuess()
        main:ClearAllPoints()
        main:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (cfg.pos and cfg.pos.x or gx) / scale, (cfg.pos and cfg.pos.y or gy) / scale)
        return
    end
    local x, y, anchored
    if cfg.pos then
        x, y = cfg.pos.x, cfg.pos.y
    elseif R.opts.anchor then
        x, y = R.opts.anchor(R.layoutKind)
        anchored = x ~= nil
    end
    x = x or UIParent:GetWidth() * R.opts.defaultPos[1]
    y = y or UIParent:GetHeight() * R.opts.defaultPos[2]
    -- Toujours affiché : l'ancre donne le centre visuel ; la touche est en bas, et le tout reste dans l'écran.
    if cfg.open == "fixed" and R.extent then
        local e = R.extent
        if anchored then y = y - e.lift * scale end
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        local left, right = (e.left or e.side) * scale, (e.right or e.side) * scale
        local top, bottom = e.top * scale, e.bottom * scale
        if left + right < width then x = math.max(left, math.min(width - right, x)) end
        if top + bottom < height then y = math.max(bottom, math.min(height - top, y)) end
    end
    main:ClearAllPoints()
    main:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

-- Le rond s'ouvre autour du bouton Menu (ou au centre de l'écran) sans jamais sortir de l'écran.
function R.PlaceRing()
    local main, ring, cfg = R.main, R.ring, R.cfg
    local scale = main:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local width, height = UIParent:GetWidth() / scale, UIParent:GetHeight() / scale
    local half = ring:GetWidth() / 2
    local x, y
    if cfg.open ~= "center" then x, y = main:GetCenter() end
    x, y = x or width / 2, y or height / 2
    if cfg.open == "fixed" then
        -- Toujours affiché : collé à la touche (déjà gardée dans l'écran).
        ring:ClearAllPoints()
        ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y + (R.keyOffset or 0))
        return
    end
    x = half * 2 >= width and width / 2 or math.max(half, math.min(width - half, x))
    y = half * 2 >= height and height / 2 or math.max(half, math.min(height - half, y))
    ring:ClearAllPoints()
    ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

function R.Mark(index)
    local cfg = R.cfg
    if not cfg or not R.ring or not index then return end
    for p, tab in ipairs(R.tabs) do
        local on = p == index
        tab.glow:SetShown(on)
        tab.dim = on and 1 or .55
        tab.icon:SetVertexColor(tab.dim, tab.dim, tab.dim)
    end
    local page = cfg.pages[index]
    if page then
        R.ring.title:SetText(page.name or "")
        local c = R.COLOR[page.color or ""]
        if c and c[3] then R.ring.edge:SetVertexColor(c[3], c[4], c[5], .95) else R.ring.edge:SetVertexColor(1, .82, .32, .95) end
        -- Toujours affiché avec plusieurs pages : la touche montre la page en cours.
        if cfg.open == "fixed" and #cfg.pages > 1 and R.main then
            R.main.icon:SetTexture(I(page.icon) or QUESTION)
            local count = math.min(#cfg.pages, R.MAXPAGES)
            R.main.label:SetText(cfg.labels and ((page.name or "") .. " " .. index .. "/" .. count) or "")
            for i, b in ipairs(R.arrows or {}) do
                local target = cfg.pages[R.StepPage(index, i == 1 and -1 or 1)]
                b.icon:SetTexture(I(target and target.icon) or QUESTION)
                b.dim = .65
                b.icon:SetVertexColor(.65, .65, .65)
            end
        end
    end
end

-- Sorts pas encore appris : cachés ; ils apparaissent tout seuls une fois appris chez le maître.
-- Un sort se lance par son nom : le jeu prend toujours le plus haut rang appris.
-- CH : postures / formes. Les formes de la barre de postures du jeu, dans l'ordre (stance:1, stance:2…).
function R.FormChoices()
    local list = {}
    if not (GetNumShapeshiftForms and GetShapeshiftFormInfo) then return list end
    for i = 1, GetNumShapeshiftForms() or 0 do
        local _, _, _, id = GetShapeshiftFormInfo(i)
        list[i] = id or false
    end
    return list
end
local function FormIndex(forme, list)
    if type(forme) ~= "table" then return end
    local want = {}
    for _, id in ipairs(forme) do
        local name = SpellName(id)
        if name then want[name] = true end
    end
    for i, id in ipairs(list) do
        if id and want[SpellName(id) or ""] then return i end
    end
end
function R.FormName(forme)
    if type(forme) ~= "table" then return "aucune" end
    local list = R.FormChoices()
    local i = FormIndex(forme, list)
    return SpellName(i and list[i] or forme[1]) or "?"
end
-- Pilote sécurisé « forme » : [stance:N] page ; 0 sans forme. Hors combat seulement.
function R.UpdateForms()
    if not (R.auto and R.cfg and RegisterStateDriver) or InCombatLockdown() then return end
    local list, parts, taken = R.FormChoices(), {}, {}
    for p, pg in ipairs(R.cfg.pages) do
        if type(pg.forme) == "table" then
            local want = {}
            for _, id in ipairs(pg.forme) do
                local name = SpellName(id)
                if name then want[name] = true end
            end
            for i, id in ipairs(list) do
                if id and not taken[i] and want[SpellName(id) or ""] then
                    taken[i] = true
                    parts[#parts + 1] = "[stance:" .. i .. "] " .. p
                end
            end
        end
    end
    parts[#parts + 1] = "0"
    local driver = table.concat(parts, "; ")
    if driver ~= R.formDriver then
        R.formDriver = driver
        RegisterStateDriver(R.auto, "forme", driver)
    end
end
-- Éditeur : la page passe à la forme suivante de la barre de postures, puis « aucune ».
function R.CycleForm()
    local kind, t = R.Target()
    if kind ~= "page" or not t then return end
    local list = R.FormChoices()
    if #list == 0 then
        t.forme = nil
        Say("ce personnage n'a encore aucune posture ni forme.")
        R.Apply()
        return
    end
    local cur = FormIndex(t.forme, list) or 0
    local nextId
    for i = cur + 1, #list do
        if list[i] then nextId = list[i] break end
    end
    t.forme = nextId and {nextId} or nil
    R.Apply()
end

function R.ScanKnown()
    local W = addon.book
    if W and W.Scan then pcall(W.Scan) end
end
function R.Known(item)
    if item.a == "PETBAR" then return next(R.PetBar()) ~= nil end
    if item.a == "GROUP" then return #R.GroupEntries(item) > 0 end
    if item.a == "PETACTION" then return R.PetBar()[item.slot or 0] ~= nil end
    if item.a ~= "SPELL" then return true end
    -- Une posture ou un ordre du familier glissé de son grimoire : connu s'il est sur sa barre.
    if R.PetSlotFor(item) then return true end
    local W = addon.book
    if not W or not W.book or (W.bookCount or 0) == 0 then return true end
    return W.Best(item.spell) ~= nil
end
function R.KnownSig()
    local parts = {}
    for _, page in ipairs(R.cfg and R.cfg.pages or {}) do
        for _, item in ipairs(page.items) do
            if item.a == "FLYOUT" then
                parts[#parts + 1] = "f" .. #FlyoutSpells(item.flyout)
            elseif item.a == "GROUP" then
                parts[#parts + 1] = "g" .. #R.GroupEntries(item)
            else
                parts[#parts + 1] = R.Known(item) and "1" or "0"
            end
            if item.hold then parts[#parts + 1] = R.Known(item.hold) and "h" or "-" end
        end
    end
    local bar, names = R.PetBar and R.PetBar() or {}, {}
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do names[slot] = bar[slot] and bar[slot].name or "-" end
    parts[#parts + 1] = "P" .. table.concat(names, ",")
    return table.concat(parts)
end

-- Page suivante (step 1) ou précédente (-1), en sautant les pages vides.
function R.StepPage(index, step)
    local counts = R.counts or {}
    local count = #counts
    if count == 0 then return index end
    local current = index or 1
    for _ = 1, count do
        current = (current - 1 + step) % count + 1
        if (counts[current] or 1) > 0 then break end
    end
    return current
end

-- Le joystick CAM de l'app : sa place se règle dans l'app, l'addon ne la voit pas. Par défaut,
-- en bas à droite comme sur l'écran d'un téléphone ; « Caler sur le joystick » la rend exacte.
function R.StickGuess()
    local w, h = UIParent:GetWidth(), UIParent:GetHeight()
    return w * .905, h * .195, h * .19
end
function R.StickRadius()
    if R.cfg and tonumber(R.cfg.stickR) then return R.cfg.stickR end
    local _, _, r = R.StickGuess()
    return r
end
-- Début et fin de l'arc (degrés autour du joystick ; 215° = en bas à gauche, 80° = en haut),
-- réglables par le calage ou dans les réglages ; ramenés dans l'écran si un bout en sort.
R.ARC_FROM, R.ARC_TO = 215, 80
function R.ArcEnds(radius, half)
    local cfg = R.cfg
    local from = tonumber(cfg.arcFrom) or R.ARC_FROM
    local to = tonumber(cfg.arcTo) or R.ARC_TO
    if math.abs(to - from) < 20 then to = from + (to < from and -20 or 20) end
    local gx, gy = R.StickGuess()
    local cx, cy = cfg.pos and cfg.pos.x or gx, cfg.pos and cfg.pos.y or gy
    local w, h = UIParent:GetWidth(), UIParent:GetHeight()
    local function inside(a)
        local x, y = cx + math.cos(math.rad(a)) * radius, cy + math.sin(math.rad(a)) * radius
        return x >= half and x <= w - half and y >= half and y <= h - half
    end
    local dir = to < from and -1 or 1
    for _ = 1, 180 do
        if inside(from) or math.abs(to - from) <= 20 then break end
        from = from + dir
    end
    for _ = 1, 180 do
        if inside(to) or math.abs(to - from) <= 20 then break end
        to = to - dir
    end
    return from, to
end
-- Une page : ses sorts côte à côte, du début à la fin de l'arc (pas plus écartés qu'un peu).
-- Trop serrés : un peu plus petits (70 % au moins) ; sinon plusieurs rangées en taille normale.
function R.ArcRows(n, r, from, to, itemSize, labelRoom)
    local rows = {}
    if n < 1 then return rows end
    local span = to - from
    local len = math.abs(math.rad(span))
    local small = itemSize * .7
    local function Row(radius, count)
        local step = count > 1 and span / (count - 1) or 0
        local widest = math.deg((itemSize + 30) / radius)
        if math.abs(step) > widest then step = step < 0 and -widest or widest end
        local size = count > 1 and math.abs(math.rad(step)) * radius - 4 or itemSize
        return {r = radius, n = count, step = step, size = math.max(small, math.min(itemSize, size))}
    end
    if n <= math.floor(len * r / (small + 2)) + 1 then
        rows[1] = Row(r, n)
        return rows
    end
    local left, radius = n, r
    while left > 0 do
        local fit = math.max(1, math.floor(len * radius / (itemSize + 4)) + 1)
        local count = #rows == 3 and left or math.min(left, fit)
        rows[#rows + 1] = Row(radius, count)
        left = left - count
        radius = radius + itemSize + 8 + labelRoom
    end
    return rows
end
-- Flèches de page : à gauche du premier sort, à sa hauteur ; ou là où on les a glissées.
function R.ArrowSpot(rings, i)
    local cfg, main = R.cfg, R.main
    local pos = cfg.arrowPos
    if pos and tonumber(pos.x) and tonumber(pos.y) then
        local scale = main:GetEffectiveScale() / UIParent:GetEffectiveScale()
        local x, y = pos.x / scale, pos.y / scale
        local mx, my = main:GetCenter()
        if mx then
            x = math.max(22 - mx, math.min(UIParent:GetWidth() / scale - 68 - mx, x))
            y = math.max(22 - my, math.min(UIParent:GetHeight() / scale - 22 - my, y))
        end
        return i == 1 and x or x + 46, y
    end
    if not rings.r then return (i == 1 and -26 or 26), -22 end
    local a = math.rad(rings.from)
    local right = math.cos(a) * rings.r - 53
    local y = math.sin(a) * rings.r
    local _, cy = main:GetCenter()
    if cy then y = math.max(y, 24 - cy) end
    return i == 1 and right - 46 or right, y
end

-- Reconstruit le rond à partir des réglages. Hors combat seulement (cadres sécurisés).
function R.Layout()
    if not R.main then return end
    if InCombatLockdown() then R.pending = true return end
    R.pending = nil
    local cfg = R.Config()
    local main, ring = R.main, R.ring
    if StreamingTouchDB[R.opts.off] then
        ring:Hide()
        main:Hide()
        return
    end
    main:Show()
    main:SetScale(math.max(.5, math.min(2, cfg.scale or 1)))
    main:SetAttribute("keydown", GetCVarBool("ActionButtonUseKeyDown") and true or false)
    local fixed = cfg.open == "fixed"
    main:SetAttribute("fixed", fixed)
    for _, t in ipairs({ring.edge, ring.plate, ring.edge2, ring.inner, ring.title, ring.close}) do
        t:SetShown(not fixed)
    end
    ring.edit:Hide()
    local keyless = fixed and R.arrows ~= nil
    local layout = cfg.layout
    local mobile = fixed and (layout == nil or layout == "joystick" or layout == "mobile" or layout == "arc")
    R.layoutKind = fixed and (mobile and "joystick" or layout) or nil
    -- Première fois autour du joystick : l'ancienne place ne vaut plus.
    if mobile and not cfg.joy then
        cfg.joy = 1
        cfg.pos = nil
    end
    R.Paint(main, keyless and 44 or 54, cfg.keyIcon or R.opts.keyIcon or R.KEYICON, cfg.keyColor or "or", cfg.keyShape or cfg.shape, cfg.labels and R.opts.label or "")
    main.rim:SetAlpha(keyless and 0 or 1)
    main.icon:SetAlpha(keyless and 0 or 1)
    main:EnableMouse(not keyless)
    main.label:ClearAllPoints()
    if mobile and keyless then
        main.label:SetPoint("TOP", main, "CENTER", -95, -84)
        R.labelOnArrows = true
    elseif keyless then
        main.label:SetPoint("TOP", main, "CENTER", 0, -46)
    else
        main.label:SetPoint("TOP", main, "BOTTOM", 0, -1)
    end
    R.PlaceKey()

    local pages = cfg.pages
    local count = math.min(#pages, R.MAXPAGES)
    if R.opts.hideUnknown then R.ScanKnown() end
    local visible = {}
    for p = 1, count do
        local list = {}
        for _, item in ipairs(pages[p].items) do
            if #list < R.MAXITEMS and (not R.opts.hideUnknown or R.Known(item)) then list[#list + 1] = item end
        end
        visible[p] = list
    end
    local itemSize, tabSize = 50, 38
    local labelRoom = cfg.labels and 14 or 0
    local rTab = count > 6 and 80 or 72
    local rItem = rTab + tabSize / 2 + itemSize / 2 + 12 + labelRoom
    local outer = rItem + itemSize / 2 + 8 + labelRoom
    -- Toujours affiché : pas de disque. En arc (par défaut) : éventail au-dessus de la touche,
    -- rangée du bas d'abord (la plus proche du pouce). En rond : cercle avec la touche en bas.
    local arc = fixed and layout == "fan"
    local SPAN = 140
    -- Autour du joystick : les sorts côte à côte sur un arc qui suit le cercle du joystick CAM de
    -- l'app, du premier sort (en bas à gauche) au dernier ; début et fin se règlent.
    local rings = {}
    local innerCap, rInner, rOuter
    if mobile then
        local ringScale = math.max(.5, math.min(2, cfg.scale or 1))
        local r = R.StickRadius() / ringScale + itemSize / 2 + 10 + (tonumber(cfg.gap) or 0) / ringScale
        rings.r = r
        rings.from, rings.to = R.ArcEnds(r * ringScale, (itemSize / 2 + 3) * ringScale)
        rItem = r
        for p = 1, count do
            rings[p] = R.ArcRows(#visible[p], r, rings.from, rings.to, itemSize, labelRoom)
            local last = rings[p][#rings[p]]
            if last then rItem = math.max(rItem, last.r) end
        end
        outer = rItem + itemSize / 2 + 8 + labelRoom
    elseif fixed then
        local most = 1
        for p = 1, count do most = math.max(most, #visible[p]) end
        local pitch = itemSize + 12
        if arc then
            innerCap = most > 5 and math.floor(most * .4 + .5) or most
            rInner = math.max(19 + itemSize / 2 + 26, innerCap * pitch / math.rad(SPAN),
                (itemSize / 2 + labelRoom + 6) / math.sin(math.rad(90 - SPAN / 2 + SPAN / (2 * innerCap))))
            rOuter = math.max(rInner + itemSize + labelRoom + 10, (most - innerCap) * pitch / math.rad(SPAN))
            rItem = most > innerCap and rOuter or rInner
        else
            rItem = math.max(itemSize / 2 + 30 + labelRoom, (most + 1) * pitch / (2 * math.pi))
        end
        outer = rItem + itemSize / 2 + 8 + labelRoom
    end
    local mid = rTab + tabSize / 2 + 8
    ring:SetSize(outer * 2, outer * 2)
    ring.edge:SetSize(outer * 2, outer * 2)
    ring.plate:SetSize(outer * 2 - 5, outer * 2 - 5)
    ring.edge2:SetSize(mid * 2, mid * 2)
    ring.inner:SetSize(mid * 2 - 3, mid * 2 - 3)
    ring:SetAttribute("pages", count)
    -- CH : rôles des pages. Premier essai : Mêlée (page 2) en couche 2, Tirs (page 1) en combat.
    if R.opts.fixed and not cfg.rolesV1 then
        cfg.rolesV1 = true
        if pages[2] then pages[2].layer = true end
        if pages[1] then pages[1].combat = true end
    end
    if R.opts.fixed and not cfg.setupV2 then
        cfg.setupV2 = true
        R.SuggestSetup(cfg)
    end
    if R.opts.fixed and not cfg.setupV3 then
        cfg.setupV3 = true
        R.SuggestGroups(cfg)
    end
    if not R.opts.fixed and not cfg.postureV2 then
        cfg.postureV2 = true
        R.FillPostures(cfg)
    end
    local roles = {}
    for p = 1, count do
        for _, k in ipairs({"layer", "combat", "peace"}) do
            if pages[p][k] and not roles[k] then roles[k] = p end
        end
    end
    ring:SetAttribute("layerpage", roles.layer)
    ring:SetAttribute("combatpage", roles.combat)
    ring:SetAttribute("peacepage", roles.peace)
    if R.opts.fixed then pcall(R.UpdateForms) end
    -- Toujours affiché en rond : la touche est en bas du cercle, le rond au-dessus d'elle.
    R.keyOffset = (fixed and not arc and not mobile) and rItem or 0
    -- Ce qui dépasse autour de la touche (unités du rond), pour tout garder dans l'écran ;
    -- lift : de combien l'ancre (centre visuel) est au-dessus de la touche.
    local below = keyless and (46 + labelRoom + 6) or (19 + labelRoom + 6)
    if mobile then
        -- L'ancre est la place du gros bouton ; à droite, rien au-delà de 70°.
        R.extent = nil
    elseif arc then
        R.extent = {top = outer, bottom = below, side = outer, lift = outer / 2}
    elseif fixed then
        R.extent = {top = rItem + outer, bottom = math.max(below, outer - rItem), side = outer, lift = rItem}
    else
        R.extent = nil
    end
    -- Flèches : en bas, côte à côte, à la place du bouton de page.
    R.counts = {}
    for p = 1, count do R.counts[p] = #visible[p] end
    for i, b in ipairs(R.arrows or {}) do
        b:ClearAllPoints()
        if mobile then
            -- Petites flèches au bout de l'arc, en bas à gauche, à la hauteur du premier sort.
            local x, y = R.ArrowSpot(rings, i)
            b:SetPoint("CENTER", main, "CENTER", x, y)
        else
            b:SetPoint("CENTER", main, "CENTER", (i == 1 and -26 or 26), -22)
        end
        R.Paint(b, mobile and 40 or 44, QUESTION, cfg.keyColor or "or", cfg.keyShape or cfg.shape, "")
        b:SetShown(fixed and not cfg.arrowsOff)
    end
    R.PlaceKey()
    -- Autour du joystick : flèches (la droite suit la gauche) et nom de la page gardés dans l'écran.
    if mobile and R.arrows then
        for i, b in ipairs(R.arrows) do
            b:ClearAllPoints()
            if i == 1 then
                local x, y = R.ArrowSpot(rings, 1)
                b:SetPoint("CENTER", main, "CENTER", x, y)
            else
                b:SetPoint("CENTER", R.arrows[1], "CENTER", 46, 0)
            end
        end
        local x, y = R.ArrowSpot(rings, 1)
        main.label:ClearAllPoints()
        main.label:SetPoint("TOP", main, "CENTER", x + 23, y - 24)
    end

    -- Ordres du familier qui ne sont pas sur sa barre du jeu : posés dans une case vide (hors combat).
    if next(R.PetBar()) then
        for p = 1, count do
            for _, item in ipairs(pages[p].items) do
                local token = item.a == "TEXT" and R.PET_TOKENS[string.lower(item.text or "")]
                if token and not R.PetSlotFor(item) then pcall(R.PlacePetCommand, token, item.label) end
            end
        end
    end
    local used, pops = 0, 0
    for p = 1, count do
        local page = pages[p]
        local frame = R.PageFrame(p)
        ring:SetFrameRef("page" .. p, frame)
        ring:SetAttribute("count" .. p, #visible[p])
        local tab = R.tabs[p] or R.NewTab()
        local a = math.rad(90 - (p - 1) * 360 / count)
        tab:SetAttribute("index", p)
        tab:ClearAllPoints()
        tab:SetPoint("CENTER", ring, "CENTER", math.cos(a) * rTab, math.sin(a) * rTab)
        R.Paint(tab, tabSize, page.icon, page.color, cfg.shape, "")
        tab:SetShown(not fixed)
        local items = #visible[p]
        for i = 1, items do
            used = used + 1
            local b = R.pool[used] or R.NewItem()
            local item = visible[p][i]
            local label, icon, text, macro, run, spell, click, petSlot = R.Resolve(item)
            local x, y, size = nil, nil, itemSize
            if mobile then
                do
                    local rows, k, n = rings[p], 1, i
                    while rows[k + 1] and n > rows[k].n do n, k = n - rows[k].n, k + 1 end
                    local row = rows[k]
                    local a = math.rad(rings.from + (n - 1) * row.step)
                    x, y = math.cos(a) * row.r, math.sin(a) * row.r
                    size = math.floor(row.size + .5)
                end
            elseif arc then
                -- Éventail : de gauche à droite, rangée du bas puis rangée du haut.
                local inner = math.min(items, innerCap)
                local radius, k, m = rInner, i, inner
                if i > inner then radius, k, m = rOuter, i - inner, items - inner end
                local a = math.rad(90 + SPAN / 2 - (k - .5) * SPAN / m)
                x, y = math.cos(a) * radius, math.sin(a) * radius
            else
                -- Rond fixe : de la gauche vers la droite par le haut, la place du bas pour la touche.
                local ia = fixed and math.rad(270 - i * 360 / (items + 1)) or math.rad(90 - (i - 1) * 360 / items)
                x, y = math.cos(ia) * rItem, math.sin(ia) * rItem
            end
            b:SetParent(frame)
            b:SetFrameLevel(frame:GetFrameLevel() + 2)
            b:ClearAllPoints()
            b:SetPoint("CENTER", ring, "CENTER", x, y)
            local secureClick = (not spell and not text and not macro) and click or nil
            b:SetAttribute("type", petSlot and "pet" or spell and "spell" or (text or macro) and "macro" or secureClick and "click" or nil)
            b:SetAttribute("action", petSlot)
            b:SetAttribute("spell", (not petSlot) and spell or nil)
            -- Comme sur la barre du jeu : appui long / clic droit = lancement automatique oui / non.
            local pe = petSlot and R.PetBar()[petSlot]
            local autoName = pe and pe.allowed and not pe.token and pe.name or nil
            -- Au maintien : un second sort ou une macro, si la case en a un (sort, macro ou macro libre).
            local hold = (not autoName and (item.a == "SPELL" or item.a == "MACRO" or item.a == "TEXT" or item.a == "ITEM"))
                and item.hold or nil
            if hold and not R.Known(hold) then hold = nil end
            local holdSpell = hold and hold.a == "SPELL" and (SpellName(hold.spell) or hold.name) or nil
            local holdMacro = hold and hold.a == "MACRO" and hold.macro or nil
            local holdText = hold and ((hold.a == "TEXT" and hold.text) or (hold.a == "ITEM" and hold.item
                and ("/use item:" .. hold.item))) or nil
            if not (holdSpell or holdMacro or holdText) then hold = nil end
            b:SetAttribute("type2", autoName and "macro" or holdSpell and "spell" or (holdMacro or holdText) and "macro" or nil)
            b:SetAttribute("spell2", holdSpell)
            b:SetAttribute("macro2", holdMacro)
            b:SetAttribute("macrotext2", autoName and ("/petautocasttoggle " .. autoName) or holdText)
            R.HoldBadge(b, hold, size)
            b.hold = hold
            b.petSlot = petSlot
            b:SetAttribute("macrotext", text)
            b:SetAttribute("macro", macro)
            if spell and not petSlot then
                addon.AutoCast(b, spell, (item.a == "SPELL" and type(item.spell) == "number") and item.spell or nil)
            end
            b:SetAttribute("clickbutton", secureClick)
            b.run = (not text and not macro and not spell and not secureClick) and run or nil
            b.spell = spell
            b.page, b.item = p, item
            b.spellID = (item.a == "SPELL" and type(item.spell) == "number") and item.spell or nil
            b.itemID = item.a == "ITEM" and item.item or nil
            b.name = label
            R.Paint(b, size, icon, item.color or page.color, item.shape or cfg.shape, cfg.labels and label or "")
            if item.a == "FLYOUT" or item.a == "PETBAR" or item.a == "GROUP" then
                pops = pops + 1
                R.FillPop(pops, b, item, frame, size, x, item.color or page.color, item.shape or cfg.shape)
                b.flyIcon = icon
            else
                b:SetAttribute("flyout", nil)
                b.flySpells, b.flyIcon, b.petGroup = nil, nil, nil
                if b.flyMark then b.flyMark:Hide() end
            end
            b:Show()
        end
    end
    for i = used + 1, #R.pool do R.pool[i]:Hide() end
    ring:SetAttribute("pops", pops)
    for k = pops + 1, #(R.flyPool or {}) do R.flyPool[k]:Hide() end
    for i = count + 1, #R.tabs do R.tabs[i]:Hide() end
    for i = count + 1, #R.pages do R.pages[i]:Hide() end
    local current = ring:GetAttribute("current") or 1
    if current > count then current = 1 end
    -- Toujours affiché : jamais sur une page vide s'il y en a une avec des sorts.
    if fixed and #visible[current] == 0 then
        for p = 1, count do
            if #visible[p] > 0 then current = p break end
        end
    end
    ring:SetAttribute("current", current)
    for p = 1, count do R.pages[p]:SetShown(p == current) end
    R.Mark(current)
    R.PlaceRing()
    R.used = used
    if fixed then ring:Show() elseif R.wasFixed then ring:Hide() end
    R.wasFixed = fixed
    if R.opts.hideUnknown then R.knownSig = R.KnownSig() end
    pcall(R.UpdateSpells)
end

-- Recharge, sort actif (aspect en cours), sort utilisable et portée, sur chaque bouton de sort.
-- En combat, le jeu donne des valeurs « secrètes » : la recharge passe par ses objets « durée ».
function R.ClearCooldown(cd)
    if C_Spell and C_Spell.GetSpellCooldownDuration and cd.Clear then cd:Clear() else cd:SetCooldown(0, 0) end
end
function R.ShowCooldown(cd, spell)
    if C_Spell and C_Spell.GetSpellCooldownDuration and cd.SetCooldownFromDurationObject then
        local okInfo, info = pcall(C_Spell.GetSpellCooldown, spell)
        local active = okInfo and type(info) == "table" and info.isActive
        if Secret(active) then active = nil end
        if active == false then R.ClearCooldown(cd) return end
        local ok, duration = pcall(C_Spell.GetSpellCooldownDuration, spell)
        if ok and duration then cd:SetCooldownFromDurationObject(duration) else R.ClearCooldown(cd) end
        return
    end
    local start, duration = SpellCooldown(spell)
    if Secret(start) or Secret(duration) then
        pcall(cd.SetCooldown, cd, start, duration)
    elseif start and duration and duration > 1.5 then
        cd:SetCooldown(start, duration)
    else
        cd:SetCooldown(0, 0)
    end
end
R.PET_TOKENS = {["/petattack"] = "PET_ACTION_ATTACK", ["/petfollow"] = "PET_ACTION_FOLLOW",
    ["/petstay"] = "PET_ACTION_WAIT", ["/petaggressive"] = "PET_MODE_AGGRESSIVE", ["/petdefensive"] = "PET_MODE_DEFENSIVE",
    ["/petpassive"] = "PET_MODE_PASSIVE", ["/petassist"] = "PET_MODE_ASSIST"}
function R.ActiveSet()
    local names, ids = {}, {}
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        pcall(function()
            for i = 1, 60 do
                local data = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
                if not data then break end
                local name, id = data.name, data.spellId
                if not Secret(name) and name then names[name] = true end
                if not Secret(id) and id then ids[id] = true end
            end
        end)
    elseif UnitBuff then
        pcall(function()
            for i = 1, 40 do
                local name, _, _, _, _, _, _, _, _, id = UnitBuff("player", i)
                if not name then break end
                names[name] = true
                if id then ids[id] = true end
            end
        end)
    end
    if GetNumShapeshiftForms and GetShapeshiftFormInfo then
        pcall(function()
            for i = 1, GetNumShapeshiftForms() or 0 do
                local _, active, _, id = GetShapeshiftFormInfo(i)
                if not Secret(active) and active and id and not Secret(id) then
                    ids[id] = true
                    local name = SpellName(id)
                    if name then names[name] = true end
                end
            end
        end)
    end
    return names, ids
end
-- La barre du familier du jeu, case par case : nom (dans la langue du jeu), icône, jeton d'ordre,
-- en cours, automatique, sort.
R.PET_ICONS = {PET_ACTION_ATTACK = "Ability_GhoulFrenzy", PET_ACTION_FOLLOW = "Ability_Tracking",
    PET_ACTION_WAIT = "Spell_Nature_TimeStop", PET_ACTION_MOVE_TO = "Ability_Hunter_BeastCall",
    PET_MODE_ASSIST = "Ability_Hunter_BeastSoothe", PET_MODE_DEFENSIVE = "Ability_Defend",
    PET_MODE_DEFENSIVEASSIST = "Ability_Defend", PET_MODE_PASSIVE = "Ability_Seal", PET_MODE_AGGRESSIVE = "Ability_Racial_BloodRage"}
function R.PetBookIcons()
    local map = {}
    WalkBook(true, function(e)
        if e.name and e.icon and not Secret(e.name) then map[e.name] = e.icon end
    end)
    return map
end
function R.TokenIcon(token, texture, name, book)
    if name and book and book[name] then return book[name] end
    if type(texture) == "number" then return texture end
    if type(texture) == "string" and not Secret(texture) then
        local g = _G and _G[texture]
        if type(g) == "number" or (type(g) == "string" and g:find("[\\/]")) then return g end
        if texture:find("[\\/]") then return texture end
    end
    local fallback = R.PET_ICONS[token] or (tostring(token):find("ASSIST") and "Ability_Hunter_BeastSoothe")
    return fallback and I(fallback) or nil
end
function R.PetBar()
    local list, book = {}, nil
    if not GetPetActionInfo then return list end
    pcall(function()
        for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
            local name, icon, token, active, allowed, auto, id = PetInfo(slot)
            if name and not Secret(name) then
                local entry = {slot = slot, icon = icon, id = (not Secret(id)) and id or nil,
                    active = (not Secret(active) and active) and true or false,
                    allowed = (not Secret(allowed) and allowed) and true or false,
                    auto = (not Secret(auto) and auto) and true or false}
                if token then
                    entry.token = name
                    entry.name = (_G and _G[name]) or name
                    book = book or R.PetBookIcons()
                    entry.icon = R.TokenIcon(name, icon, entry.name, book)
                else
                    entry.name = name
                end
                list[slot] = entry
            end
        end
    end)
    return list
end
-- Un ordre (/petattack…), un sort ou une case du familier : sa case sur la barre du jeu, s'il y est.
function R.PetSlotFor(item, bar)
    bar = bar or R.PetBar()
    if item.a == "PETACTION" then return bar[item.slot or 0] end
    local token = item.a == "TEXT" and R.PET_TOKENS[string.lower(item.text or "")]
    local name = (item.a == "SPELL" and (SpellName(item.spell) or item.label)) or (token and item.label)
    if not token and not name then return end
    if token then
        for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
            local e = bar[slot]
            if e and e.token and (e.token == token or e.token == token .. "ASSIST") then return e end
        end
    end
    local W = addon.book
    local mine = item.a == "SPELL" and W and W.book and W.book[name] and not (W.petNames and W.petNames[name])
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local e = bar[slot]
        if e and name and e.name == name and (not e.token or not mine) then return e end
    end
end
function R.PlacePetCommand(token, label)
    if InCombatLockdown() or not PickupPetAction or not ClearCursor then return end
    if not (C_SpellBook and C_SpellBook.PickupSpellBookItem and C_SpellBook.HasPetSpells and C_SpellBook.GetSpellBookItemInfo) then return end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    if bank == nil then return end
    R.petTried = R.petTried or {}
    if R.petTried[token] then return end
    local want = (_G and _G[token]) or label
    local bookSlot
    WalkBook(true, function(e)
        if not bookSlot and e.bank == bank and e.name and not Secret(e.name) and (e.name == want or e.name == label) then
            bookSlot = e.index
        end
    end)
    if not bookSlot then return end
    local empty
    for s = 1, NUM_PET_ACTION_SLOTS or 10 do
        if not PetInfo(s) then empty = s break end
    end
    R.petTried[token] = true
    if not empty then
        Say("« " .. tostring(label) .. " » n'est pas sur la barre du familier du jeu et elle est pleine : libère une case pour qu'il marche.")
        return
    end
    ClearCursor()
    C_SpellBook.PickupSpellBookItem(bookSlot, bank)
    PickupPetAction(empty)
    ClearCursor()
    if PetInfo(empty) then
        Say("« " .. tostring(label) .. " » mis dans la case " .. empty .. " de la barre du familier du jeu, pour qu'il marche.")
        return empty
    end
end
function R.PetState()
    local bar = R.PetBar()
    R.petBar = bar
    local tokens, spells = {}, {}
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local e = bar[slot]
        if e then
            if e.token then tokens[e.token] = e.active else spells[e.name] = {active = e.active, auto = e.auto} end
        end
    end
    return tokens, spells
end
function R.IsActive(name, id)
    if (name and R.actNames and R.actNames[name]) or (id and R.actIds and R.actIds[id]) then return true end
    local W = addon.book
    local best = W and W.Best and name and W.Best(name)
    local keys = {}
    if name then keys[#keys + 1] = name end
    if id then keys[#keys + 1] = id end
    if best and best ~= id then keys[#keys + 1] = best end
    local checks = {(C_Spell and C_Spell.IsCurrentSpell) or IsCurrentSpell or false,
        (C_Spell and C_Spell.IsAutoRepeatSpell) or IsAutoRepeatSpell or false}
    for _, f in ipairs(checks) do
        if f then
            for _, k in ipairs(keys) do
                local ok, on = pcall(f, k)
                if ok and not Secret(on) and on then return true end
            end
        end
    end
    return name ~= nil and SpellActive(name)
end
function R.Lit(b, on)
    on = on and true or false
    -- Le halo jaune autour n'est plus montré : seulement la surbrillance sur l'icône.
    if b.lit then b.glow:SetAlpha(0) end
    b.glow:SetShown(on)
    if b.lit then
        b.lit:SetShown(on)
        b.shine:SetShown(on)
    end
end
function R.Tint(b)
    if b.outOfRange then
        b.icon:SetVertexColor(1, .25, .25)
    else
        local d = b.dim or 1
        b.icon:SetVertexColor(d, d, d)
    end
end
function R.UpdateButton(b)
    -- La barre du familier en un bouton : le portrait du familier.
    if b.petGroup then
        R.Lit(b, false)
        if SetPortraitTexture and UnitExists and UnitExists("pet") then pcall(SetPortraitTexture, b.icon, "pet") end
        return
    end
    if b.petSlot then
        local e = R.petBar and R.petBar[b.petSlot]
        R.Lit(b, e and (e.active or e.auto))
        if e and e.id then R.ShowCooldown(b.cooldown, e.id) else R.ClearCooldown(b.cooldown) end
        local usable = true
        if GetPetActionSlotUsable then
            local ok, yes = pcall(GetPetActionSlotUsable, b.petSlot)
            if ok and not Secret(yes) then usable = yes and true or false end
        end
        b.dim = usable and 1 or .4
        R.Tint(b)
        b.hadSpell = true
        return
    end
    if b.flySpells then
        local active
        for _, s in ipairs(b.flySpells) do
            if s.name and R.IsActive(s.name, s.id) then active = s break end
        end
        R.Lit(b, active ~= nil)
        local icon = active and active.icon or b.flyIcon
        if icon then b.icon:SetTexture(icon) end
        b.hadSpell = true
        return
    end
    if b.itemID then
        local count = 0
        local counter = (C_Item and C_Item.GetItemCount) or GetItemCount
        if counter then
            local ok, n = pcall(counter, b.itemID)
            if ok and type(n) == "number" and not Secret(n) then count = n end
        end
        if not b.countText then
            b.countText = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            b.countText:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT", -3, 3)
        end
        b.countText:SetText(count > 1 and tostring(count) or "")
        b.countText:Show()
        local cooldown = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
        local start, duration
        if cooldown then
            local ok, s, d = pcall(cooldown, b.itemID)
            if ok then start, duration = s, d end
        end
        if Secret(start) or Secret(duration) then
            pcall(b.cooldown.SetCooldown, b.cooldown, start, duration)
        elseif start and duration and duration > 1.5 then
            b.cooldown:SetCooldown(start, duration)
        else
            b.cooldown:SetCooldown(0, 0)
        end
        local usable = true
        local check = (C_Item and C_Item.IsUsableItem) or IsUsableItem
        if check then
            local ok, yes = pcall(check, b.itemID)
            if ok and not Secret(yes) then usable = yes and true or false end
        end
        b.dim = (count > 0 and usable) and 1 or .4
        R.Tint(b)
        R.Lit(b, false)
        b.hadSpell = true
        return
    end
    if b.countText then b.countText:Hide() end
    if b.spell then
        R.ShowCooldown(b.cooldown, b.spell)
        local pet = R.petSpells and R.petSpells[b.spell]
        R.Lit(b, R.IsActive(b.spell, b.spellID) or (pet and (pet.active or pet.auto)))
        local W = addon.book
        b.dim = ((W and W.petNames and W.petNames[b.spell]) or SpellUsable(b.spell)) and 1 or .4
        R.Tint(b)
        b.hadSpell = true
        return
    end
    -- Ordres du familier (attaque, suivre, rester, agressif / défensif / passif) : allumés comme sur sa barre.
    local token = b.item and b.item.a == "TEXT" and R.PET_TOKENS[string.lower(b.item.text or "")]
    if token then
        R.Lit(b, R.petTokens and (R.petTokens[token] or R.petTokens[token .. "ASSIST"]))
        return
    end
    if b.hadSpell then
        b.hadSpell = nil
        R.ClearCooldown(b.cooldown)
        b.dim, b.outOfRange = 1, nil
        b.icon:SetVertexColor(1, 1, 1)
    end
    R.Lit(b, false)
end
function R.UpdateSpells()
    if not R.ring then return end
    R.actNames, R.actIds = R.ActiveSet()
    R.petTokens, R.petSpells = R.PetState()
    for i = 1, R.used or 0 do
        local b = R.pool[i]
        if b then pcall(R.UpdateButton, b) end
    end
    for _, pop in ipairs(R.flyPool or {}) do
        for _, btn in ipairs(pop.buttons) do
            if btn.spell or btn.petSlot or btn.hadSpell then pcall(R.UpdateButton, btn) end
        end
    end
end
-- Hors de portée : l'icône passe au rouge (vérifié 5 fois par seconde, seulement quand l'arc est là).
function R.UpdateRange()
    if not R.ring or not R.ring:IsShown() then return end
    local function check(b)
        local out = false
        if b.spell and not b.petSlot and b:IsShown() then out = SpellRange(b.spell) == false end
        if out ~= (b.outOfRange or false) then
            b.outOfRange = out
            R.Tint(b)
        end
    end
    for i = 1, R.used or 0 do
        local b = R.pool[i]
        if b then pcall(check, b) end
    end
    for _, pop in ipairs(R.flyPool or {}) do
        if pop:IsShown() then
            for _, btn in ipairs(pop.buttons) do pcall(check, btn) end
        end
    end
end

function R.Apply()
    if InCombatLockdown() then R.pending = true else R.Layout() end
    R.RefreshEditor()
end

if R.opts.fixed then
    R.ranger = CreateFrame("Frame")
    R.ranger:SetScript("OnUpdate", function(self, elapsed)
        self.tipWait = (self.tipWait or 0) - (elapsed or 0)
        if self.tipWait <= 0 then
            self.tipWait = .1
            pcall(R.WatchTooltip)
        end
        self.wait = (self.wait or 0) - (elapsed or 0)
        if self.wait > 0 then return end
        self.wait = .2
        pcall(R.UpdateRange)
    end)
end
R.events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "CVAR_UPDATE"}) do
    R.events:RegisterEvent(event)
end
-- Seul le rond de sorts suit les recharges et les auras (du joueur seulement).
if R.opts.fixed then
    for _, event in ipairs({"SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE", "ACTIONBAR_UPDATE_STATE",
        "PLAYER_ENTERING_WORLD", "LEARNED_SPELL_IN_TAB", "LEARNED_SPELL_IN_SKILL_LINE", "SPELLS_CHANGED",
        "UNIT_PET", "PET_BAR_UPDATE", "PET_UI_UPDATE", "PET_BAR_UPDATE_COOLDOWN", "START_AUTOREPEAT_SPELL",
        "STOP_AUTOREPEAT_SPELL", "UPDATE_SHAPESHIFT_FORM", "PLAYER_TARGET_CHANGED", "BAG_UPDATE", "BAG_UPDATE_COOLDOWN"}) do
        pcall(R.events.RegisterEvent, R.events, event)
    end
    if R.events.RegisterUnitEvent then R.events:RegisterUnitEvent("UNIT_AURA", "player") else R.events:RegisterEvent("UNIT_AURA") end
end
R.SPELL_EVENTS = {SPELL_UPDATE_COOLDOWN = true, SPELL_UPDATE_USABLE = true, UNIT_AURA = true,
    ACTIONBAR_UPDATE_STATE = true, PLAYER_ENTERING_WORLD = true, LEARNED_SPELL_IN_TAB = true,
    LEARNED_SPELL_IN_SKILL_LINE = true, SPELLS_CHANGED = true}
R.LEARN_EVENTS = {PLAYER_ENTERING_WORLD = true, LEARNED_SPELL_IN_TAB = true, LEARNED_SPELL_IN_SKILL_LINE = true,
    SPELLS_CHANGED = true, UNIT_PET = true, PET_BAR_UPDATE = true}
R.SPELL_EVENTS.UNIT_PET, R.SPELL_EVENTS.PET_BAR_UPDATE = true, true
for _, event in ipairs({"PET_UI_UPDATE", "PET_BAR_UPDATE_COOLDOWN", "START_AUTOREPEAT_SPELL", "STOP_AUTOREPEAT_SPELL",
    "UPDATE_SHAPESHIFT_FORM", "PLAYER_TARGET_CHANGED", "BAG_UPDATE", "BAG_UPDATE_COOLDOWN"}) do R.SPELL_EVENTS[event] = true end
R.events:SetScript("OnEvent", function(_, event, name)
    if R.SPELL_EVENTS[event] then
        if R.LEARN_EVENTS[event] and R.opts.hideUnknown and R.main and R.cfg and (event ~= "UNIT_PET" or name == "player") then
            R.ScanKnown()
            local sig = R.KnownSig()
            if sig ~= R.knownSig then
                R.knownSig = sig
                R.Apply()
            end
        end
        if event ~= "UNIT_AURA" or name == "player" then pcall(R.UpdateSpells) end
        return
    end
    if event == "PLAYER_LOGIN" then
        if StreamingTouchDB then StreamingTouchDB.petDump, StreamingTouchDB.petClicks, StreamingTouchDB.blocked = nil, nil, nil end
        R.Config()
        if InCombatLockdown() then R.pending = true return end
        R.Build()
        R.Layout()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if R.editor and R.editor:IsShown() then
            if R.editor.dock and addon.settings and addon.settings.panel then addon.settings.panel:Hide() end
            R.editor:Hide()
            Say("éditeur fermé : combat.")
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if R.pending then
            R.Build()
            R.Layout()
        end
    elseif event == "CVAR_UPDATE" then
        if R.main and not InCombatLockdown() and (name == "ActionButtonUseKeyDown" or name == "ACTION_BUTTON_USE_KEY_DOWN") then
            R.main:SetAttribute("keydown", GetCVarBool("ActionButtonUseKeyDown") and true or false)
        end
    elseif R.main and not InCombatLockdown() then
        R.Layout()
    end
end)

_G["SLASH_" .. R.opts.slash .. "1"] = R.opts.command
SlashCmdList[R.opts.slash] = function(arg)
    arg = (arg or ""):lower()
    if InCombatLockdown() then Say("pas pendant un combat.") return end
    local db = StreamingTouchDB
    if not db then return end
    if arg:find("reset") then
        db[R.opts.db] = nil
        R.Config()
        R.ed = {kind = "page", page = 1, mode = "props", cat = 1, actStart = 0, iconStart = 0}
        R.Apply()
        Say(R.opts.what .. " remis à zéro.")
    elseif arg:find("off") then
        db[R.opts.off] = true
        R.Layout()
        Say(R.opts.what .. " masqué. " .. R.opts.command .. " on pour le remettre.")
    elseif arg:find("on") then
        db[R.opts.off] = nil
        R.Build()
        R.Layout()
        Say(R.opts.what .. " affiché.")
    else
        R.OpenEditor()
    end
end

-- ===================================================================================
-- Éditeur : pages, boutons, action, icône, couleur, forme, nom, taille. Hors combat.
-- ===================================================================================
local function Text(parent, template, value)
    local f = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    f:SetText(value or "")
    return f
end
local function Push(parent, width, height, value, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    Capsule(b, height)
    local label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    b:SetFontString(label)
    b:SetText(value)
    b:SetScript("OnEnter", function(self) self:Look(false, true) end)
    b:SetScript("OnLeave", function(self) self:Look(false) end)
    b:SetScript("OnMouseDown", function(self) self:Look(false, true, true) end)
    b:SetScript("OnMouseUp", function(self) self:Look(false, self.IsMouseOver and self:IsMouseOver()) end)
    b:SetScript("OnClick", onClick)
    b:Look(false)
    return b
end
local function Tile(parent, size, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    R.Visual(b)
    b:SetScript("OnClick", onClick)
    return b
end
local function Input(parent, width, onEnter)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width, 22)
    box:SetAutoFocus(false)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        onEnter(self:GetText())
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end
local function Arm(button, label, action)
    if button.armed then
        button.armed = nil
        button:SetText(label)
        action()
        return
    end
    button.armed = true
    button:SetText("Confirmer ?")
    C_Timer.After(3, function()
        button.armed = nil
        button:SetText(label)
    end)
end

-- Calage sur le joystick CAM de l'app : deux touchers sur son cercle (bord gauche, bord du haut),
-- puis l'arc : où va le premier sort, où va le dernier (ou « Garder mon arc »).
function R.Calibrate(done)
    if InCombatLockdown() then Say("pas pendant un combat.") return end
    local f = R.calib
    if not f then
        f = CreateFrame("Button", nil, UIParent)
        R.calib = f
        f:SetAllPoints(UIParent)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:RegisterForClicks("LeftButtonUp")
        local shade = f:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        shade:SetColorTexture(.02, .06, .14, .45)
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        f.text:SetPoint("TOP", 0, -90)
        f.text:SetWidth(math.max(300, UIParent:GetWidth() * .6))
        f.dot = f:CreateTexture(nil, "OVERLAY")
        f.dot:SetTexture(CIRCLE)
        f.dot:SetVertexColor(1, .82, .32, 1)
        f.dot:SetSize(18, 18)
        f.dot:Hide()
        f.cancel = Push(f, 140, 30, "Annuler", function() f.taps = {} f:Hide() if f.done then f.done() end end)
        f.cancel:SetPoint("TOP", 0, -150)
        f.keep = Push(f, 180, 30, "Garder mon arc", function() R.CalibrateEnd(f) end)
        f.keep:SetPoint("TOP", 0, -188)
        f:SetScript("OnClick", function(self)
            local s = UIParent:GetEffectiveScale()
            local x, y = GetCursorPosition()
            x, y = x / s, y / s
            self.dot:ClearAllPoints()
            self.dot:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            self.dot:Show()
            self.taps[#self.taps + 1] = {x, y}
            local n = #self.taps
            if n == 1 then
                self.text:SetText("Bien. Maintenant, touche le bord du HAUT du joystick CAM (sur son cercle).")
            elseif n == 2 then
                self.text:SetText("Parfait. Touche où tu veux le PREMIER sort de l'arc (en général en bas, à gauche du joystick).")
                self.keep:Show()
            elseif n == 3 then
                self.text:SetText("Et maintenant, touche où tu veux le DERNIER sort (le bout de l'arc).")
            else
                R.CalibrateEnd(self)
            end
        end)
    end
    f.taps = {}
    f.done = done
    f.dot:Hide()
    f.keep:Hide()
    f.text:SetText("Calage sur le joystick CAM : touche le bord GAUCHE du joystick (sur son cercle).")
    f:Show()
end

function R.CalibrateEnd(f)
    local taps = f.taps or {}
    f.taps = {}
    f:Hide()
    if InCombatLockdown() or #taps < 2 then
        if f.done then f.done() end
        return
    end
    local cfg = R.Config()
    local lx, ly, cx, cy = taps[1][1], taps[1][2], taps[2][1], taps[2][2]
    cfg.pos = {x = cx, y = ly}
    cfg.stickR = math.max(20, ((cx - lx) + (cy - ly)) / 2)
    cfg.layout, cfg.open = nil, "fixed"
    if taps[4] then
        local function polar(t)
            local dx, dy = t[1] - cx, t[2] - ly
            return math.deg(math.atan2(dy, dx)) % 360, math.sqrt(dx * dx + dy * dy)
        end
        local a1, d1 = polar(taps[3])
        local a2, d2 = polar(taps[4])
        a1 = math.floor(a1 + .5)
        local turn = math.floor((a2 - a1 + 180) % 360 - 180 + .5)
        if math.abs(turn) < 20 then turn = R.ARC_TO - R.ARC_FROM end
        cfg.arcFrom, cfg.arcTo = a1, a1 + turn
        local ringScale = math.max(.5, math.min(2, cfg.scale or 1))
        cfg.gap = math.max(-40, math.min(160, math.floor((d1 + d2) / 2 - cfg.stickR - 35 * ringScale + .5)))
    end
    R.Apply()
    Say(taps[4] and "arc calé sur le joystick, du premier au dernier sort." or "arc calé sur le joystick.")
    if f.done then f.done() end
end

-- Déplacer tout l'arc (sorts et flèches) : on glisse le doigt n'importe où, l'arc suit.
function R.StartMove(done)
    if InCombatLockdown() then Say("pas pendant un combat.") return end
    local f = R.mover
    if not f then
        f = CreateFrame("Frame", nil, UIParent)
        R.mover = f
        f:SetAllPoints(UIParent)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:EnableMouse(true)
        local shade = f:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        shade:SetColorTexture(.02, .06, .14, .25)
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        f.text:SetPoint("TOP", 0, -90)
        f.text:SetWidth(math.max(300, UIParent:GetWidth() * .6))
        f.text:SetText("Glisse le doigt n'importe où (hors des joysticks de l'appli) : tout l'arc de sorts suit, flèches comprises. Puis touche « Terminé ».")
        f.ok = Push(f, 140, 30, "Terminé", function() R.EndMove(true) end)
        f.ok:SetPoint("TOP", -76, -150)
        f.cancel = Push(f, 140, 30, "Annuler", function() R.EndMove(false) end)
        f.cancel:SetPoint("TOP", 76, -150)
        f:SetScript("OnMouseDown", function(self)
            local s = UIParent:GetEffectiveScale()
            local x, y = GetCursorPosition()
            local pos = R.cfg.pos
            local gx, gy = R.StickGuess()
            self.grab = {x / s, y / s, pos and pos.x or gx, pos and pos.y or gy}
        end)
        f:SetScript("OnMouseUp", function(self)
            self.grab = nil
            if not InCombatLockdown() then R.Layout() end
        end)
        f:SetScript("OnUpdate", function(self)
            local g = self.grab
            if not g or InCombatLockdown() then return end
            local s = UIParent:GetEffectiveScale()
            local x, y = GetCursorPosition()
            local w, h = UIParent:GetWidth(), UIParent:GetHeight()
            R.cfg.pos = {x = math.max(0, math.min(w, g[3] + x / s - g[1])), y = math.max(0, math.min(h, g[4] + y / s - g[2]))}
            R.PlaceKey()
            R.PlaceRing()
        end)
    end
    local pos = R.Config().pos
    f.before = pos and {x = pos.x, y = pos.y} or false
    f.grab = nil
    f.done = done
    f:Show()
end

function R.EndMove(keep)
    local f = R.mover
    if not f then return end
    f.grab = nil
    f:Hide()
    if not keep then R.cfg.pos = f.before or nil end
    if not InCombatLockdown() then R.Layout() end
    if keep then Say("arc de sorts déplacé.") end
    if f.done then f.done() end
end

-- Ce qu'on modifie : le bouton Menu, une page ou un bouton de page.
function R.Target()
    local cfg, ed = R.cfg, R.ed
    if ed.kind == "key" then return "key", cfg end
    local page = cfg.pages[ed.page]
    if ed.kind == "item" and ed.item and page.items[ed.item] then return "item", page.items[ed.item], page end
    return "page", page
end

function R.Get(field)
    local kind, t = R.Target()
    if kind == "key" then
        if field == "icon" then return t.keyIcon or R.opts.keyIcon or R.KEYICON end
        if field == "color" then return t.keyColor or "or" end
        if field == "shape" then return t.keyShape end
    elseif kind == "page" then
        if field == "icon" then return t.icon end
        if field == "color" then return t.color end
        if field == "label" then return t.name end
    else
        local label, icon = R.Resolve(t)
        if field == "icon" then return icon end
        if field == "color" then return t.color end
        if field == "shape" then return t.shape end
        if field == "label" then return label end
    end
end

function R.Set(field, value)
    local kind, t = R.Target()
    if kind == "key" then
        if field == "icon" then t.keyIcon = value elseif field == "color" then t.keyColor = value elseif field == "shape" then t.keyShape = value end
    elseif kind == "page" then
        if field == "icon" then t.icon = value elseif field == "color" then t.color = value elseif field == "label" and value then t.name = value end
    else
        t[field] = value
    end
    R.Apply()
end

function R.Suggestions(kind, t)
    local list, seen = {}, {}
    local function add(v)
        v = I(v)
        if v and not seen[v] and #list < 6 then
            seen[v] = true
            list[#list + 1] = v
        end
    end
    if kind == "item" then
        add(t.icon)
        if t.a == "MACRO" then add(select(2, GetMacroInfo(t.macro or ""))) end
        if t.a == "SPELL" then add(SpellIcon(t.spell)) end
        local def = R.ACT[t.a]
        if def then for _, n in ipairs(def.i) do add(n) end end
    elseif kind == "page" then
        add(t.icon)
        for _, cat in ipairs(R.CATS) do add(cat.icon) end
    else
        add(t.keyIcon)
        for _, n in ipairs(R.KEYICONS) do add(n) end
    end
    for _, n in ipairs(R.GENERIC) do add(n) end
    return list
end

function R.AllIcons()
    if R.icons then return R.icons end
    local list = {}
    pcall(GetMacroIcons, list)
    pcall(GetMacroItemIcons, list)
    if #list == 0 then
        for _, cat in ipairs(R.CATS) do
            for _, def in ipairs(cat.list) do
                for _, n in ipairs(def.i) do list[#list + 1] = I(n) end
            end
        end
    end
    R.icons = list
    return list
end

function R.ActionChoices(cat)
    if R.opts.choices then return R.opts.choices(cat) or {} end
    local list = {}
    if R.CATS[cat] then
        for _, def in ipairs(R.CATS[cat].list) do list[#list + 1] = {a = def.k, label = def.l, icon = I(def.i[1])} end
    elseif cat == #R.CATS + 1 then
        local global, char = GetNumMacros()
        local function add(i)
            local name, icon = GetMacroInfo(i)
            if name then list[#list + 1] = {a = "MACRO", macro = name, label = name, icon = icon} end
        end
        for i = 1, global or 0 do add(i) end
        local first = (MAX_ACCOUNT_MACROS or 120) + 1
        for i = first, first + (char or 0) - 1 do add(i) end
    end
    return list
end

-- Ajoute ou remplace le bouton choisi ; garde sa couleur et sa forme quand on change l'action.
function R.Commit(item)
    local ed = R.ed
    local page = R.cfg.pages[ed.page]
    -- Choix de l'action du maintien pour le bouton en cours.
    if ed.holdPick then
        ed.holdPick, ed.mode = nil, "props"
        local target = page.items[ed.item or 0]
        if target and (item.a == "SPELL" or item.a == "MACRO" or item.a == "TEXT" or item.a == "ITEM") then
            target.hold = {a = item.a, spell = item.spell, macro = item.macro, text = item.text, name = item.name,
                label = item.label, icon = item.icon, item = item.item}
        elseif target then
            Say("au maintien, on peut mettre un sort, une macro ou un objet.")
        end
        R.Apply()
        return
    end
    if ed.adding then
        if #page.items >= R.MAXITEMS then return end
        page.items[#page.items + 1] = item
        ed.item = #page.items
    else
        local old = page.items[ed.item or 0]
        if old then item.color, item.shape = old.color, old.shape end
        page.items[ed.item or (#page.items + 1)] = item
        ed.item = ed.item or #page.items
    end
    ed.adding = nil
    ed.kind = "item"
    ed.mode = "props"
    R.Apply()
end

-- Un sort glissé depuis le grimoire (ou la barre du familier, ou une macro) rejoint la page, là où
-- on l'a lâché (sinon au bout). Un groupe du grimoire (les aspects…) donne tous ses sorts appris.
function R.Drop(index, at)
    if InCombatLockdown() or not R.cfg then return end
    local list = CursorItems()
    if not list then
        if GetCursorInfo and GetCursorInfo() then Say("on ne peut mettre ici que des sorts, des macros et des objets.") end
        return
    end
    if ClearCursor then ClearCursor() end
    local page = R.cfg.pages[index or 1]
    if not page then return end
    local function Key(item)
        if item.a == "SPELL" then return "S" .. tostring(SpellName(item.spell) or item.label or item.spell) end
        if item.a == "MACRO" then return "M" .. tostring(item.macro) end
        if item.a == "ITEM" then return "I" .. tostring(item.item) end
        if item.a == "TEXT" then return "T" .. tostring(item.text) end
        if item.a == "FLYOUT" then return "F" .. tostring(item.flyout) end
        if item.a == "PETBAR" then return "B" end
        if item.a == "GROUP" then return "G" .. tostring(item.uid) end
        if item.a == "PETACTION" then return "A" .. tostring(item.slot) end
        return tostring(item.a)
    end
    local have = {}
    for _, old in ipairs(page.items) do have[Key(old)] = true end
    local added, full = {}, false
    for _, item in ipairs(list) do
        if not have[Key(item)] then
            if #page.items >= R.MAXITEMS then full = true break end
            local pos = at and math.max(1, math.min(at, #page.items + 1)) or (#page.items + 1)
            table.insert(page.items, pos, item)
            if at then at = pos + 1 end
            have[Key(item)] = true
            added[#added + 1] = item.label or "?"
        end
    end
    if #added > 0 then
        R.Apply()
        if R.editor and R.editor:IsShown() then R.RefreshEditor() end
        Say("ajouté à « " .. (page.name or "?") .. " » : " .. table.concat(added, ", ") .. ".")
    end
    if full then
        Say("la page « " .. (page.name or "?") .. " » est pleine (" .. R.MAXITEMS .. " boutons) : enlève un sort ou ajoute une page.")
    elseif #added == 0 then
        Say("déjà dans « " .. (page.name or "?") .. " ».")
    end
end
-- Lâché sur un sort de l'arc : le nouveau prend sa place (l'ancien se pousse).
function R.DropOn(b)
    local page = b.page and R.cfg and R.cfg.pages[b.page]
    if not page then return R.Drop(R.ring and R.ring:GetAttribute("current") or 1) end
    local at
    for i, item in ipairs(page.items) do if item == b.item then at = i break end end
    R.Drop(b.page, at)
end

function R.MoveItem(step)
    local ed = R.ed
    local items = R.cfg.pages[ed.page].items
    local i = ed.kind == "item" and ed.item
    local j = i and i + step
    if not i or j < 1 or j > #items then return end
    items[i], items[j] = items[j], items[i]
    ed.item = j
    R.Apply()
end

function R.DeleteItem()
    local ed = R.ed
    local items = R.cfg.pages[ed.page].items
    if ed.kind ~= "item" or not ed.item then return end
    table.remove(items, ed.item)
    if #items == 0 then
        ed.item = nil
        ed.kind = "page"
    else
        ed.item = math.min(ed.item, #items)
    end
    ed.mode = "props"
    R.Apply()
end

function R.AddPage()
    local pages = R.cfg.pages
    if #pages >= R.MAXPAGES then return end
    pages[#pages + 1] = {name = "Page " .. (#pages + 1), icon = I("INV_Misc_Gem_Variety_01"), color = "bleu", items = {}}
    R.ed.page, R.ed.kind, R.ed.item, R.ed.mode = #pages, "page", nil, "props"
    R.Apply()
end

function R.MovePage(step)
    local pages, ed = R.cfg.pages, R.ed
    local i, j = ed.page, ed.page + step
    if j < 1 or j > #pages then return end
    pages[i], pages[j] = pages[j], pages[i]
    ed.page = j
    if R.ring and not InCombatLockdown() then R.ring:SetAttribute("current", j) end
    R.Apply()
end

function R.DeletePage()
    local pages, ed = R.cfg.pages, R.ed
    if #pages <= 1 then Say("il faut garder au moins une page.") return end
    table.remove(pages, ed.page)
    ed.page = math.max(1, ed.page - 1)
    ed.kind, ed.item, ed.mode = "page", nil, "props"
    R.Apply()
end

function R.BuildEditor()
    local e = CreateFrame("Frame", "StreamingTouchRingEditor" .. R.opts.suffix, UIParent, "BackdropTemplate")
    R.editor = e
    e:SetSize(660, 440)
    e:SetPoint("CENTER")
    e:SetFrameStrata("FULLSCREEN_DIALOG")
    e:SetToplevel(true)
    e:EnableMouse(true)
    e:SetMovable(true)
    e:SetClampedToScreen(true)
    e:RegisterForDrag("LeftButton")
    e:SetScript("OnDragStart", e.StartMoving)
    e:SetScript("OnDragStop", e.StopMovingOrSizing)
    e:SetBackdrop({bgFile = WHITE, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3}})
    e:SetBackdropColor(.03, .05, .09, .97)
    e:SetBackdropBorderColor(1, .82, .32, 1)
    tinsert(UISpecialFrames, "StreamingTouchRingEditor" .. R.opts.suffix)
    e:SetScript("OnHide", function() if R.cfg and R.cfg.open == "fixed" and not InCombatLockdown() then R.Layout() end end)
    local title = Text(e, "GameFontNormalLarge", R.opts.title)
    title:SetPoint("TOPLEFT", 14, -12)
    local closeButton = CreateFrame("Button", nil, e, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -2, -2)
    e.titleText, e.closeButton = title, closeButton
    -- CH : apparence et taille des boutons du jeu (Boutons.lua).
    local skin = Push(e, 140, 22, "Boutons du jeu >", function()
        if addon.skin then
            e:Hide()
            addon.skin.Open()
        end
    end)
    skin:SetPoint("TOPRIGHT", -34, -10)
    e.skinButton = skin

    -- Ligne des pages : le bouton Menu, puis une icône par page, puis +.
    e.keyTab = Tile(e, 34, function()
        R.ed.kind, R.ed.mode = "key", "props"
        R.RefreshEditor()
    end)
    e.keyTab:SetPoint("TOPLEFT", 16, -42)
    local sep = e:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(1, .82, .32, .5)
    sep:SetSize(2, 30)
    sep:SetPoint("LEFT", e.keyTab, "RIGHT", 8, 0)
    e.tabs = {}
    for i = 1, R.MAXPAGES do
        local t = Tile(e, 34, function()
            R.ed.page, R.ed.kind, R.ed.item, R.ed.mode = i, "page", nil, "props"
            R.RefreshEditor()
        end)
        t:SetPoint("TOPLEFT", 74 + (i - 1) * 42, -42)
        e.tabs[i] = t
    end
    e.addPage = Push(e, 90, 26, "+ Page", R.AddPage)

    e.gridTitle = Text(e, "GameFontNormal", "")
    e.gridTitle:SetPoint("TOPLEFT", 16, -88)
    e.gridTitle:SetWidth(236)
    e.gridTitle:SetJustifyH("LEFT")
    e.slots = {}
    for i = 1, R.MAXITEMS do
        local t = Tile(e, 44, function()
            if GetCursorInfo and GetCursorInfo() then R.Drop(R.ed.page, i) return end
            local page = R.cfg.pages[R.ed.page]
            if i <= #page.items then
                R.ed.kind, R.ed.item, R.ed.mode, R.ed.adding = "item", i, "props", nil
            else
                R.ed.adding, R.ed.holdPick, R.ed.mode, R.ed.actStart = true, nil, "action", 0
            end
            R.RefreshEditor()
        end)
        t:SetPoint("TOPLEFT", 22 + ((i - 1) % 4) * 58, -108 - math.floor((i - 1) / 4) * 62)
        -- Glisser un sort du grimoire sur une case : il se met là ; sur « Ajouter » : au bout.
        t:SetScript("OnReceiveDrag", function() R.Drop(R.ed.page, i) end)
        e.slots[i] = t
    end
    e:SetScript("OnReceiveDrag", function() R.Drop(R.ed.page) end)
    e.left = Push(e, 34, 24, "<", function() R.MoveItem(-1) end)
    e.left:SetPoint("TOPLEFT", 16, -306)
    e.right = Push(e, 34, 24, ">", function() R.MoveItem(1) end)
    e.right:SetPoint("LEFT", e.left, "RIGHT", 4, 0)
    e.delete = Push(e, 100, 24, "Supprimer", function(self) Arm(self, "Supprimer", R.DeleteItem) end)
    e.delete:SetPoint("LEFT", e.right, "RIGHT", 8, 0)
    local divider = e:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, .82, .32, .35)
    divider:SetSize(1, 250)
    divider:SetPoint("TOPLEFT", 262, -86)

    e.panel = CreateFrame("Frame", nil, e)
    e.panel:SetPoint("TOPLEFT", 274, -86)
    e.panel:SetSize(372, 250)
    e.modes = {}

    -- Propriétés du bouton, de la page ou du bouton Menu.
    local p = CreateFrame("Frame", nil, e.panel)
    p:SetAllPoints()
    e.modes.props = p
    p.preview = Tile(p, 48)
    p.preview:SetPoint("TOPLEFT", 0, 0)
    p.preview:EnableMouse(false)
    p.title = Text(p, "GameFontNormalLarge")
    p.title:SetPoint("TOPLEFT", 58, -2)
    p.title:SetWidth(170)
    p.title:SetJustifyH("LEFT")
    p.title:SetWordWrap(false)
    p.sub = Text(p, "GameFontDisableSmall")
    p.sub:SetPoint("TOPLEFT", 58, -24)
    p.sub:SetWidth(310)
    p.sub:SetJustifyH("LEFT")
    p.sub:SetWordWrap(false)
    p.change = Push(p, 134, 24, "Changer l'action", function()
        R.ed.adding, R.ed.holdPick, R.ed.mode, R.ed.actStart = nil, nil, "action", 0
        R.RefreshEditor()
    end)
    p.change:SetPoint("TOPRIGHT", 0, 0)
    local function Row(text, y)
        local label = Text(p, "GameFontNormalSmall", text)
        label:SetPoint("TOPLEFT", 0, y)
        return label
    end
    p.iconLabel = Row("Icône", -70)
    p.sugg = {}
    for i = 1, 6 do
        local t = Tile(p, 34, function(self) R.Set("icon", self.value) end)
        t:SetPoint("TOPLEFT", 52 + (i - 1) * 40, -58)
        p.sugg[i] = t
    end
    p.more = Push(p, 74, 24, "Toutes…", function()
        R.ed.mode, R.ed.iconStart = "icon", 0
        R.RefreshEditor()
    end)
    p.more:SetPoint("TOPLEFT", 296, -63)
    p.colorLabel = Row("Couleur", -112)
    p.swatches = {}
    for i, c in ipairs(R.COLORS) do
        local s = CreateFrame("Button", nil, p)
        s:SetSize(22, 22)
        s:SetPoint("TOPLEFT", 52 + (i - 1) * 28, -106)
        s.sel = s:CreateTexture(nil, "BACKGROUND")
        s.sel:SetColorTexture(1, 1, 1, 1)
        s.sel:SetPoint("TOPLEFT", -3, 3)
        s.sel:SetPoint("BOTTOMRIGHT", 3, -3)
        s.tex = s:CreateTexture(nil, "ARTWORK")
        s.tex:SetAllPoints()
        if c[3] then s.tex:SetColorTexture(c[3], c[4], c[5], 1) else s.tex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up") end
        s.key = c[1]
        s:SetScript("OnClick", function() R.Set("color", c[1]) end)
        p.swatches[i] = s
    end
    p.shapeLabel = Row("Forme", -148)
    p.round = Push(p, 80, 24, "Rond", function() R.Set("shape", "round") end)
    p.round:SetPoint("TOPLEFT", 52, -142)
    p.square = Push(p, 80, 24, "Carré", function() R.Set("shape", "square") end)
    p.square:SetPoint("LEFT", p.round, "RIGHT", 6, 0)
    p.auto = Push(p, 120, 24, "Comme le menu", function() R.Set("shape", nil) end)
    p.auto:SetPoint("LEFT", p.square, "RIGHT", 6, 0)
    -- CH : rôle de la page (rond de sorts) : couche 2, page en combat, page hors combat.
    p.roles = {}
    local prev
    for i, d in ipairs({{"layer", "Couche 2", 116}, {"combat", "En combat", 110}, {"peace", "Hors combat", 134}}) do
        local key = d[1]
        local b = Push(p, d[3], 24, d[2], function() R.TogglePageRole(key) end)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 6, 0) else b:SetPoint("TOPLEFT", 0, -142) end
        b.key, b.text0 = key, d[2]
        p.roles[i] = b
        prev = b
    end
    p.forme = Push(p, 372, 24, "Posture / forme : aucune", function() R.CycleForm() end)
    p.forme:SetPoint("TOPLEFT", 0, -252)
    p.nameLabel = Row("Nom", -186)
    p.name = Input(p, 160, function(text) R.Set("label", text ~= "" and text or nil) end)
    p.name:SetPoint("TOPLEFT", 58, -180)
    p.nameOk = Push(p, 44, 24, "OK", function()
        p.name:ClearFocus()
        local text = p.name:GetText()
        R.Set("label", text ~= "" and text or nil)
    end)
    p.nameOk:SetPoint("LEFT", p.name, "RIGHT", 6, 0)
    p.nameReset = Push(p, 96, 24, "Par défaut", function()
        p.name:ClearFocus()
        R.Set("label", nil)
    end)
    p.nameReset:SetPoint("LEFT", p.nameOk, "RIGHT", 6, 0)
    p.pageRow = CreateFrame("Frame", nil, p)
    p.pageRow:SetPoint("TOPLEFT", 0, -218)
    p.pageRow:SetSize(372, 26)
    local before = Push(p.pageRow, 110, 24, "< Avancer", function() R.MovePage(-1) end)
    before:SetPoint("LEFT", 0, 0)
    local after = Push(p.pageRow, 110, 24, "Reculer >", function() R.MovePage(1) end)
    after:SetPoint("LEFT", before, "RIGHT", 6, 0)
    local drop = Push(p.pageRow, 140, 24, "Supprimer la page", function(self) Arm(self, "Supprimer la page", R.DeletePage) end)
    drop:SetPoint("LEFT", after, "RIGHT", 6, 0)
    -- Au maintien : un second sort ou une macro sur le même bouton (appui long dans l'appli).
    p.holdRow = CreateFrame("Frame", nil, p)
    p.holdRow:SetPoint("TOPLEFT", 0, -218)
    p.holdRow:SetSize(372, 26)
    p.holdLabel = Text(p.holdRow, "GameFontNormalSmall", "Maintien")
    p.holdLabel:SetPoint("LEFT", 0, 0)
    p.holdPick = Push(p.holdRow, 200, 24, "Choisir…", function()
        R.ed.holdPick, R.ed.adding, R.ed.mode, R.ed.actStart = true, nil, "action", 0
        R.RefreshEditor()
    end)
    p.holdPick:SetPoint("LEFT", 58, 0)
    p.holdClear = Push(p.holdRow, 90, 24, "Aucun", function()
        local kind, t = R.Target()
        if kind == "item" then
            t.hold = nil
            R.Apply()
        end
    end)
    p.holdClear:SetPoint("LEFT", p.holdPick, "RIGHT", 6, 0)
    -- Aide sous la fiche : qui a quel rôle (page), ou ce que fait le maintien (sort).
    p.hint = Text(p, "GameFontHighlightSmall")
    p.hint:SetPoint("TOPLEFT", 0, -252)
    p.hint:SetWidth(372)
    p.hint:SetJustifyH("LEFT")

    -- Choix de l'action : catégories du jeu, tes macros, ou une macro écrite à la main.
    e.catBar = CreateFrame("Frame", nil, e.panel)
    e.catBar:SetPoint("TOPLEFT")
    e.catBar:SetSize(372, 44)
    e.cats = {}
    local catNames = R.opts.categoryNames and R.opts.categoryNames()
    if not catNames then
        catNames = {}
        for _, cat in ipairs(R.CATS) do catNames[#catNames + 1] = cat.name end
        catNames[#catNames + 1] = "Mes macros"
    end
    catNames[#catNames + 1] = "Macro libre"
    for i, name in ipairs(catNames) do
        local b = Push(e.catBar, 90, 20, name, function()
            R.ed.cat, R.ed.actStart = i, 0
            R.ed.mode = i == #catNames and "text" or "action"
            R.RefreshEditor()
        end)
        b:SetPoint("TOPLEFT", ((i - 1) % 4) * 93, -math.floor((i - 1) / 4) * 22)
        e.cats[i] = b
    end
    local a = CreateFrame("Frame", nil, e.panel)
    a:SetAllPoints()
    e.modes.action = a
    a.tiles = {}
    for i = 1, 18 do
        local t = Tile(a, 36, function(self) local c = self.choice
            local text = c.a == "TEXT"
            local group = c.a == "FLYOUT" or c.a == "PETBAR" or c.a == "ITEM"
            R.Commit({a = c.a, macro = c.macro, spell = c.spell, name = c.label, text = c.text, flyout = c.flyout, slot = c.slot,
                uid = c.uid, item = c.item, label = (text or group) and c.label or nil,
                icon = (text or c.a == "FLYOUT" or c.a == "ITEM") and c.icon or nil}) end)
        t:SetPoint("TOPLEFT", 14 + ((i - 1) % 6) * 62, -54 - math.floor((i - 1) / 6) * 56)
        a.tiles[i] = t
    end
    a.prev = Push(a, 30, 22, "<", function()
        R.ed.actStart = math.max(0, R.ed.actStart - 18)
        R.RefreshEditor()
    end)
    a.prev:SetPoint("TOPLEFT", 0, -224)
    a.info = Text(a, "GameFontHighlightSmall")
    a.info:SetPoint("LEFT", a.prev, "RIGHT", 8, 0)
    a.next = Push(a, 30, 22, ">", function()
        R.ed.actStart = R.ed.actStart + 18
        R.RefreshEditor()
    end)
    a.next:SetPoint("LEFT", a.prev, "RIGHT", 70, 0)
    local function Cancel(parent)
        local b = Push(parent, 90, 22, "Annuler", function()
            R.ed.adding, R.ed.holdPick, R.ed.mode = nil, nil, "props"
            R.RefreshEditor()
        end)
        b:SetPoint("TOPRIGHT", 0, -224)
        return b
    end
    Cancel(a)

    local x = CreateFrame("Frame", nil, e.panel)
    x:SetAllPoints()
    e.modes.text = x
    x.help = Text(x, "GameFontHighlightSmall", "Une commande par ligne, par exemple : /cast Tir des arcanes")
    x.help:SetPoint("TOPLEFT", 0, -50)
    x.box = CreateFrame("EditBox", nil, x, "BackdropTemplate")
    x.box:SetMultiLine(true)
    x.box:SetAutoFocus(false)
    x.box:SetFontObject(ChatFontNormal)
    x.box:SetMaxLetters(255)
    x.box:SetSize(372, 96)
    x.box:SetPoint("TOPLEFT", 0, -68)
    x.box:SetTextInsets(6, 6, 6, 6)
    x.box:SetBackdrop({bgFile = WHITE, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2}})
    x.box:SetBackdropColor(0, 0, 0, .6)
    x.box:SetBackdropBorderColor(1, .82, .32, .6)
    x.box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    x.nameLabel = Text(x, "GameFontNormalSmall", "Nom")
    x.nameLabel:SetPoint("TOPLEFT", 0, -180)
    x.name = Input(x, 150, function() end)
    x.name:SetPoint("TOPLEFT", 40, -174)
    x.ok = Push(x, 90, 24, "Valider", function()
        local text = x.box:GetText() or ""
        if text:gsub("%s", "") == "" then Say("écris d'abord ta macro.") return end
        local name = x.name:GetText() or ""
        x.box:ClearFocus()
        x.name:ClearFocus()
        R.Commit({a = "TEXT", text = text, label = name ~= "" and name or nil})
    end)
    x.ok:SetPoint("TOPRIGHT", 0, -174)
    Cancel(x)

    -- Toutes les icônes du jeu, par pages.
    local g = CreateFrame("Frame", nil, e.panel)
    g:SetAllPoints()
    e.modes.icon = g
    g.tiles = {}
    for i = 1, 45 do
        local t = Tile(g, 34, function(self)
            R.ed.mode = "props"
            R.Set("icon", self.value)
        end)
        t:SetPoint("TOPLEFT", ((i - 1) % 9) * 41, -math.floor((i - 1) / 9) * 42)
        g.tiles[i] = t
    end
    local function Jump(step)
        return function()
            R.ed.iconStart = math.max(0, (R.ed.iconStart or 0) + step)
            R.RefreshEditor()
        end
    end
    g.first = Push(g, 34, 22, "<<", Jump(-450))
    g.first:SetPoint("TOPLEFT", 0, -224)
    g.prev = Push(g, 30, 22, "<", Jump(-45))
    g.prev:SetPoint("LEFT", g.first, "RIGHT", 4, 0)
    g.info = Text(g, "GameFontHighlightSmall")
    g.info:SetPoint("LEFT", g.prev, "RIGHT", 6, 0)
    g.next = Push(g, 30, 22, ">", Jump(45))
    g.next:SetPoint("LEFT", g.prev, "RIGHT", 76, 0)
    g.last = Push(g, 34, 22, ">>", Jump(450))
    g.last:SetPoint("LEFT", g.next, "RIGHT", 4, 0)
    Cancel(g)

    -- Réglages généraux, en bas.
    local sizeLabel = Text(e, "GameFontNormalSmall", "Taille")
    sizeLabel:SetPoint("BOTTOMLEFT", 16, 22)
    e.minus = Push(e, 26, 22, "-", function()
        R.cfg.scale = math.max(.5, (R.cfg.scale or 1) - .1)
        R.Apply()
    end)
    e.minus:SetPoint("LEFT", sizeLabel, "RIGHT", 6, 0)
    e.size = Text(e, "GameFontHighlightSmall", "100%")
    e.size:SetWidth(40)
    e.size:SetPoint("LEFT", e.minus, "RIGHT", 2, 0)
    e.plus = Push(e, 26, 22, "+", function()
        R.cfg.scale = math.min(2, (R.cfg.scale or 1) + .1)
        R.Apply()
    end)
    e.plus:SetPoint("LEFT", e.size, "RIGHT", 2, 0)
    e.shape = Push(e, 116, 22, "", function()
        R.cfg.shape = R.cfg.shape == "square" and "round" or "square"
        R.Apply()
    end)
    e.shape:SetPoint("LEFT", e.plus, "RIGHT", 12, 0)
    e.labels = Push(e, 96, 22, "", function()
        R.cfg.labels = not R.cfg.labels
        R.Apply()
    end)
    e.labels:SetPoint("LEFT", e.shape, "RIGHT", 6, 0)
    e.open = Push(e, 140, 22, "", function()
        local order = R.opts.fixed and {"key", "center", "fixed"} or {"key", "center"}
        local nextMode = order[1]
        for i, mode in ipairs(order) do
            if mode == R.cfg.open then nextMode = order[i % #order + 1] end
        end
        R.cfg.open = nextMode
        R.Apply()
    end)
    e.open:SetPoint("LEFT", e.labels, "RIGHT", 6, 0)
    e.reset = Push(e, 104, 22, "Tout remettre", function(self)
        Arm(self, "Tout remettre", function()
            StreamingTouchDB[R.opts.db] = nil
            R.Config()
            R.ed = {kind = "page", page = 1, mode = "props", cat = 1, actStart = 0, iconStart = 0}
            R.Apply()
        end)
    end)
    e.reset:SetPoint("LEFT", e.open, "RIGHT", 6, 0)
end

function R.RefreshProps()
    local p = R.editor.modes.props
    local cfg, ed = R.cfg, R.ed
    local kind, t, page = R.Target()
    local icon, color, shape = R.Get("icon"), R.Get("color"), R.Get("shape")
    local shown = color or (page and page.color) or "or"
    if kind == "key" then
        p.title:SetText("Bouton " .. R.opts.label)
        p.sub:SetText("Appui long : cet éditeur. Glisse-le pour le déplacer.")
    elseif kind == "page" then
        p.title:SetText(t.name or "Page")
        p.sub:SetText("Page " .. ed.page .. " sur " .. #cfg.pages .. ". Touche un bouton à gauche pour le modifier.")
    else
        p.title:SetText((R.Resolve(t)))
        p.sub:SetText(R.Describe(t) .. (t.hold and ("  ·  maintien : " .. R.HoldName(t.hold)) or ""))
    end
    R.Paint(p.preview, 48, icon, shown, kind == "page" and cfg.shape or shape or cfg.shape, "")
    p.change:SetShown(kind == "item")
    local list = R.Suggestions(kind, t)
    for i, s in ipairs(p.sugg) do
        local v = list[i]
        if v then
            s.value = v
            R.Paint(s, 34, v, "aucun", "square", "")
            s.glow:SetShown(v == icon)
            s:Show()
        else
            s:Hide()
        end
    end
    for _, s in ipairs(p.swatches) do s.sel:SetShown(s.key == shown) end
    local hasShape = kind ~= "page"
    for _, w in ipairs({p.shapeLabel, p.round, p.square, p.auto}) do w:SetShown(hasShape) end
    p.round:SetEnabled(shape ~= "round")
    p.square:SetEnabled(shape ~= "square")
    p.auto:SetEnabled(shape ~= nil)
    local hasName = kind ~= "key"
    for _, w in ipairs({p.nameLabel, p.name, p.nameOk}) do w:SetShown(hasName) end
    p.nameReset:SetShown(kind == "item")
    if hasName and not p.name:HasFocus() then p.name:SetText(R.Get("label") or "") end
    p.pageRow:SetShown(kind == "page")
    local petEntry = kind == "item" and R.PetSlotFor and R.PetSlotFor(t)
    local holdable = kind == "item" and (t.a == "SPELL" or t.a == "MACRO" or t.a == "TEXT" or t.a == "ITEM")
        and not (petEntry and petEntry.allowed and not petEntry.token) and true or false
    p.holdRow:SetShown(holdable)
    if holdable then
        p.holdPick:SetText(t.hold and R.HoldName(t.hold) or "Choisir…")
        p.holdClear:SetEnabled(t.hold ~= nil)
    end
    p.hint:SetText(R.PropsHint(kind, t, holdable))
    local roles = kind == "page" and R.opts.fixed and true or false
    for _, b in ipairs(p.roles or {}) do
        b:SetShown(roles)
        if roles then b:SetText(b.text0 .. (t[b.key] and " : oui" or " : non")) end
    end
    if p.forme then
        p.forme:SetShown(roles)
        if roles then p.forme:SetText("Posture / forme : " .. R.FormName(t.forme)) end
        p.hint:ClearAllPoints()
        p.hint:SetPoint("TOPLEFT", 0, roles and -284 or -252)
    end
end

-- CH : une page prend (ou perd) un rôle ; une seule page par rôle.
-- Réglages conseillés, appliqués une seule fois : la couche 2 jamais sur la page du combat
-- (sinon « Mêlée »), et un second sort au maintien pour les sorts qui vont par deux.
local FOLLOW = {a = "TEXT", text = "/petfollow", label = "Suivre", icon = "Interface\\Icons\\Ability_Tracking"}
R.HOLD_PAIRS = {
    [3044] = {a = "SPELL", spell = 19434},   -- Tir des Arcanes : Visée
    [1978] = {a = "SPELL", spell = 3043},    -- Morsure de serpent : Piqûre de scorpide
    [2643] = {a = "SPELL", spell = 1510},    -- Flèches multiples : Salve
    [5116] = {a = "SPELL", spell = 5384},    -- Trait de choc : Feindre la mort
    [2973] = {a = "SPELL", spell = 1495},    -- Attaque du raptor : Morsure de la mangouste
    [2974] = {a = "SPELL", spell = 781},     -- Coupure d'ailes : Désengagement
    [19306] = {a = "SPELL", spell = 19263},  -- Contre-attaque : Dissuasion
    [136] = {a = "SPELL", spell = 6991},     -- Guérison du familier : Nourrir le familier
    [3111] = {a = "SPELL", spell = 6991},
    [883] = {a = "SPELL", spell = 2641},     -- Appel du familier : Renvoyer le familier
    [982] = {a = "SPELL", spell = 136},      -- Ressusciter le familier : Guérison du familier
    [1499] = {a = "SPELL", spell = 13809},   -- Piège givrant : Piège de givre
    [13795] = {a = "SPELL", spell = 13813},  -- Piège d'immolation : Piège explosif
    ["/petattack"] = FOLLOW,                 -- Familier : attaque / revient
    ["/petstay"] = FOLLOW,
    ["/petdefensive"] = {a = "TEXT", text = "/petpassive", label = "Passif", icon = "Interface\\Icons\\Ability_Seal"},
}
function R.SuggestSetup(cfg)
    local pages = cfg.pages
    local layer, combat
    for p, pg in ipairs(pages) do
        if pg.layer and not layer then layer = p end
        if pg.combat and not combat then combat = p end
    end
    if not layer or layer == combat then
        local pick
        for p, pg in ipairs(pages) do
            if p ~= combat and #pg.items > 0 then
                if pg.name == "Mêlée" then
                    pick = p
                    break
                end
                pick = pick or p
            end
        end
        for _, pg in ipairs(pages) do pg.layer = nil end
        if pick then pages[pick].layer = true end
    end
    for _, pg in ipairs(pages) do
        for _, item in ipairs(pg.items) do
            local key = (item.a == "SPELL" and item.spell) or (item.a == "TEXT" and string.lower(item.text or ""))
            local pair = key and not item.hold and R.HOLD_PAIRS[key]
            if pair then
                item.hold = {}
                for k, v in pairs(pair) do item.hold[k] = v end
            end
        end
    end
end

-- Menu rond : une page vide « Page N » (créée avec « + Page ») reçoit les postures, une seule fois.
R.POSTURES = {"E_SIT", "E_STAND", "E_KNEEL", "E_SLEEP", "E_DEAD", "E_SHEATH", "S_MOUNT"}
function R.FillPostures(cfg)
    for _, page in ipairs(cfg.pages) do
        if page.name == "Postures" then return end
    end
    for p = #cfg.pages, 1, -1 do
        local page = cfg.pages[p]
        if #page.items == 0 and string.match(page.name or "", "^Page %d+$") then
            page.name = "Postures"
            if page.icon == I("INV_Misc_Gem_Variety_01") then page.icon = I("Spell_Nature_Tranquility") end
            for _, k in ipairs(R.POSTURES) do page.items[#page.items + 1] = {a = k} end
            return
        end
    end
end

-- Sous-menu : un bouton qui ouvre une bulle avec les boutons d'une autre page (comme les aspects).
-- La page garde un numéro à elle : on peut la renommer ou la déplacer, le sous-menu la suit.
function R.PageUid(page, cfg)
    cfg = cfg or R.cfg
    if not page.uid then
        local top = cfg.uidNext or 0
        for _, pg in ipairs(cfg.pages) do top = math.max(top, pg.uid or 0) end
        cfg.uidNext = top + 1
        page.uid = cfg.uidNext
    end
    return page.uid
end
function R.GroupPage(item)
    if not item.uid or not R.cfg then return end
    for p, pg in ipairs(R.cfg.pages) do
        if pg.uid == item.uid then return pg, p end
    end
end
-- Ce que montre la bulle : sorts appris, macros, ordres et cases du familier (pas de groupe dans un groupe).
function R.GroupEntries(item)
    local list = {}
    local page = R.GroupPage(item)
    if not page then return list end
    for _, sub in ipairs(page.items) do
        local kind = sub.a
        if (kind == "SPELL" or kind == "TEXT" or kind == "MACRO" or kind == "PETACTION") and R.Known(sub) then
            list[#list + 1] = sub
        end
    end
    return list
end
-- Éditeur, catégorie « Sous-menus » : les autres pages.
function R.PageChoices()
    local list = {}
    for p, pg in ipairs(R.cfg.pages) do
        if p ~= R.ed.page and #pg.items > 0 then
            list[#list + 1] = {a = "GROUP", uid = R.PageUid(pg), label = pg.name or ("Page " .. p), icon = I(pg.icon)}
        end
    end
    return list
end
-- Réglage conseillé (une fois) : « Familier » et « Pièges » en sous-menus sur la page du combat.
-- Page pleine : on retire d'abord les sorts déjà au maintien d'un autre bouton (pas encore appris d'abord).
function R.SuggestGroups(cfg)
    local pages = cfg.pages
    local home
    for _, pg in ipairs(pages) do
        if pg.combat then
            home = pg
            break
        end
    end
    home = home or pages[1]
    if not home then return end
    local add = {}
    for _, name in ipairs({"Familier", "Pièges"}) do
        for _, pg in ipairs(pages) do
            if pg.name == name and pg ~= home and #pg.items > 0 then
                local uid, have = R.PageUid(pg, cfg), false
                for _, it in ipairs(home.items) do
                    if it.a == "GROUP" and it.uid == uid then have = true end
                end
                if not have then add[#add + 1] = {a = "GROUP", uid = uid} end
                break
            end
        end
    end
    if #add == 0 then return end
    local held = {}
    for _, it in ipairs(home.items) do
        if it.hold and it.hold.a == "SPELL" then held[it.hold.spell] = true end
    end
    for pass = 1, 2 do
        for i = #home.items, 1, -1 do
            if #home.items + #add <= R.MAXITEMS then break end
            local it = home.items[i]
            if it.a == "SPELL" and held[it.spell] and not it.hold and (pass == 2 or not R.Known(it)) then
                table.remove(home.items, i)
            end
        end
    end
    local at = #home.items + 1
    for i, it in ipairs(home.items) do
        if it.a == "FLYOUT" then at = i + 1 end
    end
    for _, g in ipairs(add) do
        if #home.items >= R.MAXITEMS then break end
        table.insert(home.items, at, g)
        at = at + 1
    end
end

-- Rôle de chaque page : la première qui l'a.
function R.PageRoles()
    local roles = {}
    for p, pg in ipairs(R.cfg.pages) do
        for _, k in ipairs({"layer", "combat", "peace"}) do
            if pg[k] and not roles[k] then roles[k] = p end
        end
    end
    return roles
end

function R.PropsHint(kind, t, holdable)
    local pages = R.cfg.pages
    if kind == "page" and not R.opts.fixed then return "" end
    if kind == "page" then
        local roles = R.PageRoles()
        local function Name(k)
            local p = roles[k]
            return p and (pages[p].name or ("Page " .. p)) or "aucune"
        end
        local text = "|cffffd25aCouche 2 : " .. Name("layer") .. "   ·   En combat : " .. Name("combat")
            .. "   ·   Hors combat : " .. Name("peace") .. "|r\n"
        if roles.layer and roles.layer == roles.combat then
            return text .. "|cffff6060Couche 2 et En combat sont la même page : en combat, maintenir Couche 2 ne change rien."
                .. " Touche une autre page en haut, puis « Couche 2 ».|r"
        end
        return text .. "|cffb0b0b0Ces pages viennent toutes seules (Couche 2 maintenue, combat, forme prise).|r"
    end
    if kind == "item" and t.a == "GROUP" then
        local page = R.GroupPage(t)
        return "|cffb0b0b0Sous-menu : les boutons de la page « " .. (page and page.name or "?")
            .. " ». Pour les changer, touche cette page en haut.|r"
    end
    if holdable then
        return "|cffb0b0b0Appui : " .. (R.Resolve(t)) .. ".   Maintien (garde le doigt ½ seconde) : "
            .. (t.hold and (R.HoldName(t.hold) .. (R.Known(t.hold) and "" or " (pas encore appris)"))
                or "rien pour l'instant, touche « Choisir »") .. ".|r"
    end
    return ""
end

function R.TogglePageRole(key)
    local page = R.cfg and R.cfg.pages[R.ed.page]
    if not page then return end
    local on = not page[key]
    if on and ((key == "layer" and page.combat) or (key == "combat" and page.layer)) then
        Say(key == "layer" and "cette page est déjà « En combat » : mets la Couche 2 sur une autre page."
            or "cette page est déjà la « Couche 2 » : mets En combat sur une autre page.")
        return
    end
    for _, pg in ipairs(R.cfg.pages) do pg[key] = nil end
    page[key] = on or nil
    R.Apply()
end

function R.RefreshActions()
    local a, ed = R.editor.modes.action, R.ed
    local list = R.ActionChoices(ed.cat)
    if ed.actStart >= #list then ed.actStart = 0 end
    for i, t in ipairs(a.tiles) do
        local c = list[ed.actStart + i]
        if c then
            t.choice = c
            R.Paint(t, 36, c.icon, "aucun", "round", c.label)
            t:Show()
        else
            t:Hide()
        end
    end
    if #list == 0 then
        a.info:SetText(R.opts.choices and "Rien ici" or "Aucune macro")
    else
        a.info:SetText((math.floor(ed.actStart / 18) + 1) .. " / " .. math.ceil(#list / 18))
    end
    a.prev:SetEnabled(ed.actStart > 0)
    a.next:SetEnabled(ed.actStart + 18 < #list)
end

function R.RefreshText()
    local x = R.editor.modes.text
    local kind, t = R.Target()
    if x.box:HasFocus() or x.name:HasFocus() then return end
    if not R.ed.adding and kind == "item" and t.a == "TEXT" then
        x.box:SetText(t.text or "")
        x.name:SetText(t.label or "")
    else
        x.box:SetText("")
        x.name:SetText("")
    end
end

function R.RefreshIcons()
    local g, ed = R.editor.modes.icon, R.ed
    local kind, t = R.Target()
    local first = R.Suggestions(kind, t)
    local all = R.AllIcons()
    local total = #first + #all
    local current = R.Get("icon")
    ed.iconStart = math.max(0, math.min(ed.iconStart or 0, math.floor((total - 1) / 45) * 45))
    for i, tile in ipairs(g.tiles) do
        local n = ed.iconStart + i
        local v = n <= #first and first[n] or all[n - #first]
        if v then
            tile.value = I(v)
            R.Paint(tile, 34, v, "aucun", "square", "")
            tile.glow:SetShown(I(v) == current)
            tile:Show()
        else
            tile:Hide()
        end
    end
    g.info:SetText((math.floor(ed.iconStart / 45) + 1) .. " / " .. math.max(1, math.ceil(total / 45)))
    g.prev:SetEnabled(ed.iconStart > 0)
    g.first:SetEnabled(ed.iconStart > 0)
    g.next:SetEnabled(ed.iconStart + 45 < total)
    g.last:SetEnabled(ed.iconStart + 45 < total)
end

function R.RefreshEditor()
    local e, cfg, ed = R.editor, R.cfg, R.ed
    if not e or not e:IsShown() or not cfg then return end
    if ed.mode ~= "action" and ed.mode ~= "text" then ed.holdPick = nil end
    local pages = cfg.pages
    ed.page = math.max(1, math.min(ed.page or 1, #pages))
    local page = pages[ed.page]
    if ed.item and ed.item > #page.items then ed.item = #page.items > 0 and #page.items or nil end
    if ed.kind == "item" and not ed.item then ed.kind = "page" end

    R.Paint(e.keyTab, 34, cfg.keyIcon or R.opts.keyIcon or R.KEYICON, cfg.keyColor or "or", cfg.keyShape or cfg.shape, "")
    e.keyTab.glow:SetShown(ed.kind == "key")
    for i, t in ipairs(e.tabs) do
        local pg = pages[i]
        if pg then
            R.Paint(t, 34, pg.icon, pg.color, cfg.shape, "")
            t.glow:SetShown(i == ed.page and ed.kind ~= "key")
            t:Show()
        else
            t:Hide()
        end
    end
    e.addPage:ClearAllPoints()
    e.addPage:SetPoint("LEFT", e.tabs[math.max(1, #pages)], "RIGHT", 10, 0)
    e.addPage:SetShown(#pages < R.MAXPAGES)

    e.gridTitle:SetText((page.name or "Page") .. " : " .. #page.items .. " / " .. R.MAXITEMS .. " boutons")
    for i, t in ipairs(e.slots) do
        local item = page.items[i]
        if item then
            local label, icon = R.Resolve(item)
            R.Paint(t, 44, icon, item.color or page.color, item.shape or cfg.shape, label)
            t.glow:SetShown(ed.kind == "item" and ed.item == i)
            t:Show()
        elseif i == #page.items + 1 then
            R.Paint(t, 44, R.PLUS, "aucun", "square", "Ajouter")
            t.glow:SetShown(ed.adding and true or false)
            t:Show()
        else
            t:Hide()
        end
    end
    local onItem = ed.kind == "item" and ed.item ~= nil
    e.left:SetEnabled(onItem and ed.item > 1)
    e.right:SetEnabled(onItem and ed.item < #page.items)
    e.delete:SetEnabled(onItem)

    e.size:SetText(math.floor((cfg.scale or 1) * 100 + .5) .. " %")
    e.shape:SetText(cfg.shape == "square" and "Forme : carrée" or "Forme : ronde")
    e.labels:SetText(cfg.labels and "Noms : oui" or "Noms : non")
    e.open:SetText(cfg.open == "fixed" and "Toujours affiché" or cfg.open == "center" and "Ouvrir : au centre"
        or ("Ouvrir : sur " .. R.opts.label))

    for name, frame in pairs(e.modes) do frame:SetShown(name == ed.mode) end
    e.catBar:SetShown(ed.mode == "action" or ed.mode == "text")
    for i, b in ipairs(e.cats) do b:SetEnabled(i ~= ed.cat or ed.mode ~= (i == #e.cats and "text" or "action")) end
    if ed.mode == "props" then
        R.RefreshProps()
    elseif ed.mode == "action" then
        R.RefreshActions()
    elseif ed.mode == "text" then
        R.RefreshText()
    elseif ed.mode == "icon" then
        R.RefreshIcons()
    end
end

-- L'éditeur logé dans les réglages (/stouch) : sans cadre, sans titre ni croix, sans Échap à lui.
function R.Dock(container)
    if not R.editor then R.BuildEditor() end
    local e = R.editor
    if e.dock == container then return e end
    e.dock = container
    e:SetParent(container)
    e:SetFrameLevel(container:GetFrameLevel() + 1)
    e:ClearAllPoints()
    e:SetPoint("TOPLEFT", container, "TOPLEFT", -14, 38)
    e:SetScale(1)
    e:SetBackdropColor(0, 0, 0, 0)
    e:SetBackdropBorderColor(0, 0, 0, 0)
    e:EnableMouse(false)
    e:SetMovable(false)
    for _, w in ipairs({e.titleText, e.closeButton, e.skinButton}) do w:Hide() end
    local name = "StreamingTouchRingEditor" .. R.opts.suffix
    for i, special in ipairs(UISpecialFrames) do
        if special == name then
            table.remove(UISpecialFrames, i)
            break
        end
    end
    return e
end

function R.OpenEditor()
    if InCombatLockdown() then Say("l'éditeur s'ouvre hors combat.") return end
    R.Config()
    -- Tout se modifie dans les réglages (/stouch), sans fenêtre à part.
    if addon.settings and addon.settings.OpenEdit and addon.settings.OpenEdit(R) then return end
    if not R.editor then R.BuildEditor() end
    if R.ring then R.ring:Hide() end
    local e = R.editor
    e:SetScale(math.min(1, UIParent:GetHeight() * .96 / 440, UIParent:GetWidth() * .96 / 660))
    e:Show()
    R.RefreshEditor()
end

return R
end

-- Le menu rond (fenêtres, cibles, emotes…).
addon.radial = NewRing({db = "ring", off = "radialOff", suffix = "", label = "Menu", what = "menu rond",
    title = "Menu rond — tout se modifie", slash = "STREAMINGTOUCHRING", command = "/strond",
    defaultPos = {.2, .52}, migrate = true, noClose = true, defaults = function() return R.DEFAULT end})

-- Le rond de sorts (aspects, pièges…) : s'ouvre au toucher ou reste toujours affiché.
addon.spells = NewRing({db = "spellRing", off = "spellRingOff", suffix = "Spells", label = "Sorts", what = "rond de sorts",
    title = "Rond de sorts — tout se modifie", slash = "STREAMINGTOUCHSPELLS", command = "/stsorts",
    defaultPos = {.32, .52}, fixed = true, keyIcon = I("Spell_Nature_RavenForm"), defaults = SpellDefaults,
    version = 2, upgrade = SpellUpgrade, hideUnknown = true,
    categoryNames = function()
        local names = {}
        local tabs = SpellTabs(true)
        for _, tab in ipairs(tabs) do names[#names + 1] = tab.name end
        names[#names + 1] = "Macros, sacs"
        -- Sous-menus : une autre page dans une bulle (si la barre a la place : 8 au plus avec « Macro libre »).
        if #tabs + 3 <= 8 then names[#names + 1] = "Sous-menus" end
        return names
    end,
    choices = function(cat)
        local tabs = SpellTabs(true)
        if tabs[cat] then return tabs[cat].list end
        local P = addon.spells
        if cat == #tabs + 1 then
            local list = MacroChoices()
            for _, c in ipairs(BagChoices()) do list[#list + 1] = c end
            if #tabs + 3 > 8 then
                for _, c in ipairs(P.PageChoices()) do list[#list + 1] = c end
            end
            return list
        end
        if cat == #tabs + 2 then return P.PageChoices() end
        return {}
    end})

-- ==== Petite barre de sorts (2.6) ====
-- Une barre à part de l'arc, pour les sorts qu'on veut sous la main (aspects, pistage, familier…) :
-- 8 boutons au plus, glissés depuis le grimoire ou un sac. Un groupe du grimoire (Aspects, Pistage…) ou
-- la barre du familier tient dans un seul bouton : on le touche, ses sorts s'ouvrent au-dessus.
-- Sa poignée (le petit rond doré « Barre ») l'ouvre et la ferme d'un appui, même en combat ; Échap la ferme aussi.
-- En ligne, en arc ou en éventail, à la taille voulue.
-- Dans Radial.lua pour qu'un /reload suffise. Elle se sert de l'habillage, des recharges et des infobulles
-- de l'arc de sorts (addon.spells).
do
local Q = {MAX = 8, buttons = {}, pops = {}, SIZE = 44, GAP = 6, HANDLE = 30}
addon.barre = Q
Q.SHAPES = {{"ligne", "Ligne"}, {"arc", "Arc"}, {"eventail", "Éventail"}}
Q.HANDLE_ICON = "Interface\\Icons\\INV_Misc_Gem_Variety_01"
Q.PET_ICON = "Ability_Hunter_BeastCall"
Q.LIST_ICON = "INV_Misc_Bag_08"
Q.SUBMAX = 12

-- Le sort part à l'appui ou au relâché, comme les barres du jeu (réglage « lancer à l'appui »).
-- Un bouton de groupe ouvre (ou ferme) ses sorts au lieu de lancer quelque chose.
Q.PRE = [=[
    local kd = owner:GetAttribute("keydown")
    if (down and kd) or (not down and not kd) then
        local pop = self:GetAttribute("flyout") and self:GetFrameRef("flypop")
        if pop then
            local open = pop:IsShown()
            for i = 1, owner:GetAttribute("pops") or 0 do
                local other = owner:GetFrameRef("pop" .. i)
                if other then other:Hide() end
            end
            if not open then pop:Show() end
            return false
        end
        return nil, "close"
    end
    return false
]=]
-- Après un sort : les groupes ouverts se referment, et la barre aussi (sauf si on veut qu'elle reste).
Q.POST = [=[
    for i = 1, owner:GetAttribute("pops") or 0 do
        local other = owner:GetFrameRef("pop" .. i)
        if other then other:Hide() end
    end
    if owner:GetAttribute("autoclose") then
        local bar = owner:GetFrameRef("bar")
        if bar then bar:Hide() end
    end
]=]
-- La poignée : ouvre ou ferme la barre, aussi en combat.
local TOGGLE = [=[
    local bar = self:GetFrameRef("bar")
    for i = 1, self:GetAttribute("pops") or 0 do
        local other = self:GetFrameRef("pop" .. i)
        if other then other:Hide() end
    end
    if bar:IsShown() then bar:Hide() else bar:Show() end
]=]
-- Barre ouverte : Échap la ferme (touche Échap de l'appli comprise), même en combat.
local ESC_SHOW = [=[
    self:ClearBindings()
    self:SetBindingClick(true, "ESCAPE", "StreamingTouchBarrePoignee")
]=]
local ESC_HIDE = [=[ self:ClearBindings() ]=]

function Q.Config()
    StreamingTouchDB = StreamingTouchDB or {}
    local c = StreamingTouchDB.barre
    if type(c) ~= "table" then
        c = {open = true, shape = "ligne", dir = -1, scale = 1, items = {}}
        StreamingTouchDB.barre = c
    end
    if type(c.items) ~= "table" then c.items = {} end
    return c
end

-- Place de la poignée, en points de l'écran (UIParent). Par défaut : en bas, à gauche du milieu.
function Q.Pos()
    local c = Q.Config()
    if type(c.pos) == "table" and tonumber(c.pos.x) and tonumber(c.pos.y) then return c.pos.x, c.pos.y end
    return UIParent:GetWidth() * .42, UIParent:GetHeight() * .24
end

local function Group(item) return item and (item.a == "FLYOUT" or item.a == "PETBAR" or item.a == "LISTE") end
Q.Group = Group

-- Nom et icône d'un bouton. Une sous-barre à soi (LISTE) : son nom, l'icône de son premier bouton.
function Q.Look(item)
    if item.a == "LISTE" then
        local first = item.items and item.items[1]
        local icon = first and select(2, addon.spells.Resolve(first))
        return item.label or "Sous-barre", icon or Q.LIST_ICON
    end
    local label, icon = addon.spells.Resolve(item)
    if item.a == "PETBAR" then icon = Q.PET_ICON end
    return label, icon
end

function Q.Build()
    if Q.frame then return end
    local P = addon.spells
    local f = CreateFrame("Frame", "StreamingTouchBarre", UIParent, "SecureFrameTemplate")
    f:SetSize(1, 1)
    f:SetFrameStrata("HIGH")
    Q.frame = f
    local bar = CreateFrame("Frame", "StreamingTouchBarreSorts", f, "SecureFrameTemplate")
    bar:SetAllPoints(f)
    Q.bar = bar
    -- Fermée par un sort (code sûr) : la poignée s'éteint quand même.
    bar:HookScript("OnHide", function() if Q.handle then Q.PaintHandle() end end)
    bar:HookScript("OnShow", function() if Q.handle then Q.PaintHandle() end end)
    local h = CreateFrame("Button", "StreamingTouchBarrePoignee", f, "SecureHandlerClickTemplate")
    h:RegisterForClicks("AnyUp")
    h:SetFrameRef("bar", bar)
    h:SetAttribute("_onclick", TOGGLE)
    h:SetAttribute("pops", 0)
    h:SetAttribute("keydown", GetCVarBool("ActionButtonUseKeyDown") and true or false)
    P.Visual(h)
    h:SetFrameLevel(f:GetFrameLevel() + 5)
    h:HookScript("OnClick", function()
        if not InCombatLockdown() and CursorItems() then Q.Drop() return end
        Q.Config().open = Q.bar:IsShown()
        Q.PaintHandle()
        if Q.bar:IsShown() then Q.Update() end
    end)
    h:HookScript("OnEnter", function(self)
        local tip = GameTooltip
        if not tip then return end
        if GameTooltip_SetDefaultAnchor then GameTooltip_SetDefaultAnchor(tip, self) else tip:SetOwner(self, "ANCHOR_LEFT") end
        tip:SetText(Q.Config().name or "Petite barre de sorts", 1, .82, .32)
        tip:AddLine("Touche : ouvrir / fermer (Échap la ferme aussi).", .9, .9, .9)
        tip:AddLine("Lâche un sort du grimoire ou un objet d'un sac ici : il va au bout de la barre.", .3, .9, .95, true)
        tip:Show()
    end)
    h:HookScript("OnLeave", function(self)
        if GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner() == self then GameTooltip:Hide() end
    end)
    h:SetScript("OnReceiveDrag", function() Q.Drop() end)
    Q.handle = h
    local esc = CreateFrame("Frame", nil, bar, "SecureHandlerShowHideTemplate")
    esc:SetAttribute("_onshow", ESC_SHOW)
    esc:SetAttribute("_onhide", ESC_HIDE)
    Q.esc = esc
end

local function Hooks(b)
    local P = addon.spells
    b:RegisterForClicks("AnyUp", "AnyDown")
    P.Visual(b)
    P.AddCooldown(b)
    SecureHandlerWrapScript(b, "OnClick", Q.handle, Q.PRE, Q.POST)
    b:HookScript("OnEnter", function(self) P.Tooltip(self) end)
    b:HookScript("OnLeave", function(self) P.HideTooltip(self) end)
end

function Q.Button(i)
    local b = Q.buttons[i]
    if b then return b end
    b = CreateFrame("Button", "StreamingTouchBarreSort" .. i, Q.bar, "SecureActionButtonTemplate")
    Hooks(b)
    -- Lâché sur un bouton de la barre : le nouveau prend sa place ; sur une sous-barre à soi : il y entre.
    b:SetScript("OnReceiveDrag", function(self)
        local item = Q.Config().items[self.index]
        if item and item.a == "LISTE" then Q.DropSub(self.index) else Q.Drop(self.index) end
    end)
    -- Maj + glisser : le sort quitte la barre, comme sur les barres du jeu.
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function(self) Q.PickUp(self.index) end)
    b.index = i
    Q.buttons[i] = b
    return b
end

-- La bulle d'un groupe : ses sorts au-dessus du bouton, sans fond. En ligne (6 par rangée), en arc ou en éventail.
function Q.Pop(k)
    local pop = Q.pops[k]
    if pop then return pop end
    pop = CreateFrame("Frame", "StreamingTouchBarreGroupe" .. k, Q.bar, "SecureFrameTemplate")
    pop:SetClampedToScreen(true)
    pop.buttons = {}
    -- Un groupe ouvert : le reste de la barre s'efface un peu (réglable), même en combat.
    pop:HookScript("OnShow", function() Q.Fade() end)
    pop:HookScript("OnHide", function() Q.Fade() end)
    Q.pops[k] = pop
    return pop
end

-- Fondu derrière un groupe ouvert : la barre et le rond (StreamingTouchDB.fondu, 35 % par défaut).
function addon.Fondu()
    local v = tonumber(StreamingTouchDB and StreamingTouchDB.fondu) or .35
    return math.max(.1, math.min(1, v))
end
function Q.Fade()
    local open
    for _, pop in ipairs(Q.pops) do
        if pop:IsShown() and Q.bar:IsShown() then open = pop end
    end
    local fade = addon.Fondu()
    for _, b in ipairs(Q.buttons) do b:SetAlpha((open and b ~= open.owner) and fade or 1) end
    if Q.handle then Q.handle:SetAlpha(open and fade or 1) end
end

-- Ce que contient un groupe : sorts d'un groupe du grimoire, barre du familier, ou ce qu'on a mis dans sa sous-barre.
function Q.Entries(item)
    local P = addon.spells
    local entries = {}
    if item.a == "PETBAR" then
        local bar = P.PetBar()
        for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
            if bar[slot] then entries[#entries + 1] = {pet = bar[slot], icon = bar[slot].icon} end
        end
    elseif item.a == "FLYOUT" then
        for _, s in ipairs(FlyoutSpells(item.flyout)) do entries[#entries + 1] = {spell = s.spell, label = s.label, icon = s.icon} end
    elseif item.a == "LISTE" then
        for _, sub in ipairs(item.items or {}) do
            local label, icon, text, macro, _, spell = P.Resolve(sub)
            if sub.a == "SPELL" and spell then
                entries[#entries + 1] = {spell = sub.spell, label = spell, icon = icon}
            elseif text or macro then
                entries[#entries + 1] = {text = text, macro = macro, label = label, icon = icon,
                    itemID = sub.a == "ITEM" and sub.item or nil}
            end
        end
    end
    return entries
end

-- Place du j-ième sort (sur n) d'une bulle, par rapport au centre de son bouton.
function Q.PopPlace(shape, j, n, size)
    local pitch = size + 6
    local span = shape == "arc" and math.rad(120) or math.pi
    local r = math.max(size * 1.6, (math.max(1, n) - 1) * pitch / span)
    local a = n > 1 and (math.pi / 2 + span / 2 - (j - 1) * span / (n - 1)) or math.pi / 2
    return math.cos(a) * r, math.sin(a) * r
end

function Q.FillPop(k, b, item, size)
    local P = addon.spells
    local pop = Q.Pop(k)
    local entries = Q.Entries(item)
    local shape = item.shape or "ligne"
    pop.owner = b
    pop:SetFrameLevel(Q.bar:GetFrameLevel() + 20)
    pop:Hide()
    local pitch = size + 6
    local perRow = math.max(1, math.min(6, #entries))
    local rows = math.max(1, math.ceil(#entries / perRow))
    pop:ClearAllPoints()
    if shape == "ligne" then
        pop:SetSize(perRow * pitch + 6, rows * pitch + 6)
        pop:SetPoint("BOTTOM", b, "TOP", 0, 6)
    else
        pop:SetSize(1, 1)
        pop:SetPoint("CENTER", b, "CENTER", 0, 0)
    end
    b.flySpells = item.a ~= "PETBAR" and {} or nil
    b.petGroup = item.a == "PETBAR" or nil
    for j, e in ipairs(entries) do
        local btn = pop.buttons[j]
        if not btn then
            btn = CreateFrame("Button", "StreamingTouchBarreGroupe" .. k .. "Sort" .. j, pop, "SecureActionButtonTemplate")
            Hooks(btn)
            pop.buttons[j] = btn
        end
        local col, row = (j - 1) % perRow, math.floor((j - 1) / perRow)
        btn:SetFrameLevel(pop:GetFrameLevel() + 2)
        btn:ClearAllPoints()
        if shape == "ligne" then
            btn:SetPoint("CENTER", pop, "BOTTOMLEFT", 3 + (col + .5) * pitch, 3 + (row + .5) * pitch)
        else
            local x, y = Q.PopPlace(shape, j, #entries, size)
            btn:SetPoint("CENTER", pop, "CENTER", x, y)
        end
        local auto
        btn.itemID = nil
        btn:SetAttribute("macrotext", nil)
        btn:SetAttribute("macro", nil)
        if e.pet then
            auto = e.pet.allowed and not e.pet.token and e.pet.name or nil
            btn:SetAttribute("type", "pet")
            btn:SetAttribute("action", e.pet.slot)
            btn:SetAttribute("spell", nil)
            btn.spell, btn.spellID, btn.petSlot = nil, nil, e.pet.slot
        elseif e.text or e.macro then
            -- Nourriture, potion, macro… : comme sur la barre.
            btn:SetAttribute("type", "macro")
            btn:SetAttribute("action", nil)
            btn:SetAttribute("spell", nil)
            btn:SetAttribute("macrotext", e.text)
            btn:SetAttribute("macro", e.macro)
            btn.spell, btn.spellID, btn.petSlot, btn.itemID = nil, nil, nil, e.itemID
        else
            local name = SpellName(e.spell) or e.label
            btn:SetAttribute("type", "spell")
            btn:SetAttribute("spell", name)
            btn:SetAttribute("action", nil)
            btn.spell, btn.spellID, btn.petSlot = name, e.spell, nil
            b.flySpells[#b.flySpells + 1] = {name = name, icon = e.icon, id = e.spell}
            addon.AutoCast(btn, name, e.spell)
        end
        -- Clic droit (ou maintien) sur un sort du familier : son lancement automatique.
        btn:SetAttribute("type2", auto and "macro" or nil)
        btn:SetAttribute("macrotext2", auto and ("/petautocasttoggle " .. auto) or nil)
        btn.name = btn.spell or (e.pet and e.pet.name) or e.label
        P.Paint(btn, size, e.icon, item.color or "or", "round", "")
        btn:Show()
    end
    for j = #entries + 1, #pop.buttons do
        local btn = pop.buttons[j]
        btn:Hide()
        btn:SetAttribute("type", nil)
        btn:SetAttribute("type2", nil)
        btn.spell, btn.petSlot, btn.itemID = nil, nil, nil
    end
    SecureHandlerSetFrameRef(b, "flypop", pop)
    Q.handle:SetFrameRef("pop" .. k, pop)
    b:SetAttribute("flyout", true)
    -- Petite flèche : ce bouton s'ouvre.
    if not b.flyMark then
        b.flyMark = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        if STANDARD_TEXT_FONT then pcall(b.flyMark.SetFont, b.flyMark, STANDARD_TEXT_FONT, 16, "THICKOUTLINE") end
        b.flyMark:SetPoint("CENTER", b, "TOP", 0, -4)
        b.flyMark:SetText("^")
    end
    b.flyMark:Show()
end

-- Place du i-ème bouton (sur n), par rapport à la poignée. Ligne : tout droit ; arc : une courbe qui monte ;
-- éventail : un demi-cercle au-dessus de la poignée. dir = -1 vers la gauche, 1 vers la droite.
function Q.Place(shape, dir, i, n, size, gap)
    local step = size + gap
    if shape == "eventail" then
        local r = math.max(size * 1.5, n * step / math.pi)
        local a = math.rad(180 - (i - .5) * 180 / n)
        return math.cos(a) * r, math.sin(a) * r
    end
    local x = dir * (i * step + (Q.HANDLE / 2 - size / 2))
    if shape == "arc" then
        local depth = math.max(1, n) * step * 3
        return x, (x * x) / depth
    end
    return x, 0
end

function Q.PlacePos()
    local f = Q.frame
    if not f or InCombatLockdown() then return end
    local scale = f:GetScale() or 1
    local x, y = Q.Pos()
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

function Q.PaintHandle()
    local h = Q.handle
    if not h then return end
    local P = addon.spells
    P.Paint(h, Q.HANDLE, Q.HANDLE_ICON, "or", "round", Q.Config().name or "Barre")
    P.Lit(h, Q.bar:IsShown())
end

function Q.Layout()
    if not Q.frame then return end
    if InCombatLockdown() then Q.pending = true return end
    Q.pending = nil
    local P = addon.spells
    local db = StreamingTouchDB or {}
    local c = Q.Config()
    local f, bar, h = Q.frame, Q.bar, Q.handle
    f:SetScale(math.max(.5, math.min(2, tonumber(c.scale) or 1)))
    Q.PlacePos()
    h:ClearAllPoints()
    h:SetPoint("CENTER", f, "CENTER", 0, 0)
    local items, size, gap = c.items, Q.SIZE, Q.GAP
    local n = math.min(#items, Q.MAX)
    local dir = (tonumber(c.dir) or -1) > 0 and 1 or -1
    local pops = 0
    for i = 1, n do
        local b = Q.Button(i)
        local item = items[i]
        local label, icon, text, macro, _, spell, _, petSlot = P.Resolve(item)
        if Group(item) then
            label, icon = Q.Look(item)
            text, macro, spell, petSlot = nil, nil, nil, nil
        end
        local x, y = Q.Place(c.shape, dir, i, n, size, gap)
        b:ClearAllPoints()
        b:SetPoint("CENTER", f, "CENTER", x, y)
        b:SetAttribute("type", petSlot and "pet" or spell and "spell" or (text or macro) and "macro" or nil)
        b:SetAttribute("action", petSlot)
        b:SetAttribute("spell", (not petSlot) and spell or nil)
        b:SetAttribute("macrotext", text)
        b:SetAttribute("macro", macro)
        if spell and not petSlot then
            addon.AutoCast(b, spell, (item.a == "SPELL" and type(item.spell) == "number") and item.spell or nil)
        end
        b.spell, b.petSlot, b.item, b.name, b.run, b.hold = spell, petSlot, item, label, nil, nil
        b.spellID = (item.a == "SPELL" and type(item.spell) == "number") and item.spell or nil
        b.itemID = item.a == "ITEM" and item.item or nil
        P.Paint(b, size, icon, item.color or "or", "round", "")
        if Group(item) then
            pops = pops + 1
            Q.FillPop(pops, b, item, size)
            b.flyIcon = I(icon) or icon
        else
            b:SetAttribute("flyout", nil)
            b.flySpells, b.flyIcon, b.petGroup = nil, nil, nil
            if b.flyMark then b.flyMark:Hide() end
        end
        b:Show()
    end
    for i = n + 1, #Q.buttons do Q.buttons[i]:Hide() end
    for k = pops + 1, #Q.pops do Q.pops[k]:Hide() end
    h:SetAttribute("pops", pops)
    h:SetAttribute("autoclose", c.autoclose ~= false)
    bar:SetShown(c.open ~= false)
    f:SetShown(not db.barreOff)
    Q.PaintHandle()
    Q.Fade()
    Q.Update()
end

-- Tous les boutons de sort : ceux de la barre et ceux des groupes.
function Q.All()
    local list = {}
    for _, b in ipairs(Q.buttons) do list[#list + 1] = b end
    for _, pop in ipairs(Q.pops) do
        for _, b in ipairs(pop.buttons) do list[#list + 1] = b end
    end
    return list
end

-- Recharges, sort actif (aspect en cours), utilisable : comme sur l'arc.
function Q.Update()
    local P = addon.spells
    if not Q.frame or not Q.bar:IsShown() then return end
    pcall(function() P.actNames, P.actIds = P.ActiveSet() end)
    pcall(function() P.petTokens, P.petSpells = P.PetState() end)
    for _, b in ipairs(Q.All()) do
        if b:IsShown() then pcall(P.UpdateButton, b) end
    end
end

-- Hors de portée : l'icône passe au rouge (4 fois par seconde, seulement barre ouverte).
function Q.UpdateRange()
    if not Q.frame or not Q.bar:IsVisible() then return end
    local P = addon.spells
    for _, b in ipairs(Q.All()) do
        if b:IsVisible() then
            local out = (b.spell and not b.petSlot) and SpellRange(b.spell) == false or false
            if out ~= (b.outOfRange or false) then
                b.outOfRange = out
                pcall(P.Tint, b)
            end
        end
    end
end

local function Key(x)
    if x.a == "SPELL" then return "S" .. tostring(SpellName(x.spell) or x.label or x.spell) end
    if x.a == "ITEM" then return "I" .. tostring(x.item) end
    if x.a == "MACRO" then return "M" .. tostring(x.macro) end
    if x.a == "FLYOUT" then return "F" .. tostring(x.flyout) end
    if x.a == "PETBAR" then return "B" end
    if x.a == "LISTE" then return "L" .. tostring(x.id) end
    return tostring(x.a)
end

-- Ajoute (ou met à la place at) une liste de boutons ; dit ce qui s'est passé.
function Q.Add(list, at)
    local items = Q.Config().items
    local have = {}
    for _, old in ipairs(items) do have[Key(old)] = true end
    local added, full = {}, false
    for _, item in ipairs(list) do
        local k = Key(item)
        if not have[k] then
            if at and items[at] then
                have[Key(items[at])] = nil
                items[at] = item
                at = nil
            elseif #items >= Q.MAX then
                full = true
                break
            else
                items[#items + 1] = item
            end
            have[k] = true
            added[#added + 1] = item.label or "?"
        end
    end
    if #added > 0 then
        Q.Config().open = true
        Q.Layout()
        Say("petite barre : " .. table.concat(added, ", ") .. ".")
    end
    if full then
        Say("la petite barre est pleine (" .. Q.MAX .. " boutons) : lâche le sort sur un autre pour le remplacer.")
    elseif #added == 0 and #list > 0 then
        Say("déjà dans la petite barre.")
    end
    if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
end

-- Ce que tient le doigt (sort, groupe du grimoire, macro, objet) rejoint la barre. at : lâché sur ce bouton.
-- Un groupe (Aspects, Pistage…) reste un seul bouton qui s'ouvre.
function Q.Drop(at)
    if InCombatLockdown() then return end
    local list = CursorItems()
    if not list then
        if GetCursorInfo and GetCursorInfo() then Say("on ne peut mettre ici que des sorts, des macros et des objets.") end
        return
    end
    if ClearCursor then ClearCursor() end
    local keep = {}
    for _, item in ipairs(list) do
        if item.a == "FLYOUT" or item.a == "SPELL" or item.a == "ITEM" or item.a == "MACRO" then keep[#keep + 1] = item end
    end
    Q.Add(keep, at)
end

-- La barre du familier du jeu en un bouton.
function Q.AddPet()
    if InCombatLockdown() then Say("pas pendant un combat.") return end
    Q.Add({{a = "PETBAR", label = "Familier", icon = Q.PET_ICON}})
end

-- Une sous-barre à soi (nourriture, potions, sorts…) : un bouton de la barre qui s'ouvre.
function Q.AddList()
    if InCombatLockdown() then Say("pas pendant un combat.") return end
    local c = Q.Config()
    c.nextId = (tonumber(c.nextId) or 0) + 1
    local n = 0
    for _, item in ipairs(c.items) do if item.a == "LISTE" then n = n + 1 end end
    local before = #c.items
    Q.Add({{a = "LISTE", id = c.nextId, label = n == 0 and "Sous-barre" or ("Sous-barre " .. (n + 1)), items = {}}})
    if #c.items > before then
        Q.sel = #c.items
        if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
    end
end

-- Ce que tient le doigt entre dans la sous-barre i (à la place j si on l'a lâché sur une case pleine).
function Q.DropSub(i, j)
    if InCombatLockdown() then return end
    local group = Q.Config().items[i]
    if not group or group.a ~= "LISTE" then return end
    local list = CursorItems()
    if not list then
        if GetCursorInfo and GetCursorInfo() then Say("on ne peut mettre ici que des sorts, des macros et des objets.") end
        return
    end
    if ClearCursor then ClearCursor() end
    group.items = group.items or {}
    local subs = group.items
    local have = {}
    for _, old in ipairs(subs) do have[Key(old)] = true end
    local added, full = {}, false
    for _, item in ipairs(list) do
        local flat = item.a == "FLYOUT" and FlyoutSpells(item.flyout) or {item}
        for _, x in ipairs(flat) do
            local k = Key(x)
            if (x.a == "SPELL" or x.a == "ITEM" or x.a == "MACRO") and not have[k] then
                if j and subs[j] then
                    have[Key(subs[j])] = nil
                    subs[j] = x
                    j = nil
                elseif #subs >= Q.SUBMAX then
                    full = true
                else
                    subs[#subs + 1] = x
                end
                if not full then
                    have[k] = true
                    added[#added + 1] = x.label or "?"
                end
            end
        end
    end
    if #added > 0 then
        Q.Layout()
        Say((group.label or "Sous-barre") .. " : " .. table.concat(added, ", ") .. ".")
    end
    if full then Say((group.label or "La sous-barre") .. " est pleine (" .. Q.SUBMAX .. " boutons).") end
    if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
end

-- Réglages d'un groupe choisi dans l'onglet : sa forme, son nom, ce qu'il contient.
function Q.SelGroup()
    local item = Q.sel and Q.Config().items[Q.sel]
    return Group(item) and item or nil
end
function Q.SetSub(field, value)
    local item = Q.SelGroup()
    if not item then return end
    item[field] = value
    Q.Layout()
    if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
end
function Q.RemoveSub()
    local item = Q.SelGroup()
    if not item or item.a ~= "LISTE" or not Q.subSel or not item.items[Q.subSel] then return end
    local gone = table.remove(item.items, Q.subSel)
    Q.subSel = nil
    Say("retiré de " .. (item.label or "la sous-barre") .. " : " .. (gone.label or "?") .. ".")
    Q.Layout()
    if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
end
function Q.Rename(text)
    text = text and text:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if text == "" then text = nil end
    Q.Config().name = text
    Q.PaintHandle()
    if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
end

-- Maj + glisser : le sort quitte la barre et reste au bout du doigt.
function Q.PickUp(i)
    if InCombatLockdown() or not (IsShiftKeyDown and IsShiftKeyDown()) then return end
    local items = Q.Config().items
    local item = items[i]
    if not item then return end
    table.remove(items, i)
    pcall(function()
        if item.a == "SPELL" then
            local pick = (C_Spell and C_Spell.PickupSpell) or PickupSpell
            if pick then pick(item.spell) end
        elseif item.a == "ITEM" then
            local pick = (C_Item and C_Item.PickupItem) or PickupItem
            if pick then pick(item.item) end
        elseif item.a == "MACRO" and PickupMacro then
            PickupMacro(item.macro)
        end
    end)
    Q.Layout()
    Say("retiré de la petite barre : " .. (item.label or "?") .. ".")
    if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
end

-- Réglages (onglet « Barre » de /stouch).
local function Refresh()
    Q.Layout()
    if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
end
function Q.Set(field, value)
    Q.Config()[field] = value
    Refresh()
end
function Q.SetOff(off)
    StreamingTouchDB.barreOff = off or nil
    Q.Build()
    Refresh()
end
function Q.Step(delta)
    local c = Q.Config()
    c.scale = math.max(.6, math.min(1.8, (tonumber(c.scale) or 1) + delta))
    Refresh()
end
function Q.StepFade(delta)
    StreamingTouchDB = StreamingTouchDB or {}
    StreamingTouchDB.fondu = math.floor(math.max(.1, math.min(1, addon.Fondu() + delta)) * 100 + .5) / 100
    Q.Fade()
    if addon.FadeRings then pcall(addon.FadeRings) end
    if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
end
function Q.MoveSel(step)
    local items, i = Q.Config().items, Q.sel
    if not i or not items[i] or not items[i + step] then return end
    items[i], items[i + step] = items[i + step], items[i]
    Q.sel = i + step
    Refresh()
end
function Q.RemoveSel()
    local items, i = Q.Config().items, Q.sel
    if not i or not items[i] then return end
    local gone = table.remove(items, i)
    Q.sel = #items > 0 and math.min(i, #items) or nil
    Say("retiré de la petite barre : " .. (gone.label or "?") .. ".")
    Refresh()
end

-- Déplacer la barre : on glisse le doigt n'importe où, la poignée suit.
function Q.StartMove(done)
    if InCombatLockdown() then Say("pas pendant un combat.") return end
    Q.Build()
    local m = Q.mover
    if not m then
        m = CreateFrame("Frame", nil, UIParent)
        Q.mover = m
        m:SetAllPoints(UIParent)
        m:SetFrameStrata("FULLSCREEN_DIALOG")
        m:EnableMouse(true)
        local shade = m:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        shade:SetColorTexture(.02, .06, .14, .25)
        m.text = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        m.text:SetPoint("TOP", 0, -90)
        m.text:SetWidth(math.max(300, UIParent:GetWidth() * .6))
        m.text:SetText("Glisse le doigt n'importe où (hors des joysticks de l'appli) : la petite barre suit. Puis touche « Terminé ».")
        for k, def in ipairs({{"Terminé", true, -76}, {"Annuler", false, 76}}) do
            local b = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
            b:SetSize(140, 30)
            b:SetText(def[1])
            b:SetPoint("TOP", def[3], -150)
            b:SetScript("OnClick", function() Q.EndMove(def[2]) end)
            m[k] = b
        end
        m:SetScript("OnMouseDown", function(self)
            local s = UIParent:GetEffectiveScale()
            local x, y = GetCursorPosition()
            local px, py = Q.Pos()
            self.grab = {x / s, y / s, px, py}
        end)
        m:SetScript("OnMouseUp", function(self) self.grab = nil end)
        m:SetScript("OnUpdate", function(self)
            local g = self.grab
            if not g or InCombatLockdown() then return end
            local s = UIParent:GetEffectiveScale()
            local x, y = GetCursorPosition()
            local w, h = UIParent:GetWidth(), UIParent:GetHeight()
            Q.Config().pos = {x = math.max(0, math.min(w, g[3] + x / s - g[1])), y = math.max(0, math.min(h, g[4] + y / s - g[2]))}
            Q.PlacePos()
        end)
    end
    local pos = Q.Config().pos
    m.before = type(pos) == "table" and {x = pos.x, y = pos.y} or false
    m.grab, m.done = nil, done
    Q.frame:Show()
    m:Show()
end
function Q.EndMove(keep)
    local m = Q.mover
    if not m then return end
    m.grab = nil
    m:Hide()
    if not keep then Q.Config().pos = m.before or nil end
    Q.Layout()
    if keep then Say("petite barre déplacée.") end
    if m.done then m.done() end
end

-- L'onglet « Barre » des réglages (construit par G.Build, rafraîchi par G.Refresh).
local function NameBox(parent, width, onDone)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width, 26)
    box:SetAutoFocus(false)
    box:SetMaxLetters(24)
    box:SetFontObject("GameFontHighlight")
    box:SetScript("OnEnterPressed", function(self) onDone(self:GetText()) self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self) onDone(self:GetText()) end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function Tile(parent, size, onDrop, onClick)
    local t = CreateFrame("Button", nil, parent)
    t:SetSize(size, size)
    t.icon = t:CreateTexture(nil, "ARTWORK")
    t.icon:SetAllPoints()
    t.sel = t:CreateTexture(nil, "OVERLAY")
    t.sel:SetColorTexture(1, .82, .32, .45)
    t.sel:SetAllPoints()
    t.sel:Hide()
    t:SetScript("OnReceiveDrag", onDrop)
    t:SetScript("OnClick", function()
        if GetCursorInfo and GetCursorInfo() then onDrop() return end
        onClick()
    end)
    return t
end

local function ShowIcon(t, item)
    if item then
        local _, icon = Q.Look(item)
        t.icon:SetTexture(I(icon) or icon)
        t.icon:SetTexCoord(.07, .93, .07, .93)
    else
        t.icon:SetColorTexture(.12, .14, .2, .7)
    end
end

function Q.BuildSettings(s, G)
    local Pill, Font, Section, Stepper = G.Pill, G.Font, G.Section, G.Stepper
    local function Again() if G.Refresh then G.Refresh() end end
    Section(s, "Petite barre de sorts", 0, 0, 290)
    s.show = Pill(s, 140, 30, "Affichée", function() Q.SetOff(false) end, Q.HANDLE_ICON)
    s.show:SetPoint("TOPLEFT", 0, -24)
    s.hide = Pill(s, 120, 30, "Masquée", function() Q.SetOff(true) end)
    s.hide:SetPoint("LEFT", s.show, "RIGHT", 8, 0)
    Section(s, "Nom de la poignée", 310, 0, 290)
    s.name = NameBox(s, 200, Q.Rename)
    s.name:SetPoint("TOPLEFT", 318, -26)
    s.autoclose = Pill(s, 300, 24, "", function() Q.Set("autoclose", Q.Config().autoclose == false) end)
    s.autoclose:SetPoint("TOPLEFT", 0, -58)
    Section(s, "Forme", 0, -84, 290)
    s.shapes = {}
    for i, sh in ipairs(Q.SHAPES) do
        local b = Pill(s, 92, 28, sh[2], function() Q.Set("shape", sh[1]) end)
        b:SetPoint("TOPLEFT", (i - 1) * 98, -106)
        s.shapes[i] = b
    end
    Section(s, "Sens", 310, -84, 290)
    s.left = Pill(s, 140, 28, "Vers la gauche", function() Q.Set("dir", -1) end)
    s.left:SetPoint("TOPLEFT", 310, -106)
    s.right = Pill(s, 140, 28, "Vers la droite", function() Q.Set("dir", 1) end)
    s.right:SetPoint("LEFT", s.left, "RIGHT", 8, 0)
    Section(s, "Taille", 0, -146, 140)
    s.size = Stepper(s, 0, -168, function() Q.Step(-.1) end, function() Q.Step(.1) end)
    -- Fondu : ce qui reste visible derrière un groupe ouvert (barre et ronds).
    Section(s, "Fondu derrière", 152, -146, 140)
    s.fade = Stepper(s, 152, -168, function() Q.StepFade(-.05) end, function() Q.StepFade(.05) end)
    Section(s, "Place", 310, -146, 290)
    s.move = Pill(s, 170, 30, "Déplacer la barre", function()
        if G.panel then G.panel:Hide() end
        Q.StartMove(function() if not InCombatLockdown() then G.Open(6) end end)
    end, "Interface\\Icons\\Ability_Rogue_Sprint")
    s.move:SetPoint("TOPLEFT", 310, -168)
    s.back = Pill(s, 110, 30, "Remettre", function() Q.Set("pos", nil) end)
    s.back:SetPoint("LEFT", s.move, "RIGHT", 8, 0)
    Section(s, "Les boutons de la barre (" .. Q.MAX .. " au plus)", 0, -210, 600)
    s.tiles = {}
    for i = 1, Q.MAX do
        local t = Tile(s, 40, function() Q.Drop(i) end, function()
            Q.sel, Q.subSel = i, nil
            Again()
        end)
        t:SetPoint("TOPLEFT", (i - 1) * 46, -232)
        s.tiles[i] = t
    end
    s.before = Pill(s, 40, 30, "<", function() Q.MoveSel(-1) end)
    s.before:SetPoint("TOPLEFT", 380, -237)
    s.after = Pill(s, 40, 30, ">", function() Q.MoveSel(1) end)
    s.after:SetPoint("LEFT", s.before, "RIGHT", 6, 0)
    s.remove = Pill(s, 110, 30, "Retirer", function() Q.RemoveSel() end)
    s.remove:SetPoint("LEFT", s.after, "RIGHT", 6, 0)
    s.list = Pill(s, 190, 30, "+ Sous-barre", function() Q.AddList() end, "Interface\\Icons\\" .. Q.LIST_ICON)
    s.list:SetPoint("TOPLEFT", 0, -280)
    s.pet = Pill(s, 210, 30, "+ Barre du familier", function() Q.AddPet() end, "Interface\\Icons\\" .. Q.PET_ICON)
    s.pet:SetPoint("LEFT", s.list, "RIGHT", 8, 0)
    s.help = Font(s, "GameFontHighlightSmall", "Pour ajouter : ouvre le grimoire (ou un sac) à côté de ce panneau, prends un sort ou un objet avec le doigt et lâche-le sur une case ci-dessus (ou n'importe où ici, ou sur le rond doré). Un groupe entier (Aspects, Pistage…) devient un seul bouton qui s'ouvre. « + Sous-barre » : un bouton à remplir toi-même (nourriture, potions…). Touche une case pour la choisir, puis < > pour la déplacer, ou « Retirer ».")
    s.help:SetPoint("TOPLEFT", 0, -320)
    s.help:SetWidth(600)
    s.help:SetJustifyH("LEFT")
    -- Le groupe choisi : sa forme ; pour une sous-barre à soi, aussi son nom et ce qu'elle contient.
    local g = CreateFrame("Frame", nil, s)
    g:SetPoint("TOPLEFT", 0, -318)
    g:SetSize(600, 140)
    s.group = g
    g.title = Section(g, "", 0, 0, 600)
    g.shapes = {}
    for i, sh in ipairs(Q.SHAPES) do
        local b = Pill(g, 84, 28, sh[2], function() Q.SetSub("shape", sh[1]) end)
        b:SetPoint("TOPLEFT", (i - 1) * 90, -22)
        g.shapes[i] = b
    end
    g.nameLabel = Font(g, "GameFontNormalSmall", "Nom :")
    g.nameLabel:SetPoint("TOPLEFT", 284, -30)
    g.name = NameBox(g, 200, function(text)
        text = text and text:gsub("^%s+", ""):gsub("%s+$", "") or ""
        local item = Q.SelGroup()
        if item and item.a == "LISTE" and text ~= "" and text ~= item.label then Q.SetSub("label", text) end
    end)
    g.name:SetPoint("TOPLEFT", 330, -24)
    g.tiles = {}
    for j = 1, Q.SUBMAX do
        local t = Tile(g, 30, function() if Q.sel then Q.DropSub(Q.sel, j) end end, function()
            Q.subSel = j
            Again()
        end)
        t:SetPoint("TOPLEFT", (j - 1) * 34, -62)
        g.tiles[j] = t
    end
    g.remove = Pill(g, 84, 30, "Retirer", function() Q.RemoveSub() end)
    g.remove:SetPoint("TOPLEFT", 412, -62)
    -- Enlever tout le groupe de la barre (pour une sous-barre, avec ce qu'elle contient).
    g.delete = Pill(g, 110, 30, "Supprimer", function(self)
        if self.armed then
            self.armed = nil
            Q.RemoveSel()
        else
            self.armed = true
            self.text:SetText("Sûr ?")
            if C_Timer and C_Timer.After then
                C_Timer.After(3, function() self.armed = nil self.text:SetText("Supprimer") end)
            end
        end
    end)
    g.delete:SetPoint("TOPLEFT", 502, -62)
    g.help = Font(g, "GameFontHighlightSmall", "Lâche ici nourriture, potions, sorts ou macros (12 au plus). Touche une case puis « Retirer » pour l'enlever. « Supprimer » (deux appuis) enlève tout ce groupe de la barre.")
    g.help:SetPoint("TOPLEFT", 0, -100)
    g.help:SetWidth(600)
    g.help:SetJustifyH("LEFT")
    g:Hide()
    s:EnableMouse(true)
    s:SetScript("OnReceiveDrag", function() Q.Drop() end)
    s:SetScript("OnMouseUp", function() if GetCursorInfo and GetCursorInfo() then Q.Drop() end end)
end

function Q.RefreshSettings(s)
    if not s or not s.show then return end
    local db = StreamingTouchDB or {}
    local c = Q.Config()
    s.show:Paint(not db.barreOff)
    s.autoclose.text:SetText(c.autoclose == false and "Après un sort : la barre reste ouverte" or "Après un sort : la barre se ferme")
    s.autoclose:Paint(c.autoclose ~= false)
    s.hide:Paint(db.barreOff and true or false)
    if not (s.name.HasFocus and s.name:HasFocus()) then s.name:SetText(c.name or "Barre") end
    for i, b in ipairs(s.shapes) do b:Paint((c.shape or "ligne") == Q.SHAPES[i][1]) end
    local right = (tonumber(c.dir) or -1) > 0
    s.left:Paint(not right)
    s.right:Paint(right)
    s.size:SetText(math.floor((tonumber(c.scale) or 1) * 100 + .5) .. " %")
    s.fade:SetText(math.floor(addon.Fondu() * 100 + .5) .. " %")
    if Q.sel and not c.items[Q.sel] then Q.sel = nil end
    for i, t in ipairs(s.tiles) do
        ShowIcon(t, c.items[i])
        t.sel:SetShown(Q.sel == i)
    end
    local item = Q.SelGroup()
    local g = s.group
    g:SetShown(item ~= nil)
    s.help:SetShown(item == nil)
    if not item then return end
    local label = Q.Look(item)
    g.title:SetText("Le groupe « " .. tostring(label) .. " » s'ouvre en :")
    for i, b in ipairs(g.shapes) do b:Paint((item.shape or "ligne") == Q.SHAPES[i][1]) end
    local mine = item.a == "LISTE"
    g.nameLabel:SetShown(mine)
    g.name:SetShown(mine)
    g.remove:SetShown(mine)
    g.help:SetShown(mine)
    if mine and not (g.name.HasFocus and g.name:HasFocus()) then g.name:SetText(item.label or "Sous-barre") end
    if Q.subSel and not (mine and item.items[Q.subSel]) then Q.subSel = nil end
    for j, t in ipairs(g.tiles) do
        t:SetShown(mine)
        ShowIcon(t, mine and item.items[j] or nil)
        t.sel:SetShown(Q.subSel == j)
    end
end

local function HasPet()
    for _, item in ipairs(Q.Config().items) do if item.a == "PETBAR" then return true end end
end

Q.events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "CVAR_UPDATE",
    "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE", "ACTIONBAR_UPDATE_STATE", "UPDATE_SHAPESHIFT_FORM",
    "PLAYER_TARGET_CHANGED", "BAG_UPDATE", "BAG_UPDATE_COOLDOWN", "SPELLS_CHANGED", "PET_BAR_UPDATE", "UNIT_PET",
    "START_AUTOREPEAT_SPELL", "STOP_AUTOREPEAT_SPELL"}) do
    pcall(Q.events.RegisterEvent, Q.events, event)
end
if Q.events.RegisterUnitEvent then pcall(Q.events.RegisterUnitEvent, Q.events, "UNIT_AURA", "player") end
Q.events:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" then
        Q.Config()
        if InCombatLockdown() then Q.pending = true return end
        Q.Build()
        Q.Layout()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not Q.frame then Q.Build() end
        if Q.pending then Q.Layout() end
    elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        if Q.frame then Q.Layout() end
    elseif event == "CVAR_UPDATE" then
        if Q.handle and not InCombatLockdown() and (name == "ActionButtonUseKeyDown" or name == "ACTION_BUTTON_USE_KEY_DOWN") then
            Q.handle:SetAttribute("keydown", GetCVarBool("ActionButtonUseKeyDown") and true or false)
        end
    elseif event == "SPELLS_CHANGED" and Q.frame and not InCombatLockdown() then
        Q.Layout()
    elseif (event == "PET_BAR_UPDATE" or event == "UNIT_PET") and Q.frame and HasPet() then
        -- Familier appelé ou renvoyé : sa bulle se refait (après le combat s'il le faut).
        Q.Layout()
    else
        Q.Update()
    end
end)
Q.ticker = CreateFrame("Frame")
Q.ticker:SetScript("OnUpdate", function(self, elapsed)
    self.wait = (self.wait or 0) - (elapsed or 0)
    if self.wait > 0 then return end
    self.wait = .25
    pcall(Q.UpdateRange)
end)

-- /stbarre : ouvre l'onglet « Barre » des réglages.
SLASH_STREAMINGTOUCHBARRE1 = "/stbarre"
SlashCmdList.STREAMINGTOUCHBARRE = function()
    if addon.settings and addon.settings.Open then addon.settings.Open(6) end
end
end

-- ==== CH : boutons du jeu (ancien Boutons.lua) ====
-- Dans Radial.lua pour qu'un /reload suffise : WoW ne charge un nouveau fichier qu'au redémarrage du jeu.
do
-- Streaming Touch, CH : apparence des boutons du jeu, groupe par groupe.
-- Barre principale, familier, postures et autres barres : forme (origine, carré, rond),
-- couleur du bord, taille, transparence, raccourci et nom des macros. /stboutons ou bouton
-- « Boutons du jeu » dans l'éditeur du menu rond. Les positions restent au mode édition du jeu.

local S = {styled = {}, group = 1}
addon.skin = S

local function Named(prefix, count)
    return function()
        local list = {}
        for i = 1, count do
            local b = _G[prefix .. i]
            if b then list[#list + 1] = b end
        end
        return list
    end
end

S.GROUPS = {
    {key = "main", name = "Barre principale", list = Named("ActionButton", 12)},
    {key = "pet", name = "Familier", list = Named("PetActionButton", 10)},
    {key = "stance", name = "Postures, aspects", list = Named("StanceButton", 10)},
    {key = "bars", name = "Autres barres", list = function()
        local list = {}
        for _, prefix in ipairs({"MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton",
            "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button"}) do
            for _, b in ipairs(Named(prefix, 12)()) do list[#list + 1] = b end
        end
        return list
    end},
}
S.SHAPES = {{"origine", "Origine"}, {"carre", "Carré"}, {"rond", "Rond"}}
S.DEFAULT = {shape = "origine", color = "or", size = 1, alpha = 1, hotkey = true, name = true}

function S.Get(key)
    StreamingTouchDB = StreamingTouchDB or {}
    local db = StreamingTouchDB
    db.skin = db.skin or {}
    db.skin[key] = db.skin[key] or {}
    local c = db.skin[key]
    for k, v in pairs(S.DEFAULT) do
        if c[k] == nil then c[k] = v end
    end
    return c
end

function S.IsDefault(c)
    for k, v in pairs(S.DEFAULT) do
        if c[k] ~= v then return false end
    end
    return true
end

local function Part(b, key, suffix)
    local name = b:GetName()
    return b[key] or (name and _G[name .. suffix])
end

local function Each(list, f)
    for _, t in pairs(list) do
        if t then f(t) end
    end
end

function S.Skin(b, cfg, group)
    local icon = Part(b, "icon", "Icon")
    if not icon then return end
    local st = S.styled[b]
    if not st then
        -- Jamais touché et réglage d'origine : on laisse le bouton du jeu tranquille.
        if S.IsDefault(cfg) then return end
        st = {round = false}
        -- Tout au fond : dans les boutons du jeu, l'icône est elle-même dans la couche BACKGROUND.
        st.rim = b:CreateTexture(nil, "BACKGROUND", nil, -8)
        st.rim:SetTexture(WHITE)
        st.rim:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
        st.rim:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
        st.rimMask = b:CreateMaskTexture()
        st.rimMask:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        st.rimMask:SetAllPoints(st.rim)
        st.iconMask = b:CreateMaskTexture()
        st.iconMask:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        st.iconMask:SetAllPoints(icon)
        S.styled[b] = st
    end
    if S.IsDefault(cfg) and st.clean then return end
    local custom = cfg.shape ~= "origine"
    local round = cfg.shape == "rond"
    local normal = b.GetNormalTexture and b:GetNormalTexture()
    local name = b:GetName()
    local art = {normal, b.SlotBackground, b.SlotArt, name and _G[name .. "FloatingBG"]}
    Each(art, function(t) t:SetAlpha(custom and 0 or 1) end)
    local c = addon.radial and addon.radial.COLOR[cfg.color or "or"]
    -- Case sans sort : le jeu cache son icône. On cache aussi le bord, la case reste transparente.
    local empty = not icon:IsShown() or not icon:GetTexture()
    if custom and c and c[3] and not empty then
        st.rim:SetVertexColor(c[3], c[4], c[5], 1)
        st.rim:Show()
    else
        st.rim:Hide()
    end
    if normal and not custom then
        if c and c[3] and cfg.color ~= "or" then normal:SetVertexColor(c[3], c[4], c[5]) else normal:SetVertexColor(1, 1, 1) end
    end
    if round ~= st.round then
        local blizzard = b.IconMask
        local overlays = {b.GetPushedTexture and b:GetPushedTexture(), b.GetHighlightTexture and b:GetHighlightTexture(),
            b.GetCheckedTexture and b:GetCheckedTexture()}
        if round then
            if blizzard then icon:RemoveMaskTexture(blizzard) end
            icon:AddMaskTexture(st.iconMask)
            st.rim:AddMaskTexture(st.rimMask)
            Each(overlays, function(t) t:AddMaskTexture(st.iconMask) end)
        else
            icon:RemoveMaskTexture(st.iconMask)
            if blizzard then icon:AddMaskTexture(blizzard) end
            st.rim:RemoveMaskTexture(st.rimMask)
            Each(overlays, function(t) t:RemoveMaskTexture(st.iconMask) end)
        end
        local cooldown = Part(b, "cooldown", "Cooldown")
        if cooldown and cooldown.SetSwipeTexture then
            cooldown:SetSwipeTexture(round and CIRCLE or WHITE)
            if cooldown.SetUseCircularEdge then cooldown:SetUseCircularEdge(round) end
        end
        st.round = round
    end
    local hotkey, macro = Part(b, "HotKey", "HotKey"), Part(b, "Name", "Name")
    if hotkey then hotkey:SetAlpha(cfg.hotkey and 1 or 0) end
    if macro then macro:SetAlpha(cfg.name and 1 or 0) end
    b:SetAlpha(cfg.alpha or 1)
    if not InCombatLockdown() then
        local want = math.max(.5, math.min(2, cfg.size or 1))
        if math.abs(b:GetScale() - want) > .001 then b:SetScale(want) end
    end
    -- Revenu au réglage d'origine : on ne retouche plus ce bouton tant que rien ne change.
    st.clean = S.IsDefault(cfg)
end

function S.ApplyAll()
    if not StreamingTouchDB then return end
    for _, group in ipairs(S.GROUPS) do
        local cfg = S.Get(group.key)
        for _, b in ipairs(group.list()) do S.Skin(b, cfg, group) end
    end
end

-- Un réglage a changé : on repeint les boutons, et on refait la mise en page tactile si la taille change.
function S.Changed(sizeChanged)
    for _, st in pairs(S.styled) do st.clean = nil end
    S.ApplyAll()
    if S.Refresh then S.Refresh() end
end

S.events = CreateFrame("Frame")
S.events:RegisterEvent("PLAYER_LOGIN")
S.events:RegisterEvent("PLAYER_REGEN_ENABLED")
S.events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        -- Le jeu recrée ou repeint des boutons : on repasse régulièrement.
        C_Timer.NewTicker(1.5, function() pcall(S.ApplyAll) end)
    end
    pcall(S.ApplyAll)
end)

-- ===================================================================================
-- Fenêtre de réglages : un groupe à gauche, ses réglages à droite. Hors combat.
-- ===================================================================================
local function Text(parent, template, value)
    local f = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    f:SetText(value or "")
    return f
end
local function Push(parent, width, height, value, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    Capsule(b, height)
    local label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    b:SetFontString(label)
    b:SetText(value)
    b:SetScript("OnEnter", function(self) self:Look(false, true) end)
    b:SetScript("OnLeave", function(self) self:Look(false) end)
    b:SetScript("OnMouseDown", function(self) self:Look(false, true, true) end)
    b:SetScript("OnMouseUp", function(self) self:Look(false, self.IsMouseOver and self:IsMouseOver()) end)
    b:SetScript("OnClick", onClick)
    b:Look(false)
    return b
end

function S.Current()
    local group = S.GROUPS[S.group]
    return group, S.Get(group.key)
end

function S.Set(field, value)
    local _, cfg = S.Current()
    cfg[field] = value
    S.Changed(field == "size")
end

function S.Step(field, step, low, high)
    local _, cfg = S.Current()
    local value = math.floor(((cfg[field] or 1) + step) * 10 + .5) / 10
    S.Set(field, math.max(low, math.min(high, value)))
end

function S.Build()
    local e = CreateFrame("Frame", "StreamingTouchSkinEditor", UIParent, "BackdropTemplate")
    S.editor = e
    e:SetSize(600, 380)
    e:SetPoint("CENTER")
    e:SetFrameStrata("FULLSCREEN_DIALOG")
    e:SetToplevel(true)
    e:EnableMouse(true)
    e:SetMovable(true)
    e:SetClampedToScreen(true)
    e:RegisterForDrag("LeftButton")
    e:SetScript("OnDragStart", e.StartMoving)
    e:SetScript("OnDragStop", e.StopMovingOrSizing)
    e:SetBackdrop({bgFile = WHITE, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3}})
    e:SetBackdropColor(.03, .05, .09, .97)
    e:SetBackdropBorderColor(1, .82, .32, 1)
    tinsert(UISpecialFrames, "StreamingTouchSkinEditor")
    Text(e, "GameFontNormalLarge", "Boutons du jeu — apparence et taille"):SetPoint("TOPLEFT", 14, -12)
    CreateFrame("Button", nil, e, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -2, -2)
    local back = Push(e, 120, 22, "< Menu rond", function()
        e:Hide()
        if addon.radial and addon.radial.OpenEditor then addon.radial.OpenEditor() end
    end)
    back:SetPoint("TOPRIGHT", -34, -10)
    local hint = Text(e, "GameFontDisableSmall", "Les positions se règlent avec le mode édition du jeu.")
    hint:SetPoint("TOPLEFT", 14, -34)

    e.groups = {}
    for i, group in ipairs(S.GROUPS) do
        local b = Push(e, 160, 30, group.name, function()
            S.group = i
            S.Refresh()
        end)
        b:SetPoint("TOPLEFT", 14, -58 - (i - 1) * 36)
        e.groups[i] = b
    end

    local right = CreateFrame("Frame", nil, e)
    right:SetPoint("TOPLEFT", 190, -56)
    right:SetSize(396, 280)
    e.previews = {}
    for i = 1, 3 do
        local tile = CreateFrame("Button", nil, right)
        addon.radial.Visual(tile)
        tile:EnableMouse(false)
        tile:SetPoint("TOPLEFT", (i - 1) * 60, 0)
        e.previews[i] = tile
    end
    e.title = Text(right, "GameFontNormalLarge")
    e.title:SetPoint("TOPLEFT", 190, -6)
    e.count = Text(right, "GameFontDisableSmall")
    e.count:SetPoint("TOPLEFT", 190, -28)

    local function Row(label, y)
        Text(right, "GameFontNormalSmall", label):SetPoint("TOPLEFT", 0, y)
    end
    Row("Forme", -70)
    e.shapes = {}
    for i, shape in ipairs(S.SHAPES) do
        local b = Push(right, 92, 24, shape[2], function() S.Set("shape", shape[1]) end)
        b:SetPoint("TOPLEFT", 90 + (i - 1) * 98, -64)
        e.shapes[i] = b
    end
    Row("Bord", -106)
    e.swatches = {}
    for i, c in ipairs(addon.radial.COLORS) do
        local s = CreateFrame("Button", nil, right)
        s:SetSize(22, 22)
        s:SetPoint("TOPLEFT", 90 + (i - 1) * 27, -100)
        s.sel = s:CreateTexture(nil, "BACKGROUND")
        s.sel:SetColorTexture(1, 1, 1, 1)
        s.sel:SetPoint("TOPLEFT", -3, 3)
        s.sel:SetPoint("BOTTOMRIGHT", 3, -3)
        s.tex = s:CreateTexture(nil, "ARTWORK")
        s.tex:SetAllPoints()
        if c[3] then s.tex:SetColorTexture(c[3], c[4], c[5], 1) else s.tex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up") end
        s.key = c[1]
        s:SetScript("OnClick", function() S.Set("color", c[1]) end)
        e.swatches[i] = s
    end
    local function Stepper(label, y, field, low, high)
        Row(label, y)
        local minus = Push(right, 30, 24, "-", function() S.Step(field, -.1, low, high) end)
        minus:SetPoint("TOPLEFT", 90, y + 6)
        local value = Text(right, "GameFontHighlight", "")
        value:SetWidth(60)
        value:SetPoint("LEFT", minus, "RIGHT", 4, 0)
        local plus = Push(right, 30, 24, "+", function() S.Step(field, .1, low, high) end)
        plus:SetPoint("LEFT", value, "RIGHT", 4, 0)
        return value
    end
    e.size = Stepper("Taille", -142, "size", .5, 2)
    e.alpha = Stepper("Opacité", -176, "alpha", .2, 1)
    Row("Textes", -210)
    e.hotkey = Push(right, 140, 24, "", function()
        local _, cfg = S.Current()
        S.Set("hotkey", not cfg.hotkey)
    end)
    e.hotkey:SetPoint("TOPLEFT", 90, -204)
    e.name = Push(right, 150, 24, "", function()
        local _, cfg = S.Current()
        S.Set("name", not cfg.name)
    end)
    e.name:SetPoint("LEFT", e.hotkey, "RIGHT", 6, 0)

    local copy = Push(e, 170, 24, "Copier sur tous", function()
        local _, cfg = S.Current()
        for _, group in ipairs(S.GROUPS) do
            local target = S.Get(group.key)
            for k in pairs(S.DEFAULT) do target[k] = cfg[k] end
        end
        S.Changed(true)
    end)
    copy:SetPoint("BOTTOMLEFT", 190, 16)
    local resetOne = Push(e, 150, 24, "Remettre ce groupe", function()
        local group = S.Current()
        StreamingTouchDB.skin[group.key] = nil
        S.Changed(true)
    end)
    resetOne:SetPoint("LEFT", copy, "RIGHT", 6, 0)
    local resetAll
    resetAll = Push(e, 110, 24, "Tout remettre", function()
        if not resetAll.armed then
            resetAll.armed = true
            resetAll:SetText("Confirmer ?")
            C_Timer.After(3, function() resetAll.armed = nil resetAll:SetText("Tout remettre") end)
            return
        end
        resetAll.armed = nil
        resetAll:SetText("Tout remettre")
        StreamingTouchDB.skin = nil
        S.Changed(true)
    end)
    resetAll:SetPoint("LEFT", resetOne, "RIGHT", 6, 0)
end

function S.Refresh()
    local e = S.editor
    if not e or not e:IsShown() then return end
    local group, cfg = S.Current()
    for i, b in ipairs(e.groups) do b:SetEnabled(i ~= S.group) end
    local list = group.list()
    e.title:SetText(group.name)
    e.count:SetText(#list == 0 and "Pas affichés en ce moment" or (#list .. " boutons"))
    for i, tile in ipairs(e.previews) do
        local b = list[i]
        local icon = b and Part(b, "icon", "Icon")
        local texture = icon and icon:GetTexture() or "Interface\\Icons\\INV_Misc_QuestionMark"
        local shape = cfg.shape == "rond" and "round" or "square"
        addon.radial.Paint(tile, 50, texture, cfg.shape == "origine" and "aucun" or cfg.color, shape, "")
        tile:SetAlpha(cfg.alpha or 1)
    end
    for i, b in ipairs(e.shapes) do b:SetEnabled(S.SHAPES[i][1] ~= cfg.shape) end
    for _, s in ipairs(e.swatches) do s.sel:SetShown(s.key == cfg.color) end
    e.size:SetText(math.floor((cfg.size or 1) * 100 + .5) .. " %")
    e.alpha:SetText(math.floor((cfg.alpha or 1) * 100 + .5) .. " %")
    e.hotkey:SetText(cfg.hotkey and "Raccourci : oui" or "Raccourci : non")
    e.name:SetText(cfg.name and "Nom macro : oui" or "Nom macro : non")
end

function S.Open()
    if InCombatLockdown() then print("|cffe8c46aStreaming Touch|r : réglages hors combat.") return end
    if not addon.radial then return end
    if not S.editor then S.Build() end
    local e = S.editor
    e:SetScale(math.min(1, UIParent:GetHeight() * .96 / 380, UIParent:GetWidth() * .96 / 600))
    e:Show()
    S.Refresh()
end

SLASH_STREAMINGTOUCHSKIN1 = "/stboutons"
SlashCmdList.STREAMINGTOUCHSKIN = function() S.Open() end
end

-- ==== CH : nouveau menu « Réglages tactiles » (/stouch, /reglages, bouton de la mini-carte) ====
-- Onglets : Commandes (ce que l'addon ajoute au jeu), Boutons du jeu, Menu rond, Rond de sorts, Chat.
do
local BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"
local G = {tab = 1, sub = {}}
addon.settings = G
-- Onglets qui contiennent un éditeur : 3 = menu rond, 4 = sorts.
G.editors = {[3] = addon.radial, [4] = addon.spells}
local S = addon.skin

local function Font(parent, template, text, r, g, b)
    local f = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    f:SetText(text or "")
    if r then f:SetTextColor(r, g, b) end
    return f
end

-- Bouton arrondi : bleu nuit, doré quand il est choisi, plus clair sous le doigt.
local function Pill(parent, width, height, text, onClick, icon)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    Capsule(b, height)
    b.text = Font(b, "GameFontHighlight", text)
    if icon then
        -- Icône ronde au bout gauche de la pilule.
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetTexture(icon)
        b.icon:SetTexCoord(.08, .92, .08, .92)
        b.icon:SetSize(height - 10, height - 10)
        b.icon:SetPoint("LEFT", 5, 0)
        if b.CreateMaskTexture then
            local mask = b:CreateMaskTexture()
            mask:SetTexture(DISC, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(b.icon)
            b.icon:AddMaskTexture(mask)
        end
        b.text:SetPoint("LEFT", b.icon, "RIGHT", 7, 0)
    else
        b.text:SetPoint("CENTER")
    end
    function b:Paint(on)
        self.on = on
        self:Look(on)
        if on then self.text:SetTextColor(.08, .06, .02) else self.text:SetTextColor(.93, .95, 1) end
    end
    b:SetScript("OnMouseDown", function(self) self:Look(self.on, true, true) end)
    b:SetScript("OnMouseUp", function(self) self:Paint(self.on) end)
    b:SetScript("OnEnter", function(self) self:Look(self.on, true) end)
    b:SetScript("OnLeave", function(self) self:Paint(self.on) end)
    b:SetScript("OnClick", onClick)
    b:Paint(false)
    return b
end

local function Section(parent, text, x, y, width)
    local f = Font(parent, "GameFontNormal", text, 1, .82, .32)
    f:SetPoint("TOPLEFT", x, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, .82, .32, .35)
    line:SetSize(width or 300, 1)
    line:SetPoint("TOPLEFT", x, y - 16)
    return f
end

local function Stepper(parent, x, y, onMinus, onPlus, extra, onExtra)
    local minus = Pill(parent, 32, 32, "-", onMinus)
    minus:SetPoint("TOPLEFT", x, y)
    local value = Font(parent, "GameFontHighlightLarge", "")
    value:SetWidth(70)
    value:SetPoint("LEFT", minus, "RIGHT", 4, 0)
    local plus = Pill(parent, 32, 32, "+", onPlus)
    plus:SetPoint("LEFT", value, "RIGHT", 4, 0)
    if extra then
        local reset = Pill(parent, 70, 30, extra, onExtra)
        reset:SetPoint("LEFT", plus, "RIGHT", 8, 0)
    end
    value.minus, value.plus = minus, plus
    return value
end

G.Pill, G.Font, G.Section, G.Stepper = Pill, Font, Section, Stepper

local function Percent(v) return math.floor((v or 1) * 100 + .5) .. " %" end

function G.Build()
    local p = CreateFrame("Frame", "StreamingTouchSettings", UIParent, "BackdropTemplate")
    G.panel = p
    p:SetSize(700, 580)
    p:SetPoint("CENTER")
    p:SetFrameStrata("FULLSCREEN_DIALOG")
    p:SetToplevel(true)
    p:EnableMouse(true)
    p:SetMovable(true)
    p:SetClampedToScreen(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving)
    p:SetScript("OnDragStop", p.StopMovingOrSizing)
    -- Fond aux coins arrondis : un liseré or, puis le fond bleu nuit.
    p.edge = RoundBox(p, "BACKGROUND", -8, 24, 0)
    p.edge:SetColor(1, .82, .32, .9)
    p.back = RoundBox(p, "BACKGROUND", -7, 22.5, 1.5)
    p.back:SetColor(.025, .045, .085, .97)
    tinsert(UISpecialFrames, "StreamingTouchSettings")
    -- Bandeau du haut : logo rond, nom de l'addon, sous-titre, croix ronde.
    local head = CreateFrame("Frame", nil, p)
    head:SetPoint("TOPLEFT", 8, -8)
    head:SetPoint("TOPRIGHT", -8, -8)
    head:SetHeight(56)
    RoundBox(head, "BACKGROUND", 0, 18, 0):SetColor(.08, .18, .34, .9)
    -- Logo : l'icône de Streaming Touch (téléphone, joystick, toucher), déjà ronde et bordée d'or.
    local logo = head:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\StreamingTouch\\Media\\Icon")
    logo:SetSize(46, 46)
    logo:SetPoint("LEFT", 6, 0)
    p.logo = logo
    p.title = Font(head, "GameFontNormalLarge", "Streaming Touch", 1, .86, .45)
    p.title:SetPoint("TOPLEFT", 60, -11)
    p.subtitle = Font(head, "GameFontHighlightSmall", "Réglages", .72, .8, .92)
    p.subtitle:SetPoint("TOPLEFT", p.title, "BOTTOMLEFT", 0, -4)
    local close = CreateFrame("Button", nil, head)
    close:SetSize(32, 32)
    close:SetPoint("RIGHT", -12, 0)
    close.edge = RoundBox(close, "BACKGROUND", 1, 16, 0)
    close.fill = RoundBox(close, "BACKGROUND", 2, 14.5, 1.5)
    close.edge:SetColor(1, .82, .32, .85)
    close.fill:SetColor(.38, .07, .07, .95)
    close.x = Font(close, "GameFontNormalLarge", "X", 1, .9, .8)
    close.x:SetPoint("CENTER", 0, 1)
    close:SetScript("OnEnter", function(self) self.fill:SetColor(.58, .12, .1, 1) end)
    close:SetScript("OnLeave", function(self) self.fill:SetColor(.38, .07, .07, .95) end)
    close:SetScript("OnClick", function() p:Hide() end)
    p.close = close

    -- Onglets.
    p.tabs = {}
    local tabs = {{"Commandes", "Interface\\Icons\\INV_Misc_Spyglass_03"},
        {"Boutons", "Interface\\Icons\\Ability_Marksmanship"},
        {"Menu rond", "Interface\\Icons\\INV_Misc_Gem_Variety_01"},
        {"Sorts", "Interface\\Icons\\Spell_Nature_RavenForm"},
        {"Chat", "Interface\\Icons\\INV_Letter_15"},
        {"Barre", "Interface\\Icons\\Ability_Hunter_AspectOfTheMonkey"}}
    -- Onglets ajoutés par les autres fichiers (Cadres.lua : cadres et mini-carte).
    for _, extra in ipairs(addon.extraTabs or {}) do tabs[#tabs + 1] = {extra.name, extra.icon} end
    local visible = #tabs - 1
    local tabW = math.floor((668 - (visible - 1) * 6) / visible)
    for i, t in ipairs(tabs) do
        local b = Pill(p, tabW, 38, t[1], function() G.Open(i) end, t[2])
        local shown = i == 1 and 0 or i - 2
        b:SetPoint("TOPLEFT", 16 + shown * (tabW + 6), -72)
        b:SetShown(i ~= 2)
        p.tabs[i] = b
    end
    p.pages, p.edits, p.subbars = {}, {}, {}
    for i = 1, #tabs do
        local page = CreateFrame("Frame", nil, p)
        page:SetPoint("TOPLEFT", 16, G.editors[i] and -158 or -122)
        page:SetSize(668, 380)
        page:Hide()
        p.pages[i] = page
        if G.editors[i] then
            -- Sous-onglets : les réglages, ou l'éditeur directement ici.
            local bar = CreateFrame("Frame", nil, p)
            bar:SetPoint("TOPLEFT", 16, -122)
            bar:SetSize(668, 30)
            bar:SetFrameLevel(p:GetFrameLevel() + 20)
            bar.view = Pill(bar, 150, 28, "Réglages", function()
                G.sub[i] = "view"
                G.Refresh()
            end)
            bar.view:SetPoint("TOPLEFT", 0, 0)
            bar.edit = Pill(bar, 230, 28, i == 3 and "Modifier le menu rond" or "Modifier les sorts", function()
                G.sub[i] = "edit"
                G.Refresh()
            end)
            bar.edit:SetPoint("LEFT", bar.view, "RIGHT", 8, 0)
            bar:Hide()
            p.subbars[i] = bar
            local edit = CreateFrame("Frame", nil, p)
            edit:SetPoint("TOPLEFT", 16, -158)
            edit:SetSize(668, 410)
            edit:Hide()
            p.edits[i] = edit
        end
    end
    -- Fermer les réglages ferme aussi l'éditeur logé dedans (et remet le rond fixe en place).
    p:SetScript("OnHide", function()
        for _, R in pairs(G.editors) do
            if R.editor and R.editor.dock and R.editor:IsShown() then R.editor:Hide() end
        end
    end)

    -- 1. Commandes : ce que l'addon ajoute au jeu ; chaque chose se coupe ici.
    local a = p.pages[1]
    local function Toggle(field, after)
        local db = StreamingTouchDB
        db[field] = not db[field] or nil
        if after then pcall(after) end
        G.Refresh()
    end
    local function Line(y, title, label, field, after, note)
        Section(a, title, 0, y, 600)
        local b = Pill(a, 300, 28, label, function() Toggle(field, after) end)
        b:SetPoint("TOPLEFT", 0, y - 18)
        b.label, b.field = label, field
        local text = Font(a, "GameFontDisableSmall", note)
        text:SetPoint("TOPLEFT", 312, y - 22)
        text:SetWidth(290)
        text:SetJustifyH("LEFT")
        return b
    end
    -- Les sorts de l'addon se refont avec le nouveau réglage (hors combat).
    local function Respells()
        for _, R in pairs(G.editors or {}) do
            if R.Layout and not InCombatLockdown() then pcall(R.Layout) end
        end
        if addon.barre and addon.barre.Layout and not InCombatLockdown() then pcall(addon.barre.Layout) end
    end
    a.toggles = {
        Line(0, "Joystick de déplacement", "Pas de côté", "strafeOff", addon.ApplyKeys,
            "Gauche et droite décalent ton personnage au lieu de le faire tourner."),
        Line(-50, "Cadavre", "Target maintenu", "corpseOff", addon.ApplyKeys,
            "Maintenir Target dans l'appli vise le cadavre à fouiller devant toi."),
        Line(-100, "Sorts offensifs", "Ciblage auto", "autoTargetOff", Respells,
            "Sans cible ennemie, le sort prend l'ennemi le plus proche devant toi et part."),
        Line(-150, "Chat", "Saisie au-dessus du clavier", "chatRaiseOff", nil,
            "Quand tu écris, la ligne du chat monte en haut de l'écran."),
        Line(-200, "Mini-carte", "Bouton de la mini-carte", "minimapOff", addon.ShowMinimapButton,
            "Sinon, /stouch ouvre aussi ces réglages."),
    }
    -- Barres du jeu : cachées au choix (l'arc de sorts et le menu rond les remplacent).
    Section(a, "Barres du jeu", 0, -248, 600)
    for i, d in ipairs({{"Barres d'action cachées", "barsShown"}, {"Familier et postures cachés", "petStanceShown"},
        {"Micro-menu caché", "microShown"}, {"Sacs cachés", "bagsShown"}}) do
        local field = d[2]
        local b = Pill(a, 300, 30, d[1], function() Toggle(field, addon.ApplyBars) end)
        b:SetPoint("TOPLEFT", ((i - 1) % 2) * 310, -270 - math.floor((i - 1) / 2) * 36)
        b.label, b.field = d[1], field
        a.toggles[#a.toggles + 1] = b
    end
    a.note = Font(a, "GameFontDisableSmall", "Pour déplacer ce qui reste à l'écran : mode Édition du jeu (Échap).")
    a.note:SetPoint("TOPLEFT", 0, -344)
    a.note:SetWidth(600)
    a.note:SetJustifyH("LEFT")
    -- Profil du compte : les réglages de ce personnage servent de base aux autres.
    Section(a, "Profil du compte (tous tes personnages)", 0, -366, 600)
    a.modele = Font(a, "GameFontDisableSmall", "")
    a.modele:SetPoint("TOPLEFT", 312, -368)
    local garder = Pill(a, 300, 30, "Enregistrer comme modèle", function()
        addon.EnregistrerModele()
        G.Refresh()
    end)
    garder:SetPoint("TOPLEFT", 0, -388)
    local prendre = Pill(a, 300, 30, "Prendre mes réglages de compte", function()
        if addon.Modele() then StaticPopup_Show("STREAMINGTOUCH_PRENDRE_MODELE")
        else addon.Note("aucun modèle : enregistre d'abord tes réglages sur ton personnage principal.") end
    end)
    prendre:SetPoint("TOPLEFT", 310, -388)
    -- Partage en texte : une fenêtre avec une zone de texte, pour copier (Exporter) ou coller (Importer).
    local function Fenetre()
        if G.texte then return G.texte end
        local f = CreateFrame("Frame", "StreamingTouchTexte", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
        f:SetSize(580, 360)
        f:SetPoint("CENTER")
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:EnableMouse(true)
        if f.SetBackdrop then
            f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", tile = true, tileSize = 32, edgeSize = 32,
                insets = {left = 8, right = 8, top = 8, bottom = 8}})
        end
        f.titre = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.titre:SetPoint("TOP", 0, -18)
        f.aide = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.aide:SetPoint("TOP", 0, -44)
        f.aide:SetWidth(530)
        local zone = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        zone:SetPoint("TOPLEFT", 22, -78)
        zone:SetPoint("BOTTOMRIGHT", -42, 56)
        local eb = CreateFrame("EditBox", nil, zone)
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(0)
        eb:SetFontObject(ChatFontNormal)
        eb:SetWidth(500)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        zone:SetScrollChild(eb)
        f.eb = eb
        f.ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.ok:SetSize(170, 26)
        f.ok:SetPoint("BOTTOMRIGHT", -26, 20)
        local fermer = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        fermer:SetSize(120, 26)
        fermer:SetPoint("BOTTOMLEFT", 26, 20)
        fermer:SetText("Fermer")
        fermer:SetScript("OnClick", function() f:Hide() end)
        if UISpecialFrames then table.insert(UISpecialFrames, "StreamingTouchTexte") end
        G.texte = f
        return f
    end
    local exporter = Pill(a, 300, 30, "Exporter mes réglages (texte)", function()
        local f = Fenetre()
        f.titre:SetText("Exporter mes réglages")
        f.aide:SetText("Tout le texte est sélectionné : Ctrl+C pour le copier, puis colle-le où tu veux."
            .. " Sur un autre personnage ou un autre PC : « Importer des réglages ».")
        f.eb:SetText(addon.Exporter())
        f.ok:SetText("Tout sélectionner")
        f.ok:SetScript("OnClick", function() f.eb:SetFocus() f.eb:HighlightText() end)
        f:Show()
        f.eb:SetFocus()
        f.eb:HighlightText()
    end)
    exporter:SetPoint("TOPLEFT", 0, -424)
    local importer = Pill(a, 300, 30, "Importer des réglages (texte)", function()
        local f = Fenetre()
        f.titre:SetText("Importer des réglages")
        f.aide:SetText("Colle le texte (Ctrl+V), puis « Importer ». Les réglages de Streaming Touch de ce personnage"
            .. " sont remplacés et l'interface se recharge. Texte d'une autre classe : les sorts de ta classe sont gardés.")
        f.eb:SetText("")
        f.ok:SetText("Importer")
        f.ok:SetScript("OnClick", function()
            if InCombatLockdown() then addon.Note("pas pendant un combat.") return end
            local ok, info = addon.Importer(f.eb:GetText())
            if ok then
                f:Hide()
                addon.Note("réglages importés" .. (info and (" (de " .. tostring(info) .. ")") or "") .. " : rechargement.")
                ReloadUI()
            else
                addon.Note("import impossible : " .. tostring(info) .. ".")
            end
        end)
        f:Show()
        f.eb:SetFocus()
    end)
    importer:SetPoint("TOPLEFT", 310, -424)
    if StaticPopupDialogs then StaticPopupDialogs["STREAMINGTOUCH_PRENDRE_MODELE"] = {
        text = "Remplacer les réglages de Streaming Touch de ce personnage par ceux de ton modèle ?\n\nL'interface va se recharger.",
        button1 = "Oui", button2 = "Annuler", timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        OnAccept = function() if addon.PrendreModele() then ReloadUI() end end,
    } end

    -- 2. Boutons du jeu : un groupe à gauche, ses réglages à droite.
    local s = p.pages[2]
    s.groups = {}
    for i, group in ipairs(S.GROUPS) do
        local b = Pill(s, 170, 34, group.name, function()
            S.group = i
            G.Refresh()
        end)
        b:SetPoint("TOPLEFT", 0, -(i - 1) * 40)
        s.groups[i] = b
    end
    local r = CreateFrame("Frame", nil, s)
    r:SetPoint("TOPLEFT", 186, 0)
    r:SetSize(420, 296)
    s.previews = {}
    for i = 1, 3 do
        local tile = CreateFrame("Button", nil, r)
        addon.radial.Visual(tile)
        tile:EnableMouse(false)
        tile:SetPoint("TOPLEFT", (i - 1) * 58, 0)
        s.previews[i] = tile
    end
    s.title = Font(r, "GameFontNormalLarge", "", 1, .86, .45)
    s.title:SetPoint("TOPLEFT", 186, -4)
    s.count = Font(r, "GameFontDisableSmall")
    s.count:SetPoint("TOPLEFT", 186, -26)
    local function Row(text, y) Font(r, "GameFontNormalSmall", text, 1, .82, .32):SetPoint("TOPLEFT", 0, y) end
    Row("Forme", -72)
    s.shapes = {}
    for i, shape in ipairs(S.SHAPES) do
        local b = Pill(r, 96, 30, shape[2], function() S.Set("shape", shape[1]) end)
        b:SetPoint("TOPLEFT", 84 + (i - 1) * 102, -64)
        s.shapes[i] = b
    end
    Row("Bord", -110)
    s.swatches = {}
    for i, c in ipairs(addon.radial.COLORS) do
        local w = CreateFrame("Button", nil, r)
        w:SetSize(24, 24)
        w:SetPoint("TOPLEFT", 84 + (i - 1) * 30, -104)
        w.sel = w:CreateTexture(nil, "BACKGROUND")
        w.sel:SetColorTexture(1, .9, .55, 1)
        w.sel:SetPoint("TOPLEFT", -3, 3)
        w.sel:SetPoint("BOTTOMRIGHT", 3, -3)
        w.tex = w:CreateTexture(nil, "ARTWORK")
        w.tex:SetAllPoints()
        if c[3] then w.tex:SetColorTexture(c[3], c[4], c[5], 1) else w.tex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up") end
        w.key = c[1]
        w:SetScript("OnClick", function() S.Set("color", c[1]) end)
        s.swatches[i] = w
    end
    Row("Taille", -148)
    s.size = Stepper(r, 84, -140, function() S.Step("size", -.1, .5, 2) end, function() S.Step("size", .1, .5, 2) end)
    Row("Opacité", -186)
    s.alpha = Stepper(r, 84, -178, function() S.Step("alpha", -.1, .2, 1) end, function() S.Step("alpha", .1, .2, 1) end)
    Row("Textes", -224)
    s.hotkey = Pill(r, 150, 30, "", function()
        local _, cfg = S.Current()
        S.Set("hotkey", not cfg.hotkey)
    end)
    s.hotkey:SetPoint("TOPLEFT", 84, -216)
    s.name = Pill(r, 160, 30, "", function()
        local _, cfg = S.Current()
        S.Set("name", not cfg.name)
    end)
    s.name:SetPoint("LEFT", s.hotkey, "RIGHT", 8, 0)
    local copy = Pill(s, 170, 30, "Copier sur tous", function()
        local _, cfg = S.Current()
        for _, group in ipairs(S.GROUPS) do
            local target = S.Get(group.key)
            for k in pairs(S.DEFAULT) do target[k] = cfg[k] end
        end
        S.Changed(true)
    end)
    copy:SetPoint("TOPLEFT", 0, -220)
    local resetOne = Pill(s, 170, 30, "Remettre ce groupe", function()
        local group = S.Current()
        if StreamingTouchDB.skin then StreamingTouchDB.skin[group.key] = nil end
        S.Changed(true)
    end)
    resetOne:SetPoint("TOPLEFT", 0, -256)
    local resetAll
    resetAll = Pill(r, 170, 30, "Tout remettre", function()
        if not resetAll.armed then
            resetAll.armed = true
            resetAll.text:SetText("Confirmer ?")
            C_Timer.After(3, function() resetAll.armed = nil resetAll.text:SetText("Tout remettre") end)
            return
        end
        resetAll.armed = nil
        resetAll.text:SetText("Tout remettre")
        StreamingTouchDB.skin = nil
        S.Changed(true)
    end)
    resetAll:SetPoint("TOPLEFT", 84, -256)

    -- 3. Menu rond : éditeur, affichage, taille.
    local m = p.pages[3]
    Section(m, "Menu rond", 0, 0, 600)
    local open = Pill(m, 300, 40, "Modifier le menu rond", function()
        G.sub[3] = "edit"
        G.Refresh()
    end, "Interface\\Icons\\INV_Misc_Gem_Variety_01")
    open:SetPoint("TOPLEFT", 0, -26)
    m.help = Font(m, "GameFontHighlightSmall", "Pages, boutons, icônes, couleurs, formes et noms : sous-onglet « Modifier le menu rond ».")
    m.help:SetPoint("TOPLEFT", 0, -76)
    Section(m, "Bouton Menu à l'écran", 0, -104, 600)
    m.show = Pill(m, 140, 32, "Affiché", function()
        StreamingTouchDB.radialOff = nil
        addon.radial.Build()
        addon.radial.Apply()
        G.Refresh()
    end)
    m.show:SetPoint("TOPLEFT", 0, -128)
    m.hide = Pill(m, 140, 32, "Masqué", function()
        StreamingTouchDB.radialOff = true
        addon.radial.Apply()
        G.Refresh()
    end)
    m.hide:SetPoint("LEFT", m.show, "RIGHT", 8, 0)
    local home = Pill(m, 200, 32, "Remettre à sa place", function()
        addon.radial.Config().pos = nil
        addon.radial.Apply()
    end)
    home:SetPoint("LEFT", m.hide, "RIGHT", 8, 0)
    Section(m, "Taille du menu rond", 0, -176, 600)
    m.size = Stepper(m, 0, -200, function()
        local cfg = addon.radial.Config()
        cfg.scale = math.max(.5, (cfg.scale or 1) - .1)
        addon.radial.Apply()
        G.Refresh()
    end, function()
        local cfg = addon.radial.Config()
        cfg.scale = math.min(2, (cfg.scale or 1) + .1)
        addon.radial.Apply()
        G.Refresh()
    end, "100 %", function()
        addon.radial.Config().scale = 1
        addon.radial.Apply()
        G.Refresh()
    end)

    -- 4. Sorts : le rond de sorts (affiché ou masqué), sa façon de s'ouvrir et sa place.
    local z = p.pages[4]
    local spells = addon.spells
    local function Armed(button, label, action)
        if not button.armed then
            button.armed = true
            button.text:SetText("Confirmer ?")
            C_Timer.After(3, function() button.armed = nil button.text:SetText(label) end)
            return
        end
        button.armed = nil
        button.text:SetText(label)
        action()
        G.Refresh()
    end
    Section(z, "Rond de sorts", 0, 0, 600)
    local function Place(place)
        local db = StreamingTouchDB
        if place == "off" then
            db.spellRingOff = true
        else
            db.spellRingOff = nil
            spells.Build()
        end
        spells.Apply()
        G.Refresh()
    end
    z.free = Pill(z, 170, 32, "Affiché", function() Place("on") end, "Interface\\Icons\\Spell_Nature_RavenForm")
    z.free:SetPoint("TOPLEFT", 0, -24)
    z.off = Pill(z, 130, 32, "Masqué", function() Place("off") end)
    z.off:SetPoint("LEFT", z.free, "RIGHT", 8, 0)
    local function Mode(open)
        StreamingTouchDB.spellRingOff = nil
        spells.Config().open = open
        spells.Build()
        spells.Apply()
        G.Refresh()
    end
    z.touch = Pill(z, 150, 28, "S'ouvre au toucher", function() Mode("key") end)
    z.touch:SetPoint("TOPLEFT", 0, -62)
    z.fixed = Pill(z, 150, 28, "Toujours affiché", function() Mode("fixed") end)
    z.fixed:SetPoint("LEFT", z.touch, "RIGHT", 8, 0)
    local function Layout(kind)
        spells.Config().layout = kind
        spells.Apply()
        G.Refresh()
    end
    z.mobile = Pill(z, 160, 28, "Autour du joystick", function() Layout("joystick") end)
    z.fan = Pill(z, 90, 28, "Éventail", function() Layout("fan") end)
    z.fan:SetPoint("LEFT", z.mobile, "RIGHT", 6, 0)
    z.round = Pill(z, 90, 28, "En rond", function() Layout("round") end)
    z.round:SetPoint("LEFT", z.fan, "RIGHT", 6, 0)
    z.note = Font(z, "GameFontDisableSmall", "")
    z.note:SetPoint("TOPLEFT", 0, -98)
    z.note:SetWidth(600)
    z.note:SetJustifyH("LEFT")
    local edit = Pill(z, 250, 30, "Modifier les sorts", function()
        G.sub[4] = "edit"
        G.Refresh()
    end, "Interface\\Icons\\Spell_Nature_RavenForm")
    edit:SetPoint("TOPLEFT", 0, -120)
    z.size = Stepper(z, 262, -120, function()
        local cfg = spells.Config()
        cfg.scale = math.max(.5, (cfg.scale or 1) - .1)
        spells.Apply()
        G.Refresh()
    end, function()
        local cfg = spells.Config()
        cfg.scale = math.min(2, (cfg.scale or 1) + .1)
        spells.Apply()
        G.Refresh()
    end, "100 %", function()
        spells.Config().scale = 1
        spells.Apply()
        G.Refresh()
    end)
    local back = Pill(z, 250, 28, "Remettre à sa place", function()
        local cfg = spells.Config()
        cfg.pos, cfg.stickR, cfg.gap, cfg.arrowPos, cfg.arcFrom, cfg.arcTo = nil, nil, nil, nil, nil, nil
        spells.Apply()
        G.Refresh()
    end)
    back:SetPoint("TOPLEFT", 0, -158)
    z.ringAdvice = Pill(z, 200, 28, "Sorts conseillés", function(self)
        Armed(self, "Sorts conseillés", function()
            local cfg = spells.Config()
            local fresh = spells.Fresh()
            cfg.pages, cfg.v = fresh.pages, fresh.v
            spells.ed = {kind = "page", page = 1, mode = "props", cat = 1, actStart = 0, iconStart = 0}
            spells.Apply()
        end)
    end)
    z.ringAdvice:SetPoint("LEFT", back, "RIGHT", 8, 0)
    -- Autour du joystick : caler l'arc sur le joystick CAM, et son écart.
    z.calib = Pill(z, 250, 32, "Caler sur le joystick", function()
        p:Hide()
        spells.Calibrate(function() if not InCombatLockdown() then G.Open(4) end end)
    end, "Interface\\Icons\\Ability_Hunter_SniperShot")
    z.calib:SetPoint("TOPLEFT", 0, -198)
    z.gapLabel = Font(z, "GameFontNormalSmall", "Écart", 1, .82, .32)
    z.gapLabel:SetPoint("TOPLEFT", 270, -207)
    z.gap = Stepper(z, 316, -198, function()
        local cfg = spells.Config()
        cfg.gap = math.max(-40, (tonumber(cfg.gap) or 0) - 8)
        spells.Apply()
        G.Refresh()
    end, function()
        local cfg = spells.Config()
        cfg.gap = math.min(160, (tonumber(cfg.gap) or 0) + 8)
        spells.Apply()
        G.Refresh()
    end)
    -- Début et fin de l'arc : « + » fait glisser le sort dans le sens des aiguilles d'une montre.
    local function Arc(field, delta)
        local cfg = spells.Config()
        local from = tonumber(cfg.arcFrom) or spells.ARC_FROM
        local to = tonumber(cfg.arcTo) or spells.ARC_TO
        if field == "arcFrom" then from = from + delta else to = to + delta end
        if math.abs(to - from) < 20 or math.abs(to - from) > 300 then return end
        cfg.arcFrom, cfg.arcTo = from, to
        spells.Apply()
        G.Refresh()
    end
    z.fromLabel = Font(z, "GameFontNormalSmall", "Début", 1, .82, .32)
    z.fromLabel:SetPoint("TOPLEFT", 0, -247)
    z.from = Stepper(z, 60, -238, function() Arc("arcFrom", 5) end, function() Arc("arcFrom", -5) end)
    z.toLabel = Font(z, "GameFontNormalSmall", "Fin", 1, .82, .32)
    z.toLabel:SetPoint("TOPLEFT", 270, -247)
    z.to = Stepper(z, 316, -238, function() Arc("arcTo", 5) end, function() Arc("arcTo", -5) end)
    z.move = Pill(z, 250, 32, "Déplacer l'arc", function()
        p:Hide()
        spells.StartMove(function() if not InCombatLockdown() then G.Open(4) end end)
    end, "Interface\\Icons\\Ability_Rogue_Sprint")
    z.move:SetPoint("TOPLEFT", 0, -278)
    -- Flèches de page (à côté de l'arc) : affichées ou non. Sans elles : Couche 2 et page de combat.
    z.arrows = Pill(z, 230, 32, "Flèches de page : oui", function()
        local cfg = spells.Config()
        cfg.arrowsOff = not cfg.arrowsOff or nil
        spells.Apply()
        G.Refresh()
    end)
    z.arrows:SetPoint("TOPLEFT", 270, -278)

    -- 5. Chat : place, largeur, lignes, taille du texte, fond.
    local c = p.pages[5]
    local function Chat()
        if addon.PositionChat and not InCombatLockdown() then addon.PositionChat() end
        G.Refresh()
    end
    Section(c, "Petit chat", 0, 0, 600)
    -- Placer au doigt (petit ou grand chat) : les réglages reviennent après le petit ; après le grand,
    -- on le laisse affiché pour le voir.
    local function PlaceChat(arg)
        local slash = SlashCmdList.STREAMINGTOUCHCHAT
        if not slash then return end
        p:Hide()
        slash(arg)
        local placer = _G.StreamingTouchChatPlacer
        if placer and not placer.chReturn then
            placer.chReturn = true
            placer:HookScript("OnHide", function(self)
                if self.stMode ~= "big" and not InCombatLockdown() then G.Open(5) end
            end)
        end
    end
    local place = Pill(c, 230, 34, "Placer au doigt", function() PlaceChat("") end, "Interface\\Icons\\INV_Letter_15")
    place:SetPoint("TOPLEFT", 0, -24)
    c.place = place
    local home = Pill(c, 230, 34, "Remettre comme avant", function()
        local db = StreamingTouchDB
        db.chatPos, db.chatWidth, db.chatRows = nil, nil, nil
        if addon.SetChatBig then addon.SetChatBig(false) end
        Chat()
    end)
    home:SetPoint("LEFT", place, "RIGHT", 8, 0)
    c.home = home
    -- Bouton + / - à côté du chat (grand chat au milieu de l'écran).
    c.sizeKey = Pill(c, 120, 34, "Bouton + : oui", function()
        local db = StreamingTouchDB
        db.chatSizeOff = not db.chatSizeOff or nil
        Chat()
    end)
    c.sizeKey:SetPoint("LEFT", home, "RIGHT", 8, 0)
    c.help = Font(c, "GameFontDisableSmall", "Coin haut gauche du chat au doigt. Bouton + : grand chat au milieu (aussi quand tu écris).")
    c.help:SetPoint("TOPLEFT", 0, -66)
    Section(c, "Largeur", 0, -92, 290)
    c.width = Stepper(c, 0, -116, function()
        local db = StreamingTouchDB
        db.chatWidth = math.max(.5, (tonumber(db.chatWidth) or 1) - .1)
        Chat()
    end, function()
        local db = StreamingTouchDB
        db.chatWidth = math.min(2.5, (tonumber(db.chatWidth) or 1) + .1)
        Chat()
    end)
    Section(c, "Lignes", 310, -92, 290)
    c.rows = Stepper(c, 310, -116, function()
        local db = StreamingTouchDB
        db.chatRows = math.max(2, (db.chatRows or addon.CHAT_ROWS or 4) - 1)
        Chat()
    end, function()
        local db = StreamingTouchDB
        db.chatRows = math.min(15, (db.chatRows or addon.CHAT_ROWS or 4) + 1)
        Chat()
    end)
    -- Taille du texte et fond : réglages du jeu lui-même, pour toutes les fenêtres de chat.
    local function Frames()
        local list = {}
        for i = 1, NUM_CHAT_WINDOWS or 10 do
            local f = _G["ChatFrame" .. i]
            if f then list[#list + 1] = f end
        end
        return list
    end
    local function TextSize(delta)
        if not ChatFrame1 or not ChatFrame1.GetFont then return end
        local size = math.floor((select(2, ChatFrame1:GetFont()) or 14) + .5) + delta
        size = math.max(8, math.min(24, size))
        for _, f in ipairs(Frames()) do
            if FCF_SetChatWindowFontSize then
                pcall(FCF_SetChatWindowFontSize, nil, f, size)
            else
                local font, _, flags = f:GetFont()
                if font then f:SetFont(font, size, flags) end
            end
        end
        Chat()
    end
    local function Alpha(delta)
        local alpha = GetChatWindowInfo and select(6, GetChatWindowInfo(1)) or .25
        alpha = math.max(0, math.min(1, math.floor(((tonumber(alpha) or .25) + delta) * 10 + .5) / 10))
        for _, f in ipairs(Frames()) do
            if FCF_SetWindowAlpha then pcall(FCF_SetWindowAlpha, f, alpha) end
        end
        G.chatAlpha = alpha
        G.Refresh()
    end
    Section(c, "Taille du texte", 0, -164, 290)
    c.font = Stepper(c, 0, -188, function() TextSize(-1) end, function() TextSize(1) end)
    Section(c, "Fond du chat", 310, -164, 290)
    c.alpha = Stepper(c, 310, -188, function() Alpha(-.1) end, function() Alpha(.1) end)
    -- Grand chat : bouton + à côté du chat, et pendant qu'on écrit.
    Section(c, "Grand chat (bouton + et quand tu écris)", 0, -236, 600)
    local bigPlace = Pill(c, 230, 34, "Placer au doigt", function() PlaceChat("grand") end, "Interface\\Icons\\INV_Letter_15")
    bigPlace:SetPoint("TOPLEFT", 0, -260)
    local middle = Pill(c, 230, 34, "Au milieu", function()
        local db = StreamingTouchDB
        db.bigPos, db.bigWidth, db.bigRows = nil, nil, nil
        Chat()
    end)
    middle:SetPoint("LEFT", bigPlace, "RIGHT", 8, 0)
    Section(c, "Largeur", 0, -306, 290)
    c.bigWidth = Stepper(c, 0, -330, function()
        local db = StreamingTouchDB
        db.bigWidth = math.max(.6, (tonumber(db.bigWidth) or 1) - .1)
        Chat()
    end, function()
        local db = StreamingTouchDB
        db.bigWidth = math.min(1.5, (tonumber(db.bigWidth) or 1) + .1)
        Chat()
    end)
    Section(c, "Lignes", 310, -306, 290)
    c.bigRows = Stepper(c, 310, -330, function()
        local db = StreamingTouchDB
        db.bigRows = math.max(4, (db.bigRows or addon.BIG_ROWS or 14) - 1)
        Chat()
    end, function()
        local db = StreamingTouchDB
        db.bigRows = math.min(24, (db.bigRows or addon.BIG_ROWS or 14) + 1)
        Chat()
    end)
    if addon.barre then addon.barre.BuildSettings(p.pages[6], G) end
    for k, extra in ipairs(addon.extraTabs or {}) do
        local page = p.pages[6 + k]
        page.tabIndex = 6 + k
        pcall(extra.build, page, G)
    end
end

function G.Refresh()
    local commandes = G.panel and G.panel.pages and G.panel.pages[1]
    if commandes and commandes.modele then
        local m = addon.Modele and addon.Modele()
        commandes.modele:SetText(m and ("Modèle : " .. (m.source or "?")) or "Aucun modèle enregistré pour l'instant.")
    end
    local p = G.panel
    if not p or not p:IsShown() then return end
    for i, b in ipairs(p.tabs) do b:Paint(i == G.tab) end
    for i, page in ipairs(p.pages) do
        local editing = G.editors[i] and G.sub[i] == "edit" or false
        page:SetShown(i == G.tab and not editing)
        if p.edits[i] then p.edits[i]:SetShown(i == G.tab and editing) end
        if p.subbars[i] then
            p.subbars[i]:SetShown(i == G.tab)
            p.subbars[i].view:Paint(not editing)
            p.subbars[i].edit:Paint(editing)
        end
    end
    for i, R in pairs(G.editors) do
        if i == G.tab and G.sub[i] == "edit" then
            R.Config()
            R.Dock(p.edits[i])
            R.editor:Show()
            R.RefreshEditor()
        elseif R.editor and R.editor.dock and R.editor:IsShown() then
            R.editor:Hide()
        end
    end
    local db = StreamingTouchDB or {}
    local a = p.pages[1]
    for _, b in ipairs(a.toggles) do
        local on = not db[b.field]
        b.text:SetText(b.label .. (on and " : oui" or " : non"))
        b:Paint(on)
    end

    local s = p.pages[2]
    local group, cfg = S.Current()
    for i, b in ipairs(s.groups) do b:Paint(i == S.group) end
    local list = group.list()
    s.title:SetText(group.name)
    s.count:SetText(#list == 0 and "Pas affichés en ce moment" or (#list .. " boutons"))
    for i, tile in ipairs(s.previews) do
        local b = list[i]
        local icon = b and (b.icon or (b:GetName() and _G[b:GetName() .. "Icon"]))
        local texture = icon and icon:GetTexture() or "Interface\\Icons\\INV_Misc_QuestionMark"
        addon.radial.Paint(tile, 50, texture, cfg.shape == "origine" and "aucun" or cfg.color, cfg.shape == "rond" and "round" or "square", "")
        tile:SetAlpha(cfg.alpha or 1)
    end
    for i, b in ipairs(s.shapes) do b:Paint(S.SHAPES[i][1] == cfg.shape) end
    for _, w in ipairs(s.swatches) do w.sel:SetShown(w.key == cfg.color) end
    s.size:SetText(Percent(cfg.size))
    s.alpha:SetText(Percent(cfg.alpha))
    s.hotkey.text:SetText(cfg.hotkey and "Raccourci : oui" or "Raccourci : non")
    s.name.text:SetText(cfg.name and "Nom macro : oui" or "Nom macro : non")
    s.hotkey:Paint(cfg.hotkey)
    s.name:Paint(cfg.name)

    local m = p.pages[3]
    m.show:Paint(not db.radialOff)
    m.hide:Paint(db.radialOff and true or false)
    m.size:SetText(Percent(addon.radial.Config().scale))

    local z = p.pages[4]
    local spellCfg = addon.spells.Config()
    local off = db.spellRingOff and true or false
    z.free:Paint(not off)
    z.off:Paint(off)
    z.touch:Paint(not off and spellCfg.open ~= "fixed")
    local fixedNow = not off and spellCfg.open == "fixed"
    local layout = spellCfg.layout
    local isMobile = layout == nil or layout == "joystick" or layout == "mobile" or layout == "arc"
    z.mobile:ClearAllPoints()
    z.mobile:SetPoint("TOPLEFT", 314, -62)
    local hug = fixedNow and isMobile
    for _, w in ipairs({z.calib, z.gapLabel, z.gap, z.gap.minus, z.gap.plus, z.fromLabel, z.from, z.from.minus,
        z.from.plus, z.toLabel, z.to, z.to.minus, z.to.plus, z.move}) do w:SetShown(hug) end
    local gap = tonumber(spellCfg.gap) or 0
    z.gap:SetText((gap > 0 and "+" or "") .. gap)
    local sp = addon.spells
    for _, e in ipairs({{z.from, spellCfg.arcFrom, sp.ARC_FROM}, {z.to, spellCfg.arcTo, sp.ARC_TO}}) do
        local v = math.floor(e[3] - (tonumber(e[2]) or e[3]) + .5)
        e[1]:SetText((v > 0 and "+" or "") .. v .. "°")
    end
    for _, b in ipairs({z.mobile, z.fan, z.round}) do b:SetShown(fixedNow) end
    z.mobile:Paint(isMobile)
    z.fan:Paint(layout == "fan")
    z.round:Paint(layout == "round")
    z.fixed:Paint(not off and spellCfg.open == "fixed")
    z.arrows:SetShown(fixedNow)
    z.arrows.text:SetText(spellCfg.arrowsOff and "Flèches de page : non" or "Flèches de page : oui")
    z.arrows:Paint(not spellCfg.arrowsOff)
    z.note:SetText(off and "Le rond de sorts n'est plus à l'écran."
        or hug and "Autour du joystick CAM. Flèches : page précédente / suivante ; glisse une flèche pour la mettre où tu veux. « Caler sur le joystick » : son cercle, puis ton premier et ton dernier sort."
        or spellCfg.open == "fixed" and "Les sorts restent autour du bouton Sorts : touche-le pour passer à la page suivante."
        or "Touche le bouton Sorts pour ouvrir le rond, touche un sort pour le lancer.")
    z.size:SetText(Percent(spellCfg.scale))
    local c = p.pages[5]
    c.width:SetText(Percent(tonumber(db.chatWidth) or 1))
    c.rows:SetText(tostring(db.chatRows or addon.CHAT_ROWS or 4))
    c.sizeKey.text:SetText(db.chatSizeOff and "Bouton + : non" or "Bouton + : oui")
    c.sizeKey:Paint(not db.chatSizeOff)
    c.bigWidth:SetText(Percent(tonumber(db.bigWidth) or 1))
    c.bigRows:SetText(tostring(db.bigRows or addon.BIG_ROWS or 14))
    local size = ChatFrame1 and ChatFrame1.GetFont and select(2, ChatFrame1:GetFont())
    c.font:SetText(size and tostring(math.floor(size + .5)) or "-")
    local alpha = G.chatAlpha or (GetChatWindowInfo and select(6, GetChatWindowInfo(1)))
    c.alpha:SetText(alpha and Percent(alpha) or "-")
    if addon.barre then addon.barre.RefreshSettings(p.pages[6]) end
    for k, extra in ipairs(addon.extraTabs or {}) do pcall(extra.refresh, p.pages[6 + k]) end
end

function G.Open(tab)
    if InCombatLockdown() then print("|cffe8c46aStreaming Touch|r : réglages hors combat.") return end
    if not G.panel then G.Build() end
    G.tab = tab or G.tab
    local p = G.panel
    p:SetSize(700, 580)
    p:SetScale(math.min(1, UIParent:GetHeight() * .96 / 580, UIParent:GetWidth() * .96 / 700))
    G.chatAlpha = nil
    p:Show()
    G.Refresh()
end

-- Ouvre l'éditeur d'un rond (menu ou sorts) directement dans les réglages.
function G.OpenEdit(R)
    for i, inst in pairs(G.editors) do
        if inst == R then
            G.sub[i] = "edit"
            G.Open(i)
            return G.panel and G.panel:IsShown()
        end
    end
end

function G.Toggle()
    if G.panel and G.panel:IsShown() then G.panel:Hide() else G.Open() end
end

-- « Boutons du jeu » s'ouvre maintenant dans ce menu.
S.Open = function() G.Open(4) end
S.Refresh = function() G.Refresh() end
end

-- ==== Grimoire : pour chaque nom de sort, le plus haut rang appris ====
-- L'arc s'en sert pour cacher les sorts pas encore appris et lancer toujours le meilleur rang.
do
local B = {}
addon.book = B
local function Rank(text) return tonumber(tostring(text or ""):match("(%d+)")) or 0 end
function B.Subtext(id)
    local read = (C_Spell and C_Spell.GetSpellSubtext) or GetSpellSubtext
    if not read or not id then return end
    local ok, text = pcall(read, id)
    if ok then return text end
end
function B.Scan()
    local book, count = {}, 0
    local function Keep(name, id, rank)
        if not name or not id then return end
        count = count + 1
        local best = book[name]
        if not best or rank >= best.rank then book[name] = {id = id, rank = rank} end
    end
    WalkBook(false, function(e)
        if e.hiddenTab or e.offTab then return end
        if e.kind == "spell" and not (e.modern and (e.passive or e.offSpec)) then
            local sub = e.sub
            if not sub or sub == "" then sub = B.Subtext(e.id) end
            Keep(e.name, e.id, Rank(sub))
        elseif e.kind == "flyout" then
            for _, s in ipairs(FlyoutSpells(e.id)) do Keep(s.label, s.spell, Rank(B.Subtext(s.spell))) end
        end
    end)
    B.petNames = {}
    for _, pet in ipairs(PetSpells()) do
        Keep(pet.label, pet.spell, Rank(type(pet.spell) == "number" and B.Subtext(pet.spell) or nil))
        B.petNames[pet.label] = true
    end
    B.book, B.bookCount = book, count
end
function B.Best(spell)
    local name = type(spell) == "string" and spell or SpellName(spell)
    local entry = name and B.book and B.book[name]
    return entry and entry.id
end
end
