-- Characters, server side: storage, the join gate (a player can't do anything until a character is chosen),
-- creating / choosing / switching / deleting, and applying the chosen character (RP name, money, look, outfit).
--
-- Per-character data: every system that stores data for a player stores it under DubzChars.GetKey(ply), which is the
-- Steam ID plus the character ("76561198000000000_3"). When a character is left or entered these hooks run, in this
-- order, so each addon can save and load its own data:
--     DubzCharLeave(ply, oldChar)     the old character is still active: save under the old key
--     DubzCharLoad(ply, newChar)      the new one is active: load under the new key (reset anything it has none of)
--     DubzCharSelected(ply, newChar)  everything is in place and the player has respawned
-- The first character on an account inherits what the account had before characters existed (LegacyKey).
util.AddNetworkString("DubzChars_Ready")    -- client -> server: my game is loaded, send my characters
util.AddNetworkString("DubzChars_List")     -- server -> client: characters, slots and which one was last played
util.AddNetworkString("DubzChars_Create")   -- client -> server: first, last, face, clothing
util.AddNetworkString("DubzChars_Select")   -- client -> server: character id
util.AddNetworkString("DubzChars_Delete")   -- client -> server: character id
util.AddNetworkString("DubzChars_Cancel")   -- client -> server: closed the switch menu without choosing
util.AddNetworkString("DubzChars_Result")   -- server -> client: ok, text
util.AddNetworkString("DubzChars_Done")     -- server -> client: a character was chosen, close the menu
util.AddNetworkString("DubzChars_Opened")   -- client -> server: the menu is on my screen (stop resending)

local cfg = DubzChars.Config

sql.Query([[CREATE TABLE IF NOT EXISTS dubz_characters (
	id INTEGER PRIMARY KEY AUTOINCREMENT, account TEXT NOT NULL, first TEXT NOT NULL, last TEXT NOT NULL,
	face TEXT NOT NULL, clothing TEXT NOT NULL, created INTEGER NOT NULL, last_played INTEGER NOT NULL DEFAULT 0,
	deleted INTEGER NOT NULL DEFAULT 0)]])
sql.Query("ALTER TABLE dubz_characters ADD COLUMN money INTEGER")   -- fails harmlessly when it already exists

-- Other addons listen to DubzCharLeave / Load / Selected / Wipe. One of them failing must not stop a player entering the game (or a delete
-- going through), so each run is protected and the failure is printed with its name.
local function safeRun(name, ...)
	local ok, err = pcall(hook.Run, name, ...)
	if not ok then ErrorNoHalt("[DubzChars] a listener of " .. name .. " failed: " .. tostring(err) .. "\n") end
end

local function log(text)
	MsgC(Color(120, 200, 255), "[DubzChars] ", color_white, text .. "\n")
end

-- Storage (everything goes through these so the backend can change later) --------------------------------------------

local function account(ply) return ply:SteamID64() or ply:SteamID() end

-- What each system keys its data by: the Steam ID, plus the character once one is active
function DubzChars.GetKey(ply)
	local char = ply.DubzChar
	if char then return account(ply) .. "_" .. char.id end

	return account(ply)
end

-- The old, character-less key: only the account's FIRST character gets it, so existing progress isn't lost
function DubzChars.LegacyKey(ply)
	local char = ply.DubzChar
	if not char then return nil end

	local first = tonumber(sql.QueryValue("SELECT MIN(id) FROM dubz_characters WHERE account = " .. sql.SQLStr(account(ply))))
	if first == char.id then return account(ply) end

	return nil
end

-- What a character is wearing, for the preview (read from what Cosmetics has saved for that character)
local function worn(ply, char)
	local key = sql.SQLStr(account(ply) .. "_" .. char.id)
	local out = {accessories = {}}

	if not sql.TableExists("dubz_cos_worn") then return out end

	for _, row in ipairs(sql.Query("SELECT slot, id FROM dubz_cos_worn WHERE sid = " .. key) or {}) do out.accessories[row.slot] = row.id end

	local look = sql.QueryValue("SELECT id FROM dubz_cos_outfit WHERE sid = " .. key)
	if look and look ~= false then out.face = look end

	local clothes = sql.QueryValue("SELECT id FROM dubz_cos_clothes WHERE worn = 1 AND sid = " .. key)
	if clothes and clothes ~= false then out.clothing = clothes end

	return out
end

function DubzChars.GetCharacters(ply)
	local rows = sql.Query("SELECT * FROM dubz_characters WHERE deleted = 0 AND account = " .. sql.SQLStr(account(ply)) .. " ORDER BY id") or {}
	local list = {}

	for _, row in ipairs(rows) do
		list[#list + 1] = {
			id = tonumber(row.id), first = row.first, last = row.last, face = row.face, clothing = row.clothing,
			last_played = tonumber(row.last_played) or 0, money = tonumber(row.money),
		}
	end

	return list
end

function DubzChars.GetCharacter(ply, id)
	for _, char in ipairs(DubzChars.GetCharacters(ply)) do
		if char.id == id then return char end
	end
end

function DubzChars.GetSlots(ply)
	local premium = DubzChars.PremiumGroups[string.lower(ply:GetUserGroup() or "")] == true
	local slots = premium and cfg.slotsPremium or cfg.slotsNormal

	-- Other addons can raise it: return a number from the DubzCharsSlots hook
	local override = tonumber(hook.Run("DubzCharsSlots", ply, slots) or 0) or 0

	return math.max(slots, 1, override)
end

local function nameTaken(first, last)
	if not cfg.uniqueNames then return false end

	local row = sql.QueryValue("SELECT id FROM dubz_characters WHERE deleted = 0 AND lower(first) = " .. sql.SQLStr(string.lower(first))
		.. " AND lower(last) = " .. sql.SQLStr(string.lower(last)))

	return row ~= nil and row ~= false
end

-- The active character of a player (nil until they pick one)
function DubzChars.Active(ply)
	return ply.DubzChar
end

-- Money belongs to the character ------------------------------------------------------------------------------------

local function startingMoney()
	return (GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.startingmoney) or 500
end

local function saveMoney(ply)
	local char = ply.DubzChar
	if not char or not ply.getDarkRPVar then return end

	char.money = math.floor(ply:getDarkRPVar("money") or 0)
	sql.Query("UPDATE dubz_characters SET money = " .. char.money .. " WHERE id = " .. char.id)
end

local function setMoney(ply, amount)
	amount = math.floor(amount)

	if ply.setDarkRPVar then ply:setDarkRPVar("money", amount) end
	if DarkRP and DarkRP.storeMoney then pcall(DarkRP.storeMoney, ply, amount) end
end

timer.Create("DubzChars_SaveMoney", 60, 0, function()
	for _, ply in ipairs(player.GetAll()) do saveMoney(ply) end
end)

hook.Add("PlayerDisconnected", "DubzChars_SaveMoneyLeave", saveMoney)
hook.Add("ShutDown", "DubzChars_SaveMoneyAll", function() for _, ply in ipairs(player.GetAll()) do saveMoney(ply) end end)

-- The module's off-state is saved by the framework and survives restarts, so a module that was ever switched off (a test, a failed
-- start) stays off with no sign. Once, turn it back on; after that the admin menu's choice is respected.
local REENABLE_FILE = "dubz_characters_reenabled.txt"

