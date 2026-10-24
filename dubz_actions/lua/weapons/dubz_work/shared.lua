-- Hands at work: given to a player while they search, scrap or craft (see dubz_actions/sv_actions.lua) and taken away when it is done.
-- It has no use of its own. In first person it shows the arms working (Bip01 bones posed like the Handies weapons do), with the item being
-- worked on held between the hands. The poses are plain numbers in the ANIMATIONS table below: change them to taste.
AddCSLuaFile()

SWEP.PrintName = "Hands At Work"
SWEP.Author = "BDubz420"
SWEP.Instructions = "You are working."
SWEP.Slot = 1
SWEP.SlotPos = 9
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.ViewModelFOV = 62
SWEP.UseHands = true
SWEP.HoldType = "normal"

SWEP.Spawnable = false
SWEP.AdminOnly = true
SWEP.Category = "Dubz"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

function SWEP:SetupDataTables()
	self:NetworkVar("String", 0, "Kind")           -- scrap, search or craft
	self:NetworkVar("String", 1, "HeldModel")      -- the model of the item in the hands ("" = nothing)
	self:NetworkVar("String", 2, "HeldMaterial")
	self:NetworkVar("Vector", 0, "HeldColor")
	self:NetworkVar("Float", 0, "Start")
	self:NetworkVar("Float", 1, "Length")
	self:NetworkVar("Float", 2, "Freeze")          -- 0 = off; 0 to 1 holds the animation at that moment (for dialing in the poses)
end

-- What other players see of the arms: scrapping and crafting hold the work low and in front with both hands, searching reaches one hand out
local HOLD = {scrap = "slam", craft = "slam", search = "pistol"}

function SWEP:Initialize()
	self:SetHoldType("slam")
	self.AppliedHold = "slam"
end

-- (the first person arms are animated on the client below; this keeps the third person hold in step on both sides)
function SWEP:Think()
	local want = HOLD[self:GetKind()] or "normal"

	if self.AppliedHold ~= want then
		self.AppliedHold = want
		self:SetHoldType(want)
	end

	if CLIENT and self.ClientThink then self:ClientThink() end
end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end

function SWEP:Deploy()
	if SERVER and IsValid(self:GetOwner()) then
		self:GetOwner():DrawWorldModel(false)
		self:GetOwner():DrawViewModel(true)
	end

	local owner = self:GetOwner()
	local vm = IsValid(owner) and owner:IsPlayer() and owner:GetViewModel()

	if IsValid(vm) then
		local seq = vm:LookupSequence("fists_idle_01")
		if seq and seq > 0 then vm:SendViewModelMatchingSequence(seq) end
	end

	return true
end

if SERVER then return end

-- The animations ------------------------------------------------------------------------------------------------------------------
-- Each one fills a pose from the time into the work (seconds) and how far through it is (0 to 1):
--   pose.bones.<Side_Bone> = Angle      arm and hand bones   (R_Forearm roll is the third number)
--   pose.curl.R / pose.curl.L           how closed each hand is, 0 to 1
--   pose.pos / pose.ang                 the whole arms moved and turned (forward, right, up)
--   pose.look                           how far the view tips down (degrees)
--   pose.item                           the held item's offset (forward, right, up) and turn (angle)
local function smooth(x) x = math.Clamp(x, 0, 1) return x * x * (3 - 2 * x) end

local ANIMATIONS = {}

-- Gripping the thing with both hands and wringing it: three twists, a hard pull, the crack
ANIMATIONS.scrap = function(t, p, pose)
	local grip = smooth(p / 0.1)
	local work = p < 0.86 and math.sin(math.max(p - 0.1, 0) / 0.76 * 3 * math.pi * 2) or 0
	local final = p >= 0.86 and math.sin((p - 0.86) / 0.14 * math.pi) or 0

	local roll = 32 * work + 55 * final

	pose.bones.R_Forearm = Angle(0, 0, roll)
	pose.bones.L_Forearm = Angle(0, 0, -roll)
	pose.bones.R_Hand = Angle(10 * work, 0, 12 * work)
	pose.bones.L_Hand = Angle(10 * work, 0, -12 * work)

	pose.curl.R, pose.curl.L = 0.75 * grip, 0.75 * grip
	pose.pos = Vector(1.5 + 2 * final, 0, 0.5 + 0.8 * math.abs(work))
	pose.ang = Angle(3 * work, 2 * work, 2 * work)
	pose.item = {pos = Vector(0, 0, 0), ang = Angle(25 * work, 18 * work, 40 * work + 90 * final)}
	pose.look = 6 * grip
end

