if isServer() then
    return
end
local tools = require "PhunLewt2/ui/tools"
local Core = PhunLewt
local PL = PhunLib
local profileName = "PhunLewtCongfigs"

Core.ui.configs = ISCollapsableWindowJoypad:derive(profileName);
local UI = Core.ui.configs
local instances = {}

function UI.open(player, data)

    local playerIndex = player:getPlayerNum()
    local core = getCore()
    local width = 600 * tools.FONT_SCALE
    local height = 300 * tools.FONT_SCALE

    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2

    local instance = UI:new(x, y, width, height, player, playerIndex, PL.table.deepCopy(data));

    instance:initialise();

    ISLayoutManager.RegisterWindow(profileName, UI, instance)
    instance:addToUIManager();
    instance:setVisible(true);
    instance:ensureVisible()
    instance:refreshItems()
    return instance;
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
    o.data = data
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

    -- self.controls.ok = ISButton:new(padding, self.height - rh - padding - tools.FONT_HGT_SMALL, 80,
    --     tools.FONT_HGT_SMALL + 4, getText("OK"), self, UI.onOK);
    -- self.controls.ok:initialise();
    -- self.controls.ok:instantiate();
    -- if self.controls.ok.enableAcceptColor then
    --     self.controls.ok:enableAcceptColor()
    -- end
    -- self:addChild(self.controls.ok);

    local panel = ISPanel:new(w - 110, y, 100, 300 - padding);
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
            if name and name ~= "" and self.data[name] == nil then
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
    if item then
        local w = 300
        local h = 200
        local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2,
            w, h, getText("IGUI_PhunLewt_Confirm_Remove", item), true, self, function(self, button)
                if button.internal == "YES" then
                    table.remove(self.data, list.selected + 1)
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

end

function UI:prerender()

    ISCollapsableWindowJoypad.prerender(self);

    local padding = 10
    local ok = self.controls.new
    -- ok:setX(ok.parent.width - ok.width - padding)
    -- ok:setY(ok.parent.height - ok.height - self:resizeWidgetHeight() - 10)

    -- self.controls.new:setY(ok.y)
    -- self.controls.new:setX(self.controls.ok.x - self.controls.new.width - padding)
    -- self.controls.delete:setY(ok.y)
    -- self.controls.delete:setX(self.controls.new.x - self.controls.delete.width - padding)
    self.controls.delete:setEnable(self.controls.list.selected > 0)

    -- self.controls.edit:setY(ok.y)
    -- self.controls.edit:setX(self.controls.delete.x - self.controls.edit.width - padding)
    self.controls.edit:setEnable(self.controls.list.selected > 0)

    -- self.controls.copy:setY(ok.y)
    -- self.controls.copy:setX(self.controls.edit.x - self.controls.copy.width - padding)
    self.controls.copy:setEnable(self.controls.list.selected > 0)
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

    local panel = self.controls.panel
    panel:setX(self.width - panel.width - padding)
    panel:setY(self:titleBarHeight() + padding)
    panel:setHeight(self.height - self:titleBarHeight() - self:resizeWidgetHeight() - padding * 2)

    local list = self.controls.list
    local listw = panel.x - 20
    -- list:setHeight(panel.height)

end

function UI:onOK()

    local data = self.data
    if self.controls.extend and self.controls.extend:isSelected(1) == false then
        data.extend = false
    else
        data.extend = nil
    end
    data.hours = tonumber(self.controls.hours:getText()) or nil
    data.onempty = self.controls.onempty:getText() or nil
    data.name = data.name or (data.region .. "_" .. data.zone)
    -- data.region = data.region or "_default"
    -- data.zone = data.zone or "main"
    -- sendClientCommand(Core.name, Core.commands.saveZoneData, data)
    self:close()
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

    -- local clipX = self.columns[1].size
    -- local clipX2 = self.columns[2].size
    -- local clipX3 = self.columns[3].size
    -- local clipY = math.max(0, y + self:getYScroll())
    -- local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight) - 1

    -- if item.item.texture then
    --     local textured = self:drawTextureScaledAspect2(item.item.texture, xoffset, y, self.itemheight - 4,
    --         self.itemheight - 4, 1, 1, 1, 1)
    --     xoffset = xoffset + self.itemheight + 4
    -- end

    -- self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.text, xoffset, y + 4, 1, 1, 1, a, self.font);
    -- self:clearStencilRect()

    -- local value = item.item.category or ""
    -- local cw = self.columns[2].size
    -- self:setStencilRect(clipX2, clipY, clipX3 - clipX2, clipY2 - clipY)
    -- self:drawText(value, cw + 4, y + 4, 1, 1, 1, a, self.font);
    -- self:clearStencilRect()

    -- local value = ""
    -- if item.item.chance then
    --     value = "-" .. tostring(item.item.chance) .. "%"
    -- end
    -- local cw = self.columns[3].size
    -- self:setStencilRect(clipX3, clipY, self:getWidth() - clipX3 - self.vscroll.width, clipY2 - clipY)
    -- self:drawText(value, cw + 4, y + 4, 1, 1, 1, a, self.font);
    -- self:clearStencilRect()

    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end
