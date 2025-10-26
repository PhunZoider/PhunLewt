if isServer() then
    return
end
local tools = require "PhunLewt/ui/tools"
local Core = PhunLewt
local PL = PhunLib
local PZ = PhunZones
local profileName = "PhunLewtEditor"

Core.ui.editor = ISCollapsableWindowJoypad:derive(profileName);
local UI = Core.ui.editor
local instances = {}

function UI.open(player, data)

    local playerIndex = player:getPlayerNum()
    local core = getCore()
    local width = 600 * tools.FONT_SCALE
    local height = 500 * tools.FONT_SCALE

    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2

    local instance = UI:new(x, y, width, height, player, playerIndex, PL.table.deepCopy(data));

    instance:initialise();

    ISLayoutManager.RegisterWindow(profileName, UI, instance)

    instance:addToUIManager();
    instance:setVisible(true);
    instance:ensureVisible()
    instance:refreshItems()
    instance:setAlwaysOnTop(true)

    -- local function receiveInheritance(inheritData)
    --     print("PhunLewt: Received inheritance data")
    --     instance.inherit = inheritData or {}
    --     instance:refreshItems()
    -- end

    -- Events[Core.events.OnReceiveInheritance].Add(instance.recieveInheritance)

    return instance;
end

function UI:requestInheritance(key)

    local s = self

    local function receiveInheritance(inheritData)
        s.inherit = inheritData or {}
        s:refreshItems()
        Events[Core.events.OnReceiveInheritance].Remove(receiveInheritance)
    end
    Events[Core.events.OnReceiveInheritance].Add(receiveInheritance)

    sendClientCommand(Core.name, Core.commands.requestInheritance, {
        username = self.player:getUsername(),
        key = key
    })

end

function UI:recieveInheritance(inheritData)
    PL.debug("PhunLewt:recieveInheritance", inheritData)
    self.inherit = inheritData or {}
    self:refreshItems()
end

function UI:new(x, y, width, height, player, playerIndex, data)
    local o = {};
    o = ISCollapsableWindowJoypad:new(x, y, width, height, player);
    setmetatable(o, self);
    self.__index = self;

    o.variableColor = {
        r = 0.9,
        g = 0.55,
        b = 0.1,
        a = 1
    };
    o.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.8
    };
    o.buttonBorderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 1
    };
    o.controls = {}
    o.data = data.data or {}
    o.inherit = data.inherit or {}
    o.selectedItems = {}
    o.moveWithMouse = false;
    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.playerIndex = playerIndex
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o:setWantKeyEvents(true)
    local title = "PhunLewt Editor"
    local zones = PZ.data.lookup
    if zones and zones[data.region] and zones[data.region][data.zone] then
        title = zones[data.region][data.zone].title
        if zones[data.region][data.zone].subtitle then
            title = title .. " - " .. zones[data.region][data.zone].subtitle
        end
    end
    o:setTitle(title .. " lewt reducer")
    return o;
end

function UI:RestoreLayout(name, layout)

    -- ISLayoutManager.DefaultRestoreWindow(self, layout)
    -- if name == profileName then
    --     ISLayoutManager.DefaultRestoreWindow(self, layout)
    --     self.userPosition = layout.userPosition == 'true'
    -- end
    self:recalcSize();
end

function UI:SaveLayout(name, layout)
    ISLayoutManager.DefaultSaveWindow(self, layout)
    if self.userPosition then
        layout.userPosition = 'true'
    else
        layout.userPosition = 'false'
    end
end

function UI:close()
    if not self.locked then
        ISCollapsableWindowJoypad.close(self);
    end

end

