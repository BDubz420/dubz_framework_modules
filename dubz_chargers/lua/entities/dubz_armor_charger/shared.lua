ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Armor Charger"
ENT.Author = "BDubz420"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category        = "Dubz Chargers"
ENT.Purpose = "An armor station."

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")
end