-- Shared readers (the HUD uses these). The server sets the values; clients just read them.

-- Seconds left on a player's NLR (0 when none).
function DubzNLR.Remaining(ply)
	local finish = ply:GetNWFloat("dubz_nlr_end", 0)
	if finish <= 0 then return 0 end
	return math.max(0, finish - CurTime())
end

-- Centre of the NLR zone, or nil when there's no active NLR.
function DubzNLR.ZonePos(ply)
	if DubzNLR.Remaining(ply) <= 0 then return nil end
	return ply:GetNWVector("dubz_nlr_pos")
end

-- True while the player has an active NLR and is inside its zone.
function DubzNLR.InZone(ply)
	local pos = DubzNLR.ZonePos(ply)
	if not pos then return false end
	return ply:GetPos():Distance(pos) <= DubzNLR.Config.zoneRadius
end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzNLR.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("nlr")
end
