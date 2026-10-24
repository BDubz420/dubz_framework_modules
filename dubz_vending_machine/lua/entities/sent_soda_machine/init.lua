AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_interiors/vendingmachinesoda01a.mdl")
	self:SetUseType(SIMPLE_USE)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)

	self.NextUse = 0
	self.Cans = {}

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end
end

local function cfg() return DubzVending.Config end

local function money(amount)
	return DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(amount) or ("$" .. amount)
end

function ENT:GetSodaPos()
	return self:GetPos() + self:GetForward() * 20 + self:GetRight() * 3 - self:GetUp() * 27
end

function ENT:DropSoda()
	local can = ents.Create("soda_can")
	if not IsValid(can) then return end

	can:SetPos(self:GetSodaPos())
	can:SetAngles(self:GetAngles() + Angle(0, 0, 90))
	can:Spawn()
	can.Born = CurTime()

	local phys = can:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetVelocity(self:GetForward() * 50)
	end

	-- Only so many cans out of one machine at once: the oldest goes
	table.insert(self.Cans, can)

	while #self.Cans > cfg().MaxCansOut do
		local old = table.remove(self.Cans, 1)
		if IsValid(old) then old:Remove() end
	end
end

-- E: pay, and a can drops out
function ENT:Use(activator)
	if not (IsValid(activator) and activator:IsPlayer()) then return end
	if not DubzVending.Enabled() or CurTime() < self.NextUse then return end
	self.NextUse = CurTime() + 1.5

	if activator:GetPos():Distance(self:GetPos()) > cfg().UseDistance + 60 then return end

	-- Out of order: nothing comes out until a city worker has fixed it
	if self:GetBroken() then
		DubzVending.Say(activator, "Out of order.", 1)
		return
	end

	local price = cfg().SodaPrice

	if activator.canAfford and not activator:canAfford(price) then
		DubzVending.Say(activator, "You cannot afford a soda (" .. money(price) .. ").", 1)
		return
	end

	if price > 0 then activator:addMoney(-price) end
	DubzVending.Say(activator, "You bought a soda for " .. money(price) .. ".")

	self:DropSoda()
	self:EmitSound(cfg().BuySound)
end

-- Old cans are cleaned up
function ENT:Think()
	local lifetime = cfg().CanLifetime

	if lifetime > 0 then
		for i = #self.Cans, 1, -1 do
			local can = self.Cans[i]

			if not IsValid(can) then
				table.remove(self.Cans, i)
			elseif CurTime() - (can.Born or CurTime()) > lifetime then
				can:Remove()
				table.remove(self.Cans, i)
			end
		end
	end

	self:NextThink(CurTime() + 1)
	return true
end

function ENT:OnRemove()
	for _, can in pairs(self.Cans or {}) do
		if IsValid(can) then can:Remove() end
	end
end
