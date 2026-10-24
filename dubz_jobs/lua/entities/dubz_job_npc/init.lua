AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Spawn it from the entities tab (Dubz Jobs) and keep it with a perma-props tool; nothing here saves it.
function ENT:Initialize()
	if self.PresetSite then self:SetSite(self.PresetSite) end

	self:SetModel(DubzJobs.NpcModels[self:GetSite()] or "models/Humans/Group01/male_09.mdl")
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetNPCState(NPC_STATE_SCRIPT)
	self:SetSolid(SOLID_BBOX)
	self:CapabilitiesAdd(bit.bor(CAP_ANIMATEDFACE, CAP_TURN_HEAD))
	self:SetUseType(SIMPLE_USE)
	self:SetMaxYawSpeed(90)
	self:DropToFloor()

	self:ApplyPose()
end

-- The pose the site's row says (Jobs > Job Sites > Pose): "auto" lets the NPC Life addon animate him, anything else holds him there
function ENT:ApplyPose()
	local site = DubzJobs.Sites[self:GetSite()]
	local pose = site and site.pose or "auto"

	self.PoseNow = pose

	if DubzNPCLife and DubzNPCLife.SetPose then
		DubzNPCLife.SetPose(self, pose)
	elseif pose ~= "auto" then
		local seq = self:LookupSequence(pose)
		if seq > 0 then self:ResetSequence(seq) end
	end
end

-- Thinks every tick (so the animation plays): NPC Life looks at you and keeps the pose; the pose is picked up again if the admin menu changes it
function ENT:Think()
	local site = DubzJobs.Sites[self:GetSite()]

	if (site and site.pose or "auto") ~= self.PoseNow then self:ApplyPose() end

	if DubzNPCLife and DubzNPCLife.Think then DubzNPCLife.Think(self) end

	self:NextThink(CurTime())
	return true
end

function ENT:OnTakeDamage() return 0 end

function ENT:AcceptInput(name, activator)
	if name ~= "Use" or not IsValid(activator) or not activator:IsPlayer() then return end

	if (activator.DubzJobsUse or 0) > CurTime() then return end
	activator.DubzJobsUse = CurTime() + 1

	DubzJobs.Talk(activator, self)
end
