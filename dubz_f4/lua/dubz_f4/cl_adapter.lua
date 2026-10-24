DubzF4.Adapter = DubzF4.Adapter or {}

local adapter = DubzF4.Adapter
local FALLBACK_MODEL = "models/player/kleiner.mdl"

function adapter.IsAvailable()
    return RPExtraTeams ~= nil
end

function adapter.FormatMoney(amount)
    amount = math.floor(amount or 0)

    local custom = hook.Run("DubzF4FormatMoney", amount)

    if custom then return custom end
    if DarkRP and DarkRP.formatMoney then return DarkRP.formatMoney(amount) end

    return "$" .. string.Comma(amount)
end

function adapter.Money(ply)
    if ply.getDarkRPVar then return ply:getDarkRPVar("money") or 0 end

    return 0
end

function adapter.CanAfford(price)
    return adapter.Money(LocalPlayer()) >= (price or 0)
end

function adapter.Salary(ply)
    if ply.getDarkRPVar then return ply:getDarkRPVar("salary") or 0 end

    return 0
end

function adapter.JobName(ply)
    if ply.getDarkRPVar then return ply:getDarkRPVar("job") or team.GetName(ply:Team()) end

    return team.GetName(ply:Team())
end

function adapter.Run(command, argument)
    if argument == nil then RunConsoleCommand("darkrp", command) else RunConsoleCommand("darkrp", command, argument) end
end

function adapter.Jobs() return RPExtraTeams or {} end
function adapter.Entities() return DarkRPEntities or {} end
function adapter.Shipments() return CustomShipments or {} end
function adapter.Vehicles() return CustomVehicles or {} end
function adapter.AmmoTypes() return (GAMEMODE and GAMEMODE.AmmoTypes) or {} end

function adapter.JobModel(job)
    local model = job.model

    if istable(model) then model = model[1] end

    return model or FALLBACK_MODEL
end

function adapter.JobModels(job)
    local model = job.model

    if istable(model) and #model > 0 then return model end

    return {adapter.JobModel(job)}
end

function adapter.TeamMatch(allowed, teamId)
    if allowed == nil or allowed == false then return true end
    if isnumber(allowed) then return allowed == teamId end
    if not istable(allowed) or next(allowed) == nil then return true end

    for _, id in pairs(allowed) do
        if id == teamId then return true end
    end

    return false
end

function adapter.Safe(fn, ...)
    local ok, result = pcall(fn, ...)

    return ok and result
end

function adapter.Permitted(entry)
    if entry.dubzDisabled then return false end

    return adapter.TeamMatch(entry.allowed, LocalPlayer():Team()) and (not entry.customCheck or adapter.Safe(entry.customCheck, LocalPlayer()))
end

function adapter.TakeOver(toggle, close)
    if not DarkRP then return false end

    DarkRP.openF4Menu = toggle
    DarkRP.closeF4Menu = close
    DarkRP.toggleF4Menu = toggle

    return true
end
