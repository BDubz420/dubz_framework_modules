-- Accessories from the two model packs (the GMod Tower pack, Workshop 148215278, and the GTA accessories pack),
-- split into EVERYDAY stock (on sale from the start) and LIMITED / SEASONAL editions (off sale until you stock them
-- from the Stock window; each has a supply, so every copy is numbered and they never come back once sold out).
--
-- Everything here shows up in the admin menu's Catalog table where prices, supply and tier can be changed, and new
-- models can be added with the Browse button. Placement defaults to the slot's bone with no offset: tune each one
-- once with the placement editor (dubz_cosmetic_editor, "Put at my center" helps) and save it for ALL models.
--
-- Row format: {id, name, slot, model, price}                          everyday, on sale
--             {id, name, slot, model, price, credits, supply, tier}   limited / seasonal, off sale
local R = DubzCosmetics.Register

local SK = "models/captainbigbutt/skeyler/"
local GT = "models/gmod_tower/"
local LV = "models/lordvipes/"
local SAL = "models/sal/"
local MOD = "models/modified/"

-- EVERYDAY STOCK ---------------------------------------------------------------------------------------------------
local everyday = {
	-- GMod Tower: hats
	{"gt_baseballcap", "Baseball Cap", "hat", GT .. "baseballcap.mdl", 350},
	{"gt_fedorahat", "Fedora", "hat", GT .. "fedorahat.mdl", 500},
	{"gt_pimphat", "Pimp Hat", "hat", GT .. "pimphat.mdl", 900},
	{"gt_partyhat", "Party Hat", "hat", GT .. "partyhat.mdl", 150},
	{"gt_sombrero", "Sombrero", "hat", GT .. "sombrero.mdl", 500},
	{"gt_tophat", "Top Hat (Classic)", "hat", GT .. "tophat.mdl", 700},
	{"gt_drinkcap", "Drinking Cap", "hat", GT .. "drinkcap.mdl", 300},
	{"gt_kfcbucket", "Chicken Bucket", "hat", GT .. "kfcbucket.mdl", 350},
	{"gt_catears", "Cat Ears", "hat", GT .. "catears.mdl", 300},
	{"gt_afro", "Afro", "hat", GT .. "afro.mdl", 350},
	{"gt_headphones", "Headphones", "hat", GT .. "headphones.mdl", 600},
	{"sk_cowboyhat", "Cowboy Hat", "hat", SK .. "hats/cowboyhat.mdl", 600},
	{"sk_strawhat", "Straw Hat", "hat", SK .. "hats/strawhat.mdl", 400},
	{"sk_sunhat", "Sun Hat", "hat", SK .. "hats/sunhat.mdl", 380},
	{"sk_fedora", "Fedora (Colours)", "hat", SK .. "hats/fedora.mdl", 550},
	{"sk_bunny_ears", "Bunny Ears", "hat", SK .. "hats/bunny_ears.mdl", 300},
	{"sk_cat_ears", "Cat Ears (Soft)", "hat", SK .. "hats/cat_ears.mdl", 300},
	{"sk_heartband", "Heart Headband", "hat", SK .. "hats/heartband.mdl", 250},
	{"sk_starband", "Star Headband", "hat", SK .. "hats/starband.mdl", 250},
	{"sk_frog_hat", "Frog Hat", "hat", SK .. "hats/frog_hat.mdl", 450},
	{"sk_bear_hat", "Bear Hat", "hat", SK .. "hats/bear_hat.mdl", 450},
	{"sk_cat_hat", "Cat Hat", "hat", SK .. "hats/cat_hat.mdl", 450},
	-- GMod Tower: face
	{"gt_aviators", "Aviators", "face", GT .. "aviators.mdl", 450},
	{"gt_3dglasses", "3D Glasses", "face", GT .. "3dglasses.mdl", 300},
	{"gt_starglasses", "Star Glasses", "face", GT .. "starglasses.mdl", 350},
	{"gt_snowboardgoggles", "Snowboard Goggles", "face", GT .. "snowboardgoggles.mdl", 400},
	{"gt_klienerglasses", "Square Glasses", "face", GT .. "klienerglasses.mdl", 300},
	{"sk_glasses01", "Glasses 1", "face", SK .. "accessories/glasses01.mdl", 250},
	{"sk_glasses02", "Glasses 2", "face", SK .. "accessories/glasses02.mdl", 250},
	{"sk_glasses03", "Glasses 3", "face", SK .. "accessories/glasses03.mdl", 250},
	{"sk_glasses04", "Glasses 4", "face", SK .. "accessories/glasses04.mdl", 250},
	{"sk_monocle", "Monocle", "face", SK .. "accessories/monocle.mdl", 400},
	{"sk_mustache", "Mustache", "face", SK .. "accessories/mustache.mdl", 200},
	-- GTA pack
	{"gta_hat01", "Cap", "hat", MOD .. "hat01_fix.mdl", 350},
	{"gta_hat03", "Hat 3", "hat", MOD .. "hat03.mdl", 400},
	{"gta_hat04", "Hat 4", "hat", MOD .. "hat04.mdl", 400},
	{"gta_hat05", "Hat 5", "hat", MOD .. "hat05_fix.mdl", 400},
	{"gta_hat06", "Hat 6", "hat", MOD .. "hat06.mdl", 450},
	{"gta_hat07", "Hat 7", "hat", MOD .. "hat07.mdl", 450},
	{"gta_hat08", "Hat 8", "hat", MOD .. "hat08.mdl", 450},
	{"gta_headphones", "Studio Headphones", "hat", MOD .. "headphones.mdl", 650},
	{"gta_beerhat", "Beer Hat", "hat", SAL .. "acc/fix/beerhat.mdl", 350},
	{"gta_chefhat", "Chef Hat", "hat", SAL .. "acc/fix/cheafhat.mdl", 400},
	{"gta_glasses01", "Shades", "face", MOD .. "glasses01.mdl", 300},
	{"gta_glasses02", "Round Shades", "face", MOD .. "glasses02.mdl", 300},
	{"gta_bandana", "Bandana", "face", MOD .. "bandana.mdl", 250},
	{"gta_scarf", "Scarf", "neck", SAL .. "acc/fix/scarf01.mdl", 350},
}

