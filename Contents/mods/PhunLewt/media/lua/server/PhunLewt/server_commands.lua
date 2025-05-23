if isClient() then
    return
end

local Core = PhunLewt
local Commands = {}

Commands[Core.commands.requestZoneData] = function(player, args)

    local data = Core:getZoneData(args.region, args.zone)
    if data then
        if Core.isLocal then
            Core.editZoneData(player, {
                region = args.region,
                zone = args.zone,
                categories = data.categories,
                items = data.items
            })
        else
            local payload = {
                username = player:getUsername(),
                region = args.region,
                categories = data.categories,
                items = data.items
            }
            sendServerCommand(player, Core.name, Core.commands.requestZoneData, payload)
        end
    end

end

Commands[Core.commands.saveZoneData] = function(player, args)
    if args then
        Core:setZoneData(args)
    end
end

return Commands
