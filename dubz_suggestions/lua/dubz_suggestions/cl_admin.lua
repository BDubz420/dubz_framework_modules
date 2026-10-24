local State = DubzSuggestions.State
local Client = DubzSuggestions.Client
local config = DubzSuggestions.Config
local WINDOW_ICON = "communication/forum"
local TAB_HEIGHT = 40
local PAD = 12
local TITLE_HEIGHT = 24
local META_HEIGHT = 20
local LINE_HEIGHT = 18
local BUTTON_HEIGHT = 30
local BUTTON_GAP = 6
local TEXT_LINES = 4
local STATUSES = {"pending", "new", "review", "planned", "done", "declined", "hidden"}
local STATUS_KEYS = {
    pending = "StatusPending", new = "StatusNew", review = "StatusReview", planned = "StatusPlanned",
    done = "StatusDone", declined = "Reject", hidden = "StatusHidden"
}
local ACTIONS = {
    pending = {{"approve", "Approve", "primary"}, {"reject", "Reject", "danger"}, {"hide", "Hide", "ghost"}},
    new = {{"review", "MarkReview", "default"}, {"planned", "MarkPlanned", "default"}, {"done", "MarkDone", "default"}, {"hide", "Hide", "ghost"}},
    review = {{"planned", "MarkPlanned", "default"}, {"done", "MarkDone", "default"}, {"hide", "Hide", "ghost"}},
    planned = {{"done", "MarkDone", "default"}, {"review", "MarkReview", "default"}, {"hide", "Hide", "ghost"}},
    done = {{"reopen", "Reopen", "default"}, {"hide", "Hide", "ghost"}},
    declined = {{"reopen", "Reopen", "default"}, {"delete", "Delete", "danger"}},
    hidden = {{"reopen", "Reopen", "default"}, {"delete", "Delete", "danger"}}
}
local frame
local view = {status = "pending"}

local function phrase(key, values)
    return DubzSuggestions.Phrase(key, values)
end

local function statusLabel(status)
    return phrase(STATUS_KEYS[status])
end

local function perform(item, action)
    if action == "delete" then
        DFW.UI.Confirm(phrase("Delete"), item.title, function() Client.Moderate(item.id, action) end, {danger = true, confirmLabel = phrase("Delete")})
        return
    end

    Client.Moderate(item.id, action)
end

local function actionBar(card, item)
    local bar = vgui.Create("Panel", card)

    bar:Dock(BOTTOM)
    bar:SetTall(BUTTON_HEIGHT)
    bar:DockMargin(PAD, 0, PAD, PAD)

    for _, entry in ipairs(ACTIONS[item.status] or {}) do
        local button = vgui.Create("DFW.Button", bar)

        button:Dock(LEFT)
        button:SetWide(110)
        button:DockMargin(0, 0, BUTTON_GAP, 0)
        button:SetLabel(phrase(entry[2]))
        button:SetVariant(entry[3])
        button.DoClick = function() perform(item, entry[1]) end
    end
end

local function buildCard(list, item)
    local lines = DFW.UI.WrapText(item.body, "Body", config.AdminWidth - 120)
    local shown = math.min(#lines, TEXT_LINES)
    local card = list:Add("DFW.Card")

    card:Dock(TOP)
    card:DockMargin(0, 0, DFW.UI.Space("SM"), DFW.UI.Space("SM"))
    card:SetTall(PAD * 2 + TITLE_HEIGHT + META_HEIGHT + shown * LINE_HEIGHT + 8 + BUTTON_HEIGHT + PAD)
    card:SetCardColor(DFW.UI.GetTheme().surfaceAlt)
    actionBar(card, item)

    card.Paint = function(_, w, h)
        local theme = DFW.UI.GetTheme()

        DFW.Draw.Card(0, 0, w, h, {radius = "MD", color = theme.surfaceAlt})
        DFW.Draw.Text(item.title, "BodyBold", PAD, PAD + TITLE_HEIGHT / 2, theme.text)

        local author = item.anonymous and (item.author .. " (" .. phrase("Anonymous") .. ")") or item.author
        local meta = phrase("AdminMeta", {author = author, topic = item.topic, score = item.score, date = os.date("%Y-%m-%d %H:%M", item.createdAt)})

        DFW.Draw.Text(meta, "Tiny", PAD, PAD + TITLE_HEIGHT + META_HEIGHT / 2, theme.textDim)

        for index = 1, shown do
            local text = lines[index]

            if index == shown and #lines > shown then text = text .. " …" end

            DFW.Draw.Text(text, "Body", PAD, PAD + TITLE_HEIGHT + META_HEIGHT + 4 + (index - 0.5) * LINE_HEIGHT, theme.textMuted)
        end
    end
end

local function render()
    if not IsValid(view.list) then return end

    view.list:Clear()

    local count, pending = 0, 0

    for _, item in ipairs(State.Admin) do
        if item.status == "pending" then pending = pending + 1 end

        if item.status == view.status then
            count = count + 1
            buildCard(view.list, item)
        end
    end

    view.subtitle(phrase("AdminSubtitle", {count = pending}))

    if count == 0 then
        local empty = view.list:Add("DFW.Label")

        empty:Dock(TOP)
        empty:SetTall(40)
        empty:SetStyle("muted")
        empty:SetAlign(TEXT_ALIGN_CENTER)
        empty:SetText(phrase("AdminEmpty"))
    end
end

local function buildTabs(content)
    local tabs = vgui.Create("DFW.TabBar", content)

    tabs:Dock(TOP)
    tabs:SetTall(TAB_HEIGHT)
    tabs.OnTabChanged = function(_, id)
        view.status = id
        render()
    end

    for _, status in ipairs(STATUSES) do tabs:AddTab(status, statusLabel(status)) end

    return tabs
end

function DubzSuggestions.OpenAdmin()
    if IsValid(frame) then frame:Remove() end

    frame = DFW.UI.CreateFrame(phrase("AdminTitle"), config.AdminWidth, config.AdminHeight, WINDOW_ICON, {module = "suggestions"})

    local content = frame:GetContent()
    local tabs = buildTabs(content)

    view.status = "pending"
    view.subtitle = function(text) frame:SetSubtitle(text) end
    view.list = vgui.Create("DFW.ScrollPanel", content)
    view.list:Dock(FILL)
    view.list:DockMargin(0, DFW.UI.Space("SM"), 0, 0)
    tabs:SetActive("pending", true)

    hook.Add("DubzSuggestionsAdmin", "DubzSuggestions_AdminRender", render)

    local closed = frame.OnClose

    frame.OnClose = function(...)
        hook.Remove("DubzSuggestionsAdmin", "DubzSuggestions_AdminRender")

        if closed then return closed(...) end
    end

    render()
    Client.RequestAdmin()
end
