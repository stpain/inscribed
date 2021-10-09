

---addon namespace
local _, ns = ...

local L = ns.locales

---basic button mixin
InscribedSmallHighlightButtonMixin = {}

function InscribedSmallHighlightButtonMixin:OnLoad()
    if self.iconFileId then
        local fileId = self.iconFileId
        self.icon:SetTexture(fileId)
    end
end

function InscribedSmallHighlightButtonMixin:OnShow()

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












InscribedListviewMixin = CreateFromMixins(CallbackRegistryMixin);
InscribedListviewMixin:GenerateCallbackEvents(
    {
        "OnSelectionChanged",
        "OnDataTableChanged",
    }
);

function InscribedListviewMixin:OnLoad()

    ---these values are set in the xml frames KeyValues, it allows use to reuse code by setting listview item values in xml
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
    self.ScrollView = CreateScrollBoxListLinearView();
    self.ScrollView:SetDataProvider(self.DataProvider);

    ---height is defined in the xml keyValues
    local height = self.elementHeight;
    self.ScrollView:SetElementExtent(height);

    self.ScrollView:SetElementInitializer(self.frameType, self.itemTemplate, GenerateClosure(self.OnElementInitialize, self));
    self.ScrollView:SetElementResetter(GenerateClosure(self.OnElementReset, self));

    self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.ScrollView);
    self.selectionBehavior:RegisterCallback("OnSelectionChanged", self.OnElementSelectionChanged, self);

    self.ScrollView:SetPadding(5, 5, 5, 5, 1);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.ScrollView);

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self.ScrollBar, "BOTTOMLEFT", 0, 4),
    };
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4),
    };
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.ScrollBox, self.ScrollBar, anchorsWithBar, anchorsWithoutBar);
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
            local element = self.ScrollView:FindFrame(elementData);
            self:OnElementSelectionChanged(elementData, true)
        end
    end
end

function InscribedListviewMixin:OnElementSelectionChanged(elementData, selected)
    --DevTools_Dump({ self.selectionBehavior:GetSelectedElementData() })

    local element = self.ScrollView:FindFrame(elementData);

    if element then
        element:SetSelected(selected);
    end

    if selected then
        self:TriggerEvent("OnSelectionChanged", elementData, selected);
    end
end



















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
        error("binding.text and binding.name and binding.title are nil")
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







InscribedSourceTemplateMixin = {}

function InscribedSourceTemplateMixin:ClearSource()
    self.icon:SetTexture(nil)
    self.name:SetText(nil)
    self.chance:SetText(nil)
    self:Hide()
end

function InscribedSourceTemplateMixin:SetSource(source)
    if type(source) == "table" then
        if type(source.itemId) == "number" then
            local _, _, _, _, icon = GetItemInfoInstant(source.itemId)
            if type(icon) == "number" then
                self.icon:SetTexture(icon)
            else
                --error("icon value returned from GetItemInfoInstant is not of type number")
                self.icon:SetTexture(nil)
            end
        end
        if type(source.name) == "string" then
            self.name:SetText(source.name)
        else
            self.name:SetText(nil)
            --error("source name is not of type string")
        end
        if type(source.chance) == "number" then
            self.chance:SetText(string.format("%.2f", source.chance))
        else
            self.chance:SetText(nil)
            --error("source chance is not of type string")
        end
        self:Show()
    else
        self.icon:SetTexture(nil)
        self.name:SetText(nil)
        self.chance:SetText(nil)
        self:Hide()
    end
end


InscribedMaterialsTemplateMixin = {}

function InscribedMaterialsTemplateMixin:ClearMaterials()
    self.icon:SetTexture(nil)
    self.name:SetText(nil)
    self.quantidy:SetText(nil)
    self:Hide()
end

function InscribedMaterialsTemplateMixin:SetMaterials(source)
    if type(source) == "table" then
        if type(source.itemId) == "number" then
            local _, _, _, _, icon = GetItemInfoInstant(source.itemId)
            if type(icon) == "number" then
                self.icon:SetTexture(icon)
            else
                --error("icon value returned from GetItemInfoInstant is not of type number")
                self.icon:SetTexture(nil)
            end
        end
        if type(source.name) == "string" then
            self.name:SetText(source.name)
        else
            self.name:SetText(nil)
            --error("source name is not of type string")
        end
        if type(source.quantidy) == "number" then
            self.quantidy:SetText(string.format("%.2f", source.quantidy))
        else
            self.quantidy:SetText(nil)
            --error("source quantidy is not of type string")
        end
        self:Show()
    else
        self.icon:SetTexture(nil)
        self.name:SetText(nil)
        self.quantidy:SetText(nil)
        self:Hide()
    end
end


InscribedCreatesTemplateMixin = {}

function InscribedCreatesTemplateMixin:ClearItem()
    self.icon:SetTexture(nil)
    self.name:SetText(nil)
    self.quantidy:SetText(nil)
    self:Hide()
end

function InscribedCreatesTemplateMixin:SetItem(source)
    if type(source) == "table" then
        if type(source.itemId) == "number" then
            local _, _, _, _, icon = GetItemInfoInstant(source.itemId)
            if type(icon) == "number" then
                self.icon:SetTexture(icon)
            else
                --error("icon value returned from GetItemInfoInstant is not of type number")
                self.icon:SetTexture(nil)
            end
        end
        if type(source.name) == "string" then
            self.name:SetText(source.name)
        else
            self.name:SetText(nil)
            --error("source name is not of type string")
        end
        if type(source.quantidy) == "number" then
            self.quantidy:SetText(string.format("%.2f", source.quantidy))
        else
            self.quantidy:SetText(nil)
            --error("source quantidy is not of type string")
        end
        self:Show()
    else
        self.icon:SetTexture(nil)
        self.name:SetText(nil)
        self.quantidy:SetText(nil)
        self:Hide()
    end
end


