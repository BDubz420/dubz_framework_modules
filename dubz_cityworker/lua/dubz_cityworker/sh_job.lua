-- The City Worker job and its parts in the F4 menu, made for DarkRP on its own hook for custom items (so nothing is needed in DarkRP's files).
-- Switch "Create The DarkRP Job" off in the admin menu to define the job yourself; the job command is how the addon finds its workers.
local cfg = DubzCW.Config

hook.Add("loadCustomDarkRPItems", "DubzCW_Job", function()
	if not DarkRP then return end

	if cfg.RegisterJob and DarkRP.createJob then
		-- (the model is a placeholder: the character system keeps each player's own model, jobs do not change it)
		DubzCW.TeamIndex = DarkRP.createJob(cfg.JobName, {
			color = cfg.JobColor,
			model = {"models/player/Group01/male_07.mdl"},
			description = cfg.JobDescription,
			weapons = DubzCW.ToolList(),
			command = cfg.JobCommand,
			max = cfg.JobMax,
			salary = cfg.JobSalary,
			admin = 0,
			vote = false,
			hasLicense = false,
			candemote = false,
			category = cfg.JobCategory,
		})
	end

	-- The replacement parts: a category in the F4 menu (only City Workers see it unless the setting is off)
	if DarkRP.createCategory and DarkRP.createEntity then
		DarkRP.createCategory{
			name = "Repair Parts",
			categorises = "entities",
			startExpanded = true,
			color = Color(35, 35, 35),
			sortOrder = 11,
			canSee = function(ply) return not cfg.PartsWorkersOnly or DubzCW.IsWorker(ply) end,
		}

		DarkRP.createEntity("Wood Plank", {
			ent = "dubz_cw_plank",
			model = cfg.PlankModel,
			price = cfg.PlankPrice,
			max = cfg.PlankMax,
			cmd = "buywoodplank",
			category = "Repair Parts",
		})

		DarkRP.createEntity("Replacement Circuit Board", {
			ent = "dubz_circuit_board",
			model = cfg.BoardModel,
			price = cfg.PartPrice,
			max = cfg.PartMax,
			cmd = "buycircuitboard",
			category = "Repair Parts",
		})
	end
end)
