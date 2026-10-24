-- Admin commands (console, admins only):
--   dubz_inv_list <player>             show what is in a player's inventory
--   dubz_inv_remove <player> <slot>    delete the item in a slot
--   dubz_inv_clear <player>            empty their inventory
--   dubz_inv_givebag [player]          give a Big backpack, or a Small one with "small" (spawns it in front of you / the player)
local function reply(ply, text)
	if IsValid(ply) then ply:ChatPrint("[Inventory] " .. text) else print("[Inventory] " .. text) end
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

add("dubz_inv_list", function(caller, args)
	local target = findPlayer(caller, args[1])
	if not target then return end

	local lines = {target:Nick() .. "'s inventory:"}
	for slot, rec in pairs(DubzInv.GetSlots(target)) do
		lines[#lines + 1] = string.format("  [%d] %s x%d (%s)", slot, rec.name or "?", rec.qty or 1, rec.class or "?")
	end

	if #lines == 1 then lines[2] = "  (empty)" end
	reply(caller, "\n" .. table.concat(lines, "\n"))
end)

add("dubz_inv_remove", function(caller, args)
	local target = findPlayer(caller, args[1])
	local slot = tonumber(args[2])
	if not target then return end
	if not slot then reply(caller, "Usage: dubz_inv_remove <player> <slot>") return end

	local rec = DubzInv.TakeSlot(target, slot)
	reply(caller, rec and ("Removed " .. (rec.name or "item") .. " from slot " .. slot .. ".") or "That slot is empty.")
end)

add("dubz_inv_clear", function(caller, args)
	local target = findPlayer(caller, args[1])
	if not target then return end

	local count = 0
	for slot in pairs(table.Copy(DubzInv.GetSlots(target))) do
		if DubzInv.TakeSlot(target, slot) then count = count + 1 end
	end

	reply(caller, "Removed " .. count .. " item(s) from " .. target:Nick() .. ".")
end)

add("dubz_inv_givebag", function(caller, args)
	local target = findPlayer(caller, args[1])
	if not target then return end

	-- dubz_inv_givebag [player] small  gives the Small Backpack
	local small = string.lower(args[2] or "") == "small"
	local bag = ents.Create(small and "dubz_backpack_small" or "dubz_backpack")
	if not IsValid(bag) then return end

	bag:Spawn()
	DubzInv.PlaceInFront(bag, target)
	reply(caller, "Spawned a " .. (small and "small" or "big") .. " backpack in front of " .. target:Nick() .. ".")
end)
