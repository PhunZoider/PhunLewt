if isClient() then
    return
end

local Core = PhunLewt
local Commands = {}

local function isAuthorized(player)
    if not player then
        return false
    end
    local level = player:getAccessLevel()
    return level == "admin" or level == "moderator"
end

Commands[Core.commands.requestInheritance] = function(player, args)
    args = args or {}
    if args then
        local results = {
            username = player:getUsername(),
            inherit = Core.resolvedData[args.key] or {}
        }
        if Core.isLocal then
            triggerEvent(Core.events.OnReceiveInheritance, results.inherit)
        else
            sendServerCommand(player, Core.name, Core.commands.requestInheritance, results)
        end
    end
end

Commands[Core.commands.requestData] = function(player, args)
    -- requesting zone from the editor, reload to support lua editing 
    args = args or {}
    Core.getSavedData()

    local names = {}
    for k, v in pairs(Core.data) do
        table.insert(names, k)
    end
    Core.configNames = names or {}

    local data = args.name and Core.data[args.name] or Core.data
    local inherited = {}
    if data.inherit then
        inherited = Core.resolvedData[data.inherit] or {}
    end
    if data then
        local copy = Core.tools.deepCopy(data)
        if Core.isLocal then
            Core.editZoneData(player, {
                data = copy,
                inherit = inherited,
                names = names
            })
            Core.hideLoadingModal()
        else
            sendServerCommand(player, Core.name, Core.commands.requestData, {
                username = player:getUsername(),
                data = copy,
                inherit = inherited,
                names = names
            })
        end
    end

end

Commands[Core.commands.requestNames] = function(player, args)
    args = args or {}
    Core.getSavedData()
    if args then
        local results = {
            username = player:getUsername(),
            names = {}
        }
        for k, v in pairs(Core.data) do
            table.insert(results.names, k)
        end
        if Core.isLocal then
            Core.configNames = results.names or {}
            Core.editConfigs(player, results.names)
            Core.hideLoadingModal()
        else
            sendServerCommand(player, Core.name, Core.commands.requestNames, results)
        end
    end
end

Commands[Core.commands.requestConfigNames] = function(player, args)
    args = args or {}
    Core.getSavedData()
    if args then
        local results = {
            username = player:getUsername(),
            names = {}
        }
        for k, v in pairs(Core.data) do
            table.insert(results.names, k)
        end
        if Core.isLocal then
            Core.configNames = results.names or {}
        else
            sendServerCommand(player, Core.name, Core.commands.requestConfigNames, results)
        end
    end
end

Commands[Core.commands.saveZoneData] = function(player, args)
    if not isAuthorized(player) then
        return
    end
    if args then
        Core.debug("PhunLewt:saveZoneData", args, "--------")
        Core:setZoneData(args)
    end
end

Commands[Core.commands.delete] = function(player, args)
    if not isAuthorized(player) then
        return
    end
    if args then
        Core.debug("PhunLewt:saveZoneData", args, "--------")
        Core.data[args.name] = nil
        Core:saveChanges(Core.data)
    end
end

Commands[Core.commands.copy] = function(player, args)
    if not isAuthorized(player) then
        return
    end
    if args then
        Core.debug("PhunLewt:copy", args, "--------")
        Core.data[args.name .. "_copy"] = Core.tools.deepCopy(Core.data[args.name])
        Core.data[args.name .. "_copy"].name = args.name .. "_copy"
        Core:saveChanges(Core.data)
    end
end

Commands[Core.commands.debug] = function(player, args)
    if args then
        Core.debug("PhunLewt:debug", args, "--------")
    end
end

return Commands
