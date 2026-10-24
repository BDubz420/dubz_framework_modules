ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Accessory"
ENT.Author = "BDubz420"
ENT.Category = "Dubz Cosmetics"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "CosID")
end

-- What the accessory really is (the box always looks the same)
function ENT:GetItemName()
	if not DubzCosmetics then return "Accessory" end

	local id = self:GetCosID()
	return DubzCosmetics.Get(id) and DubzCosmetics.DisplayName(id) or "Accessory"
end
