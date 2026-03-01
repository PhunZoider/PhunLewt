if isClient() then
    return
end
local Core = PhunLewt
local PZ = PhunZones

local getGameTime = getGameTime
local getSandboxOptions = getSandboxOptions

function Core.removeItemsFromContainer(container, isZed)

    local categoryLookup = Core.getCategoryLookup()

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

            -- Resolve lewtkey from PhunZones if available
            local lewtkey = nil
            if PZ then
                local z = PZ.getLocation(square)
                if z and z.lewtkey and z.lewtkey ~= "" then
                    lewtkey = z.lewtkey
                end
            end

            -- Zed inventory: prevent duplicate processing on the same corpse
            if isZed or (container:getParent() and instanceof(container:getParent(), "IsoZombie")) or
                container:getType() == "inventorymale" or container:getType() == "inventoryfemale" then
                Core.debug("PhunLewt: checking zed loot for " .. tostring(container:getType()))
                local md = container:getParent():getModData()
                if md.PhunLewtChecked then
                    return
                end
                md.PhunLewtChecked = true
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

function Core.setZoneData(data)

    local fileData = Core.getSavedData()
    fileData[data.name] = data
    Core.saveChanges(fileData)

end

function Core.saveChanges(data)

    Core.data = data
    ModData.add(Core.name, data)
    if Core.settings.Debug then
        Core.debug("PhunLewt: saving data to ModData", data)
    end
    Core.tools.saveTable(Core.consts.luaDataFileName, {
        groups = Core.groups or {},
        data = data
    })
    Core.buildLookup()
end
