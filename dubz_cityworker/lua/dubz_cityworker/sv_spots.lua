-- The spots of the street jobs (leaks, hydrants, rubble, electrical faults, benches): where they are, saved for each map (data/dubz_cityworker/spots_<map>.txt),
-- put down and taken away with the City Worker Placer tool (superadmins). A spot is an entity (dubz_cw_spot) that sits quiet until a worker is given the job.
util.AddNetworkString("DubzCW_PlaceAdd")      -- client -> server: put a spot of this kind where the tool points
util.AddNetworkString("DubzCW_PlaceRemove")   -- client -> server: take away the spot nearest to where the tool points
util.AddNetworkString("DubzCW_SpotList")      -- server -> client: every spot of the map (the tool draws them)

local rows = {}      -- the saved list: {kind, x, y, z, p, yaw, r}
local spawned = {}   -- id -> the entity

local function path() return "dubz_cityworker/spots_" .. game.GetMap() .. ".txt" end

local function save()
	file.CreateDir("dubz_cityworker")
	file.Write(path(), util.TableToJSON(rows))
end

local function spawnRow(id, row)
	local ent = ents.Create("dubz_cw_spot")
	if not IsValid(ent) then return end

	ent:SetKind(row.kind)
	ent:SetSpotId(id)
	ent:SetPos(Vector(row.x, row.y, row.z))
	ent:SetAngles(Angle(row.p, row.yaw, row.r))
	ent:Spawn()

	spawned[id] = ent
end

-- (Re)builds every spot of this map from the saved list
function DubzCW.LoadSpots()
	for _, ent in ipairs(ents.FindByClass("dubz_cw_spot")) do ent:Remove() end

	spawned = {}
	rows = {}

	if file.Exists(path(), "DATA") then rows = util.JSONToTable(file.Read(path(), "DATA") or "[]") or {} end

	for id, row in ipairs(rows) do spawnRow(id, row) end
end

hook.Add("InitPostEntity", "DubzCW_LoadSpots", function() timer.Simple(2, DubzCW.LoadSpots) end)
hook.Add("PostCleanupMap", "DubzCW_LoadSpots", function() timer.Simple(1, DubzCW.LoadSpots) end)

-- A spot no worker has (and that is not broken now), picked at random: what the tasks look for
function DubzCW.FindSpot(kind)
	local list = {}

	for _, ent in ipairs(ents.FindByClass("dubz_cw_spot")) do
		if ent:GetKind() == kind and not ent.DubzCWTask and not ent:GetActive() then list[#list + 1] = ent end
	end

	if #list == 0 then return nil end

	return list[math.random(#list)]
end

-- The tool's list ------------------------------------------------------------------------------------------------------------------------------------

function DubzCW.SendSpots(ply)
	if not (IsValid(ply) and ply:IsSuperAdmin()) then return end

	local list = {}

	for id, row in ipairs(rows) do list[#list + 1] = {id = id, kind = row.kind, x = row.x, y = row.y, z = row.z, p = row.p, yaw = row.yaw, r = row.r} end

	net.Start("DubzCW_SpotList")
		net.WriteString(util.TableToJSON(list))
	net.Send(ply)
end

-- Where the tool points: props count too (a pipe you put down), everything that stops a bullet
local function aim(ply)
	return util.TraceLine({start = ply:GetShootPos(), endpos = ply:GetShootPos() + ply:GetAimVector() * 8000, filter = ply, mask = MASK_SHOT})
end

local function tell(ply, text, kind)
	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind or 0, 5, text) else ply:ChatPrint(text) end
end

-- Putting one down: where the tool points, facing the way that suits it
net.Receive("DubzCW_PlaceAdd", function(_, ply)
	if not (IsValid(ply) and ply:IsSuperAdmin()) then return end

	local kind = net.ReadString()
	local valid = false

	for _, entry in ipairs(DubzCW.SpotKinds) do
		if entry.id == kind then valid = true end
	end

	if not valid then return end

	local trace = aim(ply)
	local pos, normal = trace.HitPos, trace.HitNormal
	local yaw = ply:EyeAngles().y
	local ang

	if kind == "leak" or kind == "electric" then
		-- A point on a pipe or a light: sprays out along the surface it is on
		ang = normal:Angle()
		pos = pos + normal
	elseif kind == "hydrant" then
		ang = Angle(0, math.Round((yaw + 180) / 30) * 30, 0)
	elseif kind == "rubble" then
		ang = Angle(0, math.random(0, 359), 0)
	else
		ang = Angle(0, math.Round((yaw + 180) / 15) * 15, 0)   -- (a bench faces the way you faced it from)
	end

	rows[#rows + 1] = {kind = kind, x = pos.x, y = pos.y, z = pos.z, p = ang.p, yaw = ang.y, r = ang.r}
	save()
	spawnRow(#rows, rows[#rows])

	tell(ply, "Placed a " .. kind .. " spot (number " .. #rows .. ").")
	DubzCW.SendSpots(ply)
end)

-- Taking one away: the nearest to where the tool points
net.Receive("DubzCW_PlaceRemove", function(_, ply)
	if not (IsValid(ply) and ply:IsSuperAdmin()) then return end

	local point = aim(ply).HitPos
	local bestId, bestDistance

	for id, row in ipairs(rows) do
		local distance = Vector(row.x, row.y, row.z):Distance(point)

		if distance < (bestDistance or 250) then bestId, bestDistance = id, distance end
	end

	if not bestId then tell(ply, "No spot near where you are pointing.", 1) return end

	-- (a worker on that job has it called off)
	local ent = spawned[bestId]
	if IsValid(ent) and ent.DubzCWTask then DubzCW.Cancel(ent.DubzCWTask, "That spot was taken away.") end

	table.remove(rows, bestId)
	save()
	DubzCW.LoadSpots()

	tell(ply, "Removed that spot. The numbers after it moved down by one.")
	DubzCW.SendSpots(ply)
end)

concommand.Add("dubz_cw_spots_clear", function(ply)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end

	rows = {}
	save()
	DubzCW.LoadSpots()

	if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, "All city worker spots of this map were removed.") end
end)
