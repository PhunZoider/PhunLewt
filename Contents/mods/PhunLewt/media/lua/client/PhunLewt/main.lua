if isServer() then
    return
end

local Core = PhunLewt

function Core:checkEmptyContainer(container, parent)

    local md = parent:getModData()
    local hours = self.settings.MaxGameHoursForEmptyContainer or 0

    if hours > 0 then

        if container:isEmpty() then
            container:setExplored(true)
            container:setHasBeenLooted(true)

            if not md.emptied or md.emptied == 0 then

                if not Core.isInSafehouse(parent) then
                    md.emptied = getGameTime():getWorldAgeHours()
                else
                    md.emptied = -1
                end
                parent:transmitModData()
            elseif md.emptied > 0 and md.emptied + hours < getGameTime():getWorldAgeHours() then
                sendClientCommand(self.name, self.commands.refillContainer, {
                    x = parent:getX(),
                    y = parent:getY(),
                    z = parent:getZ()
                })
                md.hadItemsRemoved = false
                md.isHasBeenLooted = false
                md.emptied = 0
                parent:transmitModData()
            end
        elseif md.emptied then
            md.emptied = nil
            parent:transmitModData()
        end
    end

end

function Core:checkRemoveItems(inventoryPage)

    local containers = {}

    for i, v in ipairs(inventoryPage.backpacks) do

        local container = nil
        local parent = v.inventory:getParent()

        if parent then
            if v.inventory:getVehiclePart() then
                local part = v.inventory:getVehiclePart();
                if part:getItemContainer() then
                    -- checkEmptyContainer(part:getItemContainer(), parent)
                    -- container = part:getItemContainer();
                end
            elseif instanceof(parent, "IsoDeadBody") or not parent.getContainer or not parent.getItemContainer then
                parent = nil
            else
                if parent.getContainerCount then
                    for i = 0, parent:getContainerCount() - 1 do
                        self:checkEmptyContainer(parent:getContainerByIndex(i), parent)
                    end
                else
                    self:checkEmptyContainer(parent:getItemContainer(), parent)
                end
            end
        end

    end

end
