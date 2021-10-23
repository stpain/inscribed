

---addon namespace
local _, ns = ...

local L = ns.locales

---basic button mixin
InscribedSmallHighlightButtonMixin = {}

function InscribedSmallHighlightButtonMixin:OnLoad()
    if self.iconFileId then
        self.icon:SetTexture(self.iconFileId)
    elseif self.atlas then
        self.icon:SetAtlas(self.atlas)
    end

    if self.highlightAtlas then
        self.highlight:SetAtlas(self.highlightAtlas)
    end

    if self.rotate then
        self.icon:SetRotation(self.rotate)
    end
end

function InscribedSmallHighlightButtonMixin:OnShow()
    if self.hideBorder then
        self.iconBorder:Hide()
    end
end

function InscribedSmallHighlightButtonMixin:OnMouseDown()
    if self.disabled then
        return;
    end
    self:AdjustPointsOffset(-1,-1)
end

function InscribedSmallHighlightButtonMixin:OnMouseUp()
    if self.disabled then
        return;
    end
    self:AdjustPointsOffset(1,1)
    if self.func then
        C_Timer.After(0, self.func)
    end
end

function InscribedSmallHighlightButtonMixin:OnEnter()
    if self.tooltipText and L[self.tooltipText] then
        GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
        GameTooltip:AddLine("|cffffffff"..L[self.tooltipText])
        GameTooltip:Show()
    elseif self.tooltipText and not L[self.tooltipText] then
        GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
        GameTooltip:AddLine(self.tooltipText)
        GameTooltip:Show()
    elseif self.link then
        GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    else
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end
end

function InscribedSmallHighlightButtonMixin:OnLeave()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
end











---this is the listview template mixin
InscribedListviewMixin = CreateFromMixins(CallbackRegistryMixin);
InscribedListviewMixin:GenerateCallbackEvents(
    {
        "OnSelectionChanged",
        "OnDataTableChanged",
    }
);

function InscribedListviewMixin:OnLoad()

    ---these values are set in the xml frames KeyValues, it allows us to reuse code by setting listview item values in xml
    if type(self.itemTemplate) ~= "string" then
        error("self.itemTemplate name not set or not of type string")
        return;
    end
    if type(self.frameType) ~= "string" then
        error("self.frameType not set or not of type string")
        return;
    end
    if type(self.elementHeight) ~= "number" then
        error("self.elementHeight not set or not of type number")
        return;
    end

    CallbackRegistryMixin.OnLoad(self)

    ---when the user changes the listview (via the menu buttons) the data is flushed and the new data inserted
    ---here we setup a callback so that any selected items from a previous menu will be reselected
    self:RegisterCallback("OnDataTableChanged", self.OnDataTableChanged, self)

    self.DataProvider = CreateDataProvider();
    self.scrollView = CreateScrollBoxListLinearView();
    self.scrollView:SetDataProvider(self.DataProvider);

    ---height is defined in the xml keyValues
    local height = self.elementHeight;
    self.scrollView:SetElementExtent(height);

    self.scrollView:SetElementInitializer(self.frameType, self.itemTemplate, GenerateClosure(self.OnElementInitialize, self));
    self.scrollView:SetElementResetter(GenerateClosure(self.OnElementReset, self));

    self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.scrollView);
    self.selectionBehavior:RegisterCallback("OnSelectionChanged", self.OnElementSelectionChanged, self);

    self.scrollView:SetPadding(5, 5, 5, 5, 1);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.scrollView);

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", 0, 4),
    };
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4),
    };
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar, anchorsWithBar, anchorsWithoutBar);
end

function InscribedListviewMixin:OnElementInitialize(element, elementData, isNew)
    if isNew then
        Mixin(element, InscribedListviewItemTemplateMixin);
        element:OnLoad();
    end

    local height = self.elementHeight;
    element:SetDataBinding(elementData, height);
    element:RegisterCallback("OnMouseDown", self.OnElementClicked, self);
end

function InscribedListviewMixin:OnElementReset(element)
    element:UnregisterCallback("OnMouseDown", self);
end

function InscribedListviewMixin:OnElementClicked(element)
    self.selectionBehavior:Select(element);
end

function InscribedListviewMixin:OnDataTableChanged(newTable)
    for k, elementData in ipairs(newTable) do
        if elementData.selected then
            self:OnElementSelectionChanged(elementData, true)
        end
    end
end

function InscribedListviewMixin:OnElementSelectionChanged(elementData, selected)
    --DevTools_Dump({ self.selectionBehavior:GetSelectedElementData() })

    local element = self.scrollView:FindFrame(elementData);

    if element then
        element:SetSelected(selected);
    end

    if selected then
        self:TriggerEvent("OnSelectionChanged", elementData, selected);
    end
end









---this is a scroll frame option, kept for future use
-- local ContentFrameMixin = CreateFromMixins(ResizeLayoutMixin);

-- InscribedScrollableFrameTemplateMixin = {}

-- function InscribedScrollableFrameTemplateMixin:OnLoad()

--     self.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued);

--     self.scrollView = CreateScrollBoxLinearView();
--     self.scrollView:SetPanExtent(50);


--     self.contentFrame = CreateFrame("Frame", nil, self.scrollBox, "ResizeLayoutFrame");
--     self.contentFrame.scrollable = true;
--     --self.contentFrame:OnLoad();
--     self.contentFrame:SetPoint("TOPLEFT", self.scrollBox);
--     self.contentFrame:SetPoint("TOPRIGHT", self.scrollBox);
--     self.contentFrame:SetScript("OnSizeChanged", GenerateClosure(self.OnContentSizeChanged, self));

--     ScrollUtil.InitScrollBoxWithScrollBar(self.scrollBox, self.scrollBar, self.scrollView);

