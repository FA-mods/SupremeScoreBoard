local SSM = '/mods/SupremeScoreBoard/'
local SSB = '/mods/SupremeScoreBoard/modules/score_board.lua'

--currentScores = false  

-- show/hide old score board
local showOrgScore = false

local orgCreateScoreUI = CreateScoreUI
function CreateScoreUI(parent) 
    orgCreateScoreUI(parent)
    if not showOrgScore then HideScore() end
end

local firstBeat = true

local orgOnBeat = _OnBeat
function _OnBeat() 
     -- skipping updates of original Score board 
     -- because we are updating Supreme Score board 

    --if firstBeat then
        --firstBeat = false
        --LOG('SCORE _OnBeat '  )
    --end
     
  --import(SSM .. 'modules/score_board.lua').Update(currentScores)
  --import(SSM .. 'modules/mciscore.lua').UpdateScoreData(newData)
end

local orgToggleScoreControl = ToggleScoreControl
function ToggleScoreControl(state)
    --LOG('SCORE ToggleScoreControl '  ) 
    if showOrgScore then orgToggleScoreControl() end
end

local orgExpand = Expand
function Expand()
    --LOG('SCORE Expand '  ) 
    if showOrgScore then orgExpand() else HideScore() end

    import(SSB).Expand()
end

local orgContract = Contract
function Contract()
    --LOG('SCORE Contract '  ) 
    if showOrgScore then orgContract() else HideScore() end

    import(SSB).Contract()
end

local orgInitialAnimation = InitialAnimation
function InitialAnimation(state)
    --LOG('SCORE InitialAnimation ' ) 
    if showOrgScore then orgInitialAnimation() else HideScore() end
end

-- hides UI elements of the old score board
function HideScore()
    if controls and controls.bg then 
        --controls.bg.Right:Set(500)
        controls.bg.OnFrame = function(self, delta)
            self.Right:Set(function() return savedParent.Right() - 20000 end)
            self:SetNeedsFrameUpdate(false)
        end
        controls.bg.Right:Set(-100)
        controls.bg:Hide()
        controls.collapseArrow:Hide() 
    end
end

local orgNoteGameSpeedChanged = NoteGameSpeedChanged
function NoteGameSpeedChanged(newSpeed)
    orgNoteGameSpeedChanged(newSpeed)
    -- gameSpeed = newSpeed
    -- if observerLine.speedSlider then
    --     observerLine.speedSlider:SetValue(gameSpeed)
    -- end
    import(SSB).OnGameSpeedChanged(newSpeed)
end