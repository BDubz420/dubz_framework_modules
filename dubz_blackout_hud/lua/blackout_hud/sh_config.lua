-- Gameplay and layout values shared by the server logic and the HUD. All of them appear in the Dubz Framework
-- admin menu (!dubzconfig > HUD); fonts and colours that follow the theme are set up in cl_config.lua.
BHUD.Config = BHUD.Config or {}

table.Merge(BHUD.Config, {
	-- Wanted: the countdown shown on the bar. If wantedAutoExpire is true the server
	-- also calls unWanted() when it runs out.
	wantedDuration = 180,
	wantedAutoExpire = true,

	-- Mayor grace period: starts when a player takes the mayor job (display only for now).
	mayorTeamName = "TEAM_MAYOR",
	mayorGraceTime = 300,

	flip = false,              -- true = top bar sits at the bottom of the screen
	hideDefaultHunger = true,  -- hide the stock hungermod bar
	barHeight = 31,

	lawsKey = KEY_F1,          -- expands / collapses the laws panel
	cinematicKey = KEY_F8,     -- hides the whole HUD and chat; press again to bring it back (1 second between presses). The weapon wheel still works. (F7 is the first / third person switch.)
	lawsCooldown = 1,          -- seconds between presses, so the key can't spam it
	lawsDefaultOpen = false,

	-- Votes and questions (a vote for mayor, the lottery, a demote ...) are cards on the HUD; these keys answer the oldest one
	promptYesKey = KEY_Y,
	promptNoKey = KEY_N,

	-- DarkRP's own "you're arrested for N seconds" text is switched off for good (the arrest popup and the bar timer replace it)
	hideDefaultArrest = true,

	-- Take over DarkRP's overhead player info (name/health/job) and door text so the
	-- org + title lines can sit above it. Set false to leave DarkRP's own display alone.
	replaceEntityDisplay = true,
	overheadDistance = 450,

	-- Door ownership text drawn on the door itself (cl_doors.lua)
	doorDistance = 250,
	doorScale = 0.14,
	doorSurfaceOffset = 0.5, -- how far in front of the door's surface the text floats; raise if it hides inside the door

	panel = {pad = 10},      -- card padding; the card colours come from the framework theme (cl_config.lua)

	-- Day-of-week colour for the clock entry, indexed by os.date("%w") + 1 (Sunday first).
	dayColors = {
		Color(255, 90, 90),   -- Sun
		Color(255, 220, 60),  -- Mon
		Color(255, 140, 40),  -- Tue
		Color(120, 225, 0),   -- Wed
		Color(60, 200, 220),  -- Thu
		Color(150, 120, 255), -- Fri
		Color(255, 120, 190), -- Sat
	},
})

-- The top bar entries in their default order and side. The "Top Bar" table in the admin menu starts from this
-- (reorder, move to the other side, or switch entries off); names match the entries in cl_bars.lua.
BHUD.DefaultBars = {
	{name = "name", side = "left"}, {name = "health", side = "left"}, {name = "armor", side = "left"},
	{name = "hunger", side = "left"}, {name = "job", side = "left"}, {name = "money", side = "left"},
	{name = "salary", side = "left"}, {name = "karma", side = "left"}, {name = "gunlicense", side = "left"},
	{name = "arrested", side = "right"}, {name = "nlr", side = "right"}, {name = "wanttime", side = "right"},
	{name = "wantedreason", side = "right"}, {name = "mayorgrace", side = "right"}, {name = "org", side = "right"},
	{name = "level", side = "right"}, {name = "props", side = "right"}, {name = "ping", side = "right"},
	{name = "fps", side = "right"}, {name = "daytime", side = "right"}, {name = "playtime", side = "right"},
}

-- What the top bar reads (replaced when the table is edited in the admin menu)
BHUD.BarRows = {}
for _, bar in ipairs(BHUD.DefaultBars) do BHUD.BarRows[#BHUD.BarRows + 1] = {name = bar.name, side = bar.side, enabled = true} end

-- Master kill switch (admin menu > Modules). Off = the HUD draws nothing and DarkRP's own HUD comes back.
-- True when the framework isn't installed, so the HUD still works without it.
function BHUD.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("hud")
end
