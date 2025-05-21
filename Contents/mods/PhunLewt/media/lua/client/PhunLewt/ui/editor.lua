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

function UI:refreshAll(zone)
    self.controls.zones:clear()
    self.controls.zones:addOption("GLOBAL")
    local zones = PZ:updateZoneData()
    local presort = {}
    for k, v in pairs(zones.lookup) do
        v.k = k
        table.insert(presort, v)
    end
    table.sort(presort, function(a, b)
        if a.order and b.order then
            return a.order < b.order
        end
        if a.title and b.title then
            return a.title:lower() < b.title:lower()
        end
        return a.k < b.k
    end)
    local final = {}
    for _, v in ipairs(presort) do
        final[v.k] = v
        final[v.k].k = nil
    end
    local selectedIndex = nil
    local index = 1
    self.zones = zones
    for k, v in pairs(final) do

        index = index + 1
        if zone and zone.region == k and zone.zone == "main" then
            selectedIndex = index
        end

        self.controls.zones:addOptionWithData(k, v.main)

        for zkey, zval in pairs(v) do
            if zkey ~= "main" then
                index = index + 1
                if zone and zone.region == k and zone.zone == zkey then
                    selectedIndex = index
                end
                self.controls.zones:addOptionWithData(("  |- " .. zkey), zval)
            end
        end

    end
    self:setZoneSelection(selectedIndex or 1)
end

function UI.open(player, data, cb)

    local playerIndex = player:getPlayerNum()
    local core = getCore()
    local width = 400 * tools.FONT_SCALE
    local height = 400 * tools.FONT_SCALE

    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2

    local instance = UI:new(x, y, width, height, player, playerIndex);
    instance.data = PL.table.deepCopy(data)
    instance.cb = cb

    instance:initialise();

    ISLayoutManager.RegisterWindow(profileName, UI, instance)

    instance:addToUIManager();
    instance:setVisible(true);
    instance:ensureVisible()
    instance:refreshAll()
    return instance;
end

function UI:new(x, y, width, height, player, playerIndex)
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
    o.data = {}
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
    o:setTitle("editor")
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

function UI:setZoneSelection(selection)

    self.controls.zones.selected = selection
    local opts = self.controls.zones.options[selection]
    local data = opts.data
    self:setZoneData(data)
end

function UI:setZoneData(data)

    local regionKey = data and data.region or nil
    local zoneKey = data and data.zone or nil

    local global = self.data or {}
    local region = regionKey and data[regionKey] or {}
    local zone = zoneKey and region[zoneKey] or {}

    if not zone.categories then
        zone.categories = {}
    end
    if not zone.items then
        zone.items = {}
    end

    self.selectedRegion = regionKey
    self.selectedZone = zoneKey
    self.selectedData = zone
    self:refreshSelected(data)

end

function UI:getZoneData()
    local global = self.data or {}
    local region = self.regionKey and data[self.regionKey] or {}
    local zone = self.zoneKey and region[self.zoneKey] or {}

    if not zone.categories then
        zone.categories = {}
    end
    if not zone.items then
        zone.items = {}
    end
    return zone
end

function UI:refreshSelected(data)

    self.controls.list:clear()
    if not data then
        return
    end
    for k, v in pairs(data) do

    end

end

function UI:setData(data)
    self.data = data
    self:refreshItems()

end

