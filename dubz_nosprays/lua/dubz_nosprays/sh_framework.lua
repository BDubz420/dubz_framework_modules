-- Registers No Sprays with the Dubz Framework (!dubzconfig > No Sprays).
DFW.Bind.Module({
	id = "no_sprays",
	name = "No Sprays",
	version = "1.0.0",
	icon = "players/face",
	description = "Stops players spraying their image on walls.",
	dependencies = {"dubz_core"},
}, DubzNoSprays.Config, {
	{path = "blockSprays", label = "Block Sprays", group = "Sprays", description = "On: nobody can spray. Off: sprays work as normal."},
}, {})
