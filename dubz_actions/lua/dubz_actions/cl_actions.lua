-- Actions, client side: the progress bar (a plain black card, filling as the work goes) and the work gesture other players see.
local cfg = DubzActions.Config

local GESTURES = {scrap = ACT_GMOD_GESTURE_ITEM_PLACE, search = ACT_GMOD_GESTURE_ITEM_GIVE, craft = ACT_GMOD_GESTURE_ITEM_DROP, pickup = ACT_GMOD_GESTURE_ITEM_PLACE}

net.Receive("DubzAct_Beat", function()
	local ply, kind = net.ReadEntity(), net.ReadString()

	-- (your own arms are the first person animation; this is for everyone else)
	if not IsValid(ply) or ply == LocalPlayer() or not GESTURES[kind] then return end

	ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, GESTURES[kind], true)
end)

-- Other players at work ---------------------------------------------------------------------------------------------------------------
-- Their model's forearms, hands and fingers move with the same animations as the first person arms, and the item is held between their hands.

local function poseOf(ply, view)
	local kind = ply:GetNWString("dubz_act_kind", "")
	local start = ply:GetNWFloat("dubz_act_start", 0)
	if kind == "" or start <= 0 or not DubzActions.HasAnimation or not DubzActions.HasAnimation(kind) then return end

	local length = math.max(ply:GetNWFloat("dubz_act_time", 1), 0.1)
	local t = math.max(CurTime() - start, 0)
	local pose = {bones = {}, curl = {R = 0, L = 0}, pos = Vector(), ang = Angle(), look = 0}

	DubzActions.Evaluate(kind, t, math.Clamp(t / length, 0, 1), pose, view or "third")
	DubzActions.AddCurl(pose.bones, "R", pose.curl.R)
	DubzActions.AddCurl(pose.bones, "L", pose.curl.L)
	DubzActions.ApplyTweaks(kind, pose.bones, view or "third")

	return pose, t
end

local ZERO = Angle(0, 0, 0)
local worked = {}   -- players whose bones are currently posed
local items = {}    -- the item model in each worker's hands

local function setBones(ply, set)
	for _, name in ipairs(DubzActions.Bones or {}) do
		-- (the whole arm is left to the hold type unless a Pose Tweak turns it; the wrists, forearm twist and fingers always move)
		if (name ~= "R_UpperArm" and name ~= "L_UpperArm") or (set and set[name]) then
			local id = ply:LookupBone("ValveBiped.Bip01_" .. name)
			if id then ply:ManipulateBoneAngles(id, set and set[name] or ZERO) end
		end
	end
end

local function dropItem(ply)
	local ent = items[ply]
	if IsValid(ent) then ent:Remove() end
	items[ply] = nil
end

hook.Add("PrePlayerDraw", "DubzActions_OthersWork", function(ply)
	if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then return end

	local pose = poseOf(ply)

	if pose then
		worked[ply] = true
		setBones(ply, pose.bones)
	elseif worked[ply] then
		worked[ply] = nil
		setBones(ply, nil)
		dropItem(ply)
	end
end)

hook.Add("PostPlayerDraw", "DubzActions_OthersItem", function(ply)
	if not worked[ply] or (ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer()) then return end

	local model = ply:GetNWString("dubz_act_model", "")
	local pose, t = poseOf(ply)

	if model == "" or not pose or not pose.item then dropItem(ply) return end

	local right, left = ply:LookupBone("ValveBiped.Bip01_R_Hand"), ply:LookupBone("ValveBiped.Bip01_L_Hand")
	if not (right and left) then return end

	local rp, lp = ply:GetBonePosition(right), ply:GetBonePosition(left)
	if not (rp and lp) then return end

	local ent = items[ply]

	if not IsValid(ent) or ent:GetModel() ~= model then
		dropItem(ply)

		ent = ClientsideModel(model, RENDERGROUP_OTHER)
		if not IsValid(ent) then return end

		ent:SetNoDraw(true)
		items[ply] = ent
	end

	local yaw = Angle(0, ply:EyeAngles().y, 0)
	local mins, maxs = ent:GetModelRenderBounds()
	local size = math.max(maxs.x - mins.x, maxs.y - mins.y, maxs.z - mins.z, 1)
	local scale = math.Clamp(cfg.itemSizeOthers / size, 0.02, 3)

	ent:SetModelScale(scale, 0)

	local angle = Angle(yaw.p + pose.item.ang.p, yaw.y + pose.item.ang.y, yaw.r + pose.item.ang.r)
	local centre = (mins + maxs) / 2 * scale

	ent:SetPos((rp + lp) / 2 + yaw:Forward() * 3 - angle:Forward() * centre.x - angle:Right() * centre.y - angle:Up() * centre.z)
	ent:SetAngles(angle)
	ent:SetMaterial(ply:GetNWString("dubz_act_material", ""))
	ent:DrawModel()
end)

