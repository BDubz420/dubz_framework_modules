AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local function freeze(ent)
	local phys = ent:GetPhysicsObject()

	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end
end

function ENT:Initialize()
	local cfg = DubzCW.Config
	local kind = self:GetKind()

	if kind == "hydrant" then
		self:SetModel(cfg.HydrantModel)
	elseif kind == "bench" then
		self:SetModel(cfg.BenchModel)
	elseif kind == "rubble" then
		self:SetModel(cfg.RubbleModels[1] or "models/props_debris/concrete_debris128pile001a.mdl")
	else
		self:SetModel("models/hunter/blocks/cube025x025x025.mdl")   -- (a leak or a fault is a point: nothing is drawn)
	end

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	freeze(self)

	if kind == "leak" or kind == "electric" then
		self:SetNoDraw(true)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	elseif kind == "rubble" then
		self:SetNoDraw(true)
		self:SetSolid(SOLID_NONE)   -- (no pile until the job)
	end

	self.DubzCWSpot = true
end

-- A worker has the job (on) or it is done (off)
function ENT:SetWorking(on)
	self:SetActive(on)

	if self:GetKind() ~= "rubble" then return end

	if on then
		-- A pile appears: one of the models, solid
		self:SetModel(table.Random(DubzCW.Config.RubbleModels))
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		freeze(self)
		self:SetNoDraw(false)
		self:SetModelScale(1, 0)
	else
		self:SetNoDraw(true)
		self:SetSolid(SOLID_NONE)
	end
end

function ENT:OnTakeDamage() return 0 end