function UI:createChildren()

    ISCollapsableWindowJoypad.createChildren(self);

    local th = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()

    local padding = 10
    local x = 0
    local y = th
    local w = self.width
    local h = self.height - rh - th

    self.controls = {}

    self.controls.ok = ISButton:new(padding, self.height - rh - padding - tools.FONT_HGT_SMALL, 100,
        tools.FONT_HGT_SMALL + 4, getText("OK"), self, UI.onOK);
    self.controls.ok:initialise();
    self.controls.ok:instantiate();
    if self.controls.ok.enableAcceptColor then
        self.controls.ok:enableAcceptColor()
    end
    self:addChild(self.controls.ok);

    -- container for the inline filters below the list
    -- local filtersPanel = ISPanel:new(0, self.controls.ok.y - 100, self.width, 80);
    -- filtersPanel.drawBorder = false
    -- filtersPanel:initialise();
    -- filtersPanel:instantiate();
    -- filtersPanel.backgroundColor = {
    --     r = 0.1,
    --     g = 0.1,
    --     b = 0.1,
    --     a = 0.8
    -- }

    -- self.controls.filtersPanel = filtersPanel
    -- self:addChild(filtersPanel);

    y = y + padding

    local lbl = tools.getLabel(getText("IGUI_PhunLewt_Name"), padding, y)
    local txt = tools.getTextbox(tostring(self.data.name or ""), getText("IGUI_PhunLewt_Name_Tooltip"),
        self.width - 200 - padding, y, 200);
    self.controls.lblName = lbl
    self.controls.name = txt
    self:addChild(lbl);
    self:addChild(txt)

    y = y + padding + lbl.height

    lbl = tools.getLabel(getText("IGUI_PhunLewt_Default"), padding, y)
    txt = tools.getTextbox(tostring(self.data.default or ""), getText("IGUI_PhunLewt_Default_Tooltip"),
        self.width - 200 - padding, y, 200);
    self.controls.lblName = lbl
    self.controls.name = txt
    self:addChild(lbl);
    self:addChild(txt)

    y = y + lbl.height + padding

    lbl = tools.getLabel(getText("IGUI_PhunLewt_Hours_To_Full"), padding, y)
    txt = tools.getTextbox(tostring(self.data.hours or ""), getText("IGUI_PhunLewt_Hours_To_Full_tooltip"),
        self.width - 200 - padding, y, 200);
    self.controls.lblHours = lbl
    self.controls.hours = txt
    self:addChild(lbl);
    self:addChild(txt)

    y = y + lbl.height + padding

    lbl = tools.getLabel(getText("IGUI_PhunLewt_On_Empty_Add_Item"), padding, y)
    txt = tools.getTextbox(tostring(self.data.onempty or ""), getText("IGUI_PhunLewt_On_Empty_Add_Item_Tooltip"),
        self.width - 200 - padding, y, 200);
    self.controls.lblOnEmtpy = lbl
    self.controls.onempty = txt
    self:addChild(lbl);
    self:addChild(txt)

    y = y + lbl.height + padding

    -- local selectorTitle = ISLabel:new(padding, y, tools.FONT_HGT_SMALL, getText("IGUI_PhunLewt_Edit_Item_Selection"), 1,
    --     1, 1, 1, UIFont.Small, true);
    -- selectorTitle:initialise();
    -- selectorTitle:instantiate();
    -- self:addChild(selectorTitle);

    -- local selector = ISButton:new(self.width - 200 - padding, y, 200, tools.BUTTON_HGT, " ... ", self, function()
    --     local existing = PL.table.deepCopy(self.data)
    --     Core.ui.filters.open(self.player, existing, function(data)
    --         local s = self
    --         s.data.categories = data.categories or {}
    --         s.data.items = data.items or {}
    --         s:refreshItems()
    --     end)
    -- end);
    -- selector:initialise();
    -- selector:instantiate();
    -- selector:setAnchorRight(true);
    -- selector:setAnchorLeft(true);
    -- self:addChild(selector);
    -- self.controls.selector = selector

    -- y = y + padding + selector.height

    local inheritsTitle = ISLabel:new(padding, y, tools.FONT_HGT_SMALL, getText("IGUI_PhunLewt_InheritFrom"), 1, 1, 1,
        1, UIFont.Small, true);
    inheritsTitle:initialise();
    inheritsTitle:instantiate();
    self:addChild(inheritsTitle);

    self.controls.inherits = ISComboBox:new(self.width - 200 - padding, y, 200, tools.FONT_HGT_MEDIUM, self, function()
        local key = self.controls.inherits.selected > 0 and
                        self.controls.inherits.options[self.controls.inherits.selected] or nil
        if key then
            self:requestInheritance(key)
            -- sendClientCommand(Core.name, Core.commands.requestInheritance, {
            --     username = self.player:getUsername(),
            --     key = key
            -- })
        else
            self.inherit = {}
            self:refreshItems()
        end
    end);
    self.controls.inherits:initialise()
    self.controls.inherits:instantiate()
    self.controls.inherits:setAnchorRight(true);
    self:addChild(self.controls.inherits)
    local names = Core.configNames or {}
    self.controls.inherits:addOption("")
    local selected = 1
    for i = 1, #names do
        if names[i] ~= self.data.name then
            self.controls.inherits:addOption(names[i])
            if self.data.inherit and names[i] == self.data.inherit then
                selected = i + 1
            end
        end
    end

    self.controls.inherits.selected = selected

    y = y + padding + self.controls.inherits.height

    self.controls.tabPanel = tools.getTabPanel(x, y, w, h - y - (padding * 2) - tools.BUTTON_HGT, {
        player = self.player,
        type = Core.consts.itemType.items
    });

    self:addChild(self.controls.tabPanel)

    self.controls.categories = Core.ui.cats:new(0, y, w, self.controls.tabPanel.height, {
        player = self.player,
        type = Core.consts.itemType.items
    });

    self.controls.items = Core.ui.items:new(0, y, w, self.controls.tabPanel.height, {
        player = self.player,
        type = Core.consts.itemType.items
    });

    self.controls.tabPanel:addView(getText("IGUI_PhunLewt_Items"), self.controls.items)
    self.controls.tabPanel:addView(getText("IGUI_PhunLewt_Categories"), self.controls.categories)

    -- if self.data.region ~= "_default" then
    --     local chkExtend = ISTickBox:new(self.width - 200 - padding, y, tools.BUTTON_HGT, tools.BUTTON_HGT,
    --         getText("IGUI_PhunZones_AllZones"), self)
    --     chkExtend:addOption(getText("IGUI_PhunLewt_Extend_Default"), nil)
    --     chkExtend:setWidthToFit()
    --     chkExtend:setSelected(1, self.data.extend ~= false)
    --     chkExtend.onMouseUp = function(s, x, y)
    --         ISTickBox.onMouseUp(s, x, y)
    --         return true
    --     end
    --     chkExtend.tooltip = getText("IGUI_PhunLewt_Extend_Default_tooltip")
    --     self:addChild(chkExtend)
    --     self.controls.extend = chkExtend

    --     y = y + chkExtend.height + padding
    -- end

    -- local list = tools.getListbox(x + padding, y, w - (padding * 2), filtersPanel.y - y - padding - tools.HEADER_HGT,
    --     {getText("Item"), {getText("IGUI_PhunLewt_Category_Header"), w - 150},
    --      {getText("IGUI_PhunLewt_Reduction_Percent"), w - 50}}, {
    --         draw = self.drawDatas,
    --         click = self.click,
    --         rightClick = self.rightClick,
    --         doubleClick = self.doubleClick
    --     });

    -- self:addChild(list);
    -- self.controls.list = list

    -- y = padding + filtersPanel.y
    -- y = 0
    -- local lblFilter = tools.getLabel(getText("IGUI_PhunLewt_Filter"), padding, padding)
    -- self.controls.lblFilter = lblFilter
    -- filtersPanel:addChild(lblFilter)

    -- local filter = ISTextEntryBox:new("", padding, y + lblFilter.height + padding, self.width - 200, tools.BUTTON_HGT);
    -- filter.onTextChange = function()
    --     self:refreshItems()
    -- end
    -- self.controls.filter = filter
    -- filter:initialise();
    -- filter:instantiate();
    -- filter:setAnchorRight(true)
    -- filtersPanel:addChild(filter);

    -- local left = filter.x + filter.width + padding
    -- local lblFilterCategory = tools.getLabel(getText("IGUI_PhunLewt_Category_Header"), self.width - x - left,
    --     lblFilter.y)
    -- filtersPanel:addChild(lblFilterCategory)
    -- self.controls.lblFilterCategory = lblFilterCategory
    -- local filterCategory = ISComboBox:new(left, y + lblFilterCategory.height + padding, self.width - padding - left,
    --     tools.FONT_HGT_MEDIUM, self, function()
    --         self:refreshItems()
    --     end);
    -- filterCategory:initialise();
    -- filterCategory:instantiate();

    -- self.controls.filterCategory = filterCategory
    -- filtersPanel:addChild(filterCategory);
    -- filterCategory:addOption("")
    -- for _, category in ipairs(PL.getAllItemCategories()) do
    --     filterCategory:addOption(category.label)
    -- end