-- A worker who leaves or whose model is gone
hook.Add("EntityRemoved", "DubzActions_Cleanup", function(ent)
	if ent:IsPlayer() then
		worked[ent] = nil
		dropItem(ent)
	end
end)

-- Your own arm for a pickup: the hands (or whatever you hold) dip down, grab and come back. (Real work, which holds the work weapon,
-- animates its own arms.)
local vmPosed = false

hook.Add("CalcViewModelView", "DubzActions_PickupView", function(wep, vm, oldPos, oldAng, pos, ang)
	local lp = LocalPlayer()
	if not IsValid(lp) or (IsValid(wep) and wep:GetClass() == "dubz_work") or lp:GetNWString("dubz_act_kind", "") ~= "pickup" then return end

	local pose = poseOf(lp, "first")
	if not pose then return end

	pos = pos + ang:Forward() * pose.pos.x + ang:Right() * pose.pos.y + ang:Up() * pose.pos.z
	ang = Angle(ang.p + pose.ang.p, ang.y + pose.ang.y, ang.r + pose.ang.r)

	return pos, ang
end)

hook.Add("PreDrawViewModel", "DubzActions_PickupArms", function(vm, ply, wep)
	if not IsValid(vm) or (IsValid(wep) and wep:GetClass() == "dubz_work") then return end

	local pose = ply:GetNWString("dubz_act_kind", "") == "pickup" and poseOf(ply, "first")

	if pose then
		vmPosed = true

		for _, name in ipairs(DubzActions.Bones or {}) do
			local id = vm:LookupBone("ValveBiped.Bip01_" .. name)
			if id then vm:ManipulateBoneAngles(id, pose.bones[name] or ZERO) end
		end
	elseif vmPosed then
		vmPosed = false

		for _, name in ipairs(DubzActions.Bones or {}) do
			local id = vm:LookupBone("ValveBiped.Bip01_" .. name)
			if id then vm:ManipulateBoneAngles(id, ZERO) end
		end
	end
end)

-- The pickup feed on the right of the screen: the work weapon is not something to announce
hook.Add("HUDWeaponPickedUp", "DubzActions_NoFeed", function(weapon)
	if IsValid(weapon) and weapon:GetClass() == "dubz_work" then return false end
end)

-- The bar is the framework's own progress card, the same one the pickup bar uses, so they all match
hook.Add("HUDPaint", "DubzActions_Bar", function()
	if not cfg.showBar then return end

	local lp = LocalPlayer()
	if not IsValid(lp) then return end

	local start = lp:GetNWFloat("dubz_act_start", 0)
	if start <= 0 or lp:GetNWString("dubz_act_kind", "") == "pickup" then return end   -- (the pickup has its own bar, from the pocket)

	local length = math.max(lp:GetNWFloat("dubz_act_time", 1), 0.1)
	local fraction = math.Clamp((CurTime() - start) / length, 0, 1)
	local label = lp:GetNWString("dubz_act_label", "")

	if DFW and DFW.Draw and DFW.Draw.ProgressCard then
		DFW.Draw.ProgressCard(ScrW() / 2, ScrH() * 0.62, 220, label, fraction)
	end
end)
