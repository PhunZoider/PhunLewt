if isServer() then
    return
end
local Core = PhunLewt
Core.contexts = {}

local mainName = "PhunLewt"

-- function Core:appendContext(context, mainMenu, playerObj, worldobjects)

--     local sub = ISContextMenu:getNew(context)
--     context:addSubMenu(mainMenu, sub)
--     sub:addOption(self.name, nil, function()
--         local player = playerObj and getSpecificPlayer(playerObj) or getPlayer()
--         Core.ui.editor.open(player, {}, function(data)
--             local s = self
--             s.filters = data
--             s:setData({})
--         end)
--     end)

-- end
