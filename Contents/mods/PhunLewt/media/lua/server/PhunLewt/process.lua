if isClient() then
    return
end
require "PhunLewt/core"
local Core = PhunLewt
local PL = PhunLib

function Core:getSavedData()
    local data = {}
    local d = PL.file.loadTable(self.consts.luaDataFileName)
    if d == nil then
        print("PhunLewt: missing ./lua/" .. self.consts.luaDataFileName ..
                  ", this is normal if you haven't modified any zones")
        ModData.add(self.name, {})
    elseif d.data then
        ModData.add(self.name, d.data or {})
        print("PhunLewt: loaded customisations from ./lua/" .. self.consts.luaDataFileName)
    elseif d.data == nil then
        print("PhunLewt: Unexpected format of ./lua/" .. self.consts.luaDataFileName .. ", cannot load data")
        ModData.add(self.name, {})
    end
    data = ModData.get(self.name)
    if data == nil then
        data = {}
        ModData.add(self.name, data)
    end
    Core.data = data
    return data
end
