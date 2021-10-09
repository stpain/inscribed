
--[[
    inscription addon for classic wrath
]]


---addon namespace
local _, ns = ...

local L = ns.locales;

local PIGMENT_SOURCE_ROW_HEIGHT = 20.0

InscribedMixin = {}


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

    ---setup the menu buttons
    self.guide.func = function()
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.guide)
        self.listview:TriggerEvent("OnDataTableChanged", ns.guide);
    end
    self.pigments.func = function()
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.pigments)
        self.listview:TriggerEvent("OnDataTableChanged", ns.pigments);
    end
    self.inks.func = function()
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.inks)
        self.listview:TriggerEvent("OnDataTableChanged", ns.inks);
    end

    ---register for when the lisview selection changes
    self.listview:RegisterCallback("OnSelectionChanged", self.OnListSelectionChanged, self);


end

---this is currently calling a big function that covers all db types, thsi could be split and a value used to identify which db type is being loaded
---@param binding any the data table to load into view, this is from 1 of the tables in the Data.lua file
function InscribedMixin:OnListSelectionChanged(binding)
    self:SetContent(binding)
end

---load the data table into view, this could be split into the seperate db types
---@param binding any the data table to load into view, this is from 1 of the tables in the Data.lua file
function InscribedMixin:SetContent(binding)

    local content = self.content
    content.title:SetText(binding.name or binding.title)
    content.notes:SetText(binding.notes)
    content.pigmentSources:Hide()
    content.inkMaterials:Hide()


    ---TODO: maybe make this better, perhaps add a value to the addon ui to check which view?
    ---using .sources to identify if this is a pigment item
    if binding.sources then

        content.notes:SetText(L["PIGMENT_NOTE"])
        
        content.pigmentSources:Show()
        content.pigmentSources:SetHeight(#binding.sources*PIGMENT_SOURCE_ROW_HEIGHT)

        if content.pigmentSources.rows then
            for _, row in ipairs(content.pigmentSources.rows) do
                row:ClearPigmentSource()
            end
        end

        for k, source in ipairs(binding.sources) do
            if not content.pigmentSources.rows then
                content.pigmentSources.rows = {}
            end
            if not content.pigmentSources.rows[k] then
                local row = CreateFrame("FRAME", nil, content.pigmentSources, "InscribedPigmentSourceTemplate")
                row:SetPoint("TOP", 0, ((k-1)*-PIGMENT_SOURCE_ROW_HEIGHT)-2)
                row:SetSize(280, PIGMENT_SOURCE_ROW_HEIGHT)
                row.icon:SetSize(PIGMENT_SOURCE_ROW_HEIGHT-2, PIGMENT_SOURCE_ROW_HEIGHT-2)
                row.iconBorder:SetSize(PIGMENT_SOURCE_ROW_HEIGHT, PIGMENT_SOURCE_ROW_HEIGHT)
                row:SetPigmentSource(source)

                content.pigmentSources.rows[k] = row
            else
                content.pigmentSources.rows[k]:SetPigmentSource(source)
            end
        end
    end


    if binding.pigments then

        content.notes:SetText(L["INK_NOTE"])
        
        content.inkMaterials:Show()
        content.inkMaterials:SetHeight(#binding.pigments*PIGMENT_SOURCE_ROW_HEIGHT)

        if content.inkMaterials.rows then
            for _, row in ipairs(content.inkMaterials.rows) do
                row:ClearInkMaterials()
            end
        end

        for k, source in ipairs(binding.pigments) do
            if not content.inkMaterials.rows then
                content.inkMaterials.rows = {}
            end
            if not content.inkMaterials.rows[k] then
                local row = CreateFrame("FRAME", nil, content.inkMaterials, "InscribedInkMaterialsTemplate")
                row:SetPoint("TOP", 0, ((k-1)*-PIGMENT_SOURCE_ROW_HEIGHT)-2)
                row:SetSize(280, PIGMENT_SOURCE_ROW_HEIGHT)
                row.icon:SetSize(PIGMENT_SOURCE_ROW_HEIGHT-2, PIGMENT_SOURCE_ROW_HEIGHT-2)
                row.iconBorder:SetSize(PIGMENT_SOURCE_ROW_HEIGHT, PIGMENT_SOURCE_ROW_HEIGHT)
                row:SetInkMaterials(source)

                content.inkMaterials.rows[k] = row
            else
                content.inkMaterials.rows[k]:SetInkMaterials(source)
            end
        end
    end
end