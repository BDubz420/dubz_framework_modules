ENT.Type = "ai"
ENT.Base = "base_ai"

ENT.PrintName = "Cosmetics Store Clerk"
ENT.Author = "BDubz420"
ENT.Category = "Dubz Cosmetics"
ENT.Spawnable = false   -- the clothing / accessories clerks below are the spawnable ones
ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "Kind")   -- "clothing" or "accessories"
end