-- end

-- function InscribedScrollableFrameTemplateMixin:OnContentSizeChanged()
--     self.scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately);
-- end











InscribedListviewItemTemplateMixin = CreateFromMixins(CallbackRegistryMixin);
InscribedListviewItemTemplateMixin:GenerateCallbackEvents(
    {
        "OnMouseDown",
    }
);

function InscribedListviewItemTemplateMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self);
    self:SetScript("OnMouseDown", self.OnMouseDown);
end

function InscribedListviewItemTemplateMixin:OnMouseDown()
    self:TriggerEvent("OnMouseDown", self);
end

function InscribedListviewItemTemplateMixin:OnMouseUp()

end

function InscribedListviewItemTemplateMixin:SetSelected(selected)
    self.selected:SetShown(selected)
end

function InscribedListviewItemTemplateMixin:SetDataBinding(binding, height)
    --print(binding)
    if type(height) == "number" then
        self:SetHeight(height)
        self.icon:SetSize(height-8, height-8)
        self.icon:SetTexCoord(0.1,0.9,0.1,0.9)
        self.text:SetHeight(height)
    else
        error("template height not set or not of type number")
    end

    if type(binding) ~= "table" then
        error("binding is not a table")
        return;
    end

    --self.dataBinding = binding;
    self:SetSelected(binding.selected);

    ---for now this is a universal template so check each value
    if binding.name then
        self.text:SetText(binding.name)
    elseif binding.title then
        self.text:SetText(binding.title)
    else
        --error("binding.text and binding.name and binding.title are nil")
    end

    if type(binding.itemId) == "number" then
        local _, _, _, _, icon = GetItemInfoInstant(binding.itemId)
        if type(icon) == "number" then
            self.icon:SetTexture(icon)
        else
            --error("icon value returned from GetItemInfoInstant is not of type number")
        end
    else
        --error("binding.itemId is not of type number")
    end

    self.icon:SetTexture(134877)
end













---thsi is the template mixin for the insecure buttons used in the content panel
InscribedSecureMacroTemplateMixin = CreateFromMixins(CallbackRegistryMixin);
InscribedSecureMacroTemplateMixin:GenerateCallbackEvents(
    {
        "OnInscribedSecureMacroTemplateClicked",
    }
);

function InscribedSecureMacroTemplateMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self);
end

function InscribedSecureMacroTemplateMixin:OnEnter()
    ---if we have a valid item link then we can show the tooltip info
    if self.itemLink then
        local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(self.itemLink)
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetHyperlink(self.itemLink)
        if classID == 7 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff3399FF"..L["TRADEGOODS_AH_TOOLTIP"])
            if subclassID == 9 then
                GameTooltip:AddLine("|cff9999ff"..L["HERB_MILLING_TOOLTIP"])
            end
        end
        GameTooltip:Show()
    end
end

function InscribedSecureMacroTemplateMixin:OnLeave()
    ---return the tooltip to its defaults
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
end

---as we are using an insecure template to enable macro usage we'll make use of the OnMouseDown script to handle things
---@param button string the mouse button used
function InscribedSecureMacroTemplateMixin:OnMouseDown(button)
    self:TriggerEvent("OnInscribedSecureMacroTemplateClicked", self, button)
end

---clear the button display and data bindings
function InscribedSecureMacroTemplateMixin:ClearItem()
    self.icon:SetTexture(nil)
    self.name:SetText(nil)
    self.chance:SetText(nil)
    self.quantidy:SetText(nil)
    self.itemLink = nil;
    self.itemName = nil;
    self.binding = nil;
    self:Hide()
end

---set the item binding, this will also set `obj.itemLink` for valid items
---@param source table the item data to bind, must have at least a `source.itemId` entry
function InscribedSecureMacroTemplateMixin:SetItem(source)
    if type(source) == "table" then
        if type(source.itemId) == "number" then
            local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(source.itemId)
            ---to handle multiple languages we'll make use of the item mixin rather than rely on just the english db values
            local item = Item:CreateFromItemID(source.itemId)

            ---if we have no item from the mixin just set the display using the db value, no macro script will be setup
            if item:IsItemEmpty() then
                self.name:SetText(source.name)

            else
                item:ContinueOnItemLoad(function()
                    ---set the obj.itemLink for features such as shift click and tooltips
                    self.itemLink = item:GetItemLink()
                    self.itemName = item:GetItemName()
                    ---update the name displayed
                    self.name:SetText(self.itemName)
                    ---update the icon displayed
                    local icon = item:GetItemIcon()
                    self.icon:SetTexture(icon)

                    ---set the macro for right click milling
                    if classID == 7 and subclassID == 9 then
                        local macro = string.format(L["MILLING_MACRO_S"] , self.itemName)
                        ---waiting for wotlk for inscription items to exists so just print hello for now
                        self:SetAttribute("macrotext2", [[/run print("hello")]])
                    end
                end)
            end
        end

        ---as this obj handles multiple db items, we'll check what fields exists and set text as required
        if type(source.chance) == "number" then
            self.chance:SetText(string.format("%.2f", source.chance))
            self.chance:Show()
        else
            self.chance:SetText(nil)
            self.chance:Hide()
        end
        if type(source.quantidy) == "number" then
            self.quantidy:SetText(source.quantidy)
            self.quantidy:Show()
        else
            self.quantidy:SetText(nil)
            self.quantidy:Hide()
        end

        ---finally bind the source table and show the object, still need this?
        self.binding = source;
        self:Show()
    else
        self.icon:SetTexture(nil)
        self.name:SetText(nil)
        self.chance:SetText(nil)
        self.quantidy:SetText(nil)
        self:Hide()
    end
end

