local Jobs = DubzF4.Jobs
local Ui = DubzF4.Ui
local Adapter = DubzF4.Adapter
local config = DubzF4.Config
local MODEL_SHARE = 0.42
local BUTTON_HEIGHT = 42
local CHIP_HEIGHT = 52
local CHIP_INSET = 12
local THUMB_SIZE = 48
local THUMB_GAP = 6

local CAMERA_DIRECTION = Vector(1, 0.55, 0.12)
local FIT_MARGIN = 1.2

local function fitCamera(model)
    local entity = model.Entity
    local w, h = model:GetSize()

    model:SetFOV(config.ModelFov)

    if not IsValid(entity) or w <= 0 or h <= 0 then return end

    local mins, maxs = entity:GetRenderBounds()
    local center = (mins + maxs) * 0.5
    local height = maxs.z - mins.z
    local width = math.max(maxs.x - mins.x, maxs.y - mins.y)
    local half = math.rad(config.ModelFov) / 2
    local verticalHalf = math.atan(math.tan(half) * h / w)
    local distance = math.max(height * 0.5 * FIT_MARGIN / math.tan(verticalHalf), width * 0.5 * FIT_MARGIN / math.tan(half))
    local sequence = entity:LookupSequence("idle_all_01")

    model:SetLookAt(center)
    model:SetCamPos(center + CAMERA_DIRECTION:GetNormalized() * distance)

    if sequence and sequence > 0 then entity:SetSequence(sequence) end
end

local function showModel(model, path)
    model:SetModel(path)
    fitCamera(model)
end

local function addModel(card, entry)
    local model = vgui.Create("DModelPanel", card)
    local models = Adapter.JobModels(entry.job)
    local chosen = Jobs.Chosen[entry.id]

    if not (chosen and table.HasValue(models, chosen)) then chosen = models[1] end

    Jobs.Chosen[entry.id] = chosen
    model:Dock(TOP)
    showModel(model, chosen)
    model.LayoutEntity = function(self, entity)
        entity:SetAngles(Angle(0, 30 + SysTime() * config.ModelSpin, 0))
        self:RunAnimation()
    end

    local base = model.PerformLayout

    model.PerformLayout = function(self, w, h)
        if base then base(self, w, h) end

        fitCamera(self)
    end

    card.PerformLayout = function(_, _, h) model:SetTall(math.floor(h * MODEL_SHARE)) end

    return model
end

local function paintThumb(button, entry, path, w, h)
    local theme = DFW.UI.GetTheme()
    local picked = Jobs.Chosen[entry.id] == path
    local hover = DFW.Anim.Lerp(button, "hover", button:IsHovered() and 1 or 0, 14)

    draw.RoundedBox(DFW.UI.Radius("SM"), 0, 0, w, h, DFW.Anim.Color(theme.surfaceAlt, theme.raised, picked and 1 or hover * 0.6))

    if picked then
        surface.SetDrawColor(DFW.UI.WithAlpha(entry.job.color or theme.accent, 160))
        surface.DrawRect(6, h - 2, w - 12, 1)
    end
end

local function addModelStrip(card, entry, model)
    local models = Adapter.JobModels(entry.job)
    local strip = vgui.Create("Panel", card)

    strip:Dock(TOP)
    strip:SetTall(THUMB_SIZE)
    strip:DockMargin(0, DFW.UI.Space("SM"), 0, 0)

    for index, path in ipairs(models) do
        local button = vgui.Create("DButton", strip)
        local icon = vgui.Create("SpawnIcon", button)

        button:SetText("")
        button:SetPos((index - 1) * (THUMB_SIZE + THUMB_GAP), 0)
        button:SetSize(THUMB_SIZE, THUMB_SIZE)
        icon:SetSize(THUMB_SIZE - 6, THUMB_SIZE - 6)
        icon:SetPos(3, 3)
        icon:SetModel(path)
        icon:SetMouseInputEnabled(false)
        button.Paint = function(self, w, h) paintThumb(self, entry, path, w, h) end
        button.DoClick = function()
            Jobs.Chosen[entry.id] = path
            showModel(model, path)
        end
    end
