-- Commends: players give each other reputation marks (the scoreboard drawer sends them).
-- Totals per kind are stored per player and networked as dubz_cm_<id>; each commend also moves karma.
util.AddNetworkString("DubzKarma_Commend")

local cfg = DubzKarma.Config

sql.Query("CREATE TABLE IF NOT EXISTS dubz_commend_daily (sid TEXT NOT NULL, day TEXT NOT NULL, used INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (sid, day))")
sql.Query("CREATE TABLE IF NOT EXISTS dubz_commends (sid TEXT NOT NULL, kind TEXT NOT NULL, count INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (sid, kind))")

-- Commends received belong to the character; the daily limit on giving them belongs to the account
local function accountOf(ply)
	return ply:SteamID64() or ply:SteamID()
end

local function sidOf(ply)
	if DubzChars and DubzChars.GetKey then return DubzChars.GetKey(ply) end
	return accountOf(ply)
end

local function loadCommends(ply)
	for _, kind in ipairs(DubzKarma.Commends) do ply:SetNWInt("dubz_cm_" .. kind.id, 0) end

	local rows = sql.Query("SELECT kind, count FROM dubz_commends WHERE sid = " .. sql.SQLStr(sidOf(ply)))

	-- The first character of an account inherits the account's old commends
	if not rows and DubzChars and DubzChars.LegacyKey then
		local legacy = DubzChars.LegacyKey(ply)
		if legacy then rows = sql.Query("SELECT kind, count FROM dubz_commends WHERE sid = " .. sql.SQLStr(legacy)) end
	end

	for _, row in ipairs(rows or {}) do
		if DubzKarma.FindCommend(row.kind) then ply:SetNWInt("dubz_cm_" .. row.kind, tonumber(row.count) or 0) end
	end
end

hook.Add("PlayerInitialSpawn", "DubzKarma_LoadCommends", loadCommends)

-- A deleted (wiped) character takes its commends with it
hook.Add("DubzCharWipe", "DubzKarma_CharWipeCommends", function(account, charId, keys)
	for _, key in ipairs(keys) do sql.Query("DELETE FROM dubz_commends WHERE sid = " .. sql.SQLStr(key)) end
end)
hook.Add("DubzCharLoad", "DubzKarma_CharLoadCommends", loadCommends)

-- Messages go to chat.
local PREFIX = Color(240, 196, 25)

local function say(ply, text)
	if DarkRP and DarkRP.talkToPerson then
		DarkRP.talkToPerson(ply, PREFIX, "[Reputation] ", color_white, text)
	else
		ply:ChatPrint("[Reputation] " .. text)
	end
end

net.Receive("DubzKarma_Commend", function(_, rater)
	local target = net.ReadEntity()
	local kind = DubzKarma.FindCommend(net.ReadString())

	if not DubzKarma.Enabled() then return end
	if not IsValid(target) or not target:IsPlayer() or target == rater or not kind then return end

	-- Light spam guard on the net message itself
	if (rater.DubzCommendNextNet or 0) > CurTime() then return end
	rater.DubzCommendNextNet = CurTime() + 0.5

	-- One commend per rater -> target per cooldown
	rater.DubzCommendCooldowns = rater.DubzCommendCooldowns or {}
	local key = sidOf(target)
	local readyAt = rater.DubzCommendCooldowns[key] or 0

	if readyAt > CurTime() then
		say(rater, string.format("Wait %d more minute(s) before commending %s again.", math.ceil((readyAt - CurTime()) / 60), target:Nick()))
		return
	end

	-- Daily allowance (saved, so reconnecting doesn't reset it)
	local day = os.date("%Y-%m-%d")
	local raterSid = sql.SQLStr(accountOf(rater))
	local used = tonumber(sql.QueryValue("SELECT used FROM dubz_commend_daily WHERE sid = " .. raterSid .. " AND day = " .. sql.SQLStr(day))) or 0

	if used >= cfg.commendsPerDay then
		say(rater, string.format("You have used all %d of your daily commends. They refresh tomorrow.", cfg.commendsPerDay))
		return
	end

	used = used + 1
	sql.Query("REPLACE INTO dubz_commend_daily (sid, day, used) VALUES (" .. raterSid .. ", " .. sql.SQLStr(day) .. ", " .. used .. ")")

	rater.DubzCommendCooldowns[key] = CurTime() + cfg.commendCooldown

	local nwKey = "dubz_cm_" .. kind.id
	local count = target:GetNWInt(nwKey, 0) + 1
	target:SetNWInt(nwKey, count)

	local sid = sql.SQLStr(key)
	sql.Query("REPLACE INTO dubz_commends (sid, kind, count) VALUES (" .. sid .. ", " .. sql.SQLStr(kind.id) .. ", " .. count .. ")")

	DubzKarma.Add(target, kind.karma)

	say(rater, "You commended " .. target:Nick() .. " as " .. kind.name .. ". (Used " .. used .. " of " .. cfg.commendsPerDay .. " daily commends.)")

	-- Tell the person who was commended (anonymously), including what it did to their karma
	local effect = kind.karma ~= 0 and string.format(" (%+d karma)", kind.karma) or ""
	say(target, "Someone marked you as " .. kind.name .. "." .. effect)
end)
