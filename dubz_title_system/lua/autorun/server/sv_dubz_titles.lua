AddCSLuaFile("autorun/sh_dubz_titles_config.lua")
AddCSLuaFile("autorun/client/cl_dubz_titles.lua")

include("autorun/sh_dubz_titles_config.lua")

util.AddNetworkString("DubzTitles_OpenMenu")
util.AddNetworkString("DubzTitles_SendData")
util.AddNetworkString("DubzTitles_BuyOrUse")

local function EnsureFolder()
    if not file.Exists(DubzTitles.Config.DataFolder, "DATA") then
        file.CreateDir(DubzTitles.Config.DataFolder)
    end
end

local function GetPlayerFileName(ply)
    -- Titles belong to the character (Steam ID + character; see DubzChars.GetKey)
    local id = (DubzChars and DubzChars.GetKey) and DubzChars.GetKey(ply) or ply:SteamID64()

    if not id or id == "0" then
        id = string.Replace(ply:SteamID() or ply:UniqueID(), ":", "_")
    end

    return DubzTitles.Config.DataFolder .. "/" .. id .. ".txt"
end

local function DefaultData()
    return {
        ownedTitles = {},
        ownedColors = {
            white = true
        },
        activeTitle = "",
        activeColor = {
            mode = "preset",
            id = "white",
            r = 255,
            g = 255,
            b = 255
        }
    }
end

local function NormalizeData(data)
    data = istable(data) and data or DefaultData()

    data.ownedTitles = istable(data.ownedTitles) and data.ownedTitles or {}
    data.ownedColors = istable(data.ownedColors) and data.ownedColors or { white = true }

    data.activeTitle = isstring(data.activeTitle) and data.activeTitle or ""

    data.activeColor = istable(data.activeColor) and data.activeColor or {
        mode = "preset",
        id = "white",
        r = 255,
        g = 255,
        b = 255
    }

    data.ownedColors.white = true

    return data
end

local function LoadPlayerData(ply)
    EnsureFolder()

    local path = GetPlayerFileName(ply)
    local data = DefaultData()

    if file.Exists(path, "DATA") then
        local raw = file.Read(path, "DATA")
        local decoded = util.JSONToTable(raw or "")

        if istable(decoded) then
            data = decoded
        end
    end

    data = NormalizeData(data)
    ply.DubzTitlesData = data

    return data
end

local function SavePlayerData(ply)
    if not IsValid(ply) then return end

    EnsureFolder()

    local data = NormalizeData(ply.DubzTitlesData)
    ply.DubzTitlesData = data

    file.Write(GetPlayerFileName(ply), util.TableToJSON(data, true))
end

local function GetData(ply)
    return ply.DubzTitlesData or LoadPlayerData(ply)
end

local function SyncPlayerTitle(ply)
    -- Master switch off: nobody has a title shown
    if not DubzTitles.Enabled() then
        ply:SetNWString("DubzTitles_Title", "")
        return
    end

    local data = GetData(ply)
    local titleInfo = DubzTitles.FindTitle(data.activeTitle)
    local colorInfo = data.activeColor or {}

    ply:SetNWString("DubzTitles_Title", titleInfo and titleInfo.name or "")
    ply:SetNWVector("DubzTitles_Color", Vector(colorInfo.r or 255, colorInfo.g or 255, colorInfo.b or 255))
end

local function SendPlayerData(ply)
    if not IsValid(ply) then return end

    net.Start("DubzTitles_SendData")
        net.WriteTable(GetData(ply))
        net.WriteBool(DubzTitles.IsVIP(ply))

        local earned = 0
        if DubzTitles.Config.UseMoneyTracker and DubzMoney then
            earned = DubzMoney.GetMoneyEarned(ply)
        else
            earned = ply.DubzTitlesData.moneyEarned or 0
        end

        net.WriteUInt(earned, 32)
    net.Send(ply)
end

local function CanAfford(ply, amount)
    amount = tonumber(amount) or 0

    if amount <= 0 then return true end

    if ply.canAfford then
        return ply:canAfford(amount)
    end

    return true
end

local function TakeMoney(ply, amount)
    amount = tonumber(amount) or 0

    if amount <= 0 then return end

    if ply.addMoney then
        ply:addMoney(-amount)
    end
end

local function Chat(ply, msg)
    if IsValid(ply) then
        ply:ChatPrint("[Dubz Titles] " .. msg)
    end
