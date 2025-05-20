if isClient() then
    return
end
require "PhunLewt/core"
local Commands = require "PhunLewt/commands"
local Core = PhunLewt

Events.OnFillContainer.Add(function(roomtype, containertype, container)
    Core:removeItemsFromContainer(container)
end);

Events.OnGameBoot.Add(function()
    Core:tweakItems()
end)
Events.OnServerStarted.Add(function()
    Core:refreshItemsToReduce()
end)