end

local function addChip(row, title, valueFn)
    local chip = Ui.Card(row)
    local caption = Ui.Label(chip, string.upper(title), "tiny")
    local value = Ui.Label(chip, "", "bodybold")

    chip:SetCardColor(DFW.UI.GetTheme().surfaceAlt)
    value.Think = function(self) self:SetText(valueFn()) end
    chip.PerformLayout = function(_, w)
        caption:SetPos(CHIP_INSET, 8)
        caption:SetSize(w - CHIP_INSET * 2, 14)
        value:SetPos(CHIP_INSET, 26)
        value:SetSize(w - CHIP_INSET * 2, 20)
    end
end

local function addChips(card, entry)
    local row = vgui.Create("Panel", card)
    local job = entry.job
    local access = (job.admin and job.admin > 0) and "AccessStaff" or (job.vote and "AccessVote" or "AccessOpen")

    row:Dock(TOP)
    row:SetTall(CHIP_HEIGHT)
    row:DockMargin(0, DFW.UI.Space("SM"), 0, DFW.UI.Space("SM"))
    Ui.Distribute(row, DFW.UI.Space("SM"))

    addChip(row, DubzF4.Phrase("Salary"), function() return Adapter.FormatMoney(job.salary or 0) end)
    addChip(row, DubzF4.Phrase("Slots"), function()
        local max = Jobs.Max(job)

        return team.NumPlayers(entry.id) .. " / " .. (max > 0 and max or "-")
    end)
    addChip(row, DubzF4.Phrase("Access"), function() return DubzF4.Phrase(access) end)
end

local function addDescription(card, job)
    local scroll = Ui.Scroll(card)
    local description = Ui.Paragraph(scroll, job.description or DubzF4.Phrase("NoDescription"), "body", DFW.UI.GetTheme().textMuted)
    local names = {}

    scroll:Dock(FILL)
    description:Dock(TOP)
    description:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("MD"))

    for _, class in ipairs(job.weapons or {}) do
        local weapon = weapons.Get(class)

        names[#names + 1] = (weapon and weapon.PrintName and weapon.PrintName ~= "") and weapon.PrintName or tostring(class)
    end

    if #names == 0 then return end

    Ui.Label(scroll, string.upper(DubzF4.Phrase("Loadout")), "tiny"):Dock(TOP)
    Ui.Paragraph(scroll, table.concat(names, ", "), "body", DFW.UI.GetTheme().text):Dock(TOP)
end

local function addBecome(card, entry)
    local job, id = entry.job, entry.id
    local button = vgui.Create("DFW.Button", card)

    button:Dock(BOTTOM)
    button:SetTall(BUTTON_HEIGHT)
    button:DockMargin(0, DFW.UI.Space("SM"), 0, 0)
    button:SetVariant("primary")
    button.DoClick = function() Jobs.Become(id, job) end
    button.Think = function(self)
        local ok, reason, current = Jobs.State(entry)

        self:SetEnabled(ok == true)

        if current then self:SetLabel(DubzF4.Phrase("CurrentJob")) elseif not ok then self:SetLabel(reason or DubzF4.Phrase("Locked")) else
            self:SetLabel(DubzF4.Phrase("BecomeJob", {job = job.name or ""}))
        end
    end
end

function Jobs.BuildDetail(parent)
    local card = Ui.Card(parent)
    local pad = DFW.UI.Space("LG")

    card:DockPadding(pad, pad, pad, pad)

    return {
        Panel = card,
        Show = function(entry)
            card:Clear()
            card.PerformLayout = nil
            addModelStrip(card, entry, addModel(card, entry))
            Ui.Label(card, entry.job.name or "?", "title", entry.job.color):Dock(TOP)
            addChips(card, entry)
            addBecome(card, entry)
            addDescription(card, entry.job)
        end
    }
end
