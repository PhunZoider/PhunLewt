if isClient() then
    return
end
require "PhunLewt2/core"
local Commands = require "PhunLewt2/server_commands"
local Core = PhunLewt

Events.OnFillContainer.Add(function(roomtype, containertype, container)
    print("PhunLewt:OnFillContainer", roomtype, containertype, container)
    Core:removeItemsFromContainer(container)
end);

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name then
        if Commands[command] then
            Commands[command](playerObj, arguments)
        end
    end
end)

Events.OnServerStarted.Add(function()
    Core:ini()
end)
