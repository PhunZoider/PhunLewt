if isServer() then
    return
end
require "PhunLewt/ui/base"
local tools = require "PhunLewt/ui/tools"
local Core = PhunLewt
local PL = PhunLib
local profileName = "PhunLewtItems"
Core.ui.items = PhunLewtBase:derive(profileName);
local UI = Core.ui.items

function UI:createChildren()
    self.data = {
        selectedItems = {},
        categories = {},
        items = {},
        data = {}
    }
    ISPanelJoypad.createChildren(self)
    local padding = 10
    local x = 0
    local y = 0

    self.controls = {}

    -- container for the inline filters below the list
    local filtersPanel = ISPanel:new(0, self.height - 100, self.width, 130);
    filtersPanel.drawBorder = false
    filtersPanel:initialise();
    filtersPanel:instantiate();
    filtersPanel.backgroundColor = {
        r = 0.1,
        g = 0.1,
        b = 0.1,
        a = 0.8
    }

    self.controls.filtersPanel = filtersPanel
    self:addChild(filtersPanel);

    -- list of items
    local list = tools.getListbox(x + padding, y + padding, self:getWidth() - (padding * 2), filtersPanel.y,
        {getText("Item"), {getText("IGUI_PhunLewt_Category_Header"), self.width - 200},
         {getText("IGUI_PhunLewt_Reduction_Percent"), self.width - 100}}, {
            draw = self.drawDatas,
            click = self.click,
            rightClick = self.rightClick,
            doubleClick = self.doubleClick
        })

    self.controls.list = list
    self:addChild(list)

    -- filter label
    local lblFilter = tools.getLabel(getText("IGUI_PhunLewt_Filter"), padding, padding)
    filtersPanel:addChild(lblFilter)

    -- filter text input
    local filter = ISTextEntryBox:new("", padding, y, filtersPanel.width - 200, tools.BUTTON_HGT);
    filter.onTextChange = function()
        self:refreshData()
    end
    self.controls.filter = filter
    filter:initialise();
    filter:instantiate();
    filtersPanel:addChild(filter);

    local left = filter.x + filter.width + padding

    -- filter category label
    local lblFilterCategory = tools.getLabel(getText("IGUI_PhunLewt_Category_Header"), filtersPanel.width - x - left,
        padding)
    filtersPanel:addChild(lblFilterCategory)
    self.controls.lblFilterCategory = lblFilterCategory
    local filterCategory = ISComboBox:new(left, y, filtersPanel.width - x - left, tools.FONT_HGT_MEDIUM, self,
        function()
            self:refreshData()
        end);
    filterCategory:initialise();
    filterCategory:instantiate();

    self.controls.filterCategory = filterCategory
    filtersPanel:addChild(filterCategory);

    local showAll = ISTickBox:new(filter.x, filter.y + filter.height + tools.BUTTON_HGT + padding * 2, 25, 25, "", self,
        function()
        end)
    showAll:initialise();
    showAll:addOption(getText("IGUI_PhunLewt_ShowAll"));
    showAll.changeOptionMethod = function()
        self:refreshData()
    end
    self.controls.showAll = showAll
    showAll:setSelected(1, true)
    filtersPanel:addChild(showAll);

    -- tooltip
    self.tooltip = ISToolTipInv:new();
    self.tooltip:initialise();
    self.tooltip:setVisible(false);
    self.tooltip:setAlwaysOnTop(true)
    self.tooltip.description = "";
    self.tooltip:setOwner(self.controls.list)

    -- data
    self.data.selectedItems = {}
    self.data.categories = PL.getAllItemCategories()
    self.data.items = PL.getAllItems()

    -- sort categories
    local catMap = {}
    local categories = {}
    filterCategory:clear()
    filterCategory:addOption("")
    for _, item in ipairs(self.data.items) do
        if not catMap[item.category] then
            catMap[item.category] = true
            table.insert(categories, item.category)
        end
    end

    table.sort(categories, function(a, b)
        return a:lower() < b:lower()
    end)

    -- add categories to filter
    for _, category in ipairs(categories) do
        filterCategory:addOption(category)
    end

    self:refreshData()
end

function UI:prerender()

    -- resize/reposition the filter panel and its children
    ISPanelJoypad.prerender(self)
    local padding = 10
    local filterPanel = self.controls.filtersPanel
    filterPanel:setWidth(filterPanel.parent.width)
    filterPanel:setY(filterPanel.parent.height - (filterPanel.height))

    local lblFilterCategory = self.controls.lblFilterCategory

    local filterCategory = self.controls.filterCategory
    filterCategory:setX(filterCategory.parent.width - filterCategory.width - padding)
    filterCategory:setY(lblFilterCategory.y + lblFilterCategory.height + padding)
    lblFilterCategory:setX(filterCategory.x)

    local filter = self.controls.filter
    filter:setWidth(filterCategory.x - filter.x - padding)
    filter:setY(lblFilterCategory.y + lblFilterCategory.height + padding)

    local list = self.controls.list
    list:setHeight(filterPanel.y - list.y - padding)

    if #list.columns > 1 and list.width < list.columns[#list.columns].size then
        for i = 2, #list.columns do
            list.columns[i].size = list.width / #list.columns
        end
    end

end

function UI:drawDatas(y, item, alt)
    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end

    local a = 0.9;

    if self.parent.data.selectedItems[item.item.type] then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.4, 0.7, 0.35, 0.15);
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.2, 0.6, 0.5, 0.5);
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g,
        self.borderColor.b);

    local iconX = 4
    local iconSize = tools.FONT_HGT_SMALL;
    local xoffset = 10;

    local clipX = self.columns[1].size
    local clipX2 = self.columns[2].size
    local clipX3 = self.columns[3].size
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight)

    if item.item.texture then
        local textured = self:drawTextureScaledAspect2(item.item.texture, xoffset, y, self.itemheight - 4,
            self.itemheight - 4, 1, 1, 1, 1)
        xoffset = xoffset + self.itemheight + 4
    end

    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.text, xoffset, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    local value = item.item.category or ""
    local cw = self.columns[2].size
    self:setStencilRect(clipX2, clipY, clipX3 - clipX2, clipY2 - clipY)
    self:drawText(value, cw + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    value = ""
    if self.parent.data.data[item.item.type] then
        value = "-" .. tostring(self.parent.data.data[item.item.type]) .. "%"
    end
    cw = self.columns[3].size
    self:setStencilRect(clipX3, clipY, self:getWidth() - clipX3 - self.vscroll.width, clipY2 - clipY)
    self:drawText(value, cw + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end

function UI:refreshData()
    self.controls.list:clear();
    self.lastSelected = nil
    local showAll = self.controls.showAll.selected[1]
    local filter = self.controls.filter:getInternalText():lower()
    local category = self.controls.filterCategory:getOptionText(self.controls.filterCategory.selected)
    for _, item in ipairs(self.data.items) do
        if showAll or self.data.data[item.type] ~= nil then
            if (filter == "" or string.match(item.label:lower(), filter)) and
                (category == "" or item.category == category) then
                self.controls.list:addItem(item.label, item);
            end
        end
    end
end
