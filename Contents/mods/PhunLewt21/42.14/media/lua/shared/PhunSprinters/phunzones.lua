require "PhunLewt2/client_main"
local Core = PhunLewt

Events[Core.events.OnReady].Add(function()

    local activeMods = getActivatedMods()

    if activeMods:contains("\\phunzones2") or activeMods:contains("\\phunzones2test") then
        require "PhunZones/core"
        local PZ = PhunZones

        print("[PhunLewt] PhunZones2 detected, adding zone fields for PhunLewt")

        PZ.fields.lewtkey = {
            label = "IGUI_PhunLewt_LewtConfig",
            type = "combo",
            tooltip = "IGUI_PhunLewt_LewtConfig_tooltip",
            initialize = function()
                sendClientCommand(Core.name, Core.commands.requestConfigNames, {})
            end,
            getOptions = function()
                local options = {{
                    label = " ",
                    value = "none"
                }}
                local names = Core.configNames or {}
                table.sort(names)
                for i, name in ipairs(names) do
                    table.insert(options, {
                        label = name,
                        value = name
                    })
                end
                return options
            end
        }

        if Core.getOption("SeparateZedConfig") then
            PZ.fields.zlewtkey = {
                label = "IGUI_PhunLewt_ZedLewtConfig",
                type = "combo",
                tooltip = "IGUI_PhunLewt_ZedLewtConfig_tooltip",
                initialize = function()
                    sendClientCommand(Core.name, Core.commands.requestConfigNames, {})
                end,
                getOptions = function()
                    local options = {{
                        label = " ",
                        value = "none"
                    }}
                    local names = Core.configNames or {}
                    table.sort(names)
                    for i, name in ipairs(names) do
                        table.insert(options, {
                            label = name,
                            value = name
                        })
                    end
                    return options
                end
            }

        end

    else
        print("[PhunLewt] PhunZones2 not detected, using default zone data for PhunLewt")
    end

end)
