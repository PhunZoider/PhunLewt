if isServer() then
    return
end

local Core = PhunLewt
local PL = PhunLib
local Commands = {}

Commands[Core.commands.requestZoneData] = function(args)
    local player = PL.getPlayerByUsername(args.username)
    if player then
        args.username = nil
        Core.editZoneData(player, args)
        Core.hideLoadingModal()
    end
end

return Commands
