-- Streaming Touch (licence MIT, voir LICENSE.txt).
-- Mini-carte (2.7) : ronde, carrée ou arrondie, avec un thème (or, acier, arcane, bois, sombre, minimal),
-- à la taille et à la place voulues. Épurée : seulement la carte, le nom de la zone, l'heure et les coordonnées.
local _, addon = ...
if not addon or not addon.enabled then return end

local WHITE = "Interface\\Buttons\\WHITE8X8"
local CIRCLE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local ROUNDED = "Interface\\AddOns\\StreamingTouch\\Media\\MasqueArrondi"
local function Say(text) print("|cffe8c46aStreaming Touch|r : " .. text) end

local M = {hiddenFrames = {}}
addon.carte = M
-- Forme : nom, libellé, forme annoncée aux autres addons, masque de la carte, masque du cadre.
M.SHAPES = {
    {"rond", "Ronde", "ROUND", "Textures\\MinimapMask", CIRCLE},
    {"carre", "Carrée", "SQUARE", WHITE, nil},
    {"arrondi", "Arrondie", "SQUARE", ROUNDED, ROUNDED},
}
-- Thème : couleur du cadre, du filet intérieur, épaisseur.
M.THEMES = {
    {"or", "Or", {.93, .66, .2, 1}, {.36, .22, .06, 1}, 5},
    {"acier", "Acier", {.72, .75, .8, 1}, {.16, .17, .2, 1}, 4},
    {"arcane", "Arcane", {.55, .5, .95, 1}, {.14, .1, .33, 1}, 4},
    {"bois", "Bois", {.47, .3, .14, 1}, {.2, .12, .05, 1}, 7},
    {"sombre", "Sombre", {.04, .04, .05, 1}, {.3, .3, .33, 1}, 6},
    {"minimal", "Minimal", {1, 1, 1, .45}, {0, 0, 0, 0}, 1.5},
}
local function Find(list, key)
    for _, x in ipairs(list) do if x[1] == key then return x end end
    return list[1]
end

function M.Config()
    StreamingTouchDB = StreamingTouchDB or {}
    local c = StreamingTouchDB.carte
    if type(c) ~= "table" then
        c = {shape = "rond", theme = "or", size = 170, coords = true, zoom = true}
        StreamingTouchDB.carte = c
    end
    return c
end

