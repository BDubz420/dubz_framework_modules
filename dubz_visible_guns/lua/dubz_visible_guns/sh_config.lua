DubzVisibleGuns = DubzVisibleGuns or {}

local Config = DubzVisibleGuns.Config or {}
DubzVisibleGuns.Config = Config

Config.MaxPistols = 2
Config.MaxRifles = 2

Config.DefaultPistolModel = "models/weapons/w_pistol.mdl"
Config.DefaultRifleModel = "models/weapons/w_rif_m4a1.mdl"

Config.IgnoreWeapons = {
    weapon_physgun = true,
    weapon_physcannon = true,
    gmod_tool = true,
    gmod_camera = true,
    keys = true,
    pocket = true,
    weapon_fists = true,
    weapon_medkit = true,

    act3_axe = true,
    act3_base = true,
    act3_base_grenade = true,
    act3_base_melee = true,
    act3_base_thingy = true,
    act3_crowbar = true,
    act3_flashlight = true,
    act3_hands = true,
    act3_knife = true,
    act3_laser = true,
    act3_nade_c4 = true,
    act3_nade_case = true,
    act3_nade_frag = true,
    act3_nade_knife = true,
    act3_nade_smoke = true,
    act3_nade_stun = true,
    act3_pbshield = true,
    act3_pipe = true,
    act3_steelshield = true
}

