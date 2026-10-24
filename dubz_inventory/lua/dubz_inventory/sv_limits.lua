-- Deploy limits. Items in the pocket don't exist in the world, so DarkRP's F4 limits (max printers, stoves ...) can't
-- see them. The rule here: only what is DEPLOYED counts. Taking an item out of the pocket puts it on the player's
-- count; picking it back up takes it off. So buying 3 printers in F4, pocketing them, and buying 3 more can't get past
-- the limit once they are all put down: the third drop is refused with "You reached the max of 3 ...".
--
-- The limit for an entity is the "Deploy Limits" table in the admin menu if it has a row, otherwise the shop's own max
-- (when "Use Shop Limits" is on). The same number is also given to the F4 shop so buying and dropping agree.
local cfg = DubzInv.Config

-- The F4 shop entry for an entity class (nil when it isn't sold in the shop)
function DubzInv.ShopEntry(class)
	for _, entry in ipairs(DarkRPEntities or {}) do
		if entry.ent == class then return entry end
	end
end

-- The most of this class a player may have deployed (nil = no limit)
function DubzInv.DeployMax(class, entry)
	if not cfg.deployLimits then return nil end

	local rule = DubzInv.DeployRules and DubzInv.DeployRules[class]
	if rule ~= nil then return rule > 0 and rule or nil end

	entry = entry or DubzInv.ShopEntry(class)
	if cfg.useShopLimits and entry and entry.max and entry.max > 0 then return entry.max end

	return nil
end

-- How many of this class the player has deployed. Shop items use DarkRP's own count (which this file keeps right for
-- the pocket); anything else is counted in the world.
local function deployed(ply, class, entry)
	if entry and ply.customEntityCount then return ply:customEntityCount(entry) end

	local count = 0
	for _, ent in ipairs(ents.FindByClass(class)) do
		local owner = ent.Getowning_ent and ent:Getowning_ent() or (ent.CPPIGetOwner and ent:CPPIGetOwner())
		if owner == ply then count = count + 1 end
	end

	return count
end

-- How many of `want` can be put down. Returns the number allowed (0 = none) and a message when it is fewer.
function DubzInv.CanDeploy(ply, rec, want)
	want = want or 1

	local class = rec and ((rec.data and rec.data.Class) or rec.class)
	if not class then return want end

	local entry = DubzInv.ShopEntry(class)
	local max = DubzInv.DeployMax(class, entry)
	if not max then return want end

	local room = max - deployed(ply, class, entry)
	local name = entry and entry.name or class

	if room <= 0 then
		return 0, "You reached the max of " .. max .. " " .. name .. " and can't deploy more."
	end

	if room < want then return room, "You can only deploy " .. room .. " more " .. name .. " (the max is " .. max .. ")." end

	return want
end

-- Deploying / pocketing keep DarkRP's count in step: only deployed items count
hook.Add("DubzInvDeployed", "DubzInv_CountUp", function(ply, ent)
	local entry = ent.DarkRPItem
	if entry and ply.addCustomEntity then ply:addCustomEntity(entry) end
end)

hook.Add("DubzInvPocketed", "DubzInv_CountDown", function(owner, ent)
	local entry = ent.DarkRPItem
	if entry and IsValid(owner) and owner.removeCustomEntity then owner:removeCustomEntity(entry) end
end)

-- The shop uses the same numbers: an entity with a row in the table gets that max in the F4 shop too
local original = {}

function DubzInv.ApplyShopLimits()
	for _, entry in ipairs(DarkRPEntities or {}) do
		if original[entry] == nil then original[entry] = entry.getMax or false end

		local rule = DubzInv.DeployRules and DubzInv.DeployRules[entry.ent]

		if cfg.deployLimits and rule ~= nil then
			entry.getMax = function() return rule end
		else
			entry.getMax = original[entry] or nil
		end
	end
end

hook.Add("InitPostEntity", "DubzInv_ShopLimits", function() timer.Simple(2, DubzInv.ApplyShopLimits) end)