function UI:getData()
    return self.data
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

    y = y + padding

    local zoneTitle = ISLabel:new(padding, y, tools.FONT_HGT_SMALL, "Zone", 1, 1, 1, 1, UIFont.Small, true);
    zoneTitle:initialise();
    zoneTitle:instantiate();
    self:addChild(zoneTitle);

    local zones = ISComboBox:new(self.width - 200 - padding, y, 200, tools.FONT_HGT_MEDIUM, self, function()
        self:setZoneSelection(self.controls.zones.selected)
    end);
    zones:initialise()
    self:addChild(zones)
    self.controls.zones = zones
    zones:setAnchorLeft(true)
    zones:setAnchorRight(true)

    y = y + padding + zones.height

    local selectorTitle = ISLabel:new(padding, y, tools.FONT_HGT_SMALL, "Items", 1, 1, 1, 1, UIFont.Small, true);
    selectorTitle:initialise();
    selectorTitle:instantiate();
    self:addChild(selectorTitle);

    local selector = ISButton:new(self.width - 200 - padding, y, 200, tools.BUTTON_HGT, " ... ", self, function()
        -- get currently selected zone
        local regionKey = self.selectedRegion
        local zoneKey = self.selectedZone

        local data = nil
        if regionKey then
            data = self.data[regionKey] or {}
        end
        if zoneKey then
            data = self.data[regionKey] and self.data[regionKey][zoneKey] or {}
        end
        if not data then
            data = self.data["GLOBAL"] or {}
        end
        local existing = PL.table.deepCopy(data)

        Core.ui.filters.open(self.player, existing, function(data)
            local s = self
            if regionKey and zoneKey then
                s.data[regionKey] = s.data[regionKey] or {}
                s.data[regionKey][zoneKey] = data
            elseif regionKey then
                s.data[regionKey] = data
            else
                s.data["GLOBAL"] = data
            end
            s:setData(s:getData())
        end)
    end);
    selector:initialise();
    selector:instantiate();
    selector:setAnchorRight(true);
    selector:setAnchorLeft(true);
    self:addChild(selector);
    self.controls.selector = selector

    y = y + padding + selector.height

    local list = tools.getListbox(x + padding, y, w - (padding * 2), 220,
        {getText("Item"), {getText("Category"), w - 150}, {getText("Chance"), w - 50}}, {
            draw = self.drawDatas,
            click = self.click,
            rightClick = self.rightClick,
            doubleClick = self.doubleClick
        });

    self:addChild(list);
    self.controls.list = list

    y = y + padding + list.height

    local lblFilter = tools.getLabel("Filter", padding, y)
    self.controls.lblFilter = lblFilter
    self:addChild(lblFilter)
    local filter = ISTextEntryBox:new("", padding, y + lblFilter.height + padding, self.width - 200, tools.BUTTON_HGT);
    filter.onTextChange = function()
        self:refreshItems()
    end
    self.controls.filter = filter
    filter:initialise();
    filter:instantiate();
    filter:setAnchorRight(true)
    self:addChild(filter);

    local left = filter.x + filter.width + padding
    local lblFilterCategory = tools.getLabel("Category", self.width - x - left, y)
    self:addChild(lblFilterCategory)
    self.controls.lblFilterCategory = lblFilterCategory
    local filterCategory = ISComboBox:new(left, y + lblFilterCategory.height + padding, self.width - padding - left,
        tools.FONT_HGT_MEDIUM, self, function()
            self:refreshItems()
        end);
    filterCategory:initialise();
    filterCategory:instantiate();

    self.controls.filterCategory = filterCategory
    self:addChild(filterCategory);
    filterCategory:addOption("")
    for _, category in ipairs(PL.getAllItemCategories()) do
        filterCategory:addOption(category.label)
    end

    self:refreshAll()
end

function UI:chancePromptForSelected(currentValue)
    local modal = ISTextBox:new(0, 0, 100, 100, "Chance (0-100)", tostring(currentValue or ""), self,
        function(target, button, obj)
            if button.internal == "OK" then
                local list = target.controls.list
                local data = list.parent.selectedItems
                local value = tonumber(button.parent.entry:getText())
                if value ~= nil and value >= 0 and value <= 100 then
                    for i, v in ipairs(list.items) do
                        if data[v.item.type] == true then
                            list.items[i].item.chance = value
                        end
                    end
                end
            end

        end, self.playerIndex)
    modal:initialise()
    modal:addToUIManager()
    modal:setAlwaysOnTop(true)
end

function UI:clearSelectedChance()
    local list = self.controls.list
    local data = list.parent.selectedItems

    for i, v in ipairs(list.items) do
        if data[v.item.type] == true then
            list.items[i].item.chance = nil
        end
    end
end

