ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Health Charger"
ENT.Category = "Dubz Chargers"
ENT.Author = "BDubz420"
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")
end