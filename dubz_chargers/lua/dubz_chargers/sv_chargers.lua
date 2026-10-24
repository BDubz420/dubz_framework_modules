-- The health and armor chargers: pay to use one, hold E to charge, the owner (a medic) earns a cut.
-- Both entities (lua/entities/dubz_health_charger, dubz_armor_charger) call DubzChargers.Setup(ENT, kind) so they
-- share one implementation. Every number comes from DubzChargers.Config (admin menu: Chargers).
local cfg = DubzChargers.Config

local KINDS = {
	health = {
		noun = "health charger", model = "models/props_combine/health_charger001.mdl", net = "Dubz_HealthCharger_Timer",
		get = function(ply) return ply:Health() end,
		set = function(ply, value) ply:SetHealth(value) end,
		max = function(ply) return ply:GetMaxHealth() end,
		settings = function() return cfg.health end,
	},
	armor = {
		noun = "armor charger", model = "models/props_combine/suit_charger001.mdl", net = "Dubz_ArmorCharger_Timer",
		get = function(ply) return ply:Armor() end,
		set = function(ply, value) ply:SetArmor(value) end,
		max = function() return cfg.armor.maxArmor end,
		settings = function() return cfg.armor end,
	},
}

local CLASSES = {dubz_health_charger = true, dubz_armor_charger = true}

-- The charger's owner: DarkRP's owning_ent when it was bought from F4, else the owner set when it was spawned
function DubzChargers.GetOwner(ent)
	local owner = ent.Getowning_ent and ent:Getowning_ent()
	if not IsValid(owner) then owner = ent:GetNWEntity("Owner") end
	return IsValid(owner) and owner or nil
end

function DubzChargers.Setup(ENT, kindName)
	local kind = KINDS[kindName]
	util.AddNetworkString(kind.net)

	function ENT:Initialize()
		self:SetModel(kind.model)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:Wake() end

		self:SetUseType(SIMPLE_USE)
		self:SetNWInt("Price", kind.settings().defaultPrice)
		self:SetNWInt("TimeLeft", 0)
		self:SetNWBool("StopTimerOnFull", cfg.stopTimerOnFull)

		self.UsedBy = nil
		self.NextTick = 0
		self.Charging = false
		self.timeLeft = 0   -- CurTime() when the current use ends
	end

	local function sound(self, name)
		if cfg.sounds then self:EmitSound(name, 75, 100) end
	end

	function ENT:SendTimer(ply, seconds)
		net.Start(kind.net)
		net.WriteEntity(self)
		net.WriteFloat(seconds)
		net.Send(ply)
	end

	function ENT:Use(activator, caller)
		if not DubzChargers.Enabled() then return end
		if not IsValid(caller) or not caller:IsPlayer() then return end

		if self.UsedBy and self.UsedBy ~= caller then
			DarkRP.notify(caller, 1, 4, "This " .. kind.noun .. " is already in use by someone else.")
			return
		end

		-- Prevent spam
		if self.LastDeniedSound and CurTime() - self.LastDeniedSound < 1 then return end

		if kind.get(caller) >= kind.max(caller) then
			sound(self, "items/suitchargeno1.wav")
			self.LastDeniedSound = CurTime()
			return
		end

		if not self.UsedBy then
			local price = self:GetNWInt("Price", kind.settings().defaultPrice)
			if caller:getDarkRPVar("money") < price then
				DarkRP.notify(caller, 1, 4, "You can't afford this!")
				return
			end

			caller:addMoney(-price)
			DarkRP.notify(caller, 0, 4, "You paid $" .. price .. " to use the " .. kind.noun .. ".")

			-- Pay the owner their cut
			local owner = DubzChargers.GetOwner(self)
			if owner and owner ~= caller then
				local cut = math.floor(price * cfg.ownerCut / 100)
				if cut > 0 then
					owner:addMoney(cut)
					DarkRP.notify(owner, 0, 4, "You earned $" .. cut .. " from your " .. kind.noun .. ".")
				end
			end

			self.UsedBy = caller
			self.timeLeft = CurTime() + cfg.useSeconds
			sound(self, "items/suitchargeok1.wav")
			self:SendTimer(caller, cfg.useSeconds)
		end

		-- Start charging if holding E
		if caller:KeyDown(IN_USE) and not self.Charging then self:StartCharging(caller) end
	end

	function ENT:StartCharging(ply)
		if not IsValid(ply) then return end

		self.Charging = true
		self.NextTick = CurTime()
		sound(self, "items/suitcharge1.wav")
	end

	function ENT:StopCharging()
		if self.Charging then
			self:StopSound("items/suitcharge1.wav")
			if kindName == "armor" then self:SetSequence("idle") end
		end

		self.Charging = false
	end

	function ENT:ResetCharger()
		self:StopCharging()
		self.UsedBy = nil
		self.timeLeft = 0

		sound(self, "items/suitchargeok1.wav")   -- ready again
	end

	function ENT:Think()
		local ply = self.UsedBy

		if ply then
			-- Walked away, died, or left
			if not IsValid(ply) or not ply:Alive() or ply:GetPos():Distance(self:GetPos()) > cfg.walkAwayDistance then
				self:ResetCharger()
				return
			end

			local remaining = math.max(0, self.timeLeft - CurTime())

			if remaining <= 0 then
				self:ResetCharger()
				return
			end

			if self.Charging then
				if not ply:KeyDown(IN_USE) then
					self:StopCharging()
					return
				end

				if CurTime() >= self.NextTick then
					local settings = kind.settings()
					self.NextTick = CurTime() + settings.tickSeconds

					if kind.get(ply) < kind.max(ply) then
						kind.set(ply, math.min(kind.max(ply), kind.get(ply) + settings.amountPerTick))
					else
						if self:GetNWBool("StopTimerOnFull", true) then self:ResetCharger() else self:StopCharging() end
						return
					end
				end
			elseif ply:KeyDown(IN_USE) then
				self:StartCharging(ply)
			end

			self:SendTimer(ply, remaining)
		end

		self:NextThink(CurTime())
		return true
	end

	function ENT:OnRemove()
		self:StopSound("items/suitcharge1.wav")
	end
