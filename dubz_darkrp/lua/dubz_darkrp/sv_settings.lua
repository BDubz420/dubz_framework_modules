DubzDarkRP.Settings = DubzDarkRP.Settings or {}

local Settings = DubzDarkRP.Settings
local config = DubzDarkRP.Config
local DATA_FILE = "dubz_darkrp/settings"
local VERSION = 1
local SAVE_DELAY = 2
local SAVE_TIMER = "DubzDarkRP_SettingsSave"
local TEXT_LIMIT = 200
local SYNC_DELAY = 6
local SMALL_BITS = 8
local SET_BITS = 8 * 2048
local REQUEST_COOLDOWN = 1
local SET_COOLDOWN = 0.2

local overrides = {}
local defaults = {}

local function live()
    return GAMEMODE and GAMEMODE.Config
end

local function scalar(value)
    local kind = type(value)

    return kind == "boolean" or kind == "number" or kind == "string"
end

local function load()
    local saved = DFW.Data.ReadJSON(DATA_FILE, {})

    overrides = {}

    for _, row in ipairs(istable(saved.values) and saved.values or {}) do
        if isstring(row.k) and scalar(row.v) then overrides[row.k] = row.v end
    end
end

function Settings.SaveNow()
    local rows = {}

    for key, value in pairs(overrides) do rows[#rows + 1] = {k = key, v = value} end

    local ok, reason = DFW.Data.WriteJSON(DATA_FILE, {version = VERSION, values = rows})

    if not ok then DubzDarkRP.Report("could not save settings: " .. tostring(reason)) end
end

local function save()
    timer.Create(SAVE_TIMER, SAVE_DELAY, 1, Settings.SaveNow)
end

function Settings.Capture()
    local current = live()

    if not current then return end

    for key, value in pairs(current) do
        if scalar(value) and defaults[key] == nil then defaults[key] = value end
    end
end

function Settings.Apply()
    local current = live()

    if not current then return end

    Settings.Capture()

    for key, value in pairs(overrides) do
        if defaults[key] ~= nil and type(defaults[key]) == type(value) then current[key] = value end
    end
end

function Settings.List()
    local current = live() or {}
    local list = {}

    for key, default in pairs(defaults) do
        list[#list + 1] = {k = key, v = current[key], d = default, t = type(default), c = overrides[key] ~= nil}
    end

    table.sort(list, function(a, b)
        if a.c ~= b.c then return a.c end

        return string.lower(a.k) < string.lower(b.k)
    end)

    return list
end

local function send(name, data, target)
    DFW.Net.Start(name)

    if not DFW.Net.WriteJSON(data) then return false end

    if target then net.Send(target) else net.Broadcast() end

    return true
end

local function overrideRows()
    local rows = {}

    for key, value in pairs(overrides) do rows[#rows + 1] = {k = key, v = value} end

    return rows
end

function Settings.Sync(target)
    send("drp_settingsync", {values = overrideRows()}, target)
end

function Settings.Send(ply)
    send("drp_settings", {settings = Settings.List()}, ply)
end

local function coerce(default, value)
    if type(default) == "boolean" then return type(value) == "boolean" and value or nil end

    if type(default) == "number" then
        local number = tonumber(value)

        return number and math.Clamp(number, -1e9, 1e9) or nil
    end

    return isstring(value) and string.sub(value, 1, TEXT_LIMIT) or nil
end

function Settings.Set(actor, key, value, reset)
    local current = live()

    if not (current and defaults[key] ~= nil) then return false, DubzDarkRP.Phrase("SettingUnknown") end

    local before = current[key]

    if reset then
        overrides[key] = nil
        current[key] = defaults[key]
    else
        local clean = coerce(defaults[key], value)

        if clean == nil then return false, DubzDarkRP.Phrase("SettingInvalid") end

        overrides[key] = clean
        current[key] = clean
    end

    save()
    Settings.Sync()
    DubzDarkRP.Audit.Log(actor, "setting", key, before, current[key])
    hook.Run("DubzDarkRPSettingChanged", key, current[key])

    return true, DubzDarkRP.Phrase(reset and "SettingWasReset" or "SettingSaved")
end

DFW.Net.Receive("drp_settings", function(_, ply)
    Settings.Send(ply)
end, {maxBits = SMALL_BITS, cooldown = REQUEST_COOLDOWN, access = DubzDarkRP.CanManage})

DFW.Net.Receive("drp_setting", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and isstring(request.key)) then return end

    local ok, message = Settings.Set(ply, request.key, request.value, request.reset == true)

    DubzDarkRP.Sync.Result(ply, ok, message)
    Settings.Send(ply)
end, {maxBits = SET_BITS, cooldown = SET_COOLDOWN, access = DubzDarkRP.CanManage})

hook.Add("DubzDarkRPBooted", "DubzDarkRP_Settings", function()
    if config.ApplyOnBoot then Settings.Apply() else Settings.Capture() end
end)

hook.Add("PlayerInitialSpawn", "DubzDarkRP_SettingsJoin", function(ply)
    timer.Simple(SYNC_DELAY, function()
        if IsValid(ply) then Settings.Sync(ply) end
    end)
end)

hook.Add("ShutDown", "DubzDarkRP_SettingsSave", Settings.SaveNow)

load()
