local Fields = DubzDarkRP.Fields
local Kinds = DubzDarkRP.Kinds
local Store = DubzDarkRP.Store
local Adapter = DubzDarkRP.Adapter
local config = DubzDarkRP.Config

local booted = false

local function replay(kind, id, entry)
    local engine = Kinds.Engine(kind)

    if entry.created and not engine.Get(id) then
        local ok, data = Fields.Normalize(entry.data, kind)

        if not ok then
            DubzDarkRP.Report("saved " .. kind .. " '" .. id .. "' is invalid and was skipped")
            return
        end

        engine.Apply(id, data)
    elseif not entry.created and not engine.Get(id) then
        DubzDarkRP.Report("saved change for " .. kind .. " '" .. id .. "' has no matching entry in the DarkRP files, so it was skipped")
        return
    elseif not entry.created and not entry.deleted then
        engine.Apply(id, entry.data)
    end

    if entry.deleted then engine.Disable(id) end
end

local function applyStored(kind)
    Store.Load(kind)

    for _, id in ipairs(Store.Ids(kind)) do replay(kind, id, Store.Get(kind, id)) end
end

local function boot()
    if booted or not Adapter.Ready() then return end

    booted = true

    for _, kind in ipairs(Kinds.Order) do Kinds.Engine(kind).Capture() end

    if DubzDarkRP.Enabled() and config.ApplyOnBoot then
        for _, kind in ipairs(Kinds.ReplayOrder) do applyStored(kind) end
    end

    hook.Run("DubzDarkRPBooted")
end

hook.Add("postLoadCustomDarkRPItems", "DubzDarkRP_Boot", boot)
hook.Add("DarkRPFinishedLoading", "DubzDarkRP_Boot", boot)
hook.Add("InitPostEntity", "DubzDarkRP_Boot", boot)

if Adapter.Ready() and #Adapter.Jobs() > 0 and not DarkRP.DARKRP_LOADING then boot() end
