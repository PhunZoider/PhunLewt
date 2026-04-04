if isServer() then
    return
end
local tools = require "PhunLewt2/ui/tools"
local Core = PhunLewt
local profileName = "PhunLewtConfigs"

Core.ui.configs = ISCollapsableWindowJoypad:derive(profileName);
local UI = Core.ui.configs
local instances = {}

function UI.open(player, data, defaults)

    local playerIndex = player:getPlayerNum()
    local core = getCore()
    local width = 450 * tools.FONT_SCALE
    local height = 350 * tools.FONT_SCALE

    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2

    local instance = UI:new(x, y, width, height, player, playerIndex, Core.tools.deepCopy(data), defaults or {});

    instance:initialise();

    ISLayoutManager.RegisterWindow(profileName, UI, instance)
    instance:addToUIManager();
    instance:setVisible(true);
    instance:ensureVisible()
    instance:refreshItems()
    return instance;
end

function UI:new(x, y, width, height, player, playerIndex, data, defaults)
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
    o.data = data
    o.defaults = defaults or {}
    o.moveWithMouse = false;
    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.playerIndex = playerIndex
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o:setWantKeyEvents(true)
    local title = "PhunLewt Configs"
    o.title = title
    o.name = title
    return o;
end

function UI:RestoreLayout(name, layout)

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

    -- Default config combo boxes
    local comboW = 200
    local labelX = padding
    local comboX = w - comboW - padding
    local comboH = tools.FONT_HGT_MEDIUM

    local containerLabel = ISLabel:new(labelX, y + 4, tools.FONT_HGT_SMALL, "Default Container Config:", 1, 1, 1, 1,
        UIFont.Small, true)
    containerLabel:initialise()
    containerLabel:instantiate()
    self:addChild(containerLabel)

    self.controls.containerCombo = ISComboBox:new(comboX, y, comboW, comboH, self, UI.onDefaultChanged)
    self.controls.containerCombo:initialise()
    self.controls.containerCombo:instantiate()
    self.controls.containerCombo:setAnchorRight(true)
    self.controls.containerCombo.tooltip = "The default config to use on all containers"
    self:addChild(self.controls.containerCombo)

    y = y + comboH + padding

    local zedLabel = ISLabel:new(labelX, y + 4, tools.FONT_HGT_SMALL, "Default Zed Config:", 1, 1, 1, 1, UIFont.Small,
        true)
    zedLabel:initialise()
    zedLabel:instantiate()
    self:addChild(zedLabel)

    self.controls.zedCombo = ISComboBox:new(comboX, y, comboW, comboH, self, UI.onDefaultChanged)
    self.controls.zedCombo:initialise()
    self.controls.zedCombo:instantiate()
    self.controls.zedCombo:setAnchorRight(true)
    -- self.controls.zedCombo:setToolTip("The default config to use on Zeds")
    self:addChild(self.controls.zedCombo)

    y = y + comboH + padding

    local panel = ISPanel:new(w - 110, y, 100, h - (y - th) - padding);
    panel.drawBorder = false
    panel:initialise();
    panel:instantiate();
    panel.backgroundColor = {
        r = 0.1,
        g = 0.1,
        b = 0.1,
        a = 0.8
    }
    self:addChild(panel);
    self.controls.panel = panel

    local y = padding
    self.controls.new = ISButton:new(padding, y, 80, tools.FONT_HGT_SMALL + 4, getText("IGUI_PhunLewt_New"), self,
        UI.onNew);
    self.controls.new:initialise();
    self.controls.new:instantiate();
    self.controls.new:setEnable(true)
    panel:addChild(self.controls.new);

    y = y + self.controls.new.height + padding
    self.controls.delete = ISButton:new(self.controls.new.x, y, 80, tools.FONT_HGT_SMALL + 4,
        getText("IGUI_PhunLewt_Delete"), self, UI.onDelete);
    self.controls.delete:initialise();
    self.controls.delete:instantiate();
    self.controls.delete:setEnable(false)
    panel:addChild(self.controls.delete);

    y = y + self.controls.delete.height + padding
    self.controls.edit = ISButton:new(self.controls.delete.x, y, 80, tools.FONT_HGT_SMALL + 4,
        getText("IGUI_PhunLewt_Edit"), self, UI.onEdit);
    self.controls.edit:initialise();
    self.controls.edit:instantiate();
    self.controls.edit:setEnable(false)
    panel:addChild(self.controls.edit);

    y = y + self.controls.edit.height + padding
    self.controls.copy = ISButton:new(self.controls.edit.x, y, 80, tools.FONT_HGT_SMALL + 4,
        getText("IGUI_PhunLewt_Copy"), self, UI.onCopy);
    self.controls.copy:initialise();
    self.controls.copy:instantiate();
    self.controls.copy:setEnable(false)
    panel:addChild(self.controls.copy);

    y = panel.y

    local list = tools.getListbox(padding, y, panel.x - padding * 2, self.height - y - padding, {getText("Item")}, {
        draw = self.drawDatas,
        click = self.click,
        rightClick = self.click,
        doubleClick = self.onEdit
    });

    list.lastSelectedRow = 1
    list.selected = 1
    self:addChild(list);
    self.controls.list = list

end

