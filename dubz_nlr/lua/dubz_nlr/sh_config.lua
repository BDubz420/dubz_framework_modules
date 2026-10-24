DubzNLR.Config = {
	-- Seconds after dying that the New Life Rule applies
	time = 240,

	-- Radius (units) around where you died that counts as your NLR zone
	zoneRadius = 1200,

	-- How often (seconds) players with an active NLR are checked against their zone
	checkInterval = 1,

	-- Entering the zone makes the player say a line in OOC chat, exactly as if they typed it themselves.
	-- To stay quiet, the line only goes out after the player has stayed inside for enterDelay seconds,
	-- a player can only trigger one every alertCooldown seconds, and the "left" line is only sent
	-- if the "entered" line was.
	announce = true,
	enterDelay = 3,
	alertCooldown = 60,

	chatPrefix = "//",   -- DarkRP's OOC command ("//" or "/ooc")
	enterMessage = "im violating New Life Rule. I need to leave.",
	leaveMessage = "ok, I've left my NLR zone.",
}
