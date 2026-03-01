if isClient() then
    return
end
require "PhunLewt2/core"
local Commands = require "PhunLewt2/server_commands"
local Core = PhunLewt

Events.OnFillContainer.Add(function(roomtype, containertype, container)
    Core.debugLn("OnFillContainer", roomtype, containertype, container)
    Core.removeItemsFromContainer(container)
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

Events.EveryTenMinutes.Add(function()
    -- refresh periodically so we aren't constantly reading from function
    Core.settings.Debug = Core.getOption("Debug", false)
end)
