-- Placement editor (admins): pick an item (an accessory, or the worn Backpack), nudge its position / rotation /
-- scale with sliders while you watch it on your own player model (the camera swings to third person), then save
-- it for that model. Saved offsets apply to everyone wearing that item on that player model.
-- Open with the dubz_cosmetic_editor console command. Built from Dubz Framework controls.
local frame
local catcher

-- Camera: hold right mouse and drag to orbit around you, mouse wheel to zoom (like a model viewer)
local cam = {yaw = 0, pitch = 10, dist = 90, height = 40}

hook.Add("ShouldDrawLocalPlayer", "DubzCos_Editor", function()
	if IsValid(frame) then return true end
end)

hook.Add("CalcView", "DubzCos_Editor", function(ply, origin, angles, fov)
	if not IsValid(frame) then return end

	local center = ply:GetPos() + Vector(0, 0, cam.height)
	local pos = center + Angle(cam.pitch, ply:EyeAngles().y + cam.yaw, 0):Forward() * cam.dist

	return {origin = pos, angles = (center - pos):Angle(), fov = fov, drawviewer = true}
end)

-- A transparent panel behind the editor window that listens for the orbit controls
local function makeCatcher()
	if IsValid(catcher) then catcher:Remove() end

	catcher = vgui.Create("EditablePanel")
	catcher:SetSize(ScrW(), ScrH())
	catcher:SetPos(0, 0)
	catcher:SetKeyboardInputEnabled(false)
	catcher:MakePopup()
	catcher:SetPopupStayAtBack(true)   -- the editor window must always stay above it
	catcher.Paint = function() end

	catcher.OnMousePressed = function(self, code)
		if IsValid(frame) then frame:MoveToFront() end
		if code ~= MOUSE_RIGHT then return end
		self.Dragging, self.LastX, self.LastY = true, gui.MouseX(), gui.MouseY()
		self:MouseCapture(true)
	end

	catcher.OnMouseReleased = function(self)
		self.Dragging = false
		self:MouseCapture(false)
	end

	catcher.Think = function(self)
		if not self.Dragging then return end
		if not input.IsMouseDown(MOUSE_RIGHT) then self.Dragging = false self:MouseCapture(false) return end

		local x, y = gui.MouseX(), gui.MouseY()
		cam.yaw = cam.yaw - (x - self.LastX) * 0.4
		cam.pitch = math.Clamp(cam.pitch + (y - self.LastY) * 0.3, -60, 75)
		self.LastX, self.LastY = x, y
	end

	catcher.OnMouseWheeled = function(_, delta)
		cam.dist = math.Clamp(cam.dist - delta * 8, 25, 220)
	end
end

-- A caption over a framework slider
local function slider(parent, label, min, max, value, decimals, onChange)
	local caption = vgui.Create("DFW.Label", parent)
	caption:Dock(TOP)
	caption:SetTall(18)
	caption:DockMargin(2, 4, 2, 0)
	caption:SetStyle("small")
	caption:SetText(label)

	local s = vgui.Create("DFW.Slider", parent)
	s:Dock(TOP)
	s:SetTall(22)
	s:DockMargin(2, 0, 2, 0)
	s:SetRange(min, max)
	s:SetDecimals(decimals or 2)
	s:SetValue(value, true)
	s.OnValueChanged = function(_, v) onChange(v) end
	return s
end

