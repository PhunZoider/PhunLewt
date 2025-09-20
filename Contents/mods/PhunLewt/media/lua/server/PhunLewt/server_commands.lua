if isClient() then
    return
end

local Core = PhunLewt
local PL = PhunLib
local Commands = {}

Commands[Core.commands.requestZoneData] = function(player, args)
    -- requesting zone from the editor, reload to support lua editing 
    Core:getSavedData()
    local data = Core:getZoneData(args.region, args.zone)
    if data then
        local copy = PL.table.deepCopy(data)
        if Core.isLocal then
            Core.editZoneData(player, copy)
            Core.hideLoadingModal()
        else
            copy.username = player:getUsername()
            sendServerCommand(player, Core.name, Core.commands.requestZoneData, copy)
        end
    end

end

Commands[Core.commands.saveZoneData] = function(player, args)
    if args then
        PL.debug("PhunLewt:saveZoneData", args, "--------")
        Core:setZoneData(args)
    end
end

Commands[Core.commands.debug] = function(player, args)
    if args then
        PL.debug("PhunLewt:debug", args, "--------")
    end
end

return Commands
