-- Streaming Touch (licence MIT, voir LICENSE.txt).
-- Cadres des personnages (2.7) : joueur, familier, cible, cible de la cible et groupe, en trois styles
-- (Compact, Bandeaux, Classique), chacun déplaçable au doigt et à la taille voulue. Ils remplacent ceux du jeu.
-- Boutons sécurisés : toucher un cadre cible le personnage, même en combat ; clic droit : son menu.
local _, addon = ...
if not addon or not addon.enabled then return end

local WHITE = "Interface\\Buttons\\WHITE8X8"
local CIRCLE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local BAR = "Interface\\TargetingFrame\\UI-StatusBar"
local function Say(text) print("|cffe8c46aStreaming Touch|r : " .. text) end
local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) or false end

local C = {frames = {}, byKey = {}, overlays = {}}
addon.cadres = C
C.STYLES = {{"compact", "Compact"}, {"bandeaux", "Bandeaux"}, {"classique", "Classique"}}
C.TEXTS = {{"pct", "%"}, {"val", "PV"}, {"both", "PV et %"}, {"non", "Rien"}}
C.PTEXTS = {{"pct", "%"}, {"val", "Points"}, {"both", "Points et %"}, {"non", "Rien"}}
C.UNITS = {
    {key = "player", label = "Joueur", units = {"player"}, pos = {.34, .92}, scale = 1},
    {key = "pet", label = "Familier", units = {"pet"}, pos = {.30, .80}, scale = .75},
    {key = "target", label = "Cible", units = {"target"}, pos = {.62, .92}, scale = 1, auras = true, cast = true},
    {key = "targettarget", label = "Cible de la cible", units = {"targettarget"}, pos = {.80, .86}, scale = .7},
    {key = "party", label = "Groupe", units = {"party1", "party2", "party3", "party4"}, pos = {.14, .66}, scale = .8},
}
for _, d in ipairs(C.UNITS) do C.byKey[d.key] = d end

-- Cadres du jeu remplacés : rangés dans un cadre caché (ils reviennent avec « Recharger »).
local BLIZZ = {
    player = {"PlayerFrame"},
    pet = {"PetFrame"},
    target = {"TargetFrame", "ComboFrame"},
    targettarget = {"TargetFrameToT"},
    party = {"PartyFrame", "CompactPartyFrame", "PartyMemberBackground", "PartyMemberFrame1", "PartyMemberFrame2",
        "PartyMemberFrame3", "PartyMemberFrame4"},
}
C.hidden = CreateFrame("Frame")
C.hidden:Hide()

function C.Config()
    StreamingTouchDB = StreamingTouchDB or {}
    local c = StreamingTouchDB.cadres
    if type(c) ~= "table" then
        c = {style = "classique", text = "pct", units = {}}
        StreamingTouchDB.cadres = c
    end
    if type(c.units) ~= "table" then c.units = {} end
    -- Les effets du jeu (en haut à droite) : cachés au départ, ils sont déjà sous nos cadres.
    if c.hideBuffs == nil then c.hideBuffs = true end
    for _, d in ipairs(C.UNITS) do
        if type(c.units[d.key]) ~= "table" then c.units[d.key] = {} end
    end
    return c
end

function C.Kill(key)
    for _, name in ipairs(BLIZZ[key] or {}) do
        local f = _G[name]
        if f and not C.killed[name] then
            C.killed[name] = true
            if name == "PetFrame" then
                C.ghostPet = true
            else
                pcall(f.UnregisterAllEvents, f)
                pcall(f.Hide, f)
                pcall(f.SetParent, f, C.hidden)
            end
        end
    end
end
C.killed = {}

local function Font(parent, size, flags)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    if STANDARD_TEXT_FONT and fs.SetFont then pcall(fs.SetFont, fs, STANDARD_TEXT_FONT, size, flags or "OUTLINE") end
    if not fs:GetFont() and fs.SetFontObject then fs:SetFontObject("GameFontHighlightSmall") end
    fs:SetShadowOffset(1, -1)
    return fs
end

local function Bar(parent)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetStatusBarTexture(BAR)
    b:SetMinMaxValues(0, 1)
    b:SetValue(1)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetTexture(BAR)
    b.bg:SetAllPoints()
    b.bg:SetVertexColor(.08, .08, .1, .85)
    return b
end

local function Masked(owner, tex)
    local m = owner:CreateMaskTexture()
    m:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m:SetAllPoints(tex)
    tex:AddMaskTexture(m)
    return m
end

-- Effets (améliorations / affaiblissements) sous un cadre. Deux façons, selon ce que le jeu permet :
-- 1. le conteneur d'effets du jeu (récent) : c'est le jeu qui dessine icônes, durées et cumuls, même en combat ;
-- 2. nos propres icônes : le temps restant est compté par le jeu (chiffres du cercle de recharge).
local function NewBlock(f, filter, max, size)
    local b = {filter = filter, max = max, size = size}
    b.frame = CreateFrame("Frame", nil, f)
    b.frame:SetSize(max * (size + 2), size)
    b.icons = {}
    for i = 1, max do
        local a = CreateFrame("Frame", nil, b.frame)
        a:SetSize(size, size)
        a.icon = a:CreateTexture(nil, "ARTWORK")
        a.icon:SetAllPoints()
        a.icon:SetTexCoord(.08, .92, .08, .92)
        a.cd = CreateFrame("Cooldown", nil, a, "CooldownFrameTemplate")
        a.cd:SetAllPoints()
        a.cd:SetReverse(true)
        if a.cd.SetHideCountdownNumbers then a.cd:SetHideCountdownNumbers(false) end
        if a.cd.SetCountdownFont then pcall(a.cd.SetCountdownFont, a.cd, "GameFontHighlightSmallOutline") end
        a.count = Font(a, 9)
        a.count:SetPoint("BOTTOMRIGHT", 2, -1)
        a:Hide()
        b.icons[i] = a
    end
    -- En combat, le jeu cache les effets aux addons : c'est alors son conteneur d'effets qui les dessine
    -- (icône, temps restant, cumuls). Rien ne s'accroche à lui ; il est posé sur nos icônes.
    local ok, cont = pcall(CreateFrame, "AuraContainer", nil, f, "CustomAuraContainerTemplate")
    local rec = {unit = f.unit, filter = filter, created = ok and type(cont) == "table", err = not ok and tostring(cont) or nil}
    if C.diag and C.diag.container then table.insert(C.diag.container, rec) end
    if ok and type(cont) == "table" and cont.AddAuraGroup then
        b.cont = cont
        cont:SetPoint("TOPLEFT", b.frame, "TOPLEFT")
        cont:SetSize(max * (size + 2), size)
        local okU, errU = pcall(cont.SetUnit, cont, f.unit)
        rec.setUnit = okU or tostring(errU)
        local okG, errG = pcall(cont.AddAuraGroup, cont, "st" .. filter, filter, {
            maxFrameCount = max,
            initializeFrame = function(btn)
                rec.buttons = (rec.buttons or 0) + 1
                if not rec.methods then
                    rec.methods = {}
                    for _, m in ipairs({"SetIcon", "SetDurationText", "SetApplicationCount", "SetAuraBorder", "SetCooldown"}) do
                        rec.methods[m] = type(btn[m])
                    end
                end
                pcall(btn.SetSize, btn, size, size)
                local icon = btn:CreateTexture(nil, "ARTWORK")
                icon:SetAllPoints()
                icon:SetTexCoord(.08, .92, .08, .92)
                pcall(btn.SetIcon, btn, icon)
                local time = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
                time:SetPoint("BOTTOM", btn, "BOTTOM", 0, -2)
                if not pcall(btn.SetDurationText, btn, time, {}) then pcall(btn.SetDurationText, btn, time) end
                local count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
                count:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 2, 2)
                if not pcall(btn.SetApplicationCount, btn, count, {}) then
                    pcall(btn.SetApplicationCount, btn, {fontString = count})
                end
            end,
        })
        rec.addGroup = okG or tostring(errG)
        pcall(cont.SetEnabled, cont, true)
        pcall(cont.UpdateAllAuras, cont)
    end
    return b
end

function C.RefreshContainers()
    for _, f in ipairs(C.frames) do
        for _, b in ipairs(f.blocks or {}) do
            if b.cont then
                pcall(b.cont.SetUnit, b.cont, f.unit)
                pcall(b.cont.SetEnabled, b.cont, true)
                pcall(b.cont.UpdateAllAuras, b.cont)
            end
        end
    end
end

