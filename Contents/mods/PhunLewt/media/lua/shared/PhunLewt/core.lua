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
        requestZoneData = "requestZoneData",
        saveZoneData = "saveZoneData"
    },
    events = {
        onReady = "PhunLewtOnReady"
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

function Core:ini()
    self.inied = true
    if not isClient() then
        Core.data = ModData.getOrCreate(self.name)
        -- Core:getSavedData()
    end
    triggerEvent(self.events.OnReady, self)
end

function Core:getReductionValue(region, zone, item)
    if self.data[region] and self.data[region][zone] and self.data[region][zone][item] then
        return self.data[region][zone][item]
    end
    if self.data._default and self.data._default[item] then
        return self.data._default[item]
    end
    return 0
end
