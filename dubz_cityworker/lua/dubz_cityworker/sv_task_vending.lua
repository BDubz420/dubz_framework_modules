-- The first task: a broken vending machine (the sent_soda_machine of the Dubz Vending Machine addon).
--   the machine stops working and has a back plate on, with a burnt circuit board behind it
--   1 pull the machine out from the wall (E at the glowing edge: it swings out)
--   2 undo the four bolts of the back plate (wrench, one by one)
--   3 carry the plate out of the way
--   4 cut the burnt circuit board out (one snip with the pliers: it comes apart into electronics scrap, which the worker picks up)
--   5 put a new circuit board in (bought in the F4 menu: carry it to the glow and it clicks in)
--   6 put the back plate on again (carry it to the glow)
--   7 do the four bolts up again (wrench)
--   8 push the machine back (E at the glowing edge): it works again, and the worker is paid
-- Every spot is worked out from the machine's own size and moved by the dial settings (!dubzconfig > City Worker > Dial In ...), live while a job runs.
-- A task is a template for more: Find, Begin, Think, Animate, Finish, Cleanup, Describe and a list of steps (see sv_cityworker.lua).
local cfg = DubzCW.Config

local T = {
	id = "vending",
	name = "Vending machine repair",
	summary = "A vending machine is broken. Pull it out from the wall, take the back plate off, cut out the burnt circuit board and fit a new one.",
}

-- Geometry -------------------------------------------------------------------------------------------------------------------------------------------

-- The machine in its own space: its front (where the can comes out) is +x, so its back is -x; +y is its left, +z up
local function box(machine)
	local mins, maxs = machine:OBBMins(), machine:OBBMaxs()

	return mins, maxs, (mins + maxs) / 2
end

-- The angles that put a part's longest side along `up` and its thinnest side along `normal` (whatever way round the model is made)
local function orientTo(ent, up, normal)
	local size = ent:OBBMaxs() - ent:OBBMins()
	local axes = {{size.x, 1}, {size.y, 2}, {size.z, 3}}

	table.sort(axes, function(a, b) return a[1] > b[1] end)

	local long, mid, short = axes[1][2], axes[2][2], axes[3][2]
	local dir = {}

	dir[long] = up
	dir[short] = normal
	dir[mid] = up:Cross(normal)

	-- (the three directions have to make a right-handed set)
	if dir[1]:Cross(dir[2]):Dot(dir[3]) < 0 then dir[mid] = -dir[mid] end

	local matrix = Matrix()
	matrix:SetForward(dir[1])
	matrix:SetRight(-dir[2])
	matrix:SetUp(dir[3])

	return matrix:GetAngles()
end

-- Puts a part so that its middle is at `center` with these angles
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

-- Where everything is (machine space, with the dial settings added; read every time, so the dials work live) ---------------------------------------

local function offsetAng(base, p, y, r)
	local _, ang = LocalToWorld(vector_origin, Angle(p, y, r), vector_origin, base)

	return ang
end

-- (the edge is on the side away from the hinge: the machine is hinged at its back left corner and swings out to the left, or the other way round)
local function edgeL(d)
	local y = d.side == 1 and d.mins.y or d.maxs.y

	return Vector(d.maxs.x + cfg.EdgeOffX, y + cfg.EdgeOffY, d.c.z + cfg.EdgeOffZ)
end

local function plateL(d)
	return Vector(d.mins.x - cfg.PlateGap + cfg.PlateOffX, d.c.y + cfg.PlateOffY, d.c.z + cfg.PlateOffZ),
		offsetAng(d.plateBaseAng, cfg.PlateAngP, cfg.PlateAngY, cfg.PlateAngR)
end

local function boardL(d)
	return Vector(d.mins.x - cfg.BoardGap + cfg.BoardOffX, d.c.y + cfg.BoardOffY, d.c.z + 6 + cfg.BoardOffZ),
		offsetAng(d.boardBaseAng, cfg.BoardAngP, cfg.BoardAngY, cfg.BoardAngR)
end

local function edge(task)
	return task.target:LocalToWorld(edgeL(task.data))
end

local function boardSocket(task)
	local pos, ang = boardL(task.data)

	return task.target:LocalToWorld(pos), task.target:LocalToWorldAngles(ang)
end

local function plateSocket(task)
	local pos, ang = plateL(task.data)

	return task.target:LocalToWorld(pos), task.target:LocalToWorldAngles(ang)
end