-- Hors combat : nos icônes ; en combat : le conteneur du jeu (par transparence, jamais bloqué en combat).
function C.CombatLook()
    local fight = (InCombatLockdown and InCombatLockdown()) or C.fighting
    for _, f in ipairs(C.frames) do
        for _, b in ipairs(f.blocks or {}) do
            if b.cont then
                b.cont:SetAlpha(fight and 1 or 0)
                b.frame:SetAlpha(fight and 0 or 1)
            end
        end
    end
end

function C.UpdateBlock(f, b)
    if b.frame:IsShown() == false then return end
    local unit, shown = f.unit, 0
    for i = 1, 40 do
        if shown >= #b.icons then break end
        local data
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local ok, d = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, b.filter)
            data = ok and d or nil
        end
        if not data then break end
        shown = shown + 1
        local a = b.icons[shown]
        pcall(a.icon.SetTexture, a.icon, data.icon)
        a.count:SetText("")
        pcall(function() if data.applications and data.applications > 1 then a.count:SetText(data.applications) end end)
        a.cd:Hide()
        local done = false
        if C_UnitAuras.GetAuraDuration and a.cd.SetCooldownFromDurationObject and data.auraInstanceID then
            done = pcall(function()
                a.cd:SetCooldownFromDurationObject(C_UnitAuras.GetAuraDuration(unit, data.auraInstanceID))
                a.cd:Show()
            end)
        end
        if not done then
            pcall(function()
                if data.duration and data.duration > 0 then
                    a.cd:SetCooldown(data.expirationTime - data.duration, data.duration)
                    a.cd:Show()
                end
            end)
        end
        a:Show()
    end
    for i = shown + 1, #b.icons do b.icons[i]:Hide() end
    b.count = shown
end

function C.Auras(f)
    local on = C.Config().units[f.def.key].auras ~= false
    if f.blizzAuras then on = false end
    for _, b in ipairs(f.blocks or {}) do
        b.frame:SetShown(on)
        if b.cont then b.cont:SetShown(on) end
        if on then C.UpdateBlock(f, b) end
    end
    if C.fighting then return end
    local side = "LEFT"
    local last, used = f, 0
    for _, b in ipairs(f.blocks or {}) do
        b.frame:ClearAllPoints()
        b.frame:SetPoint("TOP" .. side, last, "BOTTOM" .. side, 0, -3)
        if on and (b.count or 0) > 0 then
            last = b.frame
            used = used + b.size + 3
        end
    end
    if f.cast then
        f.cast:ClearAllPoints()
        f.cast:SetPoint("TOP", f, "BOTTOM", 0, -(used + 6))
    end
end

-- Effets du jeu en haut à droite (BuffFrame) : cachés si on le demande (hors combat).
function C.GameBuffs()
    if InCombatLockdown() then C.pending = true return end
    local hide = C.Config().on and C.Config().hideBuffs
    for _, name in ipairs({"BuffFrame", "DebuffFrame", "TemporaryEnchantFrame"}) do
        local fr = _G[name]
        if type(fr) == "table" and fr.SetParent then
            if hide then
                if not fr.stParent then fr.stParent = fr:GetParent() or UIParent end
                pcall(fr.SetParent, fr, C.hidden)
            elseif fr.stParent then
                pcall(fr.SetParent, fr, fr.stParent)
                fr.stParent = nil
            end
        end
    end
end

