-- Jobs settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Jobs) edits them live.
DubzJobs = DubzJobs or {}

DubzJobs.Config = {
	-- Change job without respawning: the player stays where they are with their health and armor
	seamless = true,

	-- What carries over to the new job
	keepWeapons = true,   -- weapons that were not the old job's own tools, with the ammo loaded in them
	keepAmmo = true,      -- the reserve ammo of every type

	-- How close you must be to a job NPC to keep talking to it
	talkDistance = 220,
}

-- Job sites: an NPC where a citizen is hired for a job and can quit it again. `job` is the DarkRP job command (the
-- "command" in the job's definition). Being hired puts the player in the job (the outfit and accessories come from the
-- Job Outfits table in Cosmetics and the Job Accessories table below) and hands over the tool. The tool is theirs to
-- keep; it can be bought again from the NPC if it is lost.
-- (Edit these in the admin menu: Jobs > Job Sites. The NPC's model and lines are in sv_dialog.lua / the entity.)
-- Pose: how the NPC stands or sits (a sequence name; "auto" = it idles and changes by itself, see the NPC Life addon). A pose its model does not have
-- is replaced by the plain standing one.
DubzJobs.PoseNames = {"auto", "idle_all_01", "idle_subtle", "idle_all_02", "lineidle01", "lineidle02", "lineidle03", "lineidle04",
	"pose_standing_01", "pose_standing_02", "pose_standing_03", "pose_standing_04", "sit_chair", "sit_ground", "idle_all_angry", "cower"}

DubzJobs.DefaultSites = {
	{site = "miner", job = "miner", npc = "Foreman Dale", tool = "weapon_dubz_pickaxe", price = 250, pose = "auto"},
	{site = "cityworker", job = "cityworker", npc = "Foreman Hale", tool = "dubz_cw_wrench", price = 150, pose = "pose_standing_02"},
}

DubzJobs.Sites = {}
for _, row in ipairs(DubzJobs.DefaultSites) do
	DubzJobs.Sites[row.site] = {id = row.site, job = row.job, npc = row.npc, tool = row.tool, price = row.price, pose = row.pose or "auto"}
end

-- Models the NPCs wear (by site id); anything else uses the first
DubzJobs.NpcModels = {
	miner = "models/Humans/Group03/male_07.mdl",
	cityworker = "models/Humans/Group01/male_04.mdl",
}

-- What a site's NPC says, by site id (anything missing uses the miner's wording, which is the default in sv_dialog.lua). Other addons add theirs here.
DubzJobs.Lines = DubzJobs.Lines or {}

-- The accessory a job puts on top of what the player wears (a hard hat for a miner). It is only drawn while they have
-- the job; what they really wear underneath is untouched, so leaving the job puts it all back. Accessory ids come from
-- the Cosmetics catalog (job items are registered in sh_items.lua and aren't for sale).
-- (No hard hat for now: its model isn't on players' computers, so it showed as nothing. Add {job = "Miner", slot = "hat",
-- accessory = "job_hardhat"} back once there is a real hat model everyone downloads.)
DubzJobs.DefaultAccessories = {
}
DubzJobs.Accessories = {}
for _, row in ipairs(DubzJobs.DefaultAccessories) do
	DubzJobs.Accessories[string.lower(row.job)] = DubzJobs.Accessories[string.lower(row.job)] or {}
	DubzJobs.Accessories[string.lower(row.job)][row.slot] = row.accessory
end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so DarkRP behaves as normal.
function DubzJobs.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("jobs")
end
