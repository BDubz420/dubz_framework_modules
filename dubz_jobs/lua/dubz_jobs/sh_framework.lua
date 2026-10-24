-- Registers Jobs with the Dubz Framework: seamless job changes and what carries over (!dubzconfig).
local cfg = DubzJobs.Config

DFW.Bind.Module({
	id = "jobs",
	name = "Jobs",
	version = "1.0.0",
	icon = "players/face",
	description = "Changing job without being respawned: position, health, weapons and ammo carry over; the job changes the outfit.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "seamless", label = "Seamless Job Change", group = "Job Change",
		description = "On: changing job keeps the player where they are (no respawn). Off: DarkRP's normal behaviour."},
	{path = "keepWeapons", label = "Keep Weapons", group = "Job Change",
		description = "Weapons that weren't the old job's own tools come with the player, with the ammo loaded in them."},
	{path = "keepAmmo", label = "Keep Ammo", group = "Job Change", description = "The reserve ammo of every type comes with the player."},
	{path = "talkDistance", label = "Talk Distance", min = 80, max = 500, decimals = 0, group = "Job Sites"},
}, {
	collections = {
		{
			id = "sites", label = "Job Sites", idKey = "site",
			description = "Job NPCs: the site's id (matches the NPC entity), the job command it hires for (the 'command' in the job's DarkRP definition), the NPC's name, the tool it hands over, what a replacement costs and the pose the NPC holds (standing, leaning, sitting ...).",
			columns = {
				{key = "site", label = "Site id", type = "string", width = 1, maxLength = 30},
				{key = "job", label = "Job command", type = "string", width = 1, maxLength = 40, suggest = "jobs"},
				{key = "npc", label = "NPC name", type = "string", width = 1.3, maxLength = 40},
				{key = "tool", label = "Tool (weapon class)", type = "string", width = 1.6, maxLength = 60, suggest = "weapons"},
				{key = "price", label = "Replacement price", type = "number", min = 0, max = 1000000, decimals = 0, width = 1},
				{key = "pose", label = "Pose", type = "choice", choices = DubzJobs.PoseNames, width = 1.3},
			},
			default = DubzJobs.DefaultSites,
		},
		{
			id = "job_accessories", label = "Job Accessories",
			description = "An accessory a job puts on the player while they hold it (a hard hat for a miner). It is drawn over what they wear in that slot and gone when they leave the job; what they really wear is untouched. One row per job and slot.",
			columns = {
				{key = "job", label = "Job name", type = "string", width = 1.4, maxLength = 60, suggest = "jobs"},
				{key = "slot", label = "Slot", type = "choice", choices = {"hat", "face", "neck", "back"}, width = 0.9},
				{key = "accessory", label = "Accessory id", type = "string", width = 1.6, maxLength = 60, suggest = "accessories"},
			},
			default = DubzJobs.DefaultAccessories,
		},
	},
})

DFW.Collections.Watch("jobs", "sites", function(rows)
	local sites = {}
	for _, row in ipairs(rows) do
		sites[row.site] = {id = row.site, job = row.job, npc = row.npc, tool = row.tool, price = row.price, pose = (row.pose and row.pose ~= "") and row.pose or "auto"}
	end
	DubzJobs.Sites = sites
end)

DFW.Collections.Watch("jobs", "job_accessories", function(rows)
	local map = {}

	for _, row in ipairs(rows) do
		local key = string.lower(row.job)
		map[key] = map[key] or {}
		map[key][row.slot] = row.accessory
	end

	DubzJobs.Accessories = map
end)