function C.NewFrame(unit, d)
    local f = CreateFrame("Button", "StreamingTouchCadre_" .. unit, UIParent, "SecureUnitButtonTemplate")
    f:SetAttribute("unit", unit)
    f:SetAttribute("type1", "target")
    f:SetAttribute("type2", "togglemenu")
    f:RegisterForClicks("AnyUp")
    f:SetFrameStrata("LOW")
    f.unit, f.def = unit, d
    f.shadow = f:CreateTexture(nil, "BACKGROUND", nil, -2)
    f.shadow:SetTexture(WHITE)
    f.shadow:SetVertexColor(0, 0, 0, .45)
    -- En combat, le cadre clignote en rouge (comme les cadres officiels du joueur et du familier).
    -- Un liseré tout autour, juste à l'extérieur du cadre (rien ne recouvre l'intérieur).
    f.glow = CreateFrame("Frame", nil, f)
    f.glow:SetPoint("TOPLEFT", f, "TOPLEFT", -3, 3)
    f.glow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 3, -3)
    for _, e in ipairs({
        {"TOPLEFT", 0, 0, "TOPRIGHT", 0, -3},       -- haut
        {"BOTTOMLEFT", 0, 3, "BOTTOMRIGHT", 0, 0},  -- bas
        {"TOPLEFT", 0, -3, "BOTTOMLEFT", 3, 3},     -- gauche
        {"TOPRIGHT", -3, -3, "BOTTOMRIGHT", 0, 3},  -- droite
    }) do
        local t = f.glow:CreateTexture(nil, "OVERLAY")
        t:SetTexture(WHITE)
        t:SetVertexColor(1, .15, .1, 1)
        t:SetPoint("TOPLEFT", f.glow, e[1], e[2], e[3])
        t:SetPoint("BOTTOMRIGHT", f.glow, e[4], e[5], e[6])
    end
    f.glow:Hide()
    pcall(function()
        local g = f.glow:CreateAnimationGroup()
        g:SetLooping("BOUNCE")
        local fade = g:CreateAnimation("Alpha")
        fade:SetFromAlpha(.85)
        fade:SetToAlpha(.15)
        fade:SetDuration(.6)
        if fade.SetSmoothing then fade:SetSmoothing("IN_OUT") end
        f.pulse = g
    end)
    f.rim = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.rim:SetTexture(WHITE)
    f.rimMask = Masked(f, f.rim)
    f.disc = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    f.disc:SetTexture(WHITE)
    f.disc:SetVertexColor(.05, .05, .07, 1)
    f.discMask = Masked(f, f.disc)
    f.hp = Bar(f)
    f.pp = Bar(f)
    f.over = CreateFrame("Frame", nil, f)
    f.over:SetAllPoints()
    f.over:SetFrameLevel(f:GetFrameLevel() + 6)
    f.portrait = f.over:CreateTexture(nil, "ARTWORK")
    f.portraitMask = Masked(f.over, f.portrait)
    f.name = Font(f.over, 11)
    f.level = Font(f.over, 10)
    f.hpText = Font(f.over, 11)
    f.ppText = Font(f.over, 9)
    f.mark = f.over:CreateTexture(nil, "OVERLAY")
    f.mark:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    f.mark:SetSize(16, 16)
    f.mark:Hide()
    f.lead = f.over:CreateTexture(nil, "OVERLAY")
    f.lead:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    f.lead:SetSize(12, 12)
    f.lead:Hide()
    f.state = Font(f.over, 9)
    if unit == "pet" then
        -- Humeur du familier (chasseur) : un point vert, jaune ou rouge.
        f.happy = CreateFrame("Frame", nil, f.over)
        f.happy:SetSize(16, 16)
        f.happy:SetFrameLevel(f.over:GetFrameLevel() + 2)
        f.happy.ring = f.happy:CreateTexture(nil, "BACKGROUND")
        f.happy.ring:SetTexture(WHITE)
        f.happy.ring:SetVertexColor(0, 0, 0, .85)
        f.happy.ring:SetAllPoints()
        Masked(f.happy, f.happy.ring)
        f.happy.bars = {}
        for i, col in ipairs({{.95, .2, .2}, {1, .82, .15}, {.3, .95, .3}}) do
            local b = CreateFrame("StatusBar", nil, f.happy)
            b:SetPoint("CENTER")
            b:SetSize(12, 12)
            b:SetFrameLevel(f.happy:GetFrameLevel() + i)
            b:SetStatusBarTexture(WHITE)
            b:SetStatusBarColor(col[1], col[2], col[3])
            local m = b:CreateMaskTexture()
            m:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            m:SetAllPoints(b)
            b:GetStatusBarTexture():AddMaskTexture(m)
            f.happy.bars[i] = b
        end
        f.happy:Hide()
        f.happyText = Font(f.over, 9)
    end
    if unit == "target" then
        f.combo = {}
        for i = 1, 5 do
            local t = f.over:CreateTexture(nil, "OVERLAY")
            t:SetTexture(WHITE)
            t:SetVertexColor(1, .82, .2)
            t:SetSize(7, 7)
            Masked(f.over, t)
            t:Hide()
            f.combo[i] = t
        end
    end
    f.blocks = {}
    if d.key == "target" then
        f.blocks[1] = NewBlock(f, "HARMFUL", 8, 26)
        f.blocks[2] = NewBlock(f, "HELPFUL", 10, 22)
    end
    if d.key == "pet" then
        f.blocks[1] = NewBlock(f, "HELPFUL", 8, 24)
        f.blocks[2] = NewBlock(f, "HARMFUL", 6, 24)
    end
    if d.key == "player" then
        f.blocks[1] = NewBlock(f, "HELPFUL", 12, 24)
        f.blocks[2] = NewBlock(f, "HARMFUL", 8, 26)
    end
    if d.cast then
        f.cast = Bar(f)
        f.cast:SetStatusBarColor(1, .7, .1)
        f.cast.text = Font(f.cast, 9)
        f.cast.text:SetPoint("CENTER")
        f.cast:Hide()
    end
    f:HookScript("OnEnter", function(self)
        if not GameTooltip or not UnitExists(self.unit) then return end
        if GameTooltip_SetDefaultAnchor then GameTooltip_SetDefaultAnchor(GameTooltip, self) else GameTooltip:SetOwner(self, "ANCHOR_BOTTOM") end
        pcall(GameTooltip.SetUnit, GameTooltip, self.unit)
        GameTooltip:Show()
    end)
    f:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    f:HookScript("OnShow", function(self) C.Full(self) end)
    C.frames[#C.frames + 1] = f
    return f
end

function C.Build()
    if C.built or InCombatLockdown() then return end
    C.built = true
    for _, d in ipairs(C.UNITS) do
        d.frames = {}
        for i, unit in ipairs(d.units) do d.frames[i] = C.NewFrame(unit, d) end
    end
end

-- Mise en page d'un cadre selon le style. mirror : la cible (portrait à droite).
local function Place(t, ...) t:ClearAllPoints() t:SetPoint(...) end
function C.Style(f, style)
    local thick = (C.Config().ppText or "non") ~= "non"
    local u = C.Config().units[f.def.key]
    local W = math.max(.5, math.min(2, tonumber(u.width) or 1))
    local H = math.max(.5, math.min(2, tonumber(u.height) or 1))
    local function r(x) return math.floor(x + .5) end
    local mirror = f.unit == "target" or f.unit == "targettarget"
    local side, other = mirror and "RIGHT" or "LEFT", mirror and "LEFT" or "RIGHT"
    local sgn = mirror and -1 or 1
    if f.shadowMasked then
        f.shadow:RemoveMaskTexture(f.rimMask)
        f.shadowMasked = nil
    end
    f.hp:SetOrientation("HORIZONTAL")
    f.hp:SetReverseFill(mirror)
    f.pp:SetReverseFill(mirror)
    f.rim:Show()
    f.disc:Show()
    f.shadow:Show()
    f.portrait:SetAlpha(1)
    if style ~= "bandeaux" and style ~= "classique" then style = "compact" end
    if style == "compact" then
        if f.portraitMasked ~= false then f.portrait:RemoveMaskTexture(f.portraitMask) f.portraitMasked = false end
        f.portrait:SetTexCoord(.12, .88, .12, .88)
    else
        if f.portraitMasked == false then f.portrait:AddMaskTexture(f.portraitMask) f.portraitMasked = true end
        f.portrait:SetTexCoord(0, 1, 0, 1)
    end
    f.shadow:ClearAllPoints()
    local ppH = thick and 12 or 5
    if style == "compact" then
        -- Compact : un seul bloc, le portrait carré dedans, les barres à côté.
        local hpH = r(18 * H)
        ppH = r((thick and 12 or 7) * H)
        local fh = hpH + ppH + 5
        local pic, bw = fh - 4, r(150 * W)
        f:SetSize(pic + bw + 7, fh)
        f.rim:Hide()
        f.disc:Hide()
        f.shadow:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
        f.shadow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
        f.shadow:SetVertexColor(0, 0, 0, .7)
        Place(f.portrait, side, f, side, sgn * 2, 0) f.portrait:SetSize(pic, pic)
        Place(f.hp, "TOP" .. side, f, "TOP" .. side, sgn * (pic + 5), -2) f.hp:SetSize(bw, hpH)
        Place(f.pp, "TOP" .. side, f.hp, "BOTTOM" .. side, 0, -1) f.pp:SetSize(bw, ppH)
        Place(f.name, side, f.hp, side, sgn * 4, 0)
        f.name:SetWidth(math.max(50, bw - 70))
        Place(f.hpText, other, f.hp, other, -sgn * 4, 0)
        Place(f.ppText, "CENTER", f.pp, "CENTER")
        Place(f.level, "BOTTOM", f.portrait, "BOTTOM", 0, 1)
        Place(f.mark, "BOTTOM", f, "TOP", 0, -4)
        Place(f.lead, "TOP" .. side, f.portrait, "TOP" .. side, 0, 0)
        Place(f.state, "BOTTOM", f.hp, "TOP", 0, 1)
        if f.happy then Place(f.happy, "TOP" .. other, f.portrait, "TOP" .. other, 0, 0) end
    elseif style == "bandeaux" then
        f.shadow:SetVertexColor(0, 0, 0, .45)
        local w, hpH = r(172 * W), r(19 * H)
        ppH = r(ppH * math.max(1, H))
        f:SetSize(w + 4, hpH + ppH + 6)
        f.rim:Hide()
        f.disc:Hide()
        f.shadow:ClearAllPoints()
        f.shadow:SetAllPoints()
        Place(f.hp, "TOPLEFT", f, "TOPLEFT", 2, -2) f.hp:SetSize(w, hpH)
        Place(f.pp, "TOPLEFT", f.hp, "BOTTOMLEFT", 0, -2) f.pp:SetSize(w, ppH)
        f.portrait:SetSize(1, 1)
        f.portrait:SetAlpha(0)
        Place(f.name, side, f.hp, side, sgn * 4, 0)
        f.name:SetWidth(math.max(50, w - 64))
        Place(f.hpText, other, f.hp, other, -sgn * 4, 0)
        Place(f.level, other, f, side, -sgn * 3, 0)
        Place(f.ppText, "CENTER", f.pp, "CENTER")
        Place(f.mark, "BOTTOM", f, "TOP", 0, -4)
        Place(f.lead, "BOTTOM" .. side, f, "TOP" .. side, 0, -4)
        Place(f.state, "BOTTOM", f.hp, "TOP", 0, 1)
        if f.happy then Place(f.happy, "CENTER", f.hp, "CENTER", 0, 0) end
    else
        local d, hpW, hpH = r(56 * H), r(142 * W), r(18 * H)
        ppH = r((thick and 13 or 8) * math.max(1, H))
        f.shadow:SetVertexColor(0, 0, 0, .45)
        f:SetSize(d + 8 + hpW, math.max(d, 14 + hpH + 3 + ppH + 2))
        Place(f.shadow, side, f, side, 0, 0) f.shadow:SetSize(d + 2, d + 2)
        f.shadow:AddMaskTexture(f.rimMask)
        f.shadowMasked = true
        Place(f.rim, side, f, side, sgn * 1, 0) f.rim:SetSize(d, d)
        Place(f.disc, "CENTER", f.rim, "CENTER") f.disc:SetSize(d - 6, d - 6)
        Place(f.portrait, "CENTER", f.rim, "CENTER") f.portrait:SetSize(d - 8, d - 8)
        Place(f.hp, "TOP" .. side, f, "TOP" .. side, sgn * (d + 6), -14) f.hp:SetSize(hpW, hpH)
        Place(f.pp, "TOP" .. side, f.hp, "BOTTOM" .. side, 0, -3) f.pp:SetSize(hpW, ppH)
        Place(f.name, "BOTTOM" .. side, f.hp, "TOP" .. side, sgn * 2, 2)
        f.name:SetWidth(math.max(50, hpW - 4))
        Place(f.hpText, "CENTER", f.hp, "CENTER")
        Place(f.ppText, "CENTER", f.pp, "CENTER")
        Place(f.level, "BOTTOM", f.rim, "BOTTOM", 0, -2)
        Place(f.mark, "TOP", f.rim, "TOP", 0, 6)
        Place(f.lead, "TOP" .. other, f.rim, "TOP" .. other, 0, 0)
        Place(f.state, "TOP", f.rim, "TOP", 0, -4)
        if f.happy then Place(f.happy, "BOTTOM" .. other, f.rim, "BOTTOM" .. other, sgn * 4, -2) end
    end
    if f.happyText then
        Place(f.happyText, "TOP", f.happy, "BOTTOM", 0, 1)
        f.happyText:SetAlpha(style == "bandeaux" and 0 or 1)
    end
    -- L'icône d'humeur du jeu (tenue à jour par le jeu lui-même), collée à gauche du cadre du familier.
    if f.unit == "pet" then
        pcall(C.GhostPetFrame, f)
        local w = C.HappyWidget()
        if w then
            pcall(w.SetParent, w, f.over)
            pcall(w.ClearAllPoints, w)
            if style == "compact" then
                pcall(w.SetScale, w, .62)
                pcall(w.SetPoint, w, "BOTTOMRIGHT", f.portrait, "BOTTOMRIGHT", 4, -4)
            else
                pcall(w.SetScale, w, 1)
                pcall(w.SetPoint, w, "RIGHT", f, "LEFT", -2, 0)
            end
            pcall(w.SetFrameLevel, w, f.over:GetFrameLevel() + 3)
        end
    end
    f.name:SetJustifyH(side)
    if f.combo then
        for i, t in ipairs(f.combo) do Place(t, "BOTTOM", f, "TOP", (i - 3) * 10, 2) end
    end
    local last, below = f, 0
    for _, blk in ipairs(f.blocks or {}) do
        Place(blk.frame, "TOPLEFT", last, "BOTTOMLEFT", 0, -4)
        last = blk.frame
        below = below + 4 + blk.size
        for i, a in ipairs(blk.icons or {}) do
            if i == 1 then Place(a, "LEFT", blk.frame, "LEFT", 0, 0)
            else Place(a, "LEFT", blk.icons[i - 1], "RIGHT", 2, 0) end
        end
    end
    if f.cast then
        Place(f.cast, "TOP", f, "BOTTOM", 0, below > 0 and -(below + 4) or -28)
        f.cast:SetSize(r(150 * W), 10)
    end
end

-- Les effets du familier : en combat, le jeu ne les dessine que dans son propre cadre du familier, et seulement
-- s'il est affiché. On le garde donc affiché, mais transparent et sans clic, sauf son bloc d'effets
-- (AuraFrameContainer), qu'on cale juste sous notre cadre du familier. Hors combat seulement (cadre sécurisé).
function C.GhostPetFrame(f)
    local pf = _G.PetFrame
    if not C.ghostPet or type(pf) ~= "table" or InCombatLockdown() then return end
    local auras = pf.AuraFrameContainer
    if C.diag then C.diag.petAuraFrame = type(auras) end
    if type(auras) ~= "table" then return end
    for _, r in ipairs({pf:GetRegions()}) do pcall(r.SetAlpha, r, 0) end
    for _, ch in ipairs({pf:GetChildren()}) do
        if ch ~= auras then pcall(ch.SetAlpha, ch, 0) end
    end
    pcall(auras.SetAlpha, auras, 1)
    pcall(pf.SetAlpha, pf, 1)
    pcall(pf.EnableMouse, pf, false)
    -- Décalage du bloc d'effets dans le cadre du jeu (mesuré quand il est placé, sinon une valeur sûre).
    local dx, dy = 0, 0
    pcall(function()
        local l, t, al, at = pf:GetLeft(), pf:GetTop(), auras:GetLeft(), auras:GetTop()
        if l and t and al and at then dx, dy = (al - l), (t - at) end
    end)
    C.petOffset = (dx ~= 0 or dy ~= 0) and {dx, dy} or C.petOffset or {0, 0}
    pf.stOwner = f
    pf.stBusy = true
    pcall(function()
        pf:ClearAllPoints()
        pf:SetPoint("TOPLEFT", f, "BOTTOMLEFT", -C.petOffset[1], C.petOffset[2] - 4)
    end)
    pf.stBusy = nil
    if not C.petHooked and hooksecurefunc then
        C.petHooked = true
        -- Le jeu le replace parfois (à côté de son cadre du joueur) : on le remet sous le nôtre, hors combat.
        hooksecurefunc(pf, "SetPoint", function(self)
            if self.stBusy or InCombatLockdown() or not self.stOwner then return end
            self.stBusy = true
            pcall(function()
                self:ClearAllPoints()
                self:SetPoint("TOPLEFT", self.stOwner, "BOTTOMLEFT", -C.petOffset[1], C.petOffset[2] - 4)
            end)
            self.stBusy = nil
        end)
    end
    f.blizzAuras = true
end

-- L'humeur du familier telle que le jeu l'affiche sur son propre cadre (PetFrameHappiness).
function C.HappyWidget()
    if C.happyWidget ~= nil then return C.happyWidget or nil end
    local pf = _G.PetFrame
    local w = _G.PetFrameHappiness
    if type(w) ~= "table" and type(pf) == "table" then
        w = nil
        for _, k in ipairs({"happiness", "Happiness", "HappinessFrame", "happinessFrame"}) do
            if type(pf[k]) == "table" then w = pf[k] break end
        end
        if not w and pf.GetChildren then
            for _, ch in ipairs({pf:GetChildren()}) do
                local n = ch.GetName and ch:GetName()
                if type(n) == "string" and n:find("Happi") then w = ch break end
            end
        end
    end
    C.happyWidget = type(w) == "table" and w or false
    return C.happyWidget or nil
end

-- Couleurs : classe pour les joueurs, réaction pour les autres, gris si la cible est prise.
function C.Color(u)
    if UnitIsPlayer(u) then
        local _, class = UnitClass(u)
        local col = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if col then return col.r, col.g, col.b end
    end
    if UnitIsTapDenied and UnitIsTapDenied(u) then return .5, .5, .5 end
    local react = UnitReaction and UnitReaction(u, "player")
    if Secret(react) or not react then return .25, .8, .3 end
    if react <= 3 then return .85, .18, .15 end
    if react == 4 then return .95, .8, .2 end
    return .25, .8, .3
end
local RIMS = {elite = {1, .78, .25}, worldboss = {1, .5, .1}, rareelite = {.85, .85, .95}, rare = {.75, .75, .85}}

-- Ce qui change souvent : vie, ressource, textes (4 fois par seconde et sur les évènements).
function C.Bars(f)
    local u = f.unit
    if not UnitExists(u) then return end
    local c = C.Config()
    pcall(f.hp.SetMinMaxValues, f.hp, 0, UnitHealthMax(u))
    pcall(f.hp.SetValue, f.hp, UnitHealth(u))
    pcall(f.pp.SetMinMaxValues, f.pp, 0, UnitPowerMax(u))
    pcall(f.pp.SetValue, f.pp, UnitPower(u))
    local r, g, b = C.Color(u)
    f.hp:SetStatusBarColor(r, g, b)
    f.hp.bg:SetVertexColor(r * .22, g * .22, b * .22, .9)
    local _, token = UnitPowerType(u)
    local pc = PowerBarColor and (PowerBarColor[token or ""] or PowerBarColor.MANA)
    if pc then f.pp:SetStatusBarColor(pc.r, pc.g, pc.b) f.pp.bg:SetVertexColor(pc.r * .2, pc.g * .2, pc.b * .2, .9) end
    if UnitIsDeadOrGhost(u) then
        f.hpText:SetText(UnitIsGhost and UnitIsGhost(u) and "Fantôme" or "Mort")
    elseif UnitIsConnected and not UnitIsConnected(u) then
        f.hpText:SetText("Hors ligne")
    else
        C.Fill(f.hpText, c.text or "pct", UnitHealth(u), UnitHealthMax(u), UnitHealthPercent and function()
            return UnitHealthPercent(u, true, CurveConstants and CurveConstants.ScaleTo100)
        end)
    end
    local ok, pmax = pcall(UnitPowerMax, u)
    if ok and not Secret(pmax) and pmax == 0 then
        f.ppText:SetText("")
    else
        C.Fill(f.ppText, c.ppText or "non", UnitPower(u), pmax, UnitPowerPercent and function()
            local curve = CurveConstants and CurveConstants.ScaleTo100
            local ok, v = pcall(UnitPowerPercent, u, nil, false, curve)
            if ok and v ~= nil then return v end
            return UnitPowerPercent(u, nil, curve)
        end)
    end
    if f.def.key == "party" and UnitInRange then
        local ok, near, checked = pcall(UnitInRange, u)
        if ok and type(near) == "boolean" and checked ~= false then f:SetAlpha(near and 1 or .5) else f:SetAlpha(1) end
    end
    if f.cast then C.Cast(f) end
    if f.happy then C.Mood(f) end
end

-- Écrit « 1182 », « 92 % » ou « 1182 (92 %) ». Les nombres secrets du jeu passent tels quels.
function C.Fill(fs, mode, cur, max, percent)
    fs:SetText("")
    if mode == "non" then return end
    local fmt = AbbreviateLargeNumbers or AbbreviateNumbers or tostring
    if mode == "val" then
        pcall(fs.SetFormattedText, fs, "%s", fmt(cur))
        return
    end
    local p
    if percent then
        local ok, v = pcall(percent)
        if ok then p = v end
    end
    if p == nil then
        local ok, v = pcall(function() if max and max > 0 then return cur / max * 100 end end)
        if ok then p = v end
    end
    if p == nil then
        if mode == "both" then pcall(fs.SetFormattedText, fs, "%s", fmt(cur)) end
        return
    end
    if mode == "both" then
        pcall(fs.SetFormattedText, fs, "%s (%.0f %%)", fmt(cur), p)
    else
        pcall(fs.SetFormattedText, fs, "%.0f %%", p)
    end
end

function C.Cast(f)
    local u = f.unit
    local name, _, _, start, finish = nil, nil, nil, nil, nil
    local channel
    if UnitCastingInfo then
        local ok, n, _, _, s, e = pcall(UnitCastingInfo, u)
        if ok and n then name, start, finish = n, s, e end
    end
    if not name and UnitChannelInfo then
        local ok, n, _, _, s, e = pcall(UnitChannelInfo, u)
        if ok and n then name, start, finish, channel = n, s, e, true end
    end
    if not name then f.cast:Hide() return end
    f.cast:SetReverseFill(channel and true or false)
    pcall(f.cast.SetMinMaxValues, f.cast, start, finish)
    pcall(f.cast.SetValue, f.cast, (GetTime and GetTime() or 0) * 1000)
    pcall(f.cast.text.SetText, f.cast.text, name)
    f.cast:Show()
end

-- Clignotement rouge en combat : le joueur et son familier, comme l'interface officielle.
function C.Glow(f)
    if not f.glow then return end
    local on = false
    if not C.moving and (f.unit == "player" or f.unit == "pet") and UnitExists(f.unit) then
        local ok, res = pcall(function() return UnitAffectingCombat(f.unit) and true or false end)
        on = ok and res or (f.unit == "player" and C.fighting) or false
    end
    if on then
        if not f.glow:IsShown() then
            f.glow:Show()
            if f.pulse then f.pulse:Play() else f.glow:SetAlpha(.5) end
        end
    elseif f.glow:IsShown() then
        if f.pulse then f.pulse:Stop() end
        f.glow:Hide()
    end
end

-- Tout le reste (nom, niveau, portrait, icônes) : sur les évènements.
function C.Full(f)
    local u = f.unit
    if C.moving then
        f.name:SetText(f.def.label)
        return
    end
    if not UnitExists(u) then return end
    pcall(f.name.SetText, f.name, UnitName(u))
    local level = UnitLevel(u)
    if Secret(level) then
        f.level:SetText("")
    elseif level and level < 0 then
        f.level:SetText("??")
        f.level:SetTextColor(1, .2, .2)
    else
        f.level:SetText(level or "")
        local col = GetCreatureDifficultyColor and GetCreatureDifficultyColor(level)
            or GetQuestDifficultyColor and GetQuestDifficultyColor(level)
        if col then f.level:SetTextColor(col.r, col.g, col.b) else f.level:SetTextColor(1, .82, .3) end
    end
    if SetPortraitTexture then pcall(SetPortraitTexture, f.portrait, u) end
    local class = UnitClassification and UnitClassification(u)
    local rim = (not Secret(class) and RIMS[class or ""]) or {.62, .45, .16}
    f.rim:SetVertexColor(rim[1], rim[2], rim[3], 1)
    local idx = GetRaidTargetIndex and GetRaidTargetIndex(u)
    if idx and not Secret(idx) and SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(f.mark, idx)
        f.mark:Show()
    else
        f.mark:Hide()
    end
    f.lead:SetShown(UnitIsGroupLeader and UnitIsGroupLeader(u) or false)
    local state = ""
    if u == "player" and IsResting and IsResting() then state = "Zzz" end
    f.state:SetText(state)
    C.Glow(f)
    if f.happy then
        C.Mood(f)
    end
    if f.combo then
        local n = GetComboPoints and GetComboPoints("player", "target") or 0
        if Secret(n) then n = 0 end
        for i, t in ipairs(f.combo) do t:SetShown(i <= (n or 0)) end
    end
    if f.blocks and #f.blocks > 0 then C.Auras(f) end
    C.Bars(f)
end

-- Humeur du familier : GetPetHappiness (1 mécontent, 2 content, 3 heureux), sinon la « puissance »
-- d'humeur (0 à 1 000 000). La valeur passe telle quelle aux barres, même secrète.
function C.Mood(f)
    if C.HappyWidget() then
        f.happy:Hide()
        f.happyText:SetText("")
        return
    end
    local ok, h = false, nil
    if GetPetHappiness then ok, h = pcall(GetPetHappiness) end
    if not ok or Secret(h) or type(h) ~= "number" or h < 1 or h > 3 then
        f.happy:Hide()
        f.happyText:SetText("")
        return
    end
    for i, b in ipairs(f.happy.bars) do
        b:SetMinMaxValues(i - 1, i)
        b:SetValue(h)
    end
    f.happy:Show()
    f.happyText:SetText("Humeur")
    f.happyText:SetTextColor(.85, .85, .85)
end

-- Place et taille : hors combat. Le groupe : quatre cadres l'un sous l'autre.
function C.PosOf(key)
    local d, c = C.byKey[key], C.Config()
    local p = c.units[key].pos
    if type(p) == "table" and tonumber(p.x) and tonumber(p.y) then return p.x, p.y end
    return UIParent:GetWidth() * d.pos[1], UIParent:GetHeight() * d.pos[2]
end
function C.ScaleOf(key)
    local s = tonumber(C.Config().units[key].scale)
    return s or C.byKey[key].scale
end
function C.Place(key)
    if InCombatLockdown() then C.pending = true return end
    local d = C.byKey[key]
    if not d.frames then return end
    local x, y = C.PosOf(key)
    local scale = C.ScaleOf(key)
    for i, f in ipairs(d.frames) do
        f:SetScale(scale)
        f:ClearAllPoints()
        local h, w = f:GetHeight() or 40, f:GetWidth() or 150
        if key == "party" and C.Config().partyRow then
            f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale + (i - 1) * (w + 10), y / scale)
        else
            f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale - (i - 1) * (h + 22))
        end
    end
