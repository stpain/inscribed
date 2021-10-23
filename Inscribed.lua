
--[[
    inscription addon for classic wrath
]]


---addon namespace
local addonName, ns = ...

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

    ---this table holds the content view item bindings and is used with the back button
    self.viewHistory = {}

    ---setup the menu buttons, these values are also the db names from the Data.lua file
    ---if this causes an issue we can just change this table to contain table names and xml names.
    local menu = {
        "glyphs",
        "inks",
        "pigments",
        "northrendResearch",
        "minorResearch",
        "guide",
    }
    local offsetY = 70.0;
    for k, menu in ipairs(menu) do
        self[menu]:SetPoint("TOPLEFT", 10, ((k-1) * -45) - offsetY)
        self[menu].func = function()
            self.listview.DataProvider:Flush();
            self.listview.DataProvider:InsertTable(ns[menu])
            self.listview:TriggerEvent("OnDataTableChanged", ns[menu]);
            wipe(self.viewHistory)
            self:SelectMenuButton(self[menu])
        end
    end

    ---setup the back button
    self.content.backButton.func = function()
        if #self.viewHistory > 0 then
            local previousContent = self.viewHistory[#self.viewHistory]
            --DevTools_Dump({ previousContent })
            local showBackButton = (#self.viewHistory > 1) and true or false;
            self:SetContent(previousContent, showBackButton)
            self.viewHistory[#self.viewHistory] = nil;
        end
    end

    ---register for when the lisview selection changes
    self.listview:RegisterCallback("OnSelectionChanged", self.OnListSelectionChanged, self);

    self.content.stepMaterials.title:SetText(L["STEP_MATERIALS_TITLE"])
    self.content.stepCreates.title:SetText(L["STEP_CREATES_TITLE"])

    ---create the table for player container items info
    self.playerContainers = {}


    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("ADDON_LOADED")

end

---listen to events and handle them
---@param event string the event name from blizzard
function InscribedMixin:OnEvent(event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        INSCRIBED_GLOBAL = {}
    end
end

---a basic function to hide then show the selected menu button selected texture
---@param button any the object to modify
function InscribedMixin:SelectMenuButton(button)
    for _, button in ipairs(self.menuButtons) do
        button.selected:Hide()
    end
    button.selected:Show()
end

---this is currently calling a big function that covers all db types, this could be split and a value used to identify which db type is being loaded
---@param binding any the data table to load into view, this is from 1 of the tables in the Data.lua file
function InscribedMixin:OnListSelectionChanged(binding)
    self:SetContent(binding)
end

---this object is the content view listview type buttons, usually displaying materials or items created
---this is triggered from the template when clicked and its purpose is to update the content view
---@param obj any the object clicked
---@param button string the button used
function InscribedMixin:OnInscribedSecureMacroTemplateClicked(obj, button)
    --DevTools_Dump({ ... })

    ---the dbItem is the table that we bound in the template, this was passed from when we set the content and looped the child tables
    ---we use dbItem to search for an item within a table using the dbItem.dbName foreign key and then dbItem.itemId as the lookup value
    ---name, link are set during the item:ContinueOnLoad callback in the template
    ---we use name, link to cover multiple languages as they are values returned from the server
    local dbItem = obj.binding;
    local name, link = obj.itemName, obj.itemLink
    --print(name, link)

    ---setup the AH interaction, alt+click will (when possible) search the AH for the item
    if IsAltKeyDown() and name and CanSendAuctionQuery() then
        ---this call will only populate page 0, using the next/prev page buttons will display an all items scan
        ---to get around this we just add the item name to the search box and click search to replicate a user search
        --QueryAuctionItems(self.binding.name, nil, nil, 0, false, nil, false, false, { classID = 7, subClassID = 9 })
        BrowseName:SetText(name)
        BrowseSearchButton:Click()

    ---enable the shift click linking if an itemLink exists
    elseif IsShiftKeyDown() and link then
        HandleModifiedItemClick(link)

    ---add this view to the history and load the next view
    elseif button == "LeftButton" and dbItem.dbName and dbItem.itemId then
        local currentBinding = self.content.binding;
        local elementData = self:FindDbEntryByItemId(dbItem.dbName, dbItem.itemId)
        if type(elementData) == "table" then
            table.insert(self.viewHistory, currentBinding)
            self:SetContent(elementData, true)
        end
    end
end

---db items have a foreign key `dbName`, this function will search for an item using this key and an itemId
---@param db string the db to search, these are found in the Data.lua file `ns[dbName]`
---@param itemId number the itemId value to search for
function InscribedMixin:FindDbEntryByItemId(db, itemId)
    if not ns[db] then
        error(string.format("couldnt find [%s] in [%s] as no db of that name exists", itemId, db))
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


---scan the players bags for inscription items and materials
function InscribedMixin:ScanPlayerBags()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local _, count, _, _, _, _, link, _, _, _ = GetContainerItemInfo(bag, slot)
            local exists = false;
            if link and count then
                local itemId, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = GetItemInfoInstant(link)
                exists = false;
                for _, v in ipairs(self.containers) do
                    if v.itemId == itemId then
                        exists = true;
                        v.count = v.count + count;
                    end
                end
                if exists == false then
                    table.insert(self.containers, {
                        itemId = itemId,
                        count = count,
                        link = link,
                        classId = classID,
                        subClassId = subclassID,
                        icon = icon,
                    })
                end
            end
        end
    end
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

    content.binding = binding;


    ---TODO: maybe make this better, perhaps add a value to the addon ui to check which view? OR just have a universal ui layout for all items?
    
    ---display a pigment item
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
                row:RegisterCallback("OnInscribedSecureMacroTemplateClicked", self.OnInscribedSecureMacroTemplateClicked, self);

                content.pigmentSources.rows[k] = row
            else
                content.pigmentSources.rows[k]:SetItem(source)
            end
        end
    end

    ---we have an ink item being displayed
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
                row:RegisterCallback("OnInscribedSecureMacroTemplateClicked", self.OnInscribedSecureMacroTemplateClicked, self);

                content.inkMaterials.rows[k] = row
            else
                content.inkMaterials.rows[k]:SetItem(source)

            end
        end
    end

    ---guide item
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
                row:RegisterCallback("OnInscribedSecureMacroTemplateClicked", self.OnInscribedSecureMacroTemplateClicked, self);

                content.stepMaterials.rows[k] = row
            else
                content.stepMaterials.rows[k]:SetItem(source)

            end
        end

    end

    ---guide item again
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
                row:RegisterCallback("OnInscribedSecureMacroTemplateClicked", self.OnInscribedSecureMacroTemplateClicked, self);

                content.stepCreates.rows[k] = row
            else
                content.stepCreates.rows[k]:SetItem(source)

            end
        end

        --content.stepCreates.contentFrame:MarkDirty();
    end

    ---guide item again
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
                row:RegisterCallback("OnInscribedSecureMacroTemplateClicked", self.OnInscribedSecureMacroTemplateClicked, self);

                content.stepCreates.rows[k] = row
            else
                content.stepCreates.rows[k]:SetItem(source)
            end
        end

    end

    ---glyph item
    if binding.class and binding.requiredLevel then
        local info = string.format("Type: %s \nClass: %s \nRequired level: %s \nLevel: %s", binding.type, binding.class, binding.requiredLevel, binding.level)

        self.content.notes:SetText(info)
    end

end