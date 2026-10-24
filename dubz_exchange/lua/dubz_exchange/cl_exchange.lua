-- Exchange, client side: the bank vault window and the exchange window, built from Dubz Framework controls.
local cfg = DubzExchange.Config

local SLOT, GAP = 52, 4

local function money(amount)
	return (DarkRP and DarkRP.formatMoney) and DarkRP.formatMoney(amount) or ("$" .. amount)
end

-- What the item cells need: model, quantity, name and look
local function cellItem(item)
	local out = {name = item.name, model = item.model, class = item.class, qty = item.qty}

	if item.look then
		out.color = Color(item.look.r or 255, item.look.g or 255, item.look.b or 255)
		out.material = item.look.m or ""
	end

	return out
end

local function frameworkReady()
	return DFW and DFW.UI and DFW.UI.CreateFrame
end

-- "worth about $X each" for a tooltip
local function worthText(item)
	if (item.value or 0) <= 0 then return "" end
	return "  -  worth about " .. money(item.value) .. ((item.qty or 1) > 1 and " each" or "")
end

-- A string that changes whenever the pocket does (so a window can redraw it)
local function pocketSignature()
	local slots = DubzInv and DubzInv.ClientState and DubzInv.ClientState() or {}
	local parts = {}

	for index, rec in pairs(slots) do parts[#parts + 1] = index .. rec.class .. rec.qty .. rec.name end

	table.sort(parts)
	return table.concat(parts, "|")
end

-- The bank vault ---------------------------------------------------------------------------------------------------------------

local bankFrame, bankNpc, bankData, bankLeft, bankRight

local function bankSend(action, slot, second)
	net.Start("DubzBank_Action")
		net.WriteString(action)
		net.WriteUInt(slot, 8)
		net.WriteUInt(second or 0, 8)
	net.SendToServer()
end

-- Rearranging your pocket from inside the bank window
local function pocketMove(from, to)
	net.Start("DubzInv_Action")
		net.WriteString("move")
		net.WriteUInt(from, 8)
		net.WriteUInt(to, 8)
	net.SendToServer()
end

local function grid(parent, perRow, count, fill)
	for index = 1, count do
		local col, row = (index - 1) % perRow, math.floor((index - 1) / perRow)

		local cell = vgui.Create("DFW.ItemSlot", parent)
		cell:SetPos(col * (SLOT + GAP), row * (SLOT + GAP))
		cell:SetSize(SLOT, SLOT)
		cell:SetSlotIndex(index)

		fill(cell, index)
	end
end

local function rebuildBank()
	if not (IsValid(bankFrame) and IsValid(bankLeft) and IsValid(bankRight)) then return end

	bankLeft:Clear()
	bankRight:Clear()

	-- Your pocket: click puts a whole stack in the vault, right click puts one
	local slots, capacity = DubzInv.ClientState()

	grid(bankLeft, 5, capacity or 0, function(cell, index)
		-- Every cell takes drops (to rearrange the pocket, or to take something out of the vault), items or not
		cell:SetDragGroup("dubzbank_in")
		cell.OnDropped = function(_, from) pocketMove(from, index) end
		cell:Receiver("dubzbank_out", function(_, dropped, isDropped)
			if isDropped and dropped[1] and dropped[1].SlotIndex then bankSend("withdraw", dropped[1].SlotIndex) end
		end)

		local rec = slots[index]
		if not rec then return end

		cell:SetItem(rec, rec.name .. (rec.qty > 1 and (" x" .. rec.qty) or "") .. worthText(rec) .. " - click or drag: put all in the vault, right click: put one")
		cell.OnClick = function() bankSend("deposit", index) end
		cell.OnRightClick = function() bankSend("deposit1", index) end
	end)

	-- The vault: click takes a whole stack out, right click takes one
	local byslot = {}
	for _, item in ipairs(bankData.items) do byslot[item.slot] = item end

	grid(bankRight, 6, bankData.size, function(cell, index)
		-- Every vault slot takes drops: from the vault itself (rearrange it) or from the pocket (put it in)
		cell:SetDragGroup("dubzbank_out")
		cell.OnDropped = function(_, from) bankSend("vmove", from, index) end

		for _, group in ipairs({"dubzbank_in", "dubzinv"}) do
			cell:Receiver(group, function(_, dropped, isDropped)
				if isDropped and dropped[1] and dropped[1].SlotIndex then bankSend("deposit", dropped[1].SlotIndex) end
			end)
		end

		local item = byslot[index]
		if not item then return end

		cell:SetItem(cellItem(item), item.name .. (item.qty > 1 and (" x" .. item.qty) or "") .. worthText(item) .. " - click or drag: take all out, right click: take one")
		cell.OnClick = function() bankSend("withdraw", index) end
		cell.OnRightClick = function() bankSend("withdraw1", index) end
	end)

	bankFrame.Signature = pocketSignature()
end

net.Receive("DubzBank_State", function()
	bankData = util.JSONToTable(net.ReadString()) or {size = 0, items = {}}

	if not frameworkReady() then return end

	if not IsValid(bankFrame) then
		bankNpc = nil
		for _, ent in ipairs(ents.FindByClass("dubz_bank_teller")) do
			if not IsValid(bankNpc) or ent:GetPos():DistToSqr(LocalPlayer():GetPos()) < bankNpc:GetPos():DistToSqr(LocalPlayer():GetPos()) then bankNpc = ent end
		end

		bankFrame = DFW.UI.CreateFrame(bankData.title or "Bank Teller", 14 + 5 * (SLOT + GAP) + 40 + 6 * (SLOT + GAP) + 14, 560, nil, {compact = true, module = "exchange"})
		bankFrame:Center()
		bankFrame:SetSubtitle("Your vault belongs to this character. Click to move a whole stack, right click to move one.")

		local content = bankFrame:GetContent()

		local left = vgui.Create("Panel", content)
		left:Dock(LEFT)
		left:SetWide(5 * (SLOT + GAP) + 20)
		left.Paint = function(_, w) DFW.Draw.Text("Your pocket", "Body", 6, 6, DFW.UI.GetTheme().text) end

		local right = vgui.Create("Panel", content)
		right:Dock(FILL)
		right.Paint = function(_, w)
			DFW.Draw.Text("Vault (" .. #bankData.items .. "/" .. bankData.size .. ")", "Body", 26, 6, DFW.UI.GetTheme().text)
		end

		bankLeft = vgui.Create("DFW.ScrollPanel", left)
		bankLeft:Dock(FILL)
		bankLeft:DockMargin(0, 30, 0, 0)

		bankRight = vgui.Create("DFW.ScrollPanel", right)
		bankRight:Dock(FILL)
		bankRight:DockMargin(20, 30, 0, 0)

		-- Drag an item in from this window's pocket, or from the pocket / backpack windows, onto the vault to deposit it;
		-- drag one from the vault onto the pocket side to take it out
		local function dropsInto(panel, groups, action)
			for _, group in ipairs(groups) do
				panel:Receiver(group, function(_, dropped, isDropped)
					if not isDropped then return end

					local from = dropped[1] and dropped[1].SlotIndex
					if from then bankSend(action, from) end
				end)
			end
		end

		dropsInto(right, {"dubzbank_in", "dubzinv"}, "deposit")
		dropsInto(bankRight, {"dubzbank_in", "dubzinv"}, "deposit")
		dropsInto(left, {"dubzbank_out"}, "withdraw")
		dropsInto(bankLeft, {"dubzbank_out"}, "withdraw")

		-- Redraw when the pocket changes, close when you walk away
		bankFrame.Think = function(self)
			if not IsValid(bankNpc) or LocalPlayer():GetPos():Distance(bankNpc:GetPos()) > cfg.useDistance * 1.4 then self:Remove() return end
			if (self.NextCheck or 0) > CurTime() then return end

			self.NextCheck = CurTime() + 0.3
			if pocketSignature() ~= self.Signature then rebuildBank() end
		end
	end

	rebuildBank()
end)

-- The exchange -------------------------------------------------------------------------------------------------------------------

local exFrame, exNpc, exData, exBody, exTab, exTab_, exSelected, exSearch

local function exSend(action, a, b, c)
	net.Start("DubzEx_Action")
		net.WriteString(action)
		net.WriteUInt(math.max(math.floor(a or 0), 0), 32)
		net.WriteUInt(math.max(math.floor(b or 0), 0), 32)
		net.WriteUInt(math.max(math.floor(c or 0), 0), 32)
	net.SendToServer()
end

local function exButton(parent, label, width, variant, click, enabled)
	local button = vgui.Create("DFW.Button", parent)
	button:Dock(RIGHT)
	button:SetWide(width)
	button:DockMargin(4, 8, 4, 8)
	if variant then button:SetVariant(variant) end
	button:SetLabel(label)
	if enabled == false then button:SetEnabled(false) end
	button.DoClick = click
	return button
end

-- One listing as a row: icon, what it is, the seller, the price, and the buttons for it
local function listingRow(parent, listing, buttons)
	local row = vgui.Create("Panel", parent)
	row:Dock(TOP)
	row:SetTall(60)
	row:DockMargin(0, 0, 6, 3)

	buttons(row, listing)

	local icon = vgui.Create("DFW.ItemSlot", row)
	icon:SetPos(4, 4)
	icon:SetSize(52, 52)
	icon:SetItem(cellItem(listing), listing.name .. worthText(listing))

	row.Paint = function(_, w, h)
		local theme = DFW.UI.GetTheme()
		draw.RoundedBox(6, 0, 0, w, h, theme.slot)

		DFW.Draw.Text(listing.name .. "  x" .. listing.qty, "Body", 66, 18, theme.text)
		DFW.Draw.Text((listing.mine and "Your listing" or ("Sold by " .. listing.seller)) .. "   " .. money(listing.price) .. " each"
			.. ((listing.value or 0) > 0 and ("   (going rate " .. money(listing.value) .. ")") or ""), "Small", 66, 40, theme.textMuted)
	end

	return row
end

local function tabBrowse(body)
	local search = vgui.Create("DFW.TextEntry", body)
	search:Dock(TOP)
	search:SetTall(34)
	search:DockMargin(4, 0, 4, 6)
	search:SetPlaceholder("Search for an item")
	search:SetText(exSearch or "")

	local scroll = vgui.Create("DFW.ScrollPanel", body)
	scroll:Dock(FILL)

	local function fill()
		scroll:Clear()

		local text = string.lower(string.Trim(exSearch or ""))
		local shown = 0

		for _, listing in ipairs(exData.listings) do
			if text == "" or string.find(string.lower(listing.name), text, 1, true) then
				shown = shown + 1

				listingRow(scroll, listing, function(row)
					if listing.mine then return end

					exButton(row, "Buy all", 90, "primary", function() exSend("buy", listing.id, listing.qty) end)
					if listing.qty > 10 then exButton(row, "Buy 10", 80, nil, function() exSend("buy", listing.id, 10) end) end
					exButton(row, "Buy 1", 70, nil, function() exSend("buy", listing.id, 1) end)
				end)
			end
		end

		if shown == 0 then
			local empty = vgui.Create("DFW.Label", scroll)
			empty:Dock(TOP)
			empty:SetTall(30)
			empty:DockMargin(8, 12, 8, 0)
			empty:SetText(#exData.listings == 0 and "Nothing is for sale right now." or "Nothing matches that.")
		end
	end

	search.OnChange = function(self)
		exSearch = self:GetValue()
		fill()
	end

	fill()
end

local function tabSell(body)
	local slots, capacity = DubzInv.ClientState()

	-- Right side: what you are listing
	local right = vgui.Create("Panel", body)
	right:Dock(RIGHT)
	right:SetWide(330)
	right:DockMargin(8, 0, 0, 0)

	local rec = exSelected and slots[exSelected]
	local qty, price = 1, 0

	-- The lowest price anyone else asks for the same thing
	local lowest
	if rec then
		for _, listing in ipairs(exData.listings) do
			if listing.name == rec.name and (not lowest or listing.price < lowest) then lowest = listing.price end
		end
	end

	local priceEntry, listButton

	local function summary()
		local total = qty * price
		local tax = math.floor(total * exData.tax / 100)
		return total, tax
	end

	right.Paint = function(_, w, h)
		local theme = DFW.UI.GetTheme()
		draw.RoundedBox(6, 0, 0, w, h, theme.slot)

		if not rec then
			DFW.Draw.Text("Pick an item from your pocket.", "Body", 14, 16, theme.textMuted)
			return
		end

		DFW.Draw.Text(rec.name, "Heading", 14, 14, theme.text)
		DFW.Draw.Text("You have " .. rec.qty, "Small", 14, 44, theme.textMuted)
		DFW.Draw.Text(((rec.value or 0) > 0 and ("Recommended: " .. money(rec.value) .. " each (the going rate).   ") or "") .. (lowest and ("Lowest listed: " .. money(lowest)) or "Nobody else is selling this."), "Small", 14, 64, theme.textMuted)

		DFW.Draw.Text("How many: " .. qty, "Body", 14, 100, theme.text)
		DFW.Draw.Text("Price for each:", "Body", 14, 168, theme.text)

		local total, tax = summary()
		DFW.Draw.Text("Total " .. money(total), "Body", 14, 250, theme.text)
		DFW.Draw.Text("The exchange keeps " .. exData.tax .. "% (" .. money(tax) .. "). You get " .. money(total - tax) .. ".", "Small", 14, 276, theme.textMuted)
	end

	if rec then
		local slider = vgui.Create("DFW.Slider", right)
		slider:SetPos(14, 124)
		slider:SetSize(302, 22)
		slider:SetRange(1, math.max(rec.qty, 1))
		slider:SetDecimals(0)
		slider:SetValue(1, true)
		slider.OnValueChanged = function(_, v) qty = math.floor(v) end

		priceEntry = vgui.Create("DFW.TextEntry", right)
		priceEntry:SetPos(14, 192)
		priceEntry:SetSize(302, 40)
		priceEntry:SetNumeric(true)
		priceEntry:SetPlaceholder("Price for each")
		priceEntry.OnChange = function(self) price = tonumber(self:GetValue()) or 0 end

		-- Start at the recommended price (the going rate)
		if (rec.value or 0) > 0 then
			priceEntry:SetText(tostring(rec.value))
			price = rec.value
		end

		local function quick(label, x, width, value)
			if not value then return end

			local button = vgui.Create("DFW.Button", right)
			button:SetPos(x, 300)
			button:SetSize(width, 30)
			button:SetLabel(label)
			button.DoClick = function()
				local set = math.max(1, math.floor(value))
				priceEntry:SetText(tostring(set))
				price = set
			end
		end

		quick("Recommended", 14, 98, (rec.value or 0) > 0 and rec.value)
		quick("Match lowest", 118, 98, lowest)
		quick("Undercut 5%", 222, 94, lowest and lowest * 0.95)

		listButton = vgui.Create("DFW.Button", right)
		listButton:SetPos(14, 350)
		listButton:SetSize(302, 40)
		listButton:SetVariant("primary")
		listButton:SetLabel("List it for sale")
		listButton.DoClick = function()
			if price < 1 then DFW.UI.Notify("Enter a price first.", "danger", 3) return end
			exSend("sell", exSelected, qty, price)
			exSelected = nil
		end
	end

	-- Left side: your pocket
	local scroll = vgui.Create("DFW.ScrollPanel", body)
	scroll:Dock(FILL)

	for index = 1, capacity or 0 do
		local col, row = (index - 1) % 7, math.floor((index - 1) / 7)

		local cell = vgui.Create("DFW.ItemSlot", scroll)
		cell:SetPos(col * (SLOT + GAP), row * (SLOT + GAP))
		cell:SetSize(SLOT, SLOT)
		cell:SetSlotIndex(index)

		local item = slots[index]
		if item then
			cell:SetItem(item, item.name .. (item.qty > 1 and (" x" .. item.qty) or "") .. worthText(item) .. " - click to sell it")
			cell.OnClick = function()
				exSelected = index
				exTab("sell")
			end

			if index == exSelected then
				local paintOver = cell.PaintOver
				cell.PaintOver = function(self, w, h)
					if paintOver then paintOver(self, w, h) end
					surface.SetDrawColor(DFW.UI.GetTheme().accent)
					surface.DrawOutlinedRect(0, 0, w, h, 2)
				end
			end
		end
	end
end

local function tabMine(body)
	-- Waiting sales cash
	local top = vgui.Create("Panel", body)
	top:Dock(TOP)
	top:SetTall(56)
	top:DockMargin(0, 0, 6, 6)

	exButton(top, "Collect", 130, "primary", function() exSend("collect") end, exData.cash > 0)

	top.Paint = function(_, w, h)
		local theme = DFW.UI.GetTheme()
		draw.RoundedBox(6, 0, 0, w, h, theme.slot)
		DFW.Draw.Text("Waiting for you: " .. money(exData.cash), "Body", 14, h / 2 - 8, theme.text)
		DFW.Draw.Text(#exData.mine .. " of " .. exData.slots .. " listings in use", "Small", 14, h / 2 + 12, theme.textMuted)
	end

	local scroll = vgui.Create("DFW.ScrollPanel", body)
	scroll:Dock(FILL)

	if #exData.mine == 0 then
		local empty = vgui.Create("DFW.Label", scroll)
		empty:Dock(TOP)
		empty:SetTall(30)
		empty:DockMargin(8, 12, 8, 0)
		empty:SetText("You have nothing listed. Use the Sell tab.")
	end

	for _, listing in ipairs(exData.mine) do
		listingRow(scroll, listing, function(row)
			exButton(row, "Take down", 110, nil, function() exSend("cancel", listing.id) end)
		end)
	end
end

local tabs = {browse = tabBrowse, sell = tabSell, mine = tabMine}

function exTab(id)
	if not (IsValid(exFrame) and IsValid(exBody)) then return end

	exTab_ = id
	exBody:Clear()
	tabs[id](exBody)
end

local function rebuildExchange()
	exTab(exTab_ or "browse")
end

net.Receive("DubzEx_State", function()
	exData = util.JSONToTable(net.ReadString()) or {listings = {}, mine = {}, cash = 0, slots = 0, tax = 0}
	exData.listings, exData.mine = exData.listings or {}, exData.mine or {}

	if not frameworkReady() then return end

	if not IsValid(exFrame) then
		exNpc = nil
		for _, ent in ipairs(ents.FindByClass("dubz_exchange_clerk")) do
			if not IsValid(exNpc) or ent:GetPos():DistToSqr(LocalPlayer():GetPos()) < exNpc:GetPos():DistToSqr(LocalPlayer():GetPos()) then exNpc = ent end
		end

		exFrame = DFW.UI.CreateFrame(exData.title or "Exchange Clerk", 940, 620, nil, {compact = true, module = "exchange"})
		exFrame:Center()
		exFrame:SetSubtitle("List anything from your pocket for any player to buy, even while you are away.")

		-- (the server sends updates to everyone with this window open; tell it when this one closes)
		exFrame.OnRemove = function()
			net.Start("DubzEx_Close")
			net.SendToServer()
		end
		exSelected, exSearch, exTab_ = nil, nil, "browse"

		local content = exFrame:GetContent()

		local bar = vgui.Create("DFW.TabBar", content)
		bar:Dock(TOP)
		bar:SetTall(36)
		bar:DockMargin(4, 4, 4, 8)
		bar:AddTab("browse", "Browse")
		bar:AddTab("sell", "Sell")
		bar:AddTab("mine", "My listings")
		bar.OnTabChanged = function(_, id) exTab(id) end
		bar:SetActive("browse", true)

		exBody = vgui.Create("Panel", content)
		exBody:Dock(FILL)

		exFrame.Think = function(self)
			if not IsValid(exNpc) or LocalPlayer():GetPos():Distance(exNpc:GetPos()) > cfg.useDistance * 1.4 then self:Remove() return end
			if (self.NextCheck or 0) > CurTime() then return end

			self.NextCheck = CurTime() + 0.4

			-- The Sell tab shows the pocket, so it redraws when the pocket changes
			local sig = pocketSignature()
			if exTab_ == "sell" and sig ~= self.Signature then rebuildExchange() end
			self.Signature = sig
		end
	end

	-- Anything already open is redrawn with the new numbers (but typing in the search box is left alone)
	if exTab_ == "browse" and IsValid(exFrame) and exSearch and exSearch ~= "" then
		exBody:Clear()
		tabBrowse(exBody)
	else
		rebuildExchange()
	end
end)
