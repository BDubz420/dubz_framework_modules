-- Registers Word Scramble with the Dubz Framework: timing, rewards and the word list in the admin config menu
-- (!dubzconfig). The values in sh_config.lua stay the defaults.
local defaultWords = {}
for _, word in ipairs(DubzScramble.DefaultWords) do defaultWords[#defaultWords + 1] = {word = word, bonus = 0} end

DFW.Bind.Module({
	id = "scramble",
	name = "Word Scramble",
	version = "1.0.0",
	icon = "communication/chat_bubble",
	description = "A scrambled word appears in chat every so often; the first to type the real word wins cash.",
	dependencies = {"dubz_core"},
}, DubzScramble.Config, {
	{path = "intervalMinutes", label = "Round Every (Minutes)", min = 5, max = 240, decimals = 0, group = "Timing",
		description = "About how often a round starts."},
	{path = "jitterMinutes", label = "Random Variation (Minutes)", min = 0, max = 60, decimals = 0, group = "Timing",
		description = "Each gap is the interval plus or minus up to this much, so it isn't predictable."},
	{path = "timeLimit", label = "Time To Answer (Seconds)", min = 10, max = 600, decimals = 0, group = "Timing",
		description = "After this the round is cancelled and the word is revealed."},
	{path = "hint", label = "First-Letter Hint", group = "Timing", description = "At half time, reveal the first letter."},
	{path = "minPlayers", label = "Minimum Players Online", min = 1, max = 64, decimals = 0, group = "Timing"},

	{path = "rewardBase", label = "Base Reward", min = 0, max = 100000, decimals = 0, group = "Rewards"},
	{path = "rewardPerLetter", label = "Reward Per Letter", min = 0, max = 100000, decimals = 0, group = "Rewards",
		description = "Total = base + this x the word's length (then the word's own bonus). Longer words pay more."},
	{path = "rewardCap", label = "Maximum Reward", min = 0, max = 1000000, decimals = 0, group = "Rewards"},

	{path = "minWordLength", label = "Shortest Word", min = 3, max = 20, decimals = 0, group = "Words"},
	{path = "maxWordLength", label = "Longest Word", min = 3, max = 30, decimals = 0, group = "Words"},
	{path = "chatPrefix", label = "Chat Prefix", group = "Words", maxLength = 30},
}, {
	collections = {
		{
			id = "words", label = "Words",
			description = "The words players unscramble (one word, no spaces) and each one's extra reward in percent.",
			columns = {
				{key = "word", label = "Word", type = "string", width = 2, maxLength = 30},
				{key = "bonus", label = "Bonus %", type = "number", min = 0, max = 1000, decimals = 0, width = 1},
			},
			default = defaultWords,
		},
	},
	OnChange = function(path)
		-- A new interval takes effect right away (a round in progress is left alone)
		if SERVER and (path == "intervalMinutes" or path == "jitterMinutes") and DubzScramble.Reschedule then
			DubzScramble.Reschedule()
		end
	end,
})

DFW.Collections.Watch("scramble", "words", function(rows)
	DubzScramble.Words = rows
end)
