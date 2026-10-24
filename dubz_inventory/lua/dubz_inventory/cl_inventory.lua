-- Pocket window (a grid of 64px slots), the backpack container window, pickup progress bar, the B key, and the
-- worn backpack model.
--   Pocket: left click an item = use it. Right click = menu (Use / Drop / ...). Drag onto another slot to move,
--   swap or merge stacks.
--   Backpack on the ground: E opens it (click an item to take it; "Put in backpack" in the pocket menu).
--   B: put on the backpack you're looking at, or drop the one you wear.
--
-- Other addons can add right-click entries:
--   hook.Add("DubzInvContextMenu", "MyAddon", function(menu, slot, rec) menu:AddOption("Sell", function() ... end) end)
local cfg = DubzInv.Config

local SLOT = 64
local GAP = 3
local PAD = 10

local capacity = cfg.slots
local slots = {}   -- index -> {name, model, class, qty}
local frame, bagFrame
local bagView      -- {slots = n, items = {[i] = {name, model, class, qty}}} while a backpack on the ground is open

-- Windows, slots and the pickup bar are Dubz Framework controls (DFW.Frame, DFW.ItemSlot, DFW.HeaderRow ...),
-- so they follow the framework theme and any change to those controls.

-- Networking -------------------------------------------------------------------------------------------

local function send(action, a, b)
	net.Start("DubzInv_Action")
		net.WriteString(action)
		net.WriteUInt(a or 0, 8)
		net.WriteUInt(b or 0, 8)
	net.SendToServer()
end

local function sendBag(action, slot, second)
	net.Start("DubzInv_BagAction")
		net.WriteString(action)
		net.WriteUInt(slot or 0, 8)
		net.WriteUInt(second or 0, 8)
	net.SendToServer()
end

local reload, reloadBag, openBagWindow

-- An item's colour and material (see sv_inventory.lua): lets the pocket draw a tinted gem as a tinted gem
local function readLook(item)
	if not net.ReadBool() then return end

	item.color = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
	item.material = net.ReadString()
end

-- Other addons can add a line to the tooltip (for example how many grams a stack of weed bags holds): return a string
local function note(rec)
	local text = hook.Run("DubzInvTooltip", rec)

	return text and ("  -  " .. text) or ""
end

-- "worth about $X": the going rate the exchange reports for an item (0 = unknown, nothing is shown)
local function worth(rec)
	if (rec.value or 0) <= 0 then return note(rec) end

	local text = DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(rec.value) or ("$" .. rec.value)
	return "  -  worth about " .. text .. (rec.qty > 1 and " each" or "") .. note(rec)
end

net.Receive("DubzInv_Sync", function()
	capacity = net.ReadUInt(8)
	slots = {}

	for _ = 1, net.ReadUInt(8) do
		local index = net.ReadUInt(8)
		slots[index] = {name = net.ReadString(), model = net.ReadString(), class = net.ReadString(), qty = net.ReadUInt(16)}
		readLook(slots[index])
		slots[index].value = net.ReadUInt(32)
	end

	if IsValid(frame) then reload() end
	hook.Run("DubzInvSynced")
end)

net.Receive("DubzInv_BagView", function()
	if not net.ReadBool() then
		bagView = nil
		if IsValid(bagFrame) then bagFrame:Remove() end
		bagFrame = nil
		return
	end

	bagView = {slots = net.ReadUInt(8), items = {}}

	for _ = 1, net.ReadUInt(8) do
		local index = net.ReadUInt(8)
		bagView.items[index] = {name = net.ReadString(), model = net.ReadString(), class = net.ReadString(), qty = net.ReadUInt(16)}
		readLook(bagView.items[index])
		bagView.items[index].value = net.ReadUInt(32)
	end

	if IsValid(bagFrame) then reloadBag() else openBagWindow() end
end)

-- For other client files (the trade window): the owner's slots and capacity
function DubzInv.ClientState()
	return slots, capacity
end

-- Pocket window -------------------------------------------------------------------------------------------

local function itemMenu(slot, rec)
	local menu = DermaMenu()

	menu:AddOption(cfg.useLabels[rec.class] or "Use", function() send("use", slot) end)

	-- Deploy puts ONE down, working. Drop puts the item (or the whole stack, as one prop) on the ground, not working,
	-- until it is picked up and deployed.
	if rec.class ~= "dubz_cosmetic" then menu:AddOption("Deploy", function() send("deploy", slot) end) end

	if rec.qty > 1 then
		menu:AddOption("Drop 1", function() send("drop", slot) end)
		menu:AddOption("Drop all (" .. rec.qty .. ")", function() send("dropall", slot) end)
	else
		menu:AddOption("Drop", function() send("drop", slot) end)
	end

	-- A backpack on the ground is open: items from the pocket slots can be put in it
	if bagView then
		menu:AddOption("Put in backpack", function() sendBag("put", slot) end)
	end

	hook.Run("DubzInvContextMenu", menu, slot, rec)

	menu:Open()
