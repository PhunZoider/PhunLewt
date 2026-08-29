if isClient() then
    return
end
require "PhunLewt2/core"
local Core = PhunLewt

-- Recursive inheritance resolver
local function resolveInheritance(data)
    local resolved = {}

    local function resolveEntry(key)
        -- if already resolved, return cached copy
        if resolved[key] then
            return resolved[key]
        end

        local entry = data[key]
        if not entry then
            return nil
        end

        local result = {}

        local grouphash = {}

        if entry.inherit then
            local parent = resolveEntry(entry.inherit)
            if parent then
                result = Core.tools.deepCopy(parent)
                for _, groupName in ipairs(result.groups or {}) do
                    grouphash[groupName] = true
                end
            else
                result = {}
            end
        end

        for k, v in pairs(entry) do
            if k ~= "inherit" then
                if (k == "categories" or k == "items") and type(v) == "table" then

                    if not result[k] then
                        result[k] = {}
                    end
                    for cat, val in pairs(v) do
                        result[k][cat] = val -- child overrides parent categories
                    end
                elseif k == "groups" and type(v) == "table" then
                    result.groups = result.groups or {}
                    for _, groupName in ipairs(v) do
                        if not grouphash[groupName] then
                            table.insert(result.groups, groupName)
                        end
                    end
                else
                    result = result or {}
                    result[k] = v
                end
            end
        end

        resolved[key] = result
        return result
    end

    -- resolve all top-level entries
    for k in pairs(data) do
        resolved[k] = resolveEntry(k)
    end

    return resolved
end

function Core:buildLookup()

    local resolvedConfigs = resolveInheritance(Core.data or {})
    Core.resolvedData = resolvedConfigs
    Core.debug("PhunLewt:buildLookup", "Resolved Configs:", resolvedConfigs)

end

function Core:getSavedData()

    -- cache categories for all items
    Core.getCategoryLookup()

    -- load Lua/PhunLewt.json data into ModData
    local data = {}
    local d = Core.tools.loadTable(Core.consts.luaDataFileName)
    Core.defaults = (d and d.defaults) or {}
    if d == nil then
        -- Build 42.20.4 removed loadstring, so the old Lua-source .txt config can
        -- no longer be read by the game. Point admins at the converter rather than
        -- silently starting up with no customisations.
        if Core.tools.fileExists(Core.consts.legacyLuaDataFileName) then
            print("PhunLewt: found pre-42.20.4 config at ./lua/" .. Core.consts.legacyLuaDataFileName ..
                      " but no ./lua/" .. Core.consts.luaDataFileName)
            print("PhunLewt: build 42.20.4 removed loadstring, so .txt configs can no longer be loaded")
            print("PhunLewt: convert it at https://phunzoider.github.io/PhunZones/converter/ then save the")
            print("PhunLewt: result as ./lua/" .. Core.consts.luaDataFileName ..
                      " beside the old file and restart")
        else
            print("PhunLewt: missing ./lua/" .. Core.consts.luaDataFileName ..
                      ", this is normal if you haven't modified any zones")
        end
        ModData.add(Core.name, {})
    elseif d.data then

        -- is this a legacy format?
        if d.groups then
            -- no, its current
            Core.groups = d.groups
        else
            -- yes, its old format. Do we need to do anything spesh?
            Core.groups = {}
            -- in the old format, struct was:

            -- Louisville = {
            -- train = {
            --     categories = {
            --         Accessory = 50
            --     },
            --     items = {

            --     }
            -- },
            -- main = {
            --     categories = {

            --     },
            --     items = {
            --         ["Base.223Bullets"] = 15
            --     }
            -- }
            -- }

            -- in the new format, struct is:

            -- limited_accessories = {
            -- inherit = "base",
            -- categories = {
            --     Accessory = 50,
            -- },
            -- items = {
            --     ["Base.223Bullets"] = 15,
            -- },
            -- groups = {
            --     "books",
            --     "main",
            -- }
            -- hours = 1,
            -- name = "main_copy_copy"
            -- }
            -- so we need to flatten the old structure into multiple new structures
            -- pull out _default if it exists
            local newStruct = {
                data = {},
                groups = {}
            }
            local hasDefault = false
            local default = {
                categories = {},
                items = {}
            }
            if d.data._default and d.data._default.main then
                hasDefault = true
                default = d.data._default.main
                default.name = "default"
                newStruct.data["default"] = default
            end

            for zoneName, zoneData in pairs(d.data or {}) do
                if zoneName ~= "_default" then
                    for groupName, groupData in pairs(zoneData) do
                        local newGroupName = zoneName
                        if groupName ~= "main" then
                            newGroupName = zoneName .. "_" .. groupName
                        end
                        local newGroup = groupData
                        newGroup.name = newGroupName
                        newGroup.groups = newGroup.groups or {}
                        if newGroup.extend == false then
                            -- do nothing, no inheritance
                        else
                            if groupName == "main" then
                                newGroup.inherit = "default"
                            else
                                newGroup.inherit = zoneName
                            end
                        end
                        newGroup.extend = nil
                        -- add to main data table
                        newStruct.data[newGroupName] = newGroup
                    end
                end
            end
            -- re-save
            Core.tools.saveTable(Core.consts.luaDataFileName, newStruct)
            print("PhunLewt: converted legacy ./lua/" .. Core.consts.luaDataFileName .. " to new format")
            d = newStruct
        end
        ModData.add(Core.name, d.data or {})
        print("PhunLewt: loaded customisations from ./lua/" .. Core.consts.luaDataFileName)
    elseif d.data == nil then
        print("PhunLewt: Unexpected format of ./lua/" .. Core.consts.luaDataFileName .. ", cannot load data")
        ModData.add(Core.name, {})
    end
    data = ModData.get(Core.name)
    if data == nil then
        data = {}
        ModData.add(Core.name, data)
    end
    for k, v in pairs(data) do
        v.name = k
    end
    -- Ensure the reserved default config always exists in memory
    if not data[Core.consts.defaultConfigKey] then
        data[Core.consts.defaultConfigKey] = {
            name = Core.consts.defaultConfigKey,
            categories = {},
            items = {},
            default = 0
        }
    end
    Core:buildLookup()
    Core.data = data
    Core.debug("PhunLewt:getSavedData", data, "--------")
    return data
end

