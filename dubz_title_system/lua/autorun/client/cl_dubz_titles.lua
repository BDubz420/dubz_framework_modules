include("autorun/sh_dubz_titles_config.lua")

-- The title store window, built from Dubz Framework controls (it follows the framework theme). Opened by the
-- title NPC. Titles and prices come from the admin menu's Titles / Colors tables.
local data = {}
local isVIP = false
local earned = 0
local frame
local rebuild

local function Money(n)
    return "$" .. string.Comma(tonumber(n) or 0)
end

net.Receive("DubzTitles_SendData", function()
    data = net.ReadTable() or {}
    isVIP = net.ReadBool()
    earned = net.ReadUInt(32)

    if IsValid(frame) and rebuild then rebuild() end
end)

-- A row of the title / colour lists: name on the left, price (or state) on the right, optional colour swatch
local function listRow(scroll, label, rightText, rightColor, swatch, active, enabled, onClick)
    local row = vgui.Create("DFW.Button", scroll)
    row:Dock(TOP)
    row:SetTall(30)
    row:DockMargin(0, 0, 4, 2)
    row:SetLabel(swatch and ("      " .. label) or label)
    row:SetTextAlign(TEXT_ALIGN_LEFT)
    row:SetActive(active)
    row:SetEnabled(enabled)
    row.DoClick = onClick

    row.PaintOver = function(self, w, h)
        if swatch then
            draw.RoundedBox(4, 8, 7, 16, h - 14, swatch)
        end

        if rightText ~= "" then
            DFW.Draw.Text(rightText, "Small", w - 10, h / 2, rightColor or DFW.UI.GetTheme().accent, TEXT_ALIGN_RIGHT)
        end
    end

    return row
end

