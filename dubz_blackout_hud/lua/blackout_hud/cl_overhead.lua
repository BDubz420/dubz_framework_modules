-- Overhead player info, redrawn so extra lines can sit above DarkRP's name/health/job:
--   org (top) / title / name / level / job / wanted
-- Doors are handled separately in cl_doors.lua.
local LINE_H = 24

local function shadowText(text, x, y, col, alpha)
	draw.SimpleText(text, "daHUDName", x + 1, y + 1, Color(0, 0, 0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText(text, "daHUDName", x, y, Color(col.r, col.g, col.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

local function playerLines(ply)
	local lines = {}

	-- A mask / face covering hides who they are: no organisation, title or name, just the hidden-identity text
	local hidden = DubzCosmetics and DubzCosmetics.HidesIdentity and DubzCosmetics.HidesIdentity(ply)

	local org = hidden and "" or BHUD.GetOrg(ply)
	if org ~= "" then lines[#lines + 1] = {org, BHUD.GetOrgColor(ply)} end

	-- Title from the Dubz title system (NW vars it already networks).
	local title = hidden and "" or ply:GetNWString("DubzTitles_Title", "")
	if title ~= "" then
		local vec = ply:GetNWVector("DubzTitles_Color", Vector(255, 255, 255))
		lines[#lines + 1] = {title, Color(vec.x, vec.y, vec.z)}
	end

	if hidden then
		lines[#lines + 1] = {DubzCosmetics.Config.hiddenIdentityText or "<identity hidden>", Color(170, 170, 170)}
	else
		lines[#lines + 1] = {ply:Nick(), team.GetColor(ply:Team())}
	end
	-- Overall level from the skills addon (the line is left out if that addon isn't installed)
	if DubzSkills and DubzSkills.GetOverallLevel then
		lines[#lines + 1] = {"Level: " .. DubzSkills.GetOverallLevel(ply), color_white}
	end

	lines[#lines + 1] = {ply:getDarkRPVar("job") or team.GetName(ply:Team()), team.GetColor(ply:Team())}

	if ply.isWanted and ply:isWanted() then lines[#lines + 1] = {"Wanted!", Color(255, 40, 40)} end

	return lines
end

local function drawPlayers(lp)
	local maxDist = BHUD.Config.overheadDistance
	local shootPos = lp:GetShootPos()

	for _, ply in ipairs(player.GetAll()) do
		if ply == lp or not ply:Alive() or ply:IsDormant() or ply:GetNoDraw() then continue end

		local headPos = ply:EyePos()
		local dist = shootPos:Distance(headPos)
		if dist > maxDist then continue end

		local blocked = util.TraceLine({
			start = shootPos,
			endpos = headPos,
			filter = {lp, ply},
			mask = MASK_SHOT,
		}).Hit
		if blocked then continue end

		local screen = (headPos + Vector(0, 0, 14)):ToScreen()
		if not screen.visible then continue end

		local alpha = 255 * math.Clamp((maxDist - dist) / (maxDist * 0.3), 0, 1)
		local lines = playerLines(ply)
		local y = screen.y - #lines * LINE_H

		for _, line in ipairs(lines) do
			shadowText(line[1], screen.x, y, line[2], alpha)
			y = y + LINE_H
		end
	end
end

function BHUD.DrawOverhead(lp)
	if not BHUD.Config.replaceEntityDisplay then return end

	drawPlayers(lp)
end

-- The title system draws its own overhead title; the HUD draws it now.
hook.Add("InitPostEntity", "BHUD_TakeOverTitles", function()
	if DubzTitles and DubzTitles.Config then DubzTitles.Config.DrawOverhead = not BHUD.Config.replaceEntityDisplay end
end)
