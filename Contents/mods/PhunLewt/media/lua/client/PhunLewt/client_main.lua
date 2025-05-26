if isServer() then
    return
end

local Core = PhunLewt

function Core.editZoneData(player, data)
    Core.ui.editor.open(player, data, function(zone)
        local s = self
        s:setData({})
    end)
end

function Core.showLoadingModal()
    Core.hideLoadingModal()

    if not Core.ui.loadingModal then
        local w = 300
        local h = 150

        Core.ui.loadingModal = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2,
            getCore():getScreenHeight() / 2 - h / 2, w, h, "Loading...", false, nil, nil, nil);
        Core.ui.loadingModal:initialise()
        Core.ui.loadingModal:addToUIManager()
    else
        Core.ui.loadingModal:setVisible(true)
    end
    Core.ui.loadingModal:setAlwaysOnTop(true)
end

function Core.hideLoadingModal()
    if Core.ui.loadingModal then
        Core.ui.loadingModal:close()
        Core.ui.loadingModal:setVisible(false)
        Core.ui.loadingModal = nil
    end
end
