-- Scrap, server side: how scrap and trash live in the pocket, scrapping (a bar, then the resources), counting scrap for the crafting
-- table, and melting metal in the forge.
--
-- Scrap and trash are ordinary pocket items: a record of class dubz_scrap / dubz_trash whose variant is the material or trash id, so
-- plastic and metal are different stacks. The colour and material live on the saved entity, which is how the pocket draws them.
util.AddNetworkString("DubzScrap_Start")    -- client -> server: pocket slot, scrap them all?
util.AddNetworkString("DubzScrap_Cancel")   -- client -> server: stop

local cfg = DubzScrap.Config

local function say(ply, text, kind)
	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind or 0, 5, text) else ply:ChatPrint(text) end
end

-- The pocket ---------------------------------------------------------------------------------------------------------------------

hook.Add("DubzInvMakeRecord", "DubzScrap_Record", function(ent)
	local class = ent:GetClass()
	if class ~= "dubz_scrap" and class ~= "dubz_trash" then return end

	local def = ent:GetDef()
	if not def then return end

	local data = DubzInv.SerializeEntity(ent)

	if class == "dubz_scrap" then
		-- State the look explicitly: the pocket draws the item with this colour and material
		local color = ent:GetColor()
		data.Color = {r = color.r, g = color.g, b = color.b, a = color.a}
		data.Material = ent:GetMaterial()
	end

	return {
		class = class, name = class == "dubz_scrap" and DubzScrap.ScrapName(def) or def.name, model = ent:GetModel(), qty = 1,
		variant = def.id, data = data,
	}
end)

hook.Add("DubzInvEntityVariant", "DubzScrap_Variant", function(ent)
	local class = ent:GetClass()
	if class == "dubz_scrap" or class == "dubz_trash" then return ent:GetMat() end
end)

hook.Add("DubzInvStackLimit", "DubzScrap_Stack", function(class)
	if class == "dubz_scrap" then return math.max(1, cfg.scrapStack) end
	if class == "dubz_trash" then return math.max(1, cfg.trashStack) end
end)

-- A pocket record for an amount of a scrap material (built from a real entity so it takes out of the pocket properly)
local function scrapRecord(id, amount)
	local ent = ents.Create("dubz_scrap")
	if not IsValid(ent) then return end

	ent:SetMat(id)
	ent:Spawn()

	local rec = hook.Run("DubzInvMakeRecord", ent)
	ent:Remove()

	if rec then rec.qty = amount end
	return rec
end

-- Put scrap in the pocket; what doesn't fit is dropped in front of the player
function DubzScrap.Give(ply, id, amount)
	if not (DubzScrap.Material(id) and DubzInv and DubzInv.AddItem) then return end

	local rec = scrapRecord(id, amount)
	if not rec then return end

	local data = table.Copy(rec.data)
	local added = DubzInv.AddItem(ply, rec)

	-- A stack that only partly fit has been trimmed to what was left over
	if not added then
		for _ = 1, math.min(rec.qty or 1, 8) do
			local ent = DubzInv.DeserializeEntity(ply, table.Copy(data))
			if not IsValid(ent) then break end
		end
	end
end

-- What the exchange starts from: a piece of scrap's Value, and trash is worth what it usually scraps into
hook.Add("DubzExchangeBaseValue", "DubzScrap_Value", function(class, variant)
	if class == "dubz_scrap" then
		local def = DubzScrap.Material(variant)
		return def and def.value
	end

	if class == "dubz_trash" then
		local def = DubzScrap.TrashType(variant)
		if not def then return end

		local total = 0
		for _, part in ipairs(DubzScrap.ParseYield(def.yields)) do
			total = total + (part.min + part.max) / 2 * (DubzScrap.Material(part.id).value or 0)
		end

		return total
	end
end)

-- Counting and taking scrap (for the crafting table) --------------------------------------------------------------------------

