-- Dubz Scramble: every so often a scrambled word appears in chat; the first player to type the real word wins cash.
-- Longer words pay more. If nobody gets it before the time limit, the round is cancelled and the word is revealed.
--   dubz_scramble_start    (admin console) start a round now
--   dubz_scramble_cancel   (admin console) cancel the current round
local cfg = DubzScramble.Config

local round   -- {word, scrambled, reward, ends} while a round is running

local PREFIX_COLOR = Color(255, 200, 60)

local function say(text)
	for _, ply in ipairs(player.GetAll()) do
		if DarkRP and DarkRP.talkToPerson then
			DarkRP.talkToPerson(ply, PREFIX_COLOR, cfg.chatPrefix .. " ", color_white, text)
		else
			ply:ChatPrint(cfg.chatPrefix .. " " .. text)
		end
	end
end

local function money(amount)
	return (DarkRP and DarkRP.formatMoney) and DarkRP.formatMoney(amount) or ("$" .. amount)
end

local function scramble(word)
	local letters = {}
	for i = 1, #word do letters[i] = string.sub(word, i, i) end

	-- Shuffle until it differs from the word (a short word with repeated letters may not be able to; give up then)
	for _ = 1, 20 do
		for i = #letters, 2, -1 do
			local j = math.random(1, i)
			letters[i], letters[j] = letters[j], letters[i]
		end

		if table.concat(letters) ~= word then break end
	end

	return string.upper(table.concat(letters, " "))
end

local function rewardFor(word, bonus)
	local amount = cfg.rewardBase + cfg.rewardPerLetter * #word
	amount = amount * (1 + (bonus or 0) / 100)
	return math.floor(math.min(amount, cfg.rewardCap))
end

local function pickWord()
	local pool = {}

	for _, row in ipairs(DubzScramble.Words) do
		local word = string.lower(string.Trim(row.word))
		if #word >= cfg.minWordLength and #word <= cfg.maxWordLength and not string.find(word, "%s") then
			pool[#pool + 1] = {word = word, bonus = row.bonus}
		end
	end

	return table.Random(pool)
end

local function nextDelay()
	local jitter = math.random(-cfg.jitterMinutes * 60, cfg.jitterMinutes * 60)
	return math.max(60, cfg.intervalMinutes * 60 + jitter)
end

local schedule

local function endRound(winner)
	timer.Remove("DubzScramble_Timeout")
	timer.Remove("DubzScramble_Hint")

	local finished = round
	round = nil

	if not winner and finished then
		say("Time's up! Nobody unscrambled it. The word was " .. string.upper(finished.word) .. ".")
	end

	schedule(nextDelay())
end

local function startRound(force)
	if round then return false, "A round is already running." end
	if not force and not DubzScramble.Enabled() then
		schedule(nextDelay())   -- switched off: keep the clock ticking so turning it back on just works
		return false, "disabled"
	end

	if not force and #player.GetAll() < cfg.minPlayers then
		schedule(120)   -- not enough people online: look again in two minutes
		return false, "not enough players"
	end

	local pick = pickWord()
	if not pick then
		schedule(nextDelay())
		return false, "the word list is empty (check the min / max word length too)"
	end

	round = {word = pick.word, scrambled = scramble(pick.word), reward = rewardFor(pick.word, pick.bonus), ends = CurTime() + cfg.timeLimit}

	say("Unscramble this word for " .. money(round.reward) .. ":  " .. round.scrambled .. "   (" .. #round.word .. " letters, " .. cfg.timeLimit .. " seconds, just type it in chat)")

	if cfg.hint and cfg.timeLimit >= 10 then
		timer.Create("DubzScramble_Hint", cfg.timeLimit / 2, 1, function()
			if round then say("Hint: it starts with \"" .. string.upper(string.sub(round.word, 1, 1)) .. "\".") end
		end)
	end

	timer.Create("DubzScramble_Timeout", cfg.timeLimit, 1, function() endRound(false) end)
	return true
end

function schedule(seconds)
	timer.Remove("DubzScramble_Next")
	timer.Create("DubzScramble_Next", seconds, 1, function() startRound(false) end)
end

-- Answers: the first correct message wins and is hidden from chat so nobody can copy it
hook.Add("PlayerSay", "DubzScramble_Answer", function(ply, text)
	if not round or not DubzScramble.Enabled() then return end
	if string.lower(string.Trim(text)) ~= round.word then return end

	local reward, word = round.reward, round.word

	if ply.addMoney then ply:addMoney(reward) end
	say(ply:Nick() .. " unscrambled \"" .. string.upper(word) .. "\" and won " .. money(reward) .. "!")
	endRound(true)

	return ""
end)

-- Turning the module off ends a running round quietly; turning it on starts the schedule again
hook.Add("DFW_ModuleStateChanged", "DubzScramble_Toggle", function(id)
	if id ~= "scramble" then return end

	if not DubzScramble.Enabled() then
		if round then say("Word scramble has been switched off.") end
		timer.Remove("DubzScramble_Timeout")
		timer.Remove("DubzScramble_Hint")
		round = nil
	end

	schedule(nextDelay())
end)

-- The interval was changed in the admin menu: restart the countdown (a running round keeps going)
function DubzScramble.Reschedule()
	if not round then schedule(nextDelay()) end
end

local function adminOnly(ply)
	return not IsValid(ply) or ply:IsAdmin()
end

concommand.Add("dubz_scramble_start", function(ply)
	if not adminOnly(ply) then return end

	local ok, reason = startRound(true)
	if not ok and IsValid(ply) then ply:ChatPrint("[Scramble] Couldn't start: " .. tostring(reason)) end
end)

concommand.Add("dubz_scramble_cancel", function(ply)
	if not adminOnly(ply) or not round then return end

	say("The round was cancelled.")
	round = nil
	endRound(true)
end)

-- First round: a normal interval after the server starts
hook.Add("InitPostEntity", "DubzScramble_Start", function()
	schedule(nextDelay())
end)