end

function C.Apply()
    local c = C.Config()
    if InCombatLockdown() then C.pending = true return end
    C.pending = nil
    if not c.on then
        C.GameBuffs()
        for _, f in ipairs(C.frames) do
            if UnregisterUnitWatch then UnregisterUnitWatch(f) end
            f:Hide()
        end
        return
    end
    C.Build()
    for _, d in ipairs(C.UNITS) do
        local off = c.units[d.key].off
        if not off then C.Kill(d.key) end
        for _, f in ipairs(d.frames) do
            local ok, err = pcall(C.Style, f, c.style)
            if not ok and not C.warned then C.warned = true Say("cadre " .. d.label .. " : " .. tostring(err)) end
            if off then
                if UnregisterUnitWatch then UnregisterUnitWatch(f) end
                f:Hide()
            elseif f.unit == "player" then
                f:Show()
            elseif RegisterUnitWatch then
                RegisterUnitWatch(f)
            end
        end
        C.Place(d.key)
    end
    C.GameBuffs()
    pcall(C.CombatLook)
    pcall(C.RefreshContainers)
    C.UpdateAll()
    pcall(C.Totems)
end

function C.UpdateAll()
    for _, f in ipairs(C.frames) do
        if f:IsShown() then C.Full(f) end
    end
end

