if isServer() then
    return
end

local Core = PhunLewt
local PL = PhunLib
local Commands = {}

Commands[Core.commands.requestZoneData] = function(args)
    local player = PL.getPlayerByUsername(args.username)
    if player then
        Core.editZoneData(player, args.data)
    end
end

return Commands
