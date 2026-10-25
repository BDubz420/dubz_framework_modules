local config = DubzSuggestions.Config
local Store = DubzSuggestions.Store
local Sync = DubzSuggestions.Sync

local function commandSet()
    local set = {}

    for _, command in ipairs(DubzSuggestions.List("chat_commands")) do set[string.lower(command)] = true end

    return set
end

hook.Add("PlayerSay", "DubzSuggestions_Chat", function(ply, text)
    if not commandSet()[string.lower(string.Trim(text))] then return end

    if DubzSuggestions.Enabled() then
        Sync.Open(ply, false)
    else
        DFW.Net.Start("sg_result")
        DFW.Net.WriteJSON({ok = false, message = DubzSuggestions.Phrase("ErrorDisabled")})
        net.Send(ply)
    end

    return ""
end)

concommand.Add(config.AdminCommand, function(ply)
    if not IsValid(ply) then return end

    if DubzSuggestions.CanModerate(ply) then
        Sync.Open(ply, true)
    else
        Sync.Result(ply, false, DubzSuggestions.Phrase("ErrorAccess"))
    end
end)

concommand.Add("dubz_suggestions_status", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local counts = {}

    for _, item in ipairs(Store.All()) do counts[item.status] = (counts[item.status] or 0) + 1 end

    local lines = {"enabled: " .. tostring(DubzSuggestions.Enabled()), "suggestions: " .. #Store.All()}

    for status, count in SortedPairs(counts) do lines[#lines + 1] = status .. ": " .. count end

    for _, line in ipairs(lines) do
        local text = "[DubzSuggestions] " .. line

        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, text .. "\n") else print(text) end
    end
end)
