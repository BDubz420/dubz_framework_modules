DubzSuggestions.Form = DubzSuggestions.Form or {}

local Form = DubzSuggestions.Form
local State = DubzSuggestions.State
local Client = DubzSuggestions.Client
local config = DubzSuggestions.Config
local CUSTOM_ID = "__custom"
local FIELD_HEIGHT = 32
local DETAILS_HEIGHT = 150
local LABEL_HEIGHT = 20
local BUTTON_HEIGHT = 38
local hookCounter = 0

local function phrase(key, values)
    return DubzSuggestions.Phrase(key, values)
end

local function row(parent, height)
    local holder = vgui.Create("Panel", parent)

    holder:Dock(TOP)
    holder:SetTall(height)
    holder:DockMargin(0, 0, 0, DFW.UI.Space("SM"))

    return holder
end

local function caption(parent, text)
    local label = vgui.Create("DFW.Label", parent)

    label:Dock(TOP)
    label:SetTall(LABEL_HEIGHT)
    label:SetStyle("small")
    label:SetText(text)
end

local function fillTopics(form)
    form.Topic:Clear()

    for _, topic in ipairs(State.Topics) do form.Topic:AddChoice(topic.label, topic.id) end

    if State.Settings.custom then form.Topic:AddChoice(phrase("CustomTopicOption"), CUSTOM_ID) end
end

local function refreshCustom(form)
    local _, data = form.Topic:GetSelected()
    local custom = data == CUSTOM_ID

    form.CustomRow:SetTall(custom and FIELD_HEIGHT + LABEL_HEIGHT + DFW.UI.Space("SM") or 0)
    form.Pad:InvalidateLayout(true)
end

local function readTopic(form)
    local _, data = form.Topic:GetSelected()

    if data == CUSTOM_ID then return DubzSuggestions.Topics.CustomId(form.Custom:GetValue()) end

    return data
end

local function updateCounter(form)
    local used = #form.Body:GetValue()

    form.Counter:SetText(phrase("Counter", {used = used, max = config.BodyMax}))
end

local function send(form)
    local topic = readTopic(form)

    if not topic then
        DFW.UI.Notify(phrase("ErrorTopic"), "danger")
        return
    end

    form.Submit:SetEnabled(false)
    Client.Submit({
        topic = topic,
        title = form.Title:GetValue(),
        body = form.Body:GetValue(),
        anonymous = form.Anonymous and form.Anonymous:GetChecked() or false
    })
end

local function cleared(form)
    form.Title:SetValue("")
    form.Body:SetValue("")
    form.Custom:SetValue("")
    updateCounter(form)
end

function Form.Build(parent)
    local form = {}
    local card = vgui.Create("DFW.Card", parent)
    local pad = vgui.Create("Panel", card)
    local space = DFW.UI.Space("LG")

    form.Card = card
    form.Pad = pad
    card:Dock(FILL)
    pad:Dock(FILL)
    pad:DockMargin(space, space, space, space)

    local heading = vgui.Create("DFW.Label", pad)

    heading:Dock(TOP)
    heading:SetTall(28)
    heading:SetStyle("heading")
    heading:SetText(phrase("SubmitTitle"))

    local topicRow = row(pad, LABEL_HEIGHT + FIELD_HEIGHT)

    caption(topicRow, phrase("FieldTopic"))
    form.Topic = vgui.Create("DFW.Dropdown", topicRow)
    form.Topic:Dock(TOP)
    form.Topic:SetTall(FIELD_HEIGHT)
    form.Topic.OnSelect = function() refreshCustom(form) end

    form.CustomRow = row(pad, 0)
    caption(form.CustomRow, phrase("FieldCustomTopic"))
    form.Custom = vgui.Create("DFW.TextEntry", form.CustomRow)
    form.Custom:Dock(TOP)
    form.Custom:SetTall(FIELD_HEIGHT)
    form.Custom:SetUpdateOnType(true)

    local titleRow = row(pad, LABEL_HEIGHT + FIELD_HEIGHT)

    caption(titleRow, phrase("FieldTitle"))
    form.Title = vgui.Create("DFW.TextEntry", titleRow)
    form.Title:Dock(TOP)
    form.Title:SetTall(FIELD_HEIGHT)
    form.Title:SetPlaceholder(phrase("TitlePlaceholder"))

    local bodyRow = row(pad, LABEL_HEIGHT + DETAILS_HEIGHT)

    caption(bodyRow, phrase("FieldDetails"))
    form.Body = vgui.Create("DFW.TextEntry", bodyRow)
    form.Body:Dock(TOP)
    form.Body:SetTall(DETAILS_HEIGHT)
    form.Body:SetMultiline(true)
    form.Body:SetPlaceholder(phrase("DetailsPlaceholder"))
    form.Body:SetUpdateOnType(true)
    form.Body.OnChange = function() updateCounter(form) end

    form.Counter = vgui.Create("DFW.Label", pad)
    form.Counter:Dock(TOP)
    form.Counter:SetTall(LABEL_HEIGHT)
    form.Counter:SetStyle("tiny")
    form.Counter:SetAlign(TEXT_ALIGN_RIGHT)
    updateCounter(form)

    if config.AllowAnonymous then
        local anonRow = row(pad, FIELD_HEIGHT)

        form.Anonymous = vgui.Create("DFW.Toggle", anonRow)
        form.Anonymous:Dock(FILL)
        form.Anonymous:SetLabel(phrase("Anonymous"))
    end

    form.Submit = vgui.Create("DFW.Button", pad)
    form.Submit:Dock(BOTTOM)
    form.Submit:SetTall(BUTTON_HEIGHT)
    form.Submit:SetLabel(phrase("Submit"))
    form.Submit:SetVariant("primary")
    form.Submit:SetIcon("actions/check")
    form.Submit.DoClick = function() send(form) end

    hookCounter = hookCounter + 1

    local stateHook = "DubzSuggestions_FormState" .. hookCounter
    local resultHook = "DubzSuggestions_FormResult" .. hookCounter

    hook.Add("DubzSuggestionsState", stateHook, function()
        fillTopics(form)
        refreshCustom(form)
    end)

    hook.Add("DubzSuggestionsResult", resultHook, function(ok)
        if not IsValid(form.Submit) then return end

        form.Submit:SetEnabled(true)

        if ok then cleared(form) end
    end)

    card.OnRemove = function()
        hook.Remove("DubzSuggestionsState", stateHook)
        hook.Remove("DubzSuggestionsResult", resultHook)
    end

    fillTopics(form)

    return card
end
