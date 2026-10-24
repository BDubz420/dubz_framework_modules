-- Registers Weapon Stance with the Dubz Framework (!dubzconfig > Weapon Stance).
local cfg = DubzStance.Config

DFW.Bind.Module({
	id = "weapon_stance",
	name = "Weapon Stance",
	version = "1.0.0",
	icon = "players/face",
	description = "Lowered guns until you aim, like DarkRP's own guns, for M9K and other weapon packs.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "prefixes", label = "Weapon Class Prefixes", list = true, group = "Weapons", description = "Every weapon whose class starts with one of these gets the lowered stance. Comma separated, for example: m9k_"},
	{path = "classes", label = "Single Weapon Classes", list = true, group = "Weapons", description = "Weapons from other packs, one by one. Comma separated."},

	{path = "raiseSeconds", label = "Stays Raised After Firing (Seconds)", min = 0, max = 5, decimals = 1, group = "Raising"},
	{path = "raiseOnFire", label = "Firing Raises The Gun", group = "Raising", description = "On: pressing fire raises the gun straight away. Off: only aiming does."},
	{path = "raiseOnReload", label = "Reloading Raises The Gun", group = "Raising"},
	{path = "reloadSeconds", label = "Longest Reload (Seconds)", min = 0.5, max = 15, decimals = 1, group = "Raising", description = "The gun stays raised for a reload until the magazine is full, or this long (so the reload animation plays in third person). Raise it for slow reloads."},

	{path = "thirdPersonCrosshair", label = "Third Person: Crosshair When Aiming", group = "Crosshair", description = "In third person the crosshair stays up while you aim (first person hides it down the sights). Needs the Third Person addon."},
	{path = "crosshairSize", label = "Crosshair Line Length", min = 2, max = 30, decimals = 0, group = "Crosshair"},
	{path = "crosshairGap", label = "Crosshair Gap", min = 0, max = 30, decimals = 0, group = "Crosshair"},
	{path = "crosshairThickness", label = "Crosshair Thickness", min = 1, max = 6, decimals = 0, group = "Crosshair"},

	{path = "lowerRifle", label = "Lowered Pose: Rifles And SMGs", group = "Poses", maxLength = 20, description = "A hold type: passive, normal, ... DarkRP uses passive."},
	{path = "lowerPistol", label = "Lowered Pose: Pistols", group = "Poses", maxLength = 20, description = "DarkRP uses normal."},
	{path = "lowerShotgun", label = "Lowered Pose: Shotguns", group = "Poses", maxLength = 20, description = "DarkRP uses normal."},
}, {})