local function reenableOnce()
	if file.Exists(REENABLE_FILE, "DATA") then return end
	if not (DFW and DFW.Modules and DFW.Modules.Exists("characters")) then return end

	file.Write(REENABLE_FILE, "done")
	if DFW.Modules.IsEnabled("characters") then return end

	local ok, reason = DFW.Modules.SetEnabled("characters", true)
	log("the Characters module was switched off in the framework's saved state: turned it back on (" .. tostring(ok and "ok" or reason) .. ")")
end

hook.Add("InitPostEntity", "DubzChars_Reenable", function() timer.Simple(5, reenableOnce) end)

concommand.Add("dubz_chars_enable", function(ply)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	if not (DFW and DFW.Modules) then return end

	local ok, reason = DFW.Modules.SetEnabled("characters", true)
	log("enable Characters module: " .. tostring(ok and "ok" or reason))
end)

-- If the screen is switched off, say why in the console, once the game is up (it is easy to miss: players just spawn in)
hook.Add("InitPostEntity", "DubzChars_WhyOff", function()
	timer.Simple(15, function()
		if DubzChars.Enabled() then
			log("character screen is ON. Players without a character are held at it. (dubz_chars_status lists who is where.)")
		elseif not (DubzCosmetics and DubzCosmetics.Faces) then
			MsgC(Color(255, 80, 80), "[DubzChars] ", color_white, "the character screen is OFF: the Cosmetics addon (it owns the looks and outfits) is not loaded, so players spawn straight in.\n")
		else
			MsgC(Color(255, 80, 80), "[DubzChars] ", color_white, "the character screen is OFF: the Characters module is switched off in !dubzconfig > Modules.\n")
		end
	end)
end)

