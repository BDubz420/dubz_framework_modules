-- City Worker settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > City Worker) edits them live.
-- The City Worker is a repair job. A worker is handed a job (a broken machine somewhere in the city), gets a marker to it, and has to do the work in
-- steps, with the tools: pull the machine out, take the back off, swap the circuit board, put it all back. The task list is the Tasks table in the
-- admin menu; the first task is the vending machine (the Dubz Vending Machine addon), and more are added the same way (see sv_tasks.lua).
DubzCW = DubzCW or {}

DubzCW.Config = {
	-- The job. It is made for DarkRP here (turn it off to define the job yourself; the command below is how the addon finds the workers).
	RegisterJob = true,
	JobName = "City Worker",
	JobCommand = "cityworker",
	JobColor = Color(20, 150, 20),
	JobSalary = 20,
	JobMax = 6,
	JobCategory = "Citizens",
	JobDescription = "Keeps the city running: you are sent to broken machines, take them apart and fix them with your tools, and get paid for every job.",
	JobWeapons = {"dubz_cw_wrench", "dubz_cw_pliers", "dubz_cw_shovel", "dubz_cw_hammer"},

	-- Getting a job
	AssignSeconds = 25,        -- a free worker is given the next job this long after finishing (or starting work)
	TaskMinutes = 15,          -- a job nobody finished by then is given up (the machine is put back as it was)
	MarkerDistance = 350,      -- the marker to the job is shown until the worker is this close (units)

	-- Working
	InteractDistance = 130,    -- how close the worker must be to a spot to use it
	WrenchSeconds = 4,         -- how long a hold with the wrench takes
	PliersSeconds = 3,         -- how long a hold with the pliers takes
	HighlightColor = Color(255, 200, 60),   -- the glow on the spot or part to use next
	WorkSound = true,          -- tool sounds while holding

	-- What a finished job gives (the payout itself is per task, in the Tasks table)
	ScrapId = "electronics",   -- the old circuit board comes apart into this scrap (Dubz Scrap material id) when it is cut out; empty = the board itself drops
	ScrapMin = 1,              -- pieces of it
	ScrapMax = 2,

	-- The replacement parts (bought in the F4 menu)
	PartPrice = 150,           -- a replacement circuit board
	PartMax = 3,               -- how many one worker can have at a time
	PartsWorkersOnly = true,   -- only City Workers see the parts in the F4 menu

	-- The vending machine job
	PullOutDistance = 22,      -- the machine slides straight out from the wall this far first (so it clears the wall), then swings
	SwingSide = "left",        -- which way it swings: "left" (hinged at its back left corner) or "right"
	SwingDegrees = 65,         -- how far the machine is turned out from the wall
	SwingSeconds = 1.8,        -- how long the slide and the swing take together
	CarryAwayDistance = 70,    -- the back plate has to be carried this far from the machine
	SnapDistance = 16,         -- a part put this close to where it goes clicks into place
	Sparks = true,             -- the broken circuit board sparks
	PlateModel = "models/squad/sf_plates/sf_plate4x8.mdl",
	PlateMaterial = "models/props_combine/metal_combinebridge001",
	PlateColor = Color(67, 60, 40),
	PlateGap = 4,              -- how far behind the machine the plate sits (units)
	BoardModel = "models/props/cs_office/computer_caseb_p7a.mdl",
	BoardSize = 26,            -- the longest side of the circuit board (units): the model is scaled to this
	BoardGap = 1.5,            -- how far behind the machine the circuit board sits
	BoardFlip = false,         -- turn the circuit board round if its face points into the machine
	PlateFit = 1.0,            -- how big the plate is compared with the back of the machine (1 = as tall as the machine)
	BoltInset = 4,             -- the four bolts sit this far in from the corners of the plate (units)
	BoltSeconds = 1.2,         -- how long each bolt takes with the wrench
	BoltRadius = 5,            -- how close to a bolt you must aim (units)
	SpotSize = 6,              -- the size of the glowing dots on the spots to use (units)

	-- Dialling in the spots (the vending machine job). All of these are in the MACHINE's own space, as a move from where the spot starts:
	-- X = forward (out of the front of the machine; negative = towards the back), Y = to the machine's left (negative = right), Z = up.
	-- Angles turn the part. They take effect while a job is running, so change one and watch it move. Say !cwvalues (or run dubz_cw_values) to print them.
	EdgeOffX = 0, EdgeOffY = 0, EdgeOffZ = 0,                 -- the glowing edge you press E at to pull the machine out and push it back
	PlateOffX = 0, PlateOffY = 0, PlateOffZ = 0,              -- the back plate
	PlateAngP = 0, PlateAngY = 0, PlateAngR = 0,
	BoardOffX = 0, BoardOffY = 0, BoardOffZ = 0,              -- the circuit board
	BoardAngP = 0, BoardAngY = 0, BoardAngR = 0,
}

