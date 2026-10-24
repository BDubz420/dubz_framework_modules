DubzCredits = DubzCredits or {}
DubzCredits.ActiveBoosts = {}

DubzCredits = DubzCredits or {}
DubzCredits.ActiveBoosts = {}

DubzCredits.PersonalBoosts = DubzCredits.PersonalBoosts or {}

net.Receive("DubzCredits_BoostSync", function()
    local data = net.ReadTable() or {}

    -- Stamp client time when we received it
    local now = CurTime()

    for id, info in pairs(data) do
        info._clientSyncTime = now
    end

    DubzCredits.ActiveBoosts = data
end)

net.Receive("DubzCredits_PersonalBoosts", function()
    DubzCredits.PersonalBoosts = net.ReadTable() or {}
end)