local SSB = '/mods/SupremeScoreBoard/modules/score_board.lua'
local SWV = '/mods/SupremeScoreBoard/handles/WorldViews.lua'
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local armiesDetails = GetArmiesTable().armiesTable

-- overloading WorldView control
local orgWorldView = WorldView 
WorldView = Class(orgWorldView, Control) {
     
    DisplayPing = function(self, pingData)

        orgWorldView.DisplayPing(self, pingData)
        -- passing ping data to SSB mod to flash owner's icon in score board UI
        import(SSB).DisplayPingOwner(self, pingData)
        import(SWV).DisplayPing(self, pingData)
    end,
    
  -- Register = function(self, cameraName, disableMarkers, displayName, order)
  --     orgWorldView.Register(self, cameraName, disableMarkers, displayName, order)
----       WARN('SWUI Register camera=' .. tostring(cameraName).. 'display=' .. tostring(displayName) )
  -- end,

  --  HandleEvent = function(self, event)
  --      orgWorldView.HandleEvent(self, event)
  --  end,
}