-- The street jobs (placed with the City Worker Placer tool: spots saved for each map), and the bench job
DubzCW.SpotKinds = {
	{id = "leak", name = "Gas leak"},
	{id = "hydrant", name = "Fire hydrant"},
	{id = "rubble", name = "Rubble"},
	{id = "electric", name = "Electrical (a light or a wire box)"},
	{id = "bench", name = "Bench"},
}

DubzCW.Config.LeakMin, DubzCW.Config.LeakMax = 6, 18                   -- how long the wrench is held on a leak (a random time in between)
DubzCW.Config.HydrantTurns = 3                                         -- full turns of the wrench on a fire hydrant (move the mouse in circles)
DubzCW.Config.HydrantWrenchModel = "models/props_c17/tools_wrench01a.mdl"   -- the wrench that sits on top of the hydrant
DubzCW.Config.HydrantWrenchScale = 1.6
DubzCW.Config.HydrantTopZ = 38                                         -- how high the top of the hydrant is above its base (units)
DubzCW.Config.HydrantWrenchReach = 0                                   -- the wrench turns about its jaw end, which sits on the nut; this moves it along its length from there
DubzCW.Config.HydrantWrenchSide = 0                                    -- slides it across its length (the other way to the shift above)
DubzCW.Config.HydrantWrenchFlip = false                               -- on if the jaw of the model is at the other end
DubzCW.Config.HydrantWrenchYaw = 0                                     -- and which way it starts
DubzCW.Config.RubbleScoops = 8                                         -- clicks of the shovel to clear a pile
DubzCW.Config.ViewShake = false                                        -- a little camera shake while working (off: steady)

-- The shovel in the hand (the world model; dial in with the admin menu, Dial In: Shovel): forward, right, up and pitch, yaw, roll
DubzCW.Config.ShovelHandX, DubzCW.Config.ShovelHandY, DubzCW.Config.ShovelHandZ = 2, 0, -2
DubzCW.Config.ShovelHandP, DubzCW.Config.ShovelHandYaw, DubzCW.Config.ShovelHandR = 0, 180, 90

-- The Maintenance skill (per character, in the skills menu). A worker with none is slow and paid less; at level 10 fast and paid more.
-- The time of every hold, bolt, turn and scoop is multiplied by the first number at level 0 and the second at level 10, the pay likewise.
DubzCW.Config.SkillXPPerJob = 120
DubzCW.Config.SkillXPBase = 700
DubzCW.Config.SkillXPExponent = 1.2
DubzCW.Config.SkillTimeAt0, DubzCW.Config.SkillTimeAt10 = 1.4, 0.7
DubzCW.Config.SkillPayAt0, DubzCW.Config.SkillPayAt10 = 0.8, 1.5
DubzCW.Config.ElectricTwistClicks = 4                                  -- clicks of the pliers to twist the wires back together
DubzCW.Config.HydrantModel = "models/props/cs_assault/firehydrant.mdl"
DubzCW.Config.RubbleModels = {"models/props_debris/concrete_debris128pile001a.mdl", "models/props_debris/concrete_floorpile01a.mdl", "models/props_debris/plaster_ceilingpile001a.mdl"}   -- (a list setting holds 200 characters at most)
DubzCW.Config.BenchModel = "models/props_trainstation/bench_indoor001a.mdl"   -- the bench the placer puts down (use the model of the benches in your map)
DubzCW.Config.PlankModel = "models/props_debris/wood_board04a.mdl"            -- the wood plank (and the broken pieces)
DubzCW.Config.PlankPrice = 60
DubzCW.Config.PlankMax = 3
DubzCW.Config.BenchTilt = 14                                           -- how far the broken bench leans (degrees)
DubzCW.Config.BenchSink = 5                                            -- and how far it sags (units)
DubzCW.Config.NailSeconds = 1.6                                        -- each of the four nails with the hammer
DubzCW.Config.BenchOffX, DubzCW.Config.BenchOffY, DubzCW.Config.BenchOffZ = 0, 0, 0   -- where the new plank goes, moved from the middle of the seat (bench space: x length, y width, z up)

