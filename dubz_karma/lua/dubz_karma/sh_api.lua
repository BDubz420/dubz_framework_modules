-- Shared readers other addons (HUD, scoreboard) use. All values are networked by the server.

-- Karma, or nil before the server has sent it.
function DubzKarma.Get(ply)
	local karma = ply:GetNWInt("dubz_karma", -1)
	if karma < 0 then return nil end
	return karma
end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzKarma.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("karma")
end

function DubzKarma.FindCommend(id)
	for _, kind in ipairs(DubzKarma.Commends) do
		if kind.id == id then return kind end
	end
end

-- How many times a player has received a commend kind.
function DubzKarma.GetCommend(ply, id)
	return ply:GetNWInt("dubz_cm_" .. id, 0)
end

function DubzKarma.TotalCommends(ply)
	local total = 0
	for _, kind in ipairs(DubzKarma.Commends) do total = total + DubzKarma.GetCommend(ply, kind.id) end
	return total
end

-- The kind a player has received most (their "status" icon), and its count. nil when they have none.
function DubzKarma.TopCommend(ply)
	local best, bestCount = nil, 0

	for _, kind in ipairs(DubzKarma.Commends) do
		local count = DubzKarma.GetCommend(ply, kind.id)
		if count > bestCount then best, bestCount = kind, count end
	end

	return best, bestCount
end
