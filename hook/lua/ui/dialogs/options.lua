local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import('/lua/maui/text.lua').Text
local Button = import('/lua/maui/button.lua').Button
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local Group = import('/lua/maui/group.lua').Group
local Grid = import('/lua/maui/grid.lua').Grid
local Slider = import('/lua/maui/slider.lua').Slider
local Combo = import('/lua/ui/controls/combo.lua').Combo
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local OptionsLogic = import('/lua/options/optionslogic.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')

local orgCreateOption = CreateOption
  
function CreateOption(parent, optionItemData)
    local bg = Bitmap(parent, UIUtil.SkinnableFile('/dialogs/options-02/content-box_bmp.dds'))
    
    bg._label = UIUtil.CreateText(bg, optionItemData.title, 16, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(bg._label, bg, 9, 6)
    
    --HUSSAR added fix for setting tooltip for option item
    if optionItemData.tip then
        bg._label._tipText = {text = optionItemData.title, body = optionItemData.tip }
    else
        bg._label._tipText = "options_" .. optionItemData.key
    end

    bg._label.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            Tooltip.CreateMouseoverDisplay(self, bg._label._tipText, nil, true)
            --Tooltip.CreateMouseoverDisplay(self, "options_" .. bg._label._tipText, .5, true)
        elseif event.Type == 'MouseExit' then
            Tooltip.DestroyMouseoverDisplay()
        end
    end
    
    -- this is here to help position the control
    --TODO get this data from layout!
    local controlGroup = Group(bg)
    LayoutHelpers.AtLeftTopIn(controlGroup, bg, 338, 5)
    controlGroup.Width:Set(252)
    controlGroup.Height:Set(24)

    if controlTypeCreate[optionItemData.type] then
        bg._control = controlTypeCreate[optionItemData.type](controlGroup, optionItemData)
    else
        LOG("Warning: Option item data [" .. optionItemData.key .. "] contains an unknown control type: " .. optionItemData.type .. ". Valid types are")
        for k,v in controlTypeCreate do
            LOG(k)
        end
    end
    
    if bg._control then
        LayoutHelpers.AtCenterIn(bg._control, controlGroup)
    end
    
    optionKeyToControlMap[optionItemData.key] = bg._control
    
    return bg
end