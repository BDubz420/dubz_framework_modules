-- Storage helpers: turning entities into saveable tables (and back), JSON encoding that keeps Vectors /
-- Angles, and the sqlite table.

sql.Query("CREATE TABLE IF NOT EXISTS dubz_inventory (sid TEXT PRIMARY KEY, data TEXT NOT NULL)")

-- JSON encoding ------------------------------------------------------------------------------------

-- Vectors / Angles become tagged tables, entities and functions are dropped.
local function encode(value)
	if isvector(value) then return {__v = {value.x, value.y, value.z}} end
	if isangle(value) then return {__a = {value.p, value.y, value.r}} end

	if istable(value) then
		local out = {}
		for k, v in pairs(value) do
			local encoded = encode(v)
			if encoded ~= nil then out[tostring(k)] = encoded end
		end
		return out
	end

	if isnumber(value) or isstring(value) or isbool(value) then return value end
	-- entities, functions, userdata: not saveable
end

local function decode(value)
	if not istable(value) then return value end

	if value.__v then return Vector(value.__v[1], value.__v[2], value.__v[3]) end
	if value.__a then return Angle(value.__a[1], value.__a[2], value.__a[3]) end

	local out = {}
	for k, v in pairs(value) do
		out[tonumber(k) or k] = decode(v)
	end
	return out
end

function DubzInv.ToJSON(tbl)
	return util.TableToJSON(encode(tbl))
end

function DubzInv.FromJSON(text)
	local tbl = util.JSONToTable(text or "")
	if not tbl then return nil end
	return decode(tbl)
end

-- Database -----------------------------------------------------------------------------------------

-- The key an inventory is stored under. Switches to the active character when a character system exists.
function DubzInv.GetKey(ply)
	if DubzChars and DubzChars.GetKey then return DubzChars.GetKey(ply) end
	return ply:SteamID64() or ply:SteamID()
end

function DubzInv.LoadRow(ply)
	local text = sql.QueryValue("SELECT data FROM dubz_inventory WHERE sid = " .. sql.SQLStr(DubzInv.GetKey(ply)))

	-- The first character of an account inherits what the account's pocket held before characters existed
	if not text and DubzChars and DubzChars.LegacyKey then
		local legacy = DubzChars.LegacyKey(ply)
		if legacy then text = sql.QueryValue("SELECT data FROM dubz_inventory WHERE sid = " .. sql.SQLStr(legacy)) end
	end

	return text and DubzInv.FromJSON(text) or nil
end

function DubzInv.SaveRow(ply, tbl)
	local json = sql.SQLStr(DubzInv.ToJSON(tbl))
	sql.Query("REPLACE INTO dubz_inventory (sid, data) VALUES (" .. sql.SQLStr(DubzInv.GetKey(ply)) .. ", " .. json .. ")")
end