end

function UI:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end

function UI:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:close()
    end
end

function UI:prerender()

    ISCollapsableWindowJoypad.prerender(self);

    local padding = 10
    local ok = self.controls.ok
    self.controls.ok:setX(ok.parent.width - ok.width - 10)
    self.controls.ok:setY(ok.parent.height - ok.height - self:resizeWidgetHeight() - 10)

    local items = self.controls.items
    local categories = self.controls.categories
    items:setWidth(items.parent.width)
    items:setHeight(items.parent.height - self.controls.tabPanel.tabHeight)
    categories:setWidth(categories.parent.width)
    categories:setHeight(categories.parent.height - self.controls.tabPanel.tabHeight)

    -- local filterPanel = self.controls.filtersPanel
    -- filterPanel:setWidth(filterPanel.parent.width)
    -- filterPanel:setY(ok.y - 100)

    -- local lblFilterCategory = self.controls.lblFilterCategory

    -- local filterCategory = self.controls.filterCategory
    -- filterCategory:setX(filterCategory.parent.width - filterCategory.width - padding)
    -- filterCategory:setY(lblFilterCategory.y + lblFilterCategory.height + padding)
    -- lblFilterCategory:setX(filterCategory.x)

    -- local filter = self.controls.filter
    -- filter:setWidth(filterCategory.x - filter.x - padding)
    -- filter:setY(lblFilterCategory.y + lblFilterCategory.height + padding)

    -- local list = self.controls.list
    -- local listw = list.width - 20
    -- local chanceW = 50
    -- local categoryW = 150
    -- local itemW = listw - chanceW - categoryW
    -- list.columns[2].size = itemW
    -- list.columns[3].size = itemW + categoryW
