-- Refund settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Refund) edits them live.
DubzRefund = DubzRefund or {}

DubzRefund.Config = {
	-- Cash back for an item that is taken as cash (percent of what it cost)
	cashRate = 75,

	-- Respawning: at most this many items come back per claim; the rest turn into cash (or stay waiting, below)
	maxRespawn = 6,
	overflowToCash = true,       -- true: items over the limit give cash; false: they stay in the list for later

	-- A respawned item still counts toward the entity limit from the F4 shop unless this is on
	surpassLimit = false,

	-- Items bigger than this (width x length x height of the entity, in cubic units) are cash only. A stove is about
	-- 200,000; a money printer about 40,000. The rules table below overrides it per entity.
	autoCashVolume = 120000,

	-- Forgotten refunds disappear after this many days (0 = never)
	expireDays = 7,

	-- Chat command to open the menu again
	chatCommand = "!refund",
}

-- Rules per entity: `match` is part of the entity class or its shop name (not case sensitive); mode says what that
-- entity gets: respawn (comes back) or cash (only cash). Anything not matched uses the size rule above.
DubzRefund.DefaultRules = {
	{match = "stove", mode = "cash"},
	{match = "tv", mode = "cash"},
	{match = "gunlab", mode = "cash"},
	{match = "drug_lab", mode = "cash"},
	{match = "printer", mode = "respawn"},
}
DubzRefund.Rules = table.Copy(DubzRefund.DefaultRules)

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so refunds still work.
function DubzRefund.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("refund")
end

-- What an item gets: "respawn" or "cash". rec has cls, name and vol (size).
function DubzRefund.ModeFor(rec)
	local cls, name = string.lower(rec.cls or ""), string.lower(rec.name or "")

	for _, rule in ipairs(DubzRefund.Rules) do
		local match = string.lower(rule.match or "")
		if match ~= "" and (string.find(cls, match, 1, true) or string.find(name, match, 1, true)) then return rule.mode end
	end

	return (rec.vol or 0) > DubzRefund.Config.autoCashVolume and "cash" or "respawn"
end
