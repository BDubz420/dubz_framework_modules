DubzKarma.Config = {
	start = 100,
	min = 0,
	max = 200,

	-- Karma changes from actions
	killPlayer = -10,         -- killing a player who wasn't wanted
	killWanted = 5,           -- killing a wanted player
	arrestWanted = 5,         -- arresting a criminal
	playBonus = 1,            -- passive gain...
	playBonusInterval = 1800, -- ...every this many seconds alive

	-- Commends: one player can commend another once per cooldown (seconds)
	commendCooldown = 600,

	-- Each player can hand out this many commends per real-world day (server date)
	commendsPerDay = 3,

	-- "Healed" karma: after someone uses a healing entity while hurt, they have this many seconds to reach full
	-- health for the karma to count.
	healWindow = 90,
}

-- Everyday karma: doing good, ordinary things earns a little. Edit these in the admin menu ("Karma Sources").
--   event  bought  = a player bought the entity from F4 (the buyer is the "actor")
--          healed  = a hurt player used the entity and reached full health (the user is the "actor")
--          cooked  = another addon cooked that item (the cook is the "actor", see DubzKarma.Reward)
--   who    actor = the player doing it earns it; owner = the entity's owner earns it (never the actor themselves)
--   cooldown seconds before the same player can earn the same row again (0 = no limit)
DubzKarma.DefaultSources = {
	{event = "bought", class = "microwave", karma = 1, who = "actor", cooldown = 0, note = "bought a microwave"},
	{event = "healed", class = "dubz_health_charger", karma = 1, who = "owner", cooldown = 30, note = "patched someone up"},
	{event = "cooked", class = "dubnut", karma = 1, who = "actor", cooldown = 0, note = "cooked a donut"},
	{event = "cooked", class = "dubnut_gold", karma = 1, who = "actor", cooldown = 0, note = "cooked a golden donut"},
}

-- What the rewards read (replaced when the table is edited in the admin menu)
DubzKarma.Sources = table.Copy(DubzKarma.DefaultSources)

-- Commend kinds shown in the scoreboard drawer. karma = change applied to the receiver.
-- Add, remove or retune freely; ids are stored in the database, so don't rename a live id.
DubzKarma.Commends = {
	{id = "friendly",    name = "Friendly",    desc = "Good to talk to.",              icon = "icon16/emoticon_smile.png", karma = 1},
	{id = "helpful",     name = "Helpful",     desc = "Went out of their way to help.", icon = "icon16/heart.png",          karma = 2},
	{id = "trustworthy", name = "Trustworthy", desc = "Keeps their word.",             icon = "icon16/shield.png",         karma = 2},
	{id = "great_rp",    name = "Great RP",    desc = "Makes the city feel alive.",    icon = "icon16/star.png",           karma = 2},
	{id = "generous",    name = "Generous",    desc = "Shares what they have.",        icon = "icon16/coins.png",          karma = 2},
	{id = "shady",       name = "Shady",       desc = "Something isn't right here.",   icon = "icon16/eye.png",            karma = -2},
	{id = "dangerous",   name = "Dangerous",   desc = "Keep your distance.",           icon = "icon16/exclamation.png",    karma = -2},
}
