DubzSuggestions.Public = DubzSuggestions.Public or {}

local Public = DubzSuggestions.Public
local State = DubzSuggestions.State
local Client = DubzSuggestions.Client
local config = DubzSuggestions.Config
local VOTE_SIZE = 30
local VOTE_COLUMN = 52
local PAD = 12
local TITLE_HEIGHT = 24
local META_HEIGHT = 20
local LINE_HEIGHT = 18
local COLLAPSED_LINES = 3
local TEXT_MARGIN = 56
local HEADER_HEIGHT = 34
local CONTROL_HEIGHT = 30
local hookCounter = 0

local STATUS_KINDS = {new = "accent", review = "warning", planned = "info", done = "success"}
local STATUS_KEYS = {new = "StatusNew", review = "StatusReview", planned = "StatusPlanned", done = "StatusDone"}

local function phrase(key, values)
    return DubzSuggestions.Phrase(key, values)
end

local function cardWidth()
    return config.PublicWidth - TEXT_MARGIN - VOTE_COLUMN - PAD * 3
end

local function cardHeight(card)
    local lines = card.expanded and #card.lines or math.min(#card.lines, COLLAPSED_LINES)

    return math.max(PAD * 2 + TITLE_HEIGHT + META_HEIGHT + lines * LINE_HEIGHT + 4, PAD * 2 + VOTE_SIZE * 2 + 22)
end

local function applyVote(item, value)
    item.score = item.score - item.myVote + value
    item.myVote = value
end

local function castVote(card, direction)
    local item = card.item
    local value = item.myVote == direction and 0 or direction

    applyVote(item, value)
    card.refreshVotes()
    Client.Vote(item.id, value)
end

local function placeVotes(card, w, h)
    local x = PAD + (VOTE_COLUMN - VOTE_SIZE) / 2

    card.up:SetPos(x, h / 2 - 22 - VOTE_SIZE / 2 - 4)
    card.up:SetSize(VOTE_SIZE, VOTE_SIZE)
    card.down:SetPos(x, h / 2 + 22 - VOTE_SIZE / 2 + 4)
    card.down:SetSize(VOTE_SIZE, VOTE_SIZE)
end

local function paintCard(card, w, h)
    local theme = DFW.UI.GetTheme()
    local item = card.item
    local left = PAD * 2 + VOTE_COLUMN
    local scoreColor = item.myVote == 1 and theme.accent or (item.myVote == -1 and theme.danger or theme.text)

    DFW.Draw.Card(0, 0, w, h, {radius = "MD", color = theme.surfaceAlt})
    DFW.Draw.Text(tostring(item.score), "BodyBold", PAD + VOTE_COLUMN / 2, h / 2, scoreColor, TEXT_ALIGN_CENTER)
    DFW.Draw.Text(item.title, "BodyBold", left, PAD + TITLE_HEIGHT / 2, theme.text)

    local meta = phrase("ByAuthor", {name = item.author}) .. "  •  " .. item.topic

    DFW.Draw.Text(meta, "Tiny", left, PAD + TITLE_HEIGHT + META_HEIGHT / 2, theme.textDim)

    local shown = card.expanded and #card.lines or math.min(#card.lines, COLLAPSED_LINES)
    local top = PAD + TITLE_HEIGHT + META_HEIGHT + 4

    for index = 1, shown do
        local text = card.lines[index]

        if not card.expanded and index == shown and #card.lines > shown then text = text .. " …" end

        DFW.Draw.Text(text, "Body", left, top + (index - 0.5) * LINE_HEIGHT, theme.textMuted)
    end

    local statusKey = STATUS_KEYS[item.status]

    if statusKey and item.status ~= "new" then
        local color = theme[STATUS_KINDS[item.status]] or theme.accent

        DFW.Draw.Text(phrase(statusKey), "Tiny", w - PAD, PAD + TITLE_HEIGHT / 2, color, TEXT_ALIGN_RIGHT)
    end
end

