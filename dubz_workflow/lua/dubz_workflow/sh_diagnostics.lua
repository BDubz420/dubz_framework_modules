DubzWorkflow.Reported = DubzWorkflow.Reported or {}

function DubzWorkflow.Report(message)
    if DubzWorkflow.Reported[message] then return end

    DubzWorkflow.Reported[message] = true
    MsgC(Color(255, 80, 80), "[DubzWorkflow] ", color_white, message .. "\n")

    if not SERVER then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply:IsSuperAdmin() then ply:ChatPrint("[DubzWorkflow] " .. message) end
    end
end
