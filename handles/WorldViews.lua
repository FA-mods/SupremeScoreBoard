local Prefs = import('/lua/user/prefs.lua')
local Ping = import('/lua/ui/game/ping.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
-- TODO move to utils.layout.lua
local LayoutScale = LayoutHelpers.GetPixelScaleFactor()
function UnScaleNumber(number)
    return math.floor(number / LayoutScale)
end

local armiesDetails = GetArmiesTable().armiesTable

WARN('SWV loaded handles')

local newWorldView = nil
local orgWorldView = nil

function Init(newWorld, orgWorld)
    if not orgWorldView then
        orgWorldView = orgWorld
        newWorldView = newWorld 
    end
end

function DisplayPing(worldView, pingData)

    -- adding ping overlay with name of player that created a ping
    local options = Prefs.GetFromCurrentProfile('options')
    if options['SSB_Ping_Name'] ~= false and not pingData.Marker and not pingData.Renew then
        -- showing name of player that created a ping
        local armyIndex = pingData.Owner + 1
        local armyName  = armiesDetails[armyIndex].nickname
        local fontSize  = options['SSB_Ping_Size'] or 14
        local fontColor = options['SSB_Ping_Color'] or 'ping'

        local pingOverlay = Bitmap(GetFrame(0)) 
        pingOverlay.Width:Set(10)
        pingOverlay.Height:Set(10)
        pingOverlay:SetNeedsFrameUpdate(true)
        pingOverlay.OnFrame = function(self, delta)
            local mainScreen = import('/lua/ui/game/worldview.lua').viewLeft
            local pingScreen = mainScreen:Project(pingData.Location)
            local pingX = UnScaleNumber(pingScreen.x)
            local pingY = UnScaleNumber(pingScreen.y) + LayoutHelpers.ScaleNumber(fontSize)
            LayoutHelpers.AtLeftTopIn(pingOverlay, mainScreen, pingX, pingY)
        end

        pingOverlay.text = UIUtil.CreateText(pingOverlay, armyName, fontSize, UIUtil.bodyFont)
        pingOverlay.text:SetDropShadow(true)
        if fontColor == 'army' and armiesDetails[armyIndex] then
            pingOverlay.text:SetColor(armiesDetails[armyIndex].color)
        elseif fontColor == 'ping' then 
            pingOverlay.text:SetColor(pingData.TextColor or 'Yellow')
        else
            pingOverlay.text:SetColor('white')
        end
        LayoutHelpers.AtCenterIn(pingOverlay.text, pingOverlay, 0, 0)
        
        local additionalTime = options['SSB_Ping_Time'] or 0
        local startTime = GameTime()
        ForkThread(function()
            local pingTime = startTime + pingData.Lifetime + additionalTime
            while true do
                if pingTime <= GameTime() then
                   pingOverlay:Destroy()
                   break
                end
                WaitSeconds(0.5)
            end
        end)
    end

end
 