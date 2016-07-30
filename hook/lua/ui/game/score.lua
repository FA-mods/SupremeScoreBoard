local modPath = '/mods/SupremeScoreBoard/'

--currentScores = false  

-- show/hide old score board
local showScore = false

local orgCreateScoreUI = CreateScoreUI
function CreateScoreUI(parent) 
    orgCreateScoreUI(parent)
    if not showScore then HideScore() end
end

local firstBeat = true

local orgOnBeat = _OnBeat
function _OnBeat() 

    --if firstBeat then
        --firstBeat = false
        --LOG('SCORE _OnBeat '  )
    --end
     
  --import(modPath .. 'modules/score_board.lua').Update(currentScores)
  --import(modPath .. 'modules/mciscore.lua').UpdateScoreData(newData)
end

local orgToggleScoreControl = ToggleScoreControl
function ToggleScoreControl(state)
    --LOG('SCORE ToggleScoreControl '  ) 
    if showScore then orgToggleScoreControl() end
end

local orgExpand = Expand
function Expand()
    --LOG('SCORE Expand '  ) 
    if showScore then orgExpand() else HideScore() end
end

local orgInitialAnimation = InitialAnimation
function InitialAnimation(state)
    --LOG('SCORE InitialAnimation ' ) 
    if showScore then orgInitialAnimation() else HideScore() end
end
-- hides UI elements of the old score board
function HideScore()
    if controls and controls.bg then 
        --controls.bg.Right:Set(500)
        controls.bg.Right:Set(-100)
        controls.bg:Hide()
        controls.collapseArrow:Hide() 
    end
end