end

-- /setchargerprice <amount>: the owner sets the price of the charger they are looking at
hook.Add("PlayerSay", "DubzChargers_PriceCommand", function(ply, text)
	if not DubzChargers.Enabled() then return end

	local command = string.lower(cfg.priceCommand)
	if string.lower(string.sub(text, 1, #command)) ~= command then return end

	local price = tonumber(string.Explode(" ", text)[2])
	if not price or price < cfg.minPrice or price > cfg.maxPrice then
		DarkRP.notify(ply, 1, 4, "Invalid price (" .. cfg.minPrice .. " to " .. cfg.maxPrice .. ").")
		return ""
	end

	local ent = ply:GetEyeTrace().Entity

	if IsValid(ent) and CLASSES[ent:GetClass()] and ent:GetPos():Distance(ply:GetPos()) < 200 then
		if DubzChargers.GetOwner(ent) ~= ply then
			DarkRP.notify(ply, 1, 4, "You don't own this charger.")
			return ""
		end

		ent:SetNWInt("Price", math.floor(price))
		DarkRP.notify(ply, 0, 4, "Price set to $" .. math.floor(price))
		return ""
	end

	DarkRP.notify(ply, 1, 4, "Look at a charger you own to set its price.")
	return ""
end)

-- Spawned from the spawn menu: the spawner owns it (DarkRP's F4 purchase already sets owning_ent)
hook.Add("PlayerSpawnedSENT", "DubzChargers_SetOwner", function(ply, ent)
	if not CLASSES[ent:GetClass()] then return end

	ent:SetNWEntity("Owner", ply)
	if ent.Setowning_ent then ent:Setowning_ent(ply) end
end)

hook.Add("PhysgunPickup", "DubzChargers_Physgun", function(ply, ent)
	if not IsValid(ent) or not CLASSES[ent:GetClass()] then return end
	if not DubzChargers.Enabled() then return end

	if not cfg.physgunOwnerOnly then return true end
	if DubzChargers.GetOwner(ent) == ply or ply:IsAdmin() then return true end
end)
