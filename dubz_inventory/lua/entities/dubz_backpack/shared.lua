ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Big Backpack"
ENT.Author = "BDubz420"
ENT.Category = "Dubz Inventory"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Slots")
end