for _, row in ipairs(everyday) do
	R({id = row[1], name = row[2], slot = row[3], model = row[4], tier = "common", price = row[5], shop = true})
end

-- LIMITED AND SEASONAL EDITIONS ------------------------------------------------------------------------------------
-- Off sale until you stock them. price = cash (0 = credits only), credits = credit price (0 = cash only).
local limited = {
	-- Halloween
	{"gt_halloween_pumpkinhat", "Pumpkin Head", "hat", GT .. "halloween_pumpkinhat.mdl", 4000, 25, 60, "seasonal"},
	{"gt_halloween_nightmarehat", "Nightmare Hat", "hat", GT .. "halloween_nightmarehat.mdl", 4500, 30, 50, "seasonal"},
	{"gt_halloween_jasonmask", "Hockey Mask", "face", GT .. "halloween_jasonmask.mdl", 5000, 35, 50, "seasonal"},
	{"gt_witchhat", "Witch Hat", "hat", GT .. "witchhat.mdl", 3500, 20, 60, "seasonal"},
	{"sk_pumpkin", "Jack-o'-Lantern", "hat", SK .. "hats/pumpkin.mdl", 4000, 25, 60, "seasonal"},
	{"gta_hw_skull", "Skull Mask", "face", SAL .. "halloween/skull.mdl", 5000, 35, 40, "seasonal"},
	{"gta_hw_zombie", "Zombie Mask", "face", SAL .. "halloween/zombie.mdl", 5000, 35, 40, "seasonal"},
	{"gta_hw_monkey", "Monkey Mask", "face", SAL .. "halloween/monkey.mdl", 5000, 35, 40, "seasonal"},
	{"gta_hw_ninja", "Ninja Mask", "face", SAL .. "halloween/ninja.mdl", 5000, 35, 40, "seasonal"},
	{"gta_hw_doctor", "Plague Doctor", "face", SAL .. "halloween/doctor.mdl", 6000, 45, 30, "seasonal"},
	{"gta_hw_bag", "Bag Head", "face", SAL .. "halloween/bag.mdl", 3000, 20, 60, "seasonal"},
	{"gta_hw_headwrap1", "Head Wrap", "face", SAL .. "halloween/headwrap1.mdl", 3000, 20, 60, "seasonal"},
	{"gta_hw_headwrap2", "Head Wrap 2", "face", SAL .. "halloween/headwrap2.mdl", 3000, 20, 60, "seasonal"},
	-- Christmas
	{"gt_santahat", "Santa Hat", "hat", GT .. "santahat.mdl", 2000, 12, 100, "seasonal"},
	{"sk_santa", "Santa Hat (Fluffy)", "hat", SK .. "hats/santa.mdl", 2500, 15, 80, "seasonal"},
	{"sk_maid_headband", "Maid Headband", "hat", SK .. "hats/maid_headband.mdl", 2500, 15, 80, "seasonal"},
	-- Thanksgiving
	{"gt_pilgrimhat", "Pilgrim Hat", "hat", GT .. "pilgrimhat.mdl", 2500, 15, 80, "seasonal"},
	{"gt_turkey", "Turkey", "hat", GT .. "turkey.mdl", 3500, 20, 50, "seasonal"},
	-- Limited editions (rare, numbered)
	{"sk_deadmau5", "Mouse Head", "hat", SK .. "hats/deadmau5.mdl", 60000, 300, 15, "limited"},
	{"sk_zhat", "Z Hat", "hat", SK .. "hats/zhat.mdl", 45000, 220, 20, "limited"},
	{"sk_devhat", "Developer Hat", "hat", SK .. "hats/devhat.mdl", 0, 500, 10, "limited"},
	{"sk_tophat02", "Gentleman's Top Hat", "hat", SK .. "hats/tophat02.mdl", 30000, 150, 30, "limited"},
	{"gt_king_boos_crown", "King's Crown", "hat", GT .. "king_boos_crown.mdl", 80000, 400, 10, "limited"},
	{"gt_balloonicorn", "Balloonicorn", "hat", GT .. "balloonicorn_nojiggle.mdl", 40000, 200, 20, "limited"},
	{"gt_headcrabhat", "Headcrab", "hat", GT .. "headcrabhat.mdl", 25000, 120, 40, "limited"},
	{"gt_bombermanhelmet", "Bomber Helmet", "hat", GT .. "bombermanhelmet.mdl", 30000, 150, 30, "limited"},
	{"gt_samushelmet", "Power Helmet", "hat", GT .. "samushelmet.mdl", 50000, 250, 15, "limited"},
	{"gt_legohead", "Brick Head", "hat", GT .. "legohead.mdl", 20000, 100, 40, "limited"},
	{"gt_rubikscube", "Puzzle Cube", "hat", GT .. "rubikscube.mdl", 15000, 80, 40, "limited"},
	{"gt_linkhat", "Hero's Cap", "hat", GT .. "linkhat.mdl", 35000, 175, 25, "limited"},
	{"gt_midnahat", "Twilight Hat", "hat", GT .. "midnahat.mdl", 35000, 175, 25, "limited"},
	{"gt_seusshat", "Striped Hat", "hat", GT .. "seusshat.mdl", 20000, 100, 40, "limited"},
	{"gt_teamrockethat", "Rocket Cap", "hat", GT .. "teamrockethat.mdl", 25000, 120, 40, "limited"},
	{"gt_toetohat", "Toe Hat", "hat", GT .. "toetohat.mdl", 20000, 100, 40, "limited"},
	{"gt_androssmask", "Andross Mask", "face", GT .. "androssmask.mdl", 30000, 150, 30, "limited"},
	{"gt_batmanmask", "Bat Mask", "face", GT .. "batmanmask.mdl", 40000, 200, 20, "limited"},
	{"gt_majorasmask", "Moon Mask", "face", GT .. "majorasmask.mdl", 45000, 220, 20, "limited"},
	{"gt_metaknight_mask", "Knight Mask", "face", GT .. "metaknight_mask.mdl", 35000, 175, 25, "limited"},
	{"gt_toromask", "Toro Mask", "face", GT .. "toromask.mdl", 30000, 150, 30, "limited"},
	{"gt_noface", "Faceless Mask", "face", GT .. "noface.mdl", 40000, 200, 20, "limited"},
	{"gt_jetpack", "Jetpack", "back", GT .. "jetpack.mdl", 90000, 450, 10, "limited"},
	{"gt_fairywings", "Fairy Wings", "back", GT .. "fairywings.mdl", 50000, 250, 20, "limited"},
	{"lv_mariohat", "Plumber Cap (Red)", "hat", LV .. "mariohat/mariohat.mdl", 40000, 200, 20, "limited"},
	{"lv_luigihat", "Plumber Cap (Green)", "hat", LV .. "luigihat/luigihat.mdl", 40000, 200, 20, "limited"},
	{"lv_peachcrown", "Princess Crown", "hat", LV .. "peachcrown/peachcrown.mdl", 60000, 300, 15, "limited"},
	{"lv_toadhat", "Mushroom Cap", "hat", LV .. "toadhat/toadhat.mdl", 40000, 200, 20, "limited"},
	{"lv_redshat", "Trainer Cap", "hat", LV .. "redshat/redshat.mdl", 35000, 175, 25, "limited"},
	{"lv_klonoahat", "Dream Cap", "hat", LV .. "klonoahat/klonoahat.mdl", 35000, 175, 25, "limited"},
	{"lv_blackmage_hat", "Black Mage Hat", "hat", LV .. "blackmage/blackmage_hat.mdl", 45000, 220, 20, "limited"},
	{"lv_generalpepperhat", "General's Hat", "hat", LV .. "generalpepperhat/generalpepperhat.mdl", 35000, 175, 25, "limited"},
	{"lv_billyhatcherhat", "Hatcher Hat", "hat", LV .. "billyhatcherhat/billyhatcherhat.mdl", 30000, 150, 30, "limited"},
	{"lv_servbothead", "Servbot Head", "hat", LV .. "servbothead/servbothead.mdl", 30000, 150, 30, "limited"},
	{"lv_cuboneskull", "Bone Skull", "face", LV .. "cuboneskull/cuboneskull.mdl", 45000, 220, 20, "limited"},
	{"lv_keatonmask", "Fox Mask", "face", LV .. "keatonmask/keatonmask.mdl", 35000, 175, 25, "limited"},
	{"lv_majoramask", "Majora Mask", "face", LV .. "majoramask/majoramask.mdl", 50000, 250, 15, "limited"},
	{"lv_makarmask", "Makar Mask", "face", LV .. "makarmask/makarmask.mdl", 35000, 175, 25, "limited"},
	{"lv_daftpunk", "Robot Helmet", "hat", LV .. "daftpunk/thomas.mdl", 70000, 350, 10, "limited"},
	{"lv_viewtifuljoe", "Hero Helmet", "hat", LV .. "viewtifuljoehelmet/viewtifuljoehelmet.mdl", 45000, 220, 20, "limited"},
	{"lv_blackmage_cape", "Black Mage Cape", "back", LV .. "blackmage/blackmage_cape.mdl", 50000, 250, 15, "limited"},
	-- Animal heads (GTA pack)
	{"gta_animal_bear", "Bear Head", "hat", SAL .. "bear.mdl", 20000, 100, 40, "limited"},
	{"gta_animal_cat", "Cat Head", "hat", SAL .. "cat.mdl", 20000, 100, 40, "limited"},
	{"gta_animal_fox", "Fox Head", "hat", SAL .. "fox.mdl", 20000, 100, 40, "limited"},
	{"gta_animal_owl", "Owl Head", "hat", SAL .. "owl.mdl", 20000, 100, 40, "limited"},
	{"gta_animal_penguin", "Penguin Head", "hat", SAL .. "penguin.mdl", 20000, 100, 40, "limited"},
	{"gta_animal_pig", "Pig Head", "hat", SAL .. "pig.mdl", 20000, 100, 40, "limited"},
	{"gta_animal_wolf", "Wolf Head", "hat", SAL .. "wolf.mdl", 25000, 120, 30, "limited"},
	{"gta_animal_hawk", "Hawk Head", "hat", SAL .. "hawk_1.mdl", 25000, 120, 30, "limited"},
	{"gta_animal_gingerbread", "Gingerbread Head", "hat", SAL .. "gingerbread.mdl", 15000, 80, 60, "limited"},
}

