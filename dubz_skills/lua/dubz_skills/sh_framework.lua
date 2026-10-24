-- Registers Skills with the Dubz Framework: every setting in sh_config.lua appears in the admin config menu
-- (!dubzconfig), grouped below. The values in sh_config.lua stay the defaults; the menu overrides them live.
-- This file is loaded by the framework (see the manifest at the bottom of lua/autorun/dubz_skills.lua).
DFW.Bind.Module({
	id = "skills",
	name = "Skills",
	version = "1.0.0",
	icon = "misc/bolt",
	description = "Skill sheet, overall level, walking/running speed and stamina.",
	dependencies = {"dubz_core"},
}, DubzSkills.Config, {
	-- Menu
	{path = "openKey", label = "Menu Key", keybind = true, group = "Menu", description = "Opens and closes the skills menu."},
	{path = "chatCommands", label = "Chat Commands", list = true, group = "Menu", description = "Comma separated, for example: /skills, !skills"},

	-- Overall level
	{path = "overallXPBase", label = "Overall XP Base", min = 500, max = 20000, group = "Overall Level",
		description = "XP from level L-1 to L is Base x (L-1) ^ Exponent. Higher = slower overall levelling."},
	{path = "overallXPExponent", label = "Overall XP Exponent", min = 1, max = 3, decimals = 2, group = "Overall Level"},
	{path = "maxOverallLevel", label = "Max Overall Level", min = 5, max = 100, decimals = 0, group = "Overall Level"},

	-- Skill levelling
	{path = "xpBase", label = "Skill XP Base", min = 100, max = 3000, group = "Skill Levelling",
		description = "Default curve for skills that don't set their own (walking and running do)."},
	{path = "xpExponent", label = "Skill XP Exponent", min = 1, max = 3, decimals = 2, group = "Skill Levelling"},

	-- Level-up sounds
	{path = "levelUpSounds", label = "Level-Up Dings", group = "Sounds", description = "The ding when a skill or your overall level goes up."},
	{path = "breathSounds", label = "Breathing Sounds", group = "Sounds", description = "The heavy breathing when you run out of stamina."},
	{path = "levelUpSound", label = "Level Up Sound", group = "Sounds"},
	{path = "overallLevelUpSound", label = "Overall Level Up Sound", group = "Sounds"},
	{path = "soundLevel", label = "Level Up Sound Radius", min = 50, max = 120, decimals = 0, group = "Sounds",
		description = "How far the level-up sound carries (sound level, 75 = a few metres)."},

	-- Movement
	{path = "movement.enabled", label = "Movement Skills Enabled", group = "Movement",
		description = "Turns walking/running speed control and its XP off completely."},
	{path = "movement.baseWalk", label = "Base Walk Speed", min = 50, max = 250, decimals = 0, group = "Movement"},
	{path = "movement.walkPerLevel", label = "Walk Speed Per Level", min = 0, max = 10, decimals = 1, group = "Movement"},
	{path = "movement.baseRun", label = "Base Run Speed", min = 100, max = 400, decimals = 0, group = "Movement"},
	{path = "movement.runPerLevel", label = "Run Speed Per Level", min = 0, max = 10, decimals = 1, group = "Movement"},
	{path = "movement.walkXPPerSecond", label = "Walking XP Per Second", min = 0, max = 5, decimals = 2, group = "Movement"},
	{path = "movement.runXPPerSecond", label = "Running XP Per Second", min = 0, max = 5, decimals = 2, group = "Movement"},

	-- Stamina
	{path = "stamina.enabled", label = "Stamina Enabled", group = "Stamina"},
	{path = "stamina.max", label = "Max Stamina", min = 20, max = 500, decimals = 0, group = "Stamina"},
	{path = "stamina.drainPerSecond", label = "Drain Per Second (Running)", min = 0, max = 30, decimals = 1, group = "Stamina"},
	{path = "stamina.drainReductionPerLevel", label = "Drain Reduction Per Running Level", min = 0, max = 0.1, decimals = 3, group = "Stamina",
		description = "0.05 = each Running level makes stamina drain 5% slower."},
	{path = "stamina.regenIdle", label = "Regen Per Second (Standing)", min = 0, max = 50, decimals = 1, group = "Stamina"},
	{path = "stamina.regenMoving", label = "Regen Per Second (Walking)", min = 0, max = 50, decimals = 1, group = "Stamina"},
	{path = "stamina.recoverAt", label = "Recover At", min = 0, max = 100, decimals = 0, group = "Stamina",
		description = "Stamina you must get back before you can sprint again after running out of breath."},
	{path = "stamina.exhaustSound", label = "Out Of Breath Sound", group = "Stamina"},
	{path = "stamina.breathInterval", label = "Breath Interval (Seconds)", min = 0.5, max = 10, decimals = 1, group = "Stamina"},
	{path = "stamina.soundLevel", label = "Breath Sound Radius", min = 40, max = 120, decimals = 0, group = "Stamina"},
}, {
	ui = true,
	OnChange = function(path, value)
		-- Switching sounds off: cut anything already playing
		if SERVER and (path == "levelUpSounds" or path == "breathSounds") and value == false and DFW.Util.StopAllSounds then DFW.Util.StopAllSounds() end
	end,
})