-- Ce qui entoure la carte d'origine et qu'on enlève (s'il existe dans ce jeu).
local DECOR = {"MinimapBorder", "MinimapBorderTop", "MinimapZoomIn", "MinimapZoomOut", "MiniMapWorldMapButton",
    "MinimapToggleButton", "MinimapZoneTextButton", "MinimapNorthTag", "MinimapCompassTexture", "MinimapBackdrop",
    "GameTimeFrame", "TimeManagerClockButton", "MiniMapTrackingFrame", "MiniMapTracking", "MinimapCluster"}

local function Hide(f)
    if type(f) ~= "table" or M.hiddenFrames[f] then return end
    M.hiddenFrames[f] = true
    pcall(f.Hide, f)
    if f.HookScript then
        pcall(f.HookScript, f, "OnShow", function(self) if M.active then self:Hide() end end)
    end
end

local function Text(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    if STANDARD_TEXT_FONT and fs.SetFont then pcall(fs.SetFont, fs, STANDARD_TEXT_FONT, size, "OUTLINE") end
    if not fs:GetFont() and fs.SetFontObject then fs:SetFontObject("GameFontHighlightSmall") end
    fs:SetShadowOffset(1, -1)
    return fs
end

function M.Build()
    if M.holder then return end
    local h = CreateFrame("Frame", "StreamingTouchCarte", UIParent)
    h:SetFrameStrata("LOW")
    h:SetSize(170, 170)
    h.layers = {}
    for i, sub in ipairs({-3, -2, -1}) do
        local t = h:CreateTexture(nil, "BACKGROUND", nil, sub)
        t:SetTexture(WHITE)
        t:SetPoint("CENTER")
        t.mask = h:CreateMaskTexture()
        t.mask:SetAllPoints(t)
        h.layers[i] = t
    end
    h.shadow, h.edge, h.line = h.layers[1], h.layers[2], h.layers[3]
    h.info = CreateFrame("Frame", nil, h)
    h.info:SetAllPoints()
    h.zone = Text(h.info, 12)
    h.zone:SetPoint("TOP", h, "BOTTOM", 0, -6)
    h.coords = Text(h.info, 10)
    h.coords:SetPoint("TOP", h.zone, "BOTTOM", 0, -2)
    h.clock = Text(h.info, 11)
    h.clock:SetPoint("TOP", h, "TOP", 0, -6)
    -- Toucher le nom de la zone : la carte du monde.
    h.zoneButton = CreateFrame("Button", nil, h.info)
    h.zoneButton:SetAllPoints(h.zone)
    h.zoneButton:SetScript("OnClick", function()
        if ToggleWorldMap then pcall(ToggleWorldMap) end
    end)
    h.zoom = {}
    for i, def in ipairs({{"+", 1, "BOTTOMRIGHT"}, {"-", -1, "BOTTOMLEFT"}}) do
        local b = CreateFrame("Button", nil, h.info)
        b:SetSize(26, 26)
        b.text = Text(b, 18)
        b.text:SetPoint("CENTER")
        b.text:SetText(def[1])
        b:SetScript("OnClick", function() M.Zoom(def[2]) end)
        h.zoom[i] = b
    end
    M.holder = h
end

function M.Zoom(step)
    if not Minimap or not Minimap.GetZoom then return end
    local levels = Minimap.GetZoomLevels and Minimap:GetZoomLevels() or 6
    local z = math.max(0, math.min(levels - 1, (Minimap:GetZoom() or 0) + step))
    Minimap:SetZoom(z)
end

function M.Pos()
    local c = M.Config()
    if type(c.pos) == "table" and tonumber(c.pos.x) and tonumber(c.pos.y) then return c.pos.x, c.pos.y end
    if M.home then return M.home[1], M.home[2] end
    return UIParent:GetWidth() - 110, UIParent:GetHeight() - 110
end

-- Habille le cadre : ombre, bordure du thème, filet. La carte (enfant) passe au-dessus.
function M.Paint()
    local h, c = M.holder, M.Config()
    local shape, theme = Find(M.SHAPES, c.shape), Find(M.THEMES, c.theme)
    local size = math.max(110, math.min(280, tonumber(c.size) or 170))
    local w = theme[5]
    h:SetSize(size, size)
    local sizes = {size + 2 * w + 8, size + 2 * w, size + 2}
    for i, t in ipairs(h.layers) do
        t:SetSize(sizes[i], sizes[i])
        if shape[5] then
            t.mask:SetTexture(shape[5], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            if not t.masked then t:AddMaskTexture(t.mask) t.masked = true end
        elseif t.masked then
            t:RemoveMaskTexture(t.mask)
            t.masked = nil
        end
    end
    h.shadow:SetVertexColor(0, 0, 0, theme[1] == "minimal" and 0 or .45)
    h.edge:SetVertexColor(unpack(theme[3]))
    h.line:SetVertexColor(unpack(theme[4]))
    for _, b in ipairs(h.zoom) do b:SetShown(c.zoom ~= false) end
    h.zoom[1]:ClearAllPoints()
    h.zoom[1]:SetPoint("CENTER", h, "BOTTOMRIGHT", -size * .15, size * .15)
    h.zoom[2]:ClearAllPoints()
    h.zoom[2]:SetPoint("CENTER", h, "BOTTOMLEFT", size * .15, size * .15)
    h.coords:SetShown(c.coords ~= false)
    M.shapeName = shape[3]
    if Minimap then
        Minimap:SetSize(size, size)
        pcall(Minimap.SetMaskTexture, Minimap, shape[4])
        -- La carte se redessine à la nouvelle taille.
        if Minimap.GetZoom then
            local z = Minimap:GetZoom()
            Minimap:SetZoom(z > 0 and z - 1 or z + 1)
            Minimap:SetZoom(z)
        end
    end
end

-- Icônes d'addons autour de la carte (LibDBIcon) : replacées sur le bord, selon la forme.
function M.RefreshIcons()
    local lib = LibStub and LibStub("LibDBIcon-1.0", true)
    if not lib or not lib.GetButtonList then return end
    for _, name in ipairs(lib:GetButtonList()) do pcall(lib.Refresh, lib, name) end
end

function M.Place()
    local h = M.holder
    if not h then return end
    local x, y = M.Pos()
    h:ClearAllPoints()
    h:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

function M.Apply()
    local c = M.Config()
    if not c.on then
        if M.active then M.Restore() end
        return
    end
    if not Minimap then return end
    M.Build()
    if not M.active then
        -- On garde la place d'origine : la carte reste au même endroit au premier essai.
        M.orig = {parent = Minimap:GetParent(), points = {}, w = Minimap:GetWidth(), h = Minimap:GetHeight()}
        for i = 1, (Minimap.GetNumPoints and Minimap:GetNumPoints() or 0) do M.orig.points[i] = {Minimap:GetPoint(i)} end
        local cx, cy = Minimap:GetCenter()
        if cx and not M.home then
            local s = (Minimap:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
            M.home = {cx * s, cy * s}
        end
        M.active = true
        Minimap:SetParent(M.holder)
        Minimap:ClearAllPoints()
        Minimap:SetPoint("CENTER", M.holder, "CENTER")
        Minimap:SetFrameLevel(M.holder:GetFrameLevel() + 2)
        M.holder.info:SetFrameLevel(M.holder:GetFrameLevel() + 8)
        if Minimap.EnableMouseWheel then Minimap:EnableMouseWheel(true) end
        Minimap:SetScript("OnMouseWheel", function(_, delta) M.Zoom(delta > 0 and 1 or -1) end)
        for _, name in ipairs(DECOR) do Hide(_G[name]) end
        for _, key in ipairs({"ZoomIn", "ZoomOut", "ZoomHitArea"}) do Hide(Minimap[key]) end
        -- Courrier et files d'attente : gardés, posés sur le bord.
        local mail = _G.MiniMapMailFrame or (MinimapCluster and MinimapCluster.IndicatorFrame)
        if type(mail) == "table" then
            pcall(mail.SetParent, mail, M.holder.info)
            pcall(mail.ClearAllPoints, mail)
            pcall(mail.SetPoint, mail, "TOPLEFT", M.holder, "TOPLEFT", -4, 4)
        end
        local queue = _G.MiniMapBattlefieldFrame or _G.QueueStatusButton or _G.LFGMinimapFrame
        if type(queue) == "table" then
            pcall(queue.SetParent, queue, M.holder.info)
            pcall(queue.ClearAllPoints, queue)
            pcall(queue.SetPoint, queue, "TOPRIGHT", M.holder, "TOPRIGHT", 4, 4)
        end
    end
    M.holder:Show()
    M.Paint()
    M.Place()
    M.Update()
    M.RefreshIcons()
    -- Les addons qui créent leur icône plus tard (au chargement) : encore une fois après quelques secondes.
    if C_Timer and C_Timer.After then C_Timer.After(3, function() if M.active then M.RefreshIcons() end end) end
end

function M.Restore()
    M.active = nil
    if M.holder then M.holder:Hide() end
    if not Minimap or not M.orig then return end
    Minimap:SetParent(M.orig.parent or UIParent)
    Minimap:ClearAllPoints()
    for _, p in ipairs(M.orig.points) do Minimap:SetPoint(unpack(p)) end
    if M.orig.w then Minimap:SetSize(M.orig.w, M.orig.h) end
    pcall(Minimap.SetMaskTexture, Minimap, "Textures\\MinimapMask")
    M.shapeName = "ROUND"
    if MinimapCluster then MinimapCluster:Show() end
    M.RefreshIcons()
    M.needReload = true
end

-- Nom de la zone (couleur : amie, ennemie, contestée), heure et coordonnées.
local ZONE = {friendly = {.3, .95, .3}, hostile = {1, .3, .3}, contested = {1, .7, .2}, sanctuary = {.4, .75, 1}}
function M.Update()
    local h = M.holder
    if not h or not M.active then return end
    local zone = (GetMinimapZoneText and GetMinimapZoneText()) or (GetZoneText and GetZoneText()) or ""
    h.zone:SetText(zone)
    local pvp = GetZonePVPInfo and GetZonePVPInfo()
    local col = ZONE[pvp or ""] or {1, .86, .5}
    h.zone:SetTextColor(col[1], col[2], col[3])
    h.clock:SetText(date and date("%H:%M") or "")
    if M.Config().coords ~= false and C_Map and C_Map.GetBestMapForUnit then
        local ok = pcall(function()
            local map = C_Map.GetBestMapForUnit("player")
            local pos = map and C_Map.GetPlayerMapPosition(map, "player")
            if pos then
                local x, y = pos:GetXY()
                h.coords:SetFormattedText("%.1f, %.1f", x * 100, y * 100)
            else
                h.coords:SetText("")
            end
        end)
        if not ok then h.coords:SetText("") end
    end
end

-- Les autres addons (icônes autour de la carte, points de quête) suivent la forme.
local previousShape = GetMinimapShape
function GetMinimapShape()
    if M.active then return M.shapeName or "ROUND" end
    if previousShape then return previousShape() end
    return "ROUND"
end

-- Déplacer la carte : on glisse le doigt n'importe où, elle suit.
function M.StartMove(done)
    local c = M.Config()
    if not c.on then Say("active d'abord la mini-carte.") return end
    local m = M.mover
    if not m then
        m = CreateFrame("Frame", nil, UIParent)
        M.mover = m
        m:SetAllPoints(UIParent)
        m:SetFrameStrata("FULLSCREEN_DIALOG")
        m:EnableMouse(true)
        local shade = m:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        shade:SetColorTexture(.02, .06, .14, .25)
        m.text = Text(m, 14)
        m.text:SetPoint("TOP", 0, -90)
        m.text:SetText("Glisse le doigt : la mini-carte suit. Puis touche « Terminé ».")
        local ok = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
        ok:SetSize(140, 30)
        ok:SetText("Terminé")
        ok:SetPoint("TOP", 0, -130)
        ok:SetScript("OnClick", function() M.EndMove() end)
        m.ok = ok
        m:SetScript("OnMouseDown", function(self)
            local s = UIParent:GetEffectiveScale()
            local x, y = GetCursorPosition()
            local px, py = M.Pos()
            self.grab = {x / s, y / s, px, py}
        end)
        m:SetScript("OnMouseUp", function(self) self.grab = nil end)
        m:SetScript("OnUpdate", function(self)
            local g = self.grab
            if not g then return end
            local s = UIParent:GetEffectiveScale()
            local x, y = GetCursorPosition()
            M.Config().pos = {x = g[3] + x / s - g[1], y = g[4] + y / s - g[2]}
            M.Place()
        end)
    end
    m.done = done
    m:Show()
end
function M.EndMove()
    local m = M.mover
    if not m then return end
    m.grab = nil
    m:Hide()
    Say("mini-carte placée.")
    if m.done then m.done() end
end

-- Réglages (dans l'onglet « Cadres », partie « Mini-carte »).
local function Refresh()
    M.Apply()
    if addon.settings and addon.settings.Refresh then pcall(addon.settings.Refresh) end
end
function M.Set(field, value)
    M.Config()[field] = value
    Refresh()
end
function M.StepSize(delta)
    local c = M.Config()
    c.size = math.max(110, math.min(280, (tonumber(c.size) or 170) + delta))
    Refresh()
end

function M.BuildSettings(page, G)
    local Pill, Font, Section, Stepper = G.Pill, G.Font, G.Section, G.Stepper
    local s = CreateFrame("Frame", nil, page)
    s:SetPoint("TOPLEFT", 0, -42)
    s:SetSize(668, 340)
    page.carte = s
    Section(s, "Mini-carte", 0, 0, 290)
    s.on = Pill(s, 120, 30, "Activée", function() M.Set("on", true) end)
    s.on:SetPoint("TOPLEFT", 0, -22)
    s.off = Pill(s, 150, 30, "Celle du jeu", function() M.Set("on", nil) end)
    s.off:SetPoint("LEFT", s.on, "RIGHT", 8, 0)
    s.reload = Pill(s, 200, 30, "Recharger l'interface", function() if ReloadUI then ReloadUI() end end, "Interface\\Icons\\Spell_Holy_Resurrection")
    s.reload:SetPoint("TOPLEFT", 310, -22)
    Section(s, "Forme", 0, -62, 290)
    s.shapes = {}
    for i, sh in ipairs(M.SHAPES) do
        local b = Pill(s, 92, 28, sh[2], function() M.Set("shape", sh[1]) end)
        b:SetPoint("TOPLEFT", (i - 1) * 98, -84)
        s.shapes[i] = b
    end
    Section(s, "Taille", 310, -62, 290)
    s.size = Stepper(s, 310, -82, function() M.StepSize(-10) end, function() M.StepSize(10) end)
    Section(s, "Thème", 0, -124, 600)
    s.themes = {}
    for i, th in ipairs(M.THEMES) do
        local b = Pill(s, 94, 28, th[2], function() M.Set("theme", th[1]) end)
        b:SetPoint("TOPLEFT", (i - 1) * 100, -146)
        s.themes[i] = b
    end
    Section(s, "Autour de la carte", 0, -188, 600)
    s.coords = Pill(s, 170, 28, "", function() M.Set("coords", M.Config().coords == false) end)
    s.coords:SetPoint("TOPLEFT", 0, -210)
    s.zoom = Pill(s, 170, 28, "", function() M.Set("zoom", M.Config().zoom == false) end)
    s.zoom:SetPoint("LEFT", s.coords, "RIGHT", 8, 0)
    Section(s, "Place", 0, -250, 600)
    s.move = Pill(s, 200, 30, "Déplacer la carte", function()
        if G.panel then G.panel:Hide() end
        M.StartMove(function() G.Open(page.tabIndex) end)
    end, "Interface\\Icons\\Ability_Rogue_Sprint")
    s.move:SetPoint("TOPLEFT", 0, -272)
    s.back = Pill(s, 110, 30, "Remettre", function() M.Set("pos", nil) end)
    s.back:SetPoint("LEFT", s.move, "RIGHT", 8, 0)
    s.help = Font(s, "GameFontHighlightSmall", "Toucher le nom de la zone ouvre la carte du monde. + et - (dans les coins) zooment.")
    s.help:SetPoint("TOPLEFT", 0, -312)
    s.help:SetWidth(600)
    s.help:SetJustifyH("LEFT")
end

function M.RefreshSettings(page)
    local s = page and page.carte
    if not s then return end
    local c = M.Config()
    s.on:Paint(c.on and true or false)
    s.off:Paint(not c.on)
    s.reload:SetShown(M.needReload and true or false)
    for i, b in ipairs(s.shapes) do b:Paint((c.shape or "rond") == M.SHAPES[i][1]) end
    for i, b in ipairs(s.themes) do b:Paint((c.theme or "or") == M.THEMES[i][1]) end
    s.size:SetText(tostring(math.floor(tonumber(c.size) or 170)))
    s.coords.text:SetText(c.coords == false and "Coordonnées : non" or "Coordonnées : oui")
    s.coords:Paint(c.coords ~= false)
    s.zoom.text:SetText(c.zoom == false and "Boutons + - : non" or "Boutons + - : oui")
    s.zoom:Paint(c.zoom ~= false)
end

local events = CreateFrame("Frame")
M.events = events
for _, ev in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
    "ZONE_CHANGED_NEW_AREA"}) do
    pcall(events.RegisterEvent, events, ev)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if M.Config().on then M.Apply() end
        return
    end
    M.Update()
end)
events:SetScript("OnUpdate", function(self, elapsed)
    self.wait = (self.wait or 0) - (elapsed or 0)
    if self.wait > 0 then return end
    self.wait = .5
    if M.active then pcall(M.Update) end
end)
