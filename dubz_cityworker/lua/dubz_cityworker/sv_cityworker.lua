-- The City Worker, server side: handing out jobs, following a worker through the steps of a job, paying them.
--
-- A TASK (see sv_tasks.lua for the vending machine one, the first) is a table: an id, a name and summary, Find (picks a broken-able thing in the world for
-- a worker), Begin / Think / Finish / Cleanup, and a list of STEPS. Each step is one of four kinds:
--   use    the worker presses E at a spot
--   hold   the worker holds left click with a tool (tool = "wrench" or "pliers") at a spot, a bar fills
--   carry  a part has to be carried somewhere (the step says when it is done)
--   snap   a part has to be put in its place (it clicks in when it is close enough)
-- A step says where it happens with zones() (spots and parts that glow for the worker). The engine does the rest: the screen, the bar, paying.
util.AddNetworkString("DubzCW_State")   -- server -> client: the worker's job and current step (or nothing)

local cfg = DubzCW.Config

DubzCW.Tasks = DubzCW.Tasks or {}
DubzCW.Active = DubzCW.Active or {}   -- steamid64 -> the task the worker is on

function DubzCW.RegisterTask(def)
	DubzCW.Tasks[def.id] = def
end

local function money(amount)
	return DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(amount) or ("$" .. amount)
end

local function say(ply, text, kind)
	if not IsValid(ply) then return end

	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind or 0, 6, text) else ply:ChatPrint(text) end
end

DubzCW.Say = say

-- Where a step happens ----------------------------------------------------------------------------------------------------------------------------

-- The spots and parts of the current step: a list of {pos, radius, ent}
local function zonesOf(task, step)
	local list = step.zones and step.zones(task) or {}

	for _, zone in ipairs(list) do
		if not zone.pos and IsValid(zone.ent) then zone.pos = zone.ent:WorldSpaceCenter() end
		zone.radius = zone.radius or 20
	end

	return list
end

-- Is the player looking at this spot, close enough to use it?
local function aimsAt(ply, pos, radius)
	local eye = ply:EyePos()
	local toSpot = pos - eye

	if toSpot:Length() > cfg.InteractDistance + radius then return false end

	local dir = ply:GetAimVector()
	local along = toSpot:Dot(dir)
	if along <= 0 then return false end

	return (toSpot - dir * along):Length() <= radius
end

local function aimsAtZones(ply, zones)
	for _, zone in ipairs(zones) do
		if zone.pos and aimsAt(ply, zone.pos, zone.radius) then return true end
	end

	return false
end

-- Telling the worker's screen ----------------------------------------------------------------------------------------------------------------------

-- What the worker's screen does for a kind of step: 1 = the bar, 2 = the ring (turning), 3 = nothing but the count
local MODES = {hold = 1, bolts = 1, turn = 2, scoop = 3}

