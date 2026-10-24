-- Starts the NLR on death and watches whether the player walks back into their zone.
local cfg = DubzNLR.Config

-- The player "types" the message into OOC chat, so everyone sees it the normal way (name, OOC tag, colours).
local function announce(ply, message)
	if not cfg.announce then return end

	ply:ConCommand('say "' .. cfg.chatPrefix .. ' ' .. message .. '"')
end

hook.Add("PlayerDeath", "DubzNLR_Start", function(victim)
	if not DubzNLR.Enabled() then return end
	victim:SetNWFloat("dubz_nlr_end", CurTime() + cfg.time)
	victim:SetNWVector("dubz_nlr_pos", victim:GetPos())

	victim.DubzNLR_InZone = false
	victim.DubzNLR_EnterSince = nil
	victim.DubzNLR_Announced = false
end)

timer.Create("DubzNLR_Watch", cfg.checkInterval, 0, function()
	if not DubzNLR.Enabled() then return end

	for _, ply in ipairs(player.GetAll()) do
		if not ply:Alive() then continue end

		-- NLR over (or never started): forget any zone state quietly
		if DubzNLR.Remaining(ply) <= 0 then
			ply.DubzNLR_InZone, ply.DubzNLR_EnterSince, ply.DubzNLR_Announced = false, nil, false
			continue
		end

		local inside = DubzNLR.InZone(ply)

		if inside and not ply.DubzNLR_InZone then
			ply.DubzNLR_InZone = true
			ply.DubzNLR_EnterSince = CurTime()
		elseif inside and ply.DubzNLR_EnterSince and CurTime() - ply.DubzNLR_EnterSince >= cfg.enterDelay then
			ply.DubzNLR_EnterSince = nil

			if CurTime() >= (ply.DubzNLR_NextAnnounce or 0) then
				ply.DubzNLR_NextAnnounce = CurTime() + cfg.alertCooldown
				ply.DubzNLR_Announced = true
				announce(ply, cfg.enterMessage)
			end
		elseif not inside and ply.DubzNLR_InZone then
			ply.DubzNLR_InZone = false
			ply.DubzNLR_EnterSince = nil

			if ply.DubzNLR_Announced then
				ply.DubzNLR_Announced = false
				announce(ply, cfg.leaveMessage)
			end
		end
	end
end)