local function slotsOf(ply, id)
	local found = {}

	for index, rec in pairs(DubzInv.GetSlots(ply) or {}) do
		if rec.class == "dubz_scrap" and rec.variant == id then found[#found + 1] = index end
	end

	table.sort(found)
	return found
end

function DubzScrap.Count(ply, id)
	local total = 0
	for _, index in ipairs(slotsOf(ply, id)) do total = total + (DubzInv.GetSlots(ply)[index].qty or 1) end
	return total
end

function DubzScrap.Take(ply, id, amount)
	if DubzScrap.Count(ply, id) < amount then return false end

	for _, index in ipairs(slotsOf(ply, id)) do
		if amount <= 0 then break end

		local take = math.min(DubzInv.GetSlots(ply)[index].qty or 1, amount)
		DubzInv.TakeSlot(ply, index, take)
		amount = amount - take
	end

	return true
end

-- The crafting table asks these about every material in a recipe: answer for scrap, stay out of it for anything else
hook.Add("DubzMiningExtraCount", "DubzScrap_Count", function(ply, id)
	if DubzScrap.Material(id) then return DubzScrap.Count(ply, id) end
end)

hook.Add("DubzMiningExtraTake", "DubzScrap_Take", function(ply, id, amount)
	if DubzScrap.Material(id) then return DubzScrap.Take(ply, id, amount) end
end)

-- Scrapping ------------------------------------------------------------------------------------------------------------------------
-- Right click trash (or an accessory) in the pocket > Scrap. A bar fills, then the pocket gets what came out.

local function yieldsOf(rec)
	if rec.class == "dubz_trash" then
		local def = DubzScrap.TrashType(rec.variant)
		return def and def.yields
	end

	if rec.class == "dubz_cosmetic" then return cfg.accessoryYields end
end

local function stop(ply)
	if ply.DubzScrapping and ply.DubzScrapping.animated and DubzActions then
		ply.DubzScrapping = nil
		DubzActions.Cancel(ply)
	end

	ply.DubzScrapping = nil
	ply:SetNWFloat("dubz_scrap_start", 0)
	ply:SetNWString("dubz_scrap_name", "")
end

-- XP for searching a dumpster (the dumpster calls this) and for scrapping
function DubzScrap.GiveXP(ply, low, high)
	if not (IsValid(ply) and DubzSkills and DubzSkills.AddXP) then return end

	local amount = math.random(math.min(low, high), math.max(low, high))
	if amount > 0 then DubzSkills.AddXP(ply, "scavenging", amount) end
end

function DubzScrap.OnSearch(ply)
	DubzScrap.GiveXP(ply, cfg.searchXpMin, cfg.searchXpMax)
end

-- The work is acted out with the hands at work (dubz_actions) when that addon is installed; otherwise it is just a bar
local function actionsReady() return DubzActions and DubzActions.Start and DubzActions.Allowed and DubzActions.Allowed("scrap") end

local startOne, finishOne   -- (finishOne is defined below)

startOne = function(ply, work)
	local rec = DubzInv.GetSlots(ply)[work.slot]

	-- Moved or used up between one and the next
	if not rec or rec.class ~= work.class or rec.variant ~= work.variant then ply.DubzScrapping = nil return end

	local first = DubzScrap.ParseYield(yieldsOf(rec) or "")[1]
	local color = rec.data and rec.data.Color

	local started = DubzActions.Start(ply, "scrap", work.time, {
		label = "Scrapping " .. (rec.name or ""), model = rec.model, hint = first and first.id or "metal",
		color = istable(color) and color or nil, material = rec.data and rec.data.Material,
		onFinish = function()
			if IsValid(ply) and finishOne(ply, work) then
				work.left = work.left - 1

				if work.left > 0 then startOne(ply, work) return end
			end

			ply.DubzScrapping = nil
		end,
		onCancel = function() ply.DubzScrapping = nil end,
	})

	if not started then ply.DubzScrapping = nil end
end

local function begin(ply, slot, all)
	if ply.DubzScrapping or not ply:Alive() or not DubzScrap.Enabled() then return end

	local rec = DubzInv.GetSlots(ply)[slot]
	if not rec or not yieldsOf(rec) then say(ply, "There is nothing to salvage from that.", 1) return end

	-- A better scavenger scraps faster
	local time = cfg.scrapTime * (1 - DubzScrap.SpeedBonus(DubzScrap.Level(ply)) / 100)

	ply.DubzScrapping = {slot = slot, class = rec.class, variant = rec.variant, left = all and (rec.qty or 1) or 1, time = time, finish = CurTime() + time}

	if actionsReady() then
		ply.DubzScrapping.animated = true
		startOne(ply, ply.DubzScrapping)
		return
	end

	ply:SetNWFloat("dubz_scrap_start", CurTime())
	ply:SetNWFloat("dubz_scrap_time", time)
	ply:SetNWString("dubz_scrap_name", rec.name or "")
end

-- One thing is scrapped: out of the pocket, its resources in
finishOne = function(ply, work)
	local rec = DubzInv.GetSlots(ply)[work.slot]

	-- Moved or used up while the bar was filling
	if not rec or rec.class ~= work.class or rec.variant ~= work.variant then return false end

	local text = yieldsOf(rec)
	local name = rec.name

	DubzInv.TakeSlot(ply, work.slot, 1)

	local parts = {}
	local bonus = DubzScrap.BonusChance(DubzScrap.Level(ply))

	for _, got in ipairs(DubzScrap.RollYield(text)) do
		-- A good scavenger gets a little more out of it
		if math.random() * 100 < bonus then got.amount = got.amount + 1 end

		DubzScrap.Give(ply, got.id, got.amount)
		parts[#parts + 1] = got.amount .. " " .. DubzScrap.Material(got.id).name
	end

	say(ply, "Scrapped " .. name .. (#parts > 0 and (": " .. table.concat(parts, ", ") .. ".") or ": nothing useful."))
	DubzInv.PlaySound(ply, "pickup")
	DubzScrap.GiveXP(ply, cfg.scrapXpMin, cfg.scrapXpMax)

	return true
end

timer.Create("DubzScrap_Tick", 0.1, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local work = ply.DubzScrapping
		if not work or work.animated then continue end

		if not ply:Alive() then
			stop(ply)
		elseif CurTime() >= work.finish then
			if finishOne(ply, work) then
				work.left = work.left - 1

				if work.left > 0 then
					work.finish = CurTime() + work.time
					ply:SetNWFloat("dubz_scrap_start", CurTime())
				else
					stop(ply)
				end
			else
				stop(ply)
			end
		end
	end
end)

net.Receive("DubzScrap_Start", function(_, ply)
	local slot, all = net.ReadUInt(8), net.ReadBool()
	begin(ply, slot, all)
end)

net.Receive("DubzScrap_Cancel", function(_, ply) stop(ply) end)

hook.Add("DubzCharLeave", "DubzScrap_Leave", stop)
hook.Add("PlayerDisconnected", "DubzScrap_Disconnect", stop)

-- The forge melts metal scrap into bars ---------------------------------------------------------------------------------------------
-- The forge asks this about a piece of scrap that touches it: the first answer is whether it is taken in, the second which ingot to queue
-- (every few pieces of metal make one bar).
hook.Add("DubzMiningForgeAccepts", "DubzScrap_Forge", function(forge, ent)
	if ent:GetClass() ~= "dubz_scrap" or ent:GetMat() ~= cfg.meltScrap then return end

	forge.ScrapMelted = (forge.ScrapMelted or 0) + 1

	if forge.ScrapMelted >= math.max(1, cfg.meltPerBar) then
		forge.ScrapMelted = 0
		return true, cfg.meltBar
	end

	return true
end)
