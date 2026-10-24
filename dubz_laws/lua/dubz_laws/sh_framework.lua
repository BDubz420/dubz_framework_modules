-- Registers Laws with the Dubz Framework (!dubzconfig > Laws): the numbers, and the two tables of fixed laws.
local cfg = DubzLaws.Config

DFW.Bind.Module({
	id = "laws",
	name = "Laws",
	version = "1.0.0",
	icon = "economy/inventory_2",
	description = "The city's laws as two lists, legal and illegal, set by the mayor with /addlegal and /addillegal.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "maxLegal", label = "Most Legal Laws The Mayor Can Add", min = 1, max = 30, decimals = 0, group = "Limits"},
	{path = "maxIllegal", label = "Most Illegal Laws The Mayor Can Add", min = 1, max = 30, decimals = 0, group = "Limits"},
	{path = "maxLength", label = "Longest A Law Can Be", min = 20, max = 400, decimals = 0, group = "Limits"},
	{path = "adminsCanEdit", label = "Superadmins Can Edit Laws", group = "Limits"},
}, {
	collections = {
		{
			id = "fixed_legal", label = "Fixed Legal Laws",
			description = "Laws that are always on the LEGAL list. The mayor can't remove them (a change here shows after the next mayor reset or restart).",
			columns = {{key = "law", label = "Law", type = "string", width = 1, maxLength = 200}},
			default = (function() local rows = {} for _, law in ipairs(DubzLaws.DefaultFixedLegal) do rows[#rows + 1] = {law = law} end return rows end)(),
		},
		{
			id = "fixed_illegal", label = "Fixed Illegal Laws",
			description = "Laws that are always on the ILLEGAL list. They start as DarkRP's default laws.",
			columns = {{key = "law", label = "Law", type = "string", width = 1, maxLength = 200}},
			default = (function() local rows = {} for _, law in ipairs(DubzLaws.DefaultFixedIllegal()) do rows[#rows + 1] = {law = law} end return rows end)(),
		},
	},
})

local function lawsFrom(rows)
	local list = {}

	for _, row in ipairs(rows) do
		if row.law and row.law ~= "" then list[#list + 1] = row.law end
	end

	return list
end

DFW.Collections.Watch("laws", "fixed_legal", function(rows) DubzLaws.FixedLegalRows = lawsFrom(rows) if DubzLaws.OnFixedChanged then DubzLaws.OnFixedChanged() end end)
DFW.Collections.Watch("laws", "fixed_illegal", function(rows) DubzLaws.FixedIllegalRows = lawsFrom(rows) if DubzLaws.OnFixedChanged then DubzLaws.OnFixedChanged() end end)
