require "PhunZones/core"
require "PhunLewt2/client_main"
local Core = PhunLewt
local PZ = PhunZones

-- Add a button to the zone editor to edit the lewt reduction values
-- PZ.fields.lewt = {
--     label = "IGUI_PhunLewt_Lewt",
--     type = "button",
--     tooltip = "IGUI_PhunLewt_Lewt_tooltip",
--     disabledOnNewToolTip = "IGUI_PhunLewt_DisabledOnNew_tooltip",
--     onClick = function(self, zone, player)
--         Core.showLoadingModal()
--         sendClientCommand(Core.name, Core.commands.requestData, {
--             region = zone.region,
--             zone = zone.zone
--         })
--     end
-- }

PZ.fields.lewtkey = {
    label = "IGUI_PhunLewt_LewtConfig",
    type = "combo",
    tooltip = "IGUI_PhunLewt_LewtConfig_tooltip",
    initialize = function()
        sendClientCommand(Core.name, Core.commands.requestConfigNames, {})
    end,
    getOptions = function()
        local options = {" "}
        local names = Core.configNames or {}
        table.sort(names)
        for i, name in ipairs(names) do
            table.insert(options, name)
        end
        return options
    end
}

-- PZ.fields.zedlewtkey = {
--     label = "IGUI_PhunLewt_ZedLewtConfig",
--     type = "combo",
--     tooltip = "IGUI_PhunLewt_ZedLewtConfig_tooltip",
--     getOptions = function()
--         local options = {" "}
--         local names = Core.configNames or {}
--         table.sort(names)
--         for i, name in ipairs(names) do
--             table.insert(options, name)
--         end
--         return options
--     end
-- }

