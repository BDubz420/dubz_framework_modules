-- Admin commands (console, admins only):
--   dubz_cosmetic_list                       list every registered accessory id
--   dubz_cosmetic_give <player> <id>         give a player an accessory (goes in their inventory)
--   dubz_cosmetic_take <player> <id>         remove an accessory from a player
--   dubz_cosmetic_has <player>               show what a player wears
local function reply(ply, text)
	if IsValid(ply) then ply:ChatPrint("[Cosmetics] " .. text) else print("[Cosmetics] " .. text) end
end

local function findPlayer(caller, query)
	if not query or query == "" then return caller end

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

add("dubz_cosmetic_list", function(caller)
	local lines = {}
	for id, def in pairs(DubzCosmetics.Items) do if not def.virtual then lines[#lines + 1] = string.format("  %s - %s (%s)", id, def.name, def.slot) end end
	table.sort(lines)
	reply(caller, "\n" .. table.concat(lines, "\n"))
end)

add("dubz_cosmetic_give", function(caller, args)
	local target = findPlayer(caller, args[1])
	local id = args[2]
	if not target then return end

	if not id or not DubzCosmetics.Get(id) then reply(caller, "Usage: dubz_cosmetic_give <player> <id> (see dubz_cosmetic_list)") return end

	local ok, reason = DubzCosmetics.Give(target, id)
	reply(caller, ok and ("Gave " .. id .. " to " .. target:Nick() .. ".") or ("Couldn't give it: " .. tostring(reason)))
end)

add("dubz_cosmetic_take", function(caller, args)
	local target = findPlayer(caller, args[1])
	local id = args[2]
	if not target then return end

	reply(caller, (id and DubzCosmetics.Remove(target, id)) and ("Removed " .. id .. " from " .. target:Nick() .. ".") or "They don't own that.")
end)

add("dubz_cosmetic_has", function(caller, args)
	local target = findPlayer(caller, args[1])
	if not target then return end

	local worn = {}
	for _, slot in ipairs(DubzCosmetics.Config.slots) do
		local id = DubzCosmetics.GetWornItem(target, slot.id)
		if id ~= "" then worn[#worn + 1] = slot.id .. ": " .. id end
	end

	reply(caller, target:Nick() .. " wears: " .. (#worn > 0 and table.concat(worn, ", ") or "nothing") .. " (other accessories are in their inventory)")
end)
