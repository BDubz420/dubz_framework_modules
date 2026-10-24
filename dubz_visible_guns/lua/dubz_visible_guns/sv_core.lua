if not SERVER then return end

util.AddNetworkString("DubzVisibleGuns_Update")

CreateConVar("dvg_enabled", "1", FCVAR_ARCHIVE, "Enable Dubz Visible Guns.")
CreateConVar("dvg_show_active", "0", FCVAR_ARCHIVE, "Show the currently equipped weapon on the body.")
CreateConVar("dvg_play_holster_gesture", "1", FCVAR_ARCHIVE, "Play a small gesture when the visible weapon list changes.")

local playerCache = {}
local playerSlots = {}

local function IsEnabled()
    if not DubzVisibleGuns.Enabled() then return false end

    local cvar = GetConVar("dvg_enabled")
    return not cvar or cvar:GetBool()
end

local function ShouldShowActive()
    local cvar = GetConVar("dvg_show_active")
    return DubzVisibleGuns.Config.ShowActive == true or (cvar and cvar:GetBool())
end

local function ShouldGesture()
    local cvar = GetConVar("dvg_play_holster_gesture")
    return DubzVisibleGuns.Config.HolsterGesture ~= false and cvar and cvar:GetBool()
end

local function SafeWorldModel(weapon, weaponType)
    local class = IsValid(weapon) and weapon:GetClass() or ""
    local rule = DubzVisibleGuns.GetWeaponRule(class) or {}
    local model = rule.model

    if not model or model == "" then
        model = weapon.WorldModel
    end

    if not model or model == "" then
        model = DubzVisibleGuns.GetFallbackModel(weaponType)
    end

    return model
end

local function EmptySlots()
    local slots = {
        pistols = {},
        rifles = {}
    }

    for index = 1, DubzVisibleGuns.Config.MaxPistols do
        slots.pistols[index] = { empty = true }
    end

    for index = 1, DubzVisibleGuns.Config.MaxRifles do
        slots.rifles[index] = { empty = true }
    end

    return slots
end

local function WeaponData(weapon, weaponType)
    local rule = DubzVisibleGuns.GetWeaponRule(weapon:GetClass()) or {}

    return {
        kind = rule.kind,   -- "smg" for submachine guns (they hang on the hips differently from pistols)
        class = weapon:GetClass(),
        printName = weapon:GetPrintName() or weapon.PrintName or weapon:GetClass(),
        model = SafeWorldModel(weapon, weaponType)
    }
end

local function BuildAvailableWeapons(ply)
    local available = {
        pistols = {},
        rifles = {},
        pistolOrder = {},
        rifleOrder = {}
    }

    if not IsValid(ply) or not ply:Alive() or not IsEnabled() then
        return available
    end

    local active = ply:GetActiveWeapon()

    for _, weapon in ipairs(ply:GetWeapons()) do
        if IsValid(weapon) and (ShouldShowActive() or weapon ~= active) then
            local class = string.lower(weapon:GetClass() or "")
            local rule = DubzVisibleGuns.GetWeaponRule(class)

            if rule and (rule.type == "pistol" or rule.type == "rifle") then
                local list = available[rule.type .. "s"]
                local order = available[rule.type .. "Order"]
                local class = weapon:GetClass()

                list[class] = WeaponData(weapon, rule.type)
                order[#order + 1] = class
            end
        end
    end

    return available
end

local function SlotHasAvailableWeapon(slot, available)
    if not slot or slot.empty or not slot.class then return false end

    return available[slot.class] ~= nil
end

local function FirstEmptySlot(list)
    for index, slot in ipairs(list) do
        if (not slot or slot.empty) and not (slot and slot.disabled) then
            return index
        end
    end

    return nil
end

local function WeaponAlreadySlotted(slots, class)
    for _, slot in ipairs(slots) do
        if slot and not slot.empty and slot.class == class then
            return true
        end
    end

    return false
end

local function AssignStableSlots(previousSlots, available, order, slotName, maxSlots, group)
    local slots = {}
    local previous = previousSlots and previousSlots[slotName] or {}

    for index = 1, maxSlots do
        local oldSlot = previous[index]

        if DubzVisibleGuns.SlotOff(group, index) then
            slots[index] = { empty = true, disabled = true }   -- switched off in the admin menu: nothing goes here
        elseif SlotHasAvailableWeapon(oldSlot, available) then
            slots[index] = available[oldSlot.class]
        else
            slots[index] = { empty = true }
        end
    end

    for _, class in ipairs(order) do
        if not WeaponAlreadySlotted(slots, class) then
            local emptyIndex = FirstEmptySlot(slots)
            if not emptyIndex then break end

            slots[emptyIndex] = available[class]
        end
    end

    return slots
end

local function BuildVisibleWeapons(ply)
    if not IsValid(ply) or not ply:Alive() or not IsEnabled() then
        playerSlots[ply] = EmptySlots()
        return playerSlots[ply]
    end

    local available = BuildAvailableWeapons(ply)
    local previousSlots = playerSlots[ply] or EmptySlots()
    local slots = {
        pistols = AssignStableSlots(previousSlots, available.pistols, available.pistolOrder, "pistols", DubzVisibleGuns.Config.MaxPistols, "hip"),
        rifles = AssignStableSlots(previousSlots, available.rifles, available.rifleOrder, "rifles", DubzVisibleGuns.Config.MaxRifles, "back")
    }

    playerSlots[ply] = slots

    return slots
end

local function Signature(slots)
    return util.TableToJSON(slots, true) or "{}"
end

local function SendPlayerSlots(ply, slots)
    net.Start("DubzVisibleGuns_Update")
    net.WriteEntity(ply)
    net.WriteString(util.TableToJSON(slots, true) or "{}")
    net.Broadcast()
end

local function PlayHolsterGesture(ply)
    if not ShouldGesture() or not IsValid(ply) or not ply:Alive() then return end

    local sequence = ply:LookupSequence("gesture_item_place")
    if sequence and sequence >= 0 then
        ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequence, 0, true)
        return
    end

    local fallbackAct = ACT_GMOD_GESTURE_ITEM_PLACE or ACT_GMOD_GESTURE_ITEM_DROP
    if fallbackAct then
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, fallbackAct, true)
    end