for _, row in ipairs(limited) do
	R({
		id = row[1], name = row[2], slot = row[3], model = row[4], tier = row[8],
		price = row[5], credits = row[6], supply = row[7], shop = false,
	})
end

-- Items that cover the face: wearing one swaps your overhead name for the "hidden identity" text
for _, id in ipairs({
	"gta_bandana", "gt_halloween_jasonmask", "gt_halloween_pumpkinhat", "sk_pumpkin", "gta_hw_skull", "gta_hw_zombie",
	"gta_hw_monkey", "gta_hw_ninja", "gta_hw_doctor", "gta_hw_bag", "gta_hw_headwrap1", "gta_hw_headwrap2",
	"gt_androssmask", "gt_batmanmask", "gt_majorasmask", "gt_metaknight_mask", "gt_toromask", "gt_noface",
	"lv_cuboneskull", "lv_keatonmask", "lv_majoramask", "lv_makarmask", "lv_daftpunk", "gt_samushelmet",
	"gt_bombermanhelmet", "gt_legohead", "gt_headcrabhat", "lv_servbothead",
	"gta_animal_bear", "gta_animal_cat", "gta_animal_fox", "gta_animal_owl", "gta_animal_penguin", "gta_animal_pig",
	"gta_animal_wolf", "gta_animal_hawk", "gta_animal_gingerbread",
}) do
	if DubzCosmetics.Econ[id] then DubzCosmetics.Econ[id].hides = true end
end
