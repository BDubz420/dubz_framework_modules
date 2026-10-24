-- Skill registry and the shared readers. Other addons add skills with DubzSkills.Register(); the
-- server networks levels (immediately) and XP (every few seconds) as dubz_sk_<id>_lv / _xp.
local cfg = DubzSkills.Config

DubzSkills.Skills = {}       -- id -> definition
DubzSkills.Categories = {}   -- ordered {id, name, skills = {definition, ...}}

for _, category in ipairs(cfg.categories) do
	table.insert(DubzSkills.Categories, {id = category.id, name = category.name, skills = {}})
end

local function findCategory(id)
	for _, category in ipairs(DubzSkills.Categories) do
		if category.id == id then return category end
	end
end

-- def: id, name, desc, category, optional xpBase / xpExponent / maxLevel,
--      optional effect(level) -> string shown in the tooltip (e.g. "Run speed: 204")
-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzSkills.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("skills")
end

function DubzSkills.Register(def)
	local category = findCategory(def.category)
	if not category then
		category = {id = def.category, name = def.category, skills = {}}
		table.insert(DubzSkills.Categories, category)
	end

	def.maxLevel = def.maxLevel or cfg.maxLevel
	-- xpBase / xpExponent stay nil unless the skill overrides them, so the live config values apply

	-- Re-registering (e.g. on a Lua refresh) replaces the old definition
	if DubzSkills.Skills[def.id] then
		for i, existing in ipairs(category.skills) do
			if existing.id == def.id then table.remove(category.skills, i) break end
		end
	end

	DubzSkills.Skills[def.id] = def
	table.insert(category.skills, def)
end

-- Total XP needed to reach `level`
function DubzSkills.XPForLevel(def, level)
	local total = 0
	for i = 1, level do total = total + (def.xpBase or cfg.xpBase) * i ^ (def.xpExponent or cfg.xpExponent) end
	return math.floor(total)
end

function DubzSkills.LevelFromXP(def, xp)
	local level = 0
	while level < def.maxLevel and xp >= DubzSkills.XPForLevel(def, level + 1) do level = level + 1 end
	return level
end

function DubzSkills.GetLevel(ply, id)
	return ply:GetNWInt("dubz_sk_" .. id .. "_lv", 0)
end

function DubzSkills.GetXP(ply, id)
	return ply:GetNWInt("dubz_sk_" .. id .. "_xp", 0)
end

-- Overall level ----------------------------------------------------------------------------------------

-- Total XP needed to reach an overall level (level 1 = 0 XP)
function DubzSkills.XPForOverall(level)
	local total = 0
	for i = 1, level - 1 do total = total + cfg.overallXPBase * i ^ cfg.overallXPExponent end
	return math.floor(total)
end

function DubzSkills.OverallLevelFromXP(xp)
	local level = 1
	while level < cfg.maxOverallLevel and xp >= DubzSkills.XPForOverall(level + 1) do level = level + 1 end
	return level
end

-- All skill XP together (as last networked), plus any admin bonus XP.
function DubzSkills.GetTotalXP(ply)
	local total = ply:GetNWInt("dubz_sk__bonus_xp", 0)
	for id in pairs(DubzSkills.Skills) do total = total + DubzSkills.GetXP(ply, id) end
	return total
end

function DubzSkills.GetOverallLevel(ply)
	return ply:GetNWInt("dubz_overall_lv", 1)
end

-- 0-1 progress to the next overall level
function DubzSkills.OverallProgress(ply)
	local level = DubzSkills.GetOverallLevel(ply)
	if level >= cfg.maxOverallLevel then return 1 end

	local from = DubzSkills.XPForOverall(level)
	local to = DubzSkills.XPForOverall(level + 1)
	return math.Clamp((DubzSkills.GetTotalXP(ply) - from) / (to - from), 0, 1)
end

-- 0-1 progress through the current level
function DubzSkills.Progress(ply, id)
	local def = DubzSkills.Skills[id]
	if not def then return 0 end

	local level = DubzSkills.GetLevel(ply, id)
	if level >= def.maxLevel then return 1 end

	local from = DubzSkills.XPForLevel(def, level)
	local to = DubzSkills.XPForLevel(def, level + 1)
	return math.Clamp((DubzSkills.GetXP(ply, id) - from) / (to - from), 0, 1)
end