-- Exact class overrides. Add your server's custom weapon classes here.
-- type must be "pistol" or "rifle". model is optional; WorldModel is used when omitted.
Config.WeaponOverrides = {
    weapon_pistol = { type = "pistol", model = "models/weapons/w_pistol.mdl" },
    weapon_357 = { type = "pistol", model = "models/weapons/w_357.mdl" },
    weapon_smg1 = { type = "pistol", kind = "smg", model = "models/weapons/w_smg1.mdl" },
    weapon_ar2 = { type = "rifle", model = "models/weapons/w_irifle.mdl" },
    weapon_shotgun = { type = "rifle", model = "models/weapons/w_shotgun.mdl" },
    weapon_crossbow = { type = "rifle", model = "models/weapons/w_crossbow.mdl" },

    act3_blackhawk = { type = "pistol", model = "models/weapons/act3/pistol_blackhawk.mdl" },
    act3_c96 = { type = "pistol", model = "models/weapons/act3/pistol_c96.mdl" },
    act3_deagle = { type = "pistol", model = "models/weapons/act3/pistol_deagle.mdl" },
    act3_fiveseven = { type = "pistol", model = "models/weapons/act3/pistol_fiveseven.mdl" },
    act3_g17 = { type = "pistol", model = "models/weapons/act3/pistol_g17.mdl" },
    act3_m11 = { type = "pistol", kind = "smg", model = "models/weapons/act3/smg_m10.mdl" },
    act3_m1911 = { type = "pistol", model = "models/weapons/act3/pistol_m1911.mdl" },
    act3_m9 = { type = "pistol", model = "models/weapons/act3/pistol_m9.mdl" },
    act3_model29 = { type = "pistol", model = "models/weapons/act3/pist_model29.mdl" },
    act3_p1 = { type = "pistol", model = "models/weapons/act3/pistol_p1.mdl" },
    act3_p220 = { type = "pistol", model = "models/weapons/act3/pistol_p220.mdl" },
    act3_usp = { type = "pistol", model = "models/weapons/act3/pistol_usp.mdl" },

    act3_ak = { type = "rifle", model = "models/weapons/act3/rifle_ak.mdl" },
    act3_ar = { type = "rifle", model = "models/weapons/act3/rifle_ar.mdl" },
    act3_atxa2 = { type = "rifle", model = "models/weapons/act3/launcher_atxa2.mdl" },
    act3_aug = { type = "rifle", model = "models/weapons/act3/rifle_aug.mdl" },
    act3_awp = { type = "rifle", model = "models/weapons/act3/rifle_awp.mdl" },
    act3_bar = { type = "rifle", model = "models/weapons/act3/mg_bar.mdl" },
    act3_bazooka = { type = "rifle", model = "models/weapons/act3/launcher_bazooka.mdl" },
    act3_cdte = { type = "rifle", model = "models/weapons/act3/launcher_cdte.mdl" },
    act3_g3 = { type = "rifle", model = "models/weapons/act3/rifle_g3.mdl" },
    act3_garand = { type = "rifle", model = "models/weapons/act3/rifle_garand.mdl" },
    act3_k98 = { type = "rifle", model = "models/weapons/act3/rifle_k98.mdl" },
    act3_lior = { type = "rifle", model = "models/weapons/act3/shot_lior.mdl" },
    act3_m1014 = { type = "rifle", model = "models/weapons/act3/shot_m1014.mdl" },
    act3_m122 = { type = "rifle", model = "models/weapons/act3/rifle_m122.mdl" },
    act3_m1919 = { type = "rifle", model = "models/weapons/act3/mg_m1919.mdl" },
    act3_m203 = { type = "rifle", model = "models/weapons/act3/launcher_m203.mdl" },
    act3_m249 = { type = "rifle", model = "models/weapons/act3/mg_m249.mdl" },
    act3_m3 = { type = "rifle", model = "models/weapons/act3/shot_m3.mdl" },
    act3_mg3 = { type = "rifle", model = "models/weapons/act3/mg_mg3.mdl" },
    act3_minigun = { type = "rifle", model = "models/weapons/act3/mg_minigun.mdl" },
    act3_mp40 = { type = "pistol", kind = "smg", model = "models/weapons/act3/smg_mp40.mdl" },
    act3_mp5 = { type = "pistol", kind = "smg", model = "models/weapons/act3/smg_mp5.mdl" },
    act3_musket = { type = "rifle", model = "models/weapons/act3/musket_brownbess.mdl" },
    act3_ou = { type = "rifle", model = "models/weapons/act3/shot_dbou.mdl" },
    act3_p90 = { type = "pistol", kind = "smg", model = "models/weapons/act3/smg_p90.mdl" },
    act3_rpg7 = { type = "rifle", model = "models/weapons/act3hd/launcher_rpg7.mdl" },
    act3_scout = { type = "rifle", model = "models/weapons/act3/rifle_scout.mdl" },
    act3_sg552 = { type = "rifle", model = "models/weapons/act3/rifle_sg552.mdl" },
    act3_stg44 = { type = "rifle", model = "models/weapons/act3/rifle_stg44.mdl" },
    act3_tgewehr = { type = "rifle", model = "models/weapons/act3/rifle_tankgewehr.mdl" },
    act3_thompson = { type = "pistol", kind = "smg", model = "models/weapons/act3/smg_thompson.mdl" },
    act3_ump = { type = "pistol", kind = "smg", model = "models/weapons/act3/smg_ump.mdl" }
}

-- Pattern fallback for weapon classes not listed above.
Config.TypePatterns = {
    pistol = {
        "pistol",
        "revolver",
        "deagle",
        "glock",
        "usp",
        "m9",
        "m1911",
        "five",
        "sidearm"
    },
    rifle = {
        "rifle",
        "ar2",
        "ak",
        "m4",
        "m16",
        "smg",
        "shotgun",
        "sniper",
        "scout",
        "awp",
        "mp5",
        "ump",
        "p90",
        "aug",
        "scar",
        "famas",
        "galil",
        "crossbow",
        "launcher"
    }
}

