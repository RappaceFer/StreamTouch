-- Streaming Touch 2 : le cœur de l'addon. Écrit pour Streaming Touch, licence MIT (voir LICENSE.txt).
-- Ici : les réglages enregistrés, le bouton de la mini-carte, /stouch, et trois petits modules qui se coupent
-- chacun dans /stouch, onglet Commandes :
--   • pas de côté : gauche et droite du joystick décalent le personnage au lieu de le faire tourner ;
--   • cadavre : le bouton Target de l'appli, maintenu, vise le cadavre à fouiller devant toi (touche F10) ;
--   • chat : sa place et sa taille, et sa ligne de saisie qui monte au-dessus du clavier du téléphone.
-- Et les barres du jeu, cachées au choix (barres d'action, familier et postures, micro-menu, sacs).
-- L'arc de sorts, le menu rond et la fenêtre de réglages sont dans Radial.lua.
local _, ST = ...
ST.enabled = true
ST.CHAT_ROWS = 4

local function DB()
    StreamingTouchDB = StreamingTouchDB or {}
    return StreamingTouchDB
end
local function Note(text) print("|cffe8c46aStreaming Touch|r : " .. text) end
ST.DB, ST.Note = DB, Note

-- ===== Profil du compte : des réglages de base communs à tous tes personnages ==============
-- StreamingTouchAccount (enregistré pour le compte entier) garde un modèle : tous les réglages généraux,
-- plus l'arc de sorts de chaque classe enregistrée. Un nouveau personnage le prend à sa première connexion ;
-- un personnage déjà réglé le prend avec le bouton de /stouch, onglet Commandes.
do
    local function Copie(v)
        if type(v) ~= "table" then return v end
        local t = {}
        for k, x in pairs(v) do t[k] = Copie(x) end
        return t
    end
    local function Classe() return select(2, UnitClass("player")) or "?" end
    function ST.Modele()
        local compte = StreamingTouchAccount
        if type(compte) == "table" and type(compte.general) == "table" then return compte end
        -- Pas de modèle enregistré : les réglages de base livrés avec l'addon (Defaults.lua).
        return type(ST.DEFAUT) == "table" and ST.DEFAUT or nil
    end
    function ST.EnregistrerModele()
        if type(StreamingTouchAccount) ~= "table" then StreamingTouchAccount = {} end
        local compte, db = StreamingTouchAccount, DB()
        compte.general = {}
        for k, v in pairs(db) do if k ~= "spellRing" then compte.general[k] = Copie(v) end end
        compte.classes = compte.classes or {}
        if type(db.spellRing) == "table" then
            compte.classes[Classe()] = Copie(db.spellRing)
            -- La disposition de l'arc seule (taille, place, forme), pour les classes sans modèle de sorts.
            compte.arc = Copie(db.spellRing)
            compte.arc.pages = nil
        end
        compte.source = (UnitName("player") or "?") .. ", " .. date("%d/%m/%Y")
        Note("réglages enregistrés comme modèle pour tes autres personnages.")
    end
    -- Remplace les réglages de ce personnage par le modèle : sorts de sa classe, sinon la disposition de l'arc.
    function ST.PrendreModele()
        local compte = ST.Modele()
        if not compte then return false end
        local db = {}
        for k, v in pairs(compte.general) do db[k] = Copie(v) end
        local sorts = type(compte.classes) == "table" and compte.classes[Classe()]
        if sorts then db.spellRing = Copie(sorts) elseif compte.arc then db.spellRing = Copie(compte.arc) end
        StreamingTouchDB = db
        return true
    end
    -- Partage : tous les réglages de ce personnage en texte (Partage.lua), et l'inverse.
    function ST.Exporter()
        return ST.Encoder({v = 1, nom = UnitName("player"), classe = Classe(), db = DB()})
    end
    -- Remplace les réglages de ce personnage. Texte d'une autre classe : on garde la disposition de l'arc,
    -- ses sorts repartent de ceux conseillés pour la classe (comme le profil du compte).
    function ST.Importer(texte)
        local data, err = ST.Decoder(texte)
        if not data then return false, err end
        if type(data) ~= "table" or type(data.db) ~= "table" then return false, "ce n'est pas un texte de réglages" end
        local db = Copie(data.db)
        if data.classe ~= Classe() and type(db.spellRing) == "table" then db.spellRing.pages = nil end
        StreamingTouchDB = db
        return true, data.nom
    end
    local depart = CreateFrame("Frame")
    depart:RegisterEvent("ADDON_LOADED")
    depart:SetScript("OnEvent", function(self, _, nom)
        if nom ~= "StreamingTouch" then return end
        self:UnregisterEvent("ADDON_LOADED")
        -- Aucun réglage enregistré pour ce personnage : c'est sa première connexion avec l'addon.
        ST.nouveauPerso = (StreamingTouchDB == nil or next(StreamingTouchDB) == nil) and ST.Modele() ~= nil
    end)
end

-- Clés laissées par la version 1 (taille forcée, roue d'actions, ancienne place du chat…) : on fait le ménage une fois.
local OLD_KEYS = {"touchScale", "modeScale", "originalRootScale", "cvars", "chat", "wheelOn", "wheelDX", "wheelDY",
    "wheelScale", "wheelNine", "wheelSpells", "wheelBackup", "wheelRestoreOnce", "petBarHidden", "petBarSeen",
    "spellPlace", "spellPlaceSeen", "spellRingSeen", "actionBars", "petDump", "petClicks", "blocked"}
local function Tidy()
    local db = DB()
    if db.v2 then return end
    for _, key in ipairs(OLD_KEYS) do db[key] = nil end
    db.v2 = true
end

-- ===== Touches : pas de côté et cadavre ===================================================
-- Des raccourcis posés par-dessus ceux du joueur, le temps de la session : ses propres réglages ne bougent pas.
local keys = CreateFrame("Frame", "StreamingTouchKeys")
local corpse = CreateFrame("Button", "StreamingTouchCorpse", UIParent, "SecureActionButtonTemplate")
corpse:SetSize(1, 1)
corpse:SetPoint("BOTTOMLEFT")
corpse:RegisterForClicks("AnyDown", "AnyUp")
for field, value in pairs({type = "macro", macrotext = "/target [@softinteract,dead]"}) do corpse:SetAttribute(field, value) end
corpse:HookScript("PostClick", function(_, _, down)
    if down then return end
    if not (UnitExists("target") and UnitIsDead("target")) then
        Note("pas de cadavre devant toi : approche-toi, tourne-toi vers lui, puis maintiens Target.")
    end
end)
ST.corpse = corpse

function ST.ApplyKeys()
    if InCombatLockdown() then ST.keysPending = true return end
    ST.keysPending = nil
    local db = DB()
    ClearOverrideBindings(keys)
    if not db.strafeOff then
        SetOverrideBinding(keys, false, "A", "STRAFELEFT")
        SetOverrideBinding(keys, false, "D", "STRAFERIGHT")
    end
    if not db.corpseOff then SetOverrideBindingClick(keys, false, "F10", corpse:GetName(), "LeftButton") end
end

-- ===== Barres du jeu : cachées au choix ===================================================
-- Une barre cachée part dans un cadre invisible : le jeu peut la remontrer, elle reste hors de vue.
-- Le micro-menu, lui, devient seulement transparent : le menu rond ouvre les fenêtres par ses boutons.
-- Hors combat seulement (les barres d'action sont protégées) ; en combat, on attend la fin.
local vault = CreateFrame("Frame")
vault:Hide()
local homes = {}
ST.BAR_GROUPS = {
    {field = "barsShown", names = {"MainActionBar", "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight",
        "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7"}},
    {field = "petStanceShown", names = {"PetActionBar", "PetActionBarFrame", "StanceBar", "StanceBarFrame"}},
    {field = "microShown", names = {"MicroMenuContainer"}, fade = true},
    {field = "bagsShown", names = {"BagsBar", "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot",
        "CharacterBag2Slot", "CharacterBag3Slot", "CharacterReagentBag0Slot", "BagBarExpandToggle"}},
}
local function Mouse(frame, on, depth)
    if frame.EnableMouse then pcall(frame.EnableMouse, frame, on) end
    if (depth or 0) < 2 and frame.GetChildren then
        for _, child in ipairs({frame:GetChildren()}) do Mouse(child, on, (depth or 0) + 1) end
    end
end
function ST.ApplyBars()
    if InCombatLockdown() then ST.barsPending = true return end
    ST.barsPending = nil
    local db = DB()
    for _, group in ipairs(ST.BAR_GROUPS) do
        local hide = not db[group.field]
        local frames = {}
        for _, name in ipairs(group.names) do
            local frame = _G[name]
            if type(frame) == "table" and frame.SetParent then frames[#frames + 1] = frame end
        end
        if group.fade and #frames == 0 and type(MICRO_BUTTONS) == "table" then
            for _, name in ipairs(MICRO_BUTTONS) do
                if type(_G[name]) == "table" then frames[#frames + 1] = _G[name] end
            end
        end
        for _, frame in ipairs(frames) do
            if group.fade then
                frame:SetAlpha(hide and 0 or 1)
                Mouse(frame, not hide)
            elseif hide and frame:GetParent() ~= vault then
                homes[frame] = frame:GetParent() or UIParent
                pcall(frame.SetParent, frame, vault)
            elseif not hide and frame:GetParent() == vault then
                pcall(frame.SetParent, frame, homes[frame] or UIParent)
            end
        end
    end
end
ST.barVault = vault

-- ===== Chat : petit, grand, ligne de saisie ===============================================
-- Petit chat : en bas à gauche, ou là où le joueur l'a mis (/stouch, onglet Chat).
-- Grand chat : au milieu de l'écran, avec le bouton + à côté du chat, ou le temps d'écrire
-- (la ligne de saisie monte en haut, le chat grandit juste dessous, au-dessus du clavier du téléphone).
local moving, moved = false, false
local big, typing, sizeKey = false, nil, nil
local raised = {}
local function Settled() local db = DB() return db.chatPos or db.chatWidth or db.chatRows end
local function LineHeight()
    local size = ChatFrame1 and ChatFrame1.GetFont and select(2, ChatFrame1:GetFont())
    return (tonumber(size) or 14) * 1.25
end
local function Rows(n) return LineHeight() * n + 8 end
local function Large() return big or typing ~= nil end
local function Managed() return Settled() or Large() end

-- Grand chat : sa largeur (réglable) et son bord gauche (au milieu, ou là où le joueur l'a mis).
ST.BIG_ROWS = 14
local function BigBox()
    local db = DB()
    local screenW = UIParent:GetWidth()
    local width = math.min(screenW * .9, math.min(620, screenW * .6) * (tonumber(db.bigWidth) or 1))
    local pos = db.bigPos
    if pos and pos.x then return width, math.max(0, math.min(screenW - width, pos.x)), true end
    return width, (screenW - width) / 2, false
end

-- Sa place : point, point d'UIParent, décalages, largeur, hauteur.
local function ChatSpot()
    local db = DB()
    if Large() then
        local screenH = UIParent:GetHeight()
        local width, left = BigBox()
        local top, limit = screenH * .22, screenH - 12
        local pos = db.bigPos
        if pos and pos.y then top = math.max(0, screenH - pos.y) end
        -- En écrivant : juste sous la ligne de saisie montée, au-dessus du clavier du téléphone.
        if typing then top, limit = screenH * .12 + 64, screenH * .46 end
        local height = math.max(Rows(3), math.min(Rows(db.bigRows or ST.BIG_ROWS), limit - top))
        return "TOPLEFT", "TOPLEFT", left, -top, width, height
    end
    local width, height = 430 * (tonumber(db.chatWidth) or 1), Rows(db.chatRows or ST.CHAT_ROWS)
    local pos = db.chatPos
    if pos and pos.x and pos.y then return "TOPLEFT", "BOTTOMLEFT", pos.x, pos.y, width, height end
    return "BOTTOMLEFT", "BOTTOMLEFT", 40, 90, width, height
end

-- Bouton rond + / - à droite des onglets du chat.
local function SizeKey()
    if sizeKey then return sizeKey end
    sizeKey = CreateFrame("Button", "StreamingTouchChatSize", UIParent)
    sizeKey:SetSize(30, 30)
    sizeKey:SetFrameStrata("MEDIUM")
    if sizeKey.SetHitRectInsets then sizeKey:SetHitRectInsets(-9, -9, -9, -9) end
    local rim = sizeKey:CreateTexture(nil, "BACKGROUND")
    rim:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    rim:SetVertexColor(1, .82, .32, .95)
    rim:SetAllPoints()
    local face = sizeKey:CreateTexture(nil, "BORDER")
    face:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    face:SetVertexColor(.03, .07, .15, .9)
    face:SetPoint("CENTER")
    face:SetSize(26, 26)
    sizeKey.label = sizeKey:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sizeKey.label:SetPoint("CENTER", 0, 1)
    sizeKey:SetScript("OnClick", function() ST.SetChatBig(not Large()) end)
    return sizeKey
end
function ST.PlaceSizeKey()
    local chat = ChatFrame1
    if chat == nil then return end
    local key = SizeKey()
    if DB().chatSizeOff then
        key:Hide()
        return
    end
    key:ClearAllPoints()
    key:SetPoint("BOTTOMLEFT", chat, "TOPRIGHT", 8, 2)
    key.label:SetText(Large() and "-" or "+")
    key:Show()
end

function ST.PositionChat()
    local chat = ChatFrame1
    if not chat then return end
    if InCombatLockdown() and chat.IsProtected and chat:IsProtected() then return end
    if not Managed() then
        if moved and FCF_RestorePositionAndDimensions then pcall(FCF_RestorePositionAndDimensions, chat) end
        moved = false
        ST.PlaceSizeKey()
        return
    end
    moving = true
    local point, rel, x, y, width, height = ChatSpot()
    pcall(function()
        -- Le gestionnaire de cadres du jeu ne le replace plus derrière nous (une fois, hors combat).
        if chat.BreakFromFrameManager and not ST.chatFree and not InCombatLockdown() then
            ST.chatFree = true
            chat:BreakFromFrameManager()
        end
        chat:ClearAllPoints()
        chat:SetPoint(point, UIParent, rel, x, y)
        chat:SetSize(width, height)
    end)
    moving, moved = false, true
    ST.PlaceSizeKey()
end

-- Grand ou petit chat (bouton + / -). Petit pendant qu'on écrit : la saisie se ferme.
function ST.SetChatBig(on)
    big = on and true or false
    if not big and typing then
        local box = typing
        if ChatFrameUtil and ChatFrameUtil.DeactivateChat then pcall(ChatFrameUtil.DeactivateChat, box)
        elseif ChatEdit_DeactivateChat then pcall(ChatEdit_DeactivateChat, box) end
    end
    ST.PositionChat()
end

-- Garde : à la connexion (ou par le mode édition), le jeu peut replacer le chat sans passer par SetPoint.
-- Chaque seconde, hors combat : s'il n'est plus à sa place, on le remet.
local function Misplaced()
    local chat = ChatFrame1
    if chat:GetNumPoints() ~= 1 then return true end
    local point, to, rel, x, y = chat:GetPoint(1)
    local wantPoint, wantRel, wantX, wantY = ChatSpot()
    return point ~= wantPoint or to ~= UIParent or rel ~= wantRel
        or math.abs((tonumber(x) or 0) - wantX) > 1 or math.abs((tonumber(y) or 0) - wantY) > 1
end
local guard = CreateFrame("Frame")
ST.chatGuard = guard
local since = 0
guard:SetScript("OnUpdate", function(_, elapsed)
    since = since + (elapsed or 0)
    if since < 1 then return end
    since = 0
    if moving or not ChatFrame1 or not Managed() or InCombatLockdown() then return end
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return end
    local ok, wrong = pcall(Misplaced)
    if ok and wrong then ST.PositionChat() end
end)

-- Quand tu écris : la ligne de saisie monte en haut de l'écran, le chat grandit juste dessous.
local function Lift(box)
    if not box or DB().chatRaiseOff then return end
    if not raised[box] then
        local points = {}
        for i = 1, box:GetNumPoints() do points[i] = {box:GetPoint(i)} end
        raised[box] = {points = points, width = box:GetWidth()}
    end
    typing = box
    -- Même largeur et même bord que le grand chat juste dessous.
    local width, left, placed = BigBox()
    box:ClearAllPoints()
    if placed then
        box:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, -UIParent:GetHeight() * .12)
    else
        box:SetPoint("TOP", UIParent, "TOP", 0, -UIParent:GetHeight() * .12)
    end
    box:SetWidth(width)
    ST.PositionChat()
end
local function Drop(box)
    local was = box and raised[box]
    if not was then return end
    raised[box] = nil
    box:ClearAllPoints()
    for _, point in ipairs(was.points) do box:SetPoint(unpack(point)) end
    if was.width and was.width > 0 then box:SetWidth(was.width) end
    if typing == box then typing = nil end
    ST.PositionChat()
end
ST.LiftChatInput, ST.DropChatInput = Lift, Drop

local hooked = false
local function HookChat()
    if hooked then return end
    hooked = true
    local util = ChatFrameUtil
    if util and util.ActivateChat and util.DeactivateChat then
        hooksecurefunc(util, "ActivateChat", Lift)
        hooksecurefunc(util, "DeactivateChat", Drop)
    elseif type(ChatEdit_ActivateChat) == "function" then
        hooksecurefunc("ChatEdit_ActivateChat", Lift)
        hooksecurefunc("ChatEdit_DeactivateChat", Drop)
    end
    -- Le jeu (ou son mode édition) peut replacer le chat : on remet le nôtre juste après.
    if ChatFrame1 then
        hooksecurefunc(ChatFrame1, "SetPoint", function()
            if not moving and Managed() then C_Timer.After(0, ST.PositionChat) end
        end)
    end
end

-- Placer au doigt : on touche l'écran là où va le coin haut gauche du chat, ou du grand chat (Échap pour annuler).
local placer
local function Placer()
    if placer then return placer end
    placer = CreateFrame("Button", "StreamingTouchChatPlacer", UIParent)
    placer:SetAllPoints(UIParent)
    placer:SetFrameStrata("FULLSCREEN_DIALOG")
    placer:RegisterForClicks("AnyUp")
    local shade = placer:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints()
    shade:SetColorTexture(0, 0, 0, .45)
    placer.text = placer:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    placer.text:SetPoint("CENTER")
    placer:SetScript("OnClick", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        local spot = {x = x / scale, y = y / scale}
        self:Hide()
        if self.stMode == "big" then
            DB().bigPos = spot
            ST.SetChatBig(true)
        else
            DB().chatPos = spot
            ST.PositionChat()
        end
    end)
    tinsert(UISpecialFrames, "StreamingTouchChatPlacer")
    placer:Hide()
    return placer
end
SLASH_STREAMINGTOUCHCHAT1 = "/stchat"
-- /stchat : le petit chat ; /stchat grand : le grand chat.
SlashCmdList.STREAMINGTOUCHCHAT = function(arg)
    if InCombatLockdown() then Note("le chat se place hors combat.") return end
    local p = Placer()
    p.stMode = string.find(string.lower(tostring(arg or "")), "grand") and "big" or nil
    p.text:SetText("Touche l'écran là où tu veux le coin haut gauche " .. (p.stMode and "du grand chat" or "du chat")
        .. ".\nÉchap pour annuler.")
    p:Show()
end

-- Après un réglage : le chat reprend sa place.
function ST.Relayout() pcall(ST.PositionChat) end

-- ===== Bouton de la mini-carte ============================================================
local mini = CreateFrame("Button", "StreamingTouchMinimapButton", Minimap)
mini:SetSize(31, 31)
mini:SetFrameStrata("MEDIUM")
mini:SetFrameLevel(8)
mini:RegisterForClicks("AnyUp")
mini:RegisterForDrag("LeftButton")
mini:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
mini.icon = mini:CreateTexture(nil, "BACKGROUND")
mini.icon:SetTexture("Interface\\AddOns\\StreamingTouch\\Media\\Icon")
mini.icon:SetSize(22, 22)
mini.icon:SetPoint("CENTER", 0, 1)
mini.rim = mini:CreateTexture(nil, "OVERLAY")
mini.rim:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mini.rim:SetSize(53, 53)
mini.rim:SetPoint("TOPLEFT")
ST.minimapButton = mini

local function PlaceMini()
    local angle = math.rad(tonumber(DB().minimapAngle) or 215)
    local radius = (Minimap:GetWidth() or 140) / 2 + 10
    mini:ClearAllPoints()
    mini:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end
function ST.ShowMinimapButton()
    PlaceMini()
    mini:SetShown(not DB().minimapOff)
end
mini:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local cx, cy = Minimap:GetCenter()
        local x, y = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        DB().minimapAngle = math.deg(math.atan2(y / scale - cy, x / scale - cx))
        PlaceMini()
    end)
end)
mini:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
mini:SetScript("OnClick", function() ST.OpenSettings() end)
mini:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Streaming Touch")
    GameTooltip:AddLine("Réglages tactiles. Glisse pour déplacer ce bouton.", 1, 1, 1)
    GameTooltip:Show()
end)
mini:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ===== Réglages : /stouch, /reglages ======================================================
function ST.OpenSettings()
    local panel = ST.settings
    if panel and panel.Toggle then panel.Toggle() else Note("réglages indisponibles.") end
end
SLASH_STREAMINGTOUCHOPTIONS1 = "/stouch"
SLASH_STREAMINGTOUCHOPTIONS2 = "/reglages"
SlashCmdList.STREAMINGTOUCHOPTIONS = function() ST.OpenSettings() end

-- ===== Évènements ===========================================================================
local events = CreateFrame("Frame")
ST.events = events
-- Après un chargement d'écran ou le mode Édition : le chat et les barres reprennent leur état.
local function Settle()
    ST.PositionChat()
    ST.ApplyBars()
end
for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "EDIT_MODE_LAYOUTS_UPDATED"}) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if ST.nouveauPerso and ST.PrendreModele() then Note("nouveau personnage : tes réglages de compte sont appliqués.") end
        ST.nouveauPerso = nil
        Tidy()
        ST.ApplyKeys()
        ST.ShowMinimapButton()
        HookChat()
        ST.PositionChat()
        ST.ApplyBars()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ST.keysPending then ST.ApplyKeys() end
        if ST.barsPending then ST.ApplyBars() end
    else
        C_Timer.After(0, Settle)
    end
end)
