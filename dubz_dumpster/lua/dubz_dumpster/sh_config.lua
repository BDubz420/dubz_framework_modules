DubzDumpster.Config = {
	-- Only these jobs may search (the job NAME as shown in F4). Leave empty = every job can.
	jobs = {
		--["hobo"] = true,
	},

	cooldown = 300,          -- seconds before a searched dumpster can be searched again
	searchTime = 1.8,        -- seconds a search takes (one hand reaches in and grabs, with the hands-at-work addon); 0 = instant
	propsMin = 1,            -- the fewest junk props a search that finds something gives
	propsAmount = 6,         -- the most (it is different every time)

	-- Some searches find nothing at all. A better scavenger (the Scavenging skill) finds nothing less often.
	emptyChance = 20,        -- percent of searches that turn up nothing
	emptyChancePerLevel = 1.5, -- percent less for each Scavenging level
	propLifetime = 60,       -- seconds before the junk props disappear

	-- Cash
	moneyMin = 1,
	moneyMax = 500,
	moneyChance = 20,        -- percent chance of cash per search

	-- Item drops: each search gets entityRolls rolls; every roll picks a random row of the Item Drops table and
	-- succeeds with that row's chance (percent).
	entityRolls = 2,
}

-- Junk props (the "Junk Props" table in the admin menu starts from this list)
DubzDumpster.DefaultProps = {
	"models/props_junk/garbage_milkcarton001a.mdl",
	"models/props_junk/garbage_bag001a.mdl",
	"models/props_junk/garbage_metalcan001a.mdl",
	"models/props_junk/Shoe001a.mdl",
	"models/props_junk/garbage_milkcarton002a.mdl",
	"models/props_junk/garbage_metalcan002a.mdl",
	"models/props_junk/garbage_carboard002a.mdl",
	"models/props_lab/harddrive01.mdl",
	"models/props_junk/plasticbucket001a.mdl",
	"models/props_junk/MetalBucket01a.mdl",
	"models/props_junk/metal_paintcan001b.mdl",
	"models/props_interiors/pot02a.mdl",
	"models/props_combine/breenglobe.mdl",
	"models/props_junk/PropaneCanister001a.mdl",
	"models/props_junk/meathook001a.mdl",
	"models/props_c17/lampShade001a.mdl",
	"models/props_c17/playground_swingset_seat01a.mdl",
	"models/props_c17/doll01.mdl",
	"models/props_canal/mattpipe.mdl",
	"models/props_combine/breenclock.mdl",
	"models/props_lab/hevplate.mdl",
	"models/props_lab/reciever01c.mdl",
	"models/props_trainstation/payphone_reciever001a.mdl",
	"models/props_junk/garbage_newspaper001a.mdl",
	"models/props_junk/garbage_plasticbottle001a.mdl",
	"models/props_junk/garbage_plasticbottle003a.mdl",
	"models/props_junk/garbage_plasticbottle002a.mdl",
	"models/props_junk/sawblade001a.mdl",
	"models/props_interiors/pot01a.mdl",
	"models/props_junk/CinderBlock01a.mdl",
	"models/props_c17/tools_wrench01a.mdl",
}

-- Item drops: entity class and the percent chance it drops when its roll comes up
DubzDumpster.DefaultDrops = {
	-- Common drugs
	{"durgz_cocaine", 50}, {"durgz_heroine", 50}, {"durgz_lsd", 50}, {"durgz_weed", 50}, {"durgz_meth", 50},
	{"durgz_mushroom", 50}, {"durgz_pcp", 50}, {"durgz_alcohol", 45}, {"durgz_aspirin", 45}, {"durgz_cigarette", 45},

	-- Common food and junk
	{"soda_can", 35}, {"dubnut", 35}, {"uweed_cookies", 35}, {"uweed_cakeslice", 35}, {"uweed_brownies", 35},
	{"am_beer", 30}, {"am_ginbottle", 30}, {"wm_bottle", 30},

	-- Weed related
	{"uweed_bud", 30}, {"uweed_skin", 30}, {"uweed_frontwoods", 30},

	-- Guns, vape and roulette
	{"m9k_sig_p229r", 20}, {"weapon_vape", 20}, {"weapon_roulette", 20},

	-- Melee weapons
	{"weapon_hl2axe", 15}, {"weapon_hl2bottle", 15}, {"weapon_hl2brokenbottle", 15}, {"weapon_hl2hook", 15},
	{"weapon_hl2pan", 15}, {"weapon_hl2pickaxe", 15}, {"weapon_hl2pipe", 15}, {"weapon_hl2pot", 15}, {"weapon_hl2shovel", 15},
}

-- What the entity actually reads. These start as the defaults above; the framework replaces them whenever an admin
-- edits the tables in the config menu.
DubzDumpster.Props = table.Copy(DubzDumpster.DefaultProps)
DubzDumpster.Drops = {}
for _, row in ipairs(DubzDumpster.DefaultDrops) do DubzDumpster.Drops[#DubzDumpster.Drops + 1] = {class = row[1], chance = row[2]} end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzDumpster.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("dumpsters")
end
