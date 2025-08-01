if isClient() then
    return
end
local Core = PhunLewt
local PL = PhunLib
local PZ = PhunZones

function Core:removeItemsFromContainer(container)
    if self.zoneLookups == nil then
        self:cacheLookups()
    end
    local square = container:getSourceGrid()
    local defItem = nil
    local adjustment = 1

    local checks = {}

    if square then
        local items = container and container.getItems and container:getItems()
        local removed = 0

        if items and items:size() > 0 then

            local def = {
                items = {},
                categories = {}
            }

            if self.data._default and self.data._default.main then
                def = self.data._default.main or self.data._default or {
                    items = {},
                    categories = {}
                }
            end

            local z = PZ:getLocation(square)

            local lookup = self.zoneLookups[z.region .. z.zone] or self.zoneLookups[z.region .. "main"] or def

            if lookup.onempty ~= nil and lookup.onempty ~= "" then
                defItem = lookup.onempty
            end

            local hours = nil

            if lookup.hours and lookup.hours > 0 then
                hours = lookup.hours
            elseif def.hours and def.hours > 0 and lookup.exclude ~= false then
                hours = def.hours
            end

            if hours ~= nil then
                if getGameTime():getWorldAgeHours() < hours then
                    adjustment = getGameTime():getWorldAgeHours() / hours
                end
            end

            -- PhunLib.debug("PhunLewt:def", def)

            for i = items:size() - 1, 0, -1 do
                local item = items:get(i)
                if item and item.getFullType and item.getDisplayCategory then
                    local chance = (lookup.items and lookup.items[item:getFullType() or ""]) or
                                       (lookup.categories and lookup.categories[item:getDisplayCategory() or ""]) or nil
                    if chance == nil and z.region ~= "_default" and lookup.extend ~= false then
                        chance =
                            def.items[item:getFullType() or ""] or def.categories[item:getDisplayCategory() or ""] or
                                nil
                    end
                    if chance == nil then
                        chance = (100 - self.settings.Default)
                    end
                    if chance ~= nil then
                        local rand = ZombRand(100)
                        if Core.settings.Debug then
                            print("PhunLewt: Chance to remove item " .. (item:getFullType() or "???") .. " (" ..
                                      (item:getDisplayCategory() or "???") .. "): " .. " chance: " .. tostring(chance) ..
                                      ", adjusted: " .. tostring(adjustment) .. " (" .. tostring(hours) .. ")/(" ..
                                      tostring(getGameTime():getWorldAgeHours()) .. ") = " ..
                                      tostring(chance * adjustment) .. "%, rolled: " .. tostring(rand))
                        end

                        if rand < (chance * adjustment) then
                            if Core.settings.Debug then
                                print("PhunLewt: removing item " .. (item:getFullType() or "???"))
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

local function deepMerge(base, override)
    local result = {}
    for k, v in pairs(base) do
        if type(v) == "table" then
            result[k] = {}
            for sk, sv in pairs(v) do
                result[k][sk] = sv
            end
        else
            result[k] = v
        end
    end
    for k, v in pairs(override) do
        if type(v) == "table" then
            result[k] = result[k] or {}
            for sk, sv in pairs(v) do
                result[k][sk] = sv
            end
        else
            result[k] = v
        end
    end
    return result
end

function Core:cacheLookups()

    local default = self.data._default or {}

    local results = {}
    for k, v in pairs(self.data) do
        if k ~= "_default" then
            local regionData = self.data[k] or {}

            if type(v) == "table" then
                for zone, zoneData in pairs(v) do

                    local key = k .. zone

                    local main = zone ~= "main" and self.data[k].main or {}
                    local subzone = self.data[k][zone] or {}

                    if subzone.extend ~= false then
                        subzone = deepMerge(main, subzone)
                    end
                    results[key] = subzone
                end
            end
        end
    end
    self.zoneLookups = results
end

function Core:getZoneData(region, zone)
    if not region or region == "_default" then
        if not self.data._default then
            self.data._default = {}
        end
        if not self.data._default.main then
            self.data._default.main = {
                categories = {},
                items = {}
            }
        end
        if not self.data._default.main.categories then
            self.data._default.categories = {}
        end
        if not self.data._default.main.items then
            self.data._default.main.items = {}
        end
        self.data._default.region = "_default"
        self.data._default.zone = "main"
        self.data._default.main.region = "_default"
        self.data._default.main.zone = "main"
        return self.data._default.main
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
    self.data[region][zone].region = region
    self.data[region][zone].zone = zone
    return self.data[region][zone]

end

function Core:setZoneData(data)

    local fileData = Core:getSavedData()

    if fileData == nil then
        fileData = {}
    end
    if not fileData[data.region] then
        fileData[data.region] = {}
    end
    if not fileData[data.region][data.zone] then
        fileData[data.region][data.zone] = {
            categories = {},
            items = {}
        }
    end
    if data.extend == false then
        fileData[data.region][data.zone].extend = false
    else
        fileData[data.region][data.zone].extend = nil
    end
    if data.onempty ~= "" then
        fileData[data.region][data.zone].onempty = data.onempty
    else
        fileData[data.region][data.zone].onempty = nil
    end
    if data.hours and tonumber(data.hours) > 0 then
        fileData[data.region][data.zone].hours = tonumber(data.hours)
    else
        fileData[data.region][data.zone].hours = nil
    end
    fileData[data.region][data.zone].categories = data.categories or {}
    fileData[data.region][data.zone].items = data.items or {}
    self:saveChanges(fileData)

    -- local d = self:getZoneData(data.region, data.zone)
    -- if data.extend == false then
    --     d.extend = false
    -- else
    --     d.extend = nil
    -- end
    -- if data.onempty ~= "" then
    --     d.onempty = data.onempty
    -- else
    --     d.onempty = nil
    -- end
    -- if data.hours and tonumber(data.hours) > 0 then
    --     d.hours = tonumber(data.hours)
    -- else
    --     d.hours = nil
    -- end
    -- d.categories = data.categories or {}
    -- d.items = data.items or {}
    -- self:saveChanges(self.data)
    self:cacheLookups()
end

function Core:saveChanges(data)
    self.data = data
    ModData.add(self.name, data)
    if self.settings.Debug then
        PhunLib.debug("PhunLewt: saving data to ModData", data)
    end
    PL.file.saveTable(self.consts.luaDataFileName, {
        data = data
    })
end
