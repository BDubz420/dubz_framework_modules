-- Clothing and looks. A player model has two parts you can change separately:
--   LOOK      who you are: gender + face (male_01 ... female_07), the "person". Changing it costs Config.lookPrice.
--   CLOTHING  what you wear: a clothing set (Citizen clothes, Rebel gear, Medic uniform ...), each priced and
--             owned separately (Config.clothingPrices). The final model is the clothing set's version of your look,
--             for example models/player/group03/male_02.mdl.
-- Add clothing sets with DubzCosmetics.RegisterClothing{id, name, folder, bodygroups = {[groupIndex] = value}, skin = n};
-- bodygroups and skin are applied on top of the model, and a set may have no folder at all (then it is just the
-- default model with those bodygroups / skin, which is how uniforms on custom models will work). folder is the models/player/<folder> the
-- set's models live in. Sets whose model files aren't installed are skipped for that look.
DubzCosmetics.Faces = {}
DubzCosmetics.FaceOrder = {}
DubzCosmetics.Clothing = {}
DubzCosmetics.ClothingOrder = {}

function DubzCosmetics.RegisterFace(def)
	if not DubzCosmetics.Faces[def.id] then table.insert(DubzCosmetics.FaceOrder, def.id) end
	DubzCosmetics.Faces[def.id] = def
end

function DubzCosmetics.RegisterClothing(def)
	if not DubzCosmetics.Clothing[def.id] then table.insert(DubzCosmetics.ClothingOrder, def.id) end
	DubzCosmetics.Clothing[def.id] = def
end

function DubzCosmetics.GetFace(id) return DubzCosmetics.Faces[id or ""] end
function DubzCosmetics.GetClothing(id) return DubzCosmetics.Clothing[id or ""] end

-- The model for a look wearing a clothing set, or nil if those files aren't installed
function DubzCosmetics.ModelFor(faceId, clothingId)
	local clothing = DubzCosmetics.GetClothing(clothingId)
	if not clothing or not DubzCosmetics.GetFace(faceId) then return nil end

	-- A set without its own folder is made of bodygroups / a skin on the default set's model (a uniform worn on the
	-- same body); sets with a folder are separate models
	local folder = clothing.folder
	if not folder then
		local default = DubzCosmetics.GetClothing(DubzCosmetics.DefaultClothing)
		folder = default and default.folder or "group01"
	end

	local path = "models/player/" .. folder .. "/" .. faceId .. ".mdl"
	if file.Exists(path, "GAME") then return path end
end

-- The default citizen faces
for i = 1, 9 do
	DubzCosmetics.RegisterFace({id = "male_0" .. i, name = "Male " .. i, gender = "Male"})
end

for _, i in ipairs({1, 2, 3, 4, 6, 7}) do
	DubzCosmetics.RegisterFace({id = "female_0" .. i, name = "Female " .. i, gender = "Female"})
end

-- Clothing sets (the first one is what everybody owns and starts in)
DubzCosmetics.RegisterClothing({id = "citizen", name = "Citizen Clothes", folder = "group01"})
DubzCosmetics.RegisterClothing({id = "rebel", name = "Rebel Gear", folder = "group03"})
DubzCosmetics.RegisterClothing({id = "medic", name = "Medic Uniform", folder = "group03m"})

DubzCosmetics.DefaultClothing = "citizen"

-- What a player has chosen. "" look = the job's own model.
function DubzCosmetics.GetLookId(ply)
	return ply:GetNWString("dubz_outfit", "")
end

function DubzCosmetics.GetClothingId(ply)
	local id = ply:GetNWString("dubz_clothes", "")
	return id ~= "" and id or DubzCosmetics.DefaultClothing
end

-- The clothing sets a player owns (the default set always counts)
function DubzCosmetics.OwnsClothing(ply, id)
	if id == DubzCosmetics.DefaultClothing then return true end

	for owned in string.gmatch(ply:GetNWString("dubz_clothes_owned", ""), "[^,]+") do
		if owned == id then return true end
	end

	return false
end
