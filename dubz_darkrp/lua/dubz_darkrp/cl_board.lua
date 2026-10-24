local Board = DubzDarkRP.Board
local Fields = DubzDarkRP.Fields
local Kinds = DubzDarkRP.Kinds
local Adapter = DubzDarkRP.Adapter
local config = DubzDarkRP.Config
local WINDOW_ICON = "darkrp/agenda"
local TOOLBAR_HEIGHT = 40
local REFRESH_TIMER = "DubzDarkRP_BoardRefresh"
local REFRESH_DELAY = 0.1
local COLUMN_GAP = -12
local CATEGORY_BUTTON_WIDTH = 150
local DRAWER_Z = 100
local DRAWER_GAP = 16
local INDICATOR_WIDTH = 330
local INDICATOR_RIGHT = 100
local DRAFT_ID = "__draft"
local REMOVED_TOGGLE_WIDTH = 170

local state = {Frame = nil, Kind = "jobs", Filter = "", Extra = {}, Slots = {}, Closing = false, ShowRemoved = false}

local function send(action, kind, id, data)
    DFW.Net.Start("drp_edit")
    DFW.Net.WriteJSON({action = action, kind = kind, id = id, data = data})
    net.SendToServer()
end

local function kindName(kind)
    return DubzDarkRP.Phrase(Kinds.Meta[kind].label)
end

local function slot()
    return state.Slots[state.Kind]
end

local function entryData(id)
    local entry = Kinds.Engine(state.Kind).Get(id)

    return entry and Fields.Extract(entry, state.Kind)
end

local function anyDirty()
    for _, current in pairs(state.Slots) do
        if current.Dirty then return true end
    end

    return false
end

local function refreshIndicator()
    if IsValid(state.Indicator) then state.Indicator:SetVisible(slot() ~= nil and slot().Dirty) end
end

local function setDirty(value)
    slot().Dirty = value
    refreshIndicator()
end

local function showDrawer(visible)
    slot().Open = visible
    state.Drawer:SetVisible(visible)
    state.Area:DockMargin(0, 0, visible and (config.DrawerWidth + DRAWER_GAP) or 0, 0)
    state.Content:InvalidateLayout(true)
end

local rebuild

local function load(id, data)
    slot().Form.Load(id, data)
    slot().Form.SetMessage("", true)
    setDirty(false)
end

local function guard(proceed)
    if not slot().Dirty then
        proceed()
        return
    end

    DFW.UI.Confirm(DubzDarkRP.Phrase("DiscardTitle"), DubzDarkRP.Phrase("DiscardHint"), function()
        setDirty(false)
        proceed()
    end, {danger = true, confirmLabel = DubzDarkRP.Phrase("DiscardConfirm")})
end

local function startDraft(data)
    local current = slot()

    current.Draft = true
    current.Selected = DRAFT_ID
    showDrawer(true)
    load(nil, data)
    rebuild()
end

local function choose(row)
    if row and row.draft then
        showDrawer(true)
        return
    end

    guard(function()
        local current = slot()

        current.Draft = false
        current.Selected = row and row.id
        showDrawer(row ~= nil)
        load(row and row.id, row and Fields.Extract(row.entry, state.Kind))
        rebuild()
    end)
end

local function openNew()
    guard(function() startDraft(Fields.DefaultsOf(state.Kind)) end)
end

local function duplicate(raw)
    local unique = Kinds.Meta[state.Kind].unique

    raw.name = tostring(raw.name) .. " " .. DubzDarkRP.Phrase("CopySuffix")

    if unique ~= "name" then raw[unique] = "" end

    startDraft(raw)
    setDirty(true)
end

local function reset()
    local current = slot()

    if current.Selected and current.Selected ~= DRAFT_ID then
        load(current.Selected, entryData(current.Selected) or Fields.DefaultsOf(state.Kind))
    else
        load(nil, Fields.DefaultsOf(state.Kind))
    end
end

