if isServer() then
    return
end
require "PhunLewt/ui/base"
local tools = require "PhunLewt/ui/tools"
local Core = PhunLewt
local PL = PhunLib
local profileName = "PhunLewtCats"
Core.ui.cats = PhunLewtBase:derive(profileName);
local UI = Core.ui.cats

function UI:createChildren()
    ISPanelJoypad.createChildren(self)
    local padding = 10
    local x = padding
    local y = padding
    self.controls = {}
    local list = tools.getListbox(x, y, self:getWidth() - padding * 2, self.height - tools.HEADER_HGT - padding * 2,
        {"Category", {getText("Chance"), self.width - 100}}, {
            draw = self.drawDatas,
            click = self.click,
            rightClick = self.rightClick,
            doubleClick = self.doubleClick
        })

    self.controls.list = list
    self:addChild(list)
    self.data.categories = PL.getAllItemCategories()

end

function UI:drawDatas(y, item, alt)
    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end

    local a = 0.9;

    if self.parent.data.selectedItems[item.item.label] then
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
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight) - 1

    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.text, xoffset, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    local value = ""
    if self.parent.data.data[item.item.label] then
        value = "-" .. tostring(self.parent.data.data[item.item.label]) .. "%"
    end
    local cw = self.columns[2].size
    self:setStencilRect(clipX2, clipY, self:getWidth() - clipX2 - self.vscroll.width, clipY2 - clipY)
    self:drawText(value, cw + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end

function UI:refreshData()
    self.controls.list:clear();
    self.lastSelected = nil

    self.data.selectedItems = {}

    for _, item in ipairs(self.data.categories or {}) do
        self.controls.list:addItem(item.label, item);
    end
end
