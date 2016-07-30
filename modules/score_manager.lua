 -- ##########################################################################################
--  File:    /LUA/modules/score_manager.lua
--  Author:  HUSSAR
--  Summary: Provides additional info about score, armies, teams and other data
--  Copyright © 2016 HUSSAR All rights reserved.
-- ##########################################################################################
--  NOTE: Contact HUSSAR, in case you are trying to 
--        implement/port this mod to latest version of FAF patch
-- http://forums.faforever.com/forums/memberlist.php?mode=viewprofile&u=9827
-- ##########################################################################################
 
local modPath = '/mods/SupremeScoreBoard/'
local modTextures = modPath..'textures/'
local modScripts  = modPath..'modules/'
local modInfo  = import(modPath..'mod_info.lua')
 
-- import local modules
local tab  = import(modScripts..'ext.tables.lua')
local str  = import(modScripts..'ext.strings.lua')
local num  = import(modScripts..'ext.numbers.lua')
local log  = import(modScripts..'ext.logging.lua') 

-- import game modules
local UIUtil        = import('/lua/ui/uiutil.lua')
local GameMain      = import('/lua/ui/game/gamemain.lua') 
local Announcement  = import('/lua/ui/game/announcement.lua')
local FindClients   = import('/lua/ui/game/chat.lua').FindClients 
local Prefs         = import('/lua/user/prefs.lua')

-- session info should not changed during the game so getting it just once
local sessionReplay  = SessionIsReplay()    
local sessionInfo    = SessionGetScenarioInfo()   
local sessionOptions = sessionInfo.Options

local scoreData = {}
function SetScoreData(newData)
    --LOG('SSB SetScoreData=' .. table.getsize(newData))
    scoreData = newData --table.deepcopy(newData)
end

function GetScoreData()
    return scoreData
end
 
function GetInfoForAI()
    local ai = {}
    -- activate AI when there is at least one AI player
    ai.active = false
    ai.cheat = {}
    ai.cheat.income = tonumber(sessionInfo.Options.CheatMult) or 0
    ai.cheat.build  = tonumber(sessionInfo.Options.BuildMult) or 0
    ai.cheat.omni = sessionInfo.Options.OmniCheat
   
    ai.info = {}
    ai.info.income = string.format("x%1.1f", ai.cheat.income)
    ai.info.build  = string.format("x%1.1f", ai.cheat.build)
    ai.info.omni   = (ai.cheat.omni and 'ON' or 'OFF')
         
    return ai
end
-- gets army's name using its army index
function GetArmyName(armyIndex)
    local armyName = ''
    local armies = GetArmiesTable().armiesTable
    for armyID,army in armies do
        if armyID == armyIndex then
           armyName = army.nickname
           break
        end
    end 
    return armyName
end
-- gets army's index using its army name
function GetArmyIndex(armyName)
    local armies = GetArmiesTable().armiesTable
    for armyID,army in armies do
        if army.nickname == armyName then
           return armyID
        end
    end 
    return 1
end
-- gets army's clan name using its army name
function GetArmyClan(armyName) 
    local clans = sessionOptions.ClanTags 
    if (clans == nil) then return "" end
    local tag = sessionOptions.ClanTags[armyName]
    if (tag == nil or tag == "") then return "" end
    return "["..tag.."] " 
end


local AI = GetInfoForAI()

-- gets army's rating using its army index or AI type/multipliers
function GetArmyRating(armyIndex)
    local armyName = GetArmyName(armyIndex)
    local rating = {}
    rating.actual = sessionOptions.Ratings[armyName]
    if (rating.actual == nil or string.find(armyName,"%(AI")) then
        rating.base = 0
        -- AI Base Rating
            if (string.find(armyName,"AIx")) then rating.base = 500 
        elseif (string.find(armyName,"AI"))  then rating.base = 100
        end   
        -- AI Specialization Bonus
            if (string.find(armyName,"Adaptive"))then rating.base = rating.base + 250 
        elseif (string.find(armyName,"Tech"))    then rating.base = rating.base + 250
        elseif (string.find(armyName,"Air"))     then rating.base = rating.base + 250
        elseif (string.find(armyName,"Water"))   then rating.base = rating.base + 200
        elseif (string.find(armyName,"Random"))  then rating.base = rating.base + 200
        elseif (string.find(armyName,"Rush"))    then rating.base = rating.base + 100
        elseif (string.find(armyName,"Turtle"))  then rating.base = rating.base +  50
        elseif (string.find(armyName,"Normal"))  then rating.base = rating.base +  25
        end 
        -- AI Sorian Bonus
        if (string.find(armyName,"Sorian"))      then rating.base = rating.base + 250  
        end   
       
        --TODO include AI omni setting in rating calculation
        
        -- AI multipliers Bonus as product of percentage of AI base rating and
        -- ratio of current AI multipliers and maximum AI multipliers
        rating.cheat = rating.base * 0.9 * (AI.cheat.income / 6.0) 
        rating.build = rating.base * 1.1 * (AI.cheat.build  / 6.0) 
        --log.Trace('rating = '..rating.base.."+"..rating.build.."+"..rating.cheat)
        
        -- AI actual rating as sum of AI base rating plus build and cheat ratings
        rating.actual = rating.base + rating.build + rating.cheat                      
        -- Maximum possible rating (3000) will have AIx Sorian Adaptive (1000) 
        -- with maximum build (6.0) and cheat (6.0) multipliers
        -- rating.cheat   = 1000 * 0.9 * (6.0 / 6.0) =  900     
        -- rating.build   = 1000 * 1.1 * (6.0 / 6.0) = 1100   
        -- rating.actual  = 1000 + 900 + 1100        = 3000   
    end
    
    -- round ratings in non-ladder games
    if not sessionOptions.Ranked then
        rating.rounded = num.round100(rating.actual)
    end
    
    return rating