-- Déplacer : chaque cadre se montre (même sans cible) avec une poignée dorée ; on le glisse au doigt.
function C.StartMove(done)
    if InCombatLockdown() then Say("pas pendant un combat.") return end
    local c = C.Config()
    if not c.on then Say("active d'abord les cadres.") return end
    C.moving = true
    for _, d in ipairs(C.UNITS) do
        if not c.units[d.key].off then
            for _, f in ipairs(d.frames) do
                if UnregisterUnitWatch then UnregisterUnitWatch(f) end
                f:Show()
                C.Full(f)
            end
            local o = C.overlays[d.key]
            if not o then
                o = CreateFrame("Frame", nil, d.frames[1])
                o:SetAllPoints(d.frames[1])
                o:SetFrameLevel(d.frames[1]:GetFrameLevel() + 30)
                o:EnableMouse(true)
                o.tint = o:CreateTexture(nil, "OVERLAY")
                o.tint:SetAllPoints()
                o.tint:SetTexture(WHITE)
                o.tint:SetVertexColor(1, .82, .3, .22)
                o.label = Font(o, 12)
                o.label:SetPoint("CENTER")
                o.label:SetText(d.label)
                o:SetScript("OnMouseDown", function(self)
                    local s = UIParent:GetEffectiveScale()
                    local x, y = GetCursorPosition()
                    local px, py = C.PosOf(d.key)
                    self.grab = {x / s, y / s, px, py}
                end)
                o:SetScript("OnMouseUp", function(self) self.grab = nil end)
                o:SetScript("OnUpdate", function(self)
                    local g = self.grab
                    if not g or InCombatLockdown() then return end
                    local s = UIParent:GetEffectiveScale()
                    local x, y = GetCursorPosition()
                    c.units[d.key].pos = {x = g[3] + x / s - g[1], y = g[4] + y / s - g[2]}
                    C.Place(d.key)
                end)
                C.overlays[d.key] = o
            end
            o:Show()
        end
    end
    local bar = C.moveBar
    if not bar then
        bar = CreateFrame("Frame", nil, UIParent)
        bar:SetSize(300, 40)
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
        bar:SetFrameStrata("FULLSCREEN_DIALOG")
        bar.text = Font(bar, 13)
        bar.text:SetPoint("BOTTOM", bar, "TOP", 0, 6)
        bar.text:SetText("Glisse chaque cadre doré au doigt, puis touche « Terminé ».")
        local ok = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
        ok:SetSize(140, 30)
        ok:SetText("Terminé")
        ok:SetPoint("CENTER")
        ok:SetScript("OnClick", function() C.EndMove() end)
        bar.ok = ok
        C.moveBar = bar
    end
    bar.done = done
    bar:Show()
