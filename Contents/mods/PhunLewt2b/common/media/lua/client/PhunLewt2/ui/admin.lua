if isServer() then
    return
end

require "DebugUIs/DebugMenu/ISDebugMenu"
local Core = PhunLewt

local function showPhunLewtConfigs()
    if PL.isAdmin(getPlayer()) then
        Core.showLoadingModal()
        sendClientCommand(Core.name, Core.commands.requestNames, {})
    end
end

local ISDebugMenu_setupButtons = ISDebugMenu.setupButtons;
function ISDebugMenu:setupButtons()
    self:addButtonInfo("PhunLewt", function()
        local t = Core.tools.getAllItems(true)
        showPhunLewtConfigs()
    end, "MAIN");
    ISDebugMenu_setupButtons(self);
end

local ISAdminPanelUI_create = ISAdminPanelUI.create;
-- b42
function ISAdminPanelUI:create()

    local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
    local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
    local UI_BORDER_SPACING = 10
    local BUTTON_HGT = FONT_HGT_SMALL + 6

    local btnWid = 200;
    local x = UI_BORDER_SPACING + 1;
    local y = FONT_HGT_MEDIUM + UI_BORDER_SPACING * 2 + 1;

    self.showPhunLewtConfigs = ISButton:new(x, y, btnWid, BUTTON_HGT, "** PhunLewt **", self, showPhunLewtConfigs);
    self.showPhunLewtConfigs.internal = "";
    self.showPhunLewtConfigs:initialise();
    self.showPhunLewtConfigs:instantiate();
    self.showPhunLewtConfigs.borderColor = self.buttonBorderColor;
    self:addChild(self.showPhunLewtConfigs);

    ISAdminPanelUI_create(self);

end