function UI:click(x, y)
    local list = self.parent.controls.list
    self.selectedProperty = nil
    local row = list:rowAt(x, y)
    if row == nil or row == -1 then
        return
    end
    list:ensureVisible(row)
    local item = list.items[row].item

    local data = list.parent.selectedItems
    -- data[item.type] = data[item.type] == nil and true or nil

    -- range select
    if isShiftKeyDown() and self.lastSelected then
        local start = math.min(row, self.lastSelected)
        local finish = math.max(row, self.lastSelected)
        for i = start, finish do
            data[list.items[i].item.type] = true
        end
    elseif isCtrlKeyDown() then
        if data[item.type] == nil then
            data[item.type] = true
        else
            data[item.type] = nil
        end
    else
        for k, v in pairs(data) do
            if v == true then
                data[k] = nil
            end
        end
        data[item.type] = true
    end
    PL.debug("selectedItems", data)
    -- remember last selected for range select
    self.lastSelected = row
end

function UI:doubleClick(item)
    self.parent.selectedItems = {}
    self.parent.selectedItems[item.type] = true
    self.parent:chancePromptForSelected(item.chance)

end

function UI:rightClick(x, y)
    local list = self.parent.controls.list
    local row = list:rowAt(x, y)
    if row == -1 then
        return
    end
    if list.selected ~= row then
        list.selected = row
        list.selected = row
        list:ensureVisible(list.selected)
    end
    local item = list.items[list.selected].item
    local hasSelected = false
    for k, v in pairs(list.parent.selectedItems) do
        if v == true then
            hasSelected = true
            break
        end
    end
    if hasSelected then
        local context = ISContextMenu.get(self.parent.playerIndex, self:getAbsoluteX() + x,
            self:getAbsoluteY() + y + self:getYScroll())
        context:removeFromUIManager()
        context:addToUIManager()

        context:addOption("Edit Chance", self, function(target)
            target.parent:chancePromptForSelected(item.chance)
        end, item)
        context:addOption("Clear Chance", self, function(target)
            target.parent:clearSelectedChance()
        end, item)
    end
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
    local rw = self:resizeWidgetHeight()
    local lblFilter = self.controls.lblFilter
    local filter = self.controls.filter
    local lblFilterCategory = self.controls.lblFilterCategory
    local filterCategory = self.controls.filterCategory
    local ok = self.controls.ok

    local y = lblFilter.parent.height - tools.BUTTON_HGT - padding - padding - padding - filter.height - padding -
                  lblFilter.height
    local left = filter.x + filter.width + padding
    lblFilter:setY(y)
    lblFilterCategory:setY(y)
    lblFilterCategory:setX(left)
    y = y + lblFilterCategory.height + padding
    filter:setY(y)
    filterCategory:setY(y)
    filterCategory:setX(left)

    y = y + filter.height + padding

    self.controls.ok:setX(ok.parent.width - ok.width - 10)
    self.controls.ok:setY(ok.parent.height - ok.height - self:resizeWidgetHeight() - 10)

    local list = self.controls.list
    local listw = list.width - 20
    local chanceW = 50
    local categoryW = 150
    local itemW = listw - chanceW - categoryW
    list.columns[2].size = itemW
    list.columns[3].size = itemW + categoryW

end

function UI:onOK()
    self.cb(self:getData())
    self:close()
end

function UI:refreshItems()
    self.controls.list:clear();
    self.lastSelected = nil
    self.data = self:getData()
    local filterText = self.controls.filter:getInternalText():lower()
    local filterCategory = self.controls.filterCategory.options[self.controls.filterCategory.selected]
    local filters = self.data.filters or {}
    local results = {}

    local allItems = PL.getAllItems()
    for _, v in ipairs(allItems) do
        if (filters.items and filters.items[v.type]) or (filters.categories and filters.categories[v.category]) then
            table.insert(results, {
                type = v.type,
                label = v.label,
                category = v.category,
                texture = v.texture,
                chance = v.chance
            })
        end

    end

    table.sort(results, function(a, b)
        return a.label:lower() < b.label:lower()
    end)

    self.itemlist = results
    self.controls.list:clear()
    for _, v in ipairs(results) do
        if filterCategory == "" or v.category == filterCategory then
            if (filterText == "" or string.match(v.label:lower(), filterText)) then
                self.controls.list:addItem(v.label, v);
            end
        end
    end

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

    local value = tostring(item.item.chance or "")
    local cw = self.columns[3].size
    self:setStencilRect(clipX3, clipY, self:getWidth() - clipX3 - self.vscroll.width, clipY2 - clipY)
    self:drawText(value, cw + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end
