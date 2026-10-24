DubzSkills.Config = {
	maxLevel = 10,

	-- Level-up sounds are played from the player, so everyone near them hears it too.
	levelUpSounds = true,   -- the dings when a skill or your overall level goes up
	breathSounds = false,   -- the heavy breathing when you run out of stamina (off by default: players found it annoying)
	levelUpSound = "buttons/bell1.wav",
	overallLevelUpSound = "buttons/bell1.wav",
	soundLevel = 75,

	-- Overall level: ALL your skill XP added together slowly levels you up (shown over your head as
	-- "Level: N" and as a bar at the top of the skills menu). The XP to go from level L-1 to L is
	-- overallXPBase * (L-1) ^ overallXPExponent. Paced for about 3 hours of play a day with walking and running
	-- (roughly 4,500 XP a day): level 2 in about a day, level 3 in two more, then a level every few days to a week
	-- (more skills will speed this up, so revisit it when they arrive).
	overallXPBase = 4000,
	overallXPExponent = 1.2,
	maxOverallLevel = 50,

	-- Leveling curve. The XP to go from level L-1 to L is xpBase * L ^ xpExponent, so every level
	-- takes longer than the last. A skill can override xpBase / xpExponent in its own definition.
	-- Paced for about 3 hours of play a day (a skill earns ~2,000-2,600 XP a day): level 1 within the first day,
	-- level 2 after about two days, level 3 after about three and a half, then a level every 3-7 days up to 10
	-- (around five weeks of steady play for everything). Levels run on the curve's total, so lowering or raising the
	-- base moves everyone's levels with their saved XP.
	xpBase = 1100,
	xpExponent = 1.2,

	-- Menu
	openKey = KEY_F6,       -- toggles the skills menu (also the chat commands below and the dubz_skills console command)
	chatCommands = {"/skills", "!skills"},

	-- Categories shown in the menu, in this order. A category only appears once it has a skill.
	categories = {
		{id = "movement", name = "Movement"},
		{id = "combat",   name = "Combat"},
		{id = "street",   name = "Street Smart"},
		{id = "industry", name = "Industry"},
	},

	-- Walking / running (see sh_movement.lua). Everyone walks slowly by default, as if holding Alt,
	-- and runs a bit slower than the stock sprint. Each skill level adds a little to its speed.
	movement = {
		enabled = true,

		baseWalk = 100,
		walkPerLevel = 3,   -- max level: 130

		baseRun = 200,
		runPerLevel = 4,    -- max level: 240 (the stock DarkRP sprint)

		-- XP per second while actually moving on the ground
		walkXPPerSecond = 0.5,
		runXPPerSecond = 1.0,
	},

	-- Stamina: running drains it, resting restores it. There is no bar on purpose; when it runs out you
	-- are out of breath (can't sprint, heavy breathing) until it recovers to recoverAt.
	stamina = {
		enabled = true,
		max = 100,
		drainPerSecond = 5,           -- 20 seconds of running at running level 0
		drainReductionPerLevel = 0.05, -- each Running level makes it drain 5% slower (half at level 10)
		regenIdle = 10,               -- per second standing still
		regenMoving = 6,              -- per second walking
		recoverAt = 30,               -- how much you need back before you can sprint again

		exhaustSound = "player/breathe1.wav",
		breathInterval = 2.4,         -- seconds between breaths while out of breath
		soundLevel = 65,
	},
}
