-- Gestures, client side: the animation everyone sees, and the menu you hold G for. The menu is a framework window like the skills sheet: a
-- preview of your own model on the left (drag it to turn it; it plays whichever gesture the mouse is over) and the list on the right.
local cfg = DubzGestures.Config

-- Playing -----------------------------------------------------------------------------------------------------------------------------------

local function actOf(gesture)
	return gesture and _G[gesture.act]
end

net.Receive("DubzGest_Play", function()
	local ply, gesture = net.ReadEntity(), DubzGestures.List[net.ReadUInt(8)]
	local act = actOf(gesture)

	if IsValid(ply) and act then ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, act, true) end
end)

local function play(gesture)
	net.Start("DubzGest_Play")
		net.WriteUInt(gesture.index, 8)
	net.SendToServer()
end

-- The menu ----------------------------------------------------------------------------------------------------------------------------------

local menu

local function theme() return DFW.UI.GetTheme() end

local function visible()
	local list = {}

	for _, gesture in ipairs(DubzGestures.List) do
		if not DubzGestures.IsDisabled(gesture.id) and actOf(gesture) then list[#list + 1] = gesture end
	end

	return list
end

local function closeMenu()
	if IsValid(menu) then menu:Remove() end
	menu = nil
end

-- The preview: your own model (with your skin and bodygroups) plays the gesture over and over. Drag it sideways to turn it.
local function makePreview(parent)
	local view = vgui.Create("DModelPanel", parent)
	local lp = LocalPlayer()

	view:SetModel(lp:GetModel())
	view:SetFOV(30)
	view:SetCamPos(Vector(125, 0, 38))
	view:SetLookAt(Vector(0, 0, 36))
	view:SetAmbientLight(Color(150, 150, 150))
	view:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
	view:SetDirectionalLight(BOX_FRONT, Color(200, 200, 200))
	view:SetCursor("sizewe")

	local ent = view:GetEntity()

	if IsValid(ent) then
		ent:SetSkin(lp:GetSkin())

		for index = 0, lp:GetNumBodyGroups() - 1 do ent:SetBodygroup(index, lp:GetBodygroup(index)) end
	end

	view.Yaw = 0
	view.Gesture = nil
	view.Restart = true
	view.EndsAt = 0

	view.OnMousePressed = function(self, code)
		if code ~= MOUSE_LEFT then return end

		self.Dragging, self.LastX = true, gui.MouseX()
		self:MouseCapture(true)
	end

	view.OnMouseReleased = function(self)
		self.Dragging = false
		self:MouseCapture(false)
	end

	view.LayoutEntity = function(self, entity)
		if self.Dragging then
			local x = gui.MouseX()
			self.Yaw = self.Yaw + (x - self.LastX) * 0.7
			self.LastX = x
		end

		entity:SetAngles(Angle(0, self.Yaw, 0))

		local gesture = self.Gesture
		local sequence = -1

		if gesture then
			local act = actOf(gesture)
			if act then sequence = entity:SelectWeightedSequence(act) end
			if sequence <= 0 and gesture.seq then sequence = entity:LookupSequence(gesture.seq) end
		end

		if sequence > 0 then
			-- (starts over when the mouse moves to another gesture, and again each time one finishes)
			if self.Restart or CurTime() > self.EndsAt then
				self.Restart = false
				entity:ResetSequence(sequence)
				entity:SetCycle(0)

				local length = entity:SequenceDuration(sequence)
				self.EndsAt = CurTime() + (length > 0 and length or 3) + 0.7
			end
		elseif self.IdleSet ~= entity then
			self.IdleSet = entity

			local idle = entity:LookupSequence("idle_all_01")
			entity:SetSequence(idle > 0 and idle or 0)
		end

		self:RunAnimation()
	end

	function view:SetGesture(gesture)
		if self.Gesture == gesture then return end

		self.Gesture, self.Restart, self.IdleSet = gesture, true, nil
	end

	return view
end

local function openMenu()
	if IsValid(menu) or not (DFW and DFW.UI and DFW.UI.CreateFrame) then return end

	local all = visible()
	if #all == 0 then return end

	menu = DFW.UI.CreateFrame("Gestures", 900, 560, nil, {compact = true, module = "gestures"})
	menu:SetKeyboardInputEnabled(false)   -- the mouse is yours; the keyboard still walks you around
	menu.CloseOnEscape = false

	-- Let go of the key and it closes
	local baseThink = menu.Think
	menu.Think = function(self)
		baseThink(self)
		if not input.IsKeyDown(cfg.openKey) then closeMenu() end
	end

	local content = menu:GetContent()

	-- Left: the preview card
	local left = vgui.Create("Panel", content)
	left:Dock(LEFT)
	left:SetWide(300)
	left:DockMargin(0, 0, 8, 0)
	left.Paint = function(self, w, h) draw.RoundedBox(8, 0, 0, w, h, theme().surface) end

	local noteLabel = vgui.Create("DLabel", left)
	noteLabel:Dock(BOTTOM)
	noteLabel:SetTall(24)
	noteLabel:SetFont("DermaDefault")
	noteLabel:SetTextColor(theme().textMuted)
	noteLabel:SetContentAlignment(5)

	local nameLabel = vgui.Create("DLabel", left)
	nameLabel:Dock(BOTTOM)
	nameLabel:SetTall(30)
	nameLabel:SetFont("DermaLarge")
	nameLabel:SetTextColor(theme().text)
	nameLabel:SetContentAlignment(5)

	local view = makePreview(left)
	view:Dock(FILL)

	local function preview(gesture)
		view:SetGesture(gesture)
		nameLabel:SetText(gesture and gesture.name or "")
		noteLabel:SetText(gesture and "Plays once. Drag the model to turn it." or "Move over a gesture to preview it")
	end

	-- Right: the tabs and the list
	local right = vgui.Create("Panel", content)
	right:Dock(FILL)

	local tabs = vgui.Create("DFW.TabBar", right)
	tabs:Dock(TOP)
	tabs:SetTall(34)

	for _, name in ipairs(DubzGestures.Tabs) do tabs:AddTab(name, name) end

	local hint = vgui.Create("DLabel", right)
	hint:Dock(BOTTOM)
	hint:SetTall(22)
	hint:SetFont("DermaDefault")
	hint:SetTextColor(theme().textMuted)
	hint:SetText("Click a gesture to do it. Release " .. string.upper(input.GetKeyName(cfg.openKey) or "the key") .. " to close.")

	local scroll = vgui.Create("DFW.ScrollPanel", right)
	scroll:Dock(FILL)
	scroll:DockMargin(0, 8, 0, 6)

	local function fill(tab)
		scroll:Clear()

		local layout = vgui.Create("DIconLayout", scroll)
		layout:Dock(TOP)
		layout:SetSpaceX(6)
		layout:SetSpaceY(6)

		local columns = 3
		local cell = math.floor((900 - 300 - 8 - 24 - 6 * (columns - 1)) / columns)

		for _, gesture in ipairs(all) do
			if tab == "All" or gesture.tab == tab then
				local button = layout:Add("DFW.Button")
				button:SetSize(cell, 46)
				button:SetLabel(gesture.name)

				button.OnCursorEntered = function() preview(gesture) end

				button.DoClick = function()
					play(gesture)
					if cfg.closeOnPlay then closeMenu() end
				end
			end
		end
	end

	tabs.OnTabChanged = function(_, id) fill(id) end
	tabs:SetActive("All", true)
	fill("All")
	preview(all[1])
end

-- Hold the key ------------------------------------------------------------------------------------------------------------------------------

hook.Add("PlayerButtonDown", "DubzGestures_Open", function(ply, button)
	if ply ~= LocalPlayer() or button ~= cfg.openKey or not IsFirstTimePredicted() then return end
	if not DubzGestures.Enabled() or IsValid(menu) then return end

	-- Not while typing, in another menu, or still at the character screen
	if ply:IsTyping() or gui.IsGameUIVisible() or vgui.CursorVisible() or not ply:Alive() then return end
	if (DubzChars and DubzChars.MenuOpen) or ply:GetNWBool("dubz_char_pending", false) then return end

	openMenu()
end)

-- The menu never outlives you: dying closes it
hook.Add("Think", "DubzGestures_Guard", function()
	if IsValid(menu) and not LocalPlayer():Alive() then closeMenu() end
end)