-- Entities <-> saveable tables (adapted from DarkRP's pocket) -----------------------------------------

-- GetNetworkVars doesn't give entities because the duplicator doesn't want to save them
local function getDTVars(ent)
	if not ent.GetNetworkVars then return nil end

	local name, value = debug.getupvalue(ent.GetNetworkVars, 1)
	if name ~= "datatable" then return nil end

	local res = {}
	for k, v in pairs(value) do res[k] = v.GetFunc(ent, v.index) end
	return res
end

-- Things that only live while the entity does (a running sound, an audio channel ...) must not be saved with it:
-- merged back into a fresh entity they replace the sound it just started, so e.g. a printer taken out of the pocket
-- would be silent.
local LIVE_TYPES = {CSoundPatch = true, IGModAudioChannel = true, CLuaEmitter = true, CNewParticleEffect = true, CLuaParticle = true, ITexture = true, IMaterial = true}

local function stripLive(tbl, depth)
	depth = depth or 0
	if depth > 4 then return end

	for key, value in pairs(tbl) do
		if LIVE_TYPES[type(value)] then
			tbl[key] = nil
		elseif istable(value) and not IsColor(value) then
			stripLive(value, depth + 1)
		end
	end
end

-- Items only stack when they are really the same: everything networked on them (a cheque's amount, what a printer holds ...) has to match.
-- The signature is what the pocket compares, so two things that differ in any of it never share a stack (and never share one saved copy).
function DubzInv.StateSignature(ent)
	local vars = getDTVars(ent)
	if not vars then return "" end

	local keys = {}
	for key, value in pairs(vars) do
		if isnumber(value) or isstring(value) or isbool(value) then keys[#keys + 1] = key end
	end

	if #keys == 0 then return "" end
	table.sort(keys)

	local parts = {}
	for _, key in ipairs(keys) do parts[#parts + 1] = key .. "=" .. tostring(vars[key]) end

	return util.CRC(table.concat(parts, "|"))
end

function DubzInv.SerializeEntity(ent)
	local serialized = duplicator.CopyEntTable(ent)
	stripLive(serialized)
	serialized.DT = getDTVars(ent)

	-- some entities change their DT vars when copied; re-run to undo that
	if ent.OnEntityCopyTableFinish then ent:OnEntityCopyTableFinish(serialized) end

	return serialized
end

-- Puts an entity down in front of the player (or at a position).
function DubzInv.PlaceInFront(ent, ply, pos)
	if pos then
		ent:SetPos(pos)
	else
		local tr = util.TraceLine({
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:GetAimVector() * 85,
			filter = ply,
		})

		ent:SetPos(tr.HitPos)
		if DarkRP and DarkRP.placeEntity then DarkRP.placeEntity(ent, tr, ply) end
	end

	-- Saved physics data (and DarkRP's placement) can leave the prop frozen or asleep in mid-air, so unfreeze it
	-- and give it a small nudge forward and down. Done now and again next tick, once everything has settled.
	local function nudge()
		if not IsValid(ent) then return end

		local phys = ent:GetPhysicsObject()
		if not IsValid(phys) then return end

		phys:EnableMotion(true)
		phys:EnableGravity(true)
		phys:Wake()

		local dir = IsValid(ply) and ply:GetAimVector() or VectorRand()
		phys:SetVelocity(dir * 60 + Vector(0, 0, -30))
	end

	nudge()
	timer.Simple(0, nudge)
end

-- Recreates an entity from SerializeEntity data.
function DubzInv.DeserializeEntity(ply, item)
	local ent = ents.Create(item.Class)
	if not IsValid(ent) then return nil end

	stripLive(item)   -- (older saved items may still carry them)
	duplicator.DoGeneric(ent, item)
	ent:Spawn()
	ent:Activate()

	duplicator.DoGenericPhysics(ent, ply, item)
	table.Merge(ent:GetTable(), item)

	if ent:IsWeapon() and ent.Weapon ~= nil and not ent.Weapon:IsValid() then ent.Weapon = ent end
	if ent.Entity ~= nil and not ent.Entity:IsValid() then ent.Entity = ent end

	DubzInv.PlaceInFront(ent, ply)

	-- Ownership: the saved copy can't hold the old owner (entities aren't stored), so whoever takes it out of their
	-- pocket owns it now (printers, chargers, stoves, anything DarkRP owns by player)
	if IsValid(ply) then
		if ent.Setowning_ent then ent:Setowning_ent(ply) end
		if ent.CPPISetOwner then ent:CPPISetOwner(ply) end
		ent:SetNWEntity("Owner", ply)
		ent.SID = ply.SID
		ent.Owner = ply
	end

	-- The saved copy carries the old "was pocketed" flag and a stripped copy of the shop entry: put back the real ones
	-- so DarkRP counts (and un-counts) this entity like a bought one
	ent.IsPocketing = nil
	local entry = DubzInv.ShopEntry and DubzInv.ShopEntry(ent:GetClass())
	if entry then ent.DarkRPItem = entry end

	if ent.OnDuplicated then ent:OnDuplicated(item) end
	if ent.PostEntityPaste then ent:PostEntityPaste(ply, ent, {ent}) end

	if IsValid(ply) then hook.Run("DubzInvDeployed", ply, ent) end

	return ent
end
