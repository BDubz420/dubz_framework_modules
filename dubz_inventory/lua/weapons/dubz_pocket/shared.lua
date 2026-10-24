-- The pocket: hold left click on an item to put it in your inventory, right click to drop the last item,
-- reload to open the inventory. Replaces DarkRP's pocket SWEP (stock "pocket"); put "dubz_pocket" in your
-- DarkRP default weapons instead of "pocket".
SWEP.PrintName = "Pocket"
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.Base = "weapon_cs_base2"

SWEP.Author = "BDubz420"
SWEP.Instructions = "Hold left click to pick up\nRight click or Reload to open the inventory"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.IsDarkRPPocket = true

SWEP.IconLetter = ""

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "rpg"
SWEP.WorldModel = ""

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "Dubz Inventory"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

function SWEP:Initialize()
	self:SetHoldType("normal")
end

function SWEP:Deploy()
	return true
end

function SWEP:DrawWorldModel() end

function SWEP:PreDrawViewModel(vm)
	return true
end

function SWEP:Holster()
	if not SERVER then return true end

	local owner = self:GetOwner()
	if IsValid(owner) then
		owner:DrawViewModel(true)
		owner:DrawWorldModel(true)
	end

	return true
end

-- The inventory (lua/dubz_inventory) does the actual work.
function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.2)

	if not SERVER then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	if not (DubzInv and DubzInv.TryPickup) then
		owner:ChatPrint("The inventory isn't loaded. Check the server console for [DubzInventory] messages.")
		return
	end

	DubzInv.TryPickup(owner)
end

local function openPocket()
	if DubzInv and DubzInv.OpenMenu then
		DubzInv.OpenMenu()
	else
		chat.AddText(Color(255, 80, 80), "The inventory isn't loaded. Check your console for [DubzInventory] messages.")
	end
end

-- Right click (and Reload) open your pocket. Nothing is dropped by clicking: items are dropped from the window.
function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.3)
	if CLIENT and IsFirstTimePredicted() then openPocket() end
end

function SWEP:Reload()
	if CLIENT and IsFirstTimePredicted() then openPocket() end
end
