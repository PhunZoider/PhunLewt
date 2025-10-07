if isClient() then
    return
end
require "PhunLewt/core"
local Core = PhunLewt
local PL = PhunLib

-- Deep copy helper
local function deepcopy(orig)
    if type(orig) ~= "table" then
        return orig
    end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = deepcopy(v)
    end
    return copy
end

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
                result = deepcopy(parent)
                for _, groupName in ipairs(result.groups or {}) do
                    grouphash[groupName] = true
                end
            else
                result = {}
            end
        end

        for k, v in pairs(entry) do
            if k ~= "inherit" then
                if k == "categories" or k == "items" and type(v) == "table" then
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

    local resolvedConfigs = resolveInheritance(self.data or {})
    Core.resolvedData = resolvedConfigs
    PL.debug("PhunLewt:buildLookup", "Resolved Configs:", resolvedConfigs)

end

function Core:getCategoryLookup(refresh)
    if not refresh and self.itemCategoryLookup then
        return self.itemCategoryLookup
    end
    local results = {}
    local itemList = getScriptManager():getAllItems()
    for i = 0, itemList:size() - 1 do
        local item = itemList:get(i)
        if not item:getObsolete() and not item:isHidden() then
            local cat = PL.getCategory(item) or ""
            results[item:getFullName()] = cat
        end
    end
    self.itemCategoryLookup = results
    return results
end

function Core:getSavedData()

    -- cache categories for all items
    self:getCategoryLookup()

    -- load Lua/PhunLewt.lua data into ModData
    local data = {}
    local d = PL.file.loadTable(self.consts.luaDataFileName)
    if d == nil then
        print("PhunLewt: missing ./lua/" .. self.consts.luaDataFileName ..
                  ", this is normal if you haven't modified any zones")
        ModData.add(self.name, {})
    elseif d.data then

        -- is this a legacy format?
        if d.groups then
            -- no, its current
            self.groups = d.groups
        else
            -- yes, its old format. Do we need to do anything spesh?
            self.groups = {}
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

            for zoneName, zoneData in pairs(d.data) do
                if zoneName ~= "_default" then
                    for groupName, groupData in pairs(zoneData) do
                        local newGroupName = zoneName
                        if groupName ~= "main" then
                            newGroupName = zoneName .. "_" .. groupName
                        end
                        local newGroup = groupData
                        newGroup.name = newGroupName
                        newGroup.groups = newGroup.groups or {}
                        if newGroupName.extend == false then
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
            PL.file.saveTable(self.consts.luaDataFileName, newStruct)
            print("PhunLewt: converted legacy ./lua/" .. self.consts.luaDataFileName .. " to new format")
            d = newStruct
        end
        ModData.add(self.name, d.data or {})
        print("PhunLewt: loaded customisations from ./lua/" .. self.consts.luaDataFileName)
    elseif d.data == nil then
        print("PhunLewt: Unexpected format of ./lua/" .. self.consts.luaDataFileName .. ", cannot load data")
        ModData.add(self.name, {})
    end
    data = ModData.get(self.name)
    if data == nil then
        data = {}
        ModData.add(self.name, data)
    end
    for k, v in pairs(data) do
        v.name = k
    end
    self:buildLookup()
    Core.data = data
    PL.debug("PhunLewt:getSavedData", data, "--------")
    return data
end

