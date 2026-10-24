AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- The forge: ore chunks (and metal scrap, which makes steel bars) that touch it join a queue. E switches it on, and it works down the queue, smelting one chunk at a
-- time into one ingot, which comes out of the front. Ore chunks are anonymous: what comes out (and how long it takes, the
-- Materials table's Forge column) is only decided when a chunk starts smelting. Smelting gives Mining XP.
-- Spawn it from the entities tab and keep it with a perma-props tool.
function ENT:Initialize()
	self:SetModel(DubzMining.Config.forgeModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end

	self.Queue = {}   -- one entry per chunk: the player who mined it (or false)
	self.TouchCooldowns = {}
	self:SetNWBool("Processing", false)
	self:SetNWBool("PoweredOn", false)
	self:SetNWString("CurrentIngot", "")
	self:SetNWFloat("ForgeEndTime", 0)
end

-- `forced`: an ingot that is certain (melted scrap makes a steel bar) instead of what ore turns out to be
function ENT:Load(owner, forced)
	self.Queue[#self.Queue + 1] = {owner = IsValid(owner) and owner or false, mat = forced}
	self:EmitSound("physics/metal/metal_box_impact_soft1.wav")

	if self:GetNWBool("PoweredOn") then self:Start() end
	return true
end

-- Smelt the next chunk: this is where it turns out what it was
function ENT:Next()
	local c = DubzMining.Config

	local entry = self.Queue[1]
	local material = entry and ((entry.mat and DubzMining.Material(entry.mat)) or DubzMining.Pick("ingot"))

	if not material then
		self.Queue = {}
		return self:Stop()
	end

	self.Current = material.id
	self:SetNWString("CurrentIngot", material.name)
	self:SetNWFloat("ForgeEndTime", CurTime() + math.max(material.forge, 1))
end

function ENT:Start()
	if not self:GetNWBool("PoweredOn") or #self.Queue == 0 or self:GetNWBool("Processing") then return end

	self:SetNWBool("Processing", true)
	self:EmitSound("ambient/fire/ignite.wav", 75, 100)

	timer.Simple(1.5, function()
		if IsValid(self) and self:GetNWBool("Processing") then self:EmitSound("ambient/fire/fire_big_loop1.wav", 75, 100, 1, CHAN_STATIC) end
	end)

	self:Next()
end

function ENT:Stop()
	self:SetNWBool("Processing", false)
	self:SetNWString("CurrentIngot", "")
	self:SetNWFloat("ForgeEndTime", 0)
	self:StopSound("ambient/fire/ignite.wav")
	self:StopSound("ambient/fire/fire_big_loop1.wav")
end

function ENT:Finish()
	local id = self.Current
	self.Current = nil

	local entry = table.remove(self.Queue, 1)
	if entry and entry.owner then DubzMining.GiveSmeltXP(entry.owner) end

	local ingot = id and ents.Create("dubz_ingot")
	if IsValid(ingot) then
		ingot:SetMat(id)

		local ang = self:GetAngles()
		ingot:SetPos(self:GetPos() + ang:Forward() * 25 + ang:Up() * 10)
		ingot:SetAngles(ang)
		ingot:Spawn()

		local phys = ingot:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetVelocity(ang:Forward() * 60 + ang:Up() * 20 + VectorRand() * 5)
		end

		self:EmitSound("physics/metal/metal_canister_impact_hard" .. math.random(1, 3) .. ".wav", 75, math.random(95, 105))
	end

	if #self.Queue > 0 then self:Next() else self:Stop() end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	local on = not self:GetNWBool("PoweredOn")
	self:SetNWBool("PoweredOn", on)

	if on then
		self:EmitSound("buttons/button9.wav")
		self:Start()
	else
		self:EmitSound("buttons/button14.wav")
		self:Stop()
	end
end

-- One thing going in: an ore chunk joins the queue, metal scrap melts toward a bar. False when it won't take it.
function ENT:Accept(what, variant, miner)
	if what == "dubz_stone" then return self:Load(miner) end

	if what == "dubz_scrap" then
		-- (the scrap addon says whether metal is taken and whether a bar is ready)
		local stub = {GetClass = function() return "dubz_scrap" end, GetMat = function() return variant end}
		local taken, bar = hook.Run("DubzMiningForgeAccepts", self, stub)

		if taken then
			if bar then self:Load(nil, bar) end
			return true
		end
	end

	return false
end

-- Things that touch it: ore chunks and metal scrap go in, one at a time. A dropped STACK of them (Drop or Drop all from the pocket)
-- goes in whole: everything it holds that the forge will take. A minecart pushed into it empties its chunks in.
function ENT:StartTouch(ent)
	if not IsValid(ent) then return end

	if ent:GetClass() == "dubz_cart" and ent.PullStones then
		for _, owner in ipairs(ent:PullStones()) do self:Load(owner) end
		return
	end

	local stack = ent.DubzStack
	local what = stack and stack.class or ent:GetClass()
	if what ~= "dubz_stone" and what ~= "dubz_scrap" then return end

	local index = ent:EntIndex()
	if CurTime() < (self.TouchCooldowns[index] or 0) then return end
	self.TouchCooldowns[index] = CurTime() + 0.5

	local count = stack and (stack.qty or 1) or 1
	local variant = stack and stack.variant or (ent.GetMat and ent:GetMat())
	local miner = (not stack) and ent.Miner or nil

	local taken = 0
	for _ = 1, count do
		if not self:Accept(what, variant, miner) then break end
		taken = taken + 1
	end

	if taken >= count then
		ent:Remove()
	elseif stack and taken > 0 then
		ent:SetStackQty(count - taken)   -- (what did not fit stays on the ground)
	end
end

function ENT:Think()
	if self:GetNWBool("Processing") and CurTime() >= self:GetNWFloat("ForgeEndTime") then self:Finish() end

	self:NextThink(CurTime() + 0.25)
	return true
end

function ENT:OnRemove()
	self:Stop()
end