end

hook.Add("PlayerInitialSpawn", "DubzTitles_LoadPlayer", function(ply)
    LoadPlayerData(ply)

    timer.Simple(1, function()
        if not IsValid(ply) then return end

        SyncPlayerTitle(ply)
        SendPlayerData(ply)
    end)
end)

hook.Add("PlayerSpawn", "DubzTitles_SyncOnSpawn", function(ply)
    timer.Simple(0.25, function()
        if not IsValid(ply) then return end
        SyncPlayerTitle(ply)
        SendPlayerData(ply)
    end)
end)

hook.Add("PlayerDisconnected", "DubzTitles_SavePlayer", function(ply)
    SavePlayerData(ply)
end)

-- A deleted (wiped) character takes its titles with it
hook.Add("DubzCharWipe", "DubzTitles_CharWipe", function(account, charId, keys)
    for _, key in ipairs(keys) do
        local path = DubzTitles.Config.DataFolder .. "/" .. string.Replace(key, ":", "_") .. ".txt"
        if file.Exists(path, "DATA") then file.Delete(path) end
    end
end)

-- Switching characters: this one's titles are saved, the next one's loaded (the first character inherits the old file)
hook.Add("DubzCharLeave", "DubzTitles_CharLeave", function(ply) SavePlayerData(ply) end)

hook.Add("DubzCharLoad", "DubzTitles_CharLoad", function(ply)
    local path = GetPlayerFileName(ply)

    if not file.Exists(path, "DATA") and DubzChars and DubzChars.LegacyKey then
        local legacy = DubzChars.LegacyKey(ply)
        local legacyPath = legacy and (DubzTitles.Config.DataFolder .. "/" .. legacy .. ".txt")

        if legacyPath and file.Exists(legacyPath, "DATA") then file.Write(path, file.Read(legacyPath, "DATA")) end
    end

    LoadPlayerData(ply)

    timer.Simple(0.5, function()
        if not IsValid(ply) then return end
        SyncPlayerTitle(ply)
        SendPlayerData(ply)
    end)
end)

net.Receive("DubzTitles_BuyOrUse", function(_, ply)
    if not DubzTitles.Enabled() then return end

    local titleID = net.ReadString()
    local colorMode = net.ReadString()
    local colorID = net.ReadString()
    local customColor = net.ReadColor()

    local titleInfo = DubzTitles.FindTitle(titleID)

    if not titleInfo then
        Chat(ply, "Invalid title.")
        return
    end

    -- Progression requirement check
    local earned = 0

    if DubzTitles.Config.UseMoneyTracker and DubzMoney and DubzMoney.GetMoneyEarned then
        earned = DubzMoney.GetMoneyEarned(ply)
    else
        earned = (ply.DubzTitlesData and ply.DubzTitlesData.moneyEarned) or 0
    end

    if titleInfo.required and earned < titleInfo.required then
        Chat(ply, "You need $" .. titleInfo.required .. " earned to unlock this title.")
        return
    end

    if titleInfo.vip and not DubzTitles.IsVIP(ply) then
        Chat(ply, "That title is VIP only.")
        return
    end

    local data = GetData(ply)
    local totalCost = 0

    if not data.ownedTitles[titleID] then
        totalCost = totalCost + (tonumber(titleInfo.price) or 0)
    end

    local activeColor

    if colorMode == "custom" then
        local r = math.Clamp(customColor.r or 255, 0, 255)
        local g = math.Clamp(customColor.g or 255, 0, 255)
        local b = math.Clamp(customColor.b or 255, 0, 255)

        activeColor = {
            mode = "custom",
            id = "custom",
            r = r,
            g = g,
            b = b
        }

        totalCost = totalCost + (tonumber(DubzTitles.Config.CustomColorPrice) or 0)
    else
        local colorInfo = DubzTitles.FindColor(colorID) or DubzTitles.FindColor("white")

        if not colorInfo then
            Chat(ply, "Invalid color.")
            return
        end

        activeColor = {
            mode = "preset",
            id = colorInfo.id,
            r = colorInfo.color.r,
            g = colorInfo.color.g,
            b = colorInfo.color.b
        }

        if not data.ownedColors[colorInfo.id] then
            totalCost = totalCost + (tonumber(colorInfo.price) or 0)
        end
    end

    if not CanAfford(ply, totalCost) then
        Chat(ply, "You cannot afford this.")
        return
    end

    TakeMoney(ply, totalCost)

    data.ownedTitles[titleID] = true

    if activeColor.mode == "preset" then
        data.ownedColors[activeColor.id] = true
    end

    data.activeTitle = titleID
    data.activeColor = activeColor

    SavePlayerData(ply)
    SyncPlayerTitle(ply)
    SendPlayerData(ply)

    if totalCost > 0 then
        Chat(ply, "Purchased and equipped for $" .. totalCost .. ".")
    else
        Chat(ply, "Title equipped.")
    end
end)

