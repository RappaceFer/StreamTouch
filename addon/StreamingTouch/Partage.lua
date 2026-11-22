-- Streaming Touch : réglages en texte, pour les partager (/stouch, onglet Commandes : Exporter / Importer).
-- Le texte commence par « STOUCH1: ». Rien n'y est exécuté : on le lit comme des données, morceau par morceau.
-- Format : {clé valeur clé valeur …} ; s<longueur>:<texte> ; n<nombre>; ; t / f. Puis ~ | et retours à la ligne
-- sont échappés (~~ ~p ~n ~r), pour que le texte passe sans souci dans une zone de saisie ou un message.
local _, ST = ...
local ENTETE = "STOUCH1:"

local function Ecrire(v, out)
    local t = type(v)
    if t == "table" then
        out[#out + 1] = "{"
        local keys = {}
        for k in pairs(v) do
            if type(k) == "string" or type(k) == "number" then keys[#keys + 1] = k end
        end
        table.sort(keys, function(a, b)
            if type(a) == type(b) then return a < b end
            return type(a) == "number"
        end)
        for _, k in ipairs(keys) do
            local x = v[k]
            local tx = type(x)
            if tx == "table" or tx == "string" or tx == "number" or tx == "boolean" then
                Ecrire(k, out)
                Ecrire(x, out)
            end
        end
        out[#out + 1] = "}"
    elseif t == "string" then
        out[#out + 1] = "s" .. #v .. ":" .. v
    elseif t == "number" then
        out[#out + 1] = "n" .. string.format("%.10g", v) .. ";"
    elseif t == "boolean" then
        out[#out + 1] = v and "t" or "f"
    end
end

local ECHAPPE = {["~"] = "~~", ["|"] = "~p", ["\n"] = "~n", ["\r"] = "~r"}
local RETOUR = {["~"] = "~", p = "|", n = "\n", r = "\r"}

function ST.Encoder(valeur)
    local out = {}
    Ecrire(valeur, out)
    return ENTETE .. (table.concat(out):gsub("[~|\n\r]", ECHAPPE))
end

local function Lire(s, i, profondeur)
    if profondeur > 40 then error("texte trop imbriqué", 0) end
    local c = s:sub(i, i)
    if c == "{" then
        local t = {}
        i = i + 1
        while true do
            if i > #s then error("texte coupé", 0) end
            if s:sub(i, i) == "}" then return t, i + 1 end
            local k, v
            k, i = Lire(s, i, profondeur + 1)
            v, i = Lire(s, i, profondeur + 1)
            if type(k) ~= "string" and type(k) ~= "number" then error("texte abîmé", 0) end
            t[k] = v
        end
    elseif c == "s" then
        local n, j = s:match("^(%d+):()", i + 1)
        n = tonumber(n)
        if not n or j + n - 1 > #s then error("texte coupé", 0) end
        return s:sub(j, j + n - 1), j + n
    elseif c == "n" then
        local num, j = s:match("^([^;]+);()", i + 1)
        local x = tonumber(num)
        if not x then error("texte abîmé", 0) end
        return x, j
    elseif c == "t" then
        return true, i + 1
    elseif c == "f" then
        return false, i + 1
    end
    error("texte abîmé", 0)
end

-- Renvoie la valeur, ou nil et la raison.
function ST.Decoder(texte)
    texte = tostring(texte or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if texte:sub(1, #ENTETE) ~= ENTETE then return nil, "ce n'est pas un texte de Streaming Touch" end
    -- Un retour à la ligne ajouté en copiant (message, page web) ne fait pas partie du texte.
    local corps = texte:sub(#ENTETE + 1):gsub("[\r\n]", "")
    corps = corps:gsub("~(.)", function(c) return RETOUR[c] or c end)
    local ok, valeur, fin = pcall(Lire, corps, 1, 0)
    if not ok then return nil, valeur end
    if fin <= #corps then return nil, "texte abîmé" end
    return valeur
end
