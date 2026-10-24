-- The City Worker's shovel: for clearing rubble.
SWEP.Base = "dubz_cw_tool"

SWEP.PrintName = "City Worker Shovel"
SWEP.Instructions = "Click on a pile of rubble to scoop it away."
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Slot = 1
SWEP.SlotPos = 3

SWEP.ViewModel = "models/props_junk/shovel01a.mdl"
SWEP.WorldModel = "models/props_junk/shovel01a.mdl"
SWEP.DubzCWTool = "shovel"
SWEP.ConfigKey = "Shovel"          -- (its place in the hand is dialled in the admin menu: Dial In: Shovel)
SWEP.SwingStyle = "scoop"
SWEP.SwingTime = 0.8
SWEP.ClickDelay = 0.9
SWEP.Primary.Automatic = false     -- (one click, one scoop)

-- (a long tool: held further out, and turned so the blade points forward)
SWEP.ViewOffset = Vector(26, 10, -14)
SWEP.ViewTurn = Angle(90, 0, 0)
SWEP.HandOffset = Vector(2, 0, -2)
SWEP.HandTurn = Angle(0, 180, 90)
