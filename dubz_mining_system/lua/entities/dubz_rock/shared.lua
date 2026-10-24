ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Rock"
ENT.Category = "Dubz Mining System"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "RockHP")
	self:NetworkVar("Int", 1, "RockMax")
	self:NetworkVar("Bool", 0, "Mined")
end
