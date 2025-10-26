if isClient() then
    return
end
require "PhunLewt/core"
local Commands = require "PhunLewt/server_commands"
local Core = PhunLewt

Events.OnFillContainer.Add(function(roomtype, containertype, container)
    print("PhunLewt:OnFillContainer", roomtype, containertype, container)
    Core:removeItemsFromContainer(container)
end);

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name then
        if Commands[command] then
            Commands[command](playerObj, arguments)
        end
    end
end)

-- Events.OnZombieDead.Add(function(zed)
--     Core.debug("PhunLewt:OnZombieDead", tostring(zed));
--     Core:removeItemsFromContainer(zed and zed:getInventory(), true)
-- end);

Events.OnServerStarted.Add(function()
    Core:ini()
end)

-- Events.LoadGridsquare.Add(function(square)
--     local wx, wy = square:getX(), square:getY()
--     Core.onSquareLoaded(square)
-- end)

-- Events.OnLoadedMapZones.Add(function()
--     print("OnLoadedMapZones")
-- end)

-- local SGlobalObjectSystem_OnChunkLoaded = SGlobalObjectSystem.OnChunkLoaded

-- SGlobalObjectSystem.OnChunkLoaded = function(self, wx, wy)

--     Core.onChunkLoaded(wx, wy)
--     return SGlobalObjectSystem_OnChunkLoaded(self, wx, wy)
-- end

-- Events.OnLoadMapZones.Add(function()
--     for x = 0, getWorld():getWidth() - 1 do
--         for y = 0, getWorld():getHeight() - 1 do
--             local sq = getCell():getGridSquare(x, y, 0)
--             if sq then
--                 local objs = sq:getObjects()
--                 for i = 0, objs:size() - 1 do
--                     local obj = objs:get(i)
--                     if instanceof(obj, "IsoContainer") then
--                         local container = obj:getContainer()
--                         print("PhunLewt:OnLoadMapZones", tostring(container))
--                         container:clear()

--                     end
--                 end
--             end
--         end
--     end
-- end)

-- Events.OnLoadChunk.Add(function(chunk)
--     local sqs = chunk:getSquares()
--     for i = 0, sqs:size() - 1 do
--         local sq = sqs:get(i)
--         if sq then
--             for j = 0, sq:getObjects():size() - 1 do
--                 local obj = sq:getObjects():get(j)
--                 if instanceof(obj, "IsoContainer") then
--                     local cont = obj:getContainer()
--                     if cont then
--                         cont:clear()
--                     end
--                 end
--             end
--         end
--     end
-- end)