local function buildCard(list, item)
    local card = list:Add("DFW.Card")

    card.item = item
    card.expanded = false
    card.lines = DFW.UI.WrapText(item.body, "Body", cardWidth())
    card:Dock(TOP)
    card:DockMargin(0, 0, DFW.UI.Space("SM"), DFW.UI.Space("SM"))
    card:SetTall(cardHeight(card))
    card:SetCursor("hand")

    card.up = vgui.Create("DFW.Button", card)
    card.up:SetIcon("actions/arrow_drop_up")
    card.up.DoClick = function() castVote(card, 1) end
    card.down = vgui.Create("DFW.Button", card)
    card.down:SetIcon("actions/arrow_drop_down")
    card.down.DoClick = function() castVote(card, -1) end

    card.refreshVotes = function()
        card.up:SetVariant(item.myVote == 1 and "primary" or "ghost")
        card.down:SetVariant(item.myVote == -1 and "danger" or "ghost")
    end

    card.refreshVotes()
    card.PerformLayout = placeVotes
    card.Paint = paintCard
    card.OnMousePressed = function()
        if #card.lines <= COLLAPSED_LINES then return end

        card.expanded = not card.expanded
        card:SetTall(cardHeight(card))
        list:InvalidateLayout()
    end

    return card
end

local function sorted(items, mode)
    local list = table.Copy(items)

    table.sort(list, function(a, b)
        if mode == "new" then return a.createdAt > b.createdAt end

        if a.score ~= b.score then return a.score > b.score end

        return a.createdAt > b.createdAt
    end)

    return list
end

local function visible(view)
    local list = {}

    for _, item in ipairs(sorted(State.Items, view.sort)) do
        if view.filter == "" or item.topic == view.filter then list[#list + 1] = item end
    end

    return list
end

local function renderList(view)
    view.list:Clear()

    local items = visible(view)

    if #items == 0 then
        local empty = view.list:Add("DFW.Label")

        empty:Dock(TOP)
        empty:SetTall(40)
        empty:SetStyle("muted")
        empty:SetAlign(TEXT_ALIGN_CENTER)
        empty:SetText(phrase(State.Loaded and "NoSuggestions" or "Loading"))

        return
    end

    for _, item in ipairs(items) do buildCard(view.list, item) end
end

local function fillFilter(view)
    view.dropdown:Clear()
    view.dropdown:AddChoice(phrase("AllTopics"), "")

    local seen = {}

    for _, item in ipairs(State.Items) do
        if not seen[item.topic] then
            seen[item.topic] = true
            view.dropdown:AddChoice(item.topic, item.topic)
        end
    end

    view.dropdown:SelectByData(seen[view.filter] and view.filter or "", true)

    if not seen[view.filter] then view.filter = "" end
end

local function sortButton(view, bar, key, mode)
    local button = vgui.Create("DFW.Button", bar)

    button:Dock(LEFT)
    button:SetWide(70)
    button:DockMargin(0, 0, 4, 0)
    button:SetLabel(phrase(key))
    button.DoClick = function()
        view.sort = mode
        view.top:SetVariant(mode == "top" and "primary" or "ghost")
        view.new:SetVariant(mode == "new" and "primary" or "ghost")
        renderList(view)
    end

    return button
end

function Public.Build(parent)
    local view = {sort = "top", filter = ""}
    local card = vgui.Create("DFW.Card", parent)
    local space = DFW.UI.Space("MD")

    card:Dock(RIGHT)
    card:SetWide(config.PublicWidth)

    local pad = vgui.Create("Panel", card)

    pad:Dock(FILL)
    pad:DockMargin(space, space, space, space)

    local heading = vgui.Create("DFW.Label", pad)

    heading:Dock(TOP)
    heading:SetTall(HEADER_HEIGHT)
    heading:SetStyle("heading")
    heading:SetText(phrase("PublicTitle"))

    local bar = vgui.Create("Panel", pad)

    bar:Dock(TOP)
    bar:SetTall(CONTROL_HEIGHT)
    bar:DockMargin(0, 0, 0, space)
    view.top = sortButton(view, bar, "SortTop", "top")
    view.new = sortButton(view, bar, "SortNew", "new")
    view.top:SetVariant("primary")
    view.new:SetVariant("ghost")
    view.dropdown = vgui.Create("DFW.Dropdown", bar)
    view.dropdown:Dock(FILL)
    view.dropdown:DockMargin(space, 0, 0, 0)
    view.dropdown.OnSelect = function()
        local _, data = view.dropdown:GetSelected()

        view.filter = data or ""
        renderList(view)
    end

    view.list = vgui.Create("DFW.ScrollPanel", pad)
    view.list:Dock(FILL)

    hookCounter = hookCounter + 1

    local name = "DubzSuggestions_Public" .. hookCounter

    hook.Add("DubzSuggestionsState", name, function()
        if not IsValid(view.list) then return end

        fillFilter(view)
        renderList(view)
    end)

    card.OnRemove = function() hook.Remove("DubzSuggestionsState", name) end

    fillFilter(view)
    renderList(view)

    return card
end
