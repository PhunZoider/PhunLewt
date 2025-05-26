require "PhunZones/core"
require "PhunLewt/client_main"
local Core = PhunLewt
local PZ = PhunZones

-- Add a button to the zone editor to edit the lewt reduction values
PZ.fields.lewt = {
    label = "IGUI_PhunLewt_Lewt",
    type = "button",
    tooltip = "IGUI_PhunLewt_Lewt_tooltip",
    disabledOnNewToolTip = "IGUI_PhunLewt_DisabledOnNew_tooltip",
    onClick = function(self, zone, player)
        Core.showLoadingModal()
        sendClientCommand(Core.name, Core.commands.requestZoneData, {
            region = zone.region,
            zone = zone.zone
        })
    end
}
