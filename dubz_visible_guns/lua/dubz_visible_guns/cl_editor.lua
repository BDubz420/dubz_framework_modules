-- Placement editor (superadmins): pick a slot, pick a gun to show in it, move and turn it with sliders while you watch it on your own player model
-- (the camera swings round to third person), then save. Saved placements apply to everyone. Open with the dvg_editor console command.
-- Two things can be edited:
--   * the SLOT: where every gun in that slot sits (back with no backpack / a Small / a Big one, the two hips for pistols, the two for submachine guns)
--   * ONE GUN: an offset for a single weapon class that doesn't line up with the others (its model's origin is somewhere else). It is applied
--     on top of whatever slot the gun is in, so it only has to be set once.
-- Built the same way as the accessory placement editor (dubz_cosmetic_editor).
local frame
local catcher
local preview   -- the clientside gun being placed

local cam = { yaw = 0, pitch = 10, dist = 100, height = 40 }

hook.Add("ShouldDrawLocalPlayer", "DubzVG_Editor", function()
    if IsValid(frame) then return true end
end)

hook.Add("CalcView", "DubzVG_Editor", function(ply, origin, angles, fov)
    if not IsValid(frame) then return end

    local center = ply:GetPos() + Vector(0, 0, cam.height)
    local pos = center + Angle(cam.pitch, ply:EyeAngles().y + cam.yaw, 0):Forward() * cam.dist

    return { origin = pos, angles = (center - pos):Angle(), fov = fov, drawviewer = true }
end)

-- A transparent panel behind the window that listens for the orbit controls: hold right mouse and drag to orbit, wheel to zoom
local function makeCatcher()
    if IsValid(catcher) then catcher:Remove() end

    catcher = vgui.Create("EditablePanel")
    catcher:SetSize(ScrW(), ScrH())
    catcher:SetPos(0, 0)
    catcher:SetKeyboardInputEnabled(false)
    catcher:MakePopup()
    catcher:SetPopupStayAtBack(true)
    catcher.Paint = function() end

    catcher.OnMousePressed = function(self, code)
        if IsValid(frame) then frame:MoveToFront() end
        if code ~= MOUSE_RIGHT then return end

        self.Dragging, self.LastX, self.LastY = true, gui.MouseX(), gui.MouseY()
        self:MouseCapture(true)
    end

    catcher.OnMouseReleased = function(self)
        self.Dragging = false
        self:MouseCapture(false)
    end

    catcher.Think = function(self)
        if not self.Dragging then return end
        if not input.IsMouseDown(MOUSE_RIGHT) then self.Dragging = false self:MouseCapture(false) return end

        local x, y = gui.MouseX(), gui.MouseY()
        cam.yaw = cam.yaw - (x - self.LastX) * 0.4
        cam.pitch = math.Clamp(cam.pitch + (y - self.LastY) * 0.3, -60, 75)
        self.LastX, self.LastY = x, y
    end

    catcher.OnMouseWheeled = function(_, delta)
        cam.dist = math.Clamp(cam.dist - delta * 8, 25, 240)
    end
end

-- What is being edited. `slot` and `gun` are each {pos, ang, scale}; `mode` says which one the sliders change.
local state = {
    id = nil, bone = "ValveBiped.Bip01_Spine2", mode = "slot", kind = "rifle",
    slot = { pos = Vector(), ang = Angle(), scale = 1 },
    gun = { pos = Vector(), ang = Angle(), scale = 1 },
    class = nil, model = nil,
}

local function current() return state.mode == "gun" and state.gun or state.slot end

-- The gun, drawn live: the slot's placement, then the gun's own offset on top
hook.Add("PostPlayerDraw", "DubzVG_EditorDraw", function(ply)
    if not IsValid(frame) or ply ~= LocalPlayer() or not state.id or not state.model then return end

    local pos, ang = DubzVisibleGuns.SlotWorld(ply, { bone = state.bone, pos = state.slot.pos, ang = state.slot.ang })
    if not pos then return end

    local scale = state.slot.scale

    -- (editing the slot shows the gun with the offset already saved for it; editing the gun shows the offset being made)
    local offset = state.mode == "gun" and state.gun or (state.class and DubzVisibleGuns.Config.GunTweaks[state.class])

    if offset then
        pos, ang = LocalToWorld(offset.pos, offset.ang, pos, ang)
        scale = scale * (offset.scale or 1)
    end

    if not IsValid(preview) or preview.DVGPath ~= state.model then
        if IsValid(preview) then preview:Remove() end

        preview = ClientsideModel(state.model, RENDERGROUP_OPAQUE)
        if not IsValid(preview) then return end

        preview:SetNoDraw(true)
        preview.DVGPath = state.model
    end

    preview:SetModelScale(scale, 0)
    preview:SetRenderOrigin(pos)
    preview:SetRenderAngles(ang)
    preview:SetupBones()
    preview:DrawModel()
end)

