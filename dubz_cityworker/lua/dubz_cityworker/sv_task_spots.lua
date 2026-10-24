-- The street jobs: a gas leak, a fire hydrant, a pile of rubble and an electrical fault. Each is a spot put down with the City Worker Placer tool (sv_spots.lua);
-- the job picks one that is quiet, breaks it (it leaks, sprays, piles up, sparks), and the worker puts it right with the tool:
--   gas leak        hold left click with the WRENCH on the pipe
--   fire hydrant    the wrench sits on the hydrant's nut: hold left click and move the mouse in circles to turn it
--   rubble          click with the SHOVEL on the pile: every click is a scoop
--   electrical      PLIERS: one click pulls the wires out, hold to twist them back together, then press E to push them back in
-- The time of the leak is a random one between the two numbers in the settings. Every time and count is scaled by the worker's Maintenance skill.
local cfg = DubzCW.Config

local function snd(ent, name, level, pitch, volume)
	if IsValid(ent) then ent:EmitSound(name, level or 65, pitch or 100, volume or 1) end
end

local function pick(list) return list[math.random(#list)] end

-- (steady: the camera only shakes when the settings say so)
local function punch(ply, angle)
	if cfg.ViewShake and IsValid(ply) then ply:ViewPunch(angle) end
end

-- What working on it sounds and feels like: a push every second (a viewpunch and a sound), like the original pack
local WORK = {
	leak = {
		punch = Angle(0, 0, 3), sounds = {"physics/metal/metal_box_strain1.wav", "physics/metal/metal_box_strain2.wav", "physics/metal/metal_box_strain3.wav", "physics/metal/metal_box_strain4.wav"},
		finish = {"physics/metal/metal_grenade_impact_soft1.wav", "physics/metal/metal_grenade_impact_soft2.wav", "physics/metal/metal_grenade_impact_soft3.wav"},
	},
	hydrant = {
		punch = Angle(0, 0, 5), sounds = {"physics/metal/metal_box_strain1.wav", "physics/metal/metal_box_strain2.wav", "physics/metal/metal_box_strain3.wav", "physics/metal/metal_box_strain4.wav"},
		finish = {"physics/metal/metal_box_strain1.wav", "physics/metal/metal_box_strain3.wav"},
	},
	rubble = {
		punch = Angle(-5, 1, 0), sounds = {"physics/concrete/boulder_impact_hard1.wav", "physics/concrete/boulder_impact_hard2.wav", "physics/concrete/boulder_impact_hard3.wav", "physics/metal/metal_canister_impact_hard1.wav", "physics/metal/metal_canister_impact_hard2.wav"},
		finish = {"physics/concrete/boulder_impact_hard4.wav", "physics/metal/metal_canister_impact_hard3.wav"},
	},
}

-- A hold step on a spot: the time is the one chosen when the job began
local function holdStep(kind, tool, text, hint, up, radius)
	return {
		kind = "hold", tool = tool,
		text = text,
		hint = hint,
		prompt = "hold left click (" .. tool .. ")",
		seconds = function(task) return task.data.seconds end,
		zones = function(task) return {{pos = task.target:GetPos() + Vector(0, 0, up), radius = radius}} end,
		workEvery = 1,
		workSound = function(ply, task)
			local work = WORK[kind]

			punch(ply, work.punch)
			snd(task.target, pick(work.sounds), 70)
		end,
		onDone = function(task)
			local work = WORK[kind]

			task.target:SetWorking(false)
			punch(task.worker, work.punch * 2)
			snd(task.target, pick(work.finish), 72)
		end,
	}
end

-- A task for a spot that is worked on with one long hold
local function simple(def)
	local T = {id = def.id, name = def.name, summary = def.summary}

	function T.Find() return DubzCW.FindSpot(def.id) end

	function T.Begin(task)
		local low, high = cfg[def.min], cfg[def.max]

		task.data.seconds = math.Rand(math.min(low, high), math.max(low, high))
		task.target:SetWorking(true)
	end

	function T.Finish(task)
		if IsValid(task.target) then task.target:SetWorking(false) end
	end

	T.Cleanup = T.Finish
	T.steps = {holdStep(def.id, def.tool, def.text, def.hint, def.up, def.radius)}

	DubzCW.RegisterTask(T)
end

simple({
	id = "leak", name = "Gas leak", min = "LeakMin", max = "LeakMax", tool = "wrench",
	summary = "A gas pipe is leaking. Find it by the hiss and tighten it with the wrench.",
	text = "Tighten the leaking pipe", hint = "Hold left click on the leak with the wrench", up = 0, radius = 26,
})

-- The fire hydrant: a wrench sits on the nut on top; hold left click and move the mouse in circles to turn it (clockwise) ----------------------------

local hydrant = {
	id = "hydrant", name = "Fire hydrant repair",
	summary = "A fire hydrant is spraying water. Put the wrench on the nut and turn it until the water stops.",
}

function hydrant.Find() return DubzCW.FindSpot("hydrant") end

local function hydrantTop(task) return task.target:GetPos() + Vector(0, 0, cfg.HydrantTopZ) end

function hydrant.Begin(task)
	task.target:SetWorking(true)
end

-- The wrench goes onto the nut the first time the worker clicks on it with the wrench (the step's onStart)
local function putWrenchOn(task)
	local wrench = ents.Create("prop_dynamic")
	if not IsValid(wrench) then return end

	wrench:SetModel(cfg.HydrantWrenchModel)
	wrench:SetModelScale(cfg.HydrantWrenchScale, 0)
	wrench:SetPos(hydrantTop(task))
	wrench:Spawn()
	wrench:SetSolid(SOLID_NONE)

	-- (it turns about its jaw end: the end of the model's length that is the jaw, in the model's own space)
	local mins, maxs = wrench:GetModelBounds()
	task.data.jaw = (cfg.HydrantWrenchFlip and mins.x or maxs.x) * cfg.HydrantWrenchScale
	task.data.wrench = wrench

	snd(task.target, "physics/metal/metal_solid_impact_hard" .. math.random(1, 3) .. ".wav", 66, 110)
end

-- (every tick: the wrench follows the turn of the mouse, its jaw staying on the nut)
function hydrant.Animate(task)
	local wrench = task.data.wrench
	if not IsValid(wrench) then return end

	local ang = Angle(0, task.target:GetAngles().y + cfg.HydrantWrenchYaw - math.deg(task.turn.acc), 0)

	wrench:SetAngles(ang)
	wrench:SetPos(hydrantTop(task) + ang:Forward() * (cfg.HydrantWrenchReach - task.data.jaw) + ang:Right() * cfg.HydrantWrenchSide)
end

function hydrant.Finish(task)
	if IsValid(task.target) then task.target:SetWorking(false) end
	if IsValid(task.data.wrench) then task.data.wrench:Remove() end
end

hydrant.Cleanup = hydrant.Finish

hydrant.steps = {{
	kind = "turn", tool = "wrench",
	text = "Turn the wrench to shut off the water",
	hint = "Hold left click on the hydrant and move the mouse in circles (clockwise)",
	prompt = "hold left click, circle the mouse",
	turns = function() return cfg.HydrantTurns end,
	onStart = putWrenchOn,
	zones = function(task) return {{pos = hydrantTop(task), radius = 34}} end,
	workSound = function(ply, task)
		snd(task.target, "physics/metal/metal_solid_impact_soft" .. math.random(1, 3) .. ".wav", 62, math.random(115, 140))
	end,
	onDone = function(task)
		task.target:SetWorking(false)
		snd(task.target, pick(WORK.hydrant.finish), 72)
	end,
}}

DubzCW.RegisterTask(hydrant)

-- Rubble: every click of the shovel is a scoop, and the pile gets smaller ---------------------------------------------------------------------------

local rubble = {
	id = "rubble", name = "Rubble clearing",
	summary = "A pile of rubble is blocking the street. Shovel it away: click to scoop up the debris.",
}

function rubble.Find() return DubzCW.FindSpot("rubble") end

function rubble.Begin(task)
	task.target:SetWorking(true)
end

function rubble.Finish(task)
	if IsValid(task.target) then task.target:SetWorking(false) end
end

rubble.Cleanup = rubble.Finish

rubble.steps = {{
	kind = "scoop", tool = "shovel",
	text = "Shovel the rubble away",
	hint = "Click on the pile with the shovel: every click is a scoop",
	prompt = "left click (shovel)",
	count = function(task) return math.max(math.ceil(cfg.RubbleScoops * DubzCW.TimeFactor(task.worker)), 1) end,
	zones = function(task) return {{pos = task.target:GetPos() + Vector(0, 0, 20), radius = 44}} end,
	onScoop = function(task, done, total)
		local target = task.target

		-- The pile shrinks with every scoop
		target:SetModelScale(math.max(1 - 0.9 * done / total, 0.1), 0.35)

		local effect = EffectData()
		effect:SetOrigin(target:GetPos() + Vector(0, 0, 8))
		effect:SetNormal(Vector(0, 0, 1))
		effect:SetScale(1.5)
		util.Effect("WheelDust", effect)

		-- The blade goes in, then the load is thrown aside
		snd(target, "physics/concrete/rock_impact_hard" .. math.random(1, 6) .. ".wav", 68, math.random(90, 110))

		timer.Simple(0.4, function()
			if IsValid(target) then snd(target, "physics/concrete/concrete_impact_soft" .. math.random(1, 3) .. ".wav", 64, math.random(85, 105)) end
		end)
	end,
	onDone = function(task)
		snd(task.target, pick(WORK.rubble.finish), 72)
	end,
}}

DubzCW.RegisterTask(rubble)

-- The electrical fault: three steps -------------------------------------------------------------------------------------------------------------

local electric = {
	id = "electric", name = "Electrical fault",
	summary = "A light is sparking. Pull the wires out, twist them back together and push them in again.",
}

function electric.Find() return DubzCW.FindSpot("electric") end

function electric.Begin(task)
	task.target:SetWorking(true)
end

function electric.Finish(task)
	if IsValid(task.target) then task.target:SetWorking(false) end
end

electric.Cleanup = electric.Finish

local function wireZone(task) return {{pos = task.target:GetPos(), radius = 20}} end

electric.steps = {
	{
		kind = "click", tool = "pliers",
		text = "Pull the live wires out",
		hint = "One click on the sparks with the pliers",
		prompt = "left click (pliers)",
		zones = wireZone,
		onDone = function(task)
			local effect = EffectData()
			effect:SetOrigin(task.target:GetPos())
			effect:SetMagnitude(4)
			effect:SetScale(2)
			effect:SetRadius(6)
			util.Effect("ElectricSpark", effect)

			snd(task.target, "physics/plastic/plastic_box_break" .. math.random(1, 2) .. ".wav", 68)
			snd(task.target, "ambient/energy/zap" .. math.random(5, 9) .. ".wav", 70)
		end,
	},
	{
		kind = "scoop", tool = "pliers",
		text = "Twist the wires back together",
		hint = "Click on the wires with the pliers a few times",
		prompt = "left click (pliers)",
		count = function(task) return math.max(math.ceil(cfg.ElectricTwistClicks * DubzCW.TimeFactor(task.worker)), 1) end,
		zones = wireZone,
		onScoop = function(task)
			-- (a twist: a small spark and a squeak of metal)
			local effect = EffectData()
			effect:SetOrigin(task.target:GetPos())
			effect:SetMagnitude(1)
			effect:SetScale(1)
			effect:SetRadius(2)
			util.Effect("ElectricSpark", effect)

			snd(task.target, "physics/metal/metal_computer_impact_hard" .. math.random(1, 3) .. ".wav", 62, math.random(105, 130))
		end,
		onDone = function(task)
			-- Joined: the sparks stop
			task.target:SetWorking(false)
			snd(task.target, "ambient/energy/weld" .. math.random(1, 2) .. ".wav", 68)
		end,
	},
	{
		kind = "use",
		text = "Push the wires back into the casing",
		hint = "Press E at the wires",
		prompt = "press E to push them back",
		zones = wireZone,
		onDone = function(task)
			snd(task.target, "ambient/energy/whiteflash.wav", 62, 130)
			snd(task.target, "physics/plastic/plastic_box_impact_hard" .. math.random(1, 4) .. ".wav", 62)
		end,
	},
}

DubzCW.RegisterTask(electric)