-- Placement uses player bones plus local offsets/angles.
-- pos = Vector(forward/back, left/right, up/down) relative to the bone.
-- ang = Angle(pitch, yaw, roll) relative to the bone.
Config.Slots = {
    rifles = {
        {
            name = "Back Rifle Left",
            bone = "ValveBiped.Bip01_Spine2",
            pos = Vector(-3, -3, 10.5),
            ang = Angle(0, 180, 180),
            scale = 1
        },
        {
            name = "Back Rifle Right",
            bone = "ValveBiped.Bip01_Spine2",
            pos = Vector(-3, -3, -10.5),
            ang = Angle(0, 180, 0),
            scale = 1
        }
    },
    pistols = {
        {
            name = "Front Waist Pistol",
            bone = "ValveBiped.Bip01_Pelvis",
            pos = Vector(-7, 3, 4),
            ang = Angle(165, 80, 90),
            scale = 1
        },
        {
            name = "Back Waist Pistol",
            bone = "ValveBiped.Bip01_Pelvis",
            pos = Vector(7, 3, 3),
            ang = Angle(170, 80, 260),
            scale = 1
        }
    }
}

-- Submachine guns hang from the hips with the pistols (the two hip slots are shared), but sit differently because they are bigger.
-- Placement for the hip slots a submachine gun takes (index = which hip slot).
Config.Slots.smgs = {
    {
        name = "Left Hip SMG",
        bone = "ValveBiped.Bip01_Pelvis",
        pos = Vector(-6, 5, 5),
        ang = Angle(170, 90, 90),
        scale = 1
    },
    {
        name = "Right Hip SMG",
        bone = "ValveBiped.Bip01_Pelvis",
        pos = Vector(6, 5, 4),
        ang = Angle(175, 90, 260),
        scale = 1
    }
}

-- The rifles' back slots change with what is on the back: nothing, a Small Backpack or a Big Backpack (the backpack sits behind the
-- guns, so they are moved out to clear it). "none" is the Slots.rifles table above; the others are that table moved by an offset
-- (forward/back, left/right, up/down on the bone). The offsets below are a starting point: tune them live with  dvg_adjust  (client console):
--     dvg_adjust small y 1.5     then   dvg_adjust_print   to see the numbers to copy here.
Config.BackShift = {
    none  = Vector(0, 0, 0),
    small = Vector(0, 4.5, 0.5),
    big   = Vector(0, 7.5, 1.5)
}

function DubzVisibleGuns.BackKey(size)
    if size == "small" or size == "big" then return size end

    return "none"
end

-- Submachine guns
Config.TypePatterns.smg = {
    "smg", "mp5", "mp7", "mp40", "mp9", "ump", "p90", "uzi", "mac10", "mac-10", "tmp", "thompson", "kriss", "vector"
}

function DubzVisibleGuns.GetWeaponRule(class)
    class = string.lower(class or "")

    if Config.IgnoreWeapons[class] then return nil end

    local override = Config.WeaponOverrides[class]
    if override then return override end

    for _, pattern in ipairs(Config.TypePatterns.smg) do
        if string.find(class, pattern, 1, true) then
            return { type = "pistol", kind = "smg" }
        end
    end

    for weaponType, patterns in pairs(Config.TypePatterns) do
        if weaponType ~= "smg" then   -- (submachine guns were checked above)
            for _, pattern in ipairs(patterns) do
                if string.find(class, pattern, 1, true) then
                    return { type = weaponType }
                end
            end
        end
    end

    return nil
end

function DubzVisibleGuns.GetFallbackModel(weaponType)
    if weaponType == "pistol" then
        return Config.DefaultPistolModel
    end

    return Config.DefaultRifleModel
end

-- Slot ids and placement overrides ------------------------------------------------------------------------------------------------------------
-- Every spot a gun can hang has an id: back_none_1 / back_small_1 / back_big_1 (and _2) for the rifles' back slots with nothing, a Small
-- Backpack or a Big Backpack on the back; pistol_1 / pistol_2 for pistols on the hips; smg_1 / smg_2 for submachine guns on the hips.
-- The tables above are the defaults. The placement editor (dvg_editor, superadmins) saves a replacement for any slot; those live in
-- Config.Overrides (id -> {pos, ang, scale}), are kept on the server and sent to every player.
Config.Overrides = Config.Overrides or {}
DubzVisibleGuns.Resolved = {}   -- cache: id -> the slot to draw

