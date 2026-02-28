if isClient() then
    return
end
local Core = PhunLewt
local PZ = PhunZones

local getGameTime = getGameTime
local getSandboxOptions = getSandboxOptions

function Core:getAdjustmentsForZone(region, zone)
    Core.debug("PhunLewt: getAdjustmentsForZone", region, zone)
    return self.zoneLookups[region .. zone] or self.zoneLookups[region .. "main"]
end

function Core:removeItemsFromContainer(container, isZed)

    local categoryLookup = self:getCategoryLookup()

    local square = container:getSourceGrid()
    local defItem = nil
    local adjustment = 1
    local parent = container:getParent()
    local checks = {}

    if not square and parent and parent.getSquare then
        square = parent:getSquare()
    end

    if square and self.resolvedData then
        local items = container and container.getItems and container:getItems()
        local removed = 0
        local doDebug = self.settings.Debug or false

        if items and items:size() > 0 then

            local z = PZ:getLocation(square)
            local selfData = self.data

            local lewtkey = nil
            local resolvedData = self.resolvedData

            if isZed or (container:getParent() and instanceof(container:getParent(), "IsoZombie")) or
                container:getType() == "inventorymale" or container:getType() == "inventoryfemale" then
                Core.debug("PhunLewt: checking zed loot for " .. tostring(container:getType()))
                local md = container:getParent():getModData()
                if md.PhunLewtChecked then
                    return
                end
                md.PhunLewtChecked = true
                if z.zedlewtkey and z.zedlewtkey ~= "" then
                    lewtkey = z.zedlewtkey
                elseif z.zone ~= "main" and PZ.data[z.region] and PZ.data[z.region].main and
                    PZ.data[z.region].main.lewtkey and PZ.data[z.region].main.zedlewtkey ~= "" then
                    lewtkey = PZ.data[z.region].main.zedlewtkey
                end
            else
                if z.lewtkey and z.lewtkey ~= "" then
                    lewtkey = z.lewtkey
                elseif z.zone ~= "main" and PZ.data[z.region] and PZ.data[z.region].main and
                    PZ.data[z.region].main.lewtkey and PZ.data[z.region].main.lewtkey ~= "" then
                    lewtkey = PZ.data[z.region].main.lewtkey
                end
            end

            local lookup = {
                items = {},
                categories = {}
            }

            if self.resolvedData[lewtkey] then
                lookup = self.resolvedData[lewtkey]
            end

            local def = {
                items = {},
                categories = {}
            }

            local defaultReduction = 100

            if lookup.default then
                defaultReduction = lookup.default or 0
            else
                defaultReduction = self.settings.Default or 0
            end

            if lookup.onempty ~= nil and lookup.onempty ~= "" then
                defItem = lookup.onempty
            elseif def.onempty ~= nil and def.onempty ~= "" then
                defItem = def.onempty
            end

            local hours = nil

            if lookup.hours and lookup.hours > 0 then
                hours = lookup.hours
            elseif def.hours and def.hours > 0 then
                hours = def.hours
            end

            if hours ~= nil then
                if getGameTime():getWorldAgeHours() < hours then
                    adjustment = getGameTime():getWorldAgeHours() / hours
                end
            end

            if doDebug then
                local adjustmentText = ""
                if adjustment < 1 then
                    adjustmentText =
                        " adjustment: " .. Core.tools.formatWholeNumber(adjustment * 100) .. "% (hours: " ..
                            tostring(hours) .. " of " .. Core.tools.formatWholeNumber(getGameTime():getWorldAgeHours()) ..
                            ") "

                end
                print("PhunLewt " .. tostring(container:getType()) .. " at " .. tostring(square:getX()) .. ", " ..
                          tostring(square:getY()) .. ", " .. tostring(square:getZ()) .. ", config: " ..
                          tostring(lewtkey) .. adjustmentText .. " default reduction: " .. tostring(defaultReduction))

            end

            for i = items:size() - 1, 0, -1 do
                local item = items:get(i)
                if item and item.getFullType then
                    local name = item:getFullType()
                    local category = categoryLookup[name] or ""
                    -- only check item if it has a category and type
                    local chance = (lookup.items and lookup.items[name]) or
                                       (lookup.categories and lookup.categories[category]) or nil

                    -- if we have a value, its been specified. If not and we are not in default region, check default
                    if chance == nil then
                        chance = def.items[name] or def.categories[category] or nil
                    end
                    if chance == nil then
                        chance = defaultReduction
                    end
                    if chance ~= nil and chance > 0 then
                        local rand = ZombRand(100)
                        if doDebug then
                            print("   * " .. (name or "???") .. " (" .. (category or "???") .. "): " .. ": " ..
                                      tostring(chance) .. "%, adjusted to " ..
                                      Core.tools.formatWholeNumber(chance * adjustment) .. "%, rolled: " ..
                                      tostring(rand) .. (rand < (chance * adjustment) and " = removing" or " = keeping"))
                        end

                        if rand < (chance * adjustment) then
                            container:Remove(item)
                            removed = removed + 1
                        end
                    elseif doDebug then
                        print("   * no reduction for " .. (name or "???") .. ". Keeping.")
                    end
                end
            end
        end

        if removed > 0 and container:isEmpty() then
            if defItem then
                container:AddItem(defItem)
                Core.debug("PhunLewt: added default item " .. tostring(defItem) ..
                               " to container after removing all items")
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
    for k, v in pairs(override or {}) do
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
    fileData[data.name] = data
    self:saveChanges(fileData)

end

function Core:saveChanges(data)

    self.data = data
    ModData.add(self.name, data)
    if self.settings.Debug then
        Core.debug("PhunLewt: saving data to ModData", data)
    end
    Core.tools.saveTable(self.consts.luaDataFileName, {
        groups = self.groups or {},
        data = data
    })
    Core:buildLookup()
end
