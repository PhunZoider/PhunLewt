if isClient() then
    return
end
local Core = PhunLewt

local function isInSafehouse(square)

    local safehouses = SafeHouse:getSafehouseList()
    for index = 1, safehouses:size(), 1 do
        local safehouse = safehouses:get(index - 1)
        if square:getX() > safehouse:getX() and square:getX() < safehouse:getX2() then
            if square:getY() > safehouse:getY() and square:getY() < safehouse:getY2() then
                return true
            end
        end
    end
end

function Core:refillContainer(player, args)
    local square = getSquare(args.x, args.y, args.z)
    if square then
        if isInSafehouse(square) then
            return
        end
        local objs = square:getObjects()
        for i = 0, objs:size() - 1 do
            local obj = objs:get(i)
            local data = obj:getModData()
            if data and data.emptied ~= nil then
                data.emptied = 0
                local hasContainers = obj.getContainerCount and obj:getContainerCount() > 0
                local hasItemContainer = obj.getItemContainer and obj:getItemContainer()
                if hasContainers then
                    for i = 0, obj:getContainerCount() - 1 do
                        local container = obj:getContainerByIndex(i)
                        if container then
                            ItemPickerJava.fillContainer(container, player)
                        end
                        if isServer() then
                            obj:transmitUpdatedSpriteToClients()
                        end
                    end
                elseif hasItemContainer then
                    ItemPickerJava.fillContainer(hasItemContainer, player)
                    if isServer() then
                        hasItemContainer:transmitUpdatedSpriteToClients()
                    end

                end

            end
        end
    end
end

local itemsToReduceFrequencyOf = {}
function Core:removeItemsFromContainer(container)
    local items = container and container.getItems and container:getItems()
    if items and items:size() > 0 then
        for i = items:size() - 1, 0, -1 do
            local item = items:get(i)
            if item then
                local chance = itemsToReduceFrequencyOf[item:getFullType()] or 0
                if chance > 0 then
                    local rand = ZombRand(100)
                    if rand < chance then
                        container:Remove(item)
                    end
                end
            end
        end
    end
end

