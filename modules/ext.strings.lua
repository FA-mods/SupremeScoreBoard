      
--[[
TODO:
-  add localize strings
-  add logic for loading strings based on local of the game
--]]


local modPath = '/mods/SupremeScoreBoard/'
local modTextures = modPath..'textures/'
local modScripts  = modPath..'modules/'
local log  = import(modScripts..'ext.logging.lua')

locals = {}
function initalize()
    local columnActions = '\n \n to show column - Left Click'.. 
                          '\n to sort column - Right Click'
    locals['game_timer'] = 'Game Time'
    locals['game_timer_info'] = 'Elapsed game time or no rush timer'
    locals['game_quality'] = 'Game Balance'
    locals['game_quality_info'] = 'Game balance based on rating of players in teams \n >90% - good balance \n <90% - poor balance'
    locals['game_speed'] = 'Game Speed'
    locals['game_speed_info'] = 'Game speed set by an observer vs actual game speed'
    locals['game_speed_slider'] = 'Game Speed Slider'
    locals['game_speed_slider_info'] = 'Allows an observer to adjust game speed'
    
    locals['game_ranked'] = 'Game Ranking'
    locals['game_ranked_ladder'] = 'This game applies to Ladder Ranking but it will not affect your Global Ranking'
    locals['game_ranked_info'] = 'This game applies to Global FAF Ranking if all these conditions are met:'  
    locals['game_ranked_HasNoAI'] = ' no AI players' 
    locals['game_ranked_HasNoCheating'] = ' no cheating enabled' 
    locals['game_ranked_HasNoRushOff'] = ' no rush disabled'  
    locals['game_ranked_HasNoRestrictions'] = ' no unit restrictions'  
    locals['game_ranked_HasNoPrebuilt'] = ' no prebuilt units'  
    locals['game_ranked_HasNoSimMods'] = ' no sim mods'  
    locals['game_ranked_HasLockedTeams'] = ' locked teams'   
    locals['game_ranked_HasAssassination'] = ' assassination victory'  
    locals['game_ranked_HasShareUnits'] = ' sharing units until death'  
    locals['game_ranked_HasShareCaps'] = ' sharing cap with no one'  
    locals['game_ranked_HasNormalSpeed'] = ' normal speed'  
    locals['game_ranked_HasLowTimeouts'] = ' three timeouts' 
    locals['game_ranked_HasFogOfWar'] = ' fog of war explored' 
        
    locals['game_mods'] = 'Mods Sim/UI'
    locals['game_id']       = 'Replay ID'
    locals['game_id_info']  = 'This is current replay identifier from the FAF vault'
    locals['game_ver']      = 'SUI Version'
    locals['game_ver_info'] = 'This is current version of Supreme User Interface mod \n aka Supreme Score Board mod'

    -- diplomacy
    locals['share_units'] = 'Share Your Units '  
    locals['share_units_info'] = 'Transfer ownership of your units to this player. \n ' ..
    'LeftClick - selected units \n' ..
    'LeftClick+Shift - all units \n' ..
    'RightClick - request engineer \n \n' ..
    'Note that units will not be transferred if the player has reached units capacity'  
    locals['share_mass'] = 'Share Your Mass '  
    locals['share_mass_info'] = 'Transfer stored mass to this player. \n ' ..
    'LeftClick - sent 50% \n' ..
    'LeftClick+Shift - sent 100% \n' ..
    'RightClick - request mass\n \n' ..
    'Note that surplus of the transferred mass will be returned to you if the player has already full mass storage  '  
    locals['share_engy'] = 'Share Your Energy '  
    locals['share_engy_info'] = 'Transfer stored energy to this player. \n ' ..
    'LeftClick - sent 50% \n' ..
    'LeftClick+Shift - sent 100% \n' ..
    'RightClick - request energy\n \n' ..
    'Note that surplus of the transferred energy will be returned to you if the player has already full energy storage  ' 
    
    locals['units_count'] = 'Units Count'
    locals['units_count_info'] = 'Current and maximum units count. Observer will see cumulative units stats for all players. Switch to player\'s view to see unit count for that player'
    
    locals['team'] = 'TEAM'

    -- sort columns
    locals['army_teams'] = 'Faction/Team ID'
    locals['army_teams_info'] = 'This column shows army faction and team number' .. '\n \n to sort column - Right Click'
    locals['army_rating'] = 'Army Rating'
    locals['army_rating_info'] = 'This column shows army rating' .. '\n \n to sort column - Right Click'
    locals['army_nameshort'] = 'Army Name'
    locals['army_nameshort_info'] = 'This column shows army names and team colors of all armies' .. '\n \n to sort column - Right Click'
    locals['army_namefull'] = 'Army Name and Clan'
    locals['army_namefull_info'] = 'This column shows army names and team colors of all armies' .. '\n \n to sort column - Right Click'
    locals['army_score'] = 'Army Score'
    locals['army_score_info'] = 'This column shows Score points that are calculated by weighting resource produced and unit kills, loses, and built'.. columnActions
    locals['army_status'] = 'Army Status'
    locals['army_status_info'] = 'This column shows Status of armies' .. '\n \n to sort column - Right Click'
        
    locals['ratio.killsToBuilt'] = 'Kills/Built Ratio'
    locals['ratio.killsToBuilt_info'] = 'Show kills-to-built ratio that is calculated using total cost of units killed by total cost of units built. ' ..
        'This ratio tells how much a player is killing vs. how much spending on units and eco upgrades' ..
        '\n Ratio > 0.25 (Pro) ' .. 
        '\n Ratio ~ 0.15 (Average) ' .. 
        '\n Ratio < 0.05 (Bad)'
    locals['ratio.killsToLoses'] = 'Kills/Loses Ratio'
    locals['ratio.killsToLoses_info'] = 'Show kills-to-loses ratio that is calculated using total cost of units killed by total cost of units lost. ' ..
        'This ratio tells how much a player is aggressive and how well is using his units to kill enemy units' ..
        '\n Ratio > 2.0 (Pro) ' .. 
        '\n Ratio ~ 1.0 (Average) ' .. 
        '\n Ratio < 0.5 (Bad)'
          
    locals['eco.massIncome'] = 'Mass Income'
    locals['eco.massIncome_info'] = 'This column shows current Mass Income from mass extractors and RAS upgrades' .. columnActions
    locals['eco.massTotal'] = 'Mass Total'
    locals['eco.massTotal_info'] = 'This column shows current Mass Total collected by extractors and reclaimed' .. columnActions
    locals['eco.massProduced'] = 'Mass Produced'
    locals['eco.massProduced_info'] = 'This column shows Mass Produced (excluding Reclaim)' .. columnActions
    locals['eco.massReclaim'] = 'Mass Reclaim'
    locals['eco.massReclaim_info'] = 'This column shows current Mass Reclaimed by engineers. ' .. columnActions
    locals['eco.engyIncome'] = 'Energy Income'
    locals['eco.engyIncome_info'] = 'This column shows current Energy Income from power generators and RAS upgrades' .. columnActions
    locals['eco.engyTotal'] = 'Energy Total'
    locals['eco.engyTotal_info'] = 'This column shows current Energy Total collected by generators and reclaimed' .. columnActions
    locals['eco.engyProduced'] = 'Energy Produced'
    locals['eco.engyProduced_info'] = 'This column shows Energy Produced (excluding Reclaim)' .. columnActions
    locals['eco.engyReclaim'] = 'Energy Reclaim'
    locals['eco.engyReclaim_info'] = 'This column shows current Energy Reclaimed by engineers. ' .. columnActions
   
    locals['kills.mass'] = 'Total Mass in Units Killed'
    locals['kills.mass_info'] = 'This column shows total Mass cost of Killed Units' .. columnActions
    locals['loses.mass'] = 'Total Mass in Units Lost'
    locals['loses.mass_info'] = 'This column shows total Mass cost of Lost Units' .. columnActions
    
    locals['units.air'] = 'Air Units'
    locals['units.air_info'] = 'This column shows current count of Air Units.   '.. columnActions
    locals['units.land'] = 'Land Units'
    locals['units.land_info'] = 'This column shows current count of Land Units.   '.. columnActions
    locals['units.navy'] = 'Naval Units'
    locals['units.navy_info'] = 'This column shows current count of Naval Units.   '.. columnActions
    locals['units.total'] = 'All Units'
    locals['units.total_info'] = 'This column shows current count of All Units types.  '.. columnActions
    
    -- Victory Conditions
    locals['vc_unknown'] = 'VC UKNOWN'
    locals['vc_unknown_info'] = 'Game has unknown victory condition'
    locals['vc_demoralization'] = 'Assassination'
    locals['vc_demoralization_info'] = 'Game ends when you assassinate all enemy ACU units'
    locals['vc_domination'] = 'Supremacy'
    locals['vc_domination_info'] = 'Game ends when you kill all enemy structures and engineers'
    locals['vc_eradication'] = 'Annihilation'
    locals['vc_eradication_info'] = 'Game ends when you kill all enemy structures and units'
    locals['vc_sandbox'] = 'Sandbox'
    locals['vc_sandbox_info'] = 'Game never ends'
    --Unit Restrictions
    locals['ur'] = 'Unit Restrictions'
    locals['ur_NONE'] = 'None'
    -- Share Unit Cap
    locals['suc_none']   = 'Sharing cap with none'  
    locals['suc_all']    = 'Sharing cap with all'  
    locals['suc_allies'] = 'Sharing cap with allies'  
    -- Share Conditions
    locals['sc']          = 'Share Conditions'
    locals['sc_no']       = 'Sharing units after death (Full Share)'
    locals['sc_no_info']  = 'You can give units to your allies and they will not be destroyed when you die'
    locals['sc_yes']      = 'Sharing units until death'
    locals['sc_yes_info'] = 'All the units you gave to your allies will be destroyed when you die'
    -- AI Conditions    
    locals['ai_info']   = 'AI Status'
    locals['ai_omni']   = 'Omni:   '
    locals['ai_build']  = 'Build:  '
    locals['ai_income'] = 'Income: '
    locals['ai_vision'] = 'Vision: '
      
