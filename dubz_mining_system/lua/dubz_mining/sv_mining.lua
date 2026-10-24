-- Mining, server side: how gems, ingots and ore chunks live in the pocket, what the buyer and the crafting table do with
-- them, and the buyer's changing prices. (The rocks, forge and pickaxe are in their own entity / weapon files.)
--
-- Gems, ingots and ore chunks are ordinary pocket items: a record of class dubz_gem / dubz_ingot / dubz_stone whose variant is
-- the material id, so a ruby and a topaz are different stacks. The colour and shine live on the saved entity, which is how
-- the pocket draws them.
util.AddNetworkString("DubzMining_Buyer")      -- server -> client: the buyer's list (JSON)
util.AddNetworkString("DubzMining_Sell")       -- client -> server: material id, how many (0 = all), npc
util.AddNetworkString("DubzMining_Crafting")   -- server -> client: the recipe list (JSON)
util.AddNetworkString("DubzMining_Craft")      -- client -> server: recipe id, table

local cfg = DubzMining.Config

local ITEM_CLASSES = {dubz_gem = true, dubz_ingot = true, dubz_stone = true}

local function money(amount)
	return DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(amount) or ("$" .. amount)
end

local function say(ply, text, kind)
	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind or 0, 5, text) else ply:ChatPrint(text) end
end

-- The pocket ------------------------------------------------------------------------------------------------------------

hook.Add("DubzInvMakeRecord", "DubzMining_Record", function(ent)
	local class = ent:GetClass()
	if not ITEM_CLASSES[class] then return end

	-- An ore chunk is just an ore chunk: no material, no colour (it stacks with every other one)
	if class == "dubz_stone" then
		return {class = class, name = DubzMining.ItemName(class), model = ent:GetModel(), qty = 1, variant = "", data = DubzInv.SerializeEntity(ent)}
	end

	local material = DubzMining.Material(ent:GetMat())
	if not material then return end

	local data = DubzInv.SerializeEntity(ent)

	-- State the look explicitly: the pocket draws the item with this colour and material
	local color = ent:GetColor()
	data.Color = {r = color.r, g = color.g, b = color.b, a = color.a}
	data.Material = ent:GetMaterial()

	return {
		class = class, name = DubzMining.ItemName(class, material), model = ent:GetModel(), qty = 1,
		variant = material.id, data = data,
	}
end)

-- The pocket draws gems and ingots with the material set in the admin menu (Gem / Ingot Material), even ones saved with an older one,
-- and a gem or ingot taken out of the pocket gets it too
hook.Add("DubzInvLookMaterial", "DubzMining_Look", function(rec)
	if (rec.class == "dubz_gem" or rec.class == "dubz_ingot") and cfg.shine ~= "" then return cfg.shine end
end)

hook.Add("DubzInvDeployed", "DubzMining_DeployLook", function(ply, ent)
	if IsValid(ent) and (ent:GetClass() == "dubz_gem" or ent:GetClass() == "dubz_ingot") and cfg.shine ~= "" then ent:SetMaterial(cfg.shine) end
end)

hook.Add("DubzInvEntityVariant", "DubzMining_Variant", function(ent)
	if ent:GetClass() == "dubz_stone" then return "" end
	if ITEM_CLASSES[ent:GetClass()] then return ent:GetMat() end
end)

hook.Add("DubzInvStackLimit", "DubzMining_Stack", function(class)
	if ITEM_CLASSES[class] then return math.max(1, cfg.stackSize) end
end)

