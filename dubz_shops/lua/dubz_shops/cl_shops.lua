-- The shop window, client side: a Buy tab and a Sell tab (the Sell tab only when the shop buys something). Plain black cards built from Dubz
-- Framework controls. The server sends everything (prices, what is left, what you carry) and sends it again after every trade.
local frame, tabs, buyScroll, sellScroll, data, npc

local function money(amount)
	return DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(amount) or ("$" .. amount)
end

local function theme() return DFW.UI.GetTheme() end

local function close()
	if IsValid(frame) then frame:Remove() end
	frame = nil
end

local function trade(side, id, qty)
	net.Start("DubzShops_Trade")
		net.WriteString(side)
		net.WriteString(id)
		net.WriteUInt(math.Clamp(qty or 1, 1, 255), 8)
	net.SendToServer()
end

-- One row: a model on the left, the name and a second line, and buttons on the right
local function card(parent)
	local panel = vgui.Create("Panel", parent)
	panel:Dock(TOP)
	panel:SetTall(64)
	panel:DockMargin(0, 0, 6, 6)

	return panel
end

-- The item drawn as it really is: its own colour, material, scale and skin, fitted to the frame
local function icon(panel, model, look)
	local view = vgui.Create("DModelPanel", panel)
	view:SetPos(8, 6)
	view:SetSize(52, 52)
	view:SetMouseInputEnabled(false)
	view:SetModel(model)
	view:SetAmbientLight(Color(120, 120, 120))
	view:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
	view:SetDirectionalLight(BOX_FRONT, Color(190, 190, 190))
	view.LayoutEntity = function() end

	local ent = view:GetEntity()
	if not IsValid(ent) then return end

	local scale = look and look.scale or 1

	if look then
		if look.mat and look.mat ~= "" then ent:SetMaterial(look.mat) end
		if look.skin then ent:SetSkin(look.skin) end

		view:SetColor(Color(look.r or 255, look.g or 255, look.b or 255, 255))
		if scale ~= 1 then ent:SetModelScale(scale, 0) end
	end

	-- Frame the whole item, whatever its size
	local mins, maxs = ent:GetModelRenderBounds()
	mins, maxs = mins * scale, maxs * scale

	local size = math.max((maxs - mins):Length(), 4)

	view:SetFOV(32)
	view:SetLookAt((mins + maxs) / 2)
	view:SetCamPos((mins + maxs) / 2 + Vector(1, 0.85, 0.6):GetNormalized() * size * 1.15)
end

local function button(panel, text, wide, variant)
	local b = vgui.Create("DFW.Button", panel)
	b:Dock(RIGHT)
	b:SetWide(wide)
	b:DockMargin(6, 14, 8, 14)
	b:SetLabel(text)
	if variant then b:SetVariant(variant) end

	return b
end

local function emptyNote(scroll, text)
	local note = vgui.Create("DFW.Label", scroll)
	note:Dock(TOP)
	note:SetTall(36)
	note:SetStyle("small")
	note:SetText(text)
end

local function fill()
	if not IsValid(frame) or not data then return end

	frame:SetSubtitle("You have " .. money(data.money))

	-- Buy ------------------------------------------------------------------------------------------------------------
	buyScroll:Clear()

	if #data.buy == 0 then emptyNote(buyScroll, "Nothing for sale right now.") end

	for _, row in ipairs(data.buy) do
		local panel = card(buyScroll)
		icon(panel, row.model, row.look)

		local locked = row.lock ~= ""
		local soldOut = row.left == 0
		local afford = data.money >= row.price

		panel.Paint = function(self, w, h)
			local t = theme()

			draw.RoundedBox(6, 0, 0, w, h, Color(0, 0, 0, 160))
			DFW.Draw.Text(row.name .. (row.amount > 1 and ("  x" .. row.amount) or ""), "Body", 72, 22, t.text)

			local line = row.price > 0 and money(row.price) or "Free"
			local color = (afford or row.price == 0) and t.textMuted or t.danger

			if locked then
				line, color = row.lock, t.danger
			elseif soldOut then
				line, color = "Sold out for now", t.danger
			elseif row.left > 0 then
				line = line .. "   -   " .. row.left .. " left"
			end

			DFW.Draw.Text(line, "Small", 72, 43, color)
		end

		local b = button(panel, data.button, 110, "primary")
		b:SetEnabled(not locked and not soldOut and (afford or row.price == 0))
		b.DoClick = function() trade("buy", row.id, 1) end
	end

	-- Sell -----------------------------------------------------------------------------------------------------------
	sellScroll:Clear()

	if #data.sell == 0 then emptyNote(sellScroll, "You have nothing this shop will buy.") end

	for _, row in ipairs(data.sell) do
		local panel = card(sellScroll)
		icon(panel, row.model, row.look)

		panel.Paint = function(self, w, h)
			local t = theme()

			draw.RoundedBox(6, 0, 0, w, h, Color(0, 0, 0, 160))
			DFW.Draw.Text(row.name, "Body", 72, 22, t.text)
			local line = row.price > 0 and (money(row.price) .. " each   -   you have " .. row.have) or ("Not interested   -   you have " .. row.have)
			DFW.Draw.Text(line, "Small", 72, 43, (row.have > 0 and row.price > 0) and t.textMuted or t.textDim)
		end

		local all = button(panel, "Sell all", 90)
		all:SetEnabled(row.have > 0 and row.price > 0)
		all.DoClick = function() trade("sell", row.id, row.have) end

		local one = button(panel, "Sell 1", 80, "primary")
		one:SetEnabled(row.have > 0 and row.price > 0)
		one.DoClick = function() trade("sell", row.id, 1) end
	end
end

local function open()
	close()

	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then return end

	frame = DFW.UI.CreateFrame(data.name, 640, 520, nil, {compact = true, module = "shops"})

	local content = frame:GetContent()

	tabs = vgui.Create("DFW.TabBar", content)
	tabs:Dock(TOP)
	tabs:SetTall(34)
	tabs:AddTab("buy", data.buyLabel)
	if data.canSell or #data.sell > 0 then tabs:AddTab("sell", data.sellLabel) end

	local pages = vgui.Create("Panel", content)
	pages:Dock(FILL)
	pages:DockMargin(0, 8, 0, 0)

	buyScroll = vgui.Create("DFW.ScrollPanel", pages)
	buyScroll:Dock(FILL)

	sellScroll = vgui.Create("DFW.ScrollPanel", pages)
	sellScroll:Dock(FILL)
	sellScroll:SetVisible(false)

	tabs.OnTabChanged = function(_, id)
		buyScroll:SetVisible(id == "buy")
		sellScroll:SetVisible(id == "sell")
	end
	tabs:SetActive("buy", true)

	fill()
end

net.Receive("DubzShops_Open", function()
	npc = net.ReadEntity()
	local fresh = util.JSONToTable(net.ReadString())
	if not fresh then return end

	local same = IsValid(frame) and data and data.shop == fresh.shop
	data = fresh

	if same then fill() else open() end
end)

net.Receive("DubzShops_Close", close)
