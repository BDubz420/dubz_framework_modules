-- The bench: a bench spot (put down with the placer) breaks. It sags and leans, and two snapped pieces of plank lie beside it.
--   1 carry the broken pieces away
--   2 fit a new plank (bought in the F4 menu, Repair Parts): carry it to the glow on the seat and it clicks in
--   3 nail it down: four nails, one by one, with the hammer
--   4 lift the bench back up (E): it comes up level again, and the worker is paid
-- Like the vending machine task, where the new plank goes (and so the nails) is worked out from the bench's own size and moved by the settings.
local cfg = DubzCW.Config

local T = {
	id = "bench",
	name = "Broken bench",
	summary = "A bench has collapsed: a plank snapped. Clear the pieces, fit a new plank and nail it down.",
}

-- Helpers (the same as the vending machine task's) --------------------------------------------------------------------------------------------------

local function orientTo(ent, up, normal)
	local size = ent:OBBMaxs() - ent:OBBMins()
	local axes = {{size.x, 1}, {size.y, 2}, {size.z, 3}}

	table.sort(axes, function(a, b) return a[1] > b[1] end)

	local long, mid, short = axes[1][2], axes[2][2], axes[3][2]
	local dir = {}

	dir[long] = up
	dir[short] = normal
	dir[mid] = up:Cross(normal)

	if dir[1]:Cross(dir[2]):Dot(dir[3]) < 0 then dir[mid] = -dir[mid] end

	local matrix = Matrix()
	matrix:SetForward(dir[1])
	matrix:SetRight(-dir[2])
	matrix:SetUp(dir[3])

	return matrix:GetAngles()
end

local function placeCentered(ent, center, ang)
	ent:SetAngles(ang)
	ent:SetPos(center)
	ent:SetPos(center - (ent:LocalToWorld(ent:OBBCenter()) - ent:GetPos()))
end

local function freeze(ent)
	local phys = ent:GetPhysicsObject()

	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end
end

local function unfreeze(ent)
	local phys = ent:GetPhysicsObject()

	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:Wake()
	end
end

local function snd(ent, name, level, pitch, volume)
	if IsValid(ent) then ent:EmitSound(name, level or 65, pitch or 100, volume or 1) end
end

-- A part used up is no longer one of the worker's bought parts (the F4 menu limit counts what they still have)
local function uncount(ent)
	local item = ent.DarkRPItem
	if not item then return end

	local owner = ent.Getowning_ent and ent:Getowning_ent()

	if not IsValid(owner) and ent.SID then owner = Player(tonumber(ent.SID) or 0) end
	if IsValid(owner) and owner.removeCustomEntity then owner:removeCustomEntity(item) end

	ent.DarkRPItem = nil
end

-- The bench -----------------------------------------------------------------------------------------------------------------------------------------

-- Where the new plank goes: the middle of the seat, plus the settings (bench space: x, y, up)
local function seatL(d)
	return Vector(d.c.x + cfg.BenchOffX, d.c.y + cfg.BenchOffY, d.maxs.z + cfg.BenchOffZ)
end

local function seatSocket(task)
	local d = task.data
	local ang = task.target:LocalToWorldAngles(d.plankAngL)

	return task.target:LocalToWorld(seatL(d)), ang
end

-- The four nails: in from both ends of the plank, to both sides of it
local function nails(task)
	local d = task.data
	local seat = seatL(d)
	local list = {}

	for _, along in ipairs({1, -1}) do
		for _, across in ipairs({1, -1}) do
			local local_ = seat + d.lengthLocal * (along * (d.plankLength / 2 - 5)) + d.crossLocal * (across * d.plankWidth / 4) + Vector(0, 0, 1)

			list[#list + 1] = {pos = task.target:LocalToWorld(local_), radius = cfg.BoltRadius}
		end
	end

	return list
end

local function nailZones(task)
	local zones = {}

	for index, nail in ipairs(nails(task)) do
		if not task.boltDone[index] then zones[#zones + 1] = {pos = nail.pos, radius = nail.radius} end
	end

	return zones
end

local function followParts(task)
	local bench, d = task.target, task.data
	local plank = d.plank

	if d.plankAttached and IsValid(plank) then
		local pos, ang = seatSocket(task)

		placeCentered(plank, pos, ang)
	end
end

-- The bench leaning over (f = 1) or level (f = 0): it turns about its length and sags
local function applyTilt(task, f)
	local bench, d = task.target, task.data
	local axis = Vector(d.lengthLocal)

	axis:Rotate(d.baseAng)

	local ang = Angle(d.baseAng.p, d.baseAng.y, d.baseAng.r)
	ang:RotateAroundAxis(axis, cfg.BenchTilt * f)

	bench:SetAngles(ang)
	bench:SetPos(d.basePos - Vector(0, 0, cfg.BenchSink * f))

	followParts(task)
end

local function startTilt(task, from, to, seconds)
	task.data.anim = {from = from, to = to, start = CurTime(), seconds = seconds}
end

-- The task ------------------------------------------------------------------------------------------------------------------------------------------

function T.Find() return DubzCW.FindSpot("bench") end

function T.Begin(task)
	local bench, d = task.target, task.data

	bench:SetWorking(true)

	d.basePos, d.baseAng = bench:GetPos(), bench:GetAngles()
	d.mins, d.maxs = bench:OBBMins(), bench:OBBMaxs()
	d.c = (d.mins + d.maxs) / 2

	local sx, sy = d.maxs.x - d.mins.x, d.maxs.y - d.mins.y

	d.lengthLocal = sx >= sy and Vector(1, 0, 0) or Vector(0, 1, 0)
	d.crossLocal = sx >= sy and Vector(0, 1, 0) or Vector(1, 0, 0)
	d.length, d.width = math.max(sx, sy), math.min(sx, sy)
	d.f = 0
	d.pieces = {}

	-- Two snapped pieces of plank lie beside the bench
	local side = bench:LocalToWorld(d.c + d.crossLocal * (d.width / 2 + 24))

	for index = 1, 2 do
		local piece = ents.Create("prop_physics")
		if not IsValid(piece) then error("could not make a plank piece") end

		piece:SetModel(cfg.PlankModel)
		piece:SetPos(side + (bench:LocalToWorld(d.lengthLocal * (index == 1 and 1 or -1) * d.length * 0.18) - bench:GetPos()) + Vector(0, 0, 8))
		piece:SetAngles(Angle(0, math.random(0, 359), 0))
		piece:Spawn()
		piece:SetColor(Color(150, 125, 105))
		piece.DubzCWCarry = true

		local phys = piece:GetPhysicsObject()
		if IsValid(phys) then phys:SetMass(6) end

		d.pieces[index] = piece
	end

	-- The size of a plank, and how it lies on the seat: flat, along the bench (worked out from the pieces: the same model as the new plank)
	local size = d.pieces[1]:OBBMaxs() - d.pieces[1]:OBBMins()
	local sizes = {size.x, size.y, size.z}

	table.sort(sizes, function(a, b) return a > b end)
	d.plankLength, d.plankWidth = sizes[1], sizes[2]

	local lengthWorld = Vector(d.lengthLocal)
	lengthWorld:Rotate(d.baseAng)

	local flat = orientTo(d.pieces[1], lengthWorld, Vector(0, 0, 1))
	local _, local_ = WorldToLocal(vector_origin, flat, vector_origin, d.baseAng)

	d.plankAngL = local_

	-- It breaks: a crack, and the bench sags
	snd(bench, "physics/wood/wood_plank_break" .. math.random(1, 4) .. ".wav", 75)
	snd(bench, "physics/wood/wood_furniture_break" .. math.random(1, 2) .. ".wav", 72, 90)

	startTilt(task, 0, 1, 0.5)
end

function T.Animate(task)
	local d = task.data

	if d.anim then
		local t = math.Clamp((CurTime() - d.anim.start) / math.max(d.anim.seconds, 0.2), 0, 1)
		local eased = t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2

		d.f = Lerp(eased, d.anim.from, d.anim.to)
		applyTilt(task, d.f)

		if t >= 1 then
			d.anim = nil

			if d.anim == nil and d.f <= 0.01 then
				snd(task.target, "physics/wood/wood_furniture_impact_hard" .. math.random(1, 3) .. ".wav", 72, 85)
			end
		end
	else
		followParts(task)
	end
end

function T.Busy(task)
	return task.data.anim ~= nil
end

local function restore(task)
	local bench, d = task.target, task.data

	if not IsValid(bench) then return end

	d.anim = nil
	if d.basePos then
		bench:SetAngles(d.baseAng)
		bench:SetPos(d.basePos)
	end

	bench:SetWorking(false)
end

local function later(seconds, ent)
	timer.Simple(seconds, function() if IsValid(ent) then ent:Remove() end end)
end

function T.Finish(task)
	local d = task.data

	restore(task)
	snd(task.target, "buttons/button14.wav", 60, 130)

	-- The pieces and the plank are tidied away a little later (nothing left lying about)
	for _, piece in ipairs(d.pieces or {}) do later(25, piece) end
	later(30, d.plank)
end

function T.Cleanup(task)
	local d = task.data

	-- A new plank that was fitted comes off again (it is the worker's)
	if IsValid(d.plank) then
		d.plankAttached = false
		d.plank.DubzCWLocked = false
		unfreeze(d.plank)
	end

	restore(task)

	for _, piece in ipairs(d.pieces or {}) do later(5, piece) end
end

-- The steps ----------------------------------------------------------------------------------------------------------------------------------------

-- A nail hit: a thud and a ring
local function nailHit(ply, task)
	if cfg.ViewShake then ply:ViewPunch(Angle(-2, 0, 0)) end
	snd(task.target, "physics/wood/wood_plank_impact_hard" .. math.random(1, 5) .. ".wav", 66, math.random(90, 110))
	snd(task.target, "physics/metal/metal_solid_impact_bullet" .. math.random(1, 4) .. ".wav", 58, math.random(150, 190), 0.5)
end

T.steps = {
	{
		kind = "carry",
		text = "Carry the broken planks away",
		hint = "Pick each piece up with E and take it away from the bench",
		prompt = "press E to pick it up",
		wait = function(task) return task.data.anim ~= nil end,
		ent = function(task)
			for _, piece in ipairs(task.data.pieces) do
				if IsValid(piece) then return piece end
			end

			return task.target
		end,
		done = function(task)
			local center = task.target:LocalToWorld(task.data.c)

			for _, piece in ipairs(task.data.pieces) do
				if IsValid(piece) and (piece:WorldSpaceCenter():Distance(center) < cfg.CarryAwayDistance + 40 or piece:IsPlayerHolding()) then return false end
			end

			return true
		end,
		zones = function(task)
			local zones = {}

			for _, piece in ipairs(task.data.pieces) do
				if IsValid(piece) then zones[#zones + 1] = {ent = piece, radius = 26} end
			end

			return zones
		end,
	},
	{
		kind = "snap",
		text = "Fit a new plank",
		hint = "Buy a Wood Plank in the F4 menu (Repair Parts), carry it to the glow on the seat",
		prompt = "bring the new plank here",
		socket = function(task) return seatSocket(task) end,
		filter = function(task, ent) return ent:GetClass() == "dubz_cw_plank" and not ent.DubzCWLocked end,
		zones = function(task) return {{pos = (seatSocket(task)), radius = cfg.SnapDistance * 1.5}} end,
		onSnap = function(task, ent)
			local pos, ang = seatSocket(task)

			placeCentered(ent, pos, ang)
			freeze(ent)
			ent.DubzCWLocked = true
			uncount(ent)

			snd(ent, "physics/wood/wood_plank_impact_hard" .. math.random(1, 5) .. ".wav", 70)

			task.data.plank = ent
			task.data.plankAttached = true
		end,
	},
	{
		kind = "bolts", tool = "hammer",
		text = "Nail the plank down",
		hint = "Hold left click on each glowing nail with the hammer",
		prompt = "hold left click (hammer)",
		seconds = function() return cfg.NailSeconds end,
		workEvery = 0.4,
		workSound = nailHit,
		bolts = nails,
		zones = nailZones,
		onBolt = function(task)
			snd(task.data.plank, "physics/wood/wood_plank_impact_hard" .. math.random(1, 5) .. ".wav", 68, 85)
			snd(task.data.plank, "doors/door_latch1.wav", 55, math.random(150, 180), 0.6)
		end,
	},
	{
		kind = "use",
		text = "Lift the bench back up",
		hint = "Press E at the seat",
		prompt = "press E to lift it",
		zones = function(task) return {{pos = task.target:LocalToWorld(seatL(task.data)), radius = 38}} end,
		onDone = function(task)
			snd(task.target, "physics/wood/wood_furniture_strain" .. math.random(1, 3) .. ".wav", 70, 90)
			startTilt(task, task.data.f or 1, 0, math.max(cfg.SwingSeconds * 0.6, 0.8))
		end,
	},
}

DubzCW.RegisterTask(T)
