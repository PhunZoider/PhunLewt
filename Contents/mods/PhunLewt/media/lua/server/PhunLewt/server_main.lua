if isClient() then
    return
end
local Core = PhunLewt
local PL = PhunLib
local PZ = PhunZones

function Core:removeItemsFromContainer(container)

    local square = container:getSourceGrid()
    local defItem = nil
    local adjustment = 1

    if square then
        local items = container and container.getItems and container:getItems()
        local removed = 0

        if items and items:size() > 0 then

            local def = self.data._default or {
                items = {},
                categories = {}
            }

            local z = PZ:getLocation(square)

            local zone = z.region == "_default" and {
                items = {},
                categories = {}
            } or self.data[z.region] and self.data[z.region][z.zone] or {
                items = {},
                categories = {}
            }

            if zone.onempty ~= nil and zone.onempty ~= "" then
                defItem = zone.onempty
            elseif zone.exclude ~= false and def.onempty ~= nil and def.onempty ~= "" then
                defItem = def.onempty
            end

            local hours = nil

            if zone.hours and zone.hours > 0 then
                hours = zone.hours
            elseif def.hours and def.hours > 0 and zone.exclude ~= false then
                hours = def.hours
            end

            if hours ~= nil then
                if getGameTime():getWorldAgeHours() < hours then
                    adjustment = getGameTime():getWorldAgeHours() / hours
                end
            end

            for i = items:size() - 1, 0, -1 do
                local item = items:get(i)
                if item and item.getFullType and item.getDisplayCategory then
                    local chance = nil
                    chance = zone.items[item:getFullType()] or zone.categories[item:getDisplayCategory()] or nil
                    if chance == nil and def.extended ~= false then
                        chance = def.items[item:getFullType()] or def.categories[item:getDisplayCategory()] or nil
                    end
                    if chance ~= nil then
                        local rand = ZombRand(100)
                        if Core.settings.Debug then
                            print("PhunLewt: Chance to remove item " .. item:getFullType() .. " (" ..
                                      item:getDisplayCategory() .. "): " .. " chance: " .. tostring(chance) ..
                                      ", adjusted: " .. tostring(adjustment) .. " (" .. tostring(hours) .. ")/(" ..
                                      tostring(getGameTime():getWorldAgeHours()) .. ") = " ..
                                      tostring(chance * adjustment) .. "%, rolled: " .. tostring(rand))
                        end

                        if rand < (chance * adjustment) then
                            if Core.settings.Debug then
                                print("PhunLewt: removing item " .. item:getFullType())
                            end
                            container:Remove(item)
                            removed = removed + 1
                        end
                    end
                end
            end
        end

        if removed > 0 and container:isEmpty() then
            if defItem then
                container:AddItem(defItem)
                if Core.settings.Debug then
                    print("PhunLewt: added default item " .. defItem .. " to container after removing all items")
                end
            end
            container:setExplored(true)
            container:setHasBeenLooted(true)
        end
    end
end

function Core:getZoneData(region, zone)
    if not region or region == "_default" then
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
    if data.exclude == false then
        d.exclude = false
    else
        d.exclude = nil
    end
    if data.onempty ~= "" then
        d.onempty = data.onempty
    else
        d.onempty = nil
    end
    if data.hours and tonumber(data.hours) > 0 then
        d.hours = tonumber(data.hours)
    else
        d.hours = nil
    end
    d.categories = data.categories or {}
    d.items = data.items or {}
    self:saveChanges(self.data)
end

function Core:saveChanges(data)
    self.data = data
    ModData.add(self.name, data)
    PhunLib.debug("PhunLewt: saving data to ModData", data)
    PL.file.saveTable(self.consts.luaDataFileName, {
        data = data
    })
end
