ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Minecart"
ENT.Author = "Dubz"
ENT.Category = "Dubz Mining System"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Stored")
end
