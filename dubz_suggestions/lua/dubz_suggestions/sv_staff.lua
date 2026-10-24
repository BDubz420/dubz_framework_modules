DubzSuggestions.Staff = DubzSuggestions.Staff or {}

local Staff = DubzSuggestions.Staff
local config = DubzSuggestions.Config

function DubzSuggestions.CanModerate(ply)
    if not IsValid(ply) then return true end

    local custom = hook.Run("DubzSuggestionsCanModerate", ply)

    if custom ~= nil then return custom == true end

    return ply:IsAdmin()
end

local function wantsPing(ply)
    local working = hook.Run("DubzWorkflowIsWorking", ply)

    if working ~= nil then return working == true end

    return config.PingMode == "all"
end

function Staff.Ping()
    for _, ply in ipairs(player.GetAll()) do
        if DubzSuggestions.CanModerate(ply) and wantsPing(ply) then
            DFW.Net.Start("sg_ping")
            net.Send(ply)
        end
    end
end
