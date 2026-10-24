DubzScoreboard.Config = {
	serverName = "Liminal RP | Sector 18",   -- shown at the top of the scoreboard
	scale = 0.85,                            -- overall size (1 = full size)

	-- Which columns to show
	showGang = true,
	showJob = true,
	showMoney = true,
	showKD = true,
	showPing = true,
	showRanks = false,                       -- the player's rank (Owner, Admin ...) after their name, from the Ranks table

	-- Row order: money (richest first), name, job or ping
	sortBy = "money",

	-- Who sees the staff buttons (Go-To, Bring, Freeze, Jail, Spectate) when they open a player's drawer
	staffGroups = {
		superadmin = true, headadmin = true, headadminvip = true, admin = true, adminvip = true, trialadmin = true,
		moderator = true, trialmoderator = true, trialadminvip = true, moderatorvip = true, trialmoderatorvip = true,
	},
}

-- Rank names and colours (the "Ranks" table in the admin menu starts from this list)
DubzScoreboard.DefaultGroups = {
	{id = "superadmin", name = "Owner", color = {r = 255, g = 50, b = 0, a = 255}},
	{id = "headadmin", name = "Head Admin", color = {r = 199, g = 44, b = 44, a = 255}},
	{id = "headadminvip", name = "Head Admin", color = {r = 199, g = 44, b = 44, a = 255}},
	{id = "admin", name = "Administrator", color = {r = 241, g = 196, b = 15, a = 255}},
	{id = "adminvip", name = "Administrator", color = {r = 241, g = 196, b = 15, a = 255}},
	{id = "trialadmin", name = "Administrator", color = {r = 241, g = 196, b = 15, a = 255}},
	{id = "moderator", name = "Moderator", color = {r = 52, g = 152, b = 219, a = 255}},
	{id = "trialmoderator", name = "Moderator", color = {r = 52, g = 152, b = 219, a = 255}},
	{id = "trialadminvip", name = "Administrator", color = {r = 241, g = 196, b = 15, a = 255}},
	{id = "moderatorvip", name = "Moderator", color = {r = 52, g = 152, b = 219, a = 255}},
	{id = "trialmoderatorvip", name = "Moderator", color = {r = 52, g = 152, b = 219, a = 255}},
	{id = "vip", name = "VIP", color = {r = 155, g = 89, b = 182, a = 255}},
}

-- What the scoreboard reads for ranks (the framework replaces it when the table is edited)
DubzScoreboard.Groups = {}
for _, row in ipairs(DubzScoreboard.DefaultGroups) do DubzScoreboard.Groups[row.id] = {name = row.name, color = row.color} end
