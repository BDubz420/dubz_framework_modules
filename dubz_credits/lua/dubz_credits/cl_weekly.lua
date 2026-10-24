DubzCredits = DubzCredits or {}

-------------------------------------------------
-- RECEIVE DATA
-------------------------------------------------
net.Receive("DubzCredits_SyncWeekly", function()
    DubzCredits.WeeklyItems = net.ReadTable()
    DubzCredits.NextRefresh = net.ReadUInt(32)

    if DubzCredits.RebuildShopUI then
        DubzCredits:RebuildShopUI()
    end
end)