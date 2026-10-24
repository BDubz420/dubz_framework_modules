DubzF4.Reported = DubzF4.Reported or {}

function DubzF4.Report(message)
    if DubzF4.Reported[message] then return end

    DubzF4.Reported[message] = true
    MsgC(Color(255, 80, 80), "[DubzF4] ", color_white, message .. "\n")

    if not SERVER then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply:IsSuperAdmin() then ply:ChatPrint("[DubzF4] " .. message) end
    end
end
