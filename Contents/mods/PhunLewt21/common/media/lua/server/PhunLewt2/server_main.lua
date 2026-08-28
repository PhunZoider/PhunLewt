if isClient() then
    return
end
local Core = PhunLewt
local PZ = PhunZones

local getGameTime = getGameTime
local getSandboxOptions = getSandboxOptions

-- Applies a resolved config to a container's items, recursing into any bag that
-- survives the roll. Build 42 does fire OnFillContainer for the contents of a
-- spawned bag, but hands it ItemPickerJava$ItemPickerContainer -- the distribution
-- definition rather than the container -- so those items are unreachable from the
-- event itself, and can only be found from the container holding the bag. The
-- parent's event fires after its bags are filled, so they are populated by now.
local function applyReduction(container, ctx, depth)

    local items = container and container.getItems and container:getItems()
    if not items or items:size() == 0 then
        return 0
    end

    local lookup = ctx.lookup
    local indent = string.rep("   ", depth + 1)
    local removed = 0

    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if item and item.getFullType then
            local name = item:getFullType()
            local category = ctx.categoryLookup[name] or ""
            -- only check item if it has a category and type
            local chance = (lookup.items and lookup.items[name]) or
                               (lookup.categories and lookup.categories[category]) or nil

            if chance == nil then
                chance = ctx.defaultReduction
            end

            local kept = true
            if chance ~= nil and chance > 0 then
                local rand = ZombRand(100)
                if ctx.doDebug then
                    print(indent .. "* " .. (name or "???") .. " (" .. (category or "???") .. "): " .. ": " ..
                              tostring(chance) .. "%, adjusted to " ..
                              Core.tools.formatWholeNumber(chance * ctx.adjustment) .. "%, rolled: " ..
                              tostring(rand) .. (rand < (chance * ctx.adjustment) and " = removing" or " = keeping"))
                end

                if rand < (chance * ctx.adjustment) then
                    container:Remove(item)
                    if ctx.isDeadBody then
                        sendRemoveItemFromContainer(container, item)
                    end
                    removed = removed + 1
                    kept = false
                end
            elseif ctx.doDebug then
                print(indent .. "* no reduction for " .. (name or "???") .. ". Keeping.")
            end

            -- a bag that survived still holds loot of its own
            if kept and depth < ctx.maxDepth and item.getItemContainer and instanceof(item, "InventoryContainer") then
                local inner = item:getItemContainer()
                if inner then
                    if ctx.doDebug then
                        print(indent .. "> descending into " .. (name or "???"))
                    end
                    removed = removed + applyReduction(inner, ctx, depth + 1)
                end
            end
        end
    end

    return removed
end

function Core.removeItemsFromContainer(container, isZed)

    -- OnFillContainer can fire with an ItemPickerJava$ItemPickerContainer (or another
    -- non-ItemContainer wrapper) which has none of the methods used below.
    if not container or not container.getSourceGrid or not container.getParent or not container.getItems then
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
            if zed and parent then
                local md = parent:getModData()
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

            -- nested bags share the parent config: they have no square of their own
            removed = applyReduction(container, {
                categoryLookup = categoryLookup,
                lookup = lookup,
                defaultReduction = defaultReduction,
                adjustment = adjustment,
                doDebug = doDebug,
                isDeadBody = isDeadBody,
                maxDepth = Core.consts.maxContainerDepth or 3
            }, 0)
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