local function open()
	if not LocalPlayer():IsAdmin() then return end
	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then return end
	if IsValid(frame) then frame:Remove() end

	makeCatcher()

	frame = DFW.UI.CreateFrame("Accessory placement", 360, 610, nil, {compact = true, module = "cosmetics"})
	frame:SetPos(20, ScrH() / 2 - 305)
	frame:MoveToFront()

	frame.OnRemove = function()
		DubzCosmetics.Preview = nil
		if IsValid(catcher) then catcher:Remove() end
	end

	local content = frame:GetContent()

	local state = {id = nil, pos = Vector(), ang = Angle(), scale = 1}
	local controls = {}

	local function apply()
		local def = DubzCosmetics.Get(state.id)
		if not def then DubzCosmetics.Preview = nil return end

		DubzCosmetics.Preview = {slot = def.slot, id = def.id, pos = Vector(state.pos), ang = Angle(state.ang.p, state.ang.y, state.ang.r), scale = state.scale}
	end

	local function showAngles()
		controls.ap:SetValue(state.ang.p, true) controls.ay:SetValue(state.ang.y, true) controls.ar:SetValue(state.ang.r, true)
	end

	local combo = vgui.Create("DFW.Dropdown", content)
	combo:Dock(TOP)
	combo:SetTall(28)
	combo:DockMargin(4, 4, 4, 4)
	combo:SetPlaceholder("Choose an item")

	local ids = table.GetKeys(DubzCosmetics.Items)
	table.sort(ids)
	for _, id in ipairs(ids) do combo:AddChoice(DubzCosmetics.Items[id].name .. " (" .. id .. ")", id) end

	local cameraHint = vgui.Create("DFW.Label", content)
	cameraHint:Dock(TOP)
	cameraHint:SetTall(18)
	cameraHint:DockMargin(2, 0, 2, 0)
	cameraHint:SetStyle("tiny")
	cameraHint:SetText("Hold right mouse and drag to orbit, mouse wheel to zoom. Click a number to type it.")

	local REACH = 150

	local function setValues()
		local def = DubzCosmetics.Get(state.id)
		if not def then return end

		local pos, ang, scale = DubzCosmetics.GetPlacement(def, LocalPlayer():GetModel())
		state.pos, state.ang, state.scale = Vector(pos), Angle(ang.p, ang.y, ang.r), scale

		for key, value in pairs({px = pos.x, py = pos.y, pz = pos.z}) do
			local reach = math.max(REACH, math.ceil(math.abs(value)) + 50)
			controls[key]:SetRange(-reach, reach)
			controls[key]:SetValue(value, true)
		end
		showAngles()
		controls.scale:SetValue(scale, true)
		apply()
	end

	-- Position sliders reach far (items from other packs can start a long way off); they widen on their own when a
	-- value is outside the range, and you can type any number into them
	controls.px = slider(content, "Position X (forward)", -REACH, REACH, 0, 2, function(v) state.pos.x = v apply() end)
	controls.py = slider(content, "Position Y (right)", -REACH, REACH, 0, 2, function(v) state.pos.y = v apply() end)
	controls.pz = slider(content, "Position Z (up)", -REACH, REACH, 0, 2, function(v) state.pos.z = v apply() end)
	controls.ap = slider(content, "Rotate pitch", -180, 180, 0, 0, function(v) state.ang.p = v apply() end)
	controls.ay = slider(content, "Rotate yaw", -180, 180, 0, 0, function(v) state.ang.y = v apply() end)
	controls.ar = slider(content, "Rotate roll", -180, 180, 0, 0, function(v) state.ang.r = v apply() end)
	controls.scale = slider(content, "Scale", 0.1, 3, 1, 2, function(v) state.scale = v apply() end)

	combo.OnSelect = function(_, _, _, id)
		state.id = id
		setValues()
	end

	-- Quick starting points for an item that spawns far away
	local function place(pos, ang)
		state.pos, state.ang = pos, ang

		for key, value in pairs({px = pos.x, py = pos.y, pz = pos.z}) do
			local reach = math.max(REACH, math.ceil(math.abs(value)) + 50)
			controls[key]:SetRange(-reach, reach)
			controls[key]:SetValue(value, true)
		end

		showAngles()
		apply()
	end

	local quick = vgui.Create("Panel", content)
	quick:Dock(TOP)
	quick:SetTall(36)
	quick:DockMargin(2, 8, 2, 0)

	local onBone = vgui.Create("DFW.Button", quick)
	onBone:Dock(LEFT)
	onBone:SetWide(168)
	onBone:DockMargin(0, 2, 4, 2)
	onBone:SetLabel("Put on its bone")
	onBone:SetTooltip("Zero position and rotation: the item sits exactly on the body part its slot attaches to.")
	onBone.DoClick = function()
		if state.id then place(Vector(0, 0, 0), Angle(0, 0, 0)) end
	end

	local onMe = vgui.Create("DFW.Button", quick)
	onMe:Dock(FILL)
	onMe:DockMargin(0, 2, 0, 2)
	onMe:SetLabel("Put at my center")
	onMe:SetTooltip("Moves the item to the middle of your player (centre of mass), then fine tune from there.")
	onMe.DoClick = function()
		local def = DubzCosmetics.Get(state.id)
		if not def then return end

		local ply = LocalPlayer()
		local bone = ply:LookupBone(def.bone)
		if not bone then return end

		local bonePos, boneAng = ply:GetBonePosition(bone)
		local center = ply:GetPos() + ply:OBBCenter()
		local localPos = WorldToLocal(center, Angle(0, 0, 0), bonePos, boneAng)

		place(Vector(localPos.x, localPos.y, localPos.z), Angle(0, 0, 0))
	end

	local info = vgui.Create("DFW.Paragraph", content)
	info:Dock(TOP)
	info:DockMargin(4, 10, 4, 0)
	info:SetStyle("small")
	info:SetText("This model: " .. LocalPlayer():GetModel() .. "\nA placement saved for this model wins; \"Save for ALL models\" is the fallback for every other model.")

	local buttons = vgui.Create("Panel", content)
	buttons:Dock(BOTTOM)
	buttons:SetTall(78)
	buttons:DockMargin(0, 0, 0, 2)

	-- "*" is the saved-for-every-model slot (a model-specific placement still wins over it)
	local function saveFor(model)
		if not state.id then return end

		net.Start("DubzCos_SaveOffset")
			net.WriteString(state.id)
			net.WriteString(model)
			net.WriteFloat(state.pos.x) net.WriteFloat(state.pos.y) net.WriteFloat(state.pos.z)
			net.WriteFloat(state.ang.p) net.WriteFloat(state.ang.y) net.WriteFloat(state.ang.r)
			net.WriteFloat(state.scale)
		net.SendToServer()
	end

	local function resetFor(model)
		if not state.id then return end

		net.Start("DubzCos_ResetOffset")
			net.WriteString(state.id)
			net.WriteString(model)
		net.SendToServer()

		timer.Simple(0.3, function() if IsValid(frame) then setValues() end end)
	end

	local function pairRow(dock, left, right)
		local row = vgui.Create("Panel", buttons)
		row:Dock(dock)
		row:SetTall(36)

		local function make(label, variant, onClick, side)
			local button = vgui.Create("DFW.Button", row)
			button:Dock(side)
			button:SetWide(170)
			button:DockMargin(side == LEFT and 2 or 0, 4, side == LEFT and 4 or 2, 4)
			button:SetLabel(label)
			button:SetVariant(variant)
			button.DoClick = onClick
			return button
		end

		make(left[1], left[2], left[3], LEFT)
		local fill = make(right[1], right[2], right[3], FILL)
		fill:SetWide(10)
	end

	pairRow(TOP, {"Save for this model", "primary", function() saveFor(LocalPlayer():GetModel()) end},
		{"Save for ALL models", "default", function() saveFor("*") end})

	pairRow(TOP, {"Reset this model", "default", function() resetFor(LocalPlayer():GetModel()) end},
		{"Clear all-models default", "danger", function() resetFor("*") end})
end

concommand.Add("dubz_cosmetic_editor", open)

-- The third person camera steps aside while this editor has its own camera
hook.Add("DubzThirdPersonBlocked", "DubzCos_Editor", function()
	if IsValid(frame) then return true end
end)
