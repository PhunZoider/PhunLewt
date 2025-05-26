if isClient() then
    return
end
require "PhunLewt/core"
local Commands = require "PhunLewt/server_commands"
local Core = PhunLewt

Events.OnFillContainer.Add(function(roomtype, containertype, container)
    Core:removeItemsFromContainer(container)
end);

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name then
        if Commands[command] then
            Commands[command](playerObj, arguments)
        end
    end
end)
