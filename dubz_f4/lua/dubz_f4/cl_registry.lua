local config = DubzF4.Config

DubzF4.State = DubzF4.State or {Frame = nil, LastToggle = 0, LastTab = nil}

DubzF4.Tabs = DFW.Registry.Create("dubz_f4_tabs", {
    allowOverride = true,
    sort = function(a, b) return (a.order or 0) < (b.order or 0) end
})

function DubzF4.ActiveTabs()
    local active = {}

    for _, tab in ipairs(DubzF4.Tabs:All()) do
        if config.Tabs[tab.ID] ~= false then active[#active + 1] = tab end
    end

    return active
end

function DubzF4.Rows(collectionId)
    return DFW.Collections.Get("f4", collectionId) or {}
end
