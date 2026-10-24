AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- A minecart: ore chunks that touch it are collected; push the cart into a forge to load them all at once.
local CAPACITY = 20

function ENT:Initialize()
	self:SetModel(DubzMining.Config.cartModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end

	self.Owners = {}
	self:SetStored(0)
end

function ENT:SpawnFunction(ply, tr, class)
	if not tr.Hit then return end

	local ent = ents.Create(class)
	ent:SetPos(tr.HitPos + tr.HitNormal * 16)
	ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:StartTouch(ent)
	if not IsValid(ent) or ent:GetClass() ~= "dubz_stone" or self:GetStored() >= CAPACITY then return end

	self.Owners[#self.Owners + 1] = IsValid(ent.Miner) and ent.Miner or false
	self:SetStored(#self.Owners)

	ent:Remove()
	self:EmitSound("items/ammo_pickup.wav")
end

-- Called by the forge: hands over every chunk (the player who mined each) and empties the cart
function ENT:PullStones()
	local owners = self.Owners
	self.Owners = {}
	self:SetStored(0)
	return owners
end