end
function C.EndMove()
    C.moving = nil
    for _, o in pairs(C.overlays) do o.grab = nil o:Hide() end
    if C.moveBar then C.moveBar:Hide() end
    C.Apply()
    Say("cadres placés.")
    local done = C.moveBar and C.moveBar.done
    if done then done() end
end

-- Réglages.
local function Refresh()
    C.Apply()
    if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
end
function C.SetOn(on)
    local c = C.Config()
    if not on and c.on then C.needReload = true end
    c.on = on or nil
    Refresh()
end
function C.Set(field, value)
    C.Config()[field] = value
    Refresh()
end
C.sel = "player"
function C.SetUnit(field, value)
    C.Config().units[C.sel][field] = value
    if field == "off" and not value then C.needReload = C.needReload end
    if field == "off" and value then C.needReload = true end
    Refresh()
end
function C.StepScale(delta)
    local key = C.sel
    local v = math.floor(math.max(.5, math.min(2, C.ScaleOf(key) + delta)) * 100 + .5) / 100
    C.Config().units[key].scale = v
    Refresh()
end
function C.StepDim(field, delta)
    local u = C.Config().units[C.sel]
    u[field] = math.floor(math.max(.5, math.min(2, (tonumber(u[field]) or 1) + delta)) * 100 + .5) / 100
    Refresh()
end
function C.Reset()
    for _, d in ipairs(C.UNITS) do C.Config().units[d.key].pos = nil end
    Refresh()
end

C.social = {}
local function SocialButton() return _G.QuickJoinToastButton or _G.FriendsMicroButton end
local CHAT_BUTTONS = {"ChatFrameChannelButton", "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton",
    "ChatFrameMenuButton"}
local function Points(f)
    local list = {}
    for i = 1, (f.GetNumPoints and f:GetNumPoints() or 0) do list[i] = {f:GetPoint(i)} end
    return list
end
local function SetPoints(f, list)
    f:ClearAllPoints()
    for _, pt in ipairs(list) do f:SetPoint(unpack(pt)) end