net.Receive("DubzTitles_OpenMenu", function()
    if not DubzTitles.Enabled() then return end

    if not (DFW and DFW.UI and DFW.UI.CreateFrame) then
        chat.AddText(Color(255, 80, 80), "[Titles] ", color_white, "The Dubz Framework addon isn't installed, so the title store can't open.")
        return
    end

    if IsValid(frame) then frame:Remove() end

    frame = DFW.UI.CreateFrame("Title Selection", 760, 580, nil, {compact = true, module = "titles"})
    local content = frame:GetContent()

    local selectedTitle
    local selectedColor = {mode = "preset", id = "white", color = Color(255, 255, 255)}
    local tab = "titles"
    local customColor = Color(255, 255, 255)

    -- Left: tabs and the title list
    local left = vgui.Create("Panel", content)
    left:Dock(LEFT)
    left:SetWide(370)
    left:DockMargin(4, 4, 8, 4)

    local tabs = vgui.Create("DFW.TabBar", left)
    tabs:Dock(TOP)
    tabs:SetTall(34)

    local titleScroll = vgui.Create("DFW.ScrollPanel", left)
    titleScroll:Dock(FILL)

    -- Right: colours, custom colour, preview, action
    local right = vgui.Create("Panel", content)
    right:Dock(FILL)
    right:DockMargin(0, 4, 4, 4)

    local action = vgui.Create("DFW.Button", right)
    action:Dock(BOTTOM)
    action:SetTall(38)
    action:DockMargin(0, 6, 0, 0)
    action:SetVariant("primary")

    local preview = vgui.Create("Panel", right)
    preview:Dock(BOTTOM)
    preview:SetTall(54)
    preview:DockMargin(0, 6, 0, 0)
    preview.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, DFW.UI.GetTheme().slot)
        local title = selectedTitle and selectedTitle.name or "Preview"
        local font = DFW.UI.Font("Heading")
        DFW.Draw.Text(title, font, w / 2 + 1, h / 2 + 1, color_black, TEXT_ALIGN_CENTER)
        DFW.Draw.Text(title, font, w / 2, h / 2, selectedColor.color, TEXT_ALIGN_CENTER)
    end

    local customRow = vgui.Create("Panel", right)
    customRow:Dock(BOTTOM)
    customRow:SetTall(34)
    customRow:DockMargin(0, 6, 0, 0)

    local customSwatch = vgui.Create("DFW.ColorButton", customRow)
    customSwatch:Dock(LEFT)
    customSwatch:SetWide(120)
    customSwatch:SetAlphaBar(false)
    customSwatch:SetColor({r = 255, g = 255, b = 255, a = 255})
    customSwatch.OnValueChanged = function(_, color) customColor = color end

    local customUse = vgui.Create("DFW.Button", customRow)
    customUse:Dock(FILL)
    customUse:DockMargin(6, 0, 0, 0)
    customUse:SetLabel("Use custom colour  +" .. Money(DubzTitles.Config.CustomColorPrice))
    customUse.DoClick = function()
        selectedColor = {mode = "custom", id = "custom", color = Color(customColor.r, customColor.g, customColor.b)}
        rebuild()
    end

    local colorHeader = vgui.Create("DFW.SectionHeader", right)
    colorHeader:Dock(TOP)
    colorHeader:SetText("Colours")

    local colorScroll = vgui.Create("DFW.ScrollPanel", right)
    colorScroll:Dock(FILL)

    local function totalCost()
        if not selectedTitle then return nil end

        local cost = 0
        if not (data.ownedTitles and data.ownedTitles[selectedTitle.id]) then cost = cost + (selectedTitle.price or 0) end

        if selectedColor.mode == "custom" then
            cost = cost + DubzTitles.Config.CustomColorPrice
        else
            local info = DubzTitles.FindColor(selectedColor.id)
            if info and not (data.ownedColors and data.ownedColors[info.id]) then cost = cost + (info.price or 0) end
        end

        return cost
    end

    function rebuild()
        titleScroll:Clear()
        colorScroll:Clear()

        local list = tab == "vip" and DubzTitles.VIPTitles or DubzTitles.Titles

        for _, t in ipairs(list) do
            local owned = data.ownedTitles and data.ownedTitles[t.id]
            local locked = t.required and earned < t.required
            local vipLocked = t.vip and not isVIP

            local equipped = data.activeTitle == t.id
            local rightText, rightColor = "", nil
            if equipped then rightText = "EQUIPPED" rightColor = DFW.UI.GetTheme().accent
            elseif owned then rightText = "owned" rightColor = DFW.UI.GetTheme().success
            elseif vipLocked then rightText = "VIP only" rightColor = DFW.UI.GetTheme().textDim
            elseif locked then rightText = "earn " .. Money(t.required) rightColor = DFW.UI.GetTheme().textDim
            else rightText = Money(t.price) end

            listRow(titleScroll, t.name, rightText, rightColor, nil, selectedTitle and selectedTitle.id == t.id, not locked and not vipLocked, function()
                selectedTitle = t
                rebuild()
            end)
        end

        for _, c in ipairs(DubzTitles.Colors) do
            local owned = data.ownedColors and data.ownedColors[c.id]
            local equippedColor = data.activeColor and data.activeColor.mode == "preset" and data.activeColor.id == c.id
            local colorText = equippedColor and "EQUIPPED" or (owned and "owned" or Money(c.price))
            local colorTint = equippedColor and DFW.UI.GetTheme().accent or (owned and DFW.UI.GetTheme().success or nil)

            listRow(colorScroll, c.name, colorText, colorTint, c.color,
                selectedColor.mode == "preset" and selectedColor.id == c.id, true, function()
                    selectedColor = {mode = "preset", id = c.id, color = c.color}
                    rebuild()
                end)
        end

        local cost = totalCost()
        if cost == nil then
            action:SetLabel("Select a Title")
            action:SetEnabled(false)
        else
            action:SetLabel(cost > 0 and ("Buy - " .. Money(cost)) or "Equip")
            action:SetEnabled(true)
        end
    end

    tabs.OnTabChanged = function(_, id)
        tab = id
        rebuild()
    end

    tabs:AddTab("titles", "Titles")
    tabs:AddTab("vip", "VIP Titles")

    action.DoClick = function()
        if not selectedTitle then return end

        net.Start("DubzTitles_BuyOrUse")
            net.WriteString(selectedTitle.id)
            net.WriteString(selectedColor.mode)
            net.WriteString(selectedColor.id)
            net.WriteColor(selectedColor.color)
        net.SendToServer()
    end

    rebuild()
end)

hook.Add("PostDrawTranslucentRenderables", "DubzTitles_DrawTitle", function()
    if not DubzTitles.Enabled() then return end

    -- The Blackout HUD draws titles in its overhead block and sets this to false.
    if DubzTitles.Config.DrawOverhead == false and BHUD and BHUD.Enabled and BHUD.Enabled() then return end

    local localplayer = LocalPlayer()
    if not IsValid(localplayer) then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply == localplayer then continue end
        if not IsValid(ply) or not ply:Alive() then continue end

        if ply:IsDormant() or ply:GetNoDraw() then continue end

        local pos = ply:EyePos()
        pos.z = pos.z + 10
        pos = pos:ToScreen()

        local title = ply:GetNWString("DubzTitles_Title", "")
        if title == "" then continue end

        local colVec = ply:GetNWVector("DubzTitles_Color", Vector(255,255,255))
        local col = Color(colVec.x, colVec.y, colVec.z)

        local yOffset = -20

        draw.DrawNonParsedText(title, "DarkRPHUD2",
            pos.x + 1, pos.y + yOffset + 1,
            color_black, TEXT_ALIGN_CENTER)

        draw.DrawNonParsedText(title, "DarkRPHUD2",
            pos.x, pos.y + yOffset,
            col, TEXT_ALIGN_CENTER)
    end
end)
