-- Animations as data. Each kind of work is a list of KEYFRAMES: moments (0 to 1 through the work) with the pose of the arms at that moment; the
-- poses in between are blended. The four built-in kinds start as code presets (weapons/dubz_work/shared.lua); the animation editor
-- (dubz_work_editor) samples a preset into keyframes, lets you pose every moment by hand, and saves it for everybody. A saved animation
-- replaces the code preset for that kind; resetting it brings the preset back.
--
-- A saved animation: {length = seconds the editor plays it in, item = whether an item is held, keys = {key, ...}}
-- A key: {t = 0..1, bones = {R_Forearm = {pitch, yaw, roll}, ...}, curl = {R = 0..1, L = 0..1}, pos = {forward, right, up},
--         ang = {pitch, yaw, roll}, look = degrees, item = {forward, right, up, pitch, yaw, roll}}
DubzActions.Saved = DubzActions.Saved or {}
DubzActions.DefaultLength = {scrap = 3, search = 1.8, craft = 4, pickup = 1}
DubzActions.BuiltIn = {"scrap", "search", "craft", "pickup"}

local ZERO3 = {0, 0, 0}

local function smooth(x) x = math.Clamp(x, 0, 1) return x * x * (3 - 2 * x) end
local function lerp(a, b, f) return a + (b - a) * f end

local function tri(v) return {v.p, v.y, v.r} end

-- A built-in code animation, sampled into keys (the editor's starting point)
function DubzActions.Bake(kind, count)
	local animate = DubzActions.Animations and DubzActions.Animations[kind]
	local keys = {}
	count = count or 12

	if not animate then return {{t = 0}, {t = 1}} end

	local length = DubzActions.DefaultLength[kind] or 3

	for index = 0, count do
		local p = index / count
		local pose = {bones = {}, curl = {R = 0, L = 0}, pos = Vector(), ang = Angle(), look = 0}

		animate(p * length, p, pose)

		local key = {t = p, bones = {}, curl = {R = pose.curl.R, L = pose.curl.L}, pos = {pose.pos.x, pose.pos.y, pose.pos.z}, ang = tri(pose.ang), look = pose.look}

		for name, angle in pairs(pose.bones) do key.bones[name] = tri(angle) end

		if pose.item then key.item = {pose.item.pos.x, pose.item.pos.y, pose.item.pos.z, pose.item.ang.p, pose.item.ang.y, pose.item.ang.r} end

		keys[#keys + 1] = key
	end

	return keys
end

-- A fresh editable copy of a kind: the saved animation, or the preset baked into keys
function DubzActions.Working(kind)
	local saved = DubzActions.Saved[kind]
	if saved then return table.Copy(saved) end

	local keys = DubzActions.Bake(kind)
	local hasItem = false
	for _, key in ipairs(keys) do if key.item then hasItem = true end end

	return {length = DubzActions.DefaultLength[kind] or 3, item = hasItem, keys = keys}
end

-- The pose at p (0 to 1) from a list of keys, written into `pose`
function DubzActions.EvaluateKeys(data, p, pose, view)
	local keys = data.keys
	if not keys or #keys == 0 then return end

	local k1, k2 = keys[1], keys[#keys]

	if p <= keys[1].t then
		k2 = k1
	elseif p >= keys[#keys].t then
		k1 = k2
	else
		for index = 1, #keys - 1 do
			if p >= keys[index].t and p <= keys[index + 1].t then k1, k2 = keys[index], keys[index + 1] break end
		end
	end

	local span = k2.t - k1.t
	local f = span > 0.0001 and smooth((p - k1.t) / span) or 0

	-- Bones (the upper arms are the first person arms' own; other players' models keep theirs)
	local names = {}
	for name in pairs(k1.bones or {}) do names[name] = true end
	for name in pairs(k2.bones or {}) do names[name] = true end

	for name in pairs(names) do
		if not (view == "third" and (name == "R_UpperArm" or name == "L_UpperArm")) then
			local a, b = (k1.bones or {})[name] or ZERO3, (k2.bones or {})[name] or ZERO3
			pose.bones[name] = Angle(lerp(a[1], b[1], f), lerp(a[2], b[2], f), lerp(a[3], b[3], f))
		end
	end

	local c1, c2 = k1.curl or {}, k2.curl or {}
	pose.curl.R = lerp(c1.R or 0, c2.R or 0, f)
	pose.curl.L = lerp(c1.L or 0, c2.L or 0, f)

	local p1, p2 = k1.pos or ZERO3, k2.pos or ZERO3
	pose.pos = Vector(lerp(p1[1], p2[1], f), lerp(p1[2], p2[2], f), lerp(p1[3], p2[3], f))

	local a1, a2 = k1.ang or ZERO3, k2.ang or ZERO3
	pose.ang = Angle(lerp(a1[1], a2[1], f), lerp(a1[2], a2[2], f), lerp(a1[3], a2[3], f))

	pose.look = lerp(k1.look or 0, k2.look or 0, f)

	if data.item then
		local i1, i2 = k1.item or {0, 0, 0, 0, 0, 0}, k2.item or {0, 0, 0, 0, 0, 0}
		pose.item = {
			pos = Vector(lerp(i1[1], i2[1], f), lerp(i1[2], i2[2], f), lerp(i1[3], i2[3], f)),
			ang = Angle(lerp(i1[4], i2[4], f), lerp(i1[5], i2[5], f), lerp(i1[6], i2[6], f)),
		}
	else
		pose.item = nil
	end
end

function DubzActions.HasAnimation(kind)
	return DubzActions.Saved[kind] ~= nil or (DubzActions.Animations and DubzActions.Animations[kind] ~= nil)
end

-- The pose for a kind of work, whatever it is made of: what the editor is showing (your own arms while it is open), a saved animation,
-- or the code preset
function DubzActions.Evaluate(kind, t, p, pose, view)
	local editing = DubzActions.EditorOverride

	if editing and editing.kind == kind and view == "first" then
		DubzActions.EvaluateKeys(editing.data, editing.p, pose, view)
		return
	end

	local saved = DubzActions.Saved[kind]

	if saved then
		DubzActions.EvaluateKeys(saved, p, pose, view)
		return
	end

	local animate = DubzActions.Animations and DubzActions.Animations[kind]
	if animate then animate(t, p, pose) end
end

net.Receive("DubzActions_Anims", function()
	local size = net.ReadUInt(32)
	local json = util.Decompress(net.ReadData(size) or "") or "{}"

	DubzActions.Saved = util.JSONToTable(json) or {}
	hook.Run("DubzActionsAnimsChanged")
end)
