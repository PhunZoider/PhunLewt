local Core = PhunLewt
local tools = require "PhunLewt/ui/tools"
local profileName = "PhunLewtGroup"
Core.ui.group = ISPanelJoypad:derive(profileName);
local UI = Core.ui.group
local instances = {}

function UI.OnOpenPanel(playerObj, data)
    local playerIndex = playerObj:getPlayerNum()
    local instance = instances[playerIndex]
    if not instance then
        local core = getCore()
        local width = 450 * tools.FONT_SCALE
        local height = 400 * tools.FONT_SCALE
        local x = (core:getScreenWidth() - width) / 2
        local y = (core:getScreenHeight() - height) / 2
        instances[playerIndex] = UI:new(x, y, width, height, playerObj, playerIndex);
        instance = instances[playerIndex]
        instance:initialise();
    end
    instance.data = data or {}
    instance:refreshAll()
    instance:addToUIManager();
    instance:setVisible(true);
    instance:ensureVisible()
    return instance;
end
function UI:new(x, y, width, height, data)
    local o = {};
    o = ISPanelJoypad:new(x, y, width, height, data.player);
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
    o.data = {}
    o.listType = data.type or nil
    o.blacklist = data.blacklist == true
    o.moveWithMouse = false;
    o.anchorRight = true
    o.anchorBottom = true
    o.player = data.player
    o.playerIndex = o.player:getPlayerNum()
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o:setWantKeyEvents(true)
    return o;
end
function UI:createChildren()
    ISPanelJoypad.createChildren(self);
    local padding = 10
    local x = padding
    local y = 20
    local w = self.width - x - padding
    local h = self.height - y - tools.HEADER_HGT - padding
    self.tabPanel = ISTabPanel:new(x, y, w, h);
    self.tabPanel:initialise()
    self.tabPanel:setAnchorLeft(true)
    self.tabPanel:setAnchorRight(true)
    self.tabPanel:setAnchorTop(true)
    self.tabPanel:setAnchorBottom(true)
    self:addChild(self.tabPanel)

    self.categories = Core.ui.cats:new(0, y, w, self.tabPanel.height, {
        player = self.player,
        type = self.listType
    });

    self.items = Core.ui.items:new(0, y, w, self.tabPanel.height, {
        player = self.player,
        type = self.listType
    });

    self.tabPanel:addView("Items", self.items)
    self.tabPanel:addView("Categories", self.categories)

end
function UI:prerender()
    ISPanelJoypad.prerender(self)

    local items = self.items
    local categories = self.categories

    if items then
        items:setWidth(items.parent.width)
        items:setHeight(items.parent.height)
    end

    categories:setWidth(categories.parent.width)
    categories:setHeight(categories.parent.height)

end
function UI:getSelected()
    local data = self.data
    local selected = {
        categories = self.categories.data.selected or {},
        items = self.items.data.selected or {}
    }
    return selected
end
function UI:setData(data)
    self.data = data
    self:refreshAll()
end
function UI:refreshAll()
    self.categories:setData(self.data.categories)
    self.items:setData(self.data.include)

end
