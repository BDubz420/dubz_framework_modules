DubzWorkflow.Suggestions = DubzWorkflow.Suggestions or {}

local Suggestions = DubzWorkflow.Suggestions
local State = DubzWorkflow.State
local config = DubzWorkflow.Config
local WINDOW_ICON = "communication/forum"
local COLUMNS = {"pending", "new", "review", "planned", "done"}
local STATUS_KEYS = {
    pending = "StatusPending", new = "StatusNew", review = "StatusReview", planned = "StatusPlanned", done = "StatusDone"
}
local NEXT_ACTIONS = {
    pending = {{"approve", "Approve", "primary"}, {"reject", "Reject", "danger"}},
    new = {{"review", "MarkReview", "default"}, {"planned", "MarkPlanned", "default"}, {"done", "MarkDone", "default"}},
    review = {{"planned", "MarkPlanned", "default"}, {"done", "MarkDone", "default"}},
    planned = {{"done", "MarkDone", "default"}, {"review", "MarkReview", "default"}},
    done = {{"reopen", "Reopen", "default"}}
}
local HEADER_HEIGHT = 34
local COLUMN_GAP = 10
local CARD_HEIGHT = 70
local ACTION_HEIGHT = 40
local PAD = 14
local ROW = 24
local hookCounter = 0
local dialog
local shownId
local shownSignature

State.Suggestions = State.Suggestions or {items = {}, byId = {}, loaded = false}

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function statusLabel(status)
    return DubzSuggestions.Phrase(STATUS_KEYS[status] or "StatusNew")
end

local function send(name, data)
    DFW.Net.Start(name)

    if data then DFW.Net.WriteJSON(data) end

    net.SendToServer()
end

function Suggestions.Request()
    send("wf_sugreq")
end

local function signature(row)
    return table.concat({row.status, tostring(row.task), row.score}, "|")
end

DFW.Net.Receive("wf_sugs", function()
    local payload = DFW.Net.ReadJSON()

    if not istable(payload) then return end

    State.Suggestions.items = payload.items or {}
    State.Suggestions.byId = {}
    State.Suggestions.loaded = true

    for _, row in ipairs(State.Suggestions.items) do State.Suggestions.byId[row.id] = row end

    hook.Run("DubzWorkflowSuggestions")
end)

hook.Add("DubzWorkflowState", "DubzWorkflow_SuggestionsRequest", function()
    if DubzSuggestions and not State.Suggestions.loaded then Suggestions.Request() end
end)

