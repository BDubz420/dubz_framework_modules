-- What a character was holding. Weapons they own that no job hands out (a vape, a gun they bought or found), with the rounds in them and their
-- spare ammo, are saved with the character and given back when they come back: after a rejoin, a restart or switching characters.
-- (Accessories and the backpack are already saved per character by Cosmetics and the pocket.)
sql.Query("CREATE TABLE IF NOT EXISTS dubz_held (sid TEXT PRIMARY KEY, data TEXT NOT NULL)")

local cfg = DubzInv.Config

local function enabled()
	return DubzInv.Enabled() and cfg.persistHeld ~= false
end

-- Only once the character is really in the game (not at the character screen, where nothing is held)
local function inGame(ply)
	if not IsValid(ply) or ply:IsBot() or not ply:Alive() then return false end
	if DubzChars and DubzChars.Enabled and DubzChars.Enabled() and not ply.DubzChar then return false end

	return not ply.DubzHeldRestoring
end

local function skip(ply, class)
	class = string.lower(class)

	if class == "dubz_work" then return true end
	if table.HasValue(cfg.weaponBlacklist, class) then return true end

	return DubzInv.IsJobWeapon and DubzInv.IsJobWeapon(ply, class)
end

local function save(ply)
	if not enabled() or not inGame(ply) then return end

	local weapons, ammo = {}, {}

	for _, weapon in ipairs(ply:GetWeapons()) do
		local class = weapon:GetClass()

		if not skip(ply, class) then
			weapons[#weapons + 1] = {class = class, clip1 = weapon:Clip1(), clip2 = weapon:Clip2()}
		end
	end

	for id = 1, 127 do
		local name = game.GetAmmoName(id)

		if name then
			local count = ply:GetAmmoCount(id)
			if count > 0 then ammo[name] = count end
		end
	end

	local active = ply:GetActiveWeapon()

	sql.Query("REPLACE INTO dubz_held (sid, data) VALUES (" .. sql.SQLStr(DubzInv.GetKey(ply)) .. ", " .. sql.SQLStr(util.TableToJSON({
		weapons = weapons, ammo = ammo, active = IsValid(active) and active:GetClass() or nil,
	})) .. ")")
end

local function restore(ply)
	if not enabled() or not IsValid(ply) or not ply:Alive() then return end

	local text = sql.QueryValue("SELECT data FROM dubz_held WHERE sid = " .. sql.SQLStr(DubzInv.GetKey(ply)))
	local data = text and util.JSONToTable(text)
	if not data then return end

	ply.DubzHeldRestoring = true

	for _, saved in ipairs(data.weapons or {}) do
		local weapon = ply:GetWeapon(saved.class)
		if not IsValid(weapon) then weapon = ply:Give(saved.class, true) end

		if IsValid(weapon) then
			if saved.clip1 and saved.clip1 >= 0 then weapon:SetClip1(saved.clip1) end
			if saved.clip2 and saved.clip2 >= 0 then weapon:SetClip2(saved.clip2) end
		end
	end

	for name, count in pairs(data.ammo or {}) do ply:SetAmmo(count, name) end

	if data.active and IsValid(ply:GetWeapon(data.active)) then ply:SelectWeapon(data.active) end

	ply.DubzHeldRestoring = nil
end

-- Saved when they leave, switch character or the server stops, and every half minute in between (a crash loses at most that)
hook.Add("PlayerDisconnected", "DubzInv_HeldLeave", save)
hook.Add("DubzCharLeave", "DubzInv_HeldCharLeave", save)

hook.Add("ShutDown", "DubzInv_HeldShutdown", function()
	for _, ply in ipairs(player.GetAll()) do save(ply) end
end)

timer.Create("DubzInv_HeldSave", 30, 0, function()
	for _, ply in ipairs(player.GetAll()) do save(ply) end
end)

-- Given back once the character is in and spawned (the job's loadout comes first)
hook.Add("DubzCharSelected", "DubzInv_HeldRestore", function(ply)
	timer.Simple(1, function() restore(ply) end)
end)

-- Without the character system (a plain server) it happens on join
hook.Add("PlayerInitialSpawn", "DubzInv_HeldJoin", function(ply)
	if DubzChars then return end

	timer.Simple(5, function() restore(ply) end)
end)

hook.Add("DubzCharWipe", "DubzInv_HeldWipe", function(account, charId, keys)
	for _, key in ipairs(keys) do sql.Query("DELETE FROM dubz_held WHERE sid = " .. sql.SQLStr(key)) end
end)