end
function C.MoveSocial()
    local social = SocialButton()
    if type(social) ~= "table" or InCombatLockdown() then return end
    local down = C.Config().social ~= "haut"
    local S = C.social
    if not S.orig then
        S.orig = Points(social)
        S.deps = {}
        -- Les boutons accrochés sous l'icône des amis prennent sa place en haut.
        for _, name in ipairs(CHAT_BUTTONS) do
            local b = _G[name]
            if type(b) == "table" and b.GetNumPoints then
                for i = 1, b:GetNumPoints() do
                    local _, rel = b:GetPoint(i)
                    if rel == social then S.deps[#S.deps + 1] = {b, Points(b)} break end
                end
            end
        end
        if social.HookScript and hooksecurefunc then
            hooksecurefunc(social, "SetPoint", function()
                if S.busy or C.Config().social == "haut" then return end
                S.busy = true
                pcall(C.MoveSocial)
                S.busy = nil
            end)
        end
    end
    S.busy = true
    if down then
        for _, d in ipairs(S.deps) do pcall(SetPoints, d[1], S.orig) end
        local low
        for i = #CHAT_BUTTONS, 1, -1 do
            local b = _G[CHAT_BUTTONS[i]]
            if type(b) == "table" and b.IsShown and b:IsShown() then low = b break end
        end
        social:ClearAllPoints()
        if low then
            pcall(social.SetPoint, social, "TOP", low, "BOTTOM", 0, -4)
        else
            pcall(SetPoints, social, S.orig)
        end
    else
        pcall(SetPoints, social, S.orig)
        for _, d in ipairs(S.deps) do pcall(SetPoints, d[1], d[2]) end
    end
    S.busy = nil
end

-- Invocations à durée (Invocation de faucon…) : ce ne sont pas des effets mais des « totems » pour le jeu.
-- L'interface officielle les montre sous le cadre du familier (TotemFrame, rangé avec le cadre du joueur).
-- On les affiche nous-mêmes, à droite de notre cadre du familier (sous le joueur s'il n'y a pas de familier).
C.totems = {}
function C.TotemIcon(i)
    local a = C.totems[i]
    if a then return a end
    a = CreateFrame("Frame", nil, UIParent)
    a:SetSize(24, 24)
    a:SetFrameStrata("MEDIUM")
    a.icon = a:CreateTexture(nil, "ARTWORK")
    a.icon:SetAllPoints()
    a.icon:SetTexCoord(.08, .92, .08, .92)
    a.cd = CreateFrame("Cooldown", nil, a, "CooldownFrameTemplate")
    a.cd:SetAllPoints()
    pcall(a.cd.SetReverse, a.cd, true)
    pcall(a.cd.SetHideCountdownNumbers, a.cd, false)
    pcall(a.cd.SetDrawEdge, a.cd, false)
    -- Le temps restant écrit par nous (les chiffres du jeu sur le cercle peuvent être éteints).
    pcall(a.cd.SetHideCountdownNumbers, a.cd, true)
    a.top = CreateFrame("Frame", nil, a)
    a.top:SetAllPoints()
    a.top:SetFrameLevel(a.cd:GetFrameLevel() + 2)
    a.time = Font(a.top, 11)
    a.time:SetPoint("CENTER", a, "CENTER", 0, 0)
    a.time:SetTextColor(1, .95, .6)
    a.slot = i
    a:SetScript("OnUpdate", function(self, elapsed)
        self.wait = (self.wait or 0) - (elapsed or 0)
        if self.wait > 0 then return end
        self.wait = .2
        local left = GetTotemTimeLeft and GetTotemTimeLeft(self.slot)
        if left == nil then pcall(function() left = self.start + self.dur - GetTime() end) end
        local ok = pcall(function()
            local s = math.floor(left + .5)
            if s >= 60 then self.time:SetText(math.floor(s / 60) .. " m")
            elseif s > 0 then self.time:SetText(s)
            else self.time:SetText("") end
        end)
        -- Valeur protégée en combat : le jeu sait l'écrire lui-même, on la passe telle quelle.
        if not ok then
            if not pcall(self.time.SetFormattedText, self.time, "%.0f", left) then
                pcall(self.time.SetText, self.time, left)
            end
        end
    end)
    a:Hide()
    C.totems[i] = a
    return a
end
local function Truthy(v)
    local ok, res = pcall(function() return v and v ~= "" and v ~= 0 and true or false end)
    if ok then return res end
    return true -- valeur protégée par le jeu en combat : elle existe, donc on montre
end
function C.Totems()
    if type(GetTotemInfo) ~= "function" then return end
    local anchor, below
    for _, f in ipairs(C.frames or {}) do
        if f.unit == "pet" and f:IsShown() then anchor = f end
    end
    if not anchor then
        for _, f in ipairs(C.frames or {}) do
            if f.unit == "player" and f:IsShown() then anchor, below = f, true end
        end
    end
    local on = C.built and C.Config().on and anchor
    local prev, info = nil, {}
    for i = 1, (MAX_TOTEMS or 4) do
        local a = C.TotemIcon(i)
        local have, name, start, duration, icon = GetTotemInfo(i)
        pcall(function()
            local sec = issecretvalue and issecretvalue(have)
            info[#info + 1] = i .. ":" .. (sec and "secret" or (tostring(have) .. " " .. tostring(name)))
        end)
        if on and Truthy(have) and Truthy(icon) then
            pcall(a.icon.SetTexture, a.icon, icon)
            pcall(a.cd.SetCooldown, a.cd, start, duration)
            a.start, a.dur, a.wait = start, duration, 0
            a:ClearAllPoints()
            if prev then
                a:SetPoint("RIGHT", prev, "LEFT", -2, 0)
            else
                -- Sous le cadre, calé à droite (les effets partent de la gauche). Placé en coordonnées
                -- d'écran : jamais accroché au cadre sécurisé, sinon il serait bloqué en combat.
                local ok = pcall(function()
                    local k = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
                    a:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", anchor:GetRight() * k, anchor:GetBottom() * k - 4)
                end)
                if not ok then a:SetPoint("CENTER", UIParent, "CENTER", 0, -120) end
            end
            a:Show()
            prev = a
        else
            a:Hide()
        end
    end
    if C.diag then C.diag.totems = info end
end

local events = CreateFrame("Frame")
C.events = events
pcall(events.RegisterEvent, events, "PLAYER_TOTEM_UPDATE")
for _, ev in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
    "PLAYER_TARGET_CHANGED", "UNIT_PET", "GROUP_ROSTER_UPDATE", "RAID_TARGET_UPDATE", "PARTY_LEADER_CHANGED",
    "PLAYER_UPDATE_RESTING", "UNIT_PORTRAIT_UPDATE", "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_AURA",
    "UNIT_HAPPINESS", "UNIT_FACTION", "UNIT_CLASSIFICATION_CHANGED", "UNIT_TARGET", "UNIT_POWER_FREQUENT",
    "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_DISPLAYPOWER", "UNIT_FLAGS", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED"}) do
    pcall(events.RegisterEvent, events, ev)
end
-- Évènements d'un personnage : seulement les cadres de ce personnage (pas tous à chaque fois :
-- en combat, UNIT_AURA arrive sans arrêt pour chaque monstre affiché).
local PER_UNIT = {UNIT_AURA = "auras", UNIT_PORTRAIT_UPDATE = "full", UNIT_NAME_UPDATE = "full", UNIT_LEVEL = "full",
    UNIT_FACTION = "full", UNIT_CLASSIFICATION_CHANGED = "full", UNIT_HAPPINESS = "full", UNIT_DISPLAYPOWER = "bars",
    UNIT_HEALTH = "bars", UNIT_MAXHEALTH = "bars", UNIT_POWER_FREQUENT = "bars", UNIT_FLAGS = "glow"}
local function ForUnit(unit, what)
    for _, f in ipairs(C.frames) do
        if f.unit == unit and f:IsShown() then
            if what == "auras" then pcall(C.Auras, f)
            elseif what == "bars" then pcall(C.Bars, f)
            elseif what == "glow" then pcall(C.Glow, f)
            else pcall(C.Full, f) end
        end
    end
end
events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        C.Config()
        C.DiagStart()
        if C.Config().on then C.Apply() end
        pcall(C.MoveSocial)
        if C_Timer and C_Timer.After then C_Timer.After(2, function() pcall(C.MoveSocial) end) end
        return
    end
    if event == "PLAYER_TOTEM_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "UNIT_PET" then
        pcall(C.Totems)
        -- Le cadre du familier apparaît un peu après l'évènement : on replace une demi-seconde plus tard.
        if event ~= "PLAYER_TOTEM_UPDATE" and C_Timer and C_Timer.After then
            C_Timer.After(.5, function() pcall(C.Totems) end)
        end
        if event == "PLAYER_TOTEM_UPDATE" then return end
    end
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        C.fighting = event == "PLAYER_REGEN_DISABLED"
        pcall(C.CombatLook)
        if C.fighting and C_Timer and C_Timer.After then C_Timer.After(2, function() pcall(C.DiagCombat) end) end
        if event == "PLAYER_REGEN_ENABLED" and C.pending then C.Apply() return end
    end
    -- Le conteneur du jeu suit son personnage : nouvelle cible, familier appelé, entrée en combat…
    if C.built and (event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_PET" and unit == "player")
        or event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_REGEN_DISABLED") then
        C.RefreshContainers()
    end
    if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        if C.built and not InCombatLockdown() then for _, d in ipairs(C.UNITS) do C.Place(d.key) end end
        return
    end
    if not C.built or not C.Config().on then return end
    local what = PER_UNIT[event]
    if what then
        if unit then ForUnit(unit, what) end
        return
    end
    if event == "UNIT_TARGET" then
        if unit == "target" then ForUnit("targettarget", "full") end
        return
    end
    if event == "PLAYER_TARGET_CHANGED" then
        ForUnit("target", "full")
        ForUnit("targettarget", "full")
        return
    end
    if event == "UNIT_PET" then
        if unit == "player" then ForUnit("pet", "full") end
        return
    end
    C.UpdateAll()
end)
-- Barres 4 fois par seconde (portée du groupe, incantation) ; la cible de la cible n'a pas d'évènement
-- quand elle change de nom ou de vie : elle est refaite entière une fois par seconde.
events:SetScript("OnUpdate", function(self, elapsed)
    self.wait = (self.wait or 0) - (elapsed or 0)
    if self.wait > 0 then return end
    self.wait = .25
    self.tick = (self.tick or 0) + 1
    if not C.built or not C.Config().on or C.moving then return end
    for _, f in ipairs(C.frames) do
        if f:IsShown() then
            if f.unit == "targettarget" and self.tick % 4 == 0 then pcall(C.Full, f) else pcall(C.Bars, f) end
        end
    end
end)

-- Carnet de bord (enregistré quand on quitte le jeu ou /reload) : erreurs de l'addon, actions bloquées,
-- et ce que le conteneur d'effets du jeu sait faire. Sert à corriger sans avoir à tout décrire.
C.diag = {}
local function Note(list, text, max)
    list[#list + 1] = (date and date("%H:%M:%S ") or "") .. tostring(text):sub(1, 300)
    while #list > (max or 15) do table.remove(list, 1) end
end
function C.DiagStart()
    StreamingTouchDB.diag = {errors = {}, blocked = {}, container = {}, combat = {}, frames = {}}
    C.diag = StreamingTouchDB.diag
    pcall(function()
        local old = geterrorhandler and geterrorhandler()
        if old and seterrorhandler and not C.errorHooked then
            C.errorHooked = true
            seterrorhandler(function(msg, ...)
                if type(msg) == "string" and msg:find("StreamingTouch") then pcall(Note, C.diag.errors, msg) end
                return old(msg, ...)
            end)
        end
    end)
    local watch = CreateFrame("Frame")
    pcall(watch.RegisterEvent, watch, "ADDON_ACTION_BLOCKED")
    pcall(watch.RegisterEvent, watch, "ADDON_ACTION_FORBIDDEN")
    watch:SetScript("OnEvent", function(_, ev, name, func)
        if name == "StreamingTouch" then pcall(Note, C.diag.blocked, ev .. " " .. tostring(func)) end
    end)
    -- Ce que contiennent les cadres du jeu (pour l'humeur et les effets du familier).
    pcall(function()
        for _, name in ipairs({"PetFrame", "TargetFrame"}) do
            local fr, list = _G[name], {}
            if type(fr) == "table" and fr.GetChildren then
                for _, ch in ipairs({fr:GetChildren()}) do
                    list[#list + 1] = tostring(ch.GetName and ch:GetName()) .. ":" .. tostring(ch.GetObjectType and ch:GetObjectType())
                end
            end
            C.diag.frames[name] = list
        end
    end)
end
-- Deux secondes après le début d'un combat : chaque conteneur est-il là, visible, rempli ?
function C.DiagCombat()
    local list = {}
    for _, f in ipairs(C.frames) do
        for i, b in ipairs(f.blocks or {}) do
            if b.cont then
                local line = f.unit .. i
                for _, k in ipairs({"IsVisible", "GetAlpha", "GetWidth", "GetUnit", "IsEnabled"}) do
                    local ok, v = pcall(function() return tostring(b.cont[k](b.cont)) end)
                    line = line .. " " .. k .. "=" .. (ok and v or "?")
                end
                list[#list + 1] = line
            end
        end
    end
    C.diag.combat = list
end

-- L'onglet « Cadres » de /stouch (cadres et mini-carte).
addon.extraTabs = addon.extraTabs or {}
table.insert(addon.extraTabs, 1, {
    name = "Cadres", icon = "Interface\\Icons\\INV_Misc_Head_Dwarf_01",
    build = function(page, G) C.BuildSettings(page, G) end,
    refresh = function(page) C.RefreshSettings(page) end,
})

function C.BuildSettings(page, G)
    local Pill, Font2, Section, Stepper = G.Pill, G.Font, G.Section, G.Stepper
    page.subCadres = Pill(page, 150, 30, "Cadres", function() page.sub = "cadres" G.Refresh() end, "Interface\\Icons\\INV_Misc_Head_Dwarf_01")
    page.subCadres:SetPoint("TOPLEFT", 0, 0)
    page.subCarte = Pill(page, 150, 30, "Mini-carte", function() page.sub = "carte" G.Refresh() end, "Interface\\Icons\\INV_Misc_Map_01")
    page.subCarte:SetPoint("LEFT", page.subCadres, "RIGHT", 8, 0)
    page.sub = "cadres"
    local s = CreateFrame("Frame", nil, page)
    s:SetPoint("TOPLEFT", 0, -42)
    s:SetSize(668, 340)
    page.cadres = s
    Section(s, "Cadres des personnages", 0, 0, 290)
    s.on = Pill(s, 120, 30, "Activés", function() C.SetOn(true) end)
    s.on:SetPoint("TOPLEFT", 0, -22)
    s.off = Pill(s, 150, 30, "Ceux du jeu", function() C.SetOn(false) end)
    s.off:SetPoint("LEFT", s.on, "RIGHT", 8, 0)
    s.reload = Pill(s, 196, 30, "Recharger l'interface", function() if ReloadUI then ReloadUI() end end, "Interface\\Icons\\Spell_Holy_Resurrection")
    s.reload:SetPoint("TOPLEFT", 472, -22)
    s.social = Pill(s, 154, 30, "", function()
        C.Config().social = C.Config().social ~= "haut" and "haut" or nil
        C.MoveSocial()
        G.Refresh()
    end, "Interface\\FriendsFrame\\Battlenet-Portrait")
    s.social:SetPoint("TOPLEFT", 310, -22)
    Section(s, "Style", 0, -62, 290)
    s.styles = {}
    for i, st in ipairs(C.STYLES) do
        local b = Pill(s, 92, 28, st[2], function() C.Set("style", st[1]) end)
        b:SetPoint("TOPLEFT", (i - 1) * 98, -84)
        s.styles[i] = b
    end
    Section(s, "Texte de la vie", 310, -62, 290)
    s.texts = {}
    for i, t in ipairs(C.TEXTS) do
        local b = Pill(s, 72, 28, t[2], function() C.Set("text", t[1]) end)
        b:SetPoint("TOPLEFT", 310 + (i - 1) * 76, -84)
        s.texts[i] = b
    end
    Section(s, "Texte de la ressource (mana, rage, énergie…) : la barre s'épaissit pour l'afficher", 0, -124, 600)
    s.ptexts = {}
    for i, t in ipairs(C.PTEXTS) do
        local b = Pill(s, i == 3 and 130 or 90, 28, t[2], function() C.Set("ppText", t[1]) end)
        b:SetPoint("TOPLEFT", ({0, 96, 192, 328})[i], -146)
        s.ptexts[i] = b
    end
    Section(s, "Choisis un cadre", 0, -186, 600)
    s.units = {}
    local x = 0
    for i, d in ipairs(C.UNITS) do
        local w = #d.label * 7 + 30
        local b = Pill(s, w, 28, d.label, function() C.sel = d.key G.Refresh() end)
        b:SetPoint("TOPLEFT", x, -208)
        x = x + w + 6
        s.units[i] = b
    end
    s.shown = Pill(s, 100, 28, "Affiché", function() C.SetUnit("off", nil) end)
    s.shown:SetPoint("TOPLEFT", 0, -250)
    s.hiddenB = Pill(s, 90, 28, "Caché", function() C.SetUnit("off", true) end)
    s.hiddenB:SetPoint("LEFT", s.shown, "RIGHT", 6, 0)
    -- Groupe : en colonne ou en ligne (seulement quand « Groupe » est choisi).
    s.column = Pill(s, 96, 28, "Colonne", function() C.Set("partyRow", nil) end)
    s.column:SetPoint("TOPLEFT", 410, -250)
    s.row = Pill(s, 96, 28, "En ligne", function() C.Set("partyRow", true) end)
    s.row:SetPoint("LEFT", s.column, "RIGHT", 6, 0)
    s.effects = Pill(s, 120, 28, "", function()
        local u = C.Config().units[C.sel]
        if u.auras == false then u.auras = nil else u.auras = false end
        Refresh()
    end)
    s.effects:SetPoint("TOPLEFT", 410, -250)
    s.gameBuffs = Pill(s, 136, 28, "", function() C.Set("hideBuffs", not C.Config().hideBuffs) end)
    s.gameBuffs:SetPoint("LEFT", s.effects, "RIGHT", 6, 0)
    s.sizeLabel = Font2(s, "GameFontNormalSmall", "Taille")
    s.sizeLabel:SetPoint("TOPLEFT", 214, -258)
    s.size = Stepper(s, 258, -248, function() C.StepScale(-.05) end, function() C.StepScale(.05) end)
    s.widthLabel = Font2(s, "GameFontNormalSmall", "Largeur")
    s.widthLabel:SetPoint("TOPLEFT", 0, -300)
    s.width = Stepper(s, 56, -290, function() C.StepDim("width", -.1) end, function() C.StepDim("width", .1) end)
    s.heightLabel = Font2(s, "GameFontNormalSmall", "Hauteur")
    s.heightLabel:SetPoint("TOPLEFT", 214, -300)
    s.height = Stepper(s, 270, -290, function() C.StepDim("height", -.1) end, function() C.StepDim("height", .1) end)
    s.dimReset = Pill(s, 100, 28, "100 %", function()
        local u = C.Config().units[C.sel]
        u.width, u.height = nil, nil
        Refresh()
    end)
    s.dimReset:SetPoint("TOPLEFT", 430, -290)
    Section(s, "Place", 0, -334, 600)
    s.move = Pill(s, 200, 30, "Déplacer les cadres", function()
        if G.panel then G.panel:Hide() end
        C.StartMove(function() if not InCombatLockdown() then G.Open(page.tabIndex) end end)
    end, "Interface\\Icons\\Ability_Rogue_Sprint")
    s.move:SetPoint("TOPLEFT", 0, -356)
    s.back = Pill(s, 110, 30, "Remettre", function() C.Reset() end)
    s.back:SetPoint("LEFT", s.move, "RIGHT", 8, 0)
    s.help = Font2(s, "GameFontHighlightSmall", "Toucher un cadre cible le personnage, même en combat. Cadres du jeu : « Ceux du jeu » puis « Recharger l'interface ».")
    s.help:SetPoint("TOPLEFT", 0, -394)
    s.help:SetWidth(600)
    s.help:SetJustifyH("LEFT")
    if addon.carte and addon.carte.BuildSettings then addon.carte.BuildSettings(page, G) end
end

function C.RefreshSettings(page)
    if not page or not page.cadres then return end
    local sub = page.sub or "cadres"
    page.subCadres:Paint(sub == "cadres")
    page.subCarte:Paint(sub == "carte")
    page.cadres:SetShown(sub == "cadres")
    if page.carte then page.carte:SetShown(sub == "carte") end
    if addon.carte and addon.carte.RefreshSettings then addon.carte.RefreshSettings(page) end
    local s, c = page.cadres, C.Config()
    s.on:Paint(c.on and true or false)
    s.off:Paint(not c.on)
    s.reload:SetShown(C.needReload and true or false)
    for i, b in ipairs(s.styles) do b:Paint((c.style or "classique") == C.STYLES[i][1]) end
    for i, b in ipairs(s.texts) do b:Paint((c.text or "pct") == C.TEXTS[i][1]) end
    for i, b in ipairs(s.ptexts) do b:Paint((c.ppText or "non") == C.PTEXTS[i][1]) end
    for i, b in ipairs(s.units) do b:Paint(C.sel == C.UNITS[i].key) end
    local off = c.units[C.sel].off
    s.shown:Paint(not off)
    local withAuras = C.sel == "player" or C.sel == "target" or C.sel == "pet"
    s.effects:SetShown(withAuras)
    s.effects.text:SetText(c.units[C.sel].auras == false and "Effets : non" or "Effets : oui")
    s.effects:Paint(c.units[C.sel].auras ~= false)
    s.gameBuffs:SetShown(C.sel == "player")
    s.gameBuffs.text:SetText(c.hideBuffs and "Ceux du jeu : cachés" or "Ceux du jeu : là")
    s.gameBuffs:Paint(c.hideBuffs and true or false)
    s.column:SetShown(C.sel == "party")
    s.row:SetShown(C.sel == "party")
    s.column:Paint(not c.partyRow)
    s.row:Paint(c.partyRow and true or false)
    s.social.text:SetText(c.social == "haut" and "Amis : en haut" or "Amis : en bas")
    s.social:Paint(c.social ~= "haut")
    s.hiddenB:Paint(off and true or false)
    s.size:SetText(math.floor(C.ScaleOf(C.sel) * 100 + .5) .. " %")
    local u = c.units[C.sel]
    s.width:SetText(math.floor((tonumber(u.width) or 1) * 100 + .5) .. " %")
    s.height:SetText(math.floor((tonumber(u.height) or 1) * 100 + .5) .. " %")
end