-- A caption over a framework slider
local function slider(parent, label, min, max, value, decimals, onChange)
    local caption = vgui.Create("DFW.Label", parent)
    caption:Dock(TOP)
    caption:SetTall(18)
    caption:DockMargin(2, 4, 2, 0)
    caption:SetStyle("small")
    caption:SetText(label)

    local s = vgui.Create("DFW.Slider", parent)
    s:Dock(TOP)
    s:SetTall(22)
    s:DockMargin(2, 0, 2, 0)
    s:SetRange(min, max)
    s:SetDecimals(decimals or 2)
    s:SetValue(value, true)
    s.OnValueChanged = function(_, v) onChange(v) end
    return s
end

local function open()
    if not LocalPlayer():IsSuperAdmin() then return end
    if not (DFW and DFW.UI and DFW.UI.CreateFrame) then return end
    if IsValid(frame) then frame:Remove() end

    makeCatcher()

    frame = DFW.UI.CreateFrame("Weapon placement", 380, 700, nil, { compact = true })
    frame:SetPos(20, math.max(ScrH() / 2 - 350, 10))
    frame:MoveToFront()

    frame.OnRemove = function()
        DubzVisibleGuns.EditorSlot = nil
        state.id = nil

        if IsValid(preview) then preview:Remove() end
        if IsValid(catcher) then catcher:Remove() end
    end

    local content = frame:GetContent()
    local controls = {}
    local slots = DubzVisibleGuns.AllSlotIds()
    local slotInfo = {}

    for _, slot in ipairs(slots) do slotInfo[slot.id] = slot end

    -- Which gun is drawn in the slot while you place it (any model of the slot's kind; the slot's own default if you don't pick one)
    local function modelsFor(kind)
        local choices = {}

        for class, rule in pairs(DubzVisibleGuns.Config.WeaponOverrides) do
            local ruleKind = rule.kind == "smg" and "smg" or rule.type

            if rule.model and ruleKind == kind then choices[#choices + 1] = { class = class, model = rule.model } end
        end

        table.sort(choices, function(a, b) return a.class < b.class end)
        return choices
    end

    local function defaultModel(kind)
        return kind == "rifle" and DubzVisibleGuns.Config.DefaultRifleModel or DubzVisibleGuns.Config.DefaultPistolModel
    end

    local function showValues()
        local c = current()

        for key, value in pairs({ px = c.pos.x, py = c.pos.y, pz = c.pos.z }) do
            local reach = math.max(40, math.ceil(math.abs(value)) + 20)
            controls[key]:SetRange(-reach, reach)
            controls[key]:SetValue(value, true)
        end

        controls.ap:SetValue(c.ang.p, true)
        controls.ay:SetValue(c.ang.y, true)
        controls.ar:SetValue(c.ang.r, true)
        controls.scale:SetValue(c.scale, true)
    end

    local slotBox = vgui.Create("DFW.Dropdown", content)
    slotBox:Dock(TOP)
    slotBox:SetTall(28)
    slotBox:DockMargin(4, 4, 4, 2)
    slotBox:SetPlaceholder("Choose a slot")

    for _, slot in ipairs(slots) do slotBox:AddChoice(slot.name, slot.id) end

    local gunBox = vgui.Create("DFW.Dropdown", content)
    gunBox:Dock(TOP)
    gunBox:SetTall(28)
    gunBox:DockMargin(4, 2, 4, 2)
    gunBox:SetPlaceholder("Choose a gun to preview")

    local modeBox = vgui.Create("DFW.Dropdown", content)
    modeBox:Dock(TOP)
    modeBox:SetTall(28)
    modeBox:DockMargin(4, 2, 4, 2)
    modeBox:SetPlaceholder("Editing: the slot")
    modeBox:AddChoice("Editing: the SLOT (every gun in it)", "slot", true)
    modeBox:AddChoice("Editing: THIS GUN only (offset from the slot)", "gun")

    local note = vgui.Create("DFW.Paragraph", content)
    note:Dock(TOP)
    note:DockMargin(4, 4, 4, 2)
    note:SetStyle("small")
    note:SetText("Right mouse + drag to orbit, wheel to zoom. Click a number to type it. Place the slot with a gun that fits, then pick a gun that doesn't line up and switch to THIS GUN to fix just that one. Back slots: wear that backpack first to see it.")

    controls.px = slider(content, "Position X (along the bone)", -40, 40, 0, 2, function(v) current().pos.x = v end)
    controls.py = slider(content, "Position Y (towards the back / front)", -40, 40, 0, 2, function(v) current().pos.y = v end)
    controls.pz = slider(content, "Position Z (left / right)", -40, 40, 0, 2, function(v) current().pos.z = v end)
    controls.ap = slider(content, "Rotate pitch", -180, 180, 0, 0, function(v) current().ang.p = v end)
    controls.ay = slider(content, "Rotate yaw", -180, 180, 0, 0, function(v) current().ang.y = v end)
    controls.ar = slider(content, "Rotate roll", -180, 180, 0, 0, function(v) current().ang.r = v end)
    controls.scale = slider(content, "Scale", 0.3, 2, 1, 2, function(v) current().scale = v end)

    -- The offset saved for the chosen gun (or none)
    local function loadGun()
        local saved = state.class and DubzVisibleGuns.Config.GunTweaks[state.class]

        if saved then
            state.gun = { pos = Vector(saved.pos), ang = Angle(saved.ang.p, saved.ang.y, saved.ang.r), scale = saved.scale or 1 }
        else
            state.gun = { pos = Vector(), ang = Angle(), scale = 1 }
        end
    end

    -- Loads a slot's current placement (saved or default) into the sliders
    local function loadSlot(id)
        local info = slotInfo[id]
        local slot = DubzVisibleGuns.ResolveSlot(id)
        if not info or not slot then return end

        state.id, state.bone, state.kind = id, slot.bone, info.type
        state.slot = { pos = Vector(slot.pos), ang = Angle(slot.ang.p, slot.ang.y, slot.ang.r), scale = slot.scale or 1 }
        DubzVisibleGuns.EditorSlot = id

        -- The gun choices for this kind of slot, and the weapon you are holding
        gunBox:Clear()
        gunBox:AddChoice("Default " .. info.type, { class = nil, model = defaultModel(info.type) })

        local active = LocalPlayer():GetActiveWeapon()

        if IsValid(active) and active.WorldModel and active.WorldModel ~= "" then
            gunBox:AddChoice("The weapon I'm holding (" .. active:GetClass() .. ")", { class = active:GetClass(), model = active.WorldModel })
        end

        for _, choice in ipairs(modelsFor(info.type)) do gunBox:AddChoice(choice.class, { class = choice.class, model = choice.model }) end

        state.model, state.class = defaultModel(info.type), nil
        loadGun()
        showValues()
    end

    slotBox.OnSelect = function(_, _, _, id) loadSlot(id) end

    gunBox.OnSelect = function(_, _, _, choice)
        state.model = (choice and choice.model) or defaultModel(state.kind or "rifle")
        state.class = choice and choice.class or nil

        loadGun()
        showValues()
    end

    modeBox.OnSelect = function(_, _, _, mode)
        state.mode = mode or "slot"

        if state.mode == "gun" and not state.class and DFW.UI.Notify then
            DFW.UI.Notify("Pick a gun first (not 'Default'): the offset is saved for that weapon.", "info", 4)
        end

        showValues()
    end

    local buttons = vgui.Create("Panel", content)
    buttons:Dock(BOTTOM)
    buttons:SetTall(78)
    buttons:DockMargin(0, 0, 0, 2)

    local function pairRow(left, right)
        local row = vgui.Create("Panel", buttons)
        row:Dock(TOP)
        row:SetTall(36)

        local function make(label, variant, onClick, side)
            local button = vgui.Create("DFW.Button", row)
            button:Dock(side)
            button:SetWide(176)
            button:DockMargin(side == LEFT and 2 or 0, 4, side == LEFT and 4 or 2, 4)
            button:SetLabel(label)
            button:SetVariant(variant)
            button.DoClick = onClick
            return button
        end

        make(left[1], left[2], left[3], LEFT)
        make(right[1], right[2], right[3], FILL):SetWide(10)
    end

    -- The id the save and reset buttons use: the slot, or "gun:<class>" when editing one gun
    local function targetId()
        if state.mode == "gun" then return state.class and ("gun:" .. state.class) or nil end

        return state.id
    end

    pairRow({ "Save", "primary", function()
        local id = targetId()
        if not id then return end

        local c = current()

        net.Start("DubzVG_Save")
            net.WriteString(id)
            net.WriteFloat(c.pos.x) net.WriteFloat(c.pos.y) net.WriteFloat(c.pos.z)
            net.WriteFloat(c.ang.p) net.WriteFloat(c.ang.y) net.WriteFloat(c.ang.r)
            net.WriteFloat(c.scale)
        net.SendToServer()
    end }, { "Back to default", "danger", function()
        local id = targetId()
        if not id then return end

        net.Start("DubzVG_Reset")
            net.WriteString(id)
        net.SendToServer()

        timer.Simple(0.4, function()
            if not IsValid(frame) then return end

            if state.mode == "gun" then loadGun() showValues() elseif state.id then loadSlot(state.id) end
        end)
    end })

    -- Copy the numbers (for putting into sh_config.lua if you ever want them as the defaults)
    pairRow({ "Copy numbers", "default", function()
        local c = current()

        SetClipboardText(string.format("pos = Vector(%.1f, %.1f, %.1f), ang = Angle(%d, %d, %d), scale = %.2f",
            c.pos.x, c.pos.y, c.pos.z, c.ang.p, c.ang.y, c.ang.r, c.scale))
    end }, { "Close", "default", function() frame:Close() end })
end

concommand.Add("dvg_editor", open)

-- The third person camera steps aside while this editor has its own camera
hook.Add("DubzThirdPersonBlocked", "DubzVG_Editor", function()
    if IsValid(frame) then return true end
end)
