AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Items dropped from the pocket. A stack dropped is ONE prop that stands for all of them (a hundred of something is not a hundred props),
-- and it does nothing: pick it up to get the whole stack back, then deploy from the pocket to use it. It holds the pocket record.
local BOX = "models/props_junk/cardboard_box001a.mdl"

-- Call before Spawn: the pocket record this prop stands for
function ENT:SetRecord(rec)
	self.DubzStack = rec
	self:SetNWString("StackName", rec.name or rec.class or "Item")
	self:SetNWBool("DubzHoldE", true)
	self:SetNWInt("StackQty", rec.qty or 1)
end

-- After a partial pickup: what is left
function ENT:SetStackQty(qty)
	if not self.DubzStack then return end

	self.DubzStack.qty = qty
	self:SetNWInt("StackQty", qty)
end

function ENT:Initialize()
	local rec = self.DubzStack or {}
	local model = (rec.model and rec.model ~= "" and util.IsValidModel(rec.model)) and rec.model or BOX

	self:SetModel(model)
	self:PhysicsInit(SOLID_VPHYSICS)

	-- A model without physics would fall through the world: use a box instead
	if not IsValid(self:GetPhysicsObject()) then
		self:SetModel(BOX)
		self:PhysicsInit(SOLID_VPHYSICS)
	end

	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	-- Looks like what it is (a ruby stack is red)
	local data = rec.data or {}
	if istable(data.Color) then self:SetColor(Color(data.Color.r or 255, data.Color.g or 255, data.Color.b or 255, data.Color.a or 255)) end
	if isstring(data.Material) and data.Material ~= "" then self:SetMaterial(data.Material) end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end
end
