-- The animation editor (superadmin console command: dubz_work_editor).
-- Pick an animation, slide the time bar, and pose the arms at that moment: every bone, both hands' grip, the arms as a whole, the view and the
-- item. The first edit at a moment adds a keyframe there (copied from what the blend looked like); poses between keyframes blend. "Preview on me"
-- puts the work weapon in your hands so you see your own arms follow the slider. Save sends it to the server for everybody.
local KIND_PATTERN = "^[%w_]+$"

local frame, state, controls

-- Keys -----------------------------------------------------------------------------------------------------------------------

local function sortKeys(keys) table.sort(keys, function(a, b) return a.t < b.t end) end

-- The key at the current moment (or nil when the time bar is between two)
local function keyAt(p)
	for _, key in ipairs(state.data.keys) do
		if math.abs(key.t - p) < 0.012 then return key end
	end
end

-- A key for the current moment, made from what the animation looks like there
local function ensureKey()
	local existing = keyAt(state.p)
	if existing then return existing end

	local pose = {bones = {}, curl = {R = 0, L = 0}, pos = Vector(), ang = Angle(), look = 0}
	DubzActions.EvaluateKeys(state.data, state.p, pose, "first")

	local key = {t = state.p, bones = {}, curl = {R = pose.curl.R, L = pose.curl.L}, pos = {pose.pos.x, pose.pos.y, pose.pos.z}, ang = {pose.ang.p, pose.ang.y, pose.ang.r}, look = pose.look}
	for name, angle in pairs(pose.bones) do key.bones[name] = {angle.p, angle.y, angle.r} end
	if pose.item then key.item = {pose.item.pos.x, pose.item.pos.y, pose.item.pos.z, pose.item.ang.p, pose.item.ang.y, pose.item.ang.r} end

	table.insert(state.data.keys, key)
	sortKeys(state.data.keys)

	return key
end

local function currentPose()
	local pose = {bones = {}, curl = {R = 0, L = 0}, pos = Vector(), ang = Angle(), look = 0}
	DubzActions.EvaluateKeys(state.data, state.p, pose, "first")
	return pose
end

