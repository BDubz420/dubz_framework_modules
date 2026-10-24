-- Top bar entries. Order here is draw order within each side.
--   side  = "left" (default) or "right"
--   func  = returns the text to show; return nil / false / "" / 0 to hide the entry
--   mat   = icon16 path, color = tint of the box (a Color, or function(lp) returning one)
BHUD.Bars = {}

local function addBar(tab)
	table.insert(BHUD.Bars, tab)
end

local RED = Color(255, 20, 20)
local GREEN = Color(120, 225, 0)
local DARK = Color(200, 200, 200) -- neutral tint: faint light box so every entry shows its border
local BROWN = Color(107, 92, 42)

local smoothFPS = 0

-- Left side ---------------------------------------------------------------

addBar({
	name = "name", side = "left",
	mat = "icon16/user.png", color = DARK,
	func = function(lp) return "Name: " .. lp:Nick() end,
})

addBar({
	name = "health", side = "left",
	mat = "icon16/heart.png", color = RED,
	func = function(lp) return "Health: " .. lp:Health() end,
})

addBar({
	name = "armor", side = "left",
	mat = "icon16/shield.png", color = Color(20, 20, 255),
	func = function(lp)
		local armor = lp:Armor()
		if armor <= 0 then return end
		return "Armor: " .. armor
	end,
})

addBar({
	name = "hunger", side = "left",
	mat = "icon16/cake.png", color = BROWN,
	func = function(lp)
		local energy = lp:getDarkRPVar("Energy")
		if not energy then return end
		return "Hunger: " .. math.Round(energy)
	end,
})

addBar({
	name = "job", side = "left",
	mat = "icon16/briefcase.png", color = DARK,
	func = function(lp)
		return "Job: " .. (lp:getDarkRPVar("job") or team.GetName(lp:Team()))
	end,
})

addBar({
	name = "money", side = "left",
	mat = "icon16/money.png", color = GREEN,
	func = function(lp) return "Money: " .. DarkRP.formatMoney(lp:getDarkRPVar("money") or 0) end,
})

addBar({
	name = "salary", side = "left",
	mat = "icon16/coins.png", color = GREEN,
	func = function(lp)
		local salary = lp:getDarkRPVar("salary")
		if not salary or salary <= 0 then return end
		return "Salary: " .. DarkRP.formatMoney(salary)
	end,
})

addBar({
	name = "karma", side = "left",
	mat = "icon16/star.png",
	color = function(lp)
		local karma = BHUD.GetKarma(lp) or 100
		if karma >= 100 then return GREEN end
		if karma >= 50 then return Color(255, 200, 0) end
		return RED
	end,
	func = function(lp)
		local karma = BHUD.GetKarma(lp)
		if not karma then return end
		return "Karma: " .. karma
	end,
})

addBar({
	name = "gunlicense", side = "left",
	mat = "icon16/page.png", color = DARK,
	func = function(lp)
		if not lp:getDarkRPVar("HasGunlicense") then return end
		return "Gun licensed"
	end,
})

-- Right side (listed left to right) ---------------------------------------

addBar({
	name = "arrested", side = "right",
	mat = "icon16/lock.png", color = RED,
	func = function(lp)
		if not (lp.isArrested and lp:isArrested()) then return end

		local left = BHUD.Remaining(lp, "bhud_arrest_end")
		if left <= 0 then return "Arrested" end
		return "Arrested: " .. math.ceil(left)
	end,
})

addBar({
	name = "nlr", side = "right",
	mat = "icon16/time.png", color = RED,
	func = function(lp)
		-- Timer comes from the standalone dubz_nlr addon
		if not (DubzNLR and DubzNLR.Remaining) then return end

		local left = DubzNLR.Remaining(lp)
		if left <= 0 then return end

		return (DubzNLR.InZone(lp) and "NLR Zone: " or "NLR: ") .. math.ceil(left)
	end,
})

addBar({
	name = "wanttime", side = "right",
	mat = "icon16/clock_red.png", color = RED,
	func = function(lp)
		if not (lp.isWanted and lp:isWanted()) then return end
		local left = BHUD.Remaining(lp, "bhud_wanted_end")
		if left <= 0 then return end
		return "Want Time: " .. math.ceil(left)
	end,
})

addBar({
	name = "wantedreason", side = "right",
	mat = "icon16/exclamation.png", color = RED,
	func = function(lp)
		if not (lp.isWanted and lp:isWanted()) then return end
		local reason = lp:getDarkRPVar("wantedReason")
		if not reason or reason == "" then return "Wanted" end
		return "Wanted: " .. reason
	end,
})

addBar({
	name = "mayorgrace", side = "right",
	mat = "icon16/user_suit.png", color = Color(214, 150, 60),
	func = function()
		local left = BHUD.MayorGraceRemaining()
		if left <= 0 then return end
		return "Mayor Grace Period: " .. math.ceil(left)
	end,
})

addBar({
	name = "org", side = "right",
	mat = "icon16/group.png", color = function(lp) return BHUD.GetOrgColor(lp) end,
	func = function(lp)
		local org = BHUD.GetOrg(lp)
		if org == "" then return end
		return "Org: " .. org
	end,
})

-- Overall level (from the Dubz Skills addon; hidden if it isn't installed or is switched off)
addBar({
	name = "level", side = "right",
	mat = "icon16/medal_gold_1.png", color = Color(241, 196, 15),
	func = function(lp)
		if not (DubzSkills and DubzSkills.GetOverallLevel and DubzSkills.Enabled()) then return end
		return "Level: " .. DubzSkills.GetOverallLevel(lp)
	end,
})

addBar({
	name = "props", side = "right",
	mat = "icon16/box.png", color = BROWN,
	func = function(lp)
		local count = lp:GetCount("props")
		if not count or count <= 0 then return end
		local cv = GetConVar("sbox_maxprops")
		return "Props: " .. count .. (cv and ("/" .. cv:GetInt()) or "")
	end,
})

addBar({
	name = "ping", side = "right",
	mat = "icon16/connect.png", color = Color(60, 160, 220),
	func = function(lp)
		local ping = lp:Ping()
		if ping <= 0 then return end
		return "Ping: " .. ping
	end,
})

addBar({
	name = "fps", side = "right",
	mat = "icon16/monitor.png", color = DARK,
	func = function()
		smoothFPS = Lerp(0.1, smoothFPS, 1 / math.max(RealFrameTime(), 0.001))
		return "FPS: " .. math.Round(smoothFPS)
	end,
})

addBar({
	name = "daytime", side = "right",
	mat = "icon16/calendar.png",
	color = function() return BHUD.Config.dayColors[tonumber(os.date("%w")) + 1] end,
	textColor = function() return BHUD.Config.dayColors[tonumber(os.date("%w")) + 1] end,
	func = function()
		-- Real-world clock (os time), hour without the leading zero: "Tue. 6:20 PM".
		return os.date("%a. ") .. tonumber(os.date("%I")) .. os.date(":%M %p")
	end,
})

addBar({
	name = "playtime", side = "right",
	mat = "icon16/clock.png", color = DARK,
	func = function(lp)
		local seconds = BHUD.GetPlayTime(lp)
		if not seconds then return end
		return "Time Played: " .. BHUD.FormatTime(seconds)
	end,
})
