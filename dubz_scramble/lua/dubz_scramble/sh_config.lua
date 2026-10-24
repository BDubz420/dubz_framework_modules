DubzScramble.Config = {
	-- How often a round starts: about every intervalMinutes, give or take up to jitterMinutes so it isn't a clock
	intervalMinutes = 30,
	jitterMinutes = 5,

	-- How long players have to unscramble the word before the round is cancelled
	timeLimit = 60,           -- seconds
	hint = true,              -- at half time, reveal the word's first letter

	-- Rounds only start with at least this many players online
	minPlayers = 3,

	-- Reward = rewardBase + rewardPerLetter x word length, times the word's own bonus (%), capped at rewardCap.
	-- Longer words pay more.
	rewardBase = 100,
	rewardPerLetter = 50,
	rewardCap = 5000,

	-- Which words can be picked (by length)
	minWordLength = 4,
	maxWordLength = 14,

	chatPrefix = "[Scramble]",
}

-- The word list (the "Words" table in the admin menu starts from these). `bonus` is extra reward in percent.
DubzScramble.DefaultWords = {
	-- short
	"gold", "rain", "fence", "alley", "brick", "smoke", "metal", "trash", "cargo", "radio",
	-- medium
	"citizen", "warehouse", "scrap", "barricade", "dumpster", "bandage", "flashlight", "sidewalk", "neon", "payday",
	"market", "robbery", "hideout", "rooftop", "tunnel", "generator", "antenna", "signal", "curfew", "bunker",
	"lockpick", "backpack", "sneakers", "cigarette", "firewood", "apartment", "pawnshop", "locksmith", "mechanic", "scavenger",
	-- long
	"checkpoint", "blackout", "contraband", "resistance", "wastelands", "cardboard", "streetlight", "overpass", "surveillance", "headquarters",
	"neighborhood", "undercover", "ambulance", "construction", "electricity", "refrigerator", "smuggler", "informant", "demolition", "transmission",
}

-- What the round logic reads. Starts as the defaults; the framework replaces it when the table is edited.
DubzScramble.Words = {}
for _, word in ipairs(DubzScramble.DefaultWords) do DubzScramble.Words[#DubzScramble.Words + 1] = {word = word, bonus = 0} end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzScramble.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("scramble")
end
