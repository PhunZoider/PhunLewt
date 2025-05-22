if isClient() then
    return
end

local Core = PhunLewt
local Commands = {}

Commands[Core.commands.requestZoneData] = function(player, args)

    local data = Core:getZoneData(args.region, args.zone)
    if data then
        if Core.isLocal then
            Core.editZoneData(player, data)
        else
            local payload = {
                username = player:getUsername(),
                data = data
            }
            sendServerCommand(player, Core.name, Core.commands.requestZoneData, payload)
        end
    end

end

return Commands
