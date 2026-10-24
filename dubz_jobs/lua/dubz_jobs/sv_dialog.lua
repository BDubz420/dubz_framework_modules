-- Job NPCs, server side: the conversation, hiring and quitting.
-- Everything is decided here; the client only shows the text and sends back which option was picked.
-- A conversation is a set of nodes. Each node has text and options; an option can run an action and go to another
-- node, or close the conversation. Nodes and actions are in `nodes` below, so adding a job site means adding a row to
-- the Job Sites table (and, if it needs its own lines, a node set).
util.AddNetworkString("DubzJobs_Talk")     -- server -> client: the current node (JSON)
util.AddNetworkString("DubzJobs_Choose")   -- client -> server: the NPC and the option picked

local cfg = DubzJobs.Config

local function say(ply, text, kind)
	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind or 0, 5, text) else ply:ChatPrint(text) end
end

local function money(amount)
	return DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(amount) or ("$" .. amount)
end

-- What this site's NPC says: the site's own wording (DubzJobs.Lines[site id]), else the default (the miner's)
local function line(site, key, fallback)
	local set = DubzJobs.Lines[site and site.id or ""]

	return set and set[key] or fallback
end

-- Hiring and quitting --------------------------------------------------------------------------------------------------

local function hasTool(ply, site)
	if ply:HasWeapon(site.tool) then return true end

	-- A tool kept in the pocket counts too
	if DubzInv and DubzInv.GetSlots then
		for _, rec in pairs(DubzInv.GetSlots(ply) or {}) do
			if rec.class == site.tool or (rec.data and rec.data.Class == site.tool) then return true end
		end
	end

	return false
end

local function giveTool(ply, site)
	if hasTool(ply, site) then return end
	ply:Give(site.tool)
end

function DubzJobs.IsHired(ply, site)
	return ply:Team() == DubzJobs.TeamOf(site.job)
end

-- Puts the player in the job. Their position, health and everything they hold stay (see sv_jobs.lua); the job's outfit
-- and accessories come from the tables for it. Returns true, or false and a reason.
function DubzJobs.Hire(ply, site)
	local index = DubzJobs.TeamOf(site.job)
	if not index then return false, "That job doesn't exist (check the job command '" .. tostring(site.job) .. "')." end
	if ply.isArrested and ply:isArrested() then return false, "You can't take a job while you are arrested." end

	if ply:Team() ~= index and not ply:changeTeam(index, true, true) then return false, "You can't take that job right now." end

	giveTool(ply, site)
	return true
end

-- Back to the default job. Everything they hold stays (a lost tool stays lost); only the job's own gear goes.
function DubzJobs.Quit(ply, site)
	local default = GAMEMODE and GAMEMODE.DefaultTeam
	if not default then return false end

	if ply:Team() ~= default then ply:changeTeam(default, true, true) end
	return true
end

-- The conversation --------------------------------------------------------------------------------------------------------

local nodes = {}

nodes.start = function(ply, site)
	if DubzJobs.IsHired(ply, site) then
		local options = {}

		if not hasTool(ply, site) then
			options[#options + 1] = {label = "I lost my tool. I need another (" .. money(site.price) .. ").", action = "buytool"}
		end

		options[#options + 1] = {label = "I'm done. I want to quit.", node = "quit"}
		hook.Run("DubzJobsExtraOptions", ply, site, options)
		options[#options + 1] = {label = "Back to work.", close = true}

		return {text = line(site, "back", "Back already? The rocks aren't going to break themselves."), options = options}
	end

	local options = {
		{label = "Tell me about the job.", node = "about"},
	}
	-- Other addons can add entries (the mining system adds "sell everything I'm carrying")
	hook.Run("DubzJobsExtraOptions", ply, site, options)
	options[#options + 1] = {label = "Not today.", close = true}

	return {
		text = line(site, "welcome", "You looking for work? Honest work, honest money, if you don't mind the dust."),
		options = options,
	}
end

nodes.about = function(ply, site)
	return {
		text = line(site, "about", "You break rock and bring back what you find. I'll put you in work clothes and a hard hat, and hand you a pickaxe. The pickaxe is yours to keep, even if you quit. Lose it and I'll sell you another."),
		options = {
			{label = "I'll take it.", action = "hire"},
			{label = "Maybe later.", close = true},
		},
	}
end

nodes.hired = function(ply, site)
	return {
		text = line(site, "hired", "Good. Hat, overalls, pickaxe. The rocks are down the tunnel. Come back when you want to quit."),
		options = {{label = "On my way.", close = true}},
	}
end

nodes.quit = function(ply, site)
	return {
		text = line(site, "quit", "You want out? Fair enough. You keep the pickaxe and whatever you dug up. Your own clothes are waiting."),
		options = {
			{label = "Yes, I quit.", action = "quit"},
			{label = "Never mind.", node = "start"},
		},
	}
end

nodes.quit_done = function(ply, site)
	return {text = line(site, "quitDone", "Take care out there."), options = {{label = "Thanks.", close = true}}}
end

nodes.bought = function(ply, site)
	return {text = line(site, "bought", "There you go. Don't lose this one."), options = {{label = "Thanks.", close = true}}}
end

-- A plain message from an action (the action returns "message", text)
nodes.message = function(ply, site, reason)
	return {text = reason or "", options = {{label = "Thanks.", close = true}}}
end

nodes.failed = function(ply, site, reason)
	return {text = reason or "Something went wrong.", options = {{label = "Alright.", close = true}}}
end

-- What the actions do. Each returns the node to show next.
local actions = {}

actions.hire = function(ply, site)
	local ok, reason = DubzJobs.Hire(ply, site)
	if not ok then return "failed", reason end

	return "hired"
end

actions.quit = function(ply, site)
	DubzJobs.Quit(ply, site)
	return "quit_done"
end

actions.buytool = function(ply, site)
	if hasTool(ply, site) then return "start" end
	if not ply:canAfford(site.price) then return "failed", "That's " .. money(site.price) .. ". You don't have it." end

	ply:addMoney(-site.price)
	giveTool(ply, site)
	return "bought"
end

-- Sending a node ------------------------------------------------------------------------------------------------------

local function show(ply, npc, site, nodeId, reason)
	local build = nodes[nodeId] or nodes.start
	local node = build(ply, site, reason)

	-- Remember what this player can pick, so the choice can be checked
	local options = {}
	local list = {}

	for index, option in ipairs(node.options) do
		options[index] = option
		list[index] = {id = index, label = option.label, close = option.close == true}
	end

	ply.DubzJobsTalk = {npc = npc, site = site, options = options}

	net.Start("DubzJobs_Talk")
		net.WriteEntity(npc)
		net.WriteString(util.TableToJSON({name = site.npc, text = node.text, options = list}))
	net.Send(ply)
end

-- A conversation for any other NPC (the weed buyer, a dealer ...) in the same box. `options` is a list of {label = "...", run = function(ply) ... end}:
-- run is called when it is picked and may return a new {text = "...", options = {...}, name = "..."} to carry on; returning nothing ends the talk.
function DubzJobs.Say(ply, npc, name, text, options)
	local list = {}

	for index, option in ipairs(options or {}) do list[index] = {id = index, label = option.label, close = false} end

	ply.DubzJobsTalk = {npc = npc, custom = true, name = name, options = options or {}}

	net.Start("DubzJobs_Talk")
		net.WriteEntity(npc)
		net.WriteString(util.TableToJSON({name = name, text = text, options = list}))
	net.Send(ply)
end

local function endTalk(ply, npc)
	ply.DubzJobsTalk = nil

	net.Start("DubzJobs_Talk")
		net.WriteEntity(npc)
		net.WriteString(util.TableToJSON({close = true}))
	net.Send(ply)
end

function DubzJobs.Talk(ply, npc)
	if not DubzJobs.Enabled() then return end

	local site = DubzJobs.Sites[npc:GetSite()]
	if not site then say(ply, "Nobody here has work for you.", 1) return end

	-- A site with its own conversation (another addon's job) answers here: return true from the hook and nothing below runs
	if hook.Run("DubzJobsTalk", ply, npc, site) then return end

	show(ply, npc, site, "start")
end

net.Receive("DubzJobs_Choose", function(_, ply)
	local npc, id = net.ReadEntity(), net.ReadUInt(8)
	local talk = ply.DubzJobsTalk

	if not talk or talk.npc ~= npc or not IsValid(npc) then return end
	if ply:GetPos():Distance(npc:GetPos()) > cfg.talkDistance * 1.5 then ply.DubzJobsTalk = nil return end

	if (ply.DubzJobsNext or 0) > CurTime() then return end
	ply.DubzJobsNext = CurTime() + 0.4

	-- Someone else's conversation (DubzJobs.Say)
	if talk.custom then
		local picked = talk.options[id]
		if not picked then return end

		local result = picked.run and picked.run(ply)

		if istable(result) and result.text then
			DubzJobs.Say(ply, npc, result.name or talk.name, result.text, result.options)
		else
			endTalk(ply, npc)
		end

		return
	end

	local option = talk.options[id]
	if not option then return end

	if option.close then
		-- (a closing option can still do something, like opening the foreman's sale window)
		if isfunction(option.action) then option.action(ply, talk.site) end
		ply.DubzJobsTalk = nil
		return
	end

	local nextNode, reason = option.node, nil

	if isfunction(option.action) then
		nextNode, reason = option.action(ply, talk.site)
	elseif option.action and actions[option.action] then
		nextNode, reason = actions[option.action](ply, talk.site)
	end

	show(ply, npc, talk.site, nextNode or "start", reason)
end)
