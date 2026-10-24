DubzDarkRP.Kinds = DubzDarkRP.Kinds or {}
DubzDarkRP.Engines = DubzDarkRP.Engines or {}

local Kinds = DubzDarkRP.Kinds

Kinds.Order = {"jobs", "shipments", "entities", "ammo", "categories", "doorgroups"}
Kinds.ReplayOrder = {"categories", "jobs", "shipments", "entities", "ammo", "doorgroups"}

Kinds.Meta = {
    jobs = {label = "KindJobs", single = "KindJobsOne", icon = "darkrp/work", unique = "command", subtitle = "SubtitleJobs"},
    shipments = {label = "KindShipments", single = "KindShipmentsOne", icon = "darkrp/local_police", unique = "name", subtitle = "SubtitleShipments"},
    entities = {label = "KindEntities", single = "KindEntitiesOne", icon = "economy/inventory_2", unique = "cmd", subtitle = "SubtitleEntities"},
    ammo = {label = "KindAmmo", single = "KindAmmoOne", icon = "misc/bolt", unique = "ammoType", subtitle = "SubtitleAmmo"},
    categories = {
        label = "KindCategories", single = "KindCategoriesOne", icon = "misc/label", unique = "name", scope = "categorises",
        idFields = {"categorises", "name"}, group = "categorises", movable = false, subtitle = "SubtitleCategories"
    },
    doorgroups = {
        label = "KindDoorgroups", single = "KindDoorgroupsOne", icon = "misc/door", unique = "name",
        group = false, movable = false, count = "teams", subtitle = "SubtitleDoorgroups"
    }
}

function Kinds.Slug(text)
    local slug = string.gsub(string.lower(tostring(text or "")), "[^a-z0-9]+", "_")

    return (string.gsub(slug, "^_+", ""))
end

function Kinds.Subtitle(kind, data)
    local meta = Kinds.Meta[kind]
    local values = table.Copy(data)

    if meta.count then values.count = #(data[meta.count] or {}) end

    return DubzDarkRP.Phrase(meta.subtitle, values)
end

function Kinds.IdFor(kind, data)
    local meta = Kinds.Meta[kind]
    local parts = {}

    for _, key in ipairs(meta.idFields or {meta.unique}) do parts[#parts + 1] = tostring(data[key] or "") end

    local id = Kinds.Slug(table.concat(parts, "_"))

    return id ~= "" and id or Kinds.Slug(data.name)
end

function Kinds.Engine(kind)
    return DubzDarkRP.Engines[kind]
end
