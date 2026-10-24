-- The foreman's conversation. The foreman is a Dubz Jobs site NPC (Jobs > Job Sites, site "cityworker"); the Jobs addon asks this file first (the DubzJobsTalk
-- hook) and, when it answers, uses this conversation instead of its default one. It is the same conversation box, with the foreman's own lines and options:
-- what the job is, how a repair goes, what it pays, where the parts come from, tools that were lost, and quitting.
local cfg = DubzCW.Config

local function money(amount)
	return DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(amount) or ("$" .. amount)
end

-- The repair jobs on offer and what each pays, in a sentence
local function payText()
	local parts = {}

	for id, def in pairs(DubzCW.Tasks) do
		local row = DubzCW.TaskRows[id]

		if row and row.enabled then parts[#parts + 1] = string.lower(row.name or def.name) .. " pays " .. money(tonumber(row.payout) or 0) end
	end

	table.sort(parts)

	if #parts == 0 then return "There is no work on the board at the moment." end

	local text = "Right now: " .. table.concat(parts, ", ") .. "."

	if cfg.ScrapId ~= "" and cfg.ScrapMax > 0 then text = text .. " On top of that you keep the old parts: a bit of scrap for every job." end
	if cfg.JobSalary > 0 then text = text .. " And the city pays you " .. money(cfg.JobSalary) .. " a paycheck just for being on the job." end

	return text
end

local HOW_IT_GOES = "I'll send you to something broken, and you'll get a marker on your screen. First you pull the machine away from the wall, "
	.. "then you undo the four bolts of the back plate with the wrench and carry the plate out of the way. Behind it is a burnt circuit board: one snip with the pliers and it comes out "
	.. "as scrap you can keep. Fit a new one, put the plate back, do the bolts up again and push the machine home. Whatever glows is what you do next. "
	.. "Hold left click for the bolts, click once for the snip, E for everything else."

local PARTS = "The new boards come from the F4 menu, under Repair Parts, and they aren't free. Buy a spare before you go out, so you aren't walking back and forth. "
	.. "Carry it with E. When you bring it close to where it goes, it clicks in."

local menu

local function missingTools(ply)
	local missing = {}

	for _, class in ipairs(DubzCW.ToolList()) do
		if not ply:HasWeapon(class) then missing[#missing + 1] = class end
	end

	return missing
end

function menu(ply, npc, site, opening)
	local hired = DubzJobs.IsHired(ply, site)
	local options = {}
	local task = DubzCW.Active[ply:SteamID64()]
	local text = opening

	if not hired then
		text = text or "Looking for work? Things break in this city every day, and I never have enough hands. Come in, sit, ask what you like."

		options[#options + 1] = {label = "What does the job involve?", run = function(p)
			return menu(p, npc, site, "You fix what the city can't afford to leave broken. Machines, to start with. You're sent out, you take the thing apart, put it right and put it back together, and I pay you for it. No boss on your back: just you, a wrench and some pliers.")
		end}

		options[#options + 1] = {label = "How does a repair go?", run = function(p) return menu(p, npc, site, HOW_IT_GOES) end}
		options[#options + 1] = {label = "What does it pay?", run = function(p) return menu(p, npc, site, payText()) end}

		options[#options + 1] = {label = "I'll take the job.", run = function(p)
			local ok, reason = DubzJobs.Hire(p, site)

			if not ok then return menu(p, npc, site, reason or "Not right now.") end

			return menu(p, npc, site, "Good. The wrench and pliers are yours. First job should find you in a minute: look for the marker and the glow. Come back if you lose your tools.")
		end}
	else
		if not text then
			if task then
				text = "You're on a job already: " .. task.def.name .. ". Step " .. math.min(task.step, #task.def.steps) .. " of " .. #task.def.steps .. "."
			else
				text = "Back already? Something out there is still broken. Wait a bit and I'll send you."
			end
		end

		options[#options + 1] = {label = "Remind me how a repair goes.", run = function(p) return menu(p, npc, site, HOW_IT_GOES) end}
		options[#options + 1] = {label = "Where do I get the parts?", run = function(p) return menu(p, npc, site, PARTS .. " A board is " .. money(cfg.PartPrice) .. ".") end}
		options[#options + 1] = {label = "What does the work pay?", run = function(p) return menu(p, npc, site, payText()) end}

		if #missingTools(ply) > 0 then
			options[#options + 1] = {label = "I lost my tools (" .. money(site.price) .. ").", run = function(p)
				local lost = missingTools(p)

				if #lost == 0 then return menu(p, npc, site, "You've got everything you need.") end
				if p.canAfford and not p:canAfford(site.price) then return menu(p, npc, site, "That's " .. money(site.price) .. ". You don't have it on you.") end

				if site.price > 0 then p:addMoney(-site.price) end
				for _, class in ipairs(lost) do p:Give(class) end

				return menu(p, npc, site, "There you go. Don't lose these ones.")
			end}
		end

		if task then
			options[#options + 1] = {label = "I want to give this job up.", run = function(p)
				local current = DubzCW.Active[p:SteamID64()]
				if current then DubzCW.Cancel(current, "You gave the job up.") end

				return menu(p, npc, site, "Fine. I'll find you another one in a bit.")
			end}
		end

		options[#options + 1] = {label = "I want to quit.", run = function(p)
			return {text = "You want out? Fair enough. Keep the tools, you earned them. Your own clothes are waiting.", options = {
				{label = "Yes, I quit.", run = function(q)
					DubzJobs.Quit(q, site)

					return {text = "Thanks for the help. The city won't fix itself, but it was nice while it lasted.", options = {{label = "Take care.", run = function() end}}}
				end},
				{label = "Never mind.", run = function(q) return menu(q, npc, site) end},
			}}
		end}
	end

	options[#options + 1] = {label = hired and "Back to work." or "Not today.", run = function() end}

	return {text = text, options = options, name = site.npc}
end

-- The Jobs addon asks before it starts its own conversation: this foreman is answered here
hook.Add("DubzJobsTalk", "DubzCW_Foreman", function(ply, npc, site)
	if not site or site.id ~= "cityworker" then return end

	local node = menu(ply, npc, site)

	DubzJobs.Say(ply, npc, site.npc, node.text, node.options)

	return true
end)
