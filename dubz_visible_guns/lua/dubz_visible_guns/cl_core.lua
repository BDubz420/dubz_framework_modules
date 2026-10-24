if not CLIENT then return end

DubzVisibleGuns = DubzVisibleGuns or {}

local TAG = "DubzVisibleGuns"
local visibleWeapons = {}
local modelCache = {}

CreateClientConVar("dvg_enabled", "1", true, false, "Enable Dubz Visible Guns clientside drawing.")

local function IsEnabled()
    if not DubzVisibleGuns.Enabled() then return false end

    local cvar = GetConVar("dvg_enabled")
    return not cvar or cvar:GetBool()
end

local function RemoveModel(model)
    if IsValid(model) then
        model:Remove()
    end
end

local function ClearPlayerModels(ply)
    local cache = modelCache[ply]
    if not cache then return end

    for _, model in pairs(cache) do
        RemoveModel(model)
    end

    modelCache[ply] = nil
end

local function ClearAllModels()
    for ply in pairs(modelCache) do
        ClearPlayerModels(ply)
    end
end

local function SafeModel(model, weaponType)
    if model and model ~= "" and util.IsValidModel(model) then
        return model
    end

    local fallback = DubzVisibleGuns.GetFallbackModel(weaponType)
    if util.IsValidModel(fallback) then
        return fallback
    end

    return "models/weapons/w_pistol.mdl"
end

local function EnsureModel(ply, key, desiredModel, scale)
    modelCache[ply] = modelCache[ply] or {}

    local existing = modelCache[ply][key]
    if IsValid(existing) and existing.DVGModelPath == desiredModel then
        existing:SetModelScale(scale or 1, 0)
        return existing
    end

    RemoveModel(existing)

    local model = ClientsideModel(desiredModel, RENDERGROUP_OPAQUE)
    if not IsValid(model) then return nil end

    model:SetNoDraw(true)
    model:SetModelScale(scale or 1, 0)
    model.DVGModelPath = desiredModel
    modelCache[ply][key] = model

    return model
end

local function RemoveUnusedModels(ply, usedKeys)
    local cache = modelCache[ply]
    if not cache then return end

    for key, model in pairs(cache) do
        if not usedKeys[key] then
            RemoveModel(model)
            cache[key] = nil
        end
    end
end

-- Where a slot is on a player, in the world: its bone plus the slot's offsets. Used by the drawing here and by the placement editor.
function DubzVisibleGuns.SlotWorld(ply, slot)
    local boneIndex = ply:LookupBone(slot.bone or "")
    if not boneIndex then return end

    local matrix = ply:GetBoneMatrix(boneIndex)
    if not matrix then return end

    return LocalToWorld(slot.pos or Vector(0, 0, 0), slot.ang or Angle(0, 0, 0), matrix:GetTranslation(), matrix:GetAngles())
end

local function DrawSlotModel(ply, weaponData, slotId, weaponType, usedKeys)
    if not weaponData or weaponData.empty then return end

    -- The slot being placed in the editor is drawn by the editor instead
    if ply == LocalPlayer() and DubzVisibleGuns.EditorSlot == slotId then return end

    local slot = DubzVisibleGuns.ResolveSlot(slotId)
    if not slot then return end

    local pos, ang = DubzVisibleGuns.SlotWorld(ply, slot)
    if not pos then return end

    -- A gun that sits differently from the others (its model's origin is somewhere else) has its own offset, applied in the slot's space
    local scale = slot.scale or 1
    local tweak = DubzVisibleGuns.Config.GunTweaks[weaponData.class or ""]

    if tweak then
        pos, ang = LocalToWorld(tweak.pos, tweak.ang, pos, ang)
        scale = scale * (tweak.scale or 1)
    end

    local modelPath = SafeModel(weaponData.model, weaponType)
    local key = slotId
    local model = EnsureModel(ply, key, modelPath, scale)
    if not IsValid(model) then return end

    usedKeys[key] = true

    model:SetRenderOrigin(pos)
    model:SetRenderAngles(ang)
    model:SetupBones()
    model:DrawModel()
end

local function DrawPlayerWeapons(ply)
    if not IsEnabled() then return end
    if not IsValid(ply) or not ply:Alive() then return end

    local data = visibleWeapons[ply]
    if not data then return end

    if ply ~= LocalPlayer() and ply:GetPos():DistToSqr(EyePos()) > DubzVisibleGuns.Config.DrawDistance ^ 2 then return end

    local usedKeys = {}

    -- Three back variants: nothing on the back, a Small Backpack or a Big Backpack (read from the inventory addon; none if it isn't there).
    -- Each has its own placement for the rifles, so they clear the backpack.
    local size = (DubzInv and DubzInv.BagSize) and DubzInv.BagSize(ply) or ""
    local variant = DubzVisibleGuns.BackKey(size)

    for index, weaponData in ipairs(data.rifles or {}) do
        DrawSlotModel(ply, weaponData, "back_" .. variant .. "_" .. index, "rifle", usedKeys)
    end

    -- The hips: pistols and submachine guns share the two slots; a submachine gun uses its own placement for the slot it is in
    for index, weaponData in ipairs(data.pistols or {}) do
        DrawSlotModel(ply, weaponData, (weaponData.kind == "smg" and "smg_" or "pistol_") .. index, "pistol", usedKeys)
    end

    RemoveUnusedModels(ply, usedKeys)
end

net.Receive("DubzVisibleGuns_Update", function()
    local ply = net.ReadEntity()
    local json = net.ReadString()

    if not IsValid(ply) then return end

    local decoded = util.JSONToTable(json or "") or { pistols = {}, rifles = {} }

    visibleWeapons[ply] = decoded
    ClearPlayerModels(ply)
end)

-- The saved placements from the editor
net.Receive("DubzVG_Overrides", function()
    DubzVisibleGuns.SetOverrides(util.JSONToTable(net.ReadString()) or {})
end)

hook.Add("PostPlayerDraw", TAG .. "_DrawModels", DrawPlayerWeapons)

hook.Add("EntityRemoved", TAG .. "_CleanupPlayer", function(ent)
    if ent:IsPlayer() then
        visibleWeapons[ent] = nil
        ClearPlayerModels(ent)
    end
end)

hook.Add("ShutDown", TAG .. "_Cleanup", ClearAllModels)

concommand.Add("dvg_client_clear", function()
    visibleWeapons = {}
    ClearAllModels()
end)
