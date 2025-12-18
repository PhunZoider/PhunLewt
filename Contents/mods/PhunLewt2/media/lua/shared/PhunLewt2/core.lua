require "PhunLib/core"

PhunLewt = {
    name = "PhunLewt",
    consts = {
        itemType = {
            items = "items"
        },
        luaDataFileName = "PhunLewt.lua"
    },
    data = {},
    commands = {
        playerSetup = "playerSetup",
        requestData = "requestData",
        requestInheritance = "requestInheritance",
        requestNames = "requestNames",
        requestConfigNames = "requestConfigNames",
        saveZoneData = "saveZoneData",
        debug = "debug",
        delete = "delete",
        copy = "copy"
    },
    events = {
        onReady = "PhunLewtOnReady",
        OnReceiveInheritance = "PhunLewtOnReceiveInheritance"
    },
    settings = {},
    ui = {}
}

local Core = PhunLewt
local PL = PhunLib
Core.isLocal = not isClient() and not isServer() and not isCoopHost()
Core.settings = SandboxVars[Core.name] or {}
for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core.debug(...)
    if Core.settings.debug then
        PL.debug(self.name, ...)
    end
end

function Core:ini()
    self.inied = true
    if not isClient() then
        Core.data = ModData.getOrCreate(self.name)
        Core:getSavedData()
        Core:buildLookup()
        -- self:cacheLookups()
    end
    triggerEvent(self.events.OnReady, self)
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
