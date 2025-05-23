if isClient() then
    return
end
local Core = PhunLewt
local PL = PhunLib

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

function Core:getZoneData(region, zone)
    if not region or region == "'_default" then
        if not self.data._default then
            self.data._default = {}
        end
        if not self.data._default.categories then
            self.data._default.categories = {}
        end
        if not self.data._default.items then
            self.data._default.items = {}
        end
        return self.data._default
    end
    if not self.data[region] then
        self.data[region] = {}
    end
    if not self.data[region][zone] then
        self.data[region][zone] = {
            categories = {},
            items = {}
        }
    end
    if not self.data[region][zone].categories then
        self.data[region][zone].categories = {}
    end
    if not self.data[region][zone].items then
        self.data[region][zone].items = {}
    end
    return self.data[region][zone]

end

function Core:setZoneData(data)
    local d = self:getZoneData(data.region, data.zone)
    d.categories = data.categories or {}
    d.items = data.items or {}
    self:saveChanges(self.data)
end

function Core:saveChanges(data)
    ModData.add(self.name, data)
    PL.file.saveTable(self.consts.luaDataFileName, {
        data = data
    })
end
