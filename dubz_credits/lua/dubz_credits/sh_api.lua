DubzCredits = DubzCredits or {}
DubzCredits.ClientBalance = 0

if CLIENT then
    net.Receive("DubzCredits_Sync", function()
        DubzCredits.ClientBalance = net.ReadInt(32)
    end)

    function DubzCredits:GetLocalBalance()
        return self.ClientBalance or 0
    end
end

function DubzCredits:GetFormatted(ply)
    if SERVER then
        return string.Comma(self:GetBalance(ply))
    else
        return string.Comma(self:GetLocalBalance())
    end
end
