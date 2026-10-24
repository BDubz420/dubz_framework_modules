-- Donate / Credits tab and its shop sync.
local F4 = DubzF4

---------------------------------------------------------------
-- Credits display and shop - f4 menu (DISPLAY ONLY)
---------------------------------------------------------------

-- Returns seconds remaining for an active boost entry
local function GetBoostRemainingSeconds(active)
    if not active then return 0 end

    -- New format (recommended): expires = os.time() timestamp
    if tonumber(active.expires) then
        return math.max(tonumber(active.expires) - os.time(), 0)
    end

    -- Old format: remaining = seconds
    if tonumber(active.remaining) then
        return math.max(tonumber(active.remaining), 0)
    end

    return 0
end

---------------------------------------------------------------
-- Button helper
---------------------------------------------------------------
local function CreditsButton(parent, text, color, enabled, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:SetTall(26)
    btn:Dock(TOP)
    btn:SetText("")
    btn:SetEnabled(enabled)

    btn.Paint = function(self, w, h)
        local col = enabled and color or F4.C.cat2
        if enabled and self:IsHovered() then
            col = Color(col.r + 15, col.g + 15, col.b + 15)
        end

        draw.RoundedBox(0, 0, 0, w, h, col)
        draw.SimpleText(
            text,
            "DermaDefault",
            8,
            h / 2,
            enabled and color_white or Color(150, 150, 150),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )
    end

    btn.DoClick = function()
        if enabled and onClick then
            onClick()
        end
    end

    return btn
end
---------------------------------------------------------------
-- F4 TAB
---------------------------------------------------------------
function F4.Menu.Tabs.Donate(parent)
    local frame = F4.Frame

    -----------------------------------------------------------
    -- SAFETY / NORMALIZATION (READ-ONLY)
    -----------------------------------------------------------
    DubzCredits = DubzCredits or {}
    DubzCredits.Config = DubzCredits.Config or {}
    DubzCredits.Config.UI = DubzCredits.Config.UI or {}

    DubzCredits.Config.Conversions = DubzCredits.Config.Conversions or {}
    DubzCredits.Config.Boosts = DubzCredits.Config.Boosts or {}
    DubzCredits.Config.Events = DubzCredits.Config.Events or {}
    DubzCredits.Config.PersonalBoosts = DubzCredits.Config.PersonalBoosts or {}

    DubzCredits.GetFormatted = DubzCredits.GetFormatted or function() return "0" end
    DubzCredits.GetLocalBalance = DubzCredits.GetLocalBalance or function() return 0 end
    DubzCredits.ActiveBoosts = DubzCredits.ActiveBoosts or {}

    if DubzCredits.Config.UI.ConversionsEnabled == nil then
        DubzCredits.Config.UI.ConversionsEnabled = true
    end
    if DubzCredits.Config.UI.BoostsEnabled == nil then
        DubzCredits.Config.UI.BoostsEnabled = true
    end
    if DubzCredits.Config.UI.EventsEnabled == nil then
        DubzCredits.Config.UI.EventsEnabled = true
    end

    -----------------------------------------------------------
    -- ROOT PANEL
    -----------------------------------------------------------
    local panel = vgui.Create("DPanel", parent)
    panel:SetSize(frame:GetWide(), frame:GetTall() - 70)
    panel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, F4.C.surface)
    end

    -----------------------------------------------------------
    -- UI HELPERS
    -----------------------------------------------------------
    local function Header(parentPanel, text, col)
        local h = vgui.Create("DPanel", parentPanel)
        h:SetTall(26)
        h:Dock(TOP)
        h.Paint = function(self, w, hh)
            draw.RoundedBox(0, 0, 0, w, hh, col)
            draw.SimpleText(
                text,
                "DermaDefaultBold",
                8,
                hh / 2,
                color_white,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
        end
        return h
    end

    local function Spacer(parentPanel, h)
        local s = vgui.Create("DPanel", parentPanel)
        s:SetTall(h)
        s:Dock(TOP)
        s.Paint = function() end
        return s
    end

    -----------------------------------------------------------
    -- WEEKLY SHOP (BOTTOM) — Created first so BOTTOM dock
    -- reserves space before the columns fill the rest
    -----------------------------------------------------------
    local bottomList = vgui.Create("DPanel", panel)
    bottomList:Dock(BOTTOM)
    bottomList:SetTall(DubzCredits.Config.UI.WeeklyShopEnabled == false and 0 or 210)
    bottomList:SetVisible(DubzCredits.Config.UI.WeeklyShopEnabled ~= false)
    bottomList:DockMargin(0, 0, 0, 0)
    bottomList:DockPadding(8, 0, 8, 8)
    bottomList.Paint = function() end

    Header(bottomList, "Weekly Shop", Color(120, 80, 160))

    local shopContainer = vgui.Create("DPanel", bottomList)
    shopContainer:Dock(FILL)
    shopContainer:DockMargin(0, 0, 0, 0)
    shopContainer.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, F4.C.darkAlpha)
    end

    DubzCredits.ShopPanel = shopContainer

    timer.Simple(0, function()
        if DubzCredits.RebuildShopUI then
            DubzCredits:RebuildShopUI()
        end
    end)

    -----------------------------------------------------------
    -- COLUMNS (fill remaining space above weekly shop)
    -----------------------------------------------------------
    local left = vgui.Create("DPanel", panel)
    left:Dock(LEFT)
    left:SetWide(panel:GetWide() * 0.45)
    left:DockMargin(8, 8, 4, 0)
    left.Paint = function() end

    local right = vgui.Create("DPanel", panel)
    right:Dock(FILL)
    right:DockMargin(4, 8, 8, 0)
    right.Paint = function() end

    -----------------------------------------------------------
    -- LEFT COLUMN (scrollable)
    -----------------------------------------------------------
    local leftScroll = vgui.Create("DScrollPanel", left)
    leftScroll:Dock(FILL)
    leftScroll:DockPadding(0, 0, 0, 0)

    local balance = vgui.Create("DLabel", leftScroll)
    balance:Dock(TOP)
    balance:SetTall(28)
    balance:SetFont("Trebuchet20")
    balance:SetTextColor(color_white)
    balance:SetContentAlignment(5)
    balance.Think = function(self)
        self:SetText("Your Credits: " .. DubzCredits:GetFormatted())
    end

    Header(leftScroll, "Credits", F4.C.row2)

    local store = DubzCredits.Config.Store

    if store and store.Enabled and isstring(store.URL) then
        CreditsButton(
            leftScroll,
            store.ButtonText or "Buy Credits",
            F4.C.header,
            true,
            function()
                gui.OpenURL(store.URL)
            end
        )
    end

    CreditsButton(leftScroll, "Refresh Balance", F4.C.cat, true, function()
        RunConsoleCommand("dubzcredits_refresh")
    end)

    -----------------------------------------------------------
    -- CONVERSIONS
    -----------------------------------------------------------
    if DubzCredits.Config.UI.ConversionsEnabled then
        Header(leftScroll, "Conversions", F4.C.grey2)

        for id, data in SortedPairsByMemberValue(DubzCredits.Config.Conversions, "cost") do
            if data.enabled ~= false then
                local cost = tonumber(data.cost) or 0
                if data.sale then
                    cost = math.floor(cost * (1 - data.sale))
                end

                local canAfford = DubzCredits:GetLocalBalance() >= cost
                local label = (data.name or "Unknown") .. " (" .. cost .. " Credits)"
                if data.sale then label = label .. " [SALE]" end

                CreditsButton(leftScroll, label, F4.C.grey, canAfford, function()
                    DubzCredits.RequestPurchase("convert", id)
                end)
            end
        end
    end

    -----------------------------------------------------------
    -- RIGHT COLUMN (scrollable)
    -----------------------------------------------------------
    local rightScroll = vgui.Create("DScrollPanel", right)
    rightScroll:Dock(FILL)
    rightScroll:DockPadding(0, 0, 0, 0)

    -----------------------------------------------------------
    -- BOOSTS
    -----------------------------------------------------------
    if DubzCredits.Config.UI.BoostsEnabled then
        Header(rightScroll, "Global Boost Shop", Color(0, 120, 60))

        for id, data in SortedPairsByMemberValue(DubzCredits.Config.Boosts, "cost") do
            if data.enabled ~= false then
                local cost = tonumber(data.cost) or 0
                if data.sale then
                    cost = math.floor(cost * (1 - data.sale))
                end

                local active = DubzCredits.ActiveBoosts[id]
                local canAfford = DubzCredits:GetLocalBalance() >= cost and not active

                local label = (data.name or "Unknown") .. " (" .. cost .. " Credits)"
                if active then
                    local rem = GetBoostRemainingSeconds(active)
                    label = label .. " [ACTIVE " .. string.FormattedTime(rem, "%02i:%02i") .. "]"
                elseif data.sale then
                    label = label .. " [SALE]"
                end

                CreditsButton(rightScroll, label, Color(0, 140, 60), canAfford, function()
                    DubzCredits.RequestPurchase("boost", id)
                end)
            end
        end
    end

    if DubzCredits.Config.UI.PersonalBoostsEnabled ~= false then
        Header(rightScroll, "Personal Boosts", Color(100, 180, 255))

        for id, data in SortedPairsByMemberValue(DubzCredits.Config.PersonalBoosts, "cost") do
            if data.enabled ~= false then
                local cost = data.cost or 0
                local canAfford = DubzCredits:GetLocalBalance() >= cost

                CreditsButton(
                    rightScroll,
                    data.name .. " (" .. cost .. " Credits)",
                    Color(100, 180, 255),
                    canAfford,
                    function()
                        DubzCredits.RequestPurchase("pboost", id)
                    end
                )
            end
        end
    end

    -----------------------------------------------------------
    -- EVENTS
    -----------------------------------------------------------
    if DubzCredits.Config.UI.EventsEnabled then
        Header(rightScroll, "Server Events", Color(200, 140, 0))

        for id, data in SortedPairsByMemberValue(DubzCredits.Config.Events, "cost") do
            if data.enabled ~= false then
                local cost = tonumber(data.cost) or 0
                if data.sale then
                    cost = math.floor(cost * (1 - data.sale))
                end

                local canAfford = DubzCredits:GetLocalBalance() >= cost
                local label = (data.name or "Unknown") .. " (" .. cost .. " Credits)"
                if data.sale then label = label .. " [SALE]" end

                CreditsButton(rightScroll, label, Color(200, 140, 0), canAfford, function()
                    DubzCredits.RequestPurchase("event", id)
                end)
            end
        end
    end

    -------------------------------------------------
    -- TIMER HELPER
    -------------------------------------------------
    local function FormatTime(t)
        local d = math.floor(t / 86400)
        local h = math.floor((t % 86400) / 3600)
        local m = math.floor((t % 3600) / 60)
        return string.format("%dd %02dh %02dm", d, h, m)
    end

    -------------------------------------------------
    -- RARITY COLORS
    -------------------------------------------------
    local RARITY_COLORS = {
        common = Color(120, 120, 120),
        uncommon = Color(80, 160, 80),
        rare = Color(80, 120, 255),
        epic = Color(180, 80, 200),
        legendary = Color(255, 140, 0)
    }

    function DubzCredits:RebuildShopUI()
        local shopPanel = self.ShopPanel
        if not IsValid(shopPanel) then return end

        shopPanel:Clear()

        -------------------------------------------------
        -- TIMER
        -------------------------------------------------
        local timerLabel = vgui.Create("DLabel", shopPanel)
        timerLabel:Dock(TOP)
        timerLabel:SetTall(18)
        timerLabel:SetFont("DermaDefault")
        timerLabel:SetTextColor(color_white)
        timerLabel:DockMargin(8, 4, 8, 0)

        timerLabel.Think = function(self)
            local remaining = math.max((DubzCredits.NextRefresh or 0) - os.time(), 0)
            self:SetText("Refresh in: " .. FormatTime(remaining))
        end

        -------------------------------------------------
        -- GRID
        -------------------------------------------------
        local list = vgui.Create("DIconLayout", shopPanel)
        list:Dock(FILL)
        list:SetSpaceX(8)
        list:SetSpaceY(8)
        list:DockMargin(8, 8, 8, 8)

        -------------------------------------------------
        -- ITEM BUILDER
        -------------------------------------------------
        local function AddItem(id, data)
            local size = 108
            local placeholdermodel = "models/props_lab/binderredlabel.mdl"

            local icon = vgui.Create("DAdjustableModelPanel", list)
            icon:SetSize(size, size)
            icon:SetModel(data.model or placeholdermodel)

            if data.model == "models/items/healthkit.mdl" then
                icon:SetLookAng(Angle(45, 0, 0))
                icon:SetCamPos(Vector(-10, 0, 10))
            else
                icon:SetLookAng(Angle(45, 0, 0))
                icon:SetCamPos(Vector(-20, 0, 20))
            end

            icon.PaintOver = function(self, w, h)
                local cost = tonumber(data.cost) or 0
                local canAfford = DubzCredits:GetLocalBalance() >= cost

                surface.SetDrawColor(canAfford and Color(120, 80, 160) or Color(120, 40, 40))
                surface.DrawOutlinedRect(0, 0, w, h)
            end

            icon.DoClick = function()
                local cost = tonumber(data.cost) or 0
                if DubzCredits:GetLocalBalance() < cost then return end
                DubzCredits.RequestPurchase("item", id)
            end

            icon:SetTooltip((data.name or id) .. " (" .. (data.cost or 0) .. " Credits)")
        end

        -------------------------------------------------
        -- POPULATE
        -------------------------------------------------
        local items = DubzCredits.WeeklyItems

        if not items or #items == 0 then
            for id, data in pairs(DubzCredits.Config.Items or {}) do
                if data.enabled ~= false then AddItem(id, data) end
            end
            return
        end

        for _, id in ipairs(items) do
            local data = DubzCredits.Config.Items[id]
            if data and data.enabled ~= false then
                AddItem(id, data)
            end
        end
    end

    parent:AddSheet("Credits", panel, "icon16/money.png")
end

net.Receive("DubzCredits_SyncShop", function()
    DubzCredits.WeeklyItems = net.ReadTable()
    DubzCredits.DailyDeal = net.ReadString()
    DubzCredits.NextRefresh = net.ReadUInt(32)

    if DubzCredits.RebuildShopUI then
        DubzCredits:RebuildShopUI()
    end
end)
