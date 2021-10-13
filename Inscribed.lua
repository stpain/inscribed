
--[[
    inscription addon for classic wrath
]]


---addon namespace
local _, ns = ...

local L = ns.locales;

local CONTENT_PANEL_LIST_ROW_HEIGHT = 20.0

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

    self.viewHistory = {}

    ---setup the menu buttons
    self.guide.func = function()
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.guide)
        self.listview:TriggerEvent("OnDataTableChanged", ns.guide);
        wipe(self.viewHistory)
    end
    self.pigments.func = function()
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.pigments)
        self.listview:TriggerEvent("OnDataTableChanged", ns.pigments);
        wipe(self.viewHistory)
    end
    self.inks.func = function()
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.inks)
        self.listview:TriggerEvent("OnDataTableChanged", ns.inks);
        wipe(self.viewHistory)
    end
    self.minorResearch.func = function()
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.minorInscriptionResearch)
        self.listview:TriggerEvent("OnDataTableChanged", ns.minorInscriptionResearch);
        wipe(self.viewHistory)
    end
    self.northrendResearch.func = function()
        self.listview.DataProvider:Flush();
        self.listview.DataProvider:InsertTable(ns.northrendInscriptionResearch)
        self.listview:TriggerEvent("OnDataTableChanged", ns.northrendInscriptionResearch);
        wipe(self.viewHistory)
    end

    self.content.backButton.func = function()
        if #self.viewHistory > 0 then
            local previousContent = self.viewHistory[#self.viewHistory]
            --DevTools_Dump({ previousContent })
            local showBackButton = #self.viewHistory > 1 and true or false;
            self:SetContent(previousContent, showBackButton)
            self.viewHistory[#self.viewHistory] = nil;
        else

        end
    end

    ---register for when the lisview selection changes
    self.listview:RegisterCallback("OnSelectionChanged", self.OnListSelectionChanged, self);


    self.content.stepMaterials.title:SetText(L["STEP_MATERIALS_TITLE"])
    self.content.stepCreates.title:SetText(L["STEP_CREATES_TITLE"])

end

---this is currently calling a big function that covers all db types, this could be split and a value used to identify which db type is being loaded
---@param binding any the data table to load into view, this is from 1 of the tables in the Data.lua file
function InscribedMixin:OnListSelectionChanged(binding)
    self:SetContent(binding)
end


function InscribedMixin:FindDbEntryByItemId(db, itemId)
    if not ns[db] then
        error("no db of that name exists")
    end
    if type(itemId) ~= "number" then
        error("itemId is not of type number")
    end
    for k, v in ipairs(ns[db]) do
        if v.itemId == itemId then
            return ns[db][k]
        end
    end
    return false;
end

---load the data table into view, this could be split into the seperate db types
---@param binding any the data table to load into view, this is from 1 of the tables in the Data.lua file
function InscribedMixin:SetContent(binding, showBackButton)

    if showBackButton then
        self.content.backButton:Show()
    else
        self.content.backButton:Hide()
    end

    local content = self.content
    content.title:SetText(binding.name or binding.title)
    content.notes:SetText(binding.notes)
    content.pigmentSources:Hide()
    content.inkMaterials:Hide()
    content.stepMaterials:Hide()
    content.stepCreates:Hide()


    ---TODO: maybe make this better, perhaps add a value to the addon ui to check which view?
    ---using .sources to identify if this is a pigment item
    if binding.sources then

        ---lets get the higher drop chance listed first
        table.sort(binding.sources, function(a,b)
            if a.chance == b.chance then
                return a.name < b.name;
            else
                return a.chance > b.chance;
            end
        end)

        content.notes:SetText(L["PIGMENT_NOTE"])
        
        content.pigmentSources:Show()
        content.pigmentSources:SetHeight(#binding.sources*CONTENT_PANEL_LIST_ROW_HEIGHT)

        if content.pigmentSources.rows then
            for _, row in ipairs(content.pigmentSources.rows) do
                row:ClearItem()
            end
        end

        for k, source in ipairs(binding.sources) do
            if not content.pigmentSources.rows then
                content.pigmentSources.rows = {}
            end
            if not content.pigmentSources.rows[k] then
                local row = CreateFrame("BUTTON", nil, content.pigmentSources, "InscribedSecureMacroTemplate")
                row:SetPoint("TOP", 0, ((k-1)*-CONTENT_PANEL_LIST_ROW_HEIGHT)-2)
                row:SetSize(280, CONTENT_PANEL_LIST_ROW_HEIGHT)
                row.icon:SetSize(CONTENT_PANEL_LIST_ROW_HEIGHT-2, CONTENT_PANEL_LIST_ROW_HEIGHT-2)
                row.iconBorder:SetSize(CONTENT_PANEL_LIST_ROW_HEIGHT, CONTENT_PANEL_LIST_ROW_HEIGHT)
                row:SetItem(source)

                content.pigmentSources.rows[k] = row
            else
                content.pigmentSources.rows[k]:SetItem(source)
            end
        end
    end


    if binding.pigments then

        content.notes:SetText(L["INK_NOTE"])
        
        content.inkMaterials:Show()
        content.inkMaterials:SetHeight(#binding.pigments*CONTENT_PANEL_LIST_ROW_HEIGHT)

        if content.inkMaterials.rows then
            for _, row in ipairs(content.inkMaterials.rows) do
                row:ClearItem()
            end
        end

        for k, source in ipairs(binding.pigments) do
            if not content.inkMaterials.rows then
                content.inkMaterials.rows = {}
            end
            if not content.inkMaterials.rows[k] then
                local row = CreateFrame("BUTTON", nil, content.inkMaterials, "InscribedSecureMacroTemplate")
                row:SetPoint("TOP", 0, ((k-1)*-CONTENT_PANEL_LIST_ROW_HEIGHT)-2)
                row:SetSize(280, CONTENT_PANEL_LIST_ROW_HEIGHT)
                row.icon:SetSize(CONTENT_PANEL_LIST_ROW_HEIGHT-2, CONTENT_PANEL_LIST_ROW_HEIGHT-2)
                row.iconBorder:SetSize(CONTENT_PANEL_LIST_ROW_HEIGHT, CONTENT_PANEL_LIST_ROW_HEIGHT)
                row:SetItem(source)

                row:SetScript("OnMouseDown", function(_, button)
                    if button == "LeftButton" then
                        local elementData = self:FindDbEntryByItemId("pigments", source.itemId)
                        if type(elementData) == "table" then
                            table.insert(self.viewHistory, binding)
                            self:SetContent(elementData, true)
                        end
                    end
                end)

                content.inkMaterials.rows[k] = row
            else
                content.inkMaterials.rows[k]:SetItem(source)

                content.inkMaterials.rows[k]:SetScript("OnMouseDown", function(_, button)
                    if button == "LeftButton" then
                        local elementData = self:FindDbEntryByItemId("pigments", source.itemId)
                        if type(elementData) == "table" then
                            table.insert(self.viewHistory, binding)
                            self:SetContent(elementData, true)
                        end
                    end
                end)
            end
        end
    end

    if binding.materials then
    
        content.stepMaterials:Show()
        content.stepMaterials:SetHeight(#binding.materials*CONTENT_PANEL_LIST_ROW_HEIGHT)

        if content.stepMaterials.rows then
            for _, row in ipairs(content.stepMaterials.rows) do
                row:ClearItem()
            end
        end

        for k, source in ipairs(binding.materials) do
            if not content.stepMaterials.rows then
                content.stepMaterials.rows = {}
            end
            if not content.stepMaterials.rows[k] then
                local row = CreateFrame("BUTTON", nil, content.stepMaterials, "InscribedSecureMacroTemplate")
                row:SetPoint("TOP", 0, (k*-CONTENT_PANEL_LIST_ROW_HEIGHT)-2)
                row:SetSize(280, CONTENT_PANEL_LIST_ROW_HEIGHT)
                row.icon:SetSize(CONTENT_PANEL_LIST_ROW_HEIGHT-2, CONTENT_PANEL_LIST_ROW_HEIGHT-2)
                row.iconBorder:SetSize(CONTENT_PANEL_LIST_ROW_HEIGHT, CONTENT_PANEL_LIST_ROW_HEIGHT)
                row:SetItem(source)

                row:SetScript("OnMouseDown", function(_, button)
                    if button == "LeftButton" then
                        local elementData = self:FindDbEntryByItemId(source.dbName, source.itemId)
                        if type(elementData) == "table" then
                            table.insert(self.viewHistory, binding)
                            self:SetContent(elementData, true)
                        end
                    end
                end)

                content.stepMaterials.rows[k] = row
            else
                content.stepMaterials.rows[k]:SetItem(source)

                content.stepMaterials.rows[k]:SetScript("OnMouseDown", function(_, button)
                    if button == "LeftButton" then
                        local elementData = self:FindDbEntryByItemId(source.dbName, source.itemId)
                        if type(elementData) == "table" then
                            table.insert(self.viewHistory, binding)
                            self:SetContent(elementData, true)
                        end
                    end
                end)
            end
        end

    end

    if binding.creates then

        self.content.stepCreates.title:SetText(L["STEP_CREATES_TITLE"])

        content.stepCreates:Show()
        content.stepCreates:SetHeight(#binding.creates*CONTENT_PANEL_LIST_ROW_HEIGHT)

        if content.stepCreates.rows then
            for _, row in ipairs(content.stepCreates.rows) do
                row:ClearItem()
            end
        end

        for k, source in ipairs(binding.creates) do
            if not content.stepCreates.rows then
                content.stepCreates.rows = {}
            end
            if not content.stepCreates.rows[k] then
                local row = CreateFrame("BUTTON", nil, content.stepCreates, "InscribedSecureMacroTemplate")
                row:SetPoint("TOP", 0, (k*-CONTENT_PANEL_LIST_ROW_HEIGHT)-2)
                row:SetSize(280, CONTENT_PANEL_LIST_ROW_HEIGHT)
                row.icon:SetSize(CONTENT_PANEL_LIST_ROW_HEIGHT-2, CONTENT_PANEL_LIST_ROW_HEIGHT-2)
                row.iconBorder:SetSize(CONTENT_PANEL_LIST_ROW_HEIGHT, CONTENT_PANEL_LIST_ROW_HEIGHT)
                row:SetItem(source)
                
                row:SetScript("OnMouseDown", function(_, button)
                    if button == "LeftButton" then
                        local elementData = self:FindDbEntryByItemId(source.dbName, source.itemId)
                        if type(elementData) == "table" then
                            table.insert(self.viewHistory, binding)
                            self:SetContent(elementData, true)
                        end
                    end
                end)

                content.stepCreates.rows[k] = row
            else
                content.stepCreates.rows[k]:SetItem(source)

                content.stepCreates.rows[k]:SetScript("OnMouseDown", function(_, button)
                    if button == "LeftButton" then
                        local elementData = self:FindDbEntryByItemId(source.dbName, source.itemId)
                        if type(elementData) == "table" then
                            table.insert(self.viewHistory, binding)
                            self:SetContent(elementData, true)
                        end
                    end
                end)
            end
        end

        --content.stepCreates.contentFrame:MarkDirty();
    end

    if binding.teaches then

        self.content.stepCreates.title:SetText(L["STEP_TEACHES_TITLE"])

        content.stepCreates:Show()
        content.stepCreates:SetHeight(#binding.teaches*CONTENT_PANEL_LIST_ROW_HEIGHT)

        if content.stepCreates.rows then
            for _, row in ipairs(content.stepCreates.rows) do
                row:ClearItem()
            end
        end

        for k, source in ipairs(binding.teaches) do
            if not content.stepCreates.rows then
                content.stepCreates.rows = {}
            end
            if not content.stepCreates.rows[k] then
                local row = CreateFrame("BUTTON", nil, content.stepCreates.contentFrame, "InscribedSecureMacroTemplate")
                row:SetPoint("TOP", 0, ((k-1)*-CONTENT_PANEL_LIST_ROW_HEIGHT)-2)
                row:SetSize(255, CONTENT_PANEL_LIST_ROW_HEIGHT)
                row.icon:SetSize(CONTENT_PANEL_LIST_ROW_HEIGHT-2, CONTENT_PANEL_LIST_ROW_HEIGHT-2)
                row.iconBorder:SetSize(CONTENT_PANEL_LIST_ROW_HEIGHT, CONTENT_PANEL_LIST_ROW_HEIGHT)
                row:SetItem(source)

                content.stepCreates.rows[k] = row
            else
                content.stepCreates.rows[k]:SetItem(source)
            end
        end

        --content.stepCreates.contentFrame:MarkDirty();
    end

end