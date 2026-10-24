-- Characters settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Characters) edits them live.
DubzChars = DubzChars or {}

DubzChars.Config = {
	-- Start screen text
	serverName = "Liminal",
	serverTag = "RP",
	subtitle = "Sector 18",
	footer = "Having trouble loading? Join our Discord for support.",

	-- Buttons
	discordUrl = "https://discord.low",

	-- Slots: how many characters one account can have
	slotsNormal = 2,
	slotsPremium = 5,

	-- Names: first and last name are each letters only, this long
	nameMin = 2,
	nameMax = 14,
	uniqueNames = true,      -- no two living characters can share a full name

	-- What deleting a character does: "wipe" erases it and everything saved for it (pocket, skills, karma, bank, clothes
	-- ...) for good; "archive" only hides it (staff can bring it back with dubz_chars_restore).
	deleteMode = "wipe",

	-- Changing character in game (!characters): saves the one you are, then loads the one you pick
	switchEnabled = true,
	switchCommand = "!characters",
	switchCooldown = 120,        -- seconds before you can switch again

	-- Optional music while the menu is open (a direct web link to an audio file); empty = none
	musicUrl = "",
	musicVolume = 0.35,

	-- How much the world behind the menu is blurred (0 = not at all)
	blur = 4,

	-- The welcome screen shown the first time a character spawns in (and with the chat command)
	welcomeEnabled = true,
	logo = "liminal/logo.png",      -- the picture at the top of the character screen (from the content pack; empty = the written name)
	logoHeight = 130,
	welcomeEveryTime = true,      -- show it every time a character is picked (off = only the first time for each character)
	welcomeTitle = "Welcome to Sector 18",
	welcomeCommand = "!welcome",
	welcomeShowControls = true,   -- a Controls page, read live from the F4 How To Play table
	welcomeShowRules = true,      -- a Rules page, read live from the F4 Rules table
}

-- The welcome screen's text: each row is one paragraph, shown on the page named in `page` (pages appear in the order
-- they first show up). Edit freely in the admin menu (Characters > Welcome Text).
DubzChars.DefaultWelcome = {
	{page = "Welcome", text = "Sector 18 is a gloomy, low-level industrial city, and a place to spend time with people. Every script on this server was built by hand, to fit this one place."},
	{page = "Welcome", text = "Some of you came back for the nostalgia of the map. What keeps people here is the atmosphere and what you make of it: friends, music, long conversations on a cold street."},
	{page = "Welcome", text = "Or build something bigger. A crew that grows into an organisation, cooking product by the kilo and fighting a war with the others. It is all RP."},
	{page = "Welcome", text = "We play semi-serious: serious enough for the story to matter, loose enough to laugh. Welcome to the city."},
	{page = "How we play", text = "Stay in character. You are your character, not your Steam name, and what your character knows is what they have seen."},
	{page = "How we play", text = "Make something happen. Start a business, throw a party, cause trouble. A scene needs two people, so bring someone into yours."},
	{page = "How we play", text = "Talk before you shoot. A mugging, a deal gone wrong or a stand-off is better story than a kill. Karma remembers the difference."},
	{page = "How we play", text = "Be good to new people. Everyone here was new once. If someone is lost, point them at F4."},
}

DubzChars.Welcome = table.Copy(DubzChars.DefaultWelcome)

-- Outfits a new character can start in (clothing set ids from the Cosmetics addon; the first is the default)
DubzChars.DefaultStarterOutfits = {
	{outfit = "citizen"},
	{outfit = "rebel"},
}

-- Names that can't be used (staff impersonation and the like). Add your own list in the admin menu.
DubzChars.DefaultBlocked = {
	{word = "admin"}, {word = "moderator"}, {word = "owner"}, {word = "staff"}, {word = "server"},
}

-- The pool the "Random name" button draws from
DubzChars.RandomFirstMale = {
	"James", "Marcus", "Daniel", "Victor", "Leon", "Tobias", "Elias", "Declan", "Rowan", "Silas", "Callum", "Jasper", "Dmitri", "Anton",
	"Mateo", "Oscar", "Felix", "Hugo", "Nolan", "Reuben", "Adrian", "Conrad", "Dominic", "Ezra", "Gideon", "Ivan", "Julian", "Malcolm",
	"Nathan", "Owen", "Pavel", "Rafael", "Soren", "Theo", "Viktor", "Walter",
}

DubzChars.RandomFirstFemale = {
	"Mara", "Elena", "Nadia", "Iris", "Clara", "Freya", "Tessa", "Maya", "Ingrid", "Sasha", "Lena", "Ruth", "Wren", "Talia", "Greta",
	"Odette", "Vera", "June", "Nora", "Alma", "Adele", "Bianca", "Camille", "Dara", "Esme", "Fiona", "Hazel", "Ines", "Jessa", "Katya",
	"Lydia", "Marta", "Naomi", "Petra", "Rosa", "Yara",
}

