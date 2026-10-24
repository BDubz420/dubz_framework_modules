-- Actions, server side. Another addon starts a piece of work with
--     DubzActions.Start(ply, kind, seconds, opts)
-- kind: "scrap", "search" or "craft" (each has its own arm animation and sounds)
-- opts: label (shown on the bar), model / color / material (the item in their hands), hint (what it is made of, picks the sounds:
--       metal, plastic, cloth, leather, wood, dumpster, craft), onFinish(ply) and onCancel(ply).
-- Returns true when it started, false when the player is busy or can't work right now. DubzActions.Cancel(ply) stops it,
-- DubzActions.Busy(ply) asks.
util.AddNetworkString("DubzAct_Beat")   -- server -> clients near: a work gesture for this player
util.AddNetworkString("DubzActions_Anims")       -- server -> client: every saved animation
util.AddNetworkString("DubzActions_SaveAnim")    -- client -> server: save an animation (superadmin)
util.AddNetworkString("DubzActions_ResetAnim")   -- client -> server: back to the preset (superadmin)

local cfg = DubzActions.Config

DubzActions.Gestures = {scrap = ACT_GMOD_GESTURE_ITEM_PLACE, search = ACT_GMOD_GESTURE_ITEM_GIVE, craft = ACT_GMOD_GESTURE_ITEM_DROP, pickup = ACT_GMOD_GESTURE_ITEM_PLACE}

-- Sound design --------------------------------------------------------------------------------------------------------------------
-- Each kind has a beat: a list of {time as a fraction of the work, sound, pitch low, pitch high, level}. Scrapping strains and cracks
-- by what the thing is made of, searching rummages (a lid first, then things shifting), crafting is a steady tap and ratchet.
local function pick(prefix, count) return prefix .. math.random(1, count) .. ".wav" end

local SCRAP = {
	metal = {strain = "physics/metal/metal_box_strain%d.wav", strains = 4, hit = "physics/metal/metal_solid_impact_soft%d.wav", hits = 3, snap = "physics/metal/metal_box_break%d.wav", snaps = 2},
	plastic = {strain = "physics/plastic/plastic_box_impact_soft%d.wav", strains = 5, hit = "physics/plastic/plastic_box_impact_soft%d.wav", hits = 5, snap = "physics/plastic/plastic_box_break%d.wav", snaps = 2},
	cloth = {strain = "physics/cardboard/cardboard_box_impact_soft%d.wav", strains = 7, hit = "physics/cardboard/cardboard_box_impact_soft%d.wav", hits = 7, snap = "physics/cardboard/cardboard_box_break%d.wav", snaps = 3},
	leather = {strain = "physics/cardboard/cardboard_box_impact_soft%d.wav", strains = 7, hit = "physics/wood/wood_box_impact_soft%d.wav", hits = 3, snap = "physics/cardboard/cardboard_box_break%d.wav", snaps = 3},
	electronics = {strain = "physics/plastic/plastic_box_impact_soft%d.wav", strains = 5, hit = "physics/metal/metal_computer_impact_soft%d.wav", hits = 3, snap = "physics/glass/glass_impact_bullet%d.wav", snaps = 4},
	wood = {strain = "physics/wood/wood_box_impact_soft%d.wav", strains = 3, hit = "physics/wood/wood_box_impact_hard%d.wav", hits = 5, snap = "physics/wood/wood_plank_break%d.wav", snaps = 4},
}

local function scrapBeat(hint)
	local set = SCRAP[hint] or SCRAP.metal

	-- Grab, three twists with a creak each, a hard pull, and the crack
	return {
		{0.00, string.format(set.hit, math.random(1, set.hits)), 90, 100, 60},
		{0.16, string.format(set.strain, math.random(1, set.strains)), 90, 110, 62},
		{0.34, string.format(set.strain, math.random(1, set.strains)), 85, 105, 62},
		{0.52, string.format(set.strain, math.random(1, set.strains)), 95, 115, 64},
		{0.70, string.format(set.hit, math.random(1, set.hits)), 80, 95, 62},
		{0.88, string.format(set.snap, math.random(1, set.snaps)), 95, 105, 68},
		{0.96, "physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", 100, 115, 50},
	}
end