-- The lobby camera ----------------------------------------------------------------------------------------------------
-- While a player chooses a character they look at the city through a fixed camera (set once, per map, at a busy spot
-- so they can watch the RP while they decide). A superadmin stands where it should be, looks the way it should look and
-- runs  dubz_chars_setcamera  (chat: !setcharcam). Without one the menu just sits over wherever they are.
local CAMERA_FILE = "dubz_characters_camera_" .. game.GetMap() .. ".json"
DubzChars.Camera = nil

local function loadCamera()
	local text = file.Exists(CAMERA_FILE, "DATA") and file.Read(CAMERA_FILE, "DATA")
	local data = text and util.JSONToTable(text)

	if data and data.pos and data.ang then
		DubzChars.Camera = {pos = Vector(data.pos[1], data.pos[2], data.pos[3]), ang = Angle(data.ang[1], data.ang[2], data.ang[3])}
	end
end

loadCamera()

local function setCamera(ply)
	local pos, ang = ply:EyePos(), ply:EyeAngles()
	file.Write(CAMERA_FILE, util.TableToJSON({pos = {pos.x, pos.y, pos.z}, ang = {ang.p, ang.y, 0}}))

	DubzChars.Camera = {pos = pos, ang = Angle(ang.p, ang.y, 0)}
	ply:ChatPrint("[Characters] The lobby camera is set to where you are looking.")
end

-- The camera's surroundings have to be sent to the player, or the people standing there would not show up
hook.Add("SetupPlayerVisibility", "DubzChars_CameraPVS", function(ply)
	if DubzChars.Camera and (ply.DubzCharPending or (ply.DubzSwitchUntil or 0) > CurTime()) then AddOriginToPVS(DubzChars.Camera.pos) end
end)

local sendList   -- (defined below, with the list the menu shows)

-- The gate ---------------------------------------------------------------------------------------------------------

local function gated(ply)
	return IsValid(ply) and ply.DubzCharPending == true
end

-- Allowed to choose / create / delete: at the join gate, or after opening the switch menu (valid for a few minutes)
local function choosing(ply)
	return gated(ply) or (IsValid(ply) and (ply.DubzSwitchUntil or 0) > CurTime())
end

local function lockPlayer(ply)
	ply:Lock()
	ply:GodEnable()
	ply:SetNoDraw(true)
	ply:DrawShadow(false)
end

local function unlockPlayer(ply)
	ply:UnLock()
	ply:GodDisable()
	ply:SetNoDraw(false)
	ply:DrawShadow(true)
end

-- Everybody who joins, or joins back, starts at the character screen: nobody plays without a character (so nobody is left
-- with just their Steam name). The list is pushed to them until their screen confirms it is open, so a slow load can't skip it.
local function putAtGate(ply)
	ply.DubzCharPending = true
	ply.DubzCharsOpen = false
	ply:SetNWBool("dubz_char_pending", true)

	if ply:Alive() then lockPlayer(ply) end
end

hook.Add("PlayerInitialSpawn", "DubzChars_Gate", function(ply)
	if ply:IsBot() or not DubzChars.Enabled() then return end

	putAtGate(ply)
end)

net.Receive("DubzChars_Opened", function(_, ply) ply.DubzCharsOpen = true end)