function UI:onNew()

    local modal = ISTextBox:new(0, 0, 280, 180, "Name:", "", nil, function(target, button, obj)
        if button.internal == "OK" then
            local name = button.parent.entry:getText()
            if name and name ~= "" and name ~= Core.consts.defaultConfigKey and self.data[name] == nil then
                table.insert(self.data, name)
                table.sort(self.data, function(a, b)
                    return a:lower() < b:lower()
                end)
                sendClientCommand(Core.name, Core.commands.saveZoneData, {
                    name = name,
                    categories = {},
                    items = {}
                })
                self:refreshItems()
            end
        end

    end, self.playerIndex)
    modal:initialise()
    modal:addToUIManager()
end

function UI:onDelete()
    local list = self.controls.list
    if list.selected < 0 or list.selected > #list.items then
        return
    end
    local item = list.items[list.selected].item
    if item == Core.consts.defaultConfigKey then
        return
    end
    if item then
        local w = 300
        local h = 200
        local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2,
            w, h, getText("IGUI_PhunLewt_Confirm_Remove", item), true, self, function(self, button)
                if button.internal == "YES" then
                    table.remove(self.data, list.selected)
                    sendClientCommand(Core.name, Core.commands.delete, {
                        name = item
                    })
                    self:refreshItems()
                end
            end)
        modal:initialise()
        modal:addToUIManager()
        modal:setAlwaysOnTop(true)
    end
end

function UI:onCopy()
    local list = self.controls.list
    if list.selected < 0 or list.selected > #list.items then
        return
    end
    local item = list.items[list.selected].item
    if item then
        table.insert(self.data, item .. "_copy")
        table.sort(self.data, function(a, b)
            return a:lower() < b:lower()
        end)
        list.selected = #list.items
        sendClientCommand(Core.name, Core.commands.copy, {
            name = item
        })
        self:refreshItems()
    end

end

function UI:onDefaultChanged()
    local containerCombo = self.controls.containerCombo
    local zedCombo = self.controls.zedCombo
    local containerConfig = containerCombo.selected > 0 and containerCombo.options[containerCombo.selected] or
                                Core.consts.defaultConfigKey
    local zedConfig = zedCombo.selected > 0 and zedCombo.options[zedCombo.selected] or Core.consts.defaultConfigKey
    sendClientCommand(Core.name, Core.commands.saveDefaults, {
        containerConfig = containerConfig,
        zedConfig = zedConfig
    })
end

function UI:onEdit()
    local list = self.controls and self.controls.list or self.parent.controls.list
    if list.selected < 0 or list.selected > #list.items then
        return
    end
    local item = list.items[list.selected].item
    if item then
        Core.showLoadingModal()
        sendClientCommand(Core.name, Core.commands.requestData, {
            name = item
        })
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

function UI:click(x, y)
    local list = self.parent.controls.list
    local row = list:rowAt(x, y)
    if row == -1 then
        return
    end
    local item = nil

    if list.lastSelectedRow ~= row then
        list.lastSelectedRow = row
        list.selected = row
        list:ensureVisible(list.selected)
    end

end

function UI:refreshItems()

    self.lastSelected = nil

    table.sort(self.data, function(a, b)
        return a:lower() < b:lower()
    end)

    self.itemlist = self.data
    self.controls.list:clear()
    for _, v in ipairs(self.data) do
        self.controls.list:addItem(v, v);
    end

    -- Populate default config combos (guard for when called before createChildren)
    if self.controls.containerCombo then
        local defaults = self.defaults or {}
        local containerKey = defaults.containerConfig or Core.consts.defaultConfigKey
        local zedKey = defaults.zedConfig or Core.consts.defaultConfigKey

        local containerCombo = self.controls.containerCombo
        local zedCombo = self.controls.zedCombo
        containerCombo:clear()
        zedCombo:clear()

        local containerSelected = 1
        local zedSelected = 1
        for i, v in ipairs(self.data) do
            containerCombo:addOption(v)
            zedCombo:addOption(v)
            if v == containerKey then
                containerSelected = i
            end
            if v == zedKey then
                zedSelected = i
            end
        end
        containerCombo.selected = containerSelected
        zedCombo.selected = zedSelected
    end

end

function UI:prerender()

    ISCollapsableWindowJoypad.prerender(self);

    local padding = 10
    local ok = self.controls.new

    local selectedItem = self.controls.list.selected > 0 and self.controls.list.items[self.controls.list.selected] and
                             self.controls.list.items[self.controls.list.selected].item or nil
    local isDefault = selectedItem == Core.consts.defaultConfigKey

    self.controls.delete:setEnable(self.controls.list.selected > 0 and not isDefault)

    self.controls.edit:setEnable(self.controls.list.selected > 0)

    self.controls.copy:setEnable(self.controls.list.selected > 0)

    local panel = self.controls.panel
    local comboH = tools.FONT_HGT_MEDIUM
    local comboSectionH = (comboH + padding) * 2
    local panelY = self:titleBarHeight() + comboSectionH
    panel:setX(self.width - panel.width - padding)
    panel:setY(panelY)
    panel:setHeight(self.height - panelY - self:resizeWidgetHeight() - padding)

    local comboW = 200
    self.controls.containerCombo:setX(self.width - comboW - padding)
    self.controls.zedCombo:setX(self.width - comboW - padding)

    local list = self.controls.list
    list:setY(panelY + tools.HEADER_HGT)
    list:setWidth(panel.x - padding * 2)
    list:setHeight(self.height - panelY - self:resizeWidgetHeight() - padding)

end

function UI:drawDatas(y, item, alt)

    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end

    local a = 0.9;

    if self.selected and item.index == self.selected then
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

    self:drawText(item.text, xoffset, y + 4, 1, 1, 1, a, self.font);

    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end