end

function UI:onOK()

    local data = self.data

    data.inherit = self.controls.inherits.selected > 0 and
                       self.controls.inherits.options[self.controls.inherits.selected] or nil
    data.hours = tonumber(self.controls.hours:getText()) or nil
    data.default = tonumber(self.controls.name:getText()) or nil
    data.onempty = self.controls.onempty:getText() or nil
    data.name = data.name or (data.region .. "_" .. data.zone)
    data.items = self.controls.items.data.items
    data.categories = self.controls.categories.data.categories

    -- data.region = data.region or "_default"
    -- data.zone = data.zone or "main"
    sendClientCommand(Core.name, Core.commands.saveZoneData, data)
    self:close()
end

function UI:refreshItems()

    self.controls.items.data.items = self.data.items or {}
    self.controls.items.data.inherit = (self.inherit or {}).items or {}
    self.controls.items:refreshData()
    self.controls.categories.data.categories = self.data.categories or {}
    self.controls.categories.data.inherit = (self.inherit or {}).categories or {}
    self.controls.categories:refreshData()
    -- self.controls.list:clear();
    -- self.lastSelected = nil

    -- local filterText = self.controls.filter:getInternalText():lower()
    -- local filterCategory = self.controls.filterCategory.options[self.controls.filterCategory.selected]
    -- local filters = self.data or {}
    -- local results = {}

    -- local allItems = PL.getAllItems()
    -- for _, v in ipairs(allItems) do
    --     if (filters.items and filters.items[v.type]) or (filters.categories and filters.categories[v.category]) then
    --         table.insert(results, {
    --             type = v.type,
    --             label = v.label,
    --             category = v.category,
    --             texture = v.texture,
    --             chance = filters.items[v.type] or filters.categories[v.category]
    --         })
    --     end

    -- end

    -- table.sort(results, function(a, b)
    --     return a.label:lower() < b.label:lower()
    -- end)

    -- self.itemlist = results
    -- self.controls.list:clear()
    -- for _, v in ipairs(results) do
    --     if filterCategory == "" or v.category == filterCategory then
    --         if (filterText == "" or string.match(v.label:lower(), filterText)) then
    --             self.controls.list:addItem(v.label, v);
    --         end
    --     end
    -- end

end

function UI:drawDatas(y, item, alt)

    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end

    local a = 0.9;

    if self.parent.selectedItems[item.item.type] then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.4, 0.7, 0.35, 0.15);
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5);
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
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight) - 1

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

    local value = ""
    if item.item.chance then
        value = "-" .. tostring(item.item.chance) .. "%"
    end
    local cw = self.columns[3].size
    self:setStencilRect(clipX3, clipY, self:getWidth() - clipX3 - self.vscroll.width, clipY2 - clipY)
    self:drawText(value, cw + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end
