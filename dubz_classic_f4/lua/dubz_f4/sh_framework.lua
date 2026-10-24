-- Registers the F4 menu with the Dubz Framework: its settings and tables (tabs and their order, gang leaders, How To
-- Play, rules) appear in the admin config menu (!dubzconfig). The values in sh_config.lua stay the defaults; the
-- menu overrides them live (reopen F4 to see a change).
local F4 = DubzF4

local leaderRows = {}
for _, job in ipairs(F4.Config.GangLeaders) do leaderRows[#leaderRows + 1] = {job = job} end

local ruleRows = {}
for _, rule in ipairs(F4.DefaultRules) do ruleRows[#ruleRows + 1] = {rule = rule} end

local helpRows = {}
for _, row in ipairs(F4.DefaultHelp) do helpRows[#helpRows + 1] = {group = row.group, key = row.key, text = row.text} end

DFW.Bind.Module({
	id = "f4",
	name = "F4 Menu",
	version = "3.0.0",
	icon = "navigation/menu",
	description = "The classic F4 menu (follows the framework theme): tabs and their order, icon grids, rules and How To Play.",
	dependencies = {"dubz_core"},
}, F4.Config, {
	{path = "Header", key = "header", label = "Window Title", group = "Menu", maxLength = 80},
	{path = "InfoHeading", key = "info_heading", label = "Info Tab Heading", group = "Menu", maxLength = 100},
	{path = "Mayor", key = "mayor", label = "Mayor Job Name", group = "Menu", maxLength = 60,
		description = "The job name that counts as the mayor (for the agenda and laws)."},

	{path = "ShopIconScale", key = "shop_icon_scale", label = "Shop Icon Size", min = 0.04, max = 0.3, decimals = 3, group = "Icon Grids",
		description = "Icon width as a fraction of the window (0.1 = a tenth of the width)."},
	{path = "ShopIconMin", key = "shop_icon_min", label = "Shop Icon Minimum (Pixels)", min = 32, max = 256, decimals = 0, group = "Icon Grids"},
	{path = "ShopSpacing", key = "shop_spacing", label = "Shop Icon Spacing (Pixels)", min = 0, max = 20, decimals = 0, group = "Icon Grids"},
	{path = "JobIconScale", key = "job_icon_scale", label = "Job Icon Size", min = 0.1, max = 0.5, decimals = 2, group = "Icon Grids"},
	{path = "KeepCharacterModel", key = "keep_character_model", label = "Jobs Keep Your Character", group = "Jobs",
		description = "On: picking a job keeps your character's look (no model to choose), and the job icons show YOU, in the job's uniform when it has one (Cosmetics > Job Outfits). Off: DarkRP's own job models and the model picker."},
}, {
	collections = {
		{
			id = "tabs", label = "Tabs", idKey = "tab",
			description = "The F4 tabs from left to right. Use the arrows to change the order and the Shown switch to hide one. 'gangs' is the tab the gangs addon adds.",
			columns = {
				{key = "tab", label = "Tab", type = "choice", choices = F4.TabNames, width = 1.4},
				{key = "enabled", label = "Shown", type = "bool", width = 0.8},
			},
			default = F4.DefaultTabs,
		},
		{
			id = "info_links", label = "Info Buttons",
			description = "The buttons on the Info tab: a title and the web address each one opens (http or https).",
			columns = {
				{key = "title", label = "Title", type = "string", width = 2, maxLength = 80},
				{key = "url", label = "Web address", type = "string", width = 3, maxLength = 240},
			},
			default = F4.DefaultInfoLinks,
		},
		{
			id = "main_items", label = "Main Tab", idKey = "item",
			description = "What the Main tab shows. Turn a section (sec_) or a single button off with Shown. Drag the sec_ rows to reorder the sections. The gang, police and mayor sections still only appear to the people they apply to.",
			columns = {
				{key = "item", label = "Item", type = "choice", choices = F4.MainNames, width = 1.6},
				{key = "enabled", label = "Shown", type = "bool", width = 0.8},
			},
			default = F4.DefaultMain,
		},
		{
			id = "hidden_items", label = "Hidden Items",
			description = "Things the F4 menu doesn't list: a job, entity, ammo type, weapon, shipment or food, matched by its name, command or entity class. Hidden jobs can still be given by a job NPC.",
			columns = {
				{key = "kind", label = "Kind", type = "choice", choices = F4.HiddenKinds, width = 1},
				{key = "match", label = "Name, command or class", type = "string", width = 2.4, maxLength = 80},
			},
			default = F4.DefaultHidden,
		},
		{
			id = "help", label = "How To Play",
			description = "The How To Play tab: group, key and text per row. Tokens in the text show the real key from each addon: {laws_key} {skills_key} {pocket_key} {bag_key} {cinematic_key} {surrender_key} {thirdperson_key} {shoulder_key}.",
			columns = {
				{key = "group", label = "Group", type = "string", width = 1.3, maxLength = 40},
				{key = "key", label = "Key / command", type = "string", width = 1.3, maxLength = 40},
				{key = "text", label = "Text", type = "string", width = 4, maxLength = 240},
			},
			default = helpRows,
		},
		{
			id = "rules", label = "Rules",
			description = "The server rules shown in the Rules tab, one per row, in order.",
			columns = {{key = "rule", label = "Rule", type = "string", width = 1, maxLength = 240}},
			default = ruleRows,
		},
		{
			id = "gang_leaders", label = "Gang Leaders", idKey = "job",
			description = "Jobs whose holders can set their organisation's agenda from the Main tab.",
			columns = {{key = "job", label = "Job name", type = "string", width = 1, maxLength = 60, suggest = "jobs"}},
			default = leaderRows,
		},
	},
})

DFW.Collections.Watch("f4", "tabs", function(rows) F4.TabRows = rows end)
DFW.Collections.Watch("f4", "info_links", function(rows) F4.InfoLinks = rows end)
DFW.Collections.Watch("f4", "main_items", function(rows) F4.MainRows = rows end)
DFW.Collections.Watch("f4", "hidden_items", function(rows) F4.HiddenRows = rows end)
DFW.Collections.Watch("f4", "help", function(rows) F4.Help = rows end)
DFW.Collections.Watch("f4", "rules", function(rows) F4.Rules = DFW.Collections.ListFromRows(rows, "rule") end)
DFW.Collections.Watch("f4", "gang_leaders", function(rows) F4.Config.GangLeaders = DFW.Collections.ListFromRows(rows, "job") end)
