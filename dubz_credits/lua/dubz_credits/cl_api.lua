DubzCredits = DubzCredits or {}

-- Public API for UIs (F4, NPCs, etc.)
function DubzCredits.RequestPurchase(kind, id)
    if not isstring(kind) or not isstring(id) then return end

    net.Start("DubzCredits_Action")
        net.WriteString(kind)
        net.WriteString(id)
    net.SendToServer()
end

DubzCredits.WeeklyItems = {}
DubzCredits.DailyDeal = nil
DubzCredits.NextRefresh = 0

net.Receive("DubzCredits_SyncShop", function()
    DubzCredits.WeeklyItems = net.ReadTable()
    DubzCredits.DailyDeal = net.ReadString()
    DubzCredits.NextRefresh = net.ReadUInt(32)

    print("[CLIENT] Shop received")
    PrintTable(DubzCredits.WeeklyItems)

    if DubzCredits.RebuildShopUI then
        DubzCredits:RebuildShopUI()
    end
end)