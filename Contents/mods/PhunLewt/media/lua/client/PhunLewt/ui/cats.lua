if isServer() then
    return
end
local tools = require "PhunLewt/ui/tools"
local Core = PhunLewt
local PL = PhunLib
local profileName = "PhunLewtCats"
Core.ui.cats = ISPanelJoypad:derive(profileName);
local UI = Core.ui.cats

function UI:new(x, y, width, height, options)
    local opts = options or {}
    local o = ISPanelJoypad:new(x, y, width, height);
    setmetatable(o, self);
    o.player = opts.player or getPlayer()
    o.playerIndex = o.player:getPlayerNum()
    o.lastSelected = nil
    o.data = {
        selectedItems = {},
        categories = {},
        data = {}
    }
    self.instance = o;
    return o;
end

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

    local value = tostring(self.parent.data.data[item.item.label] or "")
    local cw = self.columns[2].size
    self:setStencilRect(clipX2, clipY, self:getWidth() - clipX2 - self.vscroll.width, clipY2 - clipY)
    self:drawText(value, cw + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end

function UI:setData(data)

    self.data.data = data or {}
    self:refreshData()
end

function UI:getData()
    return self.data.data
end

function UI:refreshData()
    self.controls.list:clear();
    self.lastSelected = nil

    self.data.selectedItems = {}

    for _, item in ipairs(self.data.categories or {}) do
        self.controls.list:addItem(item.label, item);
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
    local item = list.items[row]
    local data = list.parent.data.selectedItems

    -- range select
    if isShiftKeyDown() and self.lastSelected then
        local start = math.min(row, self.lastSelected)
        local finish = math.max(row, self.lastSelected)
        for i = start, finish do
            data[list.items[i].type] = true
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
    -- remember last selected for range select
    self.lastSelected = row
end

function UI:doubleClick(item)
    self.parent.selectedItems = {}
    self.parent.selectedItems[item.type] = true
    self.parent:chancePromptForSelected(self.parent.data.data[item.type])

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
    for k, v in pairs(list.parent.data.selectedItems) do
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
            target.parent:chancePromptForSelected(self.parent.data.data[item.type])
        end, item)
        context:addOption("Clear Chance", self, function(target)
            target.parent:clearSelectedChance()
        end, item)
    end
end

function UI:chancePromptForSelected(currentValue)
    local modal = ISTextBox:new(0, 0, 100, 100, "Chance (0-100)", tostring(currentValue or ""), self,
        function(target, button, obj)
            if button.internal == "OK" then
                local list = target.controls.list
                local data = list.parent.data.selectedItems
                local value = tonumber(button.parent.entry:getText())
                if value ~= nil and value >= 0 and value <= 100 then
                    for i, v in ipairs(list.items) do
                        if data[v.type] == true then
                            list.parent.data.data[v.type] = value
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
    local data = list.parent.data.selectedItems

    for i, v in ipairs(list.items) do
        if data[v.type] == true then
            list.parent.data.data[v.type] = nil
        end
    end
end
