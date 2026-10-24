DubzSuggestions.Reported = DubzSuggestions.Reported or {}

function DubzSuggestions.Report(message)
    if DubzSuggestions.Reported[message] then return end

    DubzSuggestions.Reported[message] = true
    MsgC(Color(255, 80, 80), "[DubzSuggestions] ", color_white, message .. "\n")

    if not SERVER then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply:IsSuperAdmin() then ply:ChatPrint("[DubzSuggestions] " .. message) end
    end
end