local function groupedRows()
    local groups, order = {}, {}
    local filter = state.Filter
    local meta = Kinds.Meta[state.Kind]

    local function ensure(name)
        if not groups[name] then
            groups[name] = {}
            order[#order + 1] = name
        end
    end

    local function columnFor(entry)
        return meta.group == false and DubzDarkRP.Phrase(meta.label)
            or entry[meta.group or "category"]
            or DubzDarkRP.Phrase("Uncategorized")
    end

    for _, row in ipairs(Kinds.Engine(state.Kind).List()) do
        local text = string.lower((row.entry.name or "") .. " " .. row.id)
        local hidden = row.status == "removed" and not state.ShowRemoved

        if not hidden and (filter == "" or string.find(text, filter, 1, true)) then
            local name = columnFor(row.entry)

            ensure(name)
            table.insert(groups[name], row)
        end
    end

    if slot().Draft then
        local entry = Fields.DefaultsOf(state.Kind)
        local name = columnFor(entry)

        ensure(name)
        table.insert(groups[name], 1, {id = DRAFT_ID, index = 0, entry = entry, status = "draft", draft = true})
    end

    for name in pairs(state.Extra[state.Kind] or {}) do ensure(name) end

    table.sort(order, function(a, b) return string.lower(a) < string.lower(b) end)

    return groups, order
end

rebuild = function()
    if not (IsValid(state.Frame) and IsValid(state.Scroller)) then return end

    state.Scroller:Clear()

    local handlers = {
        Selected = function() return slot().Selected end,
        Select = choose,
        Move = function(row, category)
            local movable = Kinds.Meta[state.Kind].movable ~= false

            if movable and not row.draft and row.entry.category ~= category then send("save", state.Kind, row.id, {category = category}) end
        end
    }
    local groups, order = groupedRows()

    for _, name in ipairs(order) do state.Scroller:AddPanel(Board.Column(state.Kind, name, groups[name], handlers)) end
end

local function buildSlot(kind)
    local current = {Selected = nil, Dirty = false, Open = false, Draft = false}

    state.Slots[kind] = current
    current.Form = DubzDarkRP.Form.Build(state.Drawer, kind, {
        Save = function(id, raw) send("save", kind, id, raw) end,
        Remove = function(id) send("remove", kind, id) end,
        Restore = function(id) send("restore", kind, id) end,
        Duplicate = duplicate,
        Dirty = function()
            current.Dirty = true
            refreshIndicator()
        end,
        Close = function()
            if current.Draft then
                guard(function()
                    current.Draft = false
                    current.Selected = nil
                    showDrawer(false)
                    rebuild()
                end)
            else
                choose(nil)
            end
        end
    })
    current.Form.Panel:Dock(FILL)
    current.Form.Load(nil, Fields.DefaultsOf(kind))
end

local function switchKind(kind)
    state.Kind = kind

    if not state.Slots[kind] then buildSlot(kind) end

    for name, current in pairs(state.Slots) do current.Form.Panel:SetVisible(name == kind) end

    local current = slot()
    local hasColumns = Kinds.Meta[kind].group == nil

    showDrawer(current.Open)
    refreshIndicator()
    state.NewButton:SetLabel(DubzDarkRP.Phrase("NewItem", {kind = DubzDarkRP.Phrase(Kinds.Meta[kind].single)}))
    state.CategoryButton:SetVisible(hasColumns)
    state.CategoryButton:SetWide(hasColumns and CATEGORY_BUTTON_WIDTH or 0)
    state.CategoryButton:DockMargin(hasColumns and DFW.UI.Space("SM") or 0, 0, 0, 0)
    state.Toolbar:InvalidateLayout(true)
    rebuild()
end

local function buildTabs(content)
    local tabs = vgui.Create("DFW.TabBar", content)

    tabs:Dock(TOP)
    tabs:SetTall(TOOLBAR_HEIGHT)
    tabs.OnTabChanged = function(_, id) switchKind(id) end

    for _, kind in ipairs(Kinds.Order) do tabs:AddTab(kind, kindName(kind), Kinds.Meta[kind].icon) end

    return tabs
end

local function promptCategory()
    DFW.UI.Prompt(DubzDarkRP.Phrase("NewCategory"), DubzDarkRP.Phrase("NewCategoryHint"), "", function(name)
        name = string.Trim(name or "")

        if name == "" then return end

        state.Extra[state.Kind] = state.Extra[state.Kind] or {}
        state.Extra[state.Kind][name] = true
        rebuild()
    end)
end

local function buildToolbar(content)
    local bar = vgui.Create("Panel", content)
    local category = vgui.Create("DFW.Button", bar)
    local new = vgui.Create("DFW.Button", bar)
    local removed = vgui.Create("DFW.Toggle", bar)
    local search = vgui.Create("DFW.TextEntry", bar)

    bar:Dock(TOP)
    bar:SetTall(TOOLBAR_HEIGHT)
    bar:DockMargin(0, DFW.UI.Space("SM"), 0, DFW.UI.Space("SM"))

    state.CategoryButton = category
    category:Dock(RIGHT)
    category:SetWide(CATEGORY_BUTTON_WIDTH)
    category:SetLabel(DubzDarkRP.Phrase("NewCategory"))
    category:DockMargin(DFW.UI.Space("SM"), 0, 0, 0)
    category.DoClick = promptCategory

    new:Dock(RIGHT)
    new:SetWide(170)
    new:SetVariant("primary")
    new:SetIcon("actions/add")
    new.DoClick = openNew
    state.NewButton = new

    removed:Dock(RIGHT)
    removed:SetWide(REMOVED_TOGGLE_WIDTH)
    removed:DockMargin(DFW.UI.Space("SM"), 0, DFW.UI.Space("SM"), 0)
    removed:SetLabel(DubzDarkRP.Phrase("ShowRemoved"))
    removed:SetChecked(state.ShowRemoved, true)
    removed.OnChange = function(_, value)
        state.ShowRemoved = value == true
        rebuild()
    end

    search:Dock(FILL)
    search:SetPlaceholder(DubzDarkRP.Phrase("BoardSearch"))
    search.OnChange = function(entry)
        state.Filter = string.lower(entry:GetValue())
        rebuild()
    end

    return bar
end

local function placeDrawer(content)
    local top = state.Toolbar:GetY() + state.Toolbar:GetTall() + DFW.UI.Space("SM")
    local width = math.min(config.DrawerWidth, content:GetWide())

    state.Drawer:SetPos(content:GetWide() - width, top)
    state.Drawer:SetSize(width, content:GetTall() - top)
end

local function buildIndicator(frame)
    local holder = vgui.Create("Panel", frame)
    local save = vgui.Create("DFW.Button", holder)
    local undo = vgui.Create("DFW.Button", holder)
    local label = vgui.Create("DFW.Label", holder)

    holder:SetSize(INDICATOR_WIDTH, 28)
    holder:SetVisible(false)
    holder.Think = function(self) self:SetPos(frame:GetWide() - self:GetWide() - INDICATOR_RIGHT, 6) end

    save:Dock(RIGHT)
    save:SetWide(76)
    save:SetLabel(DubzDarkRP.Phrase("SaveAll"))
    save:SetVariant("primary")
    save.DoClick = function() slot().Form.Save() end

    undo:Dock(RIGHT)
    undo:SetWide(76)
    undo:DockMargin(0, 0, DFW.UI.Space("XS"), 0)
    undo:SetLabel(DubzDarkRP.Phrase("ResetChanges"))
    undo.DoClick = reset

    label:Dock(FILL)
    label:SetText(DubzDarkRP.Phrase("UnsavedChanges"))
    label:SetStyle("small")
    label:SetColor(DFW.UI.GetTheme().warning)
    label:SetAlign(TEXT_ALIGN_RIGHT)

    state.Indicator = holder
end

local function hideArrows(scroller)
    local base = scroller.PerformLayout

    scroller.PerformLayout = function(self, w, h)
        if base then base(self, w, h) end

        self.btnLeft:SetVisible(false)
        self.btnRight:SetVisible(false)
    end
end

local function guardClose(frame)
    frame.OnClose = function()
        if state.Closing or not anyDirty() then return end

        DFW.UI.Confirm(DubzDarkRP.Phrase("CloseTitle"), DubzDarkRP.Phrase("CloseHint"), function()
            state.Closing = true
            frame:Close()
        end, {danger = true, confirmLabel = DubzDarkRP.Phrase("CloseConfirm")})

        return false
    end
end

function DubzDarkRP.OpenBoard(kind, focusId)
    if not Adapter.Ready() then
        DubzDarkRP.Report("DarkRP is not ready, so the board cannot open")
        return
    end

    if IsValid(state.Frame) then
        state.Closing = true
        state.Frame:Remove()
    end

    for _, name in ipairs(Kinds.Order) do Kinds.Engine(name).Capture() end

    local frame = DFW.UI.CreateFrame(DubzDarkRP.Phrase("EditorTitle"), config.BoardWidth, config.BoardHeight, WINDOW_ICON, {module = "drp_core"})
    local content = frame:GetContent()

    state.Frame = frame
    state.Content = content
    state.Filter = ""
    state.Extra = {}
    state.Slots = {}
    state.Closing = false
    frame:SetSubtitle(DubzDarkRP.Phrase("EditorSubtitle"))
    guardClose(frame)
    buildIndicator(frame)

    local tabs = buildTabs(content)

    state.Toolbar = buildToolbar(content)
    state.Area = vgui.Create("Panel", content)
    state.Area:Dock(FILL)

    local scrollbar = Board.Scrollbar(state.Area)

    state.Scroller = vgui.Create("DHorizontalScroller", state.Area)
    state.Scroller:Dock(FILL)
    state.Scroller:SetOverlap(COLUMN_GAP)
    hideArrows(state.Scroller)
    scrollbar:SetScroller(state.Scroller)

    state.Drawer = vgui.Create("Panel", content)
    state.Drawer:SetZPos(DRAWER_Z)
    state.Drawer:SetVisible(false)
    content.PerformLayout = function(self) placeDrawer(self) end

    kind = Kinds.Meta[kind or ""] and kind or "jobs"
    tabs:SetActive(kind, true)
    switchKind(kind)
    content:InvalidateLayout(true)

    local entry = focusId and Kinds.Engine(kind).Get(focusId)

    if entry then choose({id = focusId, entry = entry}) end

    hook.Run("DubzDarkRPBoardOpened", kind)
end

hook.Add("DubzDarkRPResult", "DubzDarkRP_Board", function(ok, message)
    if not (IsValid(state.Frame) and slot()) then return end

    local current = slot()

    current.Form.SetMessage(message, ok)

    if not ok then return end

    setDirty(false)

    if current.Form.Id() == nil then
        current.Draft = false
        current.Selected = nil
        showDrawer(false)
        rebuild()
    end
end)

hook.Add("DubzDarkRPChanged", "DubzDarkRP_Board", function(kind, id)
    if not (IsValid(state.Frame) and kind == state.Kind) then return end

    timer.Create(REFRESH_TIMER, REFRESH_DELAY, 1, function()
        if not IsValid(state.Frame) then return end

        rebuild()

        local current = slot()
        local entry = Kinds.Engine(state.Kind).Get(id)

        if entry and entry.dubzDisabled and not state.ShowRemoved and current.Selected == id then
            current.Selected = nil
            setDirty(false)
            showDrawer(false)
            rebuild()
            return
        end

        if current.Dirty or current.Selected ~= id then return end

        local data = entryData(id)

        if data then load(id, data) else choose(nil) end
    end)
end)