function DubzVisibleGuns.AllSlotIds()
    local list = {}

    for _, variant in ipairs({ { "none", "no backpack" }, { "small", "Small Backpack" }, { "big", "Big Backpack" } }) do
        for index = 1, #Config.Slots.rifles do
            list[#list + 1] = { id = "back_" .. variant[1] .. "_" .. index, name = "Back rifle " .. index .. " (" .. variant[2] .. ")", type = "rifle" }
        end
    end

    for index = 1, #Config.Slots.pistols do list[#list + 1] = { id = "pistol_" .. index, name = "Hip " .. index .. " (pistol)", type = "pistol" } end
    for index = 1, #(Config.Slots.smgs or {}) do list[#list + 1] = { id = "smg_" .. index, name = "Hip " .. index .. " (submachine gun)", type = "smg" } end

    return list
end

-- The slot to draw for an id: the saved override if there is one, otherwise the default (moved out by BackShift for the backpack variants)
function DubzVisibleGuns.ResolveSlot(id)
    local cached = DubzVisibleGuns.Resolved[id]
    if cached then return cached end

    local base, shift
    local variant, index = string.match(id, "^back_(%a+)_(%d+)$")

    if variant then
        base = Config.Slots.rifles[tonumber(index)]
        shift = Config.BackShift[variant]
    else
        local kind, number = string.match(id, "^(%a+)_(%d+)$")
        base = kind == "smg" and Config.Slots.smgs[tonumber(number)] or Config.Slots.pistols[tonumber(number)]
    end

    if not base then return nil end

    local override = Config.Overrides[id]
    local slot

    if override then
        slot = { bone = base.bone, pos = override.pos, ang = override.ang, scale = override.scale or base.scale or 1 }
    else
        slot = { bone = base.bone, pos = base.pos + (shift or Vector(0, 0, 0)), ang = base.ang, scale = base.scale or 1 }
    end

    DubzVisibleGuns.Resolved[id] = slot
    return slot
end

function DubzVisibleGuns.SetOverrides(tableOfSlots)
    Config.Overrides = {}
    Config.GunTweaks = {}

    for id, row in pairs(tableOfSlots or {}) do
        if istable(row.pos) and istable(row.ang) then
            -- "gun:<class>" is one gun that sits differently from the rest (an offset in the slot's own space); anything else is a slot
            local target = Config.Overrides
            local key = id

            if string.sub(id, 1, 4) == "gun:" then target, key = Config.GunTweaks, string.sub(id, 5) end

            target[key] = {
                pos = Vector(row.pos[1], row.pos[2], row.pos[3]),
                ang = Angle(row.ang[1], row.ang[2], row.ang[3]),
                scale = tonumber(row.scale) or 1,
            }
        end
    end

    DubzVisibleGuns.Resolved = {}
end

-- Settings the admin menu edits (!dubzconfig > Visible Weapons; see sh_framework.lua). These are the defaults.
Config.ShowActive = false         -- also show the weapon in your hands on your body (off: only the ones you are NOT holding)
Config.HolsterGesture = true      -- a small gesture when the visible list changes (a gun put away or picked up)
Config.DrawDistance = 1500        -- other players further away than this don't have their guns drawn
Config.DisabledSlots = {}         -- set of slot groups switched off: back_1, back_2, hip_1, hip_2
Config.GunTweaks = Config.GunTweaks or {}   -- class -> {pos, ang, scale}: a gun that sits differently from the others (the editor's "this gun only")

function DubzVisibleGuns.SlotOff(group, index)
    return Config.DisabledSlots[group .. "_" .. index] == true
end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzVisibleGuns.Enabled()
    return not (DFW and DFW.Bind) or DFW.Bind.Enabled("visible_guns")
end
