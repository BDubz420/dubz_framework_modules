-- Ownership of what players put down. Everything a player takes out of the pocket, buys (the F4 menu or an NPC shop) or drops belongs to them.
-- When the owner leaves the server, their things stay for the time set in the admin menu (Pocket & Backpack > Ownership), and are gone if the
-- owner has not come back by then. Back in time: it is theirs again, as if they had never gone.
local cfg = DubzInv.Config

local pending = {}   -- steamid64 -> {ents = {...}}

-- Marks something as belonging to this player
function DubzInv.Claim(ent, ply)
	if not (IsValid(ent) and IsValid(ply) and ply:IsPlayer()) then return end

	ent.DubzOwnerSid = ply:SteamID64()
end

local function kept(class)
	return table.HasValue(cfg.abandonKeep or {}, string.lower(class))
end

-- Taken out of the pocket and put down
hook.Add("DubzInvDeployed", "DubzInv_Claim", function(ply, ent)
	DubzInv.Claim(ent, ply)
end)

-- Bought in the F4 menu
for _, name in ipairs({"playerBoughtCustomEntity", "playerBoughtShipment", "playerBoughtPistol", "playerBoughtCustomVehicle"}) do
	hook.Add(name, "DubzInv_ClaimBought", function(ply, _, ent)
		DubzInv.Claim(ent, ply)
	end)
end

hook.Add("playerBoughtVehicle", "DubzInv_ClaimBought", function(ply, ent)
	DubzInv.Claim(ent, ply)
end)

-- The owner left: their things are queued; the clock starts now
hook.Add("PlayerDisconnected", "DubzInv_Abandon", function(ply)
	local minutes = tonumber(cfg.abandonMinutes) or 0
	if minutes <= 0 then return end

	local sid = ply:SteamID64()
	local list = {}

	for _, ent in ipairs(ents.GetAll()) do
		if ent.DubzOwnerSid == sid and not kept(ent:GetClass()) then list[#list + 1] = ent end
	end

	if #list == 0 then return end

	pending[sid] = {ents = list}

	timer.Create("DubzInv_Abandon_" .. sid, minutes * 60, 1, function()
		for _, ent in ipairs(list) do
			-- (still theirs: somebody who got hold of it and put it down again owns it, and it stays)
			if IsValid(ent) and ent.DubzOwnerSid == sid then ent:Remove() end
		end

		pending[sid] = nil
	end)
end)

-- Back in time: it is theirs again
hook.Add("PlayerInitialSpawn", "DubzInv_AbandonCancel", function(ply)
	local sid = ply:SteamID64()
	local entry = pending[sid]
	if not entry then return end

	timer.Remove("DubzInv_Abandon_" .. sid)
	pending[sid] = nil

	-- (the owner's game id is new for every visit: the things are pointed at the new one, and their owner variable too)
	timer.Simple(2, function()
		if not IsValid(ply) then return end

		for _, ent in ipairs(entry.ents) do
			if IsValid(ent) and ent.DubzOwnerSid == sid then
				ent.SID = ply.SID
				if ent.Setowning_ent then ent:Setowning_ent(ply) end
				if ent.CPPISetOwner then ent:CPPISetOwner(ply) end
			end
		end
	end)
end)

-- DarkRP removes the bought things (printers, shipments ...) straight away when their owner leaves unless its removal delay is set: the same time
-- is used, so everything waits the same few minutes (and DarkRP gives it back if the owner is quick).
hook.Add("InitPostEntity", "DubzInv_RemovalDelay", function()
	timer.Simple(2, function()
		local minutes = tonumber(cfg.abandonMinutes) or 0

		if minutes > 0 and GAMEMODE and GAMEMODE.Config then GAMEMODE.Config.entremovedelay = minutes * 60 end
	end)
end)
