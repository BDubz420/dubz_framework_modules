-- Mining, client side: the foreman's sale window and the crafting table's window. Built from Dubz Framework controls.
local cfg = DubzMining.Config

local buyerFrame, buyerScroll, buyerNpc, buyerData
local craftFrame, craftScroll, craftTable, craftData

local function money(amount)
	return (DarkRP and DarkRP.formatMoney) and DarkRP.formatMoney(amount) or ("$" .. amount)
end

local function swatch(rgb) return Color(rgb[1], rgb[2], rgb[3]) end

-- The foreman's sale window ----------------------------------------------------------------------------------------------

local confirmFrame

local function closeConfirm()
	if IsValid(confirmFrame) then confirmFrame:Remove() end
	confirmFrame = nil
end

local function sell(id, amount, payDebt)
	net.Start("DubzMining_Sell")
		net.WriteEntity(buyerNpc)
		net.WriteString(id)
		net.WriteUInt(amount, 16)
		net.WriteBool(payDebt or false)
	net.SendToServer()

	closeConfirm()
end

local function trendText(item)
	if item.trend <= -1 then return item.name .. " is down " .. math.abs(item.trend) .. "% from its usual price." end
	if item.trend >= 1 then return item.name .. " is up " .. item.trend .. "% from its usual price." end
end

