-- Store clerks (clothing and accessories): the buy flow. The clerks themselves are plain spawn-menu entities
-- (Dubz Cosmetics category): spawn them and make them permanent with a perma-props tool; this addon does no
-- spawning or saving of its own.
util.AddNetworkString("DubzCos_OpenStore")   -- server -> client: open a store (npc, kind)
util.AddNetworkString("DubzCos_Buy")         -- client -> server: buy an accessory / change clothing (npc, kind, id, id2)

local cfg = DubzCosmetics.Config
local say = DubzCosmetics.Say

local function isNpc(ent)
	return IsValid(ent) and string.StartWith(ent:GetClass(), "dubz_cos_npc")
end

-- Buying -----------------------------------------------------------------------------------------------------

local function charge(ply, price)
	if price <= 0 then return true end
	if ply.canAfford and not ply:canAfford(price) then return false end

	ply:addMoney(-price)
	return true
end

local function money(amount)
	return (DarkRP and DarkRP.formatMoney) and DarkRP.formatMoney(amount) or ("$" .. amount)
end

net.Receive("DubzCos_Buy", function(_, ply)
	local npc = net.ReadEntity()
	local kind = net.ReadString()
	local id = net.ReadString()
	local id2 = net.ReadString()   -- clothing: the clothing set to wear with the look in `id`

	if (ply.DubzCosBuyNext or 0) > CurTime() then return end
	ply.DubzCosBuyNext = CurTime() + 0.5

	if not DubzCosmetics.Enabled() then return end
	if not ply:Alive() or not isNpc(npc) or npc:GetKind() ~= kind then return end
	if ply:GetPos():Distance(npc:GetPos()) > cfg.npcUseDistance * 1.6 then return end

	if kind == "accessories" then
		-- id2 says how to pay: "credits" (premium currency) or anything else = cash
		local useCredits = id2 == "credits"

		local function priceOf(cash, credits) return useCredits and credits or cash end
		local function pay(price)
			if price <= 0 then return false end

			if useCredits then
				if not (DubzCredits and DubzCredits.GetBalance) or DubzCredits:GetBalance(ply) < price then return false end
				DubzCredits:Take(ply, price)
				return true
			end

			return charge(ply, price)
		end
		local function refund(price)
			if useCredits then DubzCredits:Add(ply, price) else ply:addMoney(price) end
		end
		local function cost(price) return useCredits and (price .. " credits") or money(price) end

		-- The backpack: put it straight on (you can only wear one)
		if id == "backpack" or id == "backpack_small" then
			local small = id == "backpack_small"
			local price = small and priceOf(cfg.backpackSmallPrice, cfg.backpackSmallCredits) or priceOf(cfg.backpackPrice, cfg.backpackCredits)
			if price <= 0 then say(ply, "The backpack can't be bought that way.") return end
			if not (DubzInv and DubzInv.WearBag and DubzInv.HasBag) then return end
			if DubzInv.HasBag(ply) then say(ply, "You already wear a backpack.") return end
			if not pay(price) then say(ply, "You can't afford that (" .. cost(price) .. ").") return end

			local bag = ents.Create(small and "dubz_backpack_small" or "dubz_backpack")
			if not IsValid(bag) then
				refund(price)
				say(ply, "Backpacks aren't available right now.")
				return
			end

			bag:SetModel(small and DubzInv.Config.smallBagModel or DubzInv.Config.bagModel)
			bag:SetSlots(small and DubzInv.Config.smallBagSlots or DubzInv.Config.bagSlots)
			bag:SetPos(ply:GetPos() + Vector(0, 0, 20))
			bag:Spawn()

			DubzInv.WearBag(ply, bag)
			say(ply, "You bought a " .. (small and "small" or "big") .. " backpack for " .. cost(price) .. " and put it on.")
			return
		end

		local def = DubzCosmetics.Get(id)
		if not def or def.virtual or not DubzCosmetics.IsForSale(id) then say(ply, "That isn't for sale right now.") return end

		local econ = DubzCosmetics.GetEcon(id)
		local price = priceOf(econ.price, econ.credits)
		if price <= 0 then say(ply, "That can't be bought that way.") return end
		if not pay(price) then say(ply, "You can't afford that (" .. cost(price) .. ").") return end

		-- Limited editions: take the next numbered copy (nil = it just sold out)
		local serialId = DubzCosmetics.Mint(id)
		if not serialId then
			refund(price)
			say(ply, def.name .. " has sold out.")
			return
		end

		local ok, reason = DubzCosmetics.Give(ply, serialId)
		if not ok then
			refund(price)
			-- Give the number back so a full pocket doesn't burn a limited copy
			local serial = DubzCosmetics.Serial(serialId)
			if serial and DubzCosmetics.Minted[id] == serial then
				DubzCosmetics.Minted[id] = serial - 1
				sql.Query("REPLACE INTO dubz_cos_minted (id, n) VALUES (" .. sql.SQLStr(id) .. ", " .. (serial - 1) .. ")")
			end
			say(ply, reason or "Your pocket is full.")
			return
		end

		say(ply, "You bought " .. DubzCosmetics.DisplayName(serialId) .. " for " .. cost(price) .. ". It's in your pocket.")
	elseif kind == "clothing" then
		if DubzCosmetics.OnTheClock(ply) then say(ply, "You're on the clock. Quit your job before you change your clothes.") return end

		-- One purchase covers a new look (face) and/or a clothing set you don't own yet
		local face, clothing = DubzCosmetics.GetFace(id), DubzCosmetics.GetClothing(id2)
		if not face or not clothing then return end
		if not DubzCosmetics.ModelFor(id, id2) then say(ply, "That combination isn't available.") return end

		local newLook = DubzCosmetics.GetLookId(ply) ~= id
		local newClothes = not DubzCosmetics.OwnsClothing(ply, id2)
		local changesClothes = DubzCosmetics.GetClothingId(ply) ~= id2

		if not newLook and not changesClothes then return end

		local price = (newLook and cfg.lookPrice or 0) + (newClothes and (cfg.clothingPrices[id2] or 0) or 0)
		if not charge(ply, price) then say(ply, "You can't afford that (" .. money(price) .. ").") return end

		if newLook then DubzCosmetics.SetLook(ply, id) end
		if newClothes then DubzCosmetics.UnlockClothing(ply, id2) end
		DubzCosmetics.WearClothing(ply, id2)
		DubzCosmetics.ApplyOutfit(ply)

		say(ply, "You changed into " .. face.name .. " in " .. clothing.name .. (price > 0 and (" for " .. money(price)) or "") .. ".")
	end
end)
