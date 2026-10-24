-- The two store windows, opened by the clerk NPCs (entities/dubz_cos_npc*):
--   Accessories: a big preview of YOUR character on the left (wearing what you have on now, with the selected
--   accessory tried on in its slot), a grid of accessories for sale on the right with model previews and prices,
--   a Buy button (the accessory goes into your pocket as a small suitcase), and what you wear now with Take off.
--   Clothing: Male / Female tabs, the looks (faces) for that gender, and below them the clothing sets. The preview
--   on the left shows the chosen look in the chosen clothing. One button buys and wears whatever changed: a new
--   look costs Config.lookPrice, a clothing set you don't own costs its price (Config.clothingPrices).
-- Built from Dubz Framework controls, so both follow the framework theme. Drag the preview to turn it.
local cfg = DubzCosmetics.Config

local frame

-- Badge colours / labels for limited and seasonal items
local TIER_COLORS = {limited = Color(235, 180, 60), seasonal = Color(110, 200, 240)}
local TIER_LABELS = {limited = "LIMITED", seasonal = "SEASONAL"}

-- A random funny line from the clerk; avoids repeating the last one
local lastQuip
local function quipFor(name)
	local list = cfg.quips
	if not list or #list == 0 then return "" end

	local line
	for _ = 1, 4 do
		line = list[math.random(#list)]
		if line ~= lastQuip then break end
	end
	lastQuip = line

	return (string.gsub(line, "%%s", name))
end

local function money(amount)
	return (DarkRP and DarkRP.formatMoney) and DarkRP.formatMoney(amount) or ("$" .. amount)
end

local function close()
	if IsValid(frame) then frame:Remove() end
	frame = nil
end

local function lighting(panel)
	panel:SetAmbientLight(Color(150, 150, 150))
	panel:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
	panel:SetDirectionalLight(BOX_FRONT, Color(200, 200, 200))
end

local function clearPreviews()
	for _, slot in ipairs(cfg.slots) do DubzCosmetics.ClearAttachment("store_preview_" .. slot.id) end
end

-- The big preview: a player model, drag with the mouse to turn it. closeUp (via :Frame) zooms in on the head.
local function bigPreview(parent)
	local panel = vgui.Create("DModelPanel", parent)
	lighting(panel)
	panel:SetFOV(30)
	panel.Yaw = 25

	function panel:Frame(closeUp)
		if closeUp then
			self:SetCamPos(Vector(55, 0, 66)) self:SetLookAt(Vector(0, 0, 64)) self:SetFOV(26)
		else
			self:SetCamPos(Vector(115, 0, 40)) self:SetLookAt(Vector(0, 0, 36)) self:SetFOV(30)
		end
	end

	panel:Frame(false)

	panel.LayoutEntity = function(self, ent)
		if self.Dragging then
			local x = gui.MouseX()
			self.Yaw = self.Yaw + (x - self.LastX) * 0.6
			self.LastX = x
		end

		ent:SetAngles(Angle(0, self.Yaw, 0))

		if not self.SeqSet then
			self.SeqSet = true
			local seq = ent:LookupSequence("idle_all_01")
			ent:SetSequence(seq > 0 and seq or 0)
		end
	end

	panel.OnMousePressed = function(self, code)
		if code ~= MOUSE_LEFT then return end
		self.Dragging, self.LastX = true, gui.MouseX()
		self:MouseCapture(true)
	end

	panel.OnMouseReleased = function(self)
		self.Dragging = false
		self:MouseCapture(false)
	end

	local basePaint = panel.Paint
	panel.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, DFW.UI.GetTheme().slot)
		basePaint(self, w, h)
	end

	return panel
end

-- A tile with a small model preview, a name and an optional second line (text or a function returning text).
-- `setup(modelPanel)` frames the camera. The returned panel has .View (the model panel) and .Selected.
local TILE_W, TILE_H = 118, 142

local function tile(parent, name, subText, model, setup, onClick, badge, onHover)
	local holder = vgui.Create("Panel", parent)
	holder:SetSize(TILE_W, TILE_H)

	local view = vgui.Create("DModelPanel", holder)
	view:SetPos(0, 0)
	view:SetSize(TILE_W, TILE_H - 24)
	view:SetModel(model)
	lighting(view)
	view.LayoutEntity = function() end
	if setup then setup(view) end
	holder.View = view

	-- A clear button on top handles clicks and the highlight
	local button = vgui.Create("DButton", holder)
	button:SetSize(TILE_W, TILE_H)
	button:SetText("")
	button.DoClick = onClick
	button.OnCursorEntered = function() if onHover then onHover() end end
	button.Paint = function(self, w, h)
		local theme = DFW.UI.GetTheme()

		if holder.Selected then
			surface.SetDrawColor(theme.accent)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
		elseif self:IsHovered() then
			surface.SetDrawColor(theme.border)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		DFW.Draw.Text(name, "Small", w / 2, h - 18, theme.text, TEXT_ALIGN_CENTER)

		if badge and TIER_LABELS[badge] then
			draw.RoundedBox(3, 4, 4, 62, 14, ColorAlpha(TIER_COLORS[badge], 230))
			DFW.Draw.Text(TIER_LABELS[badge], "Tiny", 35, 11, Color(20, 20, 20), TEXT_ALIGN_CENTER)
		end

		local sub = isfunction(subText) and subText() or subText
		if sub and sub ~= "" then DFW.Draw.Text(sub, "Tiny", w / 2, h - 7, theme.accent, TEXT_ALIGN_CENTER) end
	end

	holder.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, DFW.UI.GetTheme().slot)
	end

	return holder
