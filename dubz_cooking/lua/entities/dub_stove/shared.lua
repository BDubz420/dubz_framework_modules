ENT.Base = "base_gmodentity"
ENT.Type = "anim"

ENT.PrintName		= "Cooking Stove"
ENT.Category 		= "Dubz Cooking Mod"
ENT.Author			= "BDubz420"

ENT.Purpose 		= "To allow players to cook foor as the cook job."

ENT.Spawnable			= true
ENT.AdminSpawnable		= true

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "MilkAmount" )
	self:NetworkVar( "Float", 1, "IngAmount" )
	self:NetworkVar( "Float", 2, "Timer" )
	self:NetworkVar("Entity",3,"owning_ent")
end