end

-- Worn accessories (from the cosmetics addon): one cell per slot to the left of the pocket. Drag a worn item into
-- the pocket or click it to take it off; drag an accessory from the pocket onto its cell to put it on.
local EQUIP_BASE = 200   -- slot indexes of the worn cells (pocket slots are below this)

local function wornSlots()
	if not (DubzCosmetics and DubzCosmetics.Config and DubzCosmetics.Enabled and DubzCosmetics.Enabled()) then return nil end
	return DubzCosmetics.Config.slots
end

local function wornSignature()
	local list = wornSlots()
	if not list then return "" end

	local parts = {}
	for _, slot in ipairs(list) do parts[#parts + 1] = DubzCosmetics.GetWornItem(LocalPlayer(), slot.id) end
	return table.concat(parts, "|")
end

local function takeOff(slotId)
	net.Start("DubzCos_Unequip")
		net.WriteString(slotId)
	net.SendToServer()
end

local function buildWornCell(parent, order, slot, x, y)
	local cell = vgui.Create("DFW.ItemSlot", parent)
	cell:SetPos(x, y)
	cell:SetSize(SLOT, SLOT)
	cell:SetSlotIndex(EQUIP_BASE + order)
	cell:SetDragGroup("dubzinv")

	-- A pocket item dropped here is put on (the server picks the right slot for it)
	cell.OnDropped = function(self, from)
		if from < EQUIP_BASE then send("use", from) end
	end

	local id = DubzCosmetics.GetWornItem(LocalPlayer(), slot.id)
	local def = id ~= "" and DubzCosmetics.Get(id)

	if def then
		cell:SetItem({model = def.model, qty = 1}, DubzCosmetics.DisplayName(id) .. " - click or drag to take off")
		cell.OnClick = function() takeOff(slot.id) end
		cell.OnRightClick = function() takeOff(slot.id) end
	end

	-- The slot's name sits on the cell so an empty one still says what goes there
	local base = cell.PaintOver
	cell.PaintOver = function(self, w, h)
		if base then base(self, w, h) end
		if not def then DFW.Draw.Text(slot.name, "Tiny", w / 2, h / 2, DFW.UI.GetTheme().textDim, TEXT_ALIGN_CENTER) end
	end

	return cell
end

local function buildSlot(parent, index, x, y)
	local cell = vgui.Create("DFW.ItemSlot", parent)
	cell:SetPos(x, y)
	cell:SetSize(SLOT, SLOT)
	cell:SetSlotIndex(index)
	cell:SetDragGroup("dubzinv")

	-- An item dragged out of an open container lands in the pocket
	cell:Receiver("dubzbag", function(_, dropped, isDropped)
		if isDropped and dropped[1] and dropped[1].SlotIndex then sendBag("take", dropped[1].SlotIndex) end
	end)

	-- Drop another slot's item here to move / swap / merge
	cell.OnDropped = function(self, from)
		-- From a worn cell: take that accessory off (it lands in the pocket)
		if from >= EQUIP_BASE then
			local list = wornSlots()
			local slot = list and list[from - EQUIP_BASE]
			if slot then takeOff(slot.id) end
			return
		end

		send("move", from, index)
	end

	local rec = slots[index]
	if not rec then return cell end

	cell:SetItem(rec, rec.name .. (rec.qty > 1 and (" x" .. rec.qty) or "") .. worth(rec) .. " - left click: " .. (cfg.useLabels[rec.class] or "Use") .. ", right click: more")
	cell.OnClick = function() send("use", index) end
	cell.OnRightClick = function() itemMenu(index, rec) end

	return cell
end

function reload()
	if not IsValid(frame) then return end

	frame.Content:Clear()

	local perRow = cfg.perRow
	local base = cfg.slots
	local y = 0

	-- Worn accessories column on the left (when the cosmetics addon is installed)
	local worn = wornSlots()
	local left = worn and (SLOT + 16) or 0
	frame.WornSig = wornSignature()

	if worn then
		for order, slot in ipairs(worn) do buildWornCell(frame.Content, order, slot, 0, (order - 1) * (SLOT + GAP)) end
	end

	local function section(first, last)
		local count = last - first + 1

		for i = 0, count - 1 do
			local col, row = i % perRow, math.floor(i / perRow)
			buildSlot(frame.Content, first + i, left + col * (SLOT + GAP), y + row * (SLOT + GAP))
		end

		y = y + math.ceil(count / perRow) * (SLOT + GAP)
	end

	section(1, math.min(base, capacity))

	if capacity > base then
		local header = vgui.Create("DFW.HeaderRow", frame.Content)
		header:SetPos(left, y + 4)
		header:SetSize(perRow * (SLOT + GAP) - GAP, 22)
		header:SetLeft(function()
			local bagUsed = 0
			for i = base + 1, capacity do
				if slots[i] then bagUsed = bagUsed + 1 end
			end

			return "Backpack (" .. bagUsed .. "/" .. (capacity - base) .. ")"
		end)
		header:SetRight("Press " .. string.upper(input.GetKeyName(cfg.dropBagKey) or "B") .. " to drop it")

		y = y + 30
		section(base + 1, capacity)
	end

	if worn then y = math.max(y, #worn * (SLOT + GAP)) end

	local width = left + perRow * (SLOT + GAP) - GAP + PAD * 2
	frame:SetSize(width, 24 + y + PAD * 2)

	-- Keep the worn cells in step when something is put on or taken off (the server changes it, not this window)
	if not frame.WornWatch then
		frame.WornWatch = true

		local think = frame.Think
		frame.Think = function(self)
			if think then think(self) end

			if worn and (self.NextWornCheck or 0) < CurTime() then
				self.NextWornCheck = CurTime() + 0.25
				if wornSignature() ~= self.WornSig then reload() end
			end
		end
	end

	-- Keep the backpack container window next to the pocket
	if IsValid(bagFrame) then
		frame:SetPos(ScrW() / 2 - width - 6, ScrH() / 2 - frame:GetTall() / 2)
		bagFrame:SetPos(ScrW() / 2 + 6, frame:GetY())
	else
		frame:Center()
	end
end

local function closeMenu()
	if IsValid(frame) then frame:Remove() end
	frame = nil
end

-- Clean toggle: one action per key press (holding the key does nothing more) and one second between
-- toggles. To close the window with the key you must let go and press again.
local nextToggle = 0
local waitRelease = false

-- Wraps a framework frame so the open key toggles it cleanly (see waitRelease above)
local function hookToggleKey(window)
	local baseThink = window.Think
	window.Think = function(self)
		baseThink(self)
		if waitRelease and not input.IsKeyDown(cfg.openKey) then waitRelease = false end
	end

	local baseKey = window.OnKeyCodePressed
	window.OnKeyCodePressed = function(self, key)
		if key == cfg.openKey and not waitRelease then DubzInv.ToggleMenu() return end
		baseKey(self, key)
	end
end

local function frameworkReady()
	if DFW and DFW.UI and DFW.UI.CreateFrame then return true end

	chat.AddText(Color(255, 80, 80), "[Pocket] ", color_white, "The Dubz Framework addon isn't installed, so the inventory window can't open.")
	return false
end

local function buildPocketWindow()
	closeMenu()
	if not frameworkReady() then return end

	-- If the key is still held when the window appears, ignore it until it is released
	waitRelease = input.IsKeyDown(cfg.openKey)

	frame = DFW.UI.CreateFrame("Pocket", 100, 100, nil, {compact = true, module = "inventory"})
	frame.Content:DockMargin(PAD - 5, PAD - 5, PAD - 5, PAD - 5)
	hookToggleKey(frame)

	local baseThink = frame.Think
	frame.Think = function(self)
		baseThink(self)

		-- The window title carries the pocket count; the backpack count sits under its own header
		local pocketMax = math.min(cfg.slots, capacity)
		local used = 0
		for i = 1, pocketMax do
			if slots[i] then used = used + 1 end
		end

		local text = "Pocket (" .. used .. "/" .. pocketMax .. ")"
		if self.TitleText ~= text then
			self.TitleText = text
			self:SetTitle(text)
		end
	end

	reload()
end

-- Opens the pocket if it isn't open (the pocket SWEP's Reload and the chat command use this)
function DubzInv.OpenMenu()
	if not DubzInv.Enabled() then return end
	if IsValid(frame) or CurTime() < nextToggle then return end
	nextToggle = CurTime() + 1

	buildPocketWindow()
end

function DubzInv.ToggleMenu()
	if not DubzInv.Enabled() then return end
	if CurTime() < nextToggle then return end
	nextToggle = CurTime() + 1

	if IsValid(frame) then closeMenu() else buildPocketWindow() end
end

net.Receive("DubzInv_Open", function() DubzInv.OpenMenu() end)

-- Backpack container window ---------------------------------------------------------------------------------

function reloadBag()
	if not IsValid(bagFrame) or not bagView then return end

	bagFrame.Content:Clear()

	local perRow = cfg.perRow
	local rows = math.ceil(bagView.slots / perRow)

	for i = 1, bagView.slots do
		local col, row = (i - 1) % perRow, math.floor((i - 1) / perRow)

		local cell = vgui.Create("DFW.ItemSlot", bagFrame.Content)
		cell:SetPos(col * (SLOT + GAP), row * (SLOT + GAP))
		cell:SetSize(SLOT, SLOT)
		cell:SetSlotIndex(i)

		-- Drag within the container to rearrange it; drag an item in from the pocket or worn backpack to store it
		cell:SetDragGroup("dubzbag")
		cell.OnDropped = function(self, from) sendBag("move", from, i) end
		cell:Receiver("dubzinv", function(_, dropped, isDropped)
			if isDropped and dropped[1] and dropped[1].SlotIndex then sendBag("put", dropped[1].SlotIndex) end
		end)

		local rec = bagView.items[i]
		if rec then
			cell:SetItem(rec, rec.name .. (rec.qty > 1 and (" x" .. rec.qty) or "") .. worth(rec) .. " - click to take it")
			cell.OnClick = function() sendBag("take", i) end
			cell.OnRightClick = function()
				local menu = DermaMenu()
				menu:AddOption("Take", function() sendBag("take", i) end)
				menu:Open()
			end
		end
	end

	bagFrame:SetSize(perRow * (SLOT + GAP) - GAP + PAD * 2, 24 + rows * (SLOT + GAP) + PAD * 2 + 20)
end

function openBagWindow()
	if IsValid(bagFrame) then bagFrame:Remove() end
	if not frameworkReady() then return end

	bagFrame = DFW.UI.CreateFrame("Backpack", 100, 100, nil, {compact = true, module = "inventory"})
	bagFrame.Content:DockMargin(PAD - 5, PAD - 5, PAD - 5, PAD + 10)

	-- Hint along the bottom edge
	bagFrame.PaintOver = function(self, w, h)
		DFW.Draw.Text("Drag items here to store them", "Small", w / 2, h - 14, DFW.UI.Color("textMuted"), TEXT_ALIGN_CENTER)
	end

	-- Closing it tells the server too
	bagFrame.OnClose = function()
		bagView = nil
		sendBag("close")
	end

	reloadBag()

	-- Opening a backpack also shows your pocket beside it so you can move things between the two
	if not IsValid(frame) then
		nextToggle = CurTime() + 1
		buildPocketWindow()
	else
		reload()
	end
end

-- Keys -----------------------------------------------------------------------------------------------------------

local function typing()
	local focus = vgui.GetKeyboardFocus()
	return IsValid(focus) and focus:GetClassName() == "TextEntry"
end

local function lookingAtBackpack(ply)
	local tr = ply:GetEyeTrace()
	local ent = tr.Entity

	if IsValid(ent) and DubzInv.IsBagClass(ent:GetClass()) and ply:EyePos():Distance(tr.HitPos) <= cfg.bagOpenDistance then return ent end
end

local held = {}

hook.Add("PlayerButtonUp", "DubzInv_KeysUp", function(ply, button)
	if ply == LocalPlayer() then held[button] = nil end
end)

hook.Add("PlayerButtonDown", "DubzInv_Keys", function(ply, button)
	if ply ~= LocalPlayer() or not DubzInv.Enabled() then return end

	-- Only the first frame of a press counts; holding the key does nothing more
	if held[button] then return end
	held[button] = true

	if typing() then return end

	if button == cfg.openKey then
		DubzInv.ToggleMenu()
	elseif button == cfg.dropBagKey then
		if DubzInv.HasBag(ply) then
			RunConsoleCommand("dubz_dropbag")
		elseif lookingAtBackpack(ply) then
			RunConsoleCommand("dubz_wearbag")
		end
	end
end)

-- Prompt when looking at a backpack on the ground
hook.Add("HUDPaint", "DubzInv_BagPrompt", function()
	if BHUD and BHUD.Cinematic then return end

	local lp = LocalPlayer()
	if not IsValid(lp) or not lp:Alive() or IsValid(bagFrame) then return end
	if not lookingAtBackpack(lp) then return end

	local text = "E: open    " .. string.upper(input.GetKeyName(cfg.dropBagKey) or "B") .. ": wear"
	draw.SimpleTextOutlined(text, "Trebuchet24", ScrW() / 2, ScrH() / 2 + 40, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
end)

-- Pickup progress bar -----------------------------------------------------------------------------------

hook.Add("HUDPaint", "DubzInv_PickupBar", function()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end

	local start = lp:GetNWFloat("dubz_pick_start", 0)
	if start <= 0 then return end

	local time = lp:GetNWFloat("dubz_pick_time", 1)
	local fraction = math.Clamp((CurTime() - start) / time, 0, 1)

	if DFW and DFW.Draw and DFW.Draw.ProgressCard then
		DFW.Draw.ProgressCard(ScrW() / 2, ScrH() * 0.62, 220, "Picking up...", fraction)
	end
end)

-- The backpack you wear is drawn by dubz_cosmetics (it is a "back" slot item, "backpack", so its placement is
-- tuned with the cosmetic placement editor like any accessory).