-- "Are you sure?": what he will pay, how the price has moved, and what you owe him
local function confirm(id, amount)
	local lines, total, pieces = {}, 0, 0

	if id == "*" then
		for _, item in ipairs(buyerData.items) do
			if item.count > 0 then
				total, pieces = total + item.count * item.price, pieces + item.count
				local note = trendText(item)
				if note and math.abs(item.trend) >= 5 and #lines < 4 then lines[#lines + 1] = note end
			end
		end

		if pieces == 0 then return end
		table.insert(lines, 1, "Sell everything you're carrying (" .. pieces .. " pieces) for " .. money(total) .. "?")
	else
		local item
		for _, row in ipairs(buyerData.items) do
			if row.id == id then item = row end
		end

		if not item or item.count == 0 then return end

		pieces = amount == 0 and item.count or math.min(amount, item.count)
		total = pieces * item.price

		lines[1] = "Sell " .. pieces .. " x " .. item.name .. " for " .. money(total) .. "?"
		lines[2] = trendText(item)
	end

	if buyerData.owed > 0 then lines[#lines + 1] = "You owe " .. money(buyerData.owed) .. " (the minecart). Pay it out of this?" end

	closeConfirm()

	local height = 120 + #lines * 24
	confirmFrame = DFW.UI.CreateFrame("Are you sure?", 560, height, nil, {compact = true, module = "mining"})
	confirmFrame:Center()
	confirmFrame:MakePopup()

	local content = confirmFrame:GetContent()

	local buttons = vgui.Create("Panel", content)
	buttons:Dock(BOTTOM)
	buttons:SetTall(46)

	local function add(label, variant, fn)
		local button = vgui.Create("DFW.Button", buttons)
		button:Dock(RIGHT)
		button:SetWide(label == "Cancel" and 100 or 190)
		button:DockMargin(6, 4, 0, 4)
		if variant then button:SetVariant(variant) end
		button:SetLabel(label)
		button.DoClick = fn
	end

	add("Cancel", nil, closeConfirm)

	if buyerData.owed > 0 then
		add("Sell, pay later", nil, function() sell(id, amount, false) end)
		add("Sell and pay what I owe", "primary", function() sell(id, amount, true) end)
	else
		add("Yes, sell", "primary", function() sell(id, amount, false) end)
	end

	content.Paint = function(_, w)
		local theme = DFW.UI.GetTheme()
		for index, line in ipairs(lines) do
			DFW.Draw.Text(line, index == 1 and "Body" or "Small", 8, 8 + (index - 1) * 24, index == 1 and theme.text or theme.textMuted)
		end
	end
end

local function rebuildBuyer()
	if not IsValid(buyerScroll) then return end
	buyerScroll:Clear()

	local total = 0
	for _, item in ipairs(buyerData.items) do total = total + item.count * item.price end

	buyerFrame.Total = total
	buyerFrame:SetSubtitle("He pays " .. buyerData.rate .. "% of the going price. Prices change every minute." .. (buyerData.owed > 0 and ("  You owe him " .. money(buyerData.owed) .. ".") or ""))

	for _, item in ipairs(buyerData.items) do
		local row = vgui.Create("Panel", buyerScroll)
		row:Dock(TOP)
		row:SetTall(46)
		row:DockMargin(0, 0, 6, 3)

		local all = vgui.Create("DFW.Button", row)
		all:Dock(RIGHT)
		all:SetWide(90)
		all:DockMargin(4, 7, 6, 7)
		all:SetLabel("Sell all")
		all:SetEnabled(item.count > 0)
		all.DoClick = function() confirm(item.id, 0) end

		local one = vgui.Create("DFW.Button", row)
		one:Dock(RIGHT)
		one:SetWide(80)
		one:DockMargin(4, 7, 0, 7)
		one:SetLabel("Sell 1")
		one:SetEnabled(item.count > 0)
		one.DoClick = function() confirm(item.id, 1) end

		row.Paint = function(_, w, h)
			local theme = DFW.UI.GetTheme()
			draw.RoundedBox(6, 0, 0, w, h, theme.slot)

			draw.RoundedBox(4, 8, h / 2 - 11, 22, 22, swatch(item.color))
			DFW.Draw.Text(item.name, "Body", 42, h / 2 - 8, theme.text)
			DFW.Draw.Text(item.kind == "gem" and "Gem" or (item.kind == "ore" and "Ore" or "Ingot"), "Tiny", 42, h / 2 + 10, theme.textMuted)

			DFW.Draw.Text("You have " .. item.count, "Small", w - 270, h / 2 - 8, item.count > 0 and theme.text or theme.textDim, TEXT_ALIGN_RIGHT)

			-- The price right now, green when it is above the usual
			local up, down = item.trend >= 1, item.trend <= -1
			DFW.Draw.Text(money(item.price) .. (up and ("  +" .. item.trend .. "%") or (down and ("  " .. item.trend .. "%") or "")), "Small", w - 270, h / 2 + 10,
				up and Color(110, 190, 120) or (down and Color(240, 130, 120) or theme.textMuted), TEXT_ALIGN_RIGHT)
		end
	end
end

net.Receive("DubzMining_Buyer", function()
	buyerNpc = net.ReadEntity()
	buyerData = util.JSONToTable(net.ReadString()) or {items = {}, rate = 100, owed = 0}
	buyerData.owed = buyerData.owed or 0

	closeConfirm()

	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then return end

	if not IsValid(buyerFrame) then
		buyerFrame = DFW.UI.CreateFrame(buyerData.title or "Foreman", 620, 640, nil, {compact = true, module = "mining"})
		buyerFrame:Center()

		local content = buyerFrame:GetContent()

		local bottom = vgui.Create("Panel", content)
		bottom:Dock(BOTTOM)
		bottom:SetTall(52)

		local everything = vgui.Create("DFW.Button", bottom)
		everything:Dock(RIGHT)
		everything:SetWide(220)
		everything:DockMargin(8, 6, 4, 6)
		everything:SetVariant("primary")
		everything:SetLabel("Sell everything")
		everything.DoClick = function() confirm("*", 0) end

		bottom.Paint = function(_, w, h)
			DFW.Draw.Text("Worth right now: " .. money(buyerFrame.Total or 0), "Body", 10, h / 2, DFW.UI.GetTheme().accent)
		end

		buyerScroll = vgui.Create("DFW.ScrollPanel", content)
		buyerScroll:Dock(FILL)

		buyerFrame.Think = function(self)
			if not IsValid(buyerNpc) or LocalPlayer():GetPos():Distance(buyerNpc:GetPos()) > cfg.useDistance * 1.4 then
				closeConfirm()
				self:Remove()
			end
		end
	end

	rebuildBuyer()
end)

-- The crafting table ---------------------------------------------------------------------------------------------------

local function rebuildCrafting()
	if not IsValid(craftScroll) then return end
	craftScroll:Clear()

	for _, recipe in ipairs(craftData.recipes) do
		local locked = craftData.level < recipe.level
		local rows = math.max(1, #recipe.items)
		local height = math.max(78, 40 + rows * 20)

		local row = vgui.Create("Panel", craftScroll)
		row:Dock(TOP)
		row:SetTall(height)
		row:DockMargin(0, 0, 6, 4)

		local icon = vgui.Create("SpawnIcon", row)
		icon:Dock(LEFT)
		icon:SetWide(70)
		icon:DockMargin(4, 4, 8, 4)
		icon:SetModel((recipe.model and recipe.model ~= "") and recipe.model or "models/props_junk/PopCan01a.mdl")
		icon:SetMouseInputEnabled(false)

		local craft = vgui.Create("DFW.Button", row)
		craft:Dock(RIGHT)
		craft:SetWide(110)
		craft:DockMargin(6, math.floor(height / 2 - 20), 8, math.floor(height / 2 - 20))
		craft:SetVariant("primary")
		craft:SetLabel("Craft")
		craft:SetEnabled(recipe.can)
		craft.DoClick = function()
			net.Start("DubzMining_Craft")
				net.WriteEntity(craftTable)
				net.WriteString(recipe.id)
			net.SendToServer()
		end

		row.Paint = function(_, w, h)
			local theme = DFW.UI.GetTheme()
			draw.RoundedBox(6, 0, 0, w, h, theme.slot)

			DFW.Draw.Text(recipe.name .. (recipe.amount > 1 and (" x" .. recipe.amount) or ""), "Body", 90, 18, locked and theme.textDim or theme.text)
			DFW.Draw.Text("Crafting level " .. recipe.level, "Tiny", w - 130, 18, locked and Color(240, 130, 120) or theme.textMuted, TEXT_ALIGN_RIGHT)

			local y = 40
			for _, need in ipairs(recipe.items) do
				local enough = need.have >= need.need
				draw.RoundedBox(3, 92, y - 6, 12, 12, swatch(need.color))
				DFW.Draw.Text(need.name .. "  " .. need.have .. " / " .. need.need, "Small", 110, y, enough and theme.text or Color(240, 130, 120))
				y = y + 20
			end
		end
	end
end

net.Receive("DubzMining_Crafting", function()
	craftTable = net.ReadEntity()
	craftData = util.JSONToTable(net.ReadString()) or {recipes = {}, level = 1}

	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then return end

	if not IsValid(craftFrame) then
		craftFrame = DFW.UI.CreateFrame(craftData.title or "Crafting", 700, 700, nil, {compact = true, module = "mining"})
		craftFrame:Center()

		craftScroll = vgui.Create("DFW.ScrollPanel", craftFrame:GetContent())
		craftScroll:Dock(FILL)

		craftFrame.Think = function(self)
			if not IsValid(craftTable) or LocalPlayer():GetPos():Distance(craftTable:GetPos()) > cfg.useDistance * 1.4 then self:Remove() end
		end
	end

	craftFrame:SetSubtitle("Your crafting level: " .. craftData.level .. ". Materials come from your pocket. Crafting teaches you more.")
	rebuildCrafting()
end)
