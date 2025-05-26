if isServer() then
    return
end
local tools = require "PhunLewt/ui/tools"
local Core = PhunLewt
local profileName = "PhunLewtFilters"

Core.ui.filters = ISCollapsableWindowJoypad:derive(profileName);
local UI = Core.ui.filters
local instances = {}

function UI:refreshAll()
    self.controls.items:setData(self.data.items or {})
    self.controls.categories:setData(self.data.categories or {})
end

function UI.open(player, data, cb)

    local playerIndex = player:getPlayerNum()

    local core = getCore()
    local width = 400 * tools.FONT_SCALE
    local height = 400 * tools.FONT_SCALE

    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2

    local instance = UI:new(x, y, width, height, player, playerIndex);
    instance.data = data
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
    o.moveWithMouse = false;
    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.playerIndex = playerIndex
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o:setWantKeyEvents(true)
    o:setTitle("filters")
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
        tools.FONT_HGT_SMALL + 4, getText("IGUI_PhunLewt_Ok"), self, UI.onOK);
    self.controls.ok:initialise();
    self.controls.ok:instantiate();
    if self.controls.ok.enableAcceptColor then
        self.controls.ok:enableAcceptColor()
    end
    self:addChild(self.controls.ok);

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

    self:refreshAll()
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
    local ok = self.controls.ok
    self.controls.ok:setX(ok.parent.width - ok.width - 10)
    self.controls.ok:setY(ok.parent.height - ok.height - self:resizeWidgetHeight() - 10)

    local items = self.controls.items
    local categories = self.controls.categories
    items:setWidth(items.parent.width)
    items:setHeight(items.parent.height)
    categories:setWidth(categories.parent.width)
    categories:setHeight(categories.parent.height)

end

function UI:onOK()
    local data = self.data
    local selectedItems = self.controls.items:getData()
    local selected = {
        categories = self.controls.categories:getData(),
        items = self.controls.items:getData()
    }
    self.cb(selected)
    self:close()
end