end

initalize()

function loc(key)
    local text = locals[key]
    if text == nil then
       text = 'MISSING LOC ' .. key .. '' 
       log.Warning(text)
    end
    return text
end

-- get tooltip for pre-defined key 
function tooltip(key, textAppend, bodyAppend)
    textAppend = textAppend or ''
    bodyAppend = bodyAppend or ''
    return { text = loc(key)..textAppend, body = loc(key..'_info')..bodyAppend }
end 

-- change case of a string value to lower if it exists  
function lower(value)
    if value == nil then return '' end
    return string.lower(value)
end 
-- change case of a string value to upper if it exists  
function upper(value)
    if value == nil then return '' end
    return string.upper(value)
end 
  
function subs(str, strStart, strStops)
    --LOG('>>>> HUSSAR: GetStringFrom= ' .. str)
    if (str and strStart and strStops) then
        local start = string.find(str, strStart)
        local stops = string.find(str, strStops)
        if (start and start >= 0 and 
            stops and stops >= 0) then
            local ret = string.sub(str, start+1, stops-1) 
            --LOG('>>>> HUSSAR: GetStringFrom= ' .. ret)
            return ret
        end
    end
    return nil
end
 
function split(str, delimiter)
    --LOG('split'..' = '..str)
    local result = { }
    local from = 1
    local delim_from, delim_to = string.find( str, delimiter, from  )
    while delim_from do
        item = string.sub( str, from , delim_from-1 )
        --LOG('split '..'='..item)
        table.insert( result, item)
        from = delim_to + 1
        delim_from, delim_to = string.find( str, delimiter, from  )
    end
    item = string.sub( str, from  )
    --LOG('split '..'='..item)
    table.insert( result, item )
    return result
end
  