-- All the pocket slots (and the worn backpack's) that hold one material
local function slotsOf(ply, materialId)
	local found = {}

	for index, rec in pairs(DubzInv.GetSlots(ply) or {}) do
		if ITEM_CLASSES[rec.class] and rec.variant == materialId and rec.class ~= "dubz_stone" then found[#found + 1] = index end
	end

	table.sort(found)
	return found
end

-- How many of a material (gem or ingot) the player carries
function DubzMining.Count(ply, materialId)
	-- (other addons count their own materials: scrap)
	local extra = hook.Run("DubzMiningExtraCount", ply, materialId)
	if extra ~= nil then return extra end

	local total = 0
	for _, index in ipairs(slotsOf(ply, materialId)) do total = total + (DubzInv.GetSlots(ply)[index].qty or 1) end
	return total
end

-- Takes `amount` of a material out of the pocket. Returns false (and takes nothing) if there isn't enough.
function DubzMining.Take(ply, materialId, amount)
	if DubzMining.Count(ply, materialId) < amount then return false end

	local handled = hook.Run("DubzMiningExtraTake", ply, materialId, amount)
	if handled ~= nil then return handled end

	for _, index in ipairs(slotsOf(ply, materialId)) do
		if amount <= 0 then break end

		local have = DubzInv.GetSlots(ply)[index].qty or 1
		local take = math.min(have, amount)

		DubzInv.TakeSlot(ply, index, take)
		amount = amount - take
	end

	return true
end

-- What the exchange starts from for gems, ingots and ore chunks (until they sell there, then it follows the sales)
hook.Add("DubzExchangeBaseValue", "DubzMining_Value", function(class, variant)
	if class == "dubz_gem" or class == "dubz_ingot" then
		local material = DubzMining.Material(variant)
		return material and material.price
	end

	if class == "dubz_stone" then return DubzMining.AverageIngotPrice() * cfg.oreValue / 100 end
end)

-- Prices ----------------------------------------------------------------------------------------------------------------

DubzMining.PriceFactor = {}

local function refreshPrices()
	for id in pairs(DubzMining.Materials) do
		DubzMining.PriceFactor[id] = math.Round(math.Rand(math.min(cfg.buyerMinMultiplier, cfg.buyerMaxMultiplier), math.max(cfg.buyerMinMultiplier, cfg.buyerMaxMultiplier)), 2)
	end
end

function DubzMining.Price(materialId)
	local material = DubzMining.Material(materialId)
	if not material then return 0 end

	return math.floor(material.price * (DubzMining.PriceFactor[materialId] or 1))
end

timer.Create("DubzMining_Prices", 5, 0, function()
	-- (the interval is read live, so changing it in the admin menu applies without a restart)
	if CurTime() >= (DubzMining.NextPriceRefresh or 0) then
		DubzMining.NextPriceRefresh = CurTime() + math.max(10, cfg.buyerRefresh)
		refreshPrices()
	end
end)

-- The foreman's buying --------------------------------------------------------------------------------------------------
-- The mining foreman (the job NPC) opens this window from his conversation. He pays the going price times his rate.

local ORE = "*ore"   -- the id of the ore chunk row (ore chunks are anonymous, so they are one row)

-- The rows that are a whole kind of pocket item rather than one material: id -> the item class
local function special(id) return id == ORE and "dubz_stone" or nil end

local function rate() return cfg.foremanRate / 100 end

-- How many of a kind of pocket item (ore chunks) a player carries, and taking some
function DubzMining.ClassCount(ply, class)
	local total = 0
	for _, rec in pairs(DubzInv.GetSlots(ply) or {}) do
		if rec.class == class then total = total + (rec.qty or 1) end
	end
	return total
end

function DubzMining.TakeClass(ply, class, amount)
	if DubzMining.ClassCount(ply, class) < amount then return false end

	for index, rec in pairs(DubzInv.GetSlots(ply) or {}) do
		if amount <= 0 then break end

		if rec.class == class then
			local take = math.min(rec.qty or 1, amount)
			DubzInv.TakeSlot(ply, index, take)
			amount = amount - take
		end
	end

	return true
end

function DubzMining.OreCount(ply) return DubzMining.ClassCount(ply, "dubz_stone") end
function DubzMining.TakeOreCount(ply, amount) return DubzMining.TakeClass(ply, "dubz_stone", amount) end

-- What he pays for one of a thing right now, and what he usually pays
local function orePrice() return math.floor(DubzMining.AverageIngotPrice() * cfg.oreValue / 100 * rate()) end

local function sellPrice(id)
	if id == ORE then return orePrice() end
	return math.floor(DubzMining.Price(id) * rate())
end

local function usualPrice(id)
	if id == ORE then return orePrice() end

	local material = DubzMining.Material(id)
	return material and math.floor(material.price * rate()) or 0
end

local function foremanName(npc)
	local site = DubzJobs and DubzJobs.Sites and IsValid(npc) and npc.GetSite and DubzJobs.Sites[npc:GetSite()]
	return site and site.npc or "Foreman"
end

local function buyerList(ply, npc)
	local list = {{id = ORE, name = "Ore Chunk", kind = "ore", color = {130, 130, 130}, count = DubzMining.OreCount(ply), price = orePrice(), base = orePrice(), trend = 0}}

	for _, id in ipairs(DubzMining.Order) do
		local material = DubzMining.Materials[id]

		list[#list + 1] = {
			id = id, name = material.name, kind = material.kind, color = {material.color.r, material.color.g, material.color.b},
			count = DubzMining.Count(ply, id), price = sellPrice(id), base = usualPrice(id),
			-- how far the price is from the usual, in percent
			trend = math.Round(((DubzMining.PriceFactor[id] or 1) - 1) * 100),
		}
	end

	return util.TableToJSON({title = foremanName(npc), rate = cfg.foremanRate, items = list, owed = DubzMining.Owed(ply)})
end

function DubzMining.OpenBuyer(ply, npc)
	ply.DubzMiningNpc = npc

	net.Start("DubzMining_Buyer")
		net.WriteEntity(npc)
		net.WriteString(buyerList(ply, npc))
	net.Send(ply)
end

net.Receive("DubzMining_Sell", function(_, ply)
	local npc, id, amount, payDebt = net.ReadEntity(), net.ReadString(), net.ReadUInt(16), net.ReadBool()

	if not DubzMining.Enabled() or not IsValid(npc) or ply.DubzMiningNpc ~= npc then return end
	if ply:GetPos():Distance(npc:GetPos()) > cfg.useDistance * 1.5 then return end
	if (ply.DubzMiningNext or 0) > CurTime() then return end
	ply.DubzMiningNext = CurTime() + 0.3

	local total, pieces = 0, 0

	local function sell(thingId, howMany)
		local have = special(thingId) and DubzMining.ClassCount(ply, special(thingId)) or DubzMining.Count(ply, thingId)
		local count = (howMany == 0) and have or math.min(howMany, have)
		if count <= 0 then return end

		local price = sellPrice(thingId)
		local taken = special(thingId) and DubzMining.TakeClass(ply, special(thingId), count) or DubzMining.Take(ply, thingId, count)

		if taken then
			total = total + price * count
			pieces = pieces + count
		end
	end

	if id == "*" then
		sell(ORE, 0)
		for _, materialId in ipairs(DubzMining.Order) do sell(materialId, 0) end
	elseif special(id) or DubzMining.Material(id) then
		sell(id, amount)
	else
		return
	end

	if total > 0 then
		local paid = 0
		local owed = DubzMining.Owed(ply)

		if payDebt and owed > 0 then
			paid = math.min(owed, total)
			DubzMining.Settle(ply, paid)
		end

		ply:addMoney(total - paid)
		say(ply, "Sold " .. pieces .. " for " .. money(total) .. (paid > 0 and (", and " .. money(paid) .. " of it went to what you owed.") or "."))
	else
		say(ply, "You have nothing to sell.", 1)
	end

	DubzMining.OpenBuyer(ply, npc)
end)

-- The crafting table -------------------------------------------------------------------------------------------------------

-- The model shown for a recipe: its own, or the weapon's world model
function DubzMining.RecipeModel(recipe)
	if recipe.model and recipe.model ~= "" then return recipe.model end

	local swep = (recipe.kind == "weapon" or recipe.kind == "give") and weapons.Get(recipe.class)
	return swep and (swep.WorldModel or swep.Model) or ""
end

local function recipeList(ply)
	local list = {}
	local level = DubzMining.CraftLevel(ply)

	local sorted = {}
	for index, recipe in ipairs(DubzMining.Recipes) do sorted[index] = recipe end
	table.sort(sorted, function(a, b)
		if a.level ~= b.level then return a.level < b.level end
		return a.name < b.name
	end)

	for _, recipe in ipairs(sorted) do
		local items, canCraft = {}, level >= recipe.level

		for _, need in ipairs(DubzMining.ParseItems(recipe.items)) do
			local have = need.material and DubzMining.Count(ply, need.material.id) or 0
			local color = need.material and need.material.color or color_white

			if have < need.amount or not need.material then canCraft = false end
			items[#items + 1] = {name = need.material and need.material.name or need.name, need = need.amount, have = have, color = {color.r, color.g, color.b}}
		end

		list[#list + 1] = {id = recipe.id, name = recipe.name, model = DubzMining.RecipeModel(recipe), kind = recipe.kind, level = recipe.level, amount = recipe.amount or 1, items = items, can = canCraft}
	end

	return util.TableToJSON({title = cfg.craftingTitle, level = level, recipes = list})
end

function DubzMining.OpenCrafting(ply, tableEnt)
	net.Start("DubzMining_Crafting")
		net.WriteEntity(tableEnt)
		net.WriteString(recipeList(ply))
	net.Send(ply)
end

-- Puts the finished item where it belongs
local function deliver(ply, recipe, tableEnt)
	local spawnPos = tableEnt:LocalToWorld(Vector(0, 0, tableEnt:OBBMaxs().z + 5))

	-- Ammo is one handful of rounds (Makes = how many)
	if recipe.kind == "ammo" then
		ply:GiveAmmo(recipe.amount or 30, recipe.class, true)
		return
	end

	for _ = 1, recipe.amount or 1 do
		if recipe.kind == "give" then
			ply:Give(recipe.class)
		elseif recipe.kind == "weapon" then
			local pickup = ents.Create("spawned_weapon")
			if IsValid(pickup) then
				local model = DubzMining.RecipeModel(recipe)
				pickup:SetModel(model ~= "" and model or "models/weapons/w_crowbar.mdl")
				pickup:SetWeaponClass(recipe.class)
				pickup:SetPos(spawnPos)
				pickup:Spawn()
			end
		elseif recipe.kind == "accessory" then
			-- An accessory goes into the pocket (the class is the accessory's id from the Cosmetics catalog)
			if DubzCosmetics and DubzCosmetics.Give then DubzCosmetics.Give(ply, recipe.class) end
		elseif recipe.kind == "entity" then
			local ent = ents.Create(recipe.class)
			if IsValid(ent) then
				ent:SetPos(spawnPos)
				ent:Spawn()

				-- Owned by the player like anything bought in the shop
				if ent.Setowning_ent then ent:Setowning_ent(ply) end
				ent.SID = ply.SID
				if ent.CPPISetOwner then pcall(ent.CPPISetOwner, ent, ply) end

				local entry = DubzInv and DubzInv.ShopEntry and DubzInv.ShopEntry(recipe.class)
				if entry then
					ent.DarkRPItem = entry
					if ply.addCustomEntity then ply:addCustomEntity(entry) end
				end
			end
		end
	end
end

net.Receive("DubzMining_Craft", function(_, ply)
	local tableEnt, id = net.ReadEntity(), net.ReadString()

	if not DubzMining.Enabled() or not IsValid(tableEnt) or tableEnt:GetClass() ~= "dubz_crafting_table" then return end
	if ply:GetPos():Distance(tableEnt:GetPos()) > cfg.useDistance * 1.5 then return end
	if (ply.DubzMiningNext or 0) > CurTime() then return end
	ply.DubzMiningNext = CurTime() + 0.5

	local recipe
	for _, candidate in ipairs(DubzMining.Recipes) do
		if candidate.id == id then recipe = candidate break end
	end
	if not recipe then return end

	if DubzMining.CraftLevel(ply) < recipe.level then say(ply, "You need crafting level " .. recipe.level .. " for that.", 1) return end

	-- Everything must be there before anything is taken
	local needs = DubzMining.ParseItems(recipe.items)
	for _, need in ipairs(needs) do
		if not need.material or DubzMining.Count(ply, need.material.id) < need.amount then
			say(ply, "You don't have everything for that.", 1)
			return
		end
	end

	-- A printer or other limited entity can't be crafted past the player's deploy limit
	if recipe.kind == "entity" and DubzInv and DubzInv.CanDeploy then
		local allowed, message = DubzInv.CanDeploy(ply, {class = recipe.class}, recipe.amount or 1)
		if allowed < (recipe.amount or 1) then say(ply, message or "You can't have more of those.", 1) return end
	end

	-- The craft itself. With the hands-at-work addon it happens after the animation, so everything is checked again then.
	local function complete()
		if not (IsValid(ply) and IsValid(tableEnt)) then return end

		for _, need in ipairs(needs) do
			if DubzMining.Count(ply, need.material.id) < need.amount then say(ply, "You don't have everything for that any more.", 1) return end
		end

		for _, need in ipairs(needs) do DubzMining.Take(ply, need.material.id, need.amount) end

		deliver(ply, recipe, tableEnt)

		-- Crafting teaches: the more you make, the more you can make
		local xp = DubzMining.RecipeXP(recipe)
		if DubzSkills and DubzSkills.AddXP then DubzSkills.AddXP(ply, "crafting", xp) end

		say(ply, "Crafted " .. recipe.name .. " (+" .. xp .. " crafting XP).")

		net.Start("DubzMining_Crafting")
			net.WriteEntity(tableEnt)
			net.WriteString(recipeList(ply))
		net.Send(ply)
	end

	-- Bigger things take longer
	local seconds = cfg.craftTime + (recipe.level or 1) * cfg.craftTimePerLevel

	if seconds > 0 and DubzActions and DubzActions.Start and DubzActions.Allowed and DubzActions.Allowed("craft") then
		local started = DubzActions.Start(ply, "craft", seconds, {
			label = "Crafting " .. recipe.name, model = DubzMining.RecipeModel(recipe), hint = "craft",
			onFinish = function() complete() end,
		})

		if not started then say(ply, "You're busy right now.", 1) end
		return
	end

	complete()
end)

-- Mining XP -----------------------------------------------------------------------------------------------------------

function DubzMining.GiveXP(ply)
	local amount = math.random(math.min(cfg.xpMin, cfg.xpMax), math.max(cfg.xpMin, cfg.xpMax))

	if amount > 0 and DubzSkills and DubzSkills.AddXP then DubzSkills.AddXP(ply, "mining", amount) end
	return amount
end

-- Smelting an ore chunk is Mining XP too
function DubzMining.GiveSmeltXP(ply)
	if not (IsValid(ply) and ply:IsPlayer()) then return 0 end

	local amount = math.random(math.min(cfg.smeltXpMin, cfg.smeltXpMax), math.max(cfg.smeltXpMin, cfg.smeltXpMax))
	if amount > 0 and DubzSkills and DubzSkills.AddXP then DubzSkills.AddXP(ply, "mining", amount) end

	return amount
end

-- Ore chunks in the pocket, for the forge (Alt+E on it loads them). Removes them and returns how many there were.
function DubzMining.TakeOre(ply)
	local count = 0
	if not (DubzInv and DubzInv.GetSlots) then return count end

	for index, rec in pairs(DubzInv.GetSlots(ply) or {}) do
		if rec.class == "dubz_stone" then
			count = count + (rec.qty or 1)
			DubzInv.TakeSlot(ply, index)
		end
	end

	return count
end

-- The foreman's tab: minecart rental -----------------------------------------------------------------------------------
-- A minecart costs nothing to take. It is billed per rental period out (Minecart Rent), and the bill is paid when it is returned or
-- when selling ("pay now or later"). What is not paid stays on the character's tab.

local function debtKey(ply)
	return "dubz_mining_owed_" .. ((DubzChars and DubzChars.GetKey and DubzChars.GetKey(ply)) or ply:SteamID64() or "0")
end

function DubzMining.Debt(ply)
	return tonumber(ply:GetPData(debtKey(ply), "0")) or 0
end

local function setDebt(ply, amount)
	ply:SetPData(debtKey(ply), tostring(math.max(0, math.floor(amount))))
end

-- The rental fee so far for the cart that is out (at least one period)
function DubzMining.RentOwed(ply)
	local rent = ply.DubzMiningRent
	if not rent then return 0 end

	local periods = math.max(1, math.ceil((CurTime() - rent.start) / (60 * math.max(cfg.cartRentMinutes, 1))))
	return math.max(cfg.cartRentFee * periods - rent.paid, 0)
end

function DubzMining.Owed(ply)
	return DubzMining.Debt(ply) + DubzMining.RentOwed(ply)
end

-- Take `amount` off what is owed (the old tab first, then the cart that is out)
function DubzMining.Settle(ply, amount)
	local fromTab = math.min(amount, DubzMining.Debt(ply))
	setDebt(ply, DubzMining.Debt(ply) - fromTab)

	if ply.DubzMiningRent then ply.DubzMiningRent.paid = ply.DubzMiningRent.paid + (amount - fromTab) end
end

-- The cart goes back (or is lost): the fee so far is put on the tab. Returns the amount.
local function closeRental(ply)
	local rent = ply.DubzMiningRent
	if not rent then return 0 end

	local fee = DubzMining.RentOwed(ply)
	if IsValid(rent.cart) then rent.cart:Remove() end
	ply.DubzMiningRent = nil

	setDebt(ply, DubzMining.Debt(ply) + fee)
	return fee
end

hook.Add("PlayerDisconnected", "DubzMining_Rental", closeRental)
hook.Add("DubzCharLeave", "DubzMining_Rental", closeRental)

local function rentCart(ply, npc)
	if ply.DubzMiningRent then return "message", "You've still got one of mine out. Bring it back first." end
	if DubzMining.Owed(ply) > 0 then return "message", "Settle what you owe me first, then we'll talk carts." end

	local cart = ents.Create("dubz_cart")
	if not IsValid(cart) then return "message", "I'm all out of carts." end

	cart:SetPos(npc:GetPos() + npc:GetForward() * 70 + Vector(0, 0, 25))
	cart:SetAngles(Angle(0, npc:GetAngles().y, 0))
	cart:Spawn()

	ply.DubzMiningRent = {cart = cart, start = CurTime(), paid = 0}

	local hours = cfg.cartRentMinutes % 60 == 0 and (cfg.cartRentMinutes / 60 .. " hour(s)") or (cfg.cartRentMinutes .. " minutes")
	return "message", "There's your cart. " .. money(cfg.cartRentFee) .. " for every " .. hours .. " it's out. Bring it back when you're done, and I'll settle up then, or when you sell."
end

local function returnCart(ply, npc)
	local rent = ply.DubzMiningRent
	if not rent then return "message", "You don't have one of mine." end

	if IsValid(rent.cart) and rent.cart:GetPos():Distance(npc:GetPos()) > 700 then
		return "message", "Bring the cart back here first. I'm not walking down the tunnel for it."
	end

	local lost = not IsValid(rent.cart)
	local fee = closeRental(ply)

	if ply:canAfford(fee) then
		ply:addMoney(-fee)
		setDebt(ply, DubzMining.Debt(ply) - fee)
		return "message", (lost and "Lost it? It happens. " or "") .. "That's " .. money(fee) .. " for the cart. Thanks."
	end

	return "message", (lost and "Lost it? It happens. " or "") .. "That's " .. money(fee) .. " for the cart, and you can't cover it. I'll put it on your tab. Take it out of what you sell next."
end

local function payTab(ply)
	local owed = DubzMining.Debt(ply)
	if owed <= 0 then return "message", "You don't owe me anything." end

	local pay = math.min(owed, math.max(ply:getDarkRPVar("money") or 0, 0))
	if pay <= 0 then return "message", "You haven't got anything on you. Sell some ore and I'll take it from that." end

	ply:addMoney(-pay)
	setDebt(ply, owed - pay)

	return "message", pay >= owed and "Paid in full. Good." or ("Took " .. money(pay) .. ". You still owe " .. money(owed - pay) .. ".")
end

-- ...as entries in the foreman's conversation (dubz_jobs): shown for the miner site
hook.Add("DubzJobsExtraOptions", "DubzMining_Foreman", function(ply, site, options)
	if site.job ~= "miner" or not DubzMining.Enabled() then return end

	local function npc() return ply.DubzJobsTalk and ply.DubzJobsTalk.npc end

	options[#options + 1] = {
		label = "I want to sell my gems and ore.", close = true,
		action = function() if IsValid(npc()) then DubzMining.OpenBuyer(ply, npc()) end end,
	}

	if ply.DubzMiningRent then
		options[#options + 1] = {label = "I'm bringing the minecart back.", action = function() return returnCart(ply, npc()) end}
	elseif DubzJobs and DubzJobs.IsHired(ply, site) then
		options[#options + 1] = {label = "I need a minecart (" .. money(cfg.cartRentFee) .. " per rental period).", action = function() return rentCart(ply, npc()) end}
	end

	if DubzMining.Debt(ply) > 0 then
		options[#options + 1] = {label = "I'll pay what I owe (" .. money(DubzMining.Debt(ply)) .. ").", action = function() return payTab(ply) end}
	end
end)

-- Coal was taken out of mining: any a character was still carrying (pocket or worn backpack) is removed when they come in, so it isn't left as an
-- item nothing can use.
hook.Add("DubzCharLoad", "DubzMining_DropOldCoal", function(ply)
	timer.Simple(1, function()
		if not IsValid(ply) or not (DubzInv and DubzInv.GetSlots and DubzInv.TakeSlot) then return end

		for index, rec in pairs(DubzInv.GetSlots(ply) or {}) do
			if rec.class == "dubz_coal" then DubzInv.TakeSlot(ply, index, rec.qty or 1) end
		end
	end)
end)