-- One hand in the dumpster: the lid, a rummage, the grab, and everything pops out
local function searchBeat()
	return {
		{0.00, pick("physics/metal/metal_barrel_impact_hard", 3), 90, 100, 65},
		{0.30, pick("physics/cardboard/cardboard_box_impact_soft", 7), 90, 110, 58},
		{0.52, pick("physics/plastic/plastic_box_impact_soft", 5), 95, 110, 58},
		{0.88, pick("physics/cardboard/cardboard_box_impact_hard", 5), 90, 105, 62},
		{0.92, "physics/metal/metal_canister_impact_soft" .. math.random(1, 3) .. ".wav", 95, 110, 60},
	}
end

local function unusedLongSearchBeat()
	local beat = {{0.00, pick("physics/metal/metal_barrel_impact_hard", 3), 90, 100, 65}}   -- the lid

	local rummage = {
		"physics/cardboard/cardboard_box_impact_soft%d.wav 7", "physics/plastic/plastic_box_impact_soft%d.wav 5",
		"physics/metal/metal_canister_impact_soft%d.wav 3", "physics/cardboard/cardboard_box_impact_soft%d.wav 7",
	}

	-- Things shifting and rustling, a bit faster toward the end
	local t = 0.12
	local index = 1

	while t < 0.9 do
		local file, count = string.match(rummage[(index - 1) % #rummage + 1], "^(%S+) (%d+)$")
		beat[#beat + 1] = {t, string.format(file, math.random(1, tonumber(count))), 85, 115, 58}
		t = t + 0.09 + 0.07 * (1 - t)
		index = index + 1
	end

	beat[#beat + 1] = {0.93, pick("physics/metal/metal_barrel_impact_soft", 4), 95, 105, 62}   -- the lid back down
	return beat
end

local function craftBeat()
	local beat = {}

	-- A steady tap, with a ratchet between
	local t = 0.04
	local index = 0

	while t < 0.9 do
		index = index + 1

		if index % 3 == 0 then
			beat[#beat + 1] = {t, "weapons/357/357_spin1.wav", 130, 160, 55}
		else
			beat[#beat + 1] = {t, pick("physics/metal/metal_solid_impact_hard", 5), 95 + (index % 2) * 12, 108 + (index % 2) * 12, 62}
		end

		t = t + 0.11
	end

	beat[#beat + 1] = {0.96, "buttons/button9.wav", 100, 105, 60}   -- done
	return beat
end

local function beatFor(kind, hint)
	if kind == "scrap" then return scrapBeat(hint) end
	if kind == "search" then return searchBeat() end
	if kind == "craft" then return craftBeat() end
	return {}
end

-- Other addons can ask for a kind's sounds (the dumpster plays them with just a progress bar when its animation is switched off)
DubzActions.BeatFor = beatFor

-- Starting and stopping ----------------------------------------------------------------------------------------------------

function DubzActions.Busy(ply)
	return ply.DubzAction ~= nil
end

local function strip(ply)
	if IsValid(ply:GetWeapon("dubz_work")) then ply:StripWeapon("dubz_work") end

	ply:SetNWFloat("dubz_act_start", 0)
	ply:SetNWString("dubz_act_label", "")
	ply:SetNWString("dubz_act_kind", "")
	ply:SetNWString("dubz_act_model", "")
	ply:SetNWString("dubz_act_material", "")
end

-- Put away the work weapon and take the old one back out
local function finishUp(ply, act)
	strip(ply)

	if act.prev and IsValid(ply:GetWeapon(act.prev)) then ply:SelectWeapon(act.prev) end
end

function DubzActions.Cancel(ply)
	local act = ply.DubzAction
	if not act or act.finishing then return end

	ply.DubzAction = nil
	timer.Remove("DubzActions_" .. ply:EntIndex())

	finishUp(ply, act)
	if act.opts.onCancel then act.opts.onCancel(ply) end
end

local function finish(ply, act)
	if ply.DubzAction ~= act then return end

	-- The callback may start the next piece of work straight away (scrapping a whole stack): the weapon stays up for it
	act.finishing = true
	if act.opts.onFinish then act.opts.onFinish(ply) end

	if ply.DubzAction == act then
		ply.DubzAction = nil
		finishUp(ply, act)
	end
end

function DubzActions.Start(ply, kind, seconds, opts)
	if not (IsValid(ply) and ply:IsPlayer() and ply:Alive()) or not DubzActions.Allowed(kind) then return false end
	if ply:InVehicle() or (ply.isArrested and ply:isArrested()) then return false end

	local current = ply.DubzAction
	if current and not current.finishing then return false end

	opts = opts or {}
	seconds = math.max(tonumber(seconds) or 3, 0.5)

	local act = {kind = kind, opts = opts, started = CurTime(), prev = current and current.prev or (IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() or nil)}
	if act.prev == "dubz_work" then act.prev = nil end

	ply.DubzAction = act

	-- The work weapon (hands only)
	local weapon = ply:GetWeapon("dubz_work")
	if not IsValid(weapon) then weapon = ply:Give("dubz_work", true) end

	if not IsValid(weapon) then
		ply.DubzAction = nil
		return false
	end

	ply:SelectWeapon("dubz_work")

	local color = opts.color
	weapon:SetKind(kind)
	weapon:SetHeldModel(opts.model or "")
	weapon:SetHeldMaterial(opts.material or "")
	weapon:SetHeldColor(color and Vector(color.r or 255, color.g or 255, color.b or 255) or Vector(255, 255, 255))
	weapon:SetStart(CurTime())
	weapon:SetLength(seconds)

	ply:SetNWFloat("dubz_act_start", CurTime())
	ply:SetNWFloat("dubz_act_time", seconds)
	ply:SetNWString("dubz_act_label", opts.label or "")

	-- Everyone can see what they are doing (the arms work and the item is in their hands)
	ply:SetNWString("dubz_act_kind", kind)
	ply:SetNWString("dubz_act_model", opts.model or "")
	ply:SetNWString("dubz_act_material", opts.material or "")

	-- The beat: each sound at its moment (and a gesture so other players see the work too)
	local token = act
	for _, step in ipairs(beatFor(kind, opts.hint)) do
		timer.Simple(step[1] * seconds, function()
			if not IsValid(ply) or ply.DubzAction ~= token then return end

			ply:EmitSound(step[2], step[5] or 60, math.random(step[3] or 100, step[4] or 100), 0.8)

			if cfg.thirdPerson then
				net.Start("DubzAct_Beat")
					net.WriteEntity(ply)
					net.WriteString(kind)
				net.SendPVS(ply:GetPos())
			end
		end)
	end

	timer.Create("DubzActions_" .. ply:EntIndex(), seconds, 1, function()
		if IsValid(ply) then finish(ply, act) end
	end)

	return true
end

-- A pose only: for quick things like picking up. Everyone sees the arm reach (and the item), but nothing is locked, no weapon is swapped
-- and nothing waits for it. DubzActions.EndPose stops it early (it also ends by itself).
function DubzActions.Pose(ply, kind, seconds, opts)
	if not (IsValid(ply) and ply:Alive()) or ply.DubzAction or not DubzActions.Allowed(kind) then return end

	opts = opts or {}
	seconds = math.max(tonumber(seconds) or 1, 0.2)

	ply.DubzPose = CurTime()
	local mark = ply.DubzPose

	ply:SetNWFloat("dubz_act_start", CurTime())
	ply:SetNWFloat("dubz_act_time", seconds)
	ply:SetNWString("dubz_act_kind", kind)
	ply:SetNWString("dubz_act_model", opts.model or "")
	ply:SetNWString("dubz_act_material", opts.material or "")

	local function beat()
		if not IsValid(ply) or ply.DubzPose ~= mark or not cfg.thirdPerson then return end

		net.Start("DubzAct_Beat")
			net.WriteEntity(ply)
			net.WriteString(kind)
		net.SendPVS(ply:GetPos())
	end

	beat()
	timer.Simple(seconds + 0.2, function() if IsValid(ply) and ply.DubzPose == mark then DubzActions.EndPose(ply) end end)
end

function DubzActions.EndPose(ply)
	if not ply.DubzPose then return end
	ply.DubzPose = nil

	-- (a full action may have started since: leave its numbers alone)
	if ply.DubzAction then return end

	ply:SetNWFloat("dubz_act_start", 0)
	ply:SetNWString("dubz_act_kind", "")
	ply:SetNWString("dubz_act_model", "")
	ply:SetNWString("dubz_act_material", "")
end

-- The player is held in place; being hurt, dying or leaving stops the work ------------------------------

hook.Add("StartCommand", "DubzActions_Hold", function(ply, cmd)
	local act = ply.DubzAction
	if not act then return end

	-- (each kind of work says whether it holds you still: scrapping does not, by default)
	local lock = cfg["lock" .. string.upper(string.sub(act.kind, 1, 1)) .. string.sub(act.kind, 2)]

	if lock ~= false then
		cmd:ClearMovement()
		cmd:RemoveKey(bit.bor(IN_JUMP, IN_DUCK, IN_ATTACK, IN_ATTACK2, IN_SPEED))
	end
end)

-- No switching away from the work weapon while working
hook.Add("PlayerSwitchWeapon", "DubzActions_NoSwitch", function(ply, old, new)
	if ply.DubzAction and IsValid(new) and new:GetClass() ~= "dubz_work" then return true end
end)

hook.Add("EntityTakeDamage", "DubzActions_Hurt", function(target, dmg)
	if cfg.cancelOnDamage and IsValid(target) and target:IsPlayer() and target.DubzAction and dmg:GetDamage() > 0 then DubzActions.Cancel(target) end
end)

local function drop(ply)
	if ply.DubzAction then DubzActions.Cancel(ply) end
end

hook.Add("PlayerDeath", "DubzActions_Death", drop)
hook.Add("PlayerDisconnected", "DubzActions_Leave", drop)
hook.Add("DubzCharLeave", "DubzActions_CharLeave", drop)

-- The work weapon is never loot and can't be dropped
hook.Add("canDropWeapon", "DubzActions_NoDrop", function(ply, weapon)
	if IsValid(weapon) and weapon:GetClass() == "dubz_work" then return false end
end)

-- Saved animations (made in the editor, dubz_work_editor) ------------------------------------------------------------------------
-- Stored as JSON per kind and sent to every player, who then use them instead of the code presets.
sql.Query("CREATE TABLE IF NOT EXISTS dubz_actions_anims (kind TEXT PRIMARY KEY, data TEXT NOT NULL)")

local saved = {}
for _, row in ipairs(sql.Query("SELECT kind, data FROM dubz_actions_anims") or {}) do
	saved[row.kind] = util.JSONToTable(row.data)
end

local function sendAnims(target)
	local compressed = util.Compress(util.TableToJSON(saved)) or ""

	net.Start("DubzActions_Anims")
		net.WriteUInt(#compressed, 32)
		net.WriteData(compressed, #compressed)

	if target then net.Send(target) else net.Broadcast() end
end

hook.Add("PlayerInitialSpawn", "DubzActions_SendAnims", function(ply)
	timer.Simple(8, function() if IsValid(ply) then sendAnims(ply) end end)
end)

net.Receive("DubzActions_SaveAnim", function(_, ply)
	local kind, json = net.ReadString(), net.ReadString()
	if not ply:IsSuperAdmin() then return end

	kind = string.lower(kind)
	local data = util.JSONToTable(json)

	if not string.match(kind, "^[%w_]+$") or #kind > 24 or not istable(data) or not istable(data.keys) or #data.keys < 2 or #data.keys > 80 then
		ply:ChatPrint("[Actions] That animation couldn't be saved.")
		return
	end

	saved[kind] = data
	sql.Query("REPLACE INTO dubz_actions_anims (kind, data) VALUES (" .. sql.SQLStr(kind) .. ", " .. sql.SQLStr(util.TableToJSON(data)) .. ")")
	sendAnims()
end)

net.Receive("DubzActions_ResetAnim", function(_, ply)
	local kind = string.lower(net.ReadString())
	if not ply:IsSuperAdmin() then return end

	saved[kind] = nil
	sql.Query("DELETE FROM dubz_actions_anims WHERE kind = " .. sql.SQLStr(kind))
	sendAnims()
end)

concommand.Add("dubz_work_stop", function(ply)
	if IsValid(ply) and ply:IsSuperAdmin() then DubzActions.Cancel(ply) end
end)

-- A superadmin can see an animation without waiting for something to scrap: dubz_work_preview scrap|search|craft
concommand.Add("dubz_work_preview", function(ply, _, args)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end

	local kind = args[1] or "scrap"
	-- dubz_work_preview <kind> <seconds> <hint> <freeze>: a freeze between 0 and 1 holds the animation at that moment so the pose can be looked at
	local freeze = tonumber(args[4])
	local seconds = tonumber(args[2]) or (freeze and 120) or 5

	if not DubzActions.Start(ply, kind, seconds, {label = "Preview: " .. kind, model = "models/props_junk/garbage_metalcan001a.mdl", hint = args[3] or "metal"}) then return end

	local weapon = ply:GetWeapon("dubz_work")
	if IsValid(weapon) and freeze then weapon:SetFreeze(math.Clamp(freeze, 0.001, 1)) end
end)
