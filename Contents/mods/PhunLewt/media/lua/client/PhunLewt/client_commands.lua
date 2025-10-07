if isServer() then
    return
end

local Core = PhunLewt
local PL = PhunLib
local Commands = {}

Commands[Core.commands.requestData] = function(args)
    local player = PL.getPlayerByUsername(args.username)
    if player then
        args.username = nil
        Core.editZoneData(player, args)
        Core.hideLoadingModal()
    end
end

Commands[Core.commands.requestInheritance] = function(args)
    local player = PL.getPlayerByUsername(args.username)
    if player then
        args.username = nil
        triggerEvent(Core.events.OnReceiveInheritance, args.inherit or {})
    end
end

Commands[Core.commands.requestNames] = function(args)
    local player = PL.getPlayerByUsername(args.username)
    if player then
        args.username = nil
        Core.configNames = args.names or {}
        Core.editConfigs(player, args.names)
        Core.hideLoadingModal()
    end
end

return Commands
