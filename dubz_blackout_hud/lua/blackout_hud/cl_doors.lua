-- Door ownership text drawn on the door itself (3D2D), plus an "F2" prompt at the crosshair.
-- Replaces DarkRP's own door display (DarkRP_EntityDisplay is hidden in cl_hud.lua).
local WHITE = Color(255, 255, 255)
local BLACK = Color(0, 0, 0, 200)

local nearby = {}        -- doors close enough to draw, refreshed a few times a second
local layouts = {}       -- door -> cached text placement
local nextRefresh = 0

-- DarkRP door helpers (guarded: different DarkRP versions expose different methods) --------------

local function isDoor(ent)
	return IsValid(ent) and ent.isDoor and ent.isKeysOwnable and ent:isDoor() and ent:isKeysOwnable()
end

local function isOwnable(door)
	return not (door.getKeysNonOwnable and door:getKeysNonOwnable())
end

local function getOwner(door)
	local owner = door.getDoorOwner and door:getDoorOwner()
	if IsValid(owner) then return owner end
end

local function getCoowners(door, owner)
	local out = {}
	if not door.isKeysOwnedBy then return out end

	for _, ply in ipairs(player.GetAll()) do
		if ply ~= owner and door:isKeysOwnedBy(ply) then out[#out + 1] = ply:Nick() end
	end

	table.sort(out)
	return out
end

-- Teams/groups a door is restricted to (police doors etc.).
local function getGroups(door)
	local out = {}

	if door.getKeysDoorGroup and door:getKeysDoorGroup() then
		out[1] = door:getKeysDoorGroup()
	elseif door.getKeysDoorTeams then
		for id in pairs(door:getKeysDoorTeams() or {}) do out[#out + 1] = team.GetName(id) end
		table.sort(out)
	end

	return out
end

-- Placement ---------------------------------------------------------------------------------------

-- Text sits on the door's two big faces: find the thinnest axis of its bounds and use it as the normal.
local function buildLayout(door)
	local size = door:OBBMaxs() - door:OBBMins()
	local axis, thin = 1, size.x
	if size.y < thin then axis, thin = 2, size.y end
	if size.z < thin then axis, thin = 3, size.z end

	local normal = Vector(0, 0, 0)
	normal[axis] = 1

	local ang = Angle(0, normal:Angle().y + 90, 90)
	local base = door:OBBCenter() + Vector(0, 0, 15)
	local offset = thin / 2 + BHUD.Config.doorSurfaceOffset

	local backAng = Angle(ang.p, ang.y, ang.r)
	backAng:RotateAroundAxis(backAng:Right(), 180)

	return {
		front = {pos = base + ang:Up() * offset, ang = ang},
		back = {pos = base - ang:Up() * offset, ang = backAng},
	}
end

local function refreshNearby(lp)
	table.Empty(nearby)

	for _, ent in ipairs(ents.FindInSphere(lp:GetPos(), BHUD.Config.doorDistance + 100)) do
		if isDoor(ent) and isOwnable(ent) then
			local owner = getOwner(ent)
			local title = ent.getKeysTitle and ent:getKeysTitle()

			nearby[#nearby + 1] = {
				door = ent,
				owner = owner,
				title = title,
				coowners = getCoowners(ent, owner),
				groups = getGroups(ent),
				seenAt = (layouts[ent] and layouts[ent].seenAt) or nil,
			}

			layouts[ent] = layouts[ent] or buildLayout(ent)
		end
	end
end

local function fade(elapsed, delay)
	return math.Clamp((elapsed - delay) / 0.6, 0, 1)
end

local function text(str, font, y, alpha)
	draw.SimpleTextOutlined(str, font, 0, y, Color(255, 255, 255, 255 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, 200 * alpha))
end

hook.Add("PostDrawTranslucentRenderables", "BHUD_DoorDisplay", function(depth, sky)
	if sky or BHUD.Cinematic then return end

	local lp = LocalPlayer()
	if not IsValid(lp) or not lp:Alive() then return end

	if CurTime() > nextRefresh then
		nextRefresh = CurTime() + 0.4
		refreshNearby(lp)
	end

	local eye = lp:GetShootPos()
	local maxDist = BHUD.Config.doorDistance

	for _, info in ipairs(nearby) do
		local door = info.door
		if not IsValid(door) then continue end

		local dist = door:GetPos():Distance(eye)
		if dist > maxDist then
			layouts[door].seenAt = nil
			continue
		end

		local layout = layouts[door]
		layout.seenAt = layout.seenAt or CurTime()
		local elapsed = CurTime() - layout.seenAt

		-- Pick whichever face the player is looking at.
		local side = layout.front
		local worldAng = door:LocalToWorldAngles(side.ang)
		if worldAng:Up():Dot(eye - door:WorldSpaceCenter()) < 0 then
			side = layout.back
			worldAng = door:LocalToWorldAngles(side.ang)
		end

		local distFade = math.cos((dist / maxDist) * (math.pi / 2)) ^ 2

		cam.Start3D2D(door:LocalToWorld(side.pos), worldAng, BHUD.Config.doorScale)
			if #info.groups > 0 then
				for i, name in ipairs(info.groups) do
					text(name, "daHUDDoorText", 40 + 28 * (i - 1), fade(elapsed, 0.2 * i) * distFade)
				end
			else
				local title = info.title
				if title and #title > 16 then title = string.sub(title, 1, 16) .. "..." end

				text(info.owner and (title or "Private Property") or "Unowned", "daHUDDoorTitle", 10, fade(elapsed, 0) * distFade)

				if info.owner then
					local alpha = fade(elapsed, 0.3) * distFade
					text(info.owner:Nick(), "daHUDDoorText", 42, alpha)

					local shown = math.min(#info.coowners, 3)
					for i = 1, shown do text(info.coowners[i], "daHUDDoorText", 42 + 24 * i, alpha) end
					if #info.coowners > shown then
						text("and " .. (#info.coowners - shown) .. " more", "daHUDDoorText", 42 + 24 * (shown + 1), alpha)
					end
				end
			end
		cam.End3D2D()
	end
end)

-- Crosshair prompt -------------------------------------------------------------------------------

function BHUD.DrawDoorPrompt(lp)
	local tr = lp:GetEyeTrace()
	local door = tr.Entity

	if not isDoor(door) or not isOwnable(door) then return end
	if #getGroups(door) > 0 then return end

	local dist = door:GetPos():Distance(lp:GetShootPos())
	local maxDist = BHUD.Config.doorDistance
	if dist > maxDist then return end

	local owner = getOwner(door)
	local prompt

	if not owner then
		prompt = "Press F2 to purchase"
	elseif owner == lp then
		prompt = "Press F2 to sell"
	elseif door.isKeysAllowedToOwn and door.isKeysOwnedBy and door:isKeysAllowedToOwn(lp) and not door:isKeysOwnedBy(lp) then
		prompt = "Press F2 to co-own"
	end

	if not prompt then return end

	local alpha = math.cos((dist / maxDist) * (math.pi / 2)) ^ 2
	draw.SimpleTextOutlined(prompt, "daHUDDoorText", ScrW() / 2, ScrH() / 2 - 8,
		Color(255, 255, 255, 255 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, 255 * alpha))
end

-- If DarkRP's own entity display is left enabled, still suppress its door text.
hook.Add("HUDDrawDoorData", "BHUD_SuppressDoorData", function(door)
	if isDoor(door) and isOwnable(door) then return true end
end)
