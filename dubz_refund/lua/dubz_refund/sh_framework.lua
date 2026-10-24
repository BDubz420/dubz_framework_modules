-- Registers Refund with the Dubz Framework: cash rate, limits and the per-entity rules in the admin config menu
-- (!dubzconfig). The values in sh_config.lua stay the defaults.
local cfg = DubzRefund.Config

DFW.Bind.Module({
	id = "refund",
	name = "Refund",
	version = "1.0.0",
	icon = "economy/diamond",
	description = "Gives players back what a restart or crash cost them: small items respawn, big ones refund as cash.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "cashRate", label = "Cash Back (%)", min = 0, max = 100, decimals = 0, group = "Refund",
		description = "Percent of the price returned for an item taken as cash."},
	{path = "maxRespawn", label = "Most Respawned At Once", min = 1, max = 30, decimals = 0, group = "Refund",
		description = "How many items come back in one go, so the spawn isn't buried."},
	{path = "overflowToCash", label = "Extra Items Become Cash", group = "Refund",
		description = "On: items over the limit give cash. Off: they stay in the list for the next claim."},
	{path = "surpassLimit", label = "Ignore Shop Limits", group = "Refund",
		description = "Off: respawned items can't push a player past the entity limit in the F4 shop (the rest become cash)."},
	{path = "autoCashVolume", label = "Cash-Only Size", min = 1000, max = 5000000, decimals = 0, group = "Refund",
		description = "Entities bigger than this (width x length x height) are cash only. Stove about 200,000, money printer about 40,000."},
	{path = "expireDays", label = "Forget After (Days)", min = 0, max = 90, decimals = 0, group = "Refund", description = "0 = never."},
	{path = "chatCommand", label = "Chat Command", group = "Refund", maxLength = 30},
}, {
	ui = true,
	collections = {
		{
			id = "rules", label = "Entity Rules", idKey = "match",
			description = "Part of an entity's class or shop name and what it gets: respawn or cash. Anything not listed uses the size rule.",
			columns = {
				{key = "match", label = "Class or name contains", type = "string", width = 2, maxLength = 60, suggest = "entities"},
				{key = "mode", label = "Gets", type = "choice", choices = {"respawn", "cash"}, width = 1},
			},
			default = DubzRefund.DefaultRules,
			public = false,
		},
	},
})

DFW.Collections.Watch("refund", "rules", function(rows) DubzRefund.Rules = rows end)