end

local function tileGrid(scroll)
	local layout = vgui.Create("DIconLayout", scroll)
	layout:Dock(TOP)
	layout:SetSpaceX(6)
	layout:SetSpaceY(6)
	layout:DockMargin(0, 0, 4, 4)
	return layout
end

local function actionButton(parent)
	local button = vgui.Create("DFW.Button", parent)
	button:Dock(BOTTOM)
	button:SetTall(38)
	button:DockMargin(0, 6, 0, 0)
	button:SetVariant("primary")
	return button
end

local function send(npc, kind, id, id2)
	net.Start("DubzCos_Buy")
		net.WriteEntity(npc)
		net.WriteString(kind)
		net.WriteString(id)
		net.WriteString(id2 or "")
	net.SendToServer()
end

-- Accessories ---------------------------------------------------------------------------------------------------

local function openAccessories(npc)
	frame = DFW.UI.CreateFrame("Accessories", 1060, 700, nil, {compact = true, module = "cosmetics"})
	frame.OnRemove = clearPreviews

	local content = frame:GetContent()
	local selected

	-- Left: big view of your character and the buy button
	local left = vgui.Create("Panel", content)
	left:Dock(LEFT)
	left:SetWide(430)
	left:DockMargin(4, 4, 8, 4)

	local credits = actionButton(left)
	credits:SetLabel("")
	credits:SetVisible(false)
	credits.DoClick = function() if selected then send(npc, "accessories", selected, "credits") end end

	local buy = actionButton(left)
	buy:SetLabel("Pick something to try on")
	buy:SetEnabled(false)
	buy.DoClick = function() if selected then send(npc, "accessories", selected, "cash") end end

	local info = vgui.Create("DFW.Label", left)
	info:Dock(BOTTOM)
	info:SetTall(26)
	info:SetStyle("bodybold")
	info:SetAlign(TEXT_ALIGN_CENTER)

	-- The clerk's remark about whatever you are hovering
	local quipLabel = vgui.Create("DFW.Label", left)
	quipLabel:Dock(BOTTOM)
	quipLabel:SetTall(30)
	quipLabel:SetStyle("body")
	quipLabel:SetAlign(TEXT_ALIGN_CENTER)
	quipLabel:SetText("")

	local preview = bigPreview(left)
	preview:Dock(FILL)
	preview:SetModel(LocalPlayer():GetModel())

	-- The preview is your character: everything you wear now, with the selected item tried on in its slot
	preview.PostDrawModel = function(self, ent)
		local model = LocalPlayer():GetModel()
		local trying = selected and DubzCosmetics.Get(selected)

		for _, slot in ipairs(cfg.slots) do
			local def = (trying and trying.slot == slot.id) and trying or DubzCosmetics.Get(DubzCosmetics.GetWorn(LocalPlayer(), slot.id))

			if def then
				local pos, ang, scale = DubzCosmetics.GetPlacement(def, model)
				DubzCosmetics.DrawAttachment(ent, def, pos, ang, scale, "store_preview_" .. slot.id, LocalPlayer())
			else
				DubzCosmetics.ClearAttachment("store_preview_" .. slot.id)
			end
		end
	end

	-- Right: for sale, then what you're wearing
	local right = vgui.Create("Panel", content)
	right:Dock(FILL)
	right:DockMargin(0, 4, 4, 4)

	local worn = DubzCosmetics.WornList(right)
	worn:Dock(BOTTOM)

	local wornHeader = vgui.Create("DFW.SectionHeader", right)
	wornHeader:Dock(BOTTOM)
	wornHeader:SetText("You're wearing")

	local saleHeader = vgui.Create("DFW.SectionHeader", right)
	saleHeader:Dock(TOP)
	saleHeader:SetText("For sale")

	local scroll = vgui.Create("DFW.ScrollPanel", right)
	scroll:Dock(FILL)

	local grid = tileGrid(scroll)

	-- What is for sale: the backpack (sold by the clerk, drawn by the inventory) and every item switched on
	local function offer(def)
		if def.id == "backpack" then return {id = "backpack", tier = "common", price = cfg.backpackPrice, credits = cfg.backpackCredits, supply = 0} end
		if def.id == "backpack_small" then return {id = "backpack_small", tier = "common", price = cfg.backpackSmallPrice, credits = cfg.backpackSmallCredits, supply = 0} end

		local econ = table.Copy(DubzCosmetics.GetEcon(def.id))
		econ.id = def.id
		return econ
	end

	local items = {}
	for id, def in pairs(DubzCosmetics.Items) do
		if (id == "backpack" and (cfg.backpackPrice > 0 or cfg.backpackCredits > 0)) or (id == "backpack_small" and (cfg.backpackSmallPrice > 0 or cfg.backpackSmallCredits > 0)) or DubzCosmetics.IsForSale(id) then items[#items + 1] = def end
	end

	-- Everyday stock first, then seasonal and limited editions
	local tierOrder = {common = 1, seasonal = 2, limited = 3}
	table.sort(items, function(a, b)
		local ta, tb = tierOrder[offer(a).tier] or 1, tierOrder[offer(b).tier] or 1
		if ta ~= tb then return ta < tb end
		if a.slot ~= b.slot then return a.slot < b.slot end
		return a.name < b.name
	end)

	local tiles = {}

	local function priceLine(econ)
		local parts = {}
		if econ.price > 0 then parts[#parts + 1] = money(econ.price) end
		if econ.credits > 0 then parts[#parts + 1] = econ.credits .. " cr" end
		local line = table.concat(parts, " / ")

		if cfg.revealSupply and econ.supply > 0 then
			line = line .. " (" .. math.max(0, econ.supply - (DubzCosmetics.Minted[econ.id] or 0)) .. " left)"
		end

		return line
	end

	local function choose(def)
		selected = def.id
		for id, t in pairs(tiles) do t.Selected = id == def.id end

		local econ = offer(def)

		buy:SetLabel("Buy  -  " .. money(econ.price))
		buy:SetEnabled(econ.price > 0)
		buy:SetVisible(econ.price > 0)

		credits:SetLabel("Buy with credits  -  " .. econ.credits)
		credits:SetVisible(econ.credits > 0)

		info:SetText(def.name .. "  (" .. DubzCosmetics.SlotName(def.slot) .. ")")
		left:InvalidateLayout(true)

		-- Hats, face and neck pieces are easier to judge up close
		preview:Frame(def.slot ~= "back")
	end

	for _, def in ipairs(items) do
		local econ = offer(def)

		local t = tile(grid, def.name, priceLine(econ), def.model, function(view)
			local entity = view.Entity
			if not IsValid(entity) then return end

			local mins, maxs = entity:GetRenderBounds()
			local size = math.max(maxs.x - mins.x, maxs.y - mins.y, maxs.z - mins.z, 1)
			view:SetCamPos(Vector(size * 1.1, size * 0.9, size * 0.6))
			view:SetLookAt((mins + maxs) / 2)
			view:SetFOV(40)
		end, function() choose(def) end, econ.tier, function() quipLabel:SetText(quipFor(def.name)) end)

		grid:Add(t)
		tiles[def.id] = t
	end

	if #items == 0 then info:SetText("Nothing is for sale yet.") end
end

-- Clothing ----------------------------------------------------------------------------------------------------------

local function openClothing(npc)
	frame = DFW.UI.CreateFrame("Clothing", 1180, 760, nil, {compact = true, module = "cosmetics"})

	local content = frame:GetContent()
	local lp = LocalPlayer()

	local pickedFace = DubzCosmetics.GetLookId(lp)
	if pickedFace == "" then pickedFace = "male_01" end
	local pickedClothing = DubzCosmetics.GetClothingId(lp)
	local gender = (DubzCosmetics.GetFace(pickedFace) or {}).gender or "Male"

	-- Left: preview, summary, action
	local left = vgui.Create("Panel", content)
	left:Dock(LEFT)
	left:SetWide(420)
	left:DockMargin(4, 4, 8, 4)

	local action = actionButton(left)

	local info = vgui.Create("DFW.Label", left)
	info:Dock(BOTTOM)
	info:SetTall(26)
	info:SetStyle("bodybold")
	info:SetAlign(TEXT_ALIGN_CENTER)

	local preview = bigPreview(left)
	preview:Dock(FILL)

	-- Right: tabs, looks (~30%), clothing (the rest)
	local right = vgui.Create("Panel", content)
	right:Dock(FILL)
	right:DockMargin(0, 4, 4, 4)

	local tabs = vgui.Create("DFW.TabBar", right)
	tabs:Dock(TOP)
	tabs:SetTall(34)

	local looksHolder = vgui.Create("Panel", right)
	looksHolder:Dock(TOP)

	local looksHeader = vgui.Create("DFW.SectionHeader", looksHolder)
	looksHeader:Dock(TOP)
	looksHeader:SetText("Look")

	local looksScroll = vgui.Create("DFW.ScrollPanel", looksHolder)
	looksScroll:Dock(FILL)

	local clothingHeader = vgui.Create("DFW.SectionHeader", right)
	clothingHeader:Dock(TOP)
	clothingHeader:DockMargin(0, 6, 0, 0)
	clothingHeader:SetText("Clothing")

	local clothingScroll = vgui.Create("DFW.ScrollPanel", right)
	clothingScroll:Dock(FILL)

	right.PerformLayout = function(self, w, h)
		looksHolder:SetTall(math.floor((h - 34 - 32) * 0.3))
	end

	local faceTiles, clothingTiles = {}, {}
	local rebuildFaces, refresh

	-- Price of what is picked, or nil when it is exactly what you wear now
	local function costOfChange()
		local newLook = DubzCosmetics.GetLookId(lp) ~= pickedFace
		local changesClothes = DubzCosmetics.GetClothingId(lp) ~= pickedClothing
		if not newLook and not changesClothes then return nil end

		local owned = DubzCosmetics.OwnsClothing(lp, pickedClothing)
		return (newLook and cfg.lookPrice or 0) + (owned and 0 or (cfg.clothingPrices[pickedClothing] or 0))
	end

	function refresh()
		local model = DubzCosmetics.ModelFor(pickedFace, pickedClothing)
		local face, clothing = DubzCosmetics.GetFace(pickedFace), DubzCosmetics.GetClothing(pickedClothing)

		if model and preview:GetModel() ~= model then
			preview:SetModel(model)
			preview.SeqSet = false
		end

		info:SetText((face and face.name or "") .. "  -  " .. (clothing and clothing.name or ""))

		local cost = costOfChange()
		if not model then
			action:SetLabel("Not available")
			action:SetEnabled(false)
		elseif cost == nil then
			action:SetLabel("You're wearing this")
			action:SetEnabled(false)
		else
			action:SetLabel(cost > 0 and ("Buy and wear  -  " .. money(cost)) or "Wear")
			action:SetEnabled(true)
		end

		for id, t in pairs(faceTiles) do t.Selected = id == pickedFace end

		for id, t in pairs(clothingTiles) do
			t.Selected = id == pickedClothing

			-- The clothing previews show the picked look wearing each set
			local previewModel = DubzCosmetics.ModelFor(pickedFace, id)
			if previewModel and t.View:GetModel() ~= previewModel then t.View:SetModel(previewModel) end
		end
	end

	action.DoClick = function() send(npc, "clothing", pickedFace, pickedClothing) end

	-- Faces for the chosen gender
	function rebuildFaces()
		looksScroll:Clear()
		faceTiles = {}

		local grid = tileGrid(looksScroll)

		for _, id in ipairs(DubzCosmetics.FaceOrder) do
			local face = DubzCosmetics.Faces[id]
			local model = face.gender == gender and (DubzCosmetics.ModelFor(id, pickedClothing) or DubzCosmetics.ModelFor(id, DubzCosmetics.DefaultClothing))

			if model then
				local t = tile(grid, face.name, function()
					return DubzCosmetics.GetLookId(lp) == id and "wearing" or ""
				end, model, function(view)
					view:SetCamPos(Vector(32, 0, 66))
					view:SetLookAt(Vector(0, 0, 65))
					view:SetFOV(30)

					view.LayoutEntity = function(self, ent)
						ent:SetAngles(Angle(0, 0, 0))
						local seq = ent:LookupSequence("idle_all_01")
						ent:SetSequence(seq > 0 and seq or 0)
					end
				end, function()
					pickedFace = id
					refresh()
				end)

				grid:Add(t)
				faceTiles[id] = t
			end
		end

		refresh()
	end

	tabs.OnTabChanged = function(_, id)
		gender = id

		-- Jump to the first look of that gender if the picked one isn't of it
		local face = DubzCosmetics.GetFace(pickedFace)
		if not face or face.gender ~= gender then
			for _, faceId in ipairs(DubzCosmetics.FaceOrder) do
				if DubzCosmetics.Faces[faceId].gender == gender then pickedFace = faceId break end
			end
		end

		rebuildFaces()
	end

	tabs:AddTab("Male", "Male")
	tabs:AddTab("Female", "Female")
	tabs:SetActive(gender, true)

	-- Clothing sets: each shown on the picked look, with its price, "owned" or "wearing"
	local clothingGrid = tileGrid(clothingScroll)

	for _, id in ipairs(DubzCosmetics.ClothingOrder) do
		local set = DubzCosmetics.Clothing[id]
		local model = DubzCosmetics.ModelFor(pickedFace, id)

		if model then
			local t = tile(clothingGrid, set.name, function()
				if DubzCosmetics.GetClothingId(lp) == id then return "wearing" end
				if DubzCosmetics.OwnsClothing(lp, id) then return "owned" end
				return money(cfg.clothingPrices[id] or 0)
			end, model, function(view)
				-- Upper body, so the clothes are what you notice
				view:SetCamPos(Vector(70, 0, 46))
				view:SetLookAt(Vector(0, 0, 44))
				view:SetFOV(40)

				view.LayoutEntity = function(self, ent)
					ent:SetAngles(Angle(0, 0, 0))
					local seq = ent:LookupSequence("idle_all_01")
					ent:SetSequence(seq > 0 and seq or 0)
				end
			end, function()
				pickedClothing = id
				refresh()
			end)

			clothingGrid:Add(t)
			clothingTiles[id] = t
		end
	end

	rebuildFaces()

	-- Keep the button right after buying (the server changes the NW values)
	local frameThink = frame.Think
	frame.Think = function(self)
		frameThink(self)

		local key = lp:GetNWString("dubz_outfit", "") .. "|" .. lp:GetNWString("dubz_clothes", "") .. "|" .. lp:GetNWString("dubz_clothes_owned", "")
		if self.LastKey ~= key then
			self.LastKey = key
			refresh()
		end
	end
end

net.Receive("DubzCos_OpenStore", function()
	local npc = net.ReadEntity()
	local kind = net.ReadString()
	DubzCosmetics.Minted = util.JSONToTable(net.ReadString()) or {}

	if not IsValid(npc) then return end

	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then
		chat.AddText(Color(255, 80, 80), "[Cosmetics] ", color_white, "The Dubz Framework addon isn't installed, so the store can't open.")
		return
	end

	close()

	if kind == "accessories" then openAccessories(npc) else openClothing(npc) end

	-- Walking away closes the store
	if IsValid(frame) then
		local baseThink = frame.Think
		frame.Think = function(self)
			baseThink(self)
			if not IsValid(npc) or LocalPlayer():GetPos():Distance(npc:GetPos()) > cfg.npcUseDistance * 2 then self:Close() end
		end
	end
end)
