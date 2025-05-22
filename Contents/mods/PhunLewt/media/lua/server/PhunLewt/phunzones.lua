require "PhunZones/core"
require "PhunLewt/client_main"
local Core = PhunLewt
local PZ = PhunZones

-- Add a setting for radiation level to the PhunZones mod
PZ.fields.lewt = {
    label = "IGUI_PhunLewt_Lewt",
    type = "button",
    tooltip = "IGUI_PhunLewt_Lewt_tooltip",
    disabledOnNewToolTip = "IGUI_PhunLewt_DisabledOnNew_tooltip",
    onClick = function(self, zone, player)
        sendClientCommand(Core.name, Core.commands.requestZoneData, {
            region = zone.region,
            zone = zone.zone
        })
    end
}
