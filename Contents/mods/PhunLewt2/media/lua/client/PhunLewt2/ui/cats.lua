if isServer() then
    return
end
require "PhunLewt2/ui/base"
local tools = require "PhunLewt2/ui/tools"
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
        {"Category", {getText("Chance"), self.width - 200}}, {
            draw = self.drawDatas,
            click = self.click,
            rightClick = self.rightClick,
            doubleClick = self.doubleClick
        })
    list.onMouseMove = self.doOnMouseMove
    list.onMouseMoveOutside = self.doOnMouseMoveOutside
    self.controls.list = list
    self:addChild(list)

    self.tooltip = ISToolTip:new();
    self.tooltip:initialise();
    self.tooltip:setVisible(false);
    self.tooltip:setAlwaysOnTop(true)
    self.tooltip.description = "";
    self.tooltip:setOwner(self.controls.list)

end

function UI:setValue(key, value)
    self.data.categories[key] = value
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

    local valueText = ""
    local suffix = ""
    local adjustment = nil
    local inheritValue = self.parent.data.inherit[item.item.label] or nil
    local itemValue = self.parent.data.categories[item.item.label] or nil

    if inheritValue then
        if itemValue then
            valueText = " - " .. tostring(itemValue) .. "% **"
        else
            valueText = "- " .. tostring(inheritValue) .. "% *" -- its inherited
        end
    elseif itemValue then
        valueText = " - " .. tostring(itemValue) .. "%"
    end

    -- local value = ""
    -- if self.parent.data.data[item.item.label] then
    --     value = "-" .. tostring(self.parent.data.data[item.item.label]) .. "%"
    -- end
    local cw = self.columns[2].size
    self:setStencilRect(clipX2, clipY, self:getWidth() - clipX2 - self.vscroll.width, clipY2 - clipY)
    self:drawText(valueText, cw + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end

function UI:refreshData()

    self.controls.list:clear();
    self.lastSelected = nil

    local categories = PL.getAllItemCategories() or {}

    local merged = {}
    for k, v in pairs(self.data.inherit or {}) do
        merged[k] = v
    end
    for k, v in pairs(self.data.categories) do
        merged[k] = v
    end

    self.data.selectedItems = {}

    for _, item in ipairs(categories or {}) do
        self.controls.list:addItem(item.label, item);
    end
end

function UI:doTooltip(item, col, row)
    local tooltip = self.tooltip
    if not tooltip then
        return
    end

    local desc = ""
    local suffix = ""
    local adjustment = nil
    local inheritValue = item.type and self.data.inherit[item.type] or nil
    local itemValue = item.type and self.data.categories[item.type] or nil

    if inheritValue then
        if itemValue then
            desc = "Value is being overwritten from - " .. tostring(inheritValue) .. "% to - " .. tostring(itemValue) ..
                       "%"
        else
            desc = "Value of - " .. tostring(inheritValue) .. "% is being inherited"
        end
    elseif itemValue then
        desc = "Value is set to - " .. tostring(itemValue) .. "%"
    else
        desc = "No value set, using default. Double click to set."
    end

    if desc ~= "" then
        tooltip:setName(item.label)
        tooltip.description = desc
        if not tooltip:isVisible() then
            tooltip:addToUIManager();
            tooltip:setVisible(true)
        end
        tooltip:bringToTop()
    else
        tooltip:setVisible(false)
        tooltip:removeFromUIManager()
    end

end