-- The jobs on offer: id (the task's own id), name, enabled, payout (cash for finishing it), weight (how likely it is to be picked next). More tasks are
-- added in their own file with DubzCW.RegisterTask; a row with the same id switches it and sets its pay.
DubzCW.DefaultTasks = {
	{id = "vending", name = "Vending machine repair", enabled = true, payout = 450, weight = 1},
	{id = "leak", name = "Gas leak", enabled = true, payout = 220, weight = 2},
	{id = "hydrant", name = "Fire hydrant repair", enabled = true, payout = 320, weight = 2},
	{id = "rubble", name = "Rubble clearing", enabled = true, payout = 380, weight = 2},
	{id = "electric", name = "Electrical fault", enabled = true, payout = 260, weight = 2},
	{id = "bench", name = "Broken bench", enabled = true, payout = 520, weight = 1},
}

DubzCW.TaskRows = {}
for _, row in ipairs(DubzCW.DefaultTasks) do DubzCW.TaskRows[row.id] = row end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzCW.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("cityworker")
end

-- The Maintenance skill ------------------------------------------------------------------------------------------------------------------------------

function DubzCW.SkillLevel(ply)
	if IsValid(ply) and DubzSkills and DubzSkills.GetLevel then return math.Clamp(DubzSkills.GetLevel(ply, "maintenance") or 0, 0, 10) end

	return 0
end

-- What a level does: the multiplier on the time of every task, and on its pay
function DubzCW.TimeAt(level)
	local cfg = DubzCW.Config

	return math.max(Lerp(level / 10, cfg.SkillTimeAt0, cfg.SkillTimeAt10), 0.2)
end

function DubzCW.PayAt(level)
	local cfg = DubzCW.Config

	return math.max(Lerp(level / 10, cfg.SkillPayAt0, cfg.SkillPayAt10), 0)
end

function DubzCW.TimeFactor(ply) return DubzCW.TimeAt(DubzCW.SkillLevel(ply)) end
function DubzCW.PayFactor(ply) return DubzCW.PayAt(DubzCW.SkillLevel(ply)) end

-- (skills register on Initialize because the skills addon loads after this one)
function DubzCW.RegisterSkill()
	if not (DubzSkills and DubzSkills.Register) then return end

	local cfg = DubzCW.Config

	DubzSkills.Register({
		id = "maintenance", category = "industry", name = "Maintenance",
		desc = "Every repair teaches you more. A new worker is slow and paid less; a practised one finishes jobs faster and is paid more for them.",
		maxLevel = 10, xpBase = cfg.SkillXPBase, xpExponent = cfg.SkillXPExponent,
		effect = function(level)
			return "Jobs take " .. math.floor(DubzCW.TimeAt(level) * 100) .. "% of the usual time, pay " .. math.floor(DubzCW.PayAt(level) * 100) .. "%"
		end,
	})
end

hook.Add("Initialize", "DubzCW_Skill", DubzCW.RegisterSkill)
if DubzSkills then DubzCW.RegisterSkill() end

-- The tools a worker always has, whatever list was saved in the settings before a tool was added
DubzCW.RequiredTools = {"dubz_cw_wrench", "dubz_cw_pliers", "dubz_cw_shovel", "dubz_cw_hammer"}

function DubzCW.ToolList()
	local list, seen = {}, {}

	for _, class in ipairs(DubzCW.Config.JobWeapons or {}) do
		if not seen[class] then seen[class] = true list[#list + 1] = class end
	end

	for _, class in ipairs(DubzCW.RequiredTools) do
		if not seen[class] then seen[class] = true list[#list + 1] = class end
	end

	return list
end

-- Is this player a City Worker (holding the job)?
function DubzCW.IsWorker(ply)
	if not (IsValid(ply) and ply:IsPlayer()) then return false end

	local job = RPExtraTeams and RPExtraTeams[ply:Team()]

	return job ~= nil and job.command == DubzCW.Config.JobCommand
end
