-- Shared readers for state the server networks (karma, org, timers).

-- Organisation = the player's gang (Gang12 addon: ply:getGang() returns "" when none).
function BHUD.GetOrg(ply)
	if ply.getGang then return ply:getGang() or "" end
	return ply:GetNWString("gang", "")
end

function BHUD.GetOrgColor(ply)
	local name = BHUD.GetOrg(ply)
	if name ~= "" and gangs and gangs.getColor then return gangs:getColor(name) end
	return color_white
end

-- Karma comes from the separate dubz_karma addon; nil (so the bar entry hides) when it isn't installed.
function BHUD.GetKarma(ply)
	if DubzKarma and DubzKarma.Get then return DubzKarma.Get(ply) end
end

-- Seconds left on a server-set timer stored as an end time on an entity (0 when none/expired).
function BHUD.Remaining(ent, key)
	local finish = ent:GetNWFloat(key, 0)
	if finish <= 0 then return 0 end
	return math.max(0, finish - CurTime())
end

function BHUD.MayorGraceRemaining()
	return BHUD.Remaining(game.GetWorld(), "bhud_mayor_grace_end")
end
