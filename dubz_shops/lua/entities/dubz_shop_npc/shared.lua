-- The shop NPC (base): talk to him (E), then open his shop. The shops themselves are rows of the Shops table (!dubzconfig > Shops); the entities
-- below this one (General Store, Furniture Salesman, Starter Kits) are this NPC with a fixed shop. A shop whose Id you add yourself can use this
-- entity: place it, then set its shop with  dubz_shop_set <id>  while looking at it.
ENT.Type = "ai"
ENT.Base = "base_ai"

ENT.PrintName = "Shop NPC"
ENT.Author = "BDubz420"
ENT.Category = "Dubz Shops"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true

ENT.ShopId = "store"

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "ShopId")
end