end

local function RefreshPlayer(ply, force)
    local slots = BuildVisibleWeapons(ply)
    local signature = Signature(slots)
    local previous = playerCache[ply]

    if not force and previous == signature then return end

    playerCache[ply] = signature
    SendPlayerSlots(ply, slots)

    if previous and previous ~= signature then
        PlayHolsterGesture(ply)
    end
end

timer.Create("DubzVisibleGuns_Refresh", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        RefreshPlayer(ply, false)
    end
end)

hook.Add("PlayerInitialSpawn", "DubzVisibleGuns_InitialSync", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end

        for _, target in ipairs(player.GetAll()) do
            RefreshPlayer(target, true)
        end
    end)
end)

hook.Add("PlayerSpawn", "DubzVisibleGuns_SpawnSync", function(ply)
    timer.Simple(0.25, function()
        if IsValid(ply) then
            RefreshPlayer(ply, true)
        end
    end)
end)

hook.Add("PlayerDeath", "DubzVisibleGuns_ClearOnDeath", function(ply)
    playerCache[ply] = nil
    playerSlots[ply] = EmptySlots()
    SendPlayerSlots(ply, playerSlots[ply])
end)

hook.Add("PlayerDisconnected", "DubzVisibleGuns_ClearCache", function(ply)
    playerCache[ply] = nil
    playerSlots[ply] = nil
end)

concommand.Add("dvg_refresh", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    for _, target in ipairs(player.GetAll()) do
        RefreshPlayer(target, true)
    end
end)

-- Saved placements (from the editor) ---------------------------------------------------------------------------------------------------------
-- data/dubz_visible_guns_slots.json: slot id -> {pos = {x, y, z}, ang = {p, y, r}, scale}. Sent to every player when it changes and on join.
util.AddNetworkString("DubzVG_Overrides")   -- server -> client: the whole table (JSON)
util.AddNetworkString("DubzVG_Save")        -- client -> server: slot id, position, angles, scale
util.AddNetworkString("DubzVG_Reset")       -- client -> server: slot id (back to the default)

local OVERRIDE_FILE = "dubz_visible_guns_slots.json"
local saved = {}

do
    local text = file.Exists(OVERRIDE_FILE, "DATA") and file.Read(OVERRIDE_FILE, "DATA")
    saved = (text and util.JSONToTable(text)) or {}
    DubzVisibleGuns.SetOverrides(saved)
end

local function sendOverrides(target)
    net.Start("DubzVG_Overrides")
    net.WriteString(util.TableToJSON(saved) or "{}")

    if target then net.Send(target) else net.Broadcast() end
end

local function persist()
    file.Write(OVERRIDE_FILE, util.TableToJSON(saved, true))
    DubzVisibleGuns.SetOverrides(saved)
    sendOverrides()
end

local function validId(id)
    for _, slot in ipairs(DubzVisibleGuns.AllSlotIds()) do
        if slot.id == id then return true end
    end

    return false
end

net.Receive("DubzVG_Save", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local id = net.ReadString()
    local pos = { net.ReadFloat(), net.ReadFloat(), net.ReadFloat() }
    local ang = { net.ReadFloat(), net.ReadFloat(), net.ReadFloat() }
    local scale = math.Clamp(net.ReadFloat(), 0.1, 4)

    local gunTweak = string.sub(id, 1, 4) == "gun:" and string.match(string.sub(id, 5), "^[%w_%-%.]+$") ~= nil
    if not gunTweak and not validId(id) then return end

    for index = 1, 3 do pos[index] = math.Clamp(pos[index], -80, 80) end

    saved[id] = { pos = pos, ang = ang, scale = scale }
    persist()

    ply:ChatPrint("[Visible Guns] Saved " .. id .. ".")
end)

net.Receive("DubzVG_Reset", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local id = net.ReadString()
    if saved[id] == nil then return end

    saved[id] = nil
    persist()

    ply:ChatPrint("[Visible Guns] " .. id .. " is back to its default.")
end)

hook.Add("PlayerInitialSpawn", "DubzVisibleGuns_SendOverrides", function(ply)
    timer.Simple(3, function() if IsValid(ply) then sendOverrides(ply) end end)
end)

-- Everyone's list is worked out again (the slots or weapon rules were changed in the admin menu)
function DubzVisibleGuns.RefreshAll()
    for _, ply in ipairs(player.GetAll()) do RefreshPlayer(ply, true) end
end
