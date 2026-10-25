DubzDarkRP.Config = {
    AuditLog = true,
    AuditFile = "dubz_darkrp_audit.txt",
    ApplyOnBoot = true,
    MaxJobs = 128,
    MaxItems = 512,
    EditCooldown = 0.5,
    SyncCooldown = 5,
    VoteSeconds = 20,

    EditorCommand = "dubz_drp",
    BoardWidth = 1500,
    BoardHeight = 860,
    ColumnWidth = 280,
    DrawerWidth = 430,

    Text = {
        Console = "Console",
        Created = "Created {job}.",
        Updated = "Updated {job}.",
        Removed = "Removed {job}.",
        Reset = "Reset {job}.",
        NotFound = "Nothing with id {id}.",
        Invalid = "Not saved: {reason}.",
        NoAccess = "You do not have access to DarkRP management.",
        NeedVote = "This job requires a vote.",
        NeedAdmin = "This job is restricted to staff.",
        JobRemoved = "This job has been removed.",
        CommandHelp = "Become {job}.",
        CommandVoteHelp = "Vote to become {job}.",
        VoteQuestion = "{name} wants to be {job}",
        VoteDenied = "{name} was not made {job}.",
        ShopRemoved = "This item has been removed.",
        ShopHelp = "Purchase {item}.",
        ShopBought = "You bought {item} for {price}.",
        ShopCantAfford = "You can't afford {item}.",
        ShopLimit = "You have reached the limit for {item}.",
        ShopWrongJob = "Your job can't buy {item}.",
        ShopDead = "You must be alive to buy {item}.",
        ShopFailed = "{item} could not be created.",
        ShopNotAllowed = "You are not allowed to buy {item}.",
        TabDefaults = "Disabled Defaults",
        TabSettings = "Settings",
        AddDefault = "Add a default...",
        DefaultsHint = "Turn a default off to remove it from the server, or on to bring it back. Defaults you turn off stay off, so you can redefine them on their own board.",
        DefaultsSearch = "Search defaults",
        DefaultsEmpty = "No defaults match.",
        DefaultsGroup = "{kind} defaults",
        SettingsHint = "Changes apply right away and are remembered. A few settings only take effect after a map change.",
        SettingsSearch = "Search settings",
        SettingsEmpty = "No settings match.",
        SettingsReset = "Reset",
        SettingsDefault = "Default: {value}",
        SettingSaved = "Setting saved.",
        SettingWasReset = "Setting reset to its default.",
        SettingUnknown = "That setting does not exist.",
        SettingInvalid = "That value is not valid for this setting.",
        SettingGeneral = "General setting",
        PickerWeapons = "Browse weapons",
        WeaponsTitle = "Weapon browser",
        WeaponsSearch = "Search weapons",
        WeaponsOther = "Other",
        WeaponsCount = "{count} weapons",
        PickerProps = "Browse props",
        PropsTitle = "Prop browser",
        PropsSearch = "Search props",
        PropsEmpty = "No props found.",
        PickerAmmoModels = "Pick model",
        AmmoModelsTitle = "Ammo model",
        AmmoModelCustom = "Custom model path",
        UseModel = "Use model",
        ModelCount = "{count} models",
        KindJobs = "Jobs",
        KindShipments = "Shipments",
        KindEntities = "Entities",
        KindAmmo = "Ammo",
        KindJobsOne = "job",
        KindShipmentsOne = "shipment",
        KindEntitiesOne = "entity",
        KindAmmoOne = "ammo",
        KindCategories = "Categories",
        KindCategoriesOne = "category",
        KindDoorgroups = "Door groups",
        KindDoorgroupsOne = "door group",
        SubtitleCategories = "{categorises}  sort {sortOrder}",
        SubtitleDoorgroups = "{count} jobs",
        FieldCategorises = "Applies to",
        FieldSortOrder = "Sort order",
        FieldStartExpanded = "Starts expanded in menus",
        FieldTeams = "Jobs allowed (job ids)",
        SubtitleJobs = "${salary}  /{command}",
        SubtitleShipments = "${price}  x{amount}",
        SubtitleEntities = "${price}  /{cmd}",
        SubtitleAmmo = "${price}  {amountGiven} rounds",
        BoardTitle = "{kind} Board",
        BoardHint = "Drag {kind} cards between categories and edit them live for every player.",
        OpenBoard = "Open board",
        EditorTitle = "Dubz DarkRP Management",
        ShortcutTitle = "Dubz DarkRP Management",
        ShortcutHint = "Open the economy board in its own window. Close this menu yourself if you only want the board.",
        EditorSubtitle = "Changes apply live to every player",
        BoardSearch = "Search cards...",
        NewItem = "New {kind}",
        NewCategory = "New category",
        NewCategoryHint = "Category name:",
        Uncategorized = "Uncategorized",
        EmptyColumn = "Drop cards here",
        DrawerNew = "New entry",
        Save = "Save",
        SaveAll = "Save",
        UnsavedChanges = "Unsaved changes",
        DiscardTitle = "Discard changes?",
        DiscardHint = "You have unsaved changes. Discard them?",
        DiscardConfirm = "Discard",
        CloseTitle = "Close without saving?",
        CloseHint = "You have unsaved changes. They will not be saved if you close the menu.",
        CloseConfirm = "Close anyway",
        ResetChanges = "Reset",
        ShowRemoved = "Show removed",
        TagDraft = "New",
        PickerModels = "Browse models",
        PickerJobs = "Pick jobs",
        ModelsTitle = "Player models",
        ModelsSearch = "Search models...",
        JobsTitle = "Pick jobs",
        AddSelected = "Add selected",
        ClearSelection = "Clear",
        Apply = "Apply",
        SelectedCount = "{count} selected",
        FieldAllowed = "Jobs allowed to buy (empty means everyone)",
        Duplicate = "Duplicate",
        Remove = "Remove",
        Restore = "Restore original",
        Close = "Close",
        CopySuffix = "copy",
        TagRemoved = "Removed",
        TagCustom = "Custom",
        TagEdited = "Edited",
        TagPlaceholder = "Type or paste, then press space",
        FieldName = "Name",
        FieldCommand = "Command",
        FieldCategory = "Category",
        FieldDescription = "Description",
        FieldSalary = "Salary",
        FieldMax = "Max players (0 unlimited, under 1 is a share)",
        FieldAdmin = "Staff level (0 none, 1 admin, 2 superadmin)",
        FieldVote = "Requires a vote",
        FieldHasLicense = "Starts with a gun license",
        FieldCandemote = "Can be demoted",
        FieldColor = "Colour",
        FieldModel = "Models",
        FieldWeapons = "Weapons",
        FieldShipmentsModel = "Model path",
        FieldEntitiesModel = "Model path",
        FieldAmmoModel = "Model path",
        FieldPrice = "Price",
        FieldEntity = "Weapon class",
        FieldAmount = "Weapons per shipment",
        FieldSeparate = "Also sold separately",
        FieldPricesep = "Single weapon price",
        FieldNoship = "Single only, no shipment",
        FieldEnt = "Entity class",
        FieldCmd = "Buy command",
        FieldEntitiesMax = "Max owned per player",
        FieldAmmoType = "Ammo type",
        FieldAmountGiven = "Rounds per purchase",
        ReasonKind = "Unknown economy area",
        ReasonRequired = "{field} is required",
        ReasonLength = "{field} is too long",
        ReasonCommand = "The command may only use lowercase letters, numbers and underscores",
        ReasonDuplicate = "That is already used by {job}",
        ReasonLimit = "The limit has been reached",
        ReasonDisabled = "DarkRP management is switched off",
        ReasonUnavailable = "DarkRP is not ready yet"
    }
}