hook.Add("DubzWorkflowRegisterLinks", "DubzWorkflow_SuggestionLink", function(register)
    if not DubzSuggestions then return end

    register({
        id = "suggestion",
        label = phrase("SuggestLinkLabel"),
        icon = WINDOW_ICON,
        describe = function(ref)
            local row = State.Suggestions.byId[ref]

            return row and row.title or nil
        end,
        choices = function()
            local list = {}

            for _, row in ipairs(State.Suggestions.items) do list[#list + 1] = {label = row.title, ref = row.id} end

            return list
        end,
        open = function(ref) Suggestions.OpenDialog(ref) end
    })
end)

local function line(scroll, text, style)
    local label = scroll:Add("DFW.Label")

    label:Dock(TOP)
    label:SetTall(ROW)
    label:SetStyle(style or "muted")
    label:SetText(text)
end

local function actionButton(bar, text, variant, onClick)
    local button = vgui.Create("DFW.Button", bar)

    button:Dock(LEFT)
    button:SetWide(130)
    button:DockMargin(0, 0, 6, 0)
    button:SetLabel(text)
    button:SetVariant(variant)
    button.DoClick = onClick

    return button
end

local function buildDialog(row)
    local content = dialog:GetContent()

    content:Clear()
    dialog:SetTitle(row.title)
    dialog:SetSubtitle(statusLabel(row.status))

    local bar = vgui.Create("Panel", content)

    bar:Dock(BOTTOM)
    bar:SetTall(ACTION_HEIGHT)
    bar:DockMargin(0, DFW.UI.Space("MD"), 0, 0)

    for _, entry in ipairs(NEXT_ACTIONS[row.status] or {}) do
        actionButton(bar, DubzSuggestions.Phrase(entry[2]), entry[3], function() send("wf_sugact", {id = row.id, action = entry[1]}) end)
    end

    if row.task then
        actionButton(bar, phrase("SuggestOpenTask"), "default", function() DubzWorkflow.OpenDetail(row.task) end)
    elseif State.Me.manager then
        actionButton(bar, phrase("SuggestConvert"), "primary", function() send("wf_sugtask", {id = row.id}) end)
    end

    local scroll = vgui.Create("DFW.ScrollPanel", content)

    scroll:Dock(FILL)
    line(scroll, phrase("SuggestFrom", {author = row.author, topic = row.topic, score = row.score}), "bodybold")

    local body = DubzWorkflow.Format.Panel(scroll, row.body)

    body:Dock(TOP)
    body:DockMargin(0, DFW.UI.Space("SM"), 0, 0)
end

local function refreshDialog()
    if not (IsValid(dialog) and shownId) then return end

    local row = State.Suggestions.byId[shownId]

    if not row then
        dialog:Close()
        return
    end

    if signature(row) == shownSignature then return end

    shownSignature = signature(row)
    buildDialog(row)
end

function Suggestions.OpenDialog(id)
    local row = State.Suggestions.byId[id]

    if not row then return end

    if IsValid(dialog) then dialog:Remove() end

    dialog = DFW.UI.CreateFrame(phrase("SuggestDialogTitle"), config.SuggestionDialogWidth, config.SuggestionDialogHeight, WINDOW_ICON, {module = "workflow"})
    shownId = id
    shownSignature = signature(row)
    buildDialog(row)
end

hook.Add("DubzWorkflowSuggestions", "DubzWorkflow_SuggestionDialog", refreshDialog)

local function buildCard(scroll, row)
    local card = scroll:Add("DFW.Card")

    card:Dock(TOP)
    card:DockMargin(0, 0, DFW.UI.Space("SM"), DFW.UI.Space("SM"))
    card:SetTall(CARD_HEIGHT)
    card:SetCursor("hand")
    card.PaintOver = function(_, w)
        local theme = DFW.UI.GetTheme()
        DFW.Draw.Text(row.title, "BodyBold", PAD, PAD + 8, theme.text)
        DFW.Draw.Text(row.topic .. "  •  " .. row.author, "Small", PAD, PAD + 30, theme.textMuted)

        if row.task then DFW.Draw.Text("→ " .. row.task, "Tiny", w - PAD, PAD + 8, theme.accent, TEXT_ALIGN_RIGHT) end

        DFW.Draw.Text(tostring(row.score), "Tiny", w - PAD, PAD + 30, theme.textDim, TEXT_ALIGN_RIGHT)
    end
    card.OnMousePressed = function() Suggestions.OpenDialog(row.id) end
end

local function buildColumn(parent, status)
    local column = vgui.Create("DFW.Card", parent)
    local header = vgui.Create("DFW.Label", column)
    local scroll = vgui.Create("DFW.ScrollPanel", column)
    local pad = DFW.UI.Space("SM")

    header:Dock(TOP)
    header:SetTall(HEADER_HEIGHT)
    header:DockMargin(pad + 4, 0, pad, 0)
    header:SetStyle("bodybold")
    scroll:Dock(FILL)
    scroll:DockMargin(pad, 0, 0, pad)

    column.Refresh = function()
        local count = 0

        scroll:Clear()

        for _, row in ipairs(State.Suggestions.items) do
            if row.status == status then
                count = count + 1
                buildCard(scroll, row)
            end
        end

        header:SetText(statusLabel(status) .. "  " .. count)
    end

    return column
end

function Suggestions.Build(parent)
    local root = vgui.Create("Panel", parent)
    local columns = {}

    root:Dock(FILL)

    for _, status in ipairs(COLUMNS) do columns[#columns + 1] = buildColumn(root, status) end

    root.PerformLayout = function(self, w, h)
        local each = math.floor((w - COLUMN_GAP * (#columns - 1)) / #columns)

        for index, column in ipairs(columns) do
            column:SetPos((index - 1) * (each + COLUMN_GAP), 0)
            column:SetSize(each, h)
        end
    end

    hookCounter = hookCounter + 1

    local name = "DubzWorkflow_SuggestionsView" .. hookCounter

    hook.Add("DubzWorkflowSuggestions", name, function()
        if not IsValid(root) then return end

        for _, column in ipairs(columns) do column.Refresh() end
    end)

    root.OnRemove = function() hook.Remove("DubzWorkflowSuggestions", name) end

    Suggestions.Request()

    for _, column in ipairs(columns) do column.Refresh() end

    return root
end
