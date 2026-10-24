AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- The title store clerk: press E to open the title store. A clerk spawned from the entities tab is remembered for
-- this map (see sv_dubz_titles.lua); remove one with dubz_titlenpc_remove while looking at it.
function ENT:SpawnFunction(ply, tr, class)
	if not tr.Hit then return end

	local ent = ents.Create(class)
	ent:SetPos(tr.HitPos + Vector(0, 0, 4))
	ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
	ent:Spawn()
	ent:Activate()

	if DubzTitles and DubzTitles.RememberNpc then DubzTitles.RememberNpc(ent) end
	return ent
end

function ENT:Initialize()
	self:SetModel("models/Humans/Group01/male_07.mdl")
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetNPCState(NPC_STATE_SCRIPT)
	self:SetSolid(SOLID_BBOX)
	self:CapabilitiesAdd(bit.bor(CAP_ANIMATEDFACE, CAP_TURN_HEAD))
	self:SetUseType(SIMPLE_USE)
	self:SetMaxYawSpeed(90)
	self:DropToFloor()
end

function ENT:OnTakeDamage() return 0 end

function ENT:AcceptInput(name, activator)
	if name ~= "Use" or not IsValid(activator) or not activator:IsPlayer() then return end

	if (activator.DubzTitleNpcNext or 0) > CurTime() then return end
	activator.DubzTitleNpcNext = CurTime() + 1

	if DubzTitles and DubzTitles.OpenMenu then DubzTitles.OpenMenu(activator) end
end
