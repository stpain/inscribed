
--[[
    inscription addon for classic wrath
]]


---addon namespace
local _, ns = ...


InscribedMixin = {}

---navigate to a view, this will hide all listviews and then show the given listview
---@param listview any the listview to show
function InscribedMixin:NavigateTo(listview)
    for _, f in ipairs(self.listviews) do
        f:Hide()
    end
    for _, f in ipairs(self.listviewChildContent) do
        f:Hide()
    end
    listview:Show()
end

function InscribedMixin:OnLoad()

    local name = self:GetName()

    self:RegisterForDrag("LeftButton")

    SetPortraitToTexture(name.."Portrait", 134487)

    tinsert(UISpecialFrames, name);

    ---this works as another addon has the libs installed, check before releasing
    local ldb = LibStub("LibDataBroker-1.1")
    self.MinimapButton = ldb:NewDataObject('InscribedMinimapIcon', {
        type = "data source",
        icon = 134487,
        OnClick = function(self, button)
            Inscribed:Show()
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine(tostring('|cff0070DE'..name))
        end,
    })
    self.MinimapIcon = LibStub("LibDBIcon-1.0")
    self.MinimapIcon:Register('InscribedMinimapIcon', self.MinimapButton, {})


    self.guide.func = function()
        --self:NavigateTo(self.guideListview)
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.guide)
    end
    self.pigments.func = function()
        --self:NavigateTo(self.pigmentListview)
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.pigments)
    end
    self.inks.func = function()
        --self:NavigateTo(self.inksListview)
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.inks)
    end


    -- self.guideListview.DataProvider:InsertTable(ns.guide)
    -- self.pigmentListview.DataProvider:InsertTable(ns.pigments)
    -- self.inksListview.DataProvider:InsertTable(ns.inks)







end