-- The slider values follow the moment on the time bar
local function showValues()
	if not controls then return end

	local pose = currentPose()
	local angle = pose.bones[state.bone] or Angle()

	controls.pitch:SetValue(angle.p, true)
	controls.yaw:SetValue(angle.y, true)
	controls.roll:SetValue(angle.r, true)

	controls.curlR:SetValue(pose.curl.R, true)
	controls.curlL:SetValue(pose.curl.L, true)

	controls.posX:SetValue(pose.pos.x, true) controls.posY:SetValue(pose.pos.y, true) controls.posZ:SetValue(pose.pos.z, true)
	controls.angP:SetValue(pose.ang.p, true) controls.angY:SetValue(pose.ang.y, true) controls.angR:SetValue(pose.ang.r, true)
	controls.look:SetValue(pose.look, true)

	local item = pose.item
	controls.itemX:SetValue(item and item.pos.x or 0, true) controls.itemY:SetValue(item and item.pos.y or 0, true) controls.itemZ:SetValue(item and item.pos.z or 0, true)
	controls.itemP:SetValue(item and item.ang.p or 0, true) controls.itemYaw:SetValue(item and item.ang.y or 0, true) controls.itemR:SetValue(item and item.ang.r or 0, true)

	local times = {}
	for _, key in ipairs(state.data.keys) do times[#times + 1] = string.format("%.2f", key.t) end

	controls.keysLabel:SetText("Keyframes: " .. table.concat(times, "  ") .. (keyAt(state.p) and "   (editing the one here)" or "   (no keyframe here yet: the first change adds one)"))
end

local function publish()
	DubzActions.EditorOverride = {kind = state.kind, data = state.data, p = state.p}
end

-- Building the window ------------------------------------------------------------------------------------------------------------

local function slider(parent, label, min, max, decimals, onChange)
	local caption = vgui.Create("DFW.Label", parent)
	caption:Dock(TOP)
	caption:SetTall(16)
	caption:DockMargin(2, 3, 2, 0)
	caption:SetStyle("tiny")
	caption:SetText(label)

	local s = vgui.Create("DFW.Slider", parent)
	s:Dock(TOP)
	s:SetTall(20)
	s:DockMargin(2, 0, 2, 0)
	s:SetRange(min, max)
	s:SetDecimals(decimals or 1)
	s:SetValue(0, true)
	s.OnValueChanged = function(_, v) onChange(v) end

	return s
end

local function header(parent, text)
	local h = vgui.Create("DFW.SectionHeader", parent)
	h:Dock(TOP)
	h:DockMargin(0, 8, 0, 2)
	h:SetText(text)
end

local function button(parent, label, width, click, variant)
	local b = vgui.Create("DFW.Button", parent)
	b:Dock(LEFT)
	b:SetWide(width)
	b:DockMargin(0, 2, 4, 2)
	if variant then b:SetVariant(variant) end
	b:SetLabel(label)
	b.DoClick = click
	return b
end

local function row(parent, height)
	local r = vgui.Create("Panel", parent)
	r:Dock(TOP)
	r:SetTall(height or 34)
	r:DockMargin(2, 2, 2, 0)
	return r
end

local function edit(setter)
	return function(v)
		if not state then return end

		local key = ensureKey()
		setter(key, v)
		publish()
		showValues()
	end
end

local function kindList()
	local seen, list = {}, {}

	for _, name in ipairs(DubzActions.BuiltIn) do seen[name] = true list[#list + 1] = name end
	for name in pairs(DubzActions.Saved) do if not seen[name] then seen[name] = true list[#list + 1] = name end end

	return list
end

local function loadKind(kind)
	state = state or {}
	state.kind = kind
	state.data = DubzActions.Working(kind)
	state.p = 0
	state.playing = false
	state.bone = state.bone or "R_Forearm"

	publish()

	if controls and controls.time then
		controls.time:SetValue(0, true)
		controls.length:SetValue(state.data.length or 3, true)
		controls.hasItem:SetChecked(state.data.item == true, true)
		showValues()
	end
end

local function open()
	if not (LocalPlayer():IsSuperAdmin() and DFW and DFW.UI and DFW.UI.CreateFrame) then return end
	if not (DubzActions.Animations and DubzActions.Animations.scrap) then
		chat.AddText(Color(255, 80, 80), "[Actions] ", color_white, "The work weapon has not loaded yet: get it once with dubz_work_preview scrap, then open the editor.")
		return
	end

	if IsValid(frame) then frame:Remove() end

	state, controls = nil, {}

	frame = DFW.UI.CreateFrame("Animation editor", 400, 840, nil, {compact = true, module = "actions"})
	frame:SetPos(20, ScrH() / 2 - 420)
	frame:MoveToFront()
	frame:SetSubtitle("Pick an animation, slide the time bar, pose the arms. Save to keep it.")

	frame.OnRemove = function()
		DubzActions.EditorOverride = nil
		RunConsoleCommand("dubz_work_stop")
	end

	local content = frame:GetContent()
	local scroll = vgui.Create("DFW.ScrollPanel", content)
	scroll:Dock(FILL)

	loadKind("scrap")

	-- Which animation
	header(scroll, "Animation")

	local pick = vgui.Create("DFW.Dropdown", scroll)
	pick:Dock(TOP)
	pick:SetTall(28)
	pick:DockMargin(2, 2, 2, 2)
	for _, kind in ipairs(kindList()) do pick:AddChoice(kind, kind, kind == state.kind) end
	pick.OnSelect = function(_, _, _, kind) loadKind(kind) RunConsoleCommand("dubz_work_preview", kind, "600", "metal") end
	controls.pick = pick

	local newRow = row(scroll)
	local name = vgui.Create("DFW.TextEntry", newRow)
	name:Dock(FILL)
	name:SetPlaceholder("name for a new animation (letters, numbers, _)")
	button(newRow, "New from this", 130, function()
		local text = string.lower(string.Trim(name:GetValue() or ""))
		if not string.match(text, KIND_PATTERN) then DFW.UI.Notify("Use letters, numbers and _ only.", "danger", 3) return end

		local copy = table.Copy(state.data)
		state.kind = text
		state.data = copy
		DubzActions.Saved[text] = table.Copy(copy)
		publish()

		pick:AddChoice(text, text, true)
	end):Dock(RIGHT)

	-- Time
	header(scroll, "Time")

	controls.time = slider(scroll, "Moment in the animation (0 = start, 1 = end)", 0, 1, 3, function(v)
		state.p = v
		publish()
		showValues()
	end)

	controls.length = slider(scroll, "How long it plays here (seconds)", 0.3, 10, 1, function(v) state.data.length = v end)

	local playRow = row(scroll)
	button(playRow, "Play / pause", 110, function() state.playing = not state.playing end, "primary")
	button(playRow, "Prev key", 84, function()
		for index = #state.data.keys, 1, -1 do
			if state.data.keys[index].t < state.p - 0.012 then state.p = state.data.keys[index].t break end
		end

		controls.time:SetValue(state.p, true)
		publish()
		showValues()
	end)
	button(playRow, "Next key", 84, function()
		for _, key in ipairs(state.data.keys) do
			if key.t > state.p + 0.012 then state.p = key.t break end
		end

		controls.time:SetValue(state.p, true)
		publish()
		showValues()
	end)

	local keyRow = row(scroll)
	button(keyRow, "Add keyframe here", 150, function() ensureKey() publish() showValues() end)
	button(keyRow, "Delete this keyframe", 160, function()
		local key = keyAt(state.p)

		if key and #state.data.keys > 2 then
			table.RemoveByValue(state.data.keys, key)
			publish()
			showValues()
		end
	end)

	controls.keysLabel = vgui.Create("DFW.Label", scroll)
	controls.keysLabel:Dock(TOP)
	controls.keysLabel:SetTall(18)
	controls.keysLabel:DockMargin(2, 2, 2, 0)
	controls.keysLabel:SetStyle("tiny")

	-- A bone
	header(scroll, "A bone (R_ right, L_ left; Finger0 is the thumb)")

	local bones = vgui.Create("DFW.Dropdown", scroll)
	bones:Dock(TOP)
	bones:SetTall(28)
	bones:DockMargin(2, 2, 2, 2)
	for _, bone in ipairs(DubzActions.BoneNames) do bones:AddChoice(bone, bone, bone == state.bone) end
	bones.OnSelect = function(_, _, _, bone) state.bone = bone showValues() end

	local function setAngle(index) return function(key, v)
		key.bones[state.bone] = key.bones[state.bone] or {0, 0, 0}
		key.bones[state.bone][index] = v
	end end

	controls.pitch = slider(scroll, "Pitch", -120, 120, 1, edit(setAngle(1)))
	controls.yaw = slider(scroll, "Yaw", -120, 120, 1, edit(setAngle(2)))
	controls.roll = slider(scroll, "Roll", -120, 120, 1, edit(setAngle(3)))

	-- Hands
	header(scroll, "Grip (0 = fingers straight, 1 = closed)")
	controls.curlR = slider(scroll, "Right hand", 0, 1.5, 2, edit(function(key, v) key.curl = key.curl or {} key.curl.R = v end))
	controls.curlL = slider(scroll, "Left hand", 0, 1.5, 2, edit(function(key, v) key.curl = key.curl or {} key.curl.L = v end))

	-- The arms as a whole
	header(scroll, "Both arms together")
	local function setPos(index) return function(key, v) key.pos = key.pos or {0, 0, 0} key.pos[index] = v end end
	local function setAng(index) return function(key, v) key.ang = key.ang or {0, 0, 0} key.ang[index] = v end end

	controls.posX = slider(scroll, "Forward", -20, 20, 1, edit(setPos(1)))
	controls.posY = slider(scroll, "Right", -20, 20, 1, edit(setPos(2)))
	controls.posZ = slider(scroll, "Up", -20, 20, 1, edit(setPos(3)))
	controls.angP = slider(scroll, "Tilt (pitch)", -60, 60, 1, edit(setAng(1)))
	controls.angY = slider(scroll, "Turn (yaw)", -60, 60, 1, edit(setAng(2)))
	controls.angR = slider(scroll, "Lean (roll)", -60, 60, 1, edit(setAng(3)))
	controls.look = slider(scroll, "View tips down (degrees)", -30, 30, 1, edit(function(key, v) key.look = v end))

	-- The item
	header(scroll, "The item in the hands")

	local itemRow = row(scroll, 30)
	controls.hasItem = vgui.Create("DFW.Checkbox", itemRow)
	controls.hasItem:Dock(FILL)
	controls.hasItem:SetLabel("Show the item (added on top of the Hands settings)")
	controls.hasItem.OnChange = function(_, value) state.data.item = value == true publish() showValues() end

	local function setItem(index) return function(key, v)
		key.item = key.item or {0, 0, 0, 0, 0, 0}
		key.item[index] = v
	end end

	controls.itemX = slider(scroll, "Forward", -10, 10, 1, edit(setItem(1)))
	controls.itemY = slider(scroll, "Right", -10, 10, 1, edit(setItem(2)))
	controls.itemZ = slider(scroll, "Up", -10, 10, 1, edit(setItem(3)))
	controls.itemP = slider(scroll, "Pitch", -180, 180, 0, edit(setItem(4)))
	controls.itemYaw = slider(scroll, "Yaw", -180, 180, 0, edit(setItem(5)))
	controls.itemR = slider(scroll, "Roll", -180, 180, 0, edit(setItem(6)))

	-- Saving
	header(scroll, "Keep it")

	local previewRow = row(scroll)
	button(previewRow, "Preview on me", 130, function() RunConsoleCommand("dubz_work_preview", state.kind, "600", "metal") end)
	button(previewRow, "Stop preview", 120, function() RunConsoleCommand("dubz_work_stop") end)

	local saveRow = row(scroll)
	button(saveRow, "Save for everyone", 160, function()
		sortKeys(state.data.keys)

		net.Start("DubzActions_SaveAnim")
			net.WriteString(state.kind)
			net.WriteString(util.TableToJSON(state.data))
		net.SendToServer()

		DFW.UI.Notify("Saved " .. state.kind .. ".", "success", 3)
	end, "primary")

	button(saveRow, "Back to the preset", 150, function()
		net.Start("DubzActions_ResetAnim")
			net.WriteString(state.kind)
		net.SendToServer()

		timer.Simple(0.4, function() if state then loadKind(state.kind) end end)
	end)

	controls.time:SetValue(0, true)
	controls.length:SetValue(state.data.length or 3, true)
	controls.hasItem:SetChecked(state.data.item == true, true)
	showValues()

	RunConsoleCommand("dubz_work_preview", state.kind, "600", "metal")

	-- Play: the time bar moves by itself
	frame.Think = function()
		if not state or not state.playing then return end

		state.p = state.p + FrameTime() / math.max(state.data.length or 3, 0.3)
		if state.p > 1 then state.p = 0 end

		controls.time:SetValue(state.p, true)
		publish()
		showValues()
	end
end

concommand.Add("dubz_work_editor", open)
