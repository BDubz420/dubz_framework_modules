-- The /trade window. Layout: "You offer" and "They offer" side by side on top, your own inventory (with the
-- backpack, if you wear one) underneath. Click an item in your inventory to add or remove it from your offer.
-- Both players must press Accept; any change to either offer clears both accepts.
local cfg = DubzInv.Config

local SLOT = 64
local GAP = 3
local GREEN = Color(110, 190, 120)

local function gold() return DFW and DFW.UI and DFW.UI.Color("accent") or Color(241, 196, 15) end
local function muted() return DFW and DFW.UI and DFW.UI.Color("textMuted") or Color(170, 160, 160) end

local frame
local partner
local mine = {slots = {}, cash = 0, accepted = false}     -- my offer as last confirmed by the server
local theirs = {items = {}, cash = 0, accepted = false}
local pendingSlots = {}   -- slot index -> how many of that stack I've chosen (sent to the server)
local cashEntry

local function sendOffer()
	local list = table.GetKeys(pendingSlots)
	table.sort(list)

	net.Start("DubzTrade_Offer")
		net.WriteUInt(#list, 8)
		for _, index in ipairs(list) do
			net.WriteUInt(index, 8)
			net.WriteUInt(math.Clamp(pendingSlots[index], 1, 65535), 16)
		end
		net.WriteUInt(math.max(0, math.floor(tonumber(IsValid(cashEntry) and cashEntry:GetValue() or 0) or 0)), 32)
	net.SendToServer()
end

-- Networking -------------------------------------------------------------------------------------------

-- Someone wants to trade with you
net.Receive("DubzTrade_Request", function()
	local from = net.ReadEntity()
	if not IsValid(from) then return end

	local function reply(accept)
		net.Start("DubzTrade_Reply") net.WriteBool(accept) net.SendToServer()
	end

	if DFW and DFW.UI and DFW.UI.Confirm then
		DFW.UI.Confirm("Trade request", from:Nick() .. " wants to trade with you.", function() reply(true) end,
			{confirmLabel = "Accept", cancelLabel = "Decline", onCancel = function() reply(false) end})
	else
		reply(false)
	end
end)

local build

net.Receive("DubzTrade_Open", function()
	partner = net.ReadEntity()
	mine = {slots = {}, cash = 0, accepted = false}
	theirs = {items = {}, cash = 0, accepted = false}
	pendingSlots = {}

	build()
end)

local function readSide()
	local side = {items = {}}

	for i = 1, net.ReadUInt(8) do side.items[i] = {name = net.ReadString(), model = net.ReadString()} end
	side.cash = net.ReadUInt(32)
	side.accepted = net.ReadBool()

	return side
end

local refresh

net.Receive("DubzTrade_Update", function()
	local own = readSide()
	theirs = readSide()
	mine = {items = own.items, cash = own.cash, accepted = own.accepted}

	if IsValid(frame) then refresh() end
end)

net.Receive("DubzTrade_Close", function()
	local reason = net.ReadString()

	if IsValid(frame) then frame:Remove() end
	frame = nil

	if reason ~= "" then chat.AddText(GREEN, "[Trade] ", color_white, reason) end
end)

-- Window ---------------------------------------------------------------------------------------------------

local function offerGrid(parent, x, y, items, onClick)
	local grid = vgui.Create("Panel", parent)
	grid:SetPos(x, y)
	grid:SetSize(5 * (SLOT + GAP) - GAP, 2 * (SLOT + GAP) - GAP)

	for i = 1, cfg.tradeMaxItems do
		local col, row = (i - 1) % 5, math.floor((i - 1) / 5)
		local item = items[i]

		local slot = vgui.Create("DFW.ItemSlot", grid)
		slot:SetPos(col * (SLOT + GAP), row * (SLOT + GAP))
		slot:SetSize(SLOT, SLOT)

		if item then
			slot:SetItem(item, item.name)
			if onClick then slot.OnClick = function() onClick(i) end end
		end
	end

	return grid
end

function refresh()
	if not IsValid(frame) then return end

	frame.Offers:Clear()

	local half = 5 * (SLOT + GAP) - GAP

	-- Your offer (click an item to take it back out)
	offerGrid(frame.Offers, 0, 26, mine.items or {}, function(i)
		-- remove the i-th offered item by finding its slot index in my pending list
		local list = table.GetKeys(pendingSlots)
		table.sort(list)
		if list[i] then pendingSlots[list[i]] = nil sendOffer() end
	end)

	-- Their offer (read only)
	offerGrid(frame.Offers, half + 40, 26, theirs.items, nil)

	local function status(accepted) return accepted and "Accepted" or "Not accepted yet" end

	frame.Status = {
		mine = status(mine.accepted), mineOk = mine.accepted,
		theirs = status(theirs.accepted), theirsOk = theirs.accepted,
		theirCash = theirs.cash,
	}

	frame.AcceptBtn:SetLabel(mine.accepted and "Cancel accept" or "Accept")

	frame.Inventory:InvalidateLayout()
	if frame.RebuildInventory then frame.RebuildInventory() end
end

function build()
	if IsValid(frame) then frame:Remove() end
	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then
		chat.AddText(Color(255, 80, 80), "[Trade] ", color_white, "The Dubz Framework addon isn't installed, so the trade window can't open.")
		net.Start("DubzTrade_Cancel") net.SendToServer()
		return
	end

	local half = 5 * (SLOT + GAP) - GAP
	local width = half * 2 + 40 + 20
	local invRows = math.ceil(((DubzInv.ClientState and select(2, DubzInv.ClientState())) or cfg.slots) / 5)

	frame = DFW.UI.CreateFrame("Trade with " .. (IsValid(partner) and partner:Nick() or "player"), width,
		24 + 26 + 2 * (SLOT + GAP) + 130 + 28 + invRows * (SLOT + GAP) + 50, nil, {compact = true, module = "inventory"})

	-- Everything below is placed by hand inside the frame's content area, with the frame's own coordinates
	local content = frame:GetContent()
	content:DockMargin(0, 0, 0, 0)
	frame.Content.Paint = function(self, w, h)
		local s = frame.Status
		if not s then return end

		DFW.Draw.Text("You offer", "Body", 5, 11, color_white)
		DFW.Draw.Text(s.mine, "Body", 5 + half, 11, s.mineOk and GREEN or muted(), TEXT_ALIGN_RIGHT)

		DFW.Draw.Text((IsValid(partner) and partner:Nick() or "They") .. " offers", "Body", 5 + half + 40, 11, color_white)
		DFW.Draw.Text(s.theirs, "Body", w - 5, 11, s.theirsOk and GREEN or muted(), TEXT_ALIGN_RIGHT)
	end

	-- Closing the window cancels the trade
	frame.OnClose = function()
		net.Start("DubzTrade_Cancel") net.SendToServer()
	end

	frame.Offers = vgui.Create("Panel", content)
	frame.Offers:SetPos(5, 0)
	frame.Offers:SetSize(width - 20, 26 + 2 * (SLOT + GAP))

	local rowY = 26 + 2 * (SLOT + GAP) + 6

	-- Cash I'm offering
	local cashLabel = vgui.Create("DFW.Label", content)
	cashLabel:SetPos(5, rowY)
	cashLabel:SetSize(44, 24)
	cashLabel:SetText("Cash:")

	cashEntry = vgui.Create("DFW.TextEntry", content)
	cashEntry:SetPos(50, rowY)
	cashEntry:SetSize(110, 24)
	cashEntry:SetNumeric(true)
	cashEntry:SetText("0")

	local debounce = "DubzTrade_Cash"
	cashEntry.OnChange = function()
		timer.Create(debounce, 0.5, 1, sendOffer)
	end

	-- Their cash
	local theirCash = vgui.Create("Panel", content)
	theirCash:SetPos(5 + half + 40, rowY)
	theirCash:SetSize(half, 24)
	theirCash.Paint = function(_, w, h)
		local cash = theirs.cash or 0
		DFW.Draw.Text("Cash: " .. DarkRP.formatMoney(cash), "Body", 0, h / 2, cash > 0 and gold() or color_white)
	end

	-- Accept / cancel
	frame.AcceptBtn = vgui.Create("DFW.Button", content)
	frame.AcceptBtn:SetPos(5, rowY + 32)
	frame.AcceptBtn:SetSize(half, 28)
	frame.AcceptBtn:SetLabel("Accept")
	frame.AcceptBtn.DoClick = function()
		-- push my latest offer first, then toggle the accept
		timer.Remove(debounce)
		sendOffer()
		net.Start("DubzTrade_Accept") net.WriteBool(not mine.accepted) net.SendToServer()
	end

	local cancel = vgui.Create("DFW.Button", content)
	cancel:SetPos(5 + half + 40, rowY + 32)
	cancel:SetSize(half, 28)
	cancel:SetLabel("Cancel trade")
	cancel.DoClick = function() frame:Close() end

	-- My inventory (pockets + backpack), click to add / remove from the offer
	frame.Inventory = vgui.Create("Panel", content)
	frame.Inventory:SetPos(5, rowY + 70)
	frame.Inventory:SetSize(width - 20, frame:GetTall() - 29 - (rowY + 70) - 10)
	frame.Inventory.Paint = function(self, w, h)
		DFW.Draw.Text("Your pocket - click an item to offer it", "Body", 0, 9, muted())
	end

	frame.RebuildInventory = function()
		frame.Inventory:Clear()

		local slots, capacity = DubzInv.ClientState()
		local base = cfg.slots

		for index = 1, capacity do
			-- backpack slots start a new row so they read as their own section
			local position = index
			if index > base then position = math.ceil(base / 5) * 5 + (index - base) end

			local col, row = (position - 1) % 5, math.floor((position - 1) / 5)

			local cell = vgui.Create("DFW.ItemSlot", frame.Inventory)
			cell:SetPos(col * (SLOT + GAP), 22 + row * (SLOT + GAP))
			cell:SetSize(SLOT, SLOT)
			cell:SetHighlight(pendingSlots[index] == true)

			local rec = slots[index]
			if rec then
				cell:SetItem(rec, rec.name)

				-- A stack asks how many to offer (0 takes it back out); a single item just toggles
				local have = rec.qty or 1

				cell.OnClick = function()
					if have > 1 and DFW.UI.Prompt and (pendingSlots[index] or table.Count(pendingSlots) < cfg.tradeMaxItems) then
						DFW.UI.Prompt("How many?", rec.name .. ": you have " .. have .. ". Enter how many to offer (0 removes it from the offer).",
							tostring(pendingSlots[index] or have), function(text)
								local amount = math.floor(tonumber(text) or -1)
								if amount < 0 then return end

								pendingSlots[index] = amount > 0 and math.min(amount, have) or nil
								sendOffer()
								if IsValid(frame) then frame.RebuildInventory() end
							end)
						return
					end

					if pendingSlots[index] then
						pendingSlots[index] = nil
					elseif table.Count(pendingSlots) < cfg.tradeMaxItems then
						pendingSlots[index] = have
					end

					sendOffer()
				end
			end
		end
	end

	frame.RebuildInventory()
end

-- If my inventory changes while the window is open (it shouldn't, actions are blocked), keep it in step
hook.Add("DubzInvSynced", "DubzTrade_Resync", function()
	if IsValid(frame) and frame.RebuildInventory then frame.RebuildInventory() end
end)
