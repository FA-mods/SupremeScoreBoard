local SSB = '/mods/SupremeScoreBoard/modules/score_board.lua'
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local armiesDetails = GetArmiesTable().armiesTable

-- overloading WorldView control
local orgWorldView = WorldView 
WorldView = Class(orgWorldView, Control) {
     
    DisplayPing = function(self, pingData)

        -- passing ping data to SSB mod to flash owner's icon in score board UI
        import(SSB).DisplayPingOwner(self, pingData)
        
        orgWorldView.DisplayPing(self, pingData)
        
        -- adding ping overlay with name of player that created a ping
        local options = Prefs.GetFromCurrentProfile('options')
        if options['SSB_Ping_Name'] ~= false and not pingData.Marker and not pingData.Renew then
            -- showing name of player that created a ping
            local armyIndex = pingData.Owner + 1
            local armyName  = armiesDetails[armyIndex].nickname
            local fontSize  = options['SSB_Ping_Size'] or 14
            local fontColor = options['SSB_Ping_Color'] or 'ping'
            local additionalTime = options['SSB_Ping_Time'] or 0
            local startTime = GameTime()
            
            local pingOverlay = Bitmap(GetFrame(0))
            pingOverlay.Width:Set(10)
            pingOverlay.Height:Set(10)
            pingOverlay:SetNeedsFrameUpdate(true)
            pingOverlay.OnFrame = function(self, delta)
                local worldView = import('/lua/ui/game/worldview.lua').viewLeft
                local pos = worldView:Project(pingData.Location)
                LayoutHelpers.AtLeftTopIn(pingOverlay, worldView, 
                    pos.x - (pingOverlay.Width() / 2), 
                    pos.y - (pingOverlay.Height() / 2) + LayoutHelpers.ScaleNumber(20))
            end

            pingOverlay.text = UIUtil.CreateText(pingOverlay, armyName, fontSize, UIUtil.bodyFont)
            pingOverlay.text:SetDropShadow(true)
            if fontColor == 'army' and armiesDetails[armyIndex] then
                pingOverlay.text:SetColor(armiesDetails[armyIndex].color)
            elseif fontColor == 'ping' then 
                pingOverlay.text:SetColor(pingData.TextColor or 'white')
            else
                pingOverlay.text:SetColor('white')
            end
            LayoutHelpers.AtCenterIn(pingOverlay.text, pingOverlay, 0, 0)

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

    end,
    
  -- Register = function(self, cameraName, disableMarkers, displayName, order)
  --     orgWorldView.Register(self, cameraName, disableMarkers, displayName, order)
----       WARN('SWUI Register camera=' .. tostring(cameraName).. 'display=' .. tostring(displayName) )
  -- end,

  --  HandleEvent = function(self, event)
  --      orgWorldView.HandleEvent(self, event)
  --  end,
}