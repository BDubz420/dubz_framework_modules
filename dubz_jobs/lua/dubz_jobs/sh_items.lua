-- Accessories that only jobs hand out (never sold). They are worn through the Job Accessories table while the player
-- holds the job. Placement is tuned once with the placement editor (dubz_cosmetic_editor) like any other accessory.
if not (DubzCosmetics and DubzCosmetics.Register) then return end

-- Placeholder model: a GTA-pack hat. Swap the model here when there is a real hard hat.
DubzCosmetics.Register({
	id = "job_hardhat", name = "Hard Hat", slot = "hat",
	model = "models/modified/hat05_fix.mdl",
	tier = "common", price = 0, shop = false,
})