function DubzDarkRP.Phrase(key, values)
    local text = DubzDarkRP.Config.Text[key] or key

    for name, value in pairs(values or {}) do
        text = string.Replace(text, "{" .. name .. "}", tostring(value))
    end

    return text
end

DubzDarkRP.Lists = {chat_commands = {"!drp", "/drp"}}

function DubzDarkRP.List(id)
    local module = DFW and DFW.Collections

    if module and module.GetDefinition("drp_core", id) then
        return module.ListFromRows(module.Get("drp_core", id), "value")
    end

    return table.Copy(DubzDarkRP.Lists[id] or {})
end

DubzDarkRP.AmmoModelDefaults = {
    {name = "Small pistol box", model = "models/items/boxsrounds.mdl"},
    {name = "Medium rifle box", model = "models/items/boxmrounds.mdl"},
    {name = ".357 box", model = "models/items/357ammo.mdl"},
    {name = "Shotgun shells", model = "models/items/boxbuckshot.mdl"},
    {name = "Combine rifle cartridge", model = "models/items/combine_rifle_cartridge01.mdl"},
    {name = "Crossbow bolts", model = "models/items/crossbowrounds.mdl"}
}

function DubzDarkRP.AmmoModels()
    local module = DFW and DFW.Collections

    if module and module.GetDefinition("drp_core", "ammo_models") then
        return module.Get("drp_core", "ammo_models")
    end

    return DubzDarkRP.AmmoModelDefaults
end

function DubzDarkRP.Enabled()
    return not (DFW and DFW.Bind) or DFW.Bind.Enabled("drp_core")
end
