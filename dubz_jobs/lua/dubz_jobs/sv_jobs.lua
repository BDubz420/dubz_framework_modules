-- Seamless job change. DarkRP's changeTeam either kills/respawns the player or (with the norespawn setting) strips every
-- weapon and all ammo and re-gives the loadout. This wraps it: it always takes the no-respawn path (nobody is moved or
-- healed), and puts back what the player was holding that the old job didn't hand out. The new job's outfit is applied
-- by the Cosmetics addon from the same PlayerSetModel call DarkRP makes.
local cfg = DubzJobs.Config

-- Everything the player is carrying that has to survive the strip: weapons with clips, and every ammo type
local function snapshot(ply)
	local data = {weapons = {}, ammo = {}, active = nil}

	for _, weapon in ipairs(ply:GetWeapons()) do
		data.weapons[#data.weapons + 1] = {class = weapon:GetClass(), clip1 = weapon:Clip1(), clip2 = weapon:Clip2()}
	end

	local active = ply:GetActiveWeapon()
	if IsValid(active) then data.active = active:GetClass() end

	for id = 1, 127 do
		local name = game.GetAmmoName(id)
		if name then
			local count = ply:GetAmmoCount(id)
			if count > 0 then data.ammo[id] = count end
		end
	end

	return data
end

-- Was this weapon handed out by the old job (or the default loadout the new job will hand out again)?
local function oldJobTool(prevTeam, class)
	class = string.lower(class)

	local job = RPExtraTeams and RPExtraTeams[prevTeam]
	for _, weapon in ipairs(job and job.weapons or {}) do
		if string.lower(weapon) == class then return true end
	end

	return false
end

local function restore(ply, data, prevTeam)
	if cfg.keepWeapons then
		for _, saved in ipairs(data.weapons) do
			local have = ply:GetWeapon(saved.class)

			if IsValid(have) then
				-- The new job gave it too: it keeps the rounds that were in it
				if saved.clip1 and saved.clip1 >= 0 then have:SetClip1(saved.clip1) end
				if saved.clip2 and saved.clip2 >= 0 then have:SetClip2(saved.clip2) end
			elseif not oldJobTool(prevTeam, saved.class) then
				-- Something they owned: give it back (without the free starting ammo) and reload what was in it
				local gave = ply:Give(saved.class, true)

				if IsValid(gave) then
					if saved.clip1 and saved.clip1 >= 0 then gave:SetClip1(saved.clip1) end
					if saved.clip2 and saved.clip2 >= 0 then gave:SetClip2(saved.clip2) end
				end
			end
		end
	end

	-- Reserve ammo: the strip removed all of it
	if cfg.keepAmmo then
		for id, count in pairs(data.ammo) do ply:SetAmmo(count, id) end
	end

	if data.active and IsValid(ply:GetWeapon(data.active)) then ply:SelectWeapon(data.active) end
end

local original

local function wrap()
	local meta = FindMetaTable("Player")
	if not meta.changeTeam or meta.DubzJobsWrapped then return end

	original = meta.changeTeam
	meta.DubzJobsWrapped = true

	meta.changeTeam = function(self, t, ...)
		if not DubzJobs.Enabled() or not cfg.seamless or not self:Alive() then return original(self, t, ...) end

		local prevTeam = self:Team()
		local data = snapshot(self)

		-- The no-respawn path for this one change
		local config = GAMEMODE and GAMEMODE.Config
		local before = config and config.norespawn
		if config then config.norespawn = true end

		local ok, result = pcall(original, self, t, ...)

		if config then config.norespawn = before end
		if not ok then error(result, 0) end

		if result and self:Team() ~= prevTeam and IsValid(self) and self:Alive() then restore(self, data, prevTeam) end

		return result
	end
end

hook.Add("InitPostEntity", "DubzJobs_Wrap", wrap)
if GAMEMODE then wrap() end   -- (a Lua refresh after the map is up)