local function sendState(task, intro)
	local ply = task.worker
	if not IsValid(ply) then return end

	local steps = task.def.steps
	local step = steps[task.step]
	local zones = step and zonesOf(task, step) or {}

	-- (the bolts left are in the text)
	local text = step and step.text or "All done."

	if step and step.kind == "bolts" then
		local left = 0

		for index = 1, #step.bolts(task) do
			if not task.boltDone[index] then left = left + 1 end
		end

		text = text .. " (" .. left .. " left)"
	end

	if step and step.kind == "scoop" then
		text = text .. " (" .. math.max(step.count(task) - (task.scoops or 0), 0) .. " left)"
	end

	-- (the wrench of a turn step sits on the thing itself: the worker's own tool is put away for it)
	ply:SetNWInt("dcw_mode", step and MODES[step.kind] or 0)
	ply:SetNWBool("dcw_hide", step ~= nil and step.kind == "turn" and task.turn ~= nil and task.turn.started == true)

	net.Start("DubzCW_State")
		net.WriteBool(true)
		net.WriteVector(IsValid(task.target) and task.target:GetPos() or vector_origin)   -- (the spot itself: the machine may not be known to the client yet, far away)
		net.WriteString(task.def.name)
		net.WriteString(task.def.summary or "")
		net.WriteUInt(math.min(task.step, #steps + 1), 6)
		net.WriteUInt(#steps, 6)
		net.WriteString(text)
		net.WriteString(step and step.hint or "")
		net.WriteString(step and step.prompt or "")
		net.WriteBool(intro == true)

		net.WriteUInt(math.min(#zones, 4), 3)
		for index = 1, math.min(#zones, 4) do
			net.WriteVector(zones[index].pos or vector_origin)
			net.WriteEntity(zones[index].ent or NULL)
			net.WriteFloat(zones[index].radius)
		end
	net.Send(ply)
end

local function clearState(ply)
	if not IsValid(ply) then return end

	ply:SetNWFloat("dcw_hold", 0)
	ply:SetNWInt("dcw_mode", 0)
	ply:SetNWBool("dcw_hide", false)
	ply:SetNWBool("dcw_turning", false)
	ply.DubzCWTurning = false

	net.Start("DubzCW_State")
		net.WriteBool(false)
	net.Send(ply)
end

-- The flow of a task ----------------------------------------------------------------------------------------------------------------------------------

local function release(task)
	DubzCW.Active[task.worker:SteamID64()] = nil

	if IsValid(task.target) then task.target.DubzCWTask = nil end
end

local function advance(task)
	local step = task.def.steps[task.step]

	task.hold, task.sentHold = 0, 0
	task.worker:SetNWFloat("dcw_hold", 0)

	if step and step.onDone then step.onDone(task) end

	task.step = task.step + 1
	task.boltDone, task.holdIdx = {}, nil
	task.turn, task.scoops = {acc = 0, px = 0, py = 0}, 0
	sendState(task)
end

local function complete(task)
	local ply, def = task.worker, task.def

	release(task)
	clearState(ply)   -- (first: the card and the marker go the moment the job is over)
	if def.Finish then pcall(def.Finish, task) end

	local row = DubzCW.TaskRows[def.id]

	-- (a practised worker is paid more: the Maintenance skill; and learns from every job)
	local pay = math.floor((row and tonumber(row.payout) or 0) * DubzCW.PayFactor(ply) + 0.5)

	if DubzSkills and DubzSkills.AddXP and cfg.SkillXPPerJob > 0 then DubzSkills.AddXP(ply, "maintenance", cfg.SkillXPPerJob) end

	if pay > 0 and ply.addMoney then ply:addMoney(pay) end

	-- (the pay is cash only: the scrap came out of the machine when the old board was cut out)
	say(ply, "Job done: " .. def.name .. ". You earned " .. money(pay) .. ".")
	ply:EmitSound("plats/elevbell1.wav", 55, 120)
	ply.DubzCWNext = CurTime() + cfg.AssignSeconds

	hook.Run("DubzCWJobDone", ply, def.id, pay)
end

local function cancel(task, reason)
	local ply = task.worker

	release(task)
	clearState(ply)
	if task.def.Cleanup then pcall(task.def.Cleanup, task, reason) end

	if IsValid(ply) then
		say(ply, reason or "The job was called off.", 1)
		ply.DubzCWNext = CurTime() + cfg.AssignSeconds
	end
end

DubzCW.Cancel = cancel

local function startTask(ply, def, target)
	local task = {def = def, worker = ply, target = target, step = 1, data = {}, started = CurTime(), hold = 0, boltDone = {}, turn = {acc = 0, px = 0, py = 0}, scoops = 0}

	DubzCW.Active[ply:SteamID64()] = task
	target.DubzCWTask = task

	local ok, err = pcall(def.Begin, task)

	if not ok then
		ErrorNoHalt("[DubzCityWorker] " .. def.id .. " could not start: " .. tostring(err) .. "\n")
		release(task)
		pcall(def.Cleanup, task, "start failed")
		return false
	end

	-- (a worker who took the job before a tool was added gets it now)
	for _, class in ipairs(DubzCW.ToolList()) do
		if not ply:HasWeapon(class) then ply:Give(class) end
	end

	say(ply, "New job: " .. def.name)   -- (the card on the screen says the rest)
	ply:EmitSound("buttons/button17.wav", 55)
	sendState(task, true)

	return true
end

-- Following a worker through a step ---------------------------------------------------------------------------------------------------------------

local TOOL_SOUNDS = {wrench = "physics/metal/metal_solid_impact_soft1.wav", pliers = "physics/metal/metal_canister_impact_soft1.wav", shovel = "physics/concrete/boulder_impact_hard1.wav", hammer = "physics/wood/wood_plank_impact_hard1.wav"}

local function holdStep(task, step, dt)
	local ply = task.worker
	local zones = zonesOf(task, step)
	local weapon = ply:GetActiveWeapon()
	local tool = IsValid(weapon) and weapon.DubzCWTool or nil

	if ply:KeyDown(IN_ATTACK) and aimsAtZones(ply, zones) then
		if tool ~= step.tool then
			if CurTime() > (task.nextTip or 0) then
				task.nextTip = CurTime() + 4
				say(ply, "That needs the " .. step.tool .. ". Switch to it first.", 1)
			end
		else
			task.hold = task.hold + dt / math.max((step.seconds and step.seconds(task) or 3) * DubzCW.TimeFactor(ply), 0.3)

			if cfg.WorkSound and CurTime() > (task.nextSound or 0) then
				task.nextSound = CurTime() + (step.workEvery or 0.45)

				if step.workSound then
					step.workSound(ply, task)
				else
					ply:EmitSound(TOOL_SOUNDS[step.tool] or TOOL_SOUNDS.wrench, 55, math.random(95, 110))
				end
			end
		end
	else
		task.hold = math.max(task.hold - dt * 1.5, 0)
	end

	if math.abs(task.hold - (task.sentHold or 0)) > 0.02 then
		task.sentHold = task.hold
		ply:SetNWFloat("dcw_hold", math.min(task.hold, 1))
	end

	if task.hold >= 1 then advance(task) end
end

-- The bolts: a step with several spots, each held with the tool in turn (the spot goes out when its bolt is done)
local function boltStep(task, step, dt)
	local ply = task.worker
	local weapon = ply:GetActiveWeapon()
	local tool = IsValid(weapon) and weapon.DubzCWTool or nil
	local bolts = step.bolts(task)
	local aimed

	for index, bolt in ipairs(bolts) do
		if not task.boltDone[index] and aimsAt(ply, bolt.pos, bolt.radius) then aimed = index break end
	end

	if ply:KeyDown(IN_ATTACK) and aimed then
		if tool ~= step.tool then
			if CurTime() > (task.nextTip or 0) then
				task.nextTip = CurTime() + 4
				say(ply, "That needs the " .. step.tool .. ". Switch to it first.", 1)
			end
		else
			if task.holdIdx ~= aimed then task.holdIdx, task.hold = aimed, 0 end

			task.hold = task.hold + dt / math.max((step.seconds and step.seconds(task) or 1) * DubzCW.TimeFactor(ply), 0.2)

			-- A ratchet while it turns (or the step's own sound: a hammer)
			if cfg.WorkSound and CurTime() > (task.nextSound or 0) then
				task.nextSound = CurTime() + (step.workEvery or 0.16)

				if step.workSound then
					step.workSound(ply, task)
				else
					ply:EmitSound("physics/metal/metal_solid_impact_soft" .. math.random(1, 3) .. ".wav", 52, math.random(125, 150))
				end
			end

			if task.hold >= 1 then
				task.boltDone[aimed] = true
				task.hold, task.holdIdx = 0, nil

				if step.onBolt then step.onBolt(task, aimed, bolts[aimed].pos) end

				local all = true

				for index = 1, #bolts do
					if not task.boltDone[index] then all = false break end
				end

				if all then advance(task) else sendState(task) end
			end
		end
	else
		task.hold = math.max(task.hold - dt * 2, 0)
	end

	if math.abs(task.hold - (task.sentHold or 0)) > 0.02 then
		task.sentHold = task.hold
		ply:SetNWFloat("dcw_hold", math.min(task.hold, 1))
	end
end

-- A tool clicked once (the pliers snipping a wire): called by the tool's primary attack
function DubzCW.ToolClick(ply, tool)
	local task = IsValid(ply) and DubzCW.Active[ply:SteamID64()]
	if not task or task.step > #task.def.steps then return end

	local step = task.def.steps[task.step]

	-- A scoop of the shovel: every click counts, until there are enough
	if step.kind == "scoop" then
		if (step.wait and step.wait(task)) or not aimsAtZones(ply, zonesOf(task, step)) then return end

		if tool ~= step.tool then
			say(ply, "That needs the " .. step.tool .. ".", 1)
			return
		end

		task.scoops = (task.scoops or 0) + 1

		local total = step.count(task)

		if step.onScoop then step.onScoop(task, task.scoops, total) end

		if task.scoops >= total then advance(task) else sendState(task) end

		return
	end

	if step.kind ~= "click" or (step.wait and step.wait(task)) then return end

	if not aimsAtZones(ply, zonesOf(task, step)) then return end

	if tool ~= step.tool then
		say(ply, "That needs the " .. step.tool .. ".", 1)
		return
	end

	advance(task)
end

-- The turn steps (the wrench on the hydrant): hold left click and move the mouse in circles. The mouse moves are read here, from the player's commands;
-- the turn is how far the mouse has gone round (a little point that follows the mouse: the angle it makes counts, clockwise only)
hook.Add("StartCommand", "DubzCW_Turn", function(ply, cmd)
	local task = DubzCW.Active[ply:SteamID64()]
	local step = task and task.def.steps[task.step]

	if not (step and step.kind == "turn") or (step.wait and step.wait(task)) then
		if ply.DubzCWTurning then
			ply.DubzCWTurning = false
			ply:SetNWBool("dcw_turning", false)
		end

		return
	end

	local weapon = ply:GetActiveWeapon()
	local tool = IsValid(weapon) and weapon.DubzCWTool or nil
	local turn = task.turn
	local pressed = cmd:KeyDown(IN_ATTACK)
	local on = pressed and tool == step.tool and (ply.DubzCWTurning or aimsAtZones(ply, zonesOf(task, step)))

	if pressed and tool ~= step.tool and CurTime() > (task.nextTip or 0) and aimsAtZones(ply, zonesOf(task, step)) then
		task.nextTip = CurTime() + 4
		say(ply, "That needs the " .. step.tool .. ". Switch to it first.", 1)
	end

	if on ~= (ply.DubzCWTurning == true) then
		ply.DubzCWTurning = on
		ply:SetNWBool("dcw_turning", on)
		turn.px, turn.py, turn.last = 0, 0, nil
	end

	if not on then return end

	-- The first press with the tool on the spot: the wrench goes onto it (and the worker's own is put away)
	if not turn.started then
		turn.started = true
		ply:SetNWBool("dcw_hide", true)

		if step.onStart then step.onStart(task) end
	end

	turn.px, turn.py = turn.px + cmd:GetMouseX(), turn.py + cmd:GetMouseY()

	local length = math.sqrt(turn.px * turn.px + turn.py * turn.py)

	if length > 60 then
		turn.px, turn.py = turn.px * 60 / length, turn.py * 60 / length
		length = 60
	end

	local before = math.floor(turn.acc / (math.pi / 4))

	if length > 20 then
		local angle = math.atan2(turn.py, turn.px)

		if turn.last then
			local change = angle - turn.last

			if change > math.pi then change = change - math.pi * 2 elseif change < -math.pi then change = change + math.pi * 2 end

			turn.acc = math.max(turn.acc + change, 0)
		end

		turn.last = angle
	else
		turn.last = nil
	end

	-- A click of the ratchet every eighth of a turn
	if cfg.WorkSound and math.floor(turn.acc / (math.pi / 4)) ~= before and step.workSound then step.workSound(ply, task) end

	local progress = math.min(turn.acc / (math.max(step.turns(task) * DubzCW.TimeFactor(ply), 0.25) * math.pi * 2), 1)

	if math.abs(progress - (task.sentHold or 0)) > 0.01 then
		task.sentHold = progress
		ply:SetNWFloat("dcw_hold", progress)
	end

	if progress >= 1 then
		ply.DubzCWTurning = false
		ply:SetNWBool("dcw_turning", false)
		advance(task)
	end
end)

local function snapStep(task, step)
	local pos, ang = step.socket(task)

	for _, ent in ipairs(ents.FindInSphere(pos, cfg.SnapDistance * 2)) do
		if ent:GetPhysicsObject():IsValid() and step.filter(task, ent) and not ent:IsPlayerHolding() and ent:WorldSpaceCenter():Distance(pos) <= cfg.SnapDistance then
			if step.onSnap then step.onSnap(task, ent, pos, ang) end

			advance(task)
			return
		end
	end
end

local function tickTask(task, dt)
	local def = task.def

	if def.Think then def.Think(task, dt) end

	-- Past the last step: wait for the work to finish moving (a machine being pushed back), then pay
	if task.step > #def.steps then
		if not (def.Busy and def.Busy(task)) then complete(task) end
		return
	end

	local step = def.steps[task.step]

	if step.wait and step.wait(task) then return end

	if step.kind == "hold" then
		holdStep(task, step, dt)
	elseif step.kind == "bolts" then
		boltStep(task, step, dt)
	elseif step.kind == "carry" then
		local ent = step.ent(task)

		if not IsValid(ent) then cancel(task, "A part was lost. The job is called off.") return end
		if step.done(task) then advance(task) end
	elseif step.kind == "snap" then
		snapStep(task, step)
	end
end

-- E at a spot (the "use" steps)
hook.Add("KeyPress", "DubzCW_Use", function(ply, key)
	if key ~= IN_USE then return end

	local task = DubzCW.Active[ply:SteamID64()]
	if not task or task.step > #task.def.steps then return end

	local step = task.def.steps[task.step]
	if step.kind ~= "use" or (step.wait and step.wait(task)) then return end

	if aimsAtZones(ply, zonesOf(task, step)) then advance(task) end
end)

-- Handing out jobs -------------------------------------------------------------------------------------------------------------------------------

local function pickAndStart(ply)
	local pool, total = {}, 0

	for id, def in pairs(DubzCW.Tasks) do
		local row = DubzCW.TaskRows[id]

		if row and row.enabled then
			local weight = math.max(tonumber(row.weight) or 1, 1)

			pool[#pool + 1] = {def = def, weight = weight}
			total = total + weight
		end
	end

	-- A weighted pick; one with nothing to work on is skipped and the next is tried
	while #pool > 0 do
		local roll, chosen = math.random() * total, 1

		for index, entry in ipairs(pool) do
			roll = roll - entry.weight
			if roll <= 0 then chosen = index break end
		end

		local entry = table.remove(pool, chosen)
		total = total - entry.weight

		-- (an error in one task's search must not stop the others, or every worker's jobs)
		local ok, target = pcall(entry.def.Find, ply)

		if not ok then
			ErrorNoHalt("[DubzCityWorker] " .. entry.def.id .. " Find failed: " .. tostring(target) .. string.char(10))
		elseif IsValid(target) and startTask(ply, entry.def, target) then
			return true
		end
	end

	return false
end

timer.Create("DubzCW_Tick", 0.1, 0, function()
	if not DubzCW.Enabled() then return end

	local now = CurTime()

	for _, task in pairs(DubzCW.Active) do
		local ply = task.worker

		if not (IsValid(ply) and ply:Alive() and DubzCW.IsWorker(ply)) then
			cancel(task, "You are not on the job any more.")
		elseif ply.isArrested and ply:isArrested() then
			cancel(task, "You were arrested. The job is called off.")
		elseif not IsValid(task.target) then
			cancel(task, "The machine is gone. The job is called off.")
		elseif now - task.started > cfg.TaskMinutes * 60 then
			cancel(task, "You took too long. The job was given to somebody else.")
		else
			tickTask(task, 0.1)

			-- The glowing spots follow the machine (and the settings, while they are being dialled in); never for a job that has just ended
			if DubzCW.Active[ply:SteamID64()] == task and CurTime() > (task.nextSend or 0) then
				task.nextSend = CurTime() + 1
				sendState(task)
			end
		end
	end
end)

-- Moving parts (a machine swinging out) are updated every tick, not ten times a second, so they are smooth
hook.Add("Think", "DubzCW_Animate", function()
	for _, task in pairs(DubzCW.Active) do
		if task.def.Animate and IsValid(task.target) and not task.animFailed then
			local ok, err = pcall(task.def.Animate, task)

			if not ok then
				task.animFailed = true
				ErrorNoHalt("[DubzCityWorker] " .. task.def.id .. " Animate failed: " .. tostring(err) .. string.char(10))
			end
		end
	end
end)

timer.Create("DubzCW_Assign", 2, 0, function()
	if not DubzCW.Enabled() then return end

	for _, ply in ipairs(player.GetAll()) do
		if DubzCW.IsWorker(ply) and ply:Alive() and not (ply.isArrested and ply:isArrested()) and not DubzCW.Active[ply:SteamID64()] then
			ply.DubzCWNext = ply.DubzCWNext or (CurTime() + 5)

			if CurTime() >= ply.DubzCWNext then
				-- Nothing to work on right now: look again in a while (and say so once in a while, so the worker knows it is not broken)
				if not pickAndStart(ply) then
					ply.DubzCWNext = CurTime() + 20

					if CurTime() > (ply.DubzCWTold or 0) then
						ply.DubzCWTold = CurTime() + 90
						say(ply, "No jobs right now. You will be called when something breaks.", 0)
					end
				end
			end
		end
	end
end)

-- A player who takes the job starts the clock; one who leaves it is taken off the job (the tick checks)
hook.Add("OnPlayerChangedTeam", "DubzCW_Team", function(ply)
	ply.DubzCWNext = CurTime() + 5
end)

-- For staff: start a job on yourself right now (the same as being handed one), to try the system
-- !cwtest  or  dubz_cw_test
local function testJob(ply)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	if not IsValid(ply) then return end

	if DubzCW.Active[ply:SteamID64()] then say(ply, "You already have a job. Say !cwcancel to give it up.", 1) return end

	if pickAndStart(ply) then return end

	say(ply, "No job could be started: there is no vending machine in the world to fix. Spawn a Vending Machine (entities tab: Dubz Vending Machine) and freeze or perma-prop it.", 1)
end

concommand.Add("dubz_cw_test", testJob)

-- For dialling in the spots: prints the machine-space numbers of the job you are on (the dial settings are moves from these)
local function printValues(ply)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end

	local task = IsValid(ply) and DubzCW.Active[ply:SteamID64()]

	if not task or not task.def.Describe then
		say(ply, "You have no job to print. Say !cwtest to start one.", 1)
		return
	end

	for _, text in ipairs(task.def.Describe(task)) do ply:PrintMessage(HUD_PRINTCONSOLE, text) end

	say(ply, "The numbers are in your console.")
end

concommand.Add("dubz_cw_values", printValues)

concommand.Add("dubz_cw_cancel", function(ply)
	local task = IsValid(ply) and DubzCW.Active[ply:SteamID64()]
	if task then cancel(task, "You gave up the job.") end
end)

hook.Add("PlayerSay", "DubzCW_Commands", function(ply, text)
	if string.lower(string.Trim(text)) == "!cwvalues" then
		printValues(ply)
		return ""
	end

	if string.lower(string.Trim(text)) == "!cwtest" then
		testJob(ply)
		return ""
	end

	if string.lower(string.Trim(text)) == "!cwcancel" then
		local task = DubzCW.Active[ply:SteamID64()]

		if task then cancel(task, "You gave up the job.") else say(ply, "You have no job to give up.", 1) end
		return ""
	end
end)

-- Parts ----------------------------------------------------------------------------------------------------------------------------------------------

-- Light things a player can pick up with E (the plate, the circuit boards)
hook.Add("AllowPlayerPickup", "DubzCW_Pickup", function(ply, ent)
	if ent.DubzCWCarry or ent:GetClass() == "dubz_circuit_board" then return true end
end)

-- A part that is part of a machine is not for the pocket
hook.Add("DubzInvCanPocket", "DubzCW_NoPocketParts", function(ply, ent)
	if IsValid(ent) and (ent.DubzCWLocked or ent:GetClass() == "dubz_cw_plate") then return false, "That is part of a machine." end
end)

-- The foreman's lines (the Jobs addon's NPC; its Job Sites table has the row)
DubzJobs = DubzJobs or {}
DubzJobs.Lines = DubzJobs.Lines or {}
DubzJobs.Lines.cityworker = {
	welcome = "Looking for work? The city falls apart a little every day. Somebody has to put it back together.",
	about = "You get sent to whatever is broken: a vending machine, to start. Pull it out, get the back off, swap the board and put it all together again. You get a wrench and pliers, and the replacement parts come from the F4 menu. Pay is per job.",
	hired = "Good. Wrench and pliers are yours. I'll send you to the first job in a minute. Look for the marker, and for the glow on what needs doing.",
	back = "Back already? Something out there is still broken.",
	quit = "Hanging up the wrench? Fair enough. Keep the tools.",
	quitDone = "Thanks for the help. The city won't fix itself.",
	bought = "A new wrench. Try not to lose this one.",
}
