-- Laws settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Laws) edits them live.
DubzLaws = DubzLaws or {}

DubzLaws.Config = {
	maxLegal = 8,           -- how many laws the mayor can add to the legal list
	maxIllegal = 12,        -- ...and to the illegal list
	adminsCanEdit = true,   -- superadmins can use the commands too
	maxLength = 160,        -- the longest a law can be
}

-- Laws that are always there and the mayor can't remove (the "Fixed Laws" tables in the admin menu start from these). The illegal list starts
-- from DarkRP's own default laws.
DubzLaws.DefaultFixedLegal = {}

function DubzLaws.DefaultFixedIllegal()
	local list = {}

	for _, law in ipairs((GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.DefaultLaws) or {}) do list[#list + 1] = law end

	return list
end

-- The live lists, as arrays of text. The first FixedLegal / FixedIllegal entries are the fixed ones. (The server owns them and tells every
-- client; see sv_laws.lua and cl_laws.lua.)
DubzLaws.Legal = DubzLaws.Legal or {}
DubzLaws.Illegal = DubzLaws.Illegal or {}
DubzLaws.FixedLegal = DubzLaws.FixedLegal or 0
DubzLaws.FixedIllegal = DubzLaws.FixedIllegal or 0

-- The two lists for anything that draws them
function DubzLaws.Get()
	return DubzLaws.Legal, DubzLaws.Illegal
end

-- The commands, declared for DarkRP's help list (DarkRP is not loaded yet when this file runs, so it waits for the game to be up)
hook.Add("InitPostEntity", "DubzLaws_Declare", function()
	if not (DarkRP and DarkRP.declareChatCommand) then return end

	local plyMeta = FindMetaTable("Player")

	for _, row in ipairs({
		{"addlegal", "Add a law to the LEGAL list."},
		{"addillegal", "Add a law to the ILLEGAL list."},
		{"removelegal", "Remove a law from the legal list (by its number)."},
		{"removeillegal", "Remove a law from the illegal list (by its number)."},
	}) do
		DarkRP.declareChatCommand{command = row[1], description = row[2], delay = 1.5, condition = plyMeta.isMayor}
	end
end)

function DubzLaws.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("laws")
end
