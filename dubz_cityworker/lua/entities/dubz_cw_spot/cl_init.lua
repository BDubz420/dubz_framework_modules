include("shared.lua")

-- What a spot looks like while it is broken: a leak hisses and sprays gas, a hydrant sprays water, a fault throws sparks. Nothing is done when it is not active
-- (a hydrant or a bench is just a prop then, and a leak or a fault is nothing at all).
function ENT:Initialize()
	self.emitter = ParticleEmitter(self:GetPos())
	self.nextEmit = 0
end

function ENT:OnRemove()
	if IsValid(self.emitter) then self.emitter:Finish() end
	if self.loop then self.loop:Stop() end
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	local kind = self:GetKind()
	local loopFile = (kind == "leak" and "ambient/gas/steam2.wav") or (kind == "hydrant" and "ambient/water/water_flow_loop1.wav") or nil

	if not self:GetActive() then
		if self.loop and self.loop:IsPlaying() then self.loop:Stop() end
		return
	end

	-- The loop that goes with it
	if loopFile then
		if not self.loop then
			self.loop = CreateSound(self, loopFile)
			self.loop:SetSoundLevel(kind == "leak" and 53 or 60)
		end

		if not self.loop:IsPlaying() then self.loop:Play() end
	end

	local ply = LocalPlayer()
	if not IsValid(ply) or ply:GetPos():DistToSqr(self:GetPos()) > 1500 * 1500 or CurTime() < self.nextEmit or not IsValid(self.emitter) then return end

	if kind == "leak" then
		-- Gas out of the pipe, along the way it faces
		local smoke = self.emitter:Add("particle/smokesprites_00" .. string.format("%02d", math.random(1, 16)), self:GetPos())

		smoke:SetVelocity(self:GetForward() * 250 + VectorRand() * 20)
		smoke:SetDieTime(0.6)
		smoke:SetStartAlpha(70)
		smoke:SetEndAlpha(0)
		smoke:SetAngles(AngleRand())
		smoke:SetStartSize(math.Rand(4, 6))
		smoke:SetEndSize(math.Rand(11, 14))
		smoke:SetGravity(Vector(0, 0, 10))
		smoke:SetColor(170, 180, 150)
		smoke:SetAirResistance(50)

		self.nextEmit = CurTime() + 0.012
	elseif kind == "hydrant" then
		-- A fountain
		local water = self.emitter:Add("effects/splash" .. 2 ^ math.random(0, 2), self:GetPos() + Vector(0, 0, 35))

		water:SetVelocity(Vector(math.Rand(-45, 45), math.Rand(-45, 45), 520))
		water:SetDieTime(2)
		water:SetStartAlpha(200)
		water:SetEndAlpha(50)
		water:SetAngles(AngleRand())
		water:SetStartSize(10)
		water:SetEndSize(50)
		water:SetGravity(Vector(0, 0, -600))
		water:SetColor(255, 255, 255)
		water:SetAirResistance(0)

		self.nextEmit = CurTime() + 0.02
	elseif kind == "electric" then
		local effect = EffectData()
		effect:SetOrigin(self:GetPos())
		effect:SetNormal(self:GetForward())
		effect:SetMagnitude(math.Rand(1, 4))
		effect:SetEntity(self)
		util.Effect("ElectricSpark", effect, true, true)
		util.Effect("TeslaHitboxes", effect, true, true)

		sound.Play("ambient/energy/spark" .. math.random(1, 6) .. ".wav", self:GetPos(), 55)

		self.nextEmit = CurTime() + math.Rand(0.5, 2)
	end
end