DubzChars.RandomLast = {
	"Cole", "Hayes", "Mercer", "Voss", "Kovac", "Brandt", "Frost", "Walker", "Reyes", "Novak", "Dunne", "Hale", "Sterling", "Ashford",
	"Morrow", "Calloway", "Petrov", "Ivanov", "Rourke", "Whitlock", "Barrett", "Hollis", "Lockwood", "Marsh", "Sutter", "Vance", "Quinn",
	"Draper", "Kessler", "Lindqvist", "Okafor", "Tanaka", "Moreau", "Navarro", "Bishop", "Garrick", "Thorne", "Ellery", "Stone", "Penn",
}

-- Swears and slurs that can't be in a name (repeated letters are squashed before the check, so "fuuuck" is caught too)
DubzChars.SwearsInside = {
	"fuck", "shit", "bitch", "cunt", "nigg", "nigr", "faggot", "retard", "whore", "slut", "bastard", "asshole", "dickhead", "cocksuck",
	"pussy", "wank", "twat", "rapist", "hitler", "pedo", "molest", "tranny", "jizz",
	"cumshot", "blowjob", "handjob", "motherfuck", "bollock", "penis", "vagina", "boner", "dildo",
}

DubzChars.SwearsWhole = {
	"ass", "arse", "dick", "cock", "cum", "tit", "tits", "fag", "fags", "coon", "paki", "negro", "slag", "piss", "crap", "damn", "hell",
	"nazi", "kike", "spic", "chink", "gook", "dyke", "anus", "porn", "sex", "anal", "rape", "milf", "hoe", "thot", "prick", "nut", "nuts", "balls", "butt", "fart", "poop",
}

-- Groups that get the premium number of slots
DubzChars.DefaultPremium = {
	{group = "vip"}, {group = "vip+"}, {group = "elite"},
}

DubzChars.StarterOutfits = {}
for _, row in ipairs(DubzChars.DefaultStarterOutfits) do DubzChars.StarterOutfits[#DubzChars.StarterOutfits + 1] = row.outfit end

DubzChars.Blocked = {}
for _, row in ipairs(DubzChars.DefaultBlocked) do DubzChars.Blocked[#DubzChars.Blocked + 1] = row.word end

DubzChars.PremiumGroups = {}
for _, row in ipairs(DubzChars.DefaultPremium) do DubzChars.PremiumGroups[string.lower(row.group)] = true end

-- Master kill switch (admin menu > Modules). Off = players spawn straight in as before.
function DubzChars.Enabled()
	if not (DubzCosmetics and DubzCosmetics.Faces) then return false end   -- looks and outfits come from Cosmetics
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("characters")
end

-- First and last name checks, shared so the menu can show the reason live. Returns ok, reason, first, last
-- (the cleaned, capitalised names).
local function clean(text)
	text = string.Trim(tostring(text or ""))
	return string.upper(string.sub(text, 1, 1)) .. string.lower(string.sub(text, 2))
end

function DubzChars.ValidateName(first, last)
	local cfg = DubzChars.Config
	first, last = clean(first), clean(last)

	for _, part in ipairs({{"First name", first}, {"Last name", last}}) do
		local label, value = part[1], part[2]

		if #value < cfg.nameMin then return false, label .. " needs at least " .. cfg.nameMin .. " letters." end
		if #value > cfg.nameMax then return false, label .. " can be at most " .. cfg.nameMax .. " letters." end
		if not string.match(value, "^%a+$") then return false, label .. " can only use letters." end
	end

	-- Checked as typed and with repeated letters squashed ("fuuuck" -> "fuck"), across the first name, the last name and
	-- both joined (a word can be split between the two)
	local function squash(text) return (string.gsub(text, "(.)%1+", "%1")) end

	local joined = string.lower(first .. last)
	local candidates = {string.lower(first), string.lower(last), joined, squash(string.lower(first)), squash(string.lower(last)), squash(joined)}

	-- Built-in swear list, always on (the admin list below adds to it). Long words are blocked anywhere inside a name; short ones only when
	-- they are the whole first or last name, so real names (Cassidy, Hassan, Dickens) still work.
	local firstLow, lastLow = squash(string.lower(first)), squash(string.lower(last))

	for _, word in ipairs(DubzChars.SwearsInside) do
		for _, text in ipairs(candidates) do
			if string.find(text, word, 1, true) then return false, "That name isn't allowed." end
		end
	end

	for _, word in ipairs(DubzChars.SwearsWhole) do
		if firstLow == word or lastLow == word then return false, "That name isn't allowed." end
	end

	for _, word in ipairs(DubzChars.Blocked) do
		word = string.lower(string.Trim(word))

		if word ~= "" then
			local squashed = squash(word)

			for _, text in ipairs(candidates) do
				if string.find(text, word, 1, true) or string.find(text, squashed, 1, true) then return false, "That name isn't allowed." end
			end
		end
	end

	return true, "", first, last
end
