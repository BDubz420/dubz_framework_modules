AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetShopId(self.ShopId or "store")

	local def = DubzShops.Get(self:GetShopId())

	self:SetModel(def and def.model ~= "" and def.model or "models/Humans/Group01/male_07.mdl")
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetNPCState(NPC_STATE_SCRIPT)
	self:SetSolid(SOLID_BBOX)
	self:CapabilitiesAdd(bit.bor(CAP_ANIMATEDFACE, CAP_TURN_HEAD))
	self:SetUseType(SIMPLE_USE)
	self:SetMaxYawSpeed(90)
	self:DropToFloor()

	local idle = self:LookupSequence("idle_all_01")
	if idle > 0 then self:ResetSequence(idle) end
end

-- Thinks every tick so the animation plays; NPC Life (looking at you, changing idles, lines) runs here
function ENT:Think()
	if DubzNPCLife and DubzNPCLife.Think then DubzNPCLife.Think(self) end

	self:NextThink(CurTime())
	return true
end

function ENT:OnTakeDamage() return 0 end

-- E: talk
function ENT:AcceptInput(name, activator)
	if name ~= "Use" or not IsValid(activator) or not activator:IsPlayer() then return end
	if (activator.DubzShopUse or 0) > CurTime() then return end
	activator.DubzShopUse = CurTime() + 1

	if activator:GetPos():Distance(self:GetPos()) > DubzShops.Config.TalkDistance + 40 then return end

	DubzShops.Talk(activator, self, self:GetShopId())
end

-- Points a placed shop NPC at another shop
concommand.Add("dubz_shop_set", function(ply, _, args)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end

	local ent = ply:GetEyeTrace().Entity
	local id = args[1]

	if not (IsValid(ent) and ent.SetShopId and id and DubzShops.Get(id)) then
		ply:ChatPrint("Look at a shop NPC and give a shop Id from the Shops table.")
		return
	end

	ent:SetShopId(id)

	local def = DubzShops.Get(id)
	if def.model and def.model ~= "" then ent:SetModel(def.model) end

	ply:ChatPrint("That NPC now runs the shop '" .. id .. "'.")
end)
