-- Shared readers. The server networks capacity and the worn backpack; the slot contents go to the owner only.

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzInv.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("inventory")
end

function DubzInv.GetCapacity(ply)
	return ply:GetNWInt("dubz_inv_cap", DubzInv.Config.slots)
end

function DubzInv.HasBag(ply)
	return ply:GetNWBool("dubz_inv_hasbag", false)
end

-- Model of the worn backpack ("" when none)
function DubzInv.GetBagModel(ply)
	return ply:GetNWString("dubz_inv_bagmodel", "")
end

-- The two backpacks: the Big Backpack (dubz_backpack) and the Small Backpack (dubz_backpack_small). Told apart by their model.
function DubzInv.IsBagClass(class)
	return class == "dubz_backpack" or class == "dubz_backpack_small"
end

function DubzInv.IsSmallModel(model)
	return string.lower(model or "") == string.lower(DubzInv.Config.smallBagModel or "")
end

function DubzInv.BagClassForModel(model)
	return DubzInv.IsSmallModel(model) and "dubz_backpack_small" or "dubz_backpack"
end

-- What a player wears on their back: "" (no backpack), "small" or "big"
function DubzInv.BagSize(ply)
	if not DubzInv.HasBag(ply) then return "" end

	return DubzInv.IsSmallModel(DubzInv.GetBagModel(ply)) and "small" or "big"
end

-- How many of an item fit in one slot (see `stacking` in sh_config.lua). Always at least 1.
function DubzInv.GetStackLimit(class, model, variant)
	-- Other addons can decide for their own items (accessories stack per accessory id): return a number
	local custom = hook.Run("DubzInvStackLimit", class, model, variant)
	if custom then return math.max(1, math.floor(custom)) end

	local stacking = DubzInv.Config.stacking
	local limits = stacking.limits

	local limit = limits["model:" .. string.lower(model or "")] or limits[class or ""] or stacking.default
	return math.max(1, math.floor(limit))
end
