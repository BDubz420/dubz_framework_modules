-- Registers the City Worker with the Dubz Framework: the job, the jobs on offer and their pay, the tools, and the repair settings.
local cfg = DubzCW.Config

DFW.Bind.Module({
	id = "cityworker",
	name = "City Worker",
	version = "1.0.0",
	icon = "action/build",
	description = "A repair job: workers are sent to broken machines and fix them step by step with a wrench and pliers, with parts from the F4 menu.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "RegisterJob", label = "Create The DarkRP Job", group = "Job", description = "Off: define the job yourself in DarkRP; the Job Command below is how workers are found. Changes need a restart."},
	{path = "JobName", label = "Job Name", group = "Job", maxLength = 40},
	{path = "JobCommand", label = "Job Command", group = "Job", maxLength = 30, description = "The chat command of the job (/cityworker). The Job Sites table of the Jobs addon hires for this command."},
	{path = "JobColor", label = "Job Colour", group = "Job"},
	{path = "JobSalary", label = "Salary", min = 0, max = 10000, decimals = 0, group = "Job"},
	{path = "JobMax", label = "Most Workers", min = 1, max = 64, decimals = 0, group = "Job"},
	{path = "JobCategory", label = "F4 Category", group = "Job", maxLength = 40},
	{path = "JobDescription", label = "Description", group = "Job", maxLength = 300},
	{path = "JobWeapons", label = "Job Tools", list = true, group = "Job", maxLength = 200, description = "Weapon classes the job hands out, comma separated."},

	{path = "AssignSeconds", label = "Next Job After (Seconds)", min = 3, max = 600, decimals = 0, group = "Getting Work", description = "A free worker is given the next job this long after finishing one (or starting work)."},
	{path = "TaskMinutes", label = "Give Up A Job After (Minutes)", min = 1, max = 120, decimals = 0, group = "Getting Work", description = "A job nobody finished in this time is given up and the machine is put back as it was."},
	{path = "MarkerDistance", label = "Marker Goes Away Within", min = 50, max = 3000, decimals = 0, group = "Getting Work", description = "Units: the marker to the job is shown until the worker is this close."},

	{path = "InteractDistance", label = "Work Distance", min = 60, max = 300, decimals = 0, group = "Working"},
	{path = "WrenchSeconds", label = "Wrench Hold (Seconds)", min = 0.5, max = 30, decimals = 1, group = "Working"},
	{path = "PliersSeconds", label = "Pliers Hold (Seconds)", min = 0.5, max = 30, decimals = 1, group = "Working"},
	{path = "HighlightColor", label = "Highlight Colour", group = "Working", description = "The glow on the spot or part to use next."},
	{path = "WorkSound", label = "Tool Sounds", group = "Working"},

	{path = "ScrapId", label = "Old Board Scrap (Material Id)", group = "Rewards", maxLength = 30, description = "The old circuit board comes apart into this Dubz Scrap material when it is cut out (the worker picks it up). Empty = the board itself drops."},
	{path = "ScrapMin", label = "Scrap At Least", min = 0, max = 20, decimals = 0, group = "Rewards"},
	{path = "ScrapMax", label = "Scrap At Most", min = 0, max = 20, decimals = 0, group = "Rewards"},

	{path = "LeakMin", label = "Gas Leak Time At Least (Seconds)", min = 1, max = 120, decimals = 0, group = "Street Jobs"},
	{path = "LeakMax", label = "Gas Leak Time At Most (Seconds)", min = 1, max = 120, decimals = 0, group = "Street Jobs"},
	{path = "HydrantTurns", label = "Fire Hydrant: Turns Of The Wrench", min = 1, max = 20, decimals = 1, group = "Street Jobs", description = "Hold left click on the wrench on top of the hydrant and move the mouse in circles. This many full turns (at the base speed)."},
	{path = "HydrantWrenchModel", label = "Hydrant Wrench Model", group = "Street Jobs", maxLength = 120},
	{path = "HydrantWrenchScale", label = "Hydrant Wrench Size", min = 0.5, max = 4, decimals = 2, group = "Street Jobs"},
	{path = "HydrantTopZ", label = "Hydrant Top Height (Units)", min = 10, max = 100, decimals = 1, group = "Street Jobs", description = "How high the wrench sits above the base of the hydrant."},
	{path = "HydrantWrenchReach", label = "Wrench Shift Along Its Length", min = -30, max = 30, decimals = 1, group = "Street Jobs", description = "The wrench turns about its jaw end, set on the nut. This slides it along its length from there."},
	{path = "HydrantWrenchSide", label = "Wrench Shift Across Its Length", min = -30, max = 30, decimals = 1, group = "Street Jobs", description = "Slides the wrench sideways, the other way to the shift along its length. Both move it with the wrench's own turn."},
	{path = "HydrantWrenchFlip", label = "Wrench Jaw At The Other End", group = "Street Jobs", description = "Turn on if the wrench turns about the wrong end."},
	{path = "HydrantWrenchYaw", label = "Wrench Starting Angle", min = -180, max = 180, decimals = 0, group = "Street Jobs"},
	{path = "RubbleScoops", label = "Rubble: Scoops To Clear A Pile", min = 1, max = 60, decimals = 0, group = "Street Jobs", description = "Clicks of the shovel (at the base speed)."},
	{path = "ViewShake", label = "Camera Shake While Working", group = "Working"},
	{path = "ElectricTwistClicks", label = "Electrical: Clicks To Twist The Wires", min = 1, max = 30, decimals = 0, group = "Street Jobs", description = "Clicks of the pliers (at the base speed)."},
	{path = "HydrantModel", label = "Fire Hydrant Model", group = "Street Jobs", maxLength = 120},
	{path = "RubbleModels", label = "Rubble Models", list = true, group = "Street Jobs", description = "One is picked for each pile. Comma separated; the box holds about 200 characters, so three or four models."},

	{path = "BenchModel", label = "Bench Model", group = "Bench Job", maxLength = 120, description = "The bench the placer puts down: use the model of the benches in your map."},
	{path = "PlankModel", label = "Plank Model", group = "Bench Job", maxLength = 120, description = "Changes need a restart to reach the F4 menu."},
	{path = "PlankPrice", label = "Plank Price", min = 0, max = 100000, decimals = 0, group = "Bench Job", description = "Changes need a restart to reach the F4 menu."},
	{path = "PlankMax", label = "Planks Per Worker", min = 1, max = 20, decimals = 0, group = "Bench Job"},
	{path = "BenchTilt", label = "Broken Bench Lean (Degrees)", min = 0, max = 60, decimals = 0, group = "Bench Job"},
	{path = "BenchSink", label = "Broken Bench Sag (Units)", min = 0, max = 30, decimals = 1, group = "Bench Job"},
	{path = "NailSeconds", label = "Nail Time (Seconds)", min = 0.3, max = 10, decimals = 1, group = "Bench Job"},
	{path = "BenchOffX", label = "Plank Along The Bench", min = -100, max = 100, decimals = 1, group = "Bench Job", description = "Moves the place the new plank goes, from the middle of the seat (bench space: length, width, up)."},
	{path = "BenchOffY", label = "Plank Across The Bench", min = -100, max = 100, decimals = 1, group = "Bench Job"},
	{path = "BenchOffZ", label = "Plank Up", min = -100, max = 100, decimals = 1, group = "Bench Job"},

	{path = "PartPrice", label = "Circuit Board Price", min = 0, max = 100000, decimals = 0, group = "Parts", description = "Changes need a restart to reach the F4 menu."},
	{path = "PartMax", label = "Circuit Boards Per Worker", min = 1, max = 20, decimals = 0, group = "Parts"},
	{path = "PartsWorkersOnly", label = "Only Workers See The Parts", group = "Parts"},

	{path = "PullOutDistance", label = "Slide Out From The Wall (Units)", min = 0, max = 80, decimals = 0, group = "Vending Machine Job", description = "The machine slides straight out this far before it swings, so it clears the wall beside it."},
	{path = "SwingSide", label = "Swing Side", choices = {"left", "right"}, group = "Vending Machine Job", description = "Which way the machine swings out (the glowing edge is on the other side)."},
	{path = "SwingDegrees", label = "Machine Swing (Degrees)", min = 20, max = 120, decimals = 0, group = "Vending Machine Job"},
	{path = "SwingSeconds", label = "Swing Time (Seconds)", min = 0.3, max = 6, decimals = 1, group = "Vending Machine Job"},
	{path = "CarryAwayDistance", label = "Carry The Plate Away (Units)", min = 20, max = 300, decimals = 0, group = "Vending Machine Job"},
	{path = "SnapDistance", label = "Click Into Place Within (Units)", min = 6, max = 60, decimals = 0, group = "Vending Machine Job"},
	{path = "Sparks", label = "Broken Board Sparks", group = "Vending Machine Job"},
	{path = "PlateModel", label = "Back Plate Model", group = "Vending Machine Job", maxLength = 120},
	{path = "PlateMaterial", label = "Back Plate Material", group = "Vending Machine Job", maxLength = 120},
	{path = "PlateColor", label = "Back Plate Colour", group = "Vending Machine Job"},
	{path = "PlateGap", label = "Plate Distance Behind The Machine", min = 0, max = 30, decimals = 1, group = "Vending Machine Job"},
	{path = "BoardModel", label = "Circuit Board Model", group = "Vending Machine Job", maxLength = 120, description = "Changes need a restart to reach the F4 menu."},
	{path = "BoardSize", label = "Circuit Board Size (Units)", min = 6, max = 100, decimals = 0, group = "Vending Machine Job"},
	{path = "BoardGap", label = "Board Distance Behind The Machine", min = 0, max = 20, decimals = 1, group = "Vending Machine Job"},
	{path = "BoardFlip", label = "Turn The Circuit Board Round", group = "Vending Machine Job", description = "On if the board's face points into the machine."},
	{path = "PlateFit", label = "Plate Size", min = 0.3, max = 1.5, decimals = 2, group = "Vending Machine Job", description = "1 = as tall as the machine."},
	{path = "BoltInset", label = "Bolts In From The Corners", min = 0, max = 30, decimals = 1, group = "Vending Machine Job"},
	{path = "BoltSeconds", label = "Bolt Time (Seconds)", min = 0.2, max = 10, decimals = 1, group = "Vending Machine Job"},
	{path = "BoltRadius", label = "Bolt Aim Size (Units)", min = 2, max = 30, decimals = 1, group = "Vending Machine Job"},
	{path = "SpotSize", label = "Glowing Dot Size (Units)", min = 1, max = 40, decimals = 1, group = "Vending Machine Job"},

	{path = "SkillXPPerJob", label = "Maintenance XP Per Job", min = 0, max = 100000, decimals = 0, group = "Maintenance Skill", description = "Added to the worker's Maintenance skill when a job is finished."},
	{path = "SkillXPBase", label = "XP For The First Level", min = 10, max = 100000, decimals = 0, group = "Maintenance Skill", description = "Changes need a restart."},
	{path = "SkillXPExponent", label = "Level Curve", min = 0.5, max = 3, decimals = 2, group = "Maintenance Skill", description = "Changes need a restart."},
	{path = "SkillTimeAt0", label = "Time At Level 0 (x)", min = 0.2, max = 5, decimals = 2, group = "Maintenance Skill", description = "Every hold, bolt, wrench turn and shovel scoop takes this many times its normal time for a new worker."},
	{path = "SkillTimeAt10", label = "Time At Level 10 (x)", min = 0.2, max = 5, decimals = 2, group = "Maintenance Skill"},
	{path = "SkillPayAt0", label = "Pay At Level 0 (x)", min = 0, max = 5, decimals = 2, group = "Maintenance Skill", description = "The task's payout is multiplied by this for a new worker."},
	{path = "SkillPayAt10", label = "Pay At Level 10 (x)", min = 0, max = 5, decimals = 2, group = "Maintenance Skill"},

	{path = "ShovelHandX", label = "Shovel: Forward", min = -40, max = 40, decimals = 1, group = "Dial In: Shovel", description = "Where the shovel sits in the hand, as others see it (change and look at yourself in third person)."},
	{path = "ShovelHandY", label = "Shovel: Right", min = -40, max = 40, decimals = 1, group = "Dial In: Shovel"},
	{path = "ShovelHandZ", label = "Shovel: Up", min = -40, max = 40, decimals = 1, group = "Dial In: Shovel"},
	{path = "ShovelHandP", label = "Shovel: Pitch", min = -180, max = 180, decimals = 0, group = "Dial In: Shovel"},
	{path = "ShovelHandYaw", label = "Shovel: Yaw", min = -180, max = 180, decimals = 0, group = "Dial In: Shovel"},
	{path = "ShovelHandR", label = "Shovel: Roll", min = -180, max = 180, decimals = 0, group = "Dial In: Shovel"},

	{path = "EdgeOffX", label = "Edge: Forward", min = -100, max = 100, decimals = 1, group = "Dial In: Edge", description = "The glowing edge you press E at. Moves are in the machine's own space: forward, left, up. They apply while a job runs; say !cwvalues to print the numbers."},
	{path = "EdgeOffY", label = "Edge: Left", min = -100, max = 100, decimals = 1, group = "Dial In: Edge"},
	{path = "EdgeOffZ", label = "Edge: Up", min = -100, max = 100, decimals = 1, group = "Dial In: Edge"},
	{path = "PlateOffX", label = "Plate: Forward", min = -100, max = 100, decimals = 1, group = "Dial In: Plate", description = "The back plate (and where its four bolts are)."},
	{path = "PlateOffY", label = "Plate: Left", min = -100, max = 100, decimals = 1, group = "Dial In: Plate"},
	{path = "PlateOffZ", label = "Plate: Up", min = -100, max = 100, decimals = 1, group = "Dial In: Plate"},
	{path = "PlateAngP", label = "Plate: Pitch", min = -180, max = 180, decimals = 0, group = "Dial In: Plate"},
	{path = "PlateAngY", label = "Plate: Yaw", min = -180, max = 180, decimals = 0, group = "Dial In: Plate"},
	{path = "PlateAngR", label = "Plate: Roll", min = -180, max = 180, decimals = 0, group = "Dial In: Plate"},
	{path = "BoardOffX", label = "Board: Forward", min = -100, max = 100, decimals = 1, group = "Dial In: Circuit Board", description = "The circuit board behind the plate."},
	{path = "BoardOffY", label = "Board: Left", min = -100, max = 100, decimals = 1, group = "Dial In: Circuit Board"},
	{path = "BoardOffZ", label = "Board: Up", min = -100, max = 100, decimals = 1, group = "Dial In: Circuit Board"},
	{path = "BoardAngP", label = "Board: Pitch", min = -180, max = 180, decimals = 0, group = "Dial In: Circuit Board"},
	{path = "BoardAngY", label = "Board: Yaw", min = -180, max = 180, decimals = 0, group = "Dial In: Circuit Board"},
	{path = "BoardAngR", label = "Board: Roll", min = -180, max = 180, decimals = 0, group = "Dial In: Circuit Board"},
}, {
	collections = {
		{
			id = "tasks", label = "Tasks", idKey = "id",
			description = "The jobs a worker can be given. The Id is the task's own (vending = the vending machine repair); Payout is the cash for finishing it; Weight is how likely it is to be the next one (higher = more often). Switch a task off to stop it being given.",
			columns = {
				{key = "id", label = "Id", type = "string", width = 1.2, maxLength = 30},
				{key = "name", label = "Name", type = "string", width = 2, maxLength = 60},
				{key = "enabled", label = "On", type = "bool", width = 0.6},
				{key = "payout", label = "Payout", type = "number", min = 0, max = 1000000, decimals = 0, width = 1},
				{key = "weight", label = "Weight", type = "number", min = 1, max = 100, decimals = 0, width = 0.8},
			},
			default = DubzCW.DefaultTasks,
		},
	},
})

DFW.Collections.Watch("cityworker", "tasks", function(rows)
	-- (a task added in an update is on offer with its default row until the table is edited to say otherwise)
	DubzCW.TaskRows = {}

	for _, row in ipairs(DubzCW.DefaultTasks) do DubzCW.TaskRows[row.id] = row end

	for _, row in ipairs(rows or {}) do
		if row.id and row.id ~= "" then DubzCW.TaskRows[row.id] = row end
	end
end)