-- Reaching into the dumpster: one hand goes in, grabs, and comes back out (the loot pops out as it finishes)
ANIMATIONS.search = function(t, p, pose)
	local reach = smooth(p / 0.35) * (1 - smooth((p - 0.7) / 0.3))
	local grab = smooth((p - 0.4) / 0.2) * (1 - smooth((p - 0.8) / 0.2))

	pose.bones.R_Forearm = Angle(0, 0, 8 * math.sin(t * 9) * reach)
	pose.bones.R_Hand = Angle(-16 * reach, 0, 10 * math.sin(t * 7) * reach)

	pose.curl.R = 0.1 + 0.85 * grab
	pose.curl.L = 0.25
	pose.pos = Vector(3.5 * reach, 2 * reach, -6.5 * reach)
	pose.ang = Angle(14 * reach, 0, 6 * reach)
	pose.item = nil
	pose.look = 10 * reach
end

-- Picking something up: the hand reaches down, closes on it and comes back (used for everyone's pickups, see DubzActions.Pose)
ANIMATIONS.pickup = function(t, p, pose)
	local down = smooth(math.min(p / 0.4, 1)) * (1 - smooth((p - 0.8) / 0.2))
	local grab = smooth((p - 0.4) / 0.25) * (1 - smooth((p - 0.85) / 0.15))

	pose.bones.R_Forearm = Angle(0, 0, 10 * down)
	pose.bones.R_Hand = Angle(-20 * down, 0, 0)

	pose.curl.R = 0.1 + 0.8 * grab
	pose.curl.L = 0.2
	pose.pos = Vector(3 * down, 2 * down, -7 * down)
	pose.ang = Angle(14 * down, 0, 8 * down)
	pose.item = nil
	pose.look = 0
end

-- Tinkering: the right hand taps down on the thing in the left, over and over, with a little turn each time
ANIMATIONS.craft = function(t, p, pose)
	local phase = (t % 0.55) / 0.55
	local tap = phase < 0.7 and smooth(phase / 0.7) or 1 - smooth((phase - 0.7) / 0.3)   -- raised, then dropped
	local settle = smooth(p / 0.08)

	pose.bones.R_Forearm = Angle(-18 * tap * settle, 0, 6 * tap)
	pose.bones.R_Hand = Angle(-22 * tap * settle, 0, 0)
	pose.bones.L_Forearm = Angle(0, 0, -8 * math.sin(t * 2.2))
	pose.bones.L_Hand = Angle(0, 0, 0)

	pose.curl.R, pose.curl.L = 0.6 * settle, 0.7 * settle
	pose.pos = Vector(1.2, 0, 0.8 - 1.8 * (1 - tap) * settle)
	pose.ang = Angle(-2 * tap, 0, 0)
	pose.item = {pos = Vector(0, 0, 0), ang = Angle(0, 12 * math.sin(t * 2.2), 0)}
	pose.look = 5 * settle
end

-- Bones ---------------------------------------------------------------------------------------------------------------------------

local FINGER_ROOTS = {"1", "2", "3", "4"}

local function allBones()
	local list = {}

	for _, side in ipairs({"R", "L"}) do
		for _, name in ipairs({"UpperArm", "Forearm", "Hand"}) do list[#list + 1] = side .. "_" .. name end

		list[#list + 1] = side .. "_Finger0"
		list[#list + 1] = side .. "_Finger01"
		list[#list + 1] = side .. "_Finger02"

		for _, root in ipairs(FINGER_ROOTS) do
			list[#list + 1] = side .. "_Finger" .. root
			list[#list + 1] = side .. "_Finger" .. root .. "1"
			list[#list + 1] = side .. "_Finger" .. root .. "2"
		end
	end

	return list
end

local BONES = allBones()

local function addCurl(set, side, c)
	-- (the animations ask for a grip; the settings decide how much of it to use)
	c = c * ((DubzActions.Config and DubzActions.Config.curlScale) or 1)

	set[side .. "_Finger0"] = Angle(0, -c * 18, -c * 18)
	set[side .. "_Finger01"] = Angle(0, -c * 15, 0)
	set[side .. "_Finger02"] = Angle(0, -c * 20, 0)

	for _, root in ipairs(FINGER_ROOTS) do
		set[side .. "_Finger" .. root] = Angle(0, -c * 45, 0)
		set[side .. "_Finger" .. root .. "1"] = Angle(0, -c * 60, 0)
		set[side .. "_Finger" .. root .. "2"] = Angle(0, -c * 45, 0)
	end
end

-- Shared with the client file, which poses other players' models with the same animations
DubzActions = DubzActions or {}
DubzActions.Animations = ANIMATIONS
DubzActions.Bones = BONES
DubzActions.AddCurl = addCurl

local ZERO = Angle(0, 0, 0)

local function applyBones(vm, set)
	for _, name in ipairs(BONES) do
		local id = vm:LookupBone("ValveBiped.Bip01_" .. name)
		if id then vm:ManipulateBoneAngles(id, set[name] or ZERO) end
	end
end

local function resetBones(self)
	local owner = self:GetOwner()
	local vm = IsValid(owner) and owner:IsPlayer() and owner:GetViewModel()
	if IsValid(vm) then applyBones(vm, {}) end
end

-- Every frame ----------------------------------------------------------------------------------------------------------------------

function SWEP:ClientThink()
	local kind = self:GetKind()
	local length = math.max(self:GetLength(), 0.1)

	local pose = {bones = {}, curl = {R = 0, L = 0}, pos = Vector(), ang = Angle(), look = 0}

	-- (a saved animation, the editor's current pose, or the code preset: see cl_anim.lua)
	local t = math.max(CurTime() - self:GetStart(), 0)
	if self:GetFreeze() > 0 then t = self:GetFreeze() * length end

	DubzActions.Evaluate(kind, t, math.Clamp(t / length, 0, 1), pose, "first")

	addCurl(pose.bones, "R", pose.curl.R)
	addCurl(pose.bones, "L", pose.curl.L)
	DubzActions.ApplyTweaks(kind, pose.bones, "first")

	self.Pose = pose

	local owner = self:GetOwner()
	local vm = IsValid(owner) and owner:IsPlayer() and owner:GetViewModel()
	if IsValid(vm) then applyBones(vm, pose.bones) end
end

-- The arms move and turn as a whole
function SWEP:CalcViewModelView(vm, oldPos, oldAng, pos, ang)
	local pose = self.Pose
	if not pose then return end

	pos = pos + ang:Forward() * pose.pos.x + ang:Right() * pose.pos.y + ang:Up() * pose.pos.z
	ang = Angle(ang.p + pose.ang.p, ang.y + pose.ang.y, ang.r + pose.ang.r)

	return pos, ang
end

-- The view tips down while working
function SWEP:CalcView(ply, pos, ang, fov)
	local pose = self.Pose
	if not pose or pose.look == 0 then return end

	return pos, Angle(ang.p + pose.look, ang.y, ang.r), fov
end

-- The item in the hands -------------------------------------------------------------------------------------------------------------

local held

local function heldModel(model)
	if model == "" then
		if IsValid(held) then held:Remove() end
		held = nil
		return
	end

	if not IsValid(held) or held:GetModel() ~= model then
		if IsValid(held) then held:Remove() end

		held = ClientsideModel(model, RENDERGROUP_OTHER)
		if IsValid(held) then held:SetNoDraw(true) end
	end

	return held
end

function SWEP:PostDrawViewModel(vm, weapon, ply)
	local pose = self.Pose
	local ent = heldModel(self:GetHeldModel())
	if not (pose and pose.item and IsValid(ent)) then return end

	local c = DubzActions.Config
	local offset = Vector(c.itemForward, c.itemRight, c.itemUp)
	local eyeAng = EyeAngles()

	local pos = EyePos() + eyeAng:Forward() * (offset.x + pose.pos.x + pose.item.pos.x) + eyeAng:Right() * (offset.y + pose.pos.y + pose.item.pos.y) + eyeAng:Up() * (offset.z + pose.pos.z + pose.item.pos.z)
	local ang = Angle(eyeAng.p + pose.item.ang.p, eyeAng.y + pose.item.ang.y, eyeAng.r + pose.item.ang.r)

	-- Sized to fit the hands whatever the model is
	local mins, maxs = ent:GetModelRenderBounds()
	local size = math.max(maxs.x - mins.x, maxs.y - mins.y, maxs.z - mins.z, 1)
	ent:SetModelScale(math.Clamp(c.itemSize / size, 0.02, 3), 0)

	ent:SetPos(pos - ang:Forward() * (mins.x + maxs.x) / 2 * ent:GetModelScale() - ang:Right() * (mins.y + maxs.y) / 2 * ent:GetModelScale() - ang:Up() * (mins.z + maxs.z) / 2 * ent:GetModelScale())
	ent:SetAngles(ang)

	local color = self:GetHeldColor()
	local material = self:GetHeldMaterial()

	ent:SetMaterial(material)

	cam.IgnoreZ(true)
	render.SetColorModulation(color.x / 255, color.y / 255, color.z / 255)
	ent:DrawModel()
	render.SetColorModulation(1, 1, 1)
	cam.IgnoreZ(false)
end

function SWEP:Holster()
	resetBones(self)
	heldModel("")
	return true
end

function SWEP:OnRemove()
	resetBones(self)
	heldModel("")
end