-- The four bolts of the plate: its corners, in from the edge a little, on the outside face
local function bolts(task)
	local d = task.data
	local centerL = plateL(d)
	local halfW, halfH = d.plateW / 2 - cfg.BoltInset, d.plateH / 2 - cfg.BoltInset
	local list = {}

	for _, side in ipairs({1, -1}) do
		for _, level in ipairs({1, -1}) do
			list[#list + 1] = {pos = task.target:LocalToWorld(Vector(centerL.x - 1.5, centerL.y + side * halfW, centerL.z + level * halfH)), radius = cfg.BoltRadius}
		end
	end

	return list
end

-- The bolts still to do, as glowing spots
local function boltZones(task)
	local zones = {}

	for index, bolt in ipairs(bolts(task)) do
		if not task.boltDone[index] then zones[#zones + 1] = {pos = bolt.pos, radius = bolt.radius} end
	end

	return zones
end

-- Parts that ride on the machine (the plate, the boards) ---------------------------------------------------------------------------------------------

local function followParts(task)
	local machine, d = task.target, task.data

	for _, part in pairs(d.parts or {}) do
		if part.attached and IsValid(part.ent) then
			local centerL, angL = part.where(d)

			placeCentered(part.ent, machine:LocalToWorld(centerL), machine:LocalToWorldAngles(angL))
		end
	end
end

-- The machine turned out from the wall by `f` (0 = in place, 1 = fully out): it slides straight out from the wall first (so its corner clears the wall
-- beside it), then swings round its back corner on the hinge side. Going back is the same in reverse.
local function applySwing(task, f)
	local machine, d = task.target, task.data
	local slide = math.Clamp(f / 0.35, 0, 1)
	local swing = math.Clamp((f - 0.35) / 0.65, 0, 1)
	local out = d.baseAng:Forward() * cfg.PullOutDistance * slide
	local degrees = cfg.SwingDegrees * swing * d.side
	local offset = d.basePos - d.hinge

	offset:Rotate(Angle(0, degrees, 0))

	machine:SetPos(d.hinge + out + offset)
	machine:SetAngles(Angle(d.baseAng.p, d.baseAng.y + degrees, d.baseAng.r))

	followParts(task)
end

local function startSwing(task, from, to)
	local d = task.data

	d.anim = {from = from, to = to, start = CurTime()}

	-- The heavy start, and a scrape along the ground while it moves
	snd(task.target, "physics/metal/metal_box_strain" .. math.random(1, 4) .. ".wav", 70, 90)

	if d.scrape then d.scrape:Stop() end

	d.scrape = CreateSound(task.target, "physics/concrete/concrete_scrape_rough_loop1.wav")
	d.scrape:SetSoundLevel(62)
	d.scrape:PlayEx(0, 80)
	d.scrape:ChangeVolume(0.55, 0.3)
end

-- The task ------------------------------------------------------------------------------------------------------------------------------------------

function T.Find()
	local list = {}

	for _, machine in ipairs(ents.FindByClass("sent_soda_machine")) do
		-- (GetBroken is there once the vending machine addon is updated; an old copy without it is still a machine to fix)
		if not machine.DubzCWTask and not (machine.GetBroken and machine:GetBroken()) then list[#list + 1] = machine end
	end

	if #list == 0 then return nil end

	return list[math.random(#list)]
end

function T.Begin(task)
	local machine, d = task.target, task.data
	local phys = machine:GetPhysicsObject()

	d.parts = {}
	d.wasFrozen = IsValid(phys) and not phys:IsMotionEnabled()
	if IsValid(phys) then phys:EnableMotion(false) end

	d.basePos, d.baseAng = machine:GetPos(), machine:GetAngles()
	d.mins, d.maxs, d.c = box(machine)
	d.side = cfg.SwingSide == "right" and -1 or 1
	d.hinge = machine:LocalToWorld(Vector(d.mins.x, d.side == 1 and d.maxs.y or d.mins.y, 0))
	d.f = 0

	machine:SetBroken(true)
	snd(machine, "ambient/energy/spark2.wav", 65)

	local up, back = machine:GetUp(), -machine:GetForward()

	-- The back plate, sized to cover the back of the machine
	local plate = ents.Create("dubz_cw_plate")
	if not IsValid(plate) then error("dubz_cw_plate is missing") end

	plate:SetPos(d.basePos + Vector(0, 0, 300))
	plate:Spawn()

	local size = plate:OBBMaxs() - plate:OBBMins()
	plate:SetModelScale((d.maxs.z - d.mins.z) * cfg.PlateFit / math.max(size.x, size.y, size.z), 0)
	plate:PhysicsInit(SOLID_VPHYSICS)
	plate:SetMoveType(MOVETYPE_VPHYSICS)
	plate:SetSolid(SOLID_VPHYSICS)

	-- (its size after scaling: the height, then the width)
	local scaled = plate:OBBMaxs() - plate:OBBMins()
	local sizes = {scaled.x, scaled.y, scaled.z}

	table.sort(sizes, function(a, b) return a > b end)
	d.plateH, d.plateW = sizes[1], sizes[2]

	d.plateBaseAng = machine:WorldToLocalAngles(orientTo(plate, up, back))
	plate.DubzCWLocked = true
	freeze(plate)

	d.plate = plate
	d.parts.plate = {ent = plate, attached = true, where = plateL}

	-- The burnt circuit board behind it
	local board = ents.Create("dubz_circuit_board")
	if not IsValid(board) then error("dubz_circuit_board is missing") end

	board:SetPos(d.basePos + Vector(0, 0, 340))
	board:Spawn()
	board:SetColor(Color(75, 60, 55))
	board.DubzCWOld = true
	board.DubzCWLocked = true
	freeze(board)

	d.boardBaseAng = machine:WorldToLocalAngles(orientTo(board, up, cfg.BoardFlip and -back or back))

	d.board = board
	d.parts.board = {ent = board, attached = true, where = boardL}

	followParts(task)
end

-- Every tick: the machine swinging (smoothly), and the parts following the machine and the dial settings
function T.Animate(task)
	local d = task.data

	if d.anim then
		local t = math.Clamp((CurTime() - d.anim.start) / math.max(cfg.SwingSeconds, 0.2), 0, 1)
		local eased = t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2   -- (slow, quick, slow)

		d.f = Lerp(eased, d.anim.from, d.anim.to)
		applySwing(task, d.f)

		-- The scrape follows how fast it moves
		if d.scrape then d.scrape:ChangePitch(70 + 45 * math.sin(t * math.pi), 0) end

		if t >= 1 then
			d.anim = nil

			if d.scrape then
				d.scrape:FadeOut(0.3)
				d.scrape = nil
			end

			snd(task.target, "physics/metal/metal_box_impact_hard3.wav", 72, 85)
			snd(task.target, "physics/metal/metal_solid_impact_hard1.wav", 65, 70)
		end
	else
		followParts(task)
	end
end

-- The burnt board sparks (once the plate is out of the way) until it is cut out
function T.Think(task)
	local d = task.data

	if d.sparking and not d.boardOut and cfg.Sparks and IsValid(d.board) and CurTime() > (d.nextSpark or 0) then
		d.nextSpark = CurTime() + math.Rand(0.7, 1.7)

		local effect = EffectData()
		effect:SetOrigin(d.board:WorldSpaceCenter())
		effect:SetMagnitude(2)
		effect:SetScale(1)
		effect:SetRadius(4)
		util.Effect("ElectricSpark", effect)

		snd(d.board, "ambient/energy/spark" .. math.random(1, 6) .. ".wav", 60)
	end
end

function T.Busy(task)
	return task.data.anim ~= nil
end

-- The machine is put back as it was: in place, working, frozen again if it was
local function restore(task)
	local machine, d = task.target, task.data

	if d.scrape then
		d.scrape:Stop()
		d.scrape = nil
	end

	if not IsValid(machine) then return end

	d.anim = nil
	if d.basePos and d.hinge then applySwing(task, 0) end
	machine:SetBroken(false)

	local phys = machine:GetPhysicsObject()
	if IsValid(phys) and not d.wasFrozen then phys:EnableMotion(true) end
end

function T.Finish(task)
	local d = task.data

	restore(task)
	snd(task.target, "buttons/button14.wav", 65)
	snd(task.target, "ambient/energy/spark5.wav", 60, 120)

	-- The plate and the new board are part of the machine again (nothing left lying about)
	if IsValid(d.plate) then d.plate:Remove() end
	if IsValid(d.newBoard) then d.newBoard:Remove() end
	if IsValid(d.board) then d.board:Remove() end
end

function T.Cleanup(task)
	local d = task.data

	d.parts = d.parts or {}

	-- A new board that was put in comes out again (it is the worker's)
	if IsValid(d.newBoard) then
		d.newBoard.DubzCWLocked = false
		unfreeze(d.newBoard)
	end

	restore(task)

	if IsValid(d.plate) then d.plate:Remove() end
	if IsValid(d.board) then d.board:Remove() end
end

-- The numbers for dialling in: everything in the machine's own space (the dial settings are moves from these)
function T.Describe(task)
	local d = task.data
	local function v(vec) return string.format("%.1f, %.1f, %.1f", vec.x, vec.y, vec.z) end
	local plateC, plateA = plateL(d)
	local boardC, boardA = boardL(d)

	return {
		"--- City Worker: vending machine spots (machine space: x forward, y left, z up) ---",
		"Machine bounds: min " .. v(d.mins) .. "   max " .. v(d.maxs) .. "   centre " .. v(d.c),
		"Edge (E to pull and push): " .. v(edgeL(d)) .. "   dials: EdgeOffX/Y/Z = " .. cfg.EdgeOffX .. ", " .. cfg.EdgeOffY .. ", " .. cfg.EdgeOffZ,
		"Plate centre: " .. v(plateC) .. "   angle " .. string.format("%.0f, %.0f, %.0f", plateA.p, plateA.y, plateA.r) .. "   size " .. string.format("%.1f x %.1f", d.plateW, d.plateH),
		"   dials: PlateOffX/Y/Z = " .. cfg.PlateOffX .. ", " .. cfg.PlateOffY .. ", " .. cfg.PlateOffZ .. "   PlateAngP/Y/R = " .. cfg.PlateAngP .. ", " .. cfg.PlateAngY .. ", " .. cfg.PlateAngR,
		"Board centre: " .. v(boardC) .. "   angle " .. string.format("%.0f, %.0f, %.0f", boardA.p, boardA.y, boardA.r),
		"   dials: BoardOffX/Y/Z = " .. cfg.BoardOffX .. ", " .. cfg.BoardOffY .. ", " .. cfg.BoardOffZ .. "   BoardAngP/Y/R = " .. cfg.BoardAngP .. ", " .. cfg.BoardAngY .. ", " .. cfg.BoardAngR,
		"Bolts: " .. cfg.BoltInset .. " units in from the plate corners (BoltInset)",
	}
end

-- The steps ----------------------------------------------------------------------------------------------------------------------------------------

-- A bolt turned: a clink and a latch
local function boltDone(task)
	local plate = task.data.plate

	snd(plate, "physics/metal/metal_solid_impact_bullet" .. math.random(1, 4) .. ".wav", 62, math.random(105, 125))
	snd(plate, "doors/door_latch1.wav", 55, math.random(115, 135), 0.6)
end

T.steps = {
	{
		kind = "use", id = "pull",
		text = "Pull the machine out from the wall",
		hint = "Press E at the glowing edge",
		prompt = "press E to pull it out",
		zones = function(task) return {{pos = edge(task), radius = 12}} end,
		onDone = function(task) startSwing(task, 0, 1) end,
	},
	{
		kind = "bolts", id = "unbolt", tool = "wrench",
		text = "Undo the four bolts of the back plate",
		hint = "Hold left click on each glowing bolt with the wrench",
		prompt = "hold left click (wrench)",
		seconds = function() return cfg.BoltSeconds end,
		wait = function(task) return task.data.anim ~= nil end,
		bolts = bolts,
		zones = boltZones,
		onBolt = boltDone,
		onDone = function(task)
			local plate = task.data.plate

			if IsValid(plate) then
				task.data.parts.plate.attached = false
				plate.DubzCWLocked = false
				plate.DubzCWCarry = true
				unfreeze(plate)
				snd(plate, "physics/metal/metal_sheet_impact_hard" .. math.random(1, 4) .. ".wav", 70)
			end
		end,
	},
	{
		kind = "carry", id = "moveplate",
		text = "Carry the plate out of the way",
		hint = "Pick it up with E and move it away from the machine",
		prompt = "press E to pick it up",
		ent = function(task) return task.data.plate end,
		done = function(task)
			local pos = boardSocket(task)

			return task.data.plate:WorldSpaceCenter():Distance(pos) > cfg.CarryAwayDistance and not task.data.plate:IsPlayerHolding()
		end,
		zones = function(task) return {{ent = task.data.plate, radius = 24}} end,
		onDone = function(task) task.data.sparking = true end,
	},
	{
		kind = "click", id = "snip", tool = "pliers",
		text = "Cut the burnt circuit board out",
		hint = "One snip with the pliers: left click on it",
		prompt = "left click (pliers)",
		zones = function(task) return {{ent = task.data.board, radius = 14}} end,
		onDone = function(task)
			local d = task.data
			local board = d.board

			if not IsValid(board) then return end

			-- The snip: sparks and a zap
			local effect = EffectData()
			effect:SetOrigin(board:WorldSpaceCenter())
			effect:SetMagnitude(4)
			effect:SetScale(2)
			effect:SetRadius(8)
			util.Effect("ElectricSpark", effect)

			snd(board, "ambient/energy/zap" .. math.random(5, 9) .. ".wav", 70)
			snd(board, "physics/metal/metal_solid_impact_bullet2.wav", 70, 165)

			d.boardOut = true
			d.parts.board = nil

			local id = cfg.ScrapId

			if id ~= "" and DubzScrap and DubzScrap.Material(id) then
				-- It comes apart into electronics scrap: the worker picks it up (the pocket) like any scrap
				local pos = board:WorldSpaceCenter()

				board:Remove()
				d.board = nil

				for _ = 1, math.random(math.min(cfg.ScrapMin, cfg.ScrapMax), math.max(cfg.ScrapMin, cfg.ScrapMax)) do
					local scrap = ents.Create("dubz_scrap")

					if IsValid(scrap) then
						scrap:SetMat(id)
						scrap:SetPos(pos + VectorRand() * 2)
						scrap:SetAngles(AngleRand())
						scrap:Spawn()

						local phys = scrap:GetPhysicsObject()
						if IsValid(phys) then phys:SetVelocity(Vector(math.Rand(-45, 45), math.Rand(-45, 45), math.Rand(40, 90))) end
					end
				end

				timer.Simple(0.1, function() snd(task.target, "physics/metal/metal_computer_impact_soft2.wav", 62, 110) end)
			else
				-- (no scrap addon: the board itself comes out)
				board.DubzCWLocked = false
				board.DubzCWCarry = true
				unfreeze(board)
			end
		end,
	},
	{
		kind = "snap", id = "newboard",
		text = "Fit a new circuit board",
		hint = "Buy a Replacement Circuit Board in the F4 menu (Repair Parts), carry it to the glow",
		prompt = "bring the new board here",
		socket = function(task) return boardSocket(task) end,
		filter = function(task, ent) return ent:GetClass() == "dubz_circuit_board" and not ent.DubzCWOld and not ent.DubzCWLocked end,
		zones = function(task) return {{pos = (boardSocket(task)), radius = cfg.SnapDistance}} end,
		onSnap = function(task, ent)
			local pos, ang = boardSocket(task)

			placeCentered(ent, pos, ang)
			freeze(ent)
			ent.DubzCWLocked = true
			uncount(ent)

			snd(ent, "physics/metal/metal_computer_impact_hard" .. math.random(1, 3) .. ".wav", 68)
			snd(ent, "buttons/button9.wav", 55, 140, 0.6)

			task.data.newBoard = ent
			task.data.parts.newboard = {ent = ent, attached = true, where = boardL}
		end,
	},
	{
		kind = "snap", id = "plateback",
		text = "Put the back plate on again",
		hint = "Carry the plate to the glow",
		prompt = "bring the plate here",
		socket = function(task) return plateSocket(task) end,
		filter = function(task, ent) return ent == task.data.plate end,
		zones = function(task) return {{pos = (plateSocket(task)), radius = 24}, {ent = task.data.plate, radius = 24}} end,
		onSnap = function(task, ent)
			local pos, ang = plateSocket(task)

			placeCentered(ent, pos, ang)
			freeze(ent)
			ent.DubzCWLocked = true
			ent.DubzCWCarry = false

			snd(ent, "physics/metal/metal_box_impact_hard1.wav", 70, 90)

			task.data.parts.plate.attached = true
		end,
	},
	{
		kind = "bolts", id = "rebolt", tool = "wrench",
		text = "Do the four bolts up again",
		hint = "Hold left click on each glowing bolt with the wrench",
		prompt = "hold left click (wrench)",
		seconds = function() return cfg.BoltSeconds end,
		bolts = bolts,
		zones = boltZones,
		onBolt = boltDone,
	},
	{
		kind = "use", id = "pushback",
		text = "Push the machine back against the wall",
		hint = "Press E at the glowing edge",
		prompt = "press E to push it back",
		zones = function(task) return {{pos = edge(task), radius = 12}} end,
		onDone = function(task) startSwing(task, task.data.f or 1, 0) end,
	},
}

DubzCW.RegisterTask(T)
