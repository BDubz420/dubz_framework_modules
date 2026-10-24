-- Walking / running XP: earned by actually moving on the ground, once per second.
local mcfg = DubzSkills.Config.movement

timer.Create("DubzSkills_MovementXP", 1, 0, function()
	if not mcfg.enabled or not DubzSkills.Enabled() then return end

	for _, ply in ipairs(player.GetAll()) do
		if not ply:Alive() or ply:InVehicle() then continue end
		if ply:GetMoveType() ~= MOVETYPE_WALK or not ply:OnGround() then continue end

		local speed = ply:GetVelocity():Length2D()
		if speed < 30 then continue end

		-- Moving noticeably faster than walking pace counts as running
		local walk = DubzSkills.GetSpeeds(ply)
		if ply:KeyDown(IN_SPEED) and speed > walk * 1.15 then
			DubzSkills.AddXP(ply, "running", mcfg.runXPPerSecond)
		else
			DubzSkills.AddXP(ply, "walking", mcfg.walkXPPerSecond)
		end
	end
end)

-- Stamina ----------------------------------------------------------------------------------------------
-- No bar: running drains it, and when it hits zero you are out of breath (dubz_exhausted) - sprinting is
-- disabled in SetupMove and a heavy breathing sound plays until you have recovered.
local scfg = DubzSkills.Config.stamina
local TICK = 0.1

local function breathe(ply, pitch, volume)
	if not DubzSkills.Config.breathSounds then return end
	ply:EmitSound(scfg.exhaustSound, scfg.soundLevel, pitch, volume)
end

hook.Add("PlayerSpawn", "DubzSkills_StaminaReset", function(ply)
	ply.DubzStamina = scfg.max
	ply:SetNWBool("dubz_exhausted", false)
end)

timer.Create("DubzSkills_Stamina", TICK, 0, function()
	if not scfg.enabled or not mcfg.enabled or not DubzSkills.Enabled() then return end

	for _, ply in ipairs(player.GetAll()) do
		if not ply:Alive() then
			ply.DubzStamina = scfg.max
			if ply:GetNWBool("dubz_exhausted") then ply:SetNWBool("dubz_exhausted", false) end
			continue
		end

		local stamina = ply.DubzStamina or scfg.max
		local exhausted = ply:GetNWBool("dubz_exhausted")
		local speed = ply:GetVelocity():Length2D()
		local walk = DubzSkills.GetSpeeds(ply)

		local running = not exhausted and ply:GetMoveType() == MOVETYPE_WALK and ply:OnGround() and not ply:InVehicle()
			and ply:KeyDown(IN_SPEED) and speed > walk * 1.15

		if running then
			local drain = scfg.drainPerSecond * (1 - scfg.drainReductionPerLevel * DubzSkills.GetLevel(ply, "running"))
			stamina = math.max(0, stamina - drain * TICK)
		else
			local regen = speed < 30 and scfg.regenIdle or scfg.regenMoving
			stamina = math.min(scfg.max, stamina + regen * TICK)
		end

		ply.DubzStamina = stamina

		if not exhausted and stamina <= 0 then
			ply:SetNWBool("dubz_exhausted", true)
			ply.DubzNextBreath = CurTime() + scfg.breathInterval
			breathe(ply, 80, 1)
		elseif exhausted then
			if stamina >= scfg.recoverAt then
				ply:SetNWBool("dubz_exhausted", false)
				breathe(ply, 110, 0.6)
			elseif CurTime() >= (ply.DubzNextBreath or 0) then
				ply.DubzNextBreath = CurTime() + scfg.breathInterval
				breathe(ply, 85, 0.9)
			end
		end
	end
end)
