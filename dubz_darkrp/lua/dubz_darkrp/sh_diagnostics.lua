DubzDarkRP.Reported = DubzDarkRP.Reported or {}

function DubzDarkRP.Report(message)
    if DubzDarkRP.Reported[message] then return end

    DubzDarkRP.Reported[message] = true
    MsgC(Color(255, 80, 80), "[DubzDarkRP] ", color_white, message .. "\n")

    if not SERVER then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply:IsSuperAdmin() then ply:ChatPrint("[DubzDarkRP] " .. message) end
    end
end
