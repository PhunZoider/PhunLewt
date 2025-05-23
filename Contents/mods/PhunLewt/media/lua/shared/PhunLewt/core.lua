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
        refillContainer = "refillContainer",
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
        Core:getSavedData()
    end
    triggerEvent(self.events.OnReady, self)
end
