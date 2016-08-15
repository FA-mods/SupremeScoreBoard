--*****************************************************************************
--* File: lua/modules/ui/game/gameresult.lua
--* Summary: Victory and Defeat behavior
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local modPath = '/mods/SupremeScoreBoard/' 
local modScripts  = modPath..'modules/'
local str  = import(modScripts..'ext.strings.lua')
local log  = import(modScripts..'ext.logging.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

--TODO-FAF add
--local AnnounceDeath     = import('/lua/ui/game/score.lua').AnnounceDeath
--local AnnounceDraw      = import('/lua/ui/game/score.lua').AnnounceDraw
--local AnnounceVictory   = import('/lua/ui/game/score.lua').AnnounceVictory
local AnnounceDeath     = import(modScripts..'score_board.lua').AnnounceDeath
local AnnounceDraw      = import(modScripts..'score_board.lua').AnnounceDraw
local AnnounceVictory   = import(modScripts..'score_board.lua').AnnounceVictory
  
local OtherArmyResultStrings = {
    --TODO add localization tags and update strings when integrating with FAF
    victory  =   ' has won this game! ',      -- <LOC usersync_0001>
    defeat   =    'has been defeated by',    -- <LOC usersync_0002>
    draw     = '   has drawn with   ',          -- <LOC usersync_0003>
    gameOver = 'Game Over.',              -- <LOC usersync_0004>
}

local MyArmyResultStrings = {
    --TODO add localization tags and update strings when integrating with FAF
    victory =    " You have won this game! ",    -- <LOC GAMERESULT_0000>
    defeat  =     "You have been defeated by",  -- <LOC GAMERESULT_0001>
    draw    = "    You have draw with   ",         -- <LOC GAMERESULT_0002>
    replay  = "Replay Finished.",           -- <LOC GAMERESULT_0003>
}

function OnReplayEnd()
    LOG('GAMERESULTS... OnReplayEnd' )
   
    --import('/lua/ui/game/tabs.lua').TabAnnouncement('main', LOC(MyArmyResultStrings.replay))
    import('/lua/ui/game/tabs.lua').AddModeText("<LOC _Score>", function() import('/lua/ui/dialogs/score.lua').CreateDialog(true) end)
end
 
local stats = { done = false, players = {}, fallens = {}, killers = {} }
 
function DoGameResult(armyID, result)
    
    local armies = GetArmiesTable().armiesTable
    local armyName = armies[armyID].nickname or 'civilian' 
    log.Trace('GameResults: result = ' .. result .. ', armyID = ' .. armyID..', name = ' .. armyName)

    if stats.done then return end 

    for id, army in armies do
        if not army.civilian  then
            if not stats.players[id] and not army.civilian then
                stats.players[id] = {}
                stats.players[id].name  = army.nickname
                stats.players[id].score = 0
                stats.players[id].dead  = false 
                stats.players[id].kills = {}
            end
            stats.players[id].dead = army.outOfGame
        end
    end
     
    local split = str.split(result, ' ')
    local value  = tonumber(split[2])
    local result = tostring(split[1]) 
  
    if result == 'score' then --and stats.players[armyID].score < value then
        stats.killers[armyID] = true
        stats.players[armyID].score = stats.players[armyID].score + 1
        --LOG('GameResults: SCORE '
        --.. tostring(stats.players[armyID].score).. ' => ' .. tostring(value)  .. ' ' .. armyName)
    end

    --stats.players[armyID][result] = value
    
    -- skip duplicated score results
    if result == 'score' or stats.players[armyID].announced or stats.fallens[armyID] then
        return 
    end
     
    stats.players[armyID].announced = true

    if result == 'defeat' and stats.killers[armyID] then
       log.Trace('GameResults: ' .. tostring(result) .. ' -> ' .. 'draw')
       result = 'draw'
    end

    local message = '' --LOC(OtherArmyResultStrings[result]) 
    if armyID ~= GetFocusArmy() then
        message = ' '.. LOC(OtherArmyResultStrings[result]).. ' ' 
    else 
        message = ' '.. LOC(MyArmyResultStrings[result]) .. ' '
    end
    
    if result == 'defeat' then 
        local losersID = armyID
        local winnerID = nil
        for id, present in stats.killers do
            if id ~= armyID and present then 
                winnerID = id 
                break
            end
        end
        if not winnerID then
           winnerID = losersID -- player did CTRL+K
        end
        local losersName = armies[losersID].nickname or 'armies[' .. losersID ..'].name = nil'
        local winnerName = armies[winnerID].nickname or 'armies[' .. winnerID ..'].name = nil'
        log.Trace('GameResults: ' .. tostring(losersName) .. message .. tostring(winnerName))
        
        stats.fallens[losersID] = true

        stats.players[winnerID].kills[losersID] = true
        stats.players[winnerID].score = stats.players[winnerID].score - 1
        if stats.players[winnerID].score < 1 then
           stats.killers[winnerID] = false
        end        
        AnnounceDeath(losersID, message, winnerID)

    elseif result == 'draw' and not stats.fallens[armyID] then 
        local armyName = armies[armyID].nickname  or 'armies[' .. armyID ..'] = nil'
        log.Trace('GameResults: DRAW ' .. tostring(value) .. ' ' .. armyName)
        local drawingID1 = armyID
        local drawingID2 = nil
        for id, present in stats.killers do
            if id ~= armyID and present then 
                drawingID2 = id 
                break
            end
        end
        log.Trace('GameResults: ' .. tostring(drawingID1) .. message .. tostring(drawingID2))

        if drawingID1 ~= nil then
            stats.killers[drawingID1] = false 
            stats.fallens[drawingID1] = true
        end

        if drawingID2 ~= nil then 
            stats.killers[drawingID2] = false
            stats.fallens[drawingID2] = true
        end

        if drawingID1 ~= nil and drawingID2 ~= nil then
            stats.players[drawingID1].kills[drawingID2] = true
            stats.players[drawingID2].kills[drawingID1] = true

            AnnounceDraw(drawingID1, message, drawingID2)
        end 
    end

   -- log.Table(stats, 'stats')

    -- If it's someone else, skip it
    if armyID ~= GetFocusArmy() then --and result ~= 'victory' then
        return
    end

    -- Otherwise, do the end-of-game stuff.
    if SessionIsObservingAllowed() then
       SetFocusArmy(-1)
    end
    
    local victory = result == 'victory'
    log.Trace('GameResults:... ' .. tostring(result).. ' | victory = '  .. tostring(victory) )
    if victory then
        --TODO AnnounceVictory(losersID, message, drawingIndex)
        AnnounceVictory(armyID, message)
        PlaySound(Sound({Bank = 'Interface', Cue = 'UI_END_Game_Victory'}))
    else
        --TODO AnnounceDefeat(losersID, message, drawingIndex)
        PlaySound(Sound({Bank = 'Interface', Cue = 'UI_END_Game_Fail'}))
    end
    stats.done = true

    local tabs = import('/lua/ui/game/tabs.lua')
    tabs.OnGameOver()
    
    --message = ' '.. LOC(MyArmyResultStrings[result]) .. ' '
    --tabs.TabAnnouncement('main', LOC(MyArmyResultStrings[result]))

    local score = import('/lua/ui/dialogs/score.lua')
    tabs.AddModeText("<LOC _Score>", function()
        UIUtil.QuickDialog(GetFrame(0),
            "<LOC EXITDLG_0003>Are you sure you'd like to exit?",
            "<LOC _Yes>", function() score.CreateDialog(victory) end,
            "<LOC _No>", nil,
            nil, nil,
            true,
            {escapeButton = 2, enterButton = 1, worldCover = true})
    end)
end
