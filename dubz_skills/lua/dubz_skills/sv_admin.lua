-- Admin commands for editing players' skills, XP and overall level. Run from the console (admins only):
--   dubz_skills_info <player>                     show a player's skill levels, XP and overall level
--   dubz_skill_setlevel <player> <skill> <level>  set a skill to exactly that level (0 = none)
--   dubz_skill_addxp <player> <skill> <xp>        add (or with a negative number remove) skill XP
--   dubz_skill_reset <player> [skill]             reset one skill, or all of them
--   dubz_level_set <player> <level>               set the overall level using bonus XP
--   dubz_level_addxp <player> <xp>                add (or remove) bonus XP toward the overall level
-- <player> is part of a name; <skill> is a skill id such as walking or running.
local function reply(ply, text)
	if IsValid(ply) then ply:ChatPrint("[Skills] " .. text) else print("[Skills] " .. text) end
end

local function findPlayer(caller, query)
	if not query or query == "" then reply(caller, "Give a player name.") return end

	local matches = {}
	for _, ply in ipairs(player.GetAll()) do
		if string.find(string.lower(ply:Nick()), string.lower(query), 1, true) then matches[#matches + 1] = ply end
	end

	if #matches ~= 1 then
		reply(caller, #matches == 0 and "No player matches that name." or "More than one player matches; be more specific.")
		return
	end

	return matches[1]
end

local function add(name, run)
	concommand.Add(name, function(caller, _, args)
		if IsValid(caller) and not caller:IsAdmin() then return end
		run(caller, args)
	end)
end

local function describe(ply)
	local lines = {ply:Nick() .. " - overall level " .. DubzSkills.GetOverallLevel(ply) .. " (" .. math.floor(DubzSkills.GetServerTotalXP(ply)) .. " XP)"}

	for id in pairs(DubzSkills.Skills) do
		lines[#lines + 1] = string.format("  %s: level %d, %d XP", id, DubzSkills.GetLevel(ply, id), math.floor(DubzSkills.GetServerXP(ply, id)))
	end

	lines[#lines + 1] = "  bonus XP: " .. math.floor(DubzSkills.GetServerXP(ply, "_bonus"))
	return table.concat(lines, "\n")
end

add("dubz_skills_info", function(caller, args)
	local target = findPlayer(caller, args[1])
	if target then reply(caller, "\n" .. describe(target)) end
end)

add("dubz_skill_setlevel", function(caller, args)
	local target = findPlayer(caller, args[1])
	local def = DubzSkills.Skills[args[2] or ""]
	local level = tonumber(args[3])

	if not target then return end
	if not def or not level then
		reply(caller, "Usage: dubz_skill_setlevel <player> <skill> <level>. Skills: " .. table.concat(table.GetKeys(DubzSkills.Skills), ", "))
		return
	end

	level = math.Clamp(math.floor(level), 0, def.maxLevel)
	DubzSkills.SetXP(target, def.id, level == 0 and 0 or DubzSkills.XPForLevel(def, level))
	reply(caller, target:Nick() .. "'s " .. def.name .. " is now level " .. level .. ".")
end)

add("dubz_skill_addxp", function(caller, args)
	local target = findPlayer(caller, args[1])
	local def = DubzSkills.Skills[args[2] or ""]
	local amount = tonumber(args[3])

	if not target then return end
	if not def or not amount then reply(caller, "Usage: dubz_skill_addxp <player> <skill> <xp>") return end

	DubzSkills.SetXP(target, def.id, DubzSkills.GetServerXP(target, def.id) + amount)
	reply(caller, target:Nick() .. "'s " .. def.name .. " XP is now " .. math.floor(DubzSkills.GetServerXP(target, def.id)) .. ".")
end)

add("dubz_skill_reset", function(caller, args)
	local target = findPlayer(caller, args[1])
	if not target then return end

	if args[2] then
		local def = DubzSkills.Skills[args[2]]
		if not def then reply(caller, "Unknown skill.") return end

		DubzSkills.SetXP(target, def.id, 0)
		reply(caller, target:Nick() .. "'s " .. def.name .. " was reset.")
	else
		for id in pairs(DubzSkills.Skills) do DubzSkills.SetXP(target, id, 0) end
		DubzSkills.SetXP(target, "_bonus", 0)
		reply(caller, "All of " .. target:Nick() .. "'s skills and bonus XP were reset.")
	end
end)

add("dubz_level_addxp", function(caller, args)
	local target = findPlayer(caller, args[1])
	local amount = tonumber(args[2])

	if not target then return end
	if not amount then reply(caller, "Usage: dubz_level_addxp <player> <xp>") return end

	DubzSkills.SetXP(target, "_bonus", DubzSkills.GetServerXP(target, "_bonus") + amount)
	reply(caller, target:Nick() .. " is now overall level " .. DubzSkills.GetOverallLevel(target) .. ".")
end)

add("dubz_level_set", function(caller, args)
	local target = findPlayer(caller, args[1])
	local level = tonumber(args[2])

	if not target then return end
	if not level then reply(caller, "Usage: dubz_level_set <player> <level>") return end

	level = math.Clamp(math.floor(level), 1, DubzSkills.Config.maxOverallLevel)

	-- Bonus XP makes up the difference between the skills' XP and what the level needs.
	local needed = DubzSkills.XPForOverall(level)
	local fromSkills = DubzSkills.GetServerTotalXP(target) - DubzSkills.GetServerXP(target, "_bonus")

	if fromSkills > needed then
		reply(caller, target:Nick() .. "'s skills alone already give level " .. DubzSkills.OverallLevelFromXP(fromSkills) .. ". Lower their skills first (dubz_skill_setlevel / dubz_skill_reset).")
		return
	end

	DubzSkills.SetXP(target, "_bonus", needed - fromSkills)
	reply(caller, target:Nick() .. " is now overall level " .. DubzSkills.GetOverallLevel(target) .. ".")
end)
