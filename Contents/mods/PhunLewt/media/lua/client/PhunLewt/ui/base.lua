if isServer() then
    return
end
local tools = require "PhunLewt/ui/tools"
local Core = PhunLewt
local PL = PhunLib
local profileName = "PhunMartUIBase"
PhunLewtBase = ISPanelJoypad:derive(profileName);
local UI = PhunLewtBase

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

function UI:setData(data)

    self.data.data = data or {}
    self:refreshData()
end

function UI:getData()
    return self.data.data
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
    local data = list.parent.data.selectedItems

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
                        if data[v.item.type] == true then
                            list.parent.data.data[v.item.type] = value
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
        if data[v.item.type] == true then
            list.parent.data.data[v.item.type] = nil
        end
    end
end

function UI:doOnMouseMoveOutside(dx, dy)
    local tooltip = self.parent.tooltip
    tooltip:setVisible(false)
    tooltip:removeFromUIManager()
end
function UI:doOnMouseMove(dx, dy)

    local showInvTooltipForItem = nil
    local item = nil
    local tooltip = nil

    if not self.dragging and self.rowAt then
        if self:isMouseOver() then
            local row = self:rowAt(self:getMouseX(), self:getMouseY())
            if row ~= nil and row > 0 and self.items[row] then
                item = self.items[row].item
                if item then
                    tooltip = self.parent.tooltip

                    tooltip:setItem(instanceItem(item.type))

                    if not tooltip:isVisible() then

                        tooltip:addToUIManager();
                        tooltip:setVisible(true)
                    end
                    tooltip:bringToTop()
                elseif self.parent.tooltip:isVisible() then
                    self.parent.tooltip:setVisible(false)
                    self.parent.tooltip:removeFromUIManager()
                end
            end
        end
    end

end

function UI:doTooltip()
end

function UI:refreshData()
end