end
-- Gets HD icons for specified faction ID or defaults to standard icons if faction not found
function GetArmyIcon(factionID)
        if (factionID == 0)  then return modTextures..'faction_uef.dds'    
    elseif (factionID == 1)  then return modTextures..'faction_aeon.dds'
    elseif (factionID == 2)  then return modTextures..'faction_cybran.dds'
    elseif (factionID == 3)  then return modTextures..'faction_seraphim.dds'
    elseif (factionID == 4)  then return modTextures..'faction_nomad.dds'
    elseif (factionID == -1) then return modTextures..'faction_observer.dds'
    elseif (factionID == -2) then return modTextures..'faction_team.dds'
    else -- default to standard faction icons                    
        return UIUtil.UIFile(UIUtil.GetArmyIcon(factionID))
    end
end

function GetArmyTableKills()
    local kills = {}
    -- kills in units' value
    kills.mass  = 0
    kills.engy  = 0
    -- kills in units' count
    kills.acu   = 0
    kills.air   = 0
    kills.exp   = 0
    kills.navy  = 0
    kills.land  = 0
    kills.base  = 0
    kills.count = 0
    -- hold temp. ACU kills
    kills.tmp   = 0
    
    return kills
end
function GetArmyTableLoses()
    local loses = {}
    -- loses in units' value
    loses.mass = 0
    loses.engy = 0
    -- loses in units' count
    loses.acu   = 0
    loses.air   = 0
    loses.exp   = 0
    loses.navy  = 0
    loses.land  = 0
    loses.base  = 0
    loses.count = 0
    -- hold temp. ACU loses
    loses.tmp   = 0
    
    return loses
end
function GetArmyTableUnits()
    local units = {}
    -- units built by value
    units.mass  = 0
    units.engy  = 0
    -- units by type
    units.acu   = 0
    units.air   = 0
    units.exp   = 0
    units.navy  = 0
    units.land  = 0
    units.base  = 0
    -- units counter
    units.total = 0
    units.cap   = 0 
    
    return units
end
function GetArmyTableEco()
    local eco = {}
    eco.massIncome  = 0
    eco.massTotal   = 0
    eco.massSpent   = 0
    eco.massReclaim = 0
     
    eco.engyIncome  = 0
    eco.engyTotal   = 0
    eco.engySpent   = 0
    eco.engyReclaim = 0

    eco.buildPowerUsed  = 0
    eco.buildPowerTotal = 0
    return eco
end
function GetArmyTableRatio()
    local ratio = {}
    ratio.killsToBuilt = 0  
    ratio.killsToLoses = 0  
    ratio.builtToLoses = 0  
    return ratio
end

-- Gets replay ID for the current game session 
-- NOTE not using UIUtil.GetReplayId() because some games (e.g. BlackOps) don't 
-- have this function and this version is much cleaner
function GetReplayId()
    local id = nil
    --log.Table(GetFrontEndData(''), 'GetFrontEndData')
    local syncID = GetFrontEndData('syncreplayid')
    if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") and syncID ~= nil and syncID ~= 0 then
        id = syncID
        log.Trace('GetReplayId()... from cmd /syncreplay ' .. tostring(id) )

    elseif HasCommandLineArg("/savereplay") then
        local url = GetCommandLineArg("/savereplay", 1)[1]
        local lastpos = string.find(url, "/", 20)
        id = string.sub(url, 20, lastpos-1)
        log.Trace('GetReplayId()... from cmd /savereplay ' .. tostring(id) )

    elseif HasCommandLineArg("/replayid") then
        id =  GetCommandLineArg("/replayid", 1)[1]
        log.Trace('GetReplayId()... from cmd /replayid ' .. tostring(id) )
    end
    return id
end