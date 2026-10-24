-- The soda machine: staff put it in the world; press E to pay and a can drops out.
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Vending Machine"
ENT.Author = "BDubz420"
ENT.Contact = "Via Steam"
ENT.Category = "Dubz Vending Machine"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Broken")   -- out of order (a city worker is on the job: see the City Worker addon)
end
