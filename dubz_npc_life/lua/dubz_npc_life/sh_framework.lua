-- Registers NPC Life with the Dubz Framework: the looking, the idle animations and the sometimes-spoken lines.
local cfg = DubzNPCLife.Config

DFW.Bind.Module({
	id = "npc_life",
	name = "NPC Life",
	version = "1.0.0",
	icon = "social/person",
	description = "Shop NPCs idle with changing animations, look at you with their head and eyes, turn to face you, and sometimes say a line when you walk up or a sale goes through.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "Enabled", label = "Enabled", group = "Looking"},
	{path = "LookDistance", label = "Look At You Within", min = 60, max = 1500, decimals = 0, group = "Looking", description = "Units: how close you must be for an NPC to look at you."},
	{path = "TurnToFace", label = "Turn To Face You", group = "Looking", description = "The whole body turns when you are far to the side or behind. Off: only the head and eyes."},
	{path = "TurnSpeed", label = "Turn Speed", min = 30, max = 400, decimals = 0, group = "Looking", description = "Degrees a second."},
	{path = "IdleSequences", label = "Idle Animations", list = true, group = "Idle", maxLength = 300, description = "Animation names the NPC changes between while standing (the ones his model does not have are skipped)."},
	{path = "IdleSwitchMin", label = "Change Idle At Least (Seconds)", min = 2, max = 120, decimals = 0, group = "Idle"},
	{path = "IdleSwitchMax", label = "Change Idle At Most (Seconds)", min = 2, max = 240, decimals = 0, group = "Idle"},

	{path = "SoundsOn", label = "Spoken Lines", group = "Voice"},
	{path = "GreetDistance", label = "Greet Within", min = 40, max = 600, decimals = 0, group = "Voice", description = "Units: walking up this close can trigger a greeting."},
	{path = "GreetChance", label = "Greeting Chance (%)", min = 0, max = 100, decimals = 0, group = "Voice", description = "Not every time: this is the chance."},
	{path = "SaleChance", label = "Sale Line Chance (%)", min = 0, max = 100, decimals = 0, group = "Voice", description = "The chance of a line when a purchase or sale goes through."},
	{path = "SoundCooldown", label = "Quiet Between Lines (Seconds)", min = 0, max = 120, decimals = 0, group = "Voice"},
	{path = "SoundLevel", label = "Loudness", min = 40, max = 100, decimals = 0, group = "Voice", description = "Sound level: 60 is quiet, 80 carries."},
	{path = "GreetSounds", label = "Greeting Sounds", list = true, group = "Voice", maxLength = 600},
	{path = "SaleSounds", label = "Sale Sounds", list = true, group = "Voice", maxLength = 600},
})