-- Keeps the gate honest: anyone without an active character is put back at it (and anyone at it whose screen has not opened
-- is sent the list again)
timer.Create("DubzChars_Enforce", 4, 0, function()
	if not DubzChars.Enabled() then return end

	for _, ply in ipairs(player.GetAll()) do
		if not ply:IsBot() and not ply.DubzChar and not ply.DubzCharPreviewing then
			if not gated(ply) then putAtGate(ply) end

			-- (only once the player has been in the game a few seconds, so the list isn't sent into a loading screen)
			if not ply.DubzCharsOpen and ply:TimeConnected() > 6 then sendList(ply) end
		end
	end
end)

-- Spawns while still choosing keep the player locked and unseen
hook.Add("PlayerSpawn", "DubzChars_GateSpawn", function(ply)
	if gated(ply) then timer.Simple(0, function() if gated(ply) then lockPlayer(ply) ply:StripWeapons() end end) end
end)

hook.Add("PlayerSay", "DubzChars_GateChat", function(ply) if gated(ply) then return "" end end)
hook.Add("PlayerShouldTakeDamage", "DubzChars_GateDamage", function(ply) if gated(ply) then return false end end)
hook.Add("PlayerCanPickupWeapon", "DubzChars_GateWeapons", function(ply) if gated(ply) then return false end end)
hook.Add("PlayerUse", "DubzChars_GateUse", function(ply) if gated(ply) then return false end end)
hook.Add("PlayerCanHearPlayersVoice", "DubzChars_GateVoice", function(listener, talker) if gated(talker) then return false end end)

-- The list the menu shows --------------------------------------------------------------------------------------------

-- mode: nil = the join gate, "preview" = staff preview (changes nothing), "switch" = changing character in game
function sendList(ply, mode)
	local chars = DubzChars.GetCharacters(ply)

	local last, best = 0, -1
	for _, char in ipairs(chars) do
		char.look = worn(ply, char)
		if char.last_played > best then best, last = char.last_played, char.id end
	end

	-- Staff who opened the preview may delete from it (the preview is only ever sent to staff)
	if mode == "preview" then ply.DubzPreviewUntil = CurTime() + 600 end

	-- The character being played is the one to highlight when switching
	if mode == "switch" and ply.DubzChar then last = ply.DubzChar.id end

	local json = util.TableToJSON({
		chars = chars, slots = DubzChars.GetSlots(ply), maxSlots = math.max(cfg.slotsNormal, cfg.slotsPremium), last = last,
		starters = DubzChars.StarterOutfits, preview = mode == "preview", switching = mode == "switch",
		current = ply.DubzChar and ply.DubzChar.id or 0,
		camera = DubzChars.Camera and {pos = {DubzChars.Camera.pos.x, DubzChars.Camera.pos.y, DubzChars.Camera.pos.z}, ang = {DubzChars.Camera.ang.p, DubzChars.Camera.ang.y, 0}} or nil,
	})

	net.Start("DubzChars_List")
		net.WriteString(json)
	net.Send(ply)
end

local function result(ply, ok, text)
	net.Start("DubzChars_Result")
		net.WriteBool(ok)
		net.WriteString(text or "")
	net.Send(ply)
end

net.Receive("DubzChars_Ready", function(_, ply)
	if (ply.DubzCharsReadyAt or 0) > CurTime() then return end
	ply.DubzCharsReadyAt = CurTime() + 2

	-- Nobody without a character gets past this, whatever state the join left them in
	if not ply.DubzChar and not gated(ply) and DubzChars.Enabled() and not ply:IsBot() then putAtGate(ply) end

	if gated(ply) then sendList(ply) end
end)

-- For finding out why a screen did not show: dubz_chars_status in the server console
concommand.Add("dubz_chars_status", function(ply)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end

	for _, other in ipairs(player.GetAll()) do
		local text = string.format("[Characters] %s: character=%s pending=%s screenOpen=%s enabled=%s", other:Nick(), other.DubzChar and other.DubzChar.id or "none", tostring(other.DubzCharPending), tostring(other.DubzCharsOpen), tostring(DubzChars.Enabled()))
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end
end)

-- Applying a character --------------------------------------------------------------------------------------------

local function applyNow(ply, char, isNew)
	local old = ply.DubzChar

	-- Choosing the character you already are: nothing to do
	if old and old.id == char.id then
		ply.DubzSwitchUntil = nil
		if not gated(ply) then ply:UnLock() ply:GodDisable() end

		net.Start("DubzChars_Done")
		net.Send(ply)
		return
	end

	-- Leaving the old one: every system saves under the old key first
	if old then
		saveMoney(ply)
		safeRun("DubzCharLeave", ply, old)
	end

	local firstEver = #DubzChars.GetCharacters(ply) <= 1 and not old   -- the account's first: keeps its money as it is

	ply.DubzChar = char
	ply:SetNWInt("dubz_char_id", char.id)
	ply:SetNWString("dubz_char_name", char.first .. " " .. char.last)

	-- Money belongs to the character
	-- A brand new character always starts fresh (the server's starting money); an existing one gets back what it had when it was left
	if isNew then
		setMoney(ply, startingMoney())
	elseif char.money then
		setMoney(ply, char.money)
	elseif old or not firstEver then
		setMoney(ply, startingMoney())
	end

	-- Back to the default job: everybody enters as a citizen (the job is not kept between characters). Also when the character before was
	-- deleted (no "old" then, but the job is still the deleted one's).
	if GAMEMODE and GAMEMODE.DefaultTeam and ply.changeTeam and ply:Team() ~= GAMEMODE.DefaultTeam then
		pcall(ply.changeTeam, ply, GAMEMODE.DefaultTeam, true, true)
	end

	-- Every system loads the new character's data (a brand new one starts empty)
	safeRun("DubzCharLoad", ply, char, isNew)

	-- RP name (the scoreboard, chat and the overhead text all follow it)
	local name = char.first .. " " .. char.last
	-- Set directly: DarkRP's own setRPName checks its player table and adds " 1" when the name is already in it (and a character's name
	-- always is, from the last time it was played). Names are unique among characters (checked when one is made), so this is safe.
	if DarkRP and DarkRP.storeRPName then
		local ok, err = pcall(DarkRP.storeRPName, ply, name)
		if not ok then ErrorNoHalt("[DubzChars] storeRPName failed: " .. tostring(err) .. "\n") end
		ply:setDarkRPVar("rpname", name)
	elseif ply.setDarkRPVar then
		ply:setDarkRPVar("rpname", name)
	end

	-- A new character gets the look and outfit they picked. (An older one already has theirs saved by Cosmetics, so
	-- clothes bought since then aren't undone; only if nothing is saved at all is the creation choice used.)
	if isNew or DubzCosmetics.GetLookId(ply) == "" then
		if DubzCosmetics.GetFace(char.face) then DubzCosmetics.SetLook(ply, char.face) end
		if DubzCosmetics.GetClothing(char.clothing) then DubzCosmetics.UnlockClothing(ply, char.clothing, true) end
	end

	sql.Query("UPDATE dubz_characters SET last_played = " .. os.time() .. " WHERE id = " .. char.id)
	saveMoney(ply)

	ply.DubzCharPending = false
	ply.DubzSwitchUntil = nil
	ply:SetNWBool("dubz_char_pending", false)
	unlockPlayer(ply)

	-- A normal spawn: DarkRP gives the job's loadout and Cosmetics puts the character's model on
	ply:Spawn()

	net.Start("DubzChars_Done")
	net.Send(ply)

	safeRun("DubzCharSelected", ply, char)
end

-- Allowed to pick, make or delete? Anyone without a character always is (they are put at the gate if the join missed it). Anyone else
-- needs the switch screen open; they are told why when they are not.
local function mayChoose(ply)
	if not ply.DubzChar and not gated(ply) and DubzChars.Enabled() and not ply:IsBot() then putAtGate(ply) end

	if choosing(ply) then return true end

	net.Start("DubzChars_Result")
		net.WriteBool(false)
		net.WriteString("The character screen isn't open for you. Type " .. cfg.switchCommand .. " to switch characters.")
	net.Send(ply)

	return false
end

-- Choosing a character, protected: if anything in it fails the player is told what, and let in anyway when the character was already set
local function apply(ply, char, isNew)
	log(ply:Nick() .. " is entering as " .. char.first .. " " .. char.last .. " (#" .. char.id .. (isNew and ", new" or "") .. ")")

	local ok, err = pcall(applyNow, ply, char, isNew)
	if ok then return end

	ErrorNoHalt("[DubzChars] entering as #" .. char.id .. " failed for " .. ply:Nick() .. ": " .. tostring(err) .. "\n")
	result(ply, false, "Something went wrong loading that character: " .. tostring(err))

	-- Got as far as being that character but stopped before the end: finish the entry so they are not stuck at the screen
	if ply.DubzChar and ply.DubzChar.id == char.id and gated(ply) then
		ply.DubzCharPending = false
		ply.DubzSwitchUntil = nil
		ply:SetNWBool("dubz_char_pending", false)
		unlockPlayer(ply)

		pcall(ply.Spawn, ply)

		net.Start("DubzChars_Done")
		net.Send(ply)
	end
end

net.Receive("DubzChars_Select", function(_, ply)
	local id = net.ReadUInt(32)
	if not mayChoose(ply) or (ply.DubzCharsNext or 0) > CurTime() then return end
	ply.DubzCharsNext = CurTime() + 0.5

	local char = DubzChars.GetCharacter(ply, id)
	if not char then result(ply, false, "That character doesn't exist.") return end

	log(ply:Nick() .. " pressed Play on #" .. id)
	apply(ply, char, false)
end)

net.Receive("DubzChars_Create", function(_, ply)
	local first, last, face, clothing = net.ReadString(), net.ReadString(), net.ReadString(), net.ReadString()
	if not mayChoose(ply) or (ply.DubzCharsNext or 0) > CurTime() then return end
	ply.DubzCharsNext = CurTime() + 1

	if #DubzChars.GetCharacters(ply) >= DubzChars.GetSlots(ply) then result(ply, false, "You don't have a free character slot.") return end

	log(ply:Nick() .. " is creating a character: First name field = '" .. first .. "', Last name field = '" .. last .. "'")

	local ok, reason, cleanFirst, cleanLast = DubzChars.ValidateName(first, last)
	if not ok then result(ply, false, reason) return end

	if nameTaken(cleanFirst, cleanLast) then result(ply, false, "The name " .. cleanFirst .. " " .. cleanLast .. " is already taken by another character. Pick a different name.") return end

	-- Only looks and outfits that exist, and only the starter outfits
	if not DubzCosmetics.GetFace(face) then result(ply, false, "Pick a model.") return end
	if not table.HasValue(DubzChars.StarterOutfits, clothing) or not DubzCosmetics.ModelFor(face, clothing) then result(ply, false, "Pick an outfit.") return end

	local now = os.time()
	sql.Query(string.format("INSERT INTO dubz_characters (account, first, last, face, clothing, created, last_played) VALUES (%s, %s, %s, %s, %s, %d, %d)",
		sql.SQLStr(account(ply)), sql.SQLStr(cleanFirst), sql.SQLStr(cleanLast), sql.SQLStr(face), sql.SQLStr(clothing), now, now))

	local id = tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
	local char = id and DubzChars.GetCharacter(ply, id)
	if not char then result(ply, false, "Could not save the character. Try again.") return end

	apply(ply, char, true)
end)

net.Receive("DubzChars_Delete", function(_, ply)
	local id = net.ReadUInt(32)
	local previewing = (ply.DubzPreviewUntil or 0) > CurTime()
	if not (previewing or mayChoose(ply)) or (ply.DubzCharsNext or 0) > CurTime() then return end
	ply.DubzCharsNext = CurTime() + 1

	if not DubzChars.GetCharacter(ply, id) then result(ply, false, "That character doesn't exist.") return end

	log(ply:Nick() .. " is deleting #" .. id .. " (" .. cfg.deleteMode .. ")")

	-- "wipe" erases the character and everything saved for it. "archive" only marks it deleted and leaves the data, so
	-- staff can bring it back (dubz_chars_restore <id>) if it was a mistake.
	local playing = ply.DubzChar and ply.DubzChar.id == id

	if playing then
		-- Deleting the character you are playing: they are saved, then you are sent back to spawn and the character
		-- menu opens over the lobby camera until you pick or make another
		saveMoney(ply)
		safeRun("DubzCharLeave", ply, ply.DubzChar)
	end

	if cfg.deleteMode == "wipe" then
		-- Every system deletes what it stored under this character's key. The account's first character also owns the
		-- old pre-character data, so that goes too (or the next character would inherit it).
		local first = tonumber(sql.QueryValue("SELECT MIN(id) FROM dubz_characters WHERE account = " .. sql.SQLStr(account(ply)))) == id
		local keys = {account(ply) .. "_" .. id}
		if first then keys[#keys + 1] = account(ply) end

		safeRun("DubzCharWipe", account(ply), id, keys)
		sql.Query("DELETE FROM dubz_characters WHERE id = " .. id .. " AND account = " .. sql.SQLStr(account(ply)))
	else
		sql.Query("UPDATE dubz_characters SET deleted = 1 WHERE id = " .. id .. " AND account = " .. sql.SQLStr(account(ply)))
	end

	if playing then
		ply.DubzChar = nil
		ply:SetNWInt("dubz_char_id", 0)
		ply:SetNWString("dubz_char_name", "")

		safeRun("DubzCharLoad", ply, nil)   -- every system goes back to its "no character yet" state

		ply.DubzCharPending = true
		ply.DubzSwitchUntil = nil
		ply:SetNWBool("dubz_char_pending", true)
		ply:Spawn()   -- the spawn gate locks and hides them again
	end

	-- Back to the right screen: the real one when they were playing the deleted character (or are at the gate), the preview or the
	-- switch screen otherwise
	local mode
	if not playing and not gated(ply) then mode = previewing and "preview" or "switch" end
	if playing then ply.DubzPreviewUntil = nil end

	sendList(ply, mode)
end)

-- Switching in game ------------------------------------------------------------------------------------------------

-- !characters opens the menu so a player can change character or make another (limited by their slots). Their current
-- character is saved first and everything about them changes: name, money, pocket, accessories, skills, karma ...
local function openSwitch(ply)
	if not DubzChars.Enabled() or not cfg.switchEnabled then return end
	if not ply:Alive() then result(ply, false, "You can't switch characters while dead.") return end

	if (ply.DubzNextSwitch or 0) > CurTime() then
		result(ply, false, "Wait " .. math.ceil(ply.DubzNextSwitch - CurTime()) .. " seconds before switching again.")
		return
	end

	ply.DubzSwitchUntil = CurTime() + 300
	ply:Lock()
	ply:GodEnable()

	sendList(ply, "switch")
end

hook.Add("DubzCharSelected", "DubzChars_SwitchCooldown", function(ply)
	ply.DubzNextSwitch = CurTime() + cfg.switchCooldown
end)

net.Receive("DubzChars_Cancel", function(_, ply)
	if gated(ply) then return end

	ply.DubzSwitchUntil = nil
	ply:UnLock()
	ply:GodDisable()
end)

hook.Add("PlayerSay", "DubzChars_SwitchCommand", function(ply, text)
	if string.lower(string.Trim(text)) ~= string.lower(cfg.switchCommand) then return end

	openSwitch(ply)
	return ""
end)

-- Staff preview: opens the start screen to look at it or work on it. Nothing is changed: choosing, creating or
-- deleting in preview mode just closes it. Console: dubz_chars_menu     Chat: !charmenu
local function previewAllowed(ply)
	return IsValid(ply) and (ply:IsSuperAdmin() or (DFW and DFW.Access and DFW.Access.CanConfigure and DFW.Access.CanConfigure(ply)))
end

concommand.Add("dubz_chars_menu", function(ply)
	if previewAllowed(ply) then sendList(ply, ply.DubzChar and "preview" or nil) end   -- (someone with no character gets the real screen)
end)

hook.Add("PlayerSay", "DubzChars_PreviewCommand", function(ply, text)
	if string.lower(string.Trim(text)) ~= "!charmenu" or not previewAllowed(ply) then return end

	sendList(ply, ply.DubzChar and "preview" or nil)
	return ""
end)

-- Archived characters: staff can list and restore them (everything saved for a character is still there)
local function staffOnly(ply) return not IsValid(ply) or previewAllowed(ply) end

local function reply(ply, text) if IsValid(ply) then ply:ChatPrint(text) else print(text) end end

concommand.Add("dubz_chars_deleted", function(ply, _, args)
	if not staffOnly(ply) then return end

	local filter = args[1] and (" AND account = " .. sql.SQLStr(args[1])) or ""
	local rows = sql.Query("SELECT id, account, first, last FROM dubz_characters WHERE deleted = 1" .. filter .. " ORDER BY id DESC LIMIT 30") or {}

	if #rows == 0 then reply(ply, "No archived characters.") return end
	for _, row in ipairs(rows) do reply(ply, string.format("#%s  %s %s  (account %s)   restore: dubz_chars_restore %s", row.id, row.first, row.last, row.account, row.id)) end
end)

concommand.Add("dubz_chars_restore", function(ply, _, args)
	if not staffOnly(ply) then return end

	local id = tonumber(args[1])
	if not id then reply(ply, "Usage: dubz_chars_restore <character id>  (dubz_chars_deleted lists them)") return end

	sql.Query("UPDATE dubz_characters SET deleted = 0 WHERE id = " .. id)
	reply(ply, "Character #" .. id .. " restored: it is back in its owner's list.")
end)

-- Every character as stored (first name, then last name), to check names against what was typed
concommand.Add("dubz_chars_list", function(ply, _, args)
	if not staffOnly(ply) then return end

	local filter = args[1] and (" AND account = " .. sql.SQLStr(args[1])) or ""
	local rows = sql.Query("SELECT id, account, first, last FROM dubz_characters WHERE deleted = 0" .. filter .. " ORDER BY id DESC LIMIT 40") or {}

	if #rows == 0 then reply(ply, "No characters.") return end
	for _, row in ipairs(rows) do reply(ply, string.format("#%s  FIRST=%s  LAST=%s  (account %s)", row.id, row.first, row.last, row.account)) end
end)

-- Fix a name: dubz_chars_rename <id> <first> <last>   (applies the next time that character is played)
concommand.Add("dubz_chars_rename", function(ply, _, args)
	if not staffOnly(ply) then return end

	local id = tonumber(args[1])
	if not id or not args[2] or not args[3] then reply(ply, "Usage: dubz_chars_rename <character id> <first name> <last name>  (dubz_chars_list shows the ids)") return end

	local ok, reason, first, last = DubzChars.ValidateName(args[2], args[3])
	if not ok then reply(ply, reason) return end

	sql.Query("UPDATE dubz_characters SET first = " .. sql.SQLStr(first) .. ", last = " .. sql.SQLStr(last) .. " WHERE id = " .. id)
	reply(ply, "Character #" .. id .. " is now " .. first .. " " .. last .. ".")
end)

-- Swap the two names of a character: dubz_chars_swapnames <id>
concommand.Add("dubz_chars_swapnames", function(ply, _, args)
	if not staffOnly(ply) then return end

	local id = tonumber(args[1])
	if not id then reply(ply, "Usage: dubz_chars_swapnames <character id>") return end

	sql.Query("UPDATE dubz_characters SET first = last, last = first WHERE id = " .. id)
	reply(ply, "Character #" .. id .. ": first and last name swapped (takes effect the next time it is played).")
end)

concommand.Add("dubz_chars_setcamera", function(ply)
	if IsValid(ply) and previewAllowed(ply) then setCamera(ply) end
end)

hook.Add("PlayerSay", "DubzChars_CameraCommand", function(ply, text)
	if string.lower(string.Trim(text)) ~= "!setcharcam" or not previewAllowed(ply) then return end

	setCamera(ply)
	return ""
end)
