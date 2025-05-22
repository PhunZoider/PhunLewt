if isServer() then
    return
end
local Core = PhunLewt
local Commands = require("PhunLewt/commands")

local function setup()
    Events.OnTick.Remove(setup)
    Core:ini()
    sendClientCommand(Core.name, Core.commands.playerSetup, {})
end

Events.OnTick.Add(setup)

Events.OnRefreshInventoryWindowContainers.Add(function(page, state)
    if state == "end" and Core.settings.FixEmptyContainers then
        Core:checkRemoveItems(page)
    end
end);

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == Core.name then
        if Commands[command] then
            Commands[command](arguments)
        end
    end
end)
