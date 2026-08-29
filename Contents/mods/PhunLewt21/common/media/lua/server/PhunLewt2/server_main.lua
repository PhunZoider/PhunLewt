if isClient() then
    return
end
local Core = PhunLewt
local PZ = PhunZones

local getGameTime = getGameTime
local getSandboxOptions = getSandboxOptions

function Core.removeItemsFromContainer(container, isZed)

    -- 42.20 fires OnFillContainer for "Zombie Bag" loot with an
    -- ItemPickerJava$ItemPickerContainer (a loot distribution definition) instead of
    -- the bag's ItemContainer. That class isn't exposed to lua, so *any* index on it
    -- throws - test the type before touching it rather than probing for a method.
    if not container or not instanceof(container, "ItemContainer") then
        return
    end

    local categoryLookup = Core.getCategoryLookup()

    local square = container:getSourceGrid()
    local defItem = nil
    local adjustment = 1
    local parent = container:getParent()
    local checks = {}

    if not square and parent and parent.getSquare then
        square = parent:getSquare()
    end

    if square and Core.resolvedData then
        local items = container and container.getItems and container:getItems()
        local removed = 0
        local doDebug = Core.settings.Debug or false

        if items and items:size() > 0 then

            local isDeadBody = parent and (instanceof(parent, "IsoDeadBody") or instanceof(parent, "IsoZombie"))
            local zed = isZed or isDeadBody or container:getType() == "inventorymale" or container:getType() ==
                            "inventoryfemale"

            -- Resolve lewtkey from PhunZones if available
            local lewtkey = nil
            if PZ then
                local z = PZ.getLocation(square)
                if z then
                    if zed then
                        if z.zlewtkey and z.zlewtkey ~= "" and z.zlewtkey ~= "none" then
                            lewtkey = z.zlewtkey
                        end
                    else
                        if z.lewtkey and z.lewtkey ~= "" and z.lewtkey ~= "none" then
                            lewtkey = z.lewtkey
                        end
                    end
                end
            end

            -- Zed inventory: prevent duplicate processing on the same corpse
            if zed then
                local md = container:getParent():getModData()
                if md.PhunLewtChecked then
                    return
                end
                md.PhunLewtChecked = true
            end

            -- Resolve config: PhunZones lewtkey > admin default for type > hardcoded "default"
            local configKey = lewtkey
            if not configKey then
                local defaults = Core.defaults or {}
                if zed and defaults.zedConfig then
                    configKey = defaults.zedConfig
                elseif not zed and defaults.containerConfig then
                    configKey = defaults.containerConfig
                end
            end
            local lookup = (configKey and Core.resolvedData[configKey]) or
                               Core.resolvedData[Core.consts.defaultConfigKey] or {
                items = {},
                categories = {}
            }

            local defaultReduction = lookup.default or 0

            if lookup.onempty ~= nil and lookup.onempty ~= "" then
                defItem = lookup.onempty
            end

            local hours = (lookup.hours and lookup.hours > 0) and lookup.hours or nil

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
                          tostring(configKey) .. adjustmentText .. " default reduction: " .. tostring(defaultReduction))

            end

            for i = items:size() - 1, 0, -1 do
                local item = items:get(i)
                if item and item.getFullType then
                    local name = item:getFullType()
                    local category = categoryLookup[name] or ""
                    -- only check item if it has a category and type
                    local chance = (lookup.items and lookup.items[name]) or
                                       (lookup.categories and lookup.categories[category]) or nil

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
                            if isDeadBody then
                                sendRemoveItemFromContainer(container, item)
                            end
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

function Core:setZoneData(data)

    local fileData = Core:getSavedData()
    fileData[data.name] = data
    Core:saveChanges(fileData)

end

function Core:saveChanges(data)

    Core.data = data
    ModData.add(Core.name, data)
    if Core.settings.Debug then
        Core.debug("PhunLewt: saving data to ModData", data)
    end
    Core.tools.saveTable(Core.consts.luaDataFileName, {
        groups = Core.groups or {},
        data = data,
        defaults = Core.defaults or {}
    })
    Core:buildLookup()
end