-- Counts earnings itself when the money tracker addon isn't used (checked live, so the admin menu switch applies)
do
    hook.Add("playerEarnedMoney", "DubzTitles_FallbackTracker", function(ply, amount)
        if DubzTitles.Config.UseMoneyTracker and DubzMoney then return end
        if amount <= 0 then return end

        local data = ply.DubzTitlesData or {}
        data.moneyEarned = (data.moneyEarned or 0) + amount
        ply.DubzTitlesData = data
    end)
end

-- Titles or colours edited in the admin menu: refresh every player's shown title and their store data
hook.Add("DFW_CollectionChanged", "DubzTitles_Resync", function(moduleId, collId, rows, actor)
    if moduleId ~= "titles" or actor == nil then return end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.DubzTitlesData then
            SyncPlayerTitle(ply)
            SendPlayerData(ply)
        end
    end
end)

-- Switching the module off / on: refresh everyone's shown title
hook.Add("DFW_ModuleStateChanged", "DubzTitles_Toggle", function(id)
    if id ~= "titles" then return end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.DubzTitlesData then SyncPlayerTitle(ply) end
    end
end)

-- The title NPC (entities/npc_title) calls this: send the player's data, then open the store
function DubzTitles.OpenMenu(ply)
    if not IsValid(ply) or not DubzTitles.Enabled() then return end

    LoadPlayerData(ply)
    SyncPlayerTitle(ply)
    SendPlayerData(ply)

    net.Start("DubzTitles_OpenMenu")
    net.Send(ply)
end

-- Title NPCs spawned from the entities tab are remembered per map (data/dubz_titles/npcs_<map>.json)
local function npcFile()
    return "dubz_titles/npcs_" .. game.GetMap() .. ".json"
end

local function saveNpcs()
    local list = {}

    for _, ent in ipairs(ents.FindByClass("npc_title")) do
        if ent.DubzSaved then
            local pos, ang = ent:GetPos(), ent:GetAngles()
            list[#list + 1] = {pos = {pos.x, pos.y, pos.z}, ang = {ang.p, ang.y, ang.r}}
        end
    end

    if not file.Exists("dubz_titles", "DATA") then file.CreateDir("dubz_titles") end
    file.Write(npcFile(), util.TableToJSON(list, true))
end

function DubzTitles.RememberNpc(ent)
    ent.DubzSaved = true
    timer.Simple(0, saveNpcs)
end

local function loadNpcs()
    local text = file.Exists(npcFile(), "DATA") and file.Read(npcFile(), "DATA")

    for _, row in ipairs((text and util.JSONToTable(text)) or {}) do
        local ent = ents.Create("npc_title")

        if IsValid(ent) and istable(row.pos) and istable(row.ang) then
            ent:SetPos(Vector(row.pos[1], row.pos[2], row.pos[3]))
            ent:SetAngles(Angle(row.ang[1], row.ang[2], row.ang[3]))
            ent:Spawn()
            ent.DubzSaved = true
        end
    end
end

hook.Add("InitPostEntity", "DubzTitles_LoadNpcs", function() timer.Simple(1, loadNpcs) end)

concommand.Add("dubz_titlenpc_remove", function(ply)
    if not IsValid(ply) or not DubzTitles.IsAdmin(ply) then return end

    local ent = ply:GetEyeTrace().Entity
    if not IsValid(ent) or ent:GetClass() ~= "npc_title" then ply:ChatPrint("[Dubz Titles] Look at a title NPC first.") return end

    ent:Remove()
    timer.Simple(0, saveNpcs)
end)

timer.Create("DubzTitles_AutoSave", 120, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.DubzTitlesData then
            SavePlayerData(ply)
        end
    end
end)