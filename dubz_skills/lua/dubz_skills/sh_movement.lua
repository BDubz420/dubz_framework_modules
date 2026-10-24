-- The Walking and Running skills, and the movement speeds they control.
-- Players walk slowly by default (as if always holding Alt) and run a little slower than the stock sprint.
-- The speed is applied in SetupMove, which runs on both the server and the client so it predicts cleanly.
local mcfg = DubzSkills.Config.movement

local function walkSpeed(level) return mcfg.baseWalk + level * mcfg.walkPerLevel end
local function runSpeed(level) return mcfg.baseRun + level * mcfg.runPerLevel end

DubzSkills.Register({
	id = "walking", category = "movement", name = "Walking",
	desc = "Walking around the city makes you steadier on your feet.",
	xpBase = 1000,   -- ~1950 XP a day walking: level 2 after about 1.7 days
	effect = function(level) return "Walk speed: " .. walkSpeed(level) end,
})

DubzSkills.Register({
	id = "running", category = "movement", name = "Running",
	desc = "Running builds your stamina and top speed. It takes a long time.",
	xpBase = 1300,   -- ~2600 XP a day running: level 2 after about 1.7 days
	effect = function(level) return "Run speed: " .. runSpeed(level) end,
})

-- Returns the player's current walk and run speed.
function DubzSkills.GetSpeeds(ply)
	return walkSpeed(DubzSkills.GetLevel(ply, "walking")), runSpeed(DubzSkills.GetLevel(ply, "running"))
end

hook.Add("SetupMove", "DubzSkills_Movement", function(ply, mv)
	if not mcfg.enabled or not DubzSkills.Enabled() then return end
	if ply:GetMoveType() ~= MOVETYPE_WALK or ply:InVehicle() then return end

	-- Something else froze or cuffed the player (speed ~0): leave it alone
	if ply:GetWalkSpeed() <= 10 then return end

	local walk, run = DubzSkills.GetSpeeds(ply)
	-- Out of breath (see sv_movement.lua): no sprinting until stamina has recovered
	local sprinting = mv:KeyDown(IN_SPEED) and not ply:GetNWBool("dubz_exhausted", false)
	local speed = sprinting and run or walk

	-- Other addons (e.g. surrendering) can cap a player's speed by setting dubz_speed_cap on them
	local cap = ply:GetNWFloat("dubz_speed_cap", 0)
	if cap > 0 then speed = math.min(speed, cap) end

	mv:SetMaxSpeed(speed)
	mv:SetMaxClientSpeed(speed)
end)
