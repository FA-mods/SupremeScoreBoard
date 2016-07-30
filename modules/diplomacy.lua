 -- ##########################################################################################
--  File:    /LUA/modules/diplomacy.lua
--  Author:  HUSSAR
--  Summary: Provides functions for sending and requesting resources and units from allied players
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

local FindClients = import('/lua/ui/game/chat.lua').FindClients

local armiesData = GetArmiesTable().armiesTable  
 
GameOptions = import(modPath .. 'modules/options.lua').GetOptions(true)

 -- check of current army can share resources/units with specified target 
function CanShare(armySender, armyTarget)
    -- handle invalid army IDs
    if armySender <= 0 or armyTarget <= 0 then
       return false
    elseif armySender == armyTarget then 
       return false -- cannot share with yourself
    else 
       return IsAlly(armySender, armyTarget)
    end
end
--- send message to allies from specified army
function SendMessage(msgText, msgFrom)
    msg = { to = 'allies', Chat = true, text = msgText }
    if msgFrom then
       msg.from = msgFrom
    end
    SessionSendChatMessage(FindClients(), msg)
end
-- shares resources of current army with specified target army if they are allies
function SendResource(armyTarget, mass, energy)
    local armySender = GetFocusArmy()
    if not CanShare(armySender, armyTarget) then return end
    -- convert from percentage to double
    mass = (mass or 0) / 100.0
    energy = (energy or 0) / 100.0
    local econData = GetEconomyTotals()
    local sentAmount = 0
    local sentResource = ''
    local showNotification = true
    if mass > 0 then 
        --TODO find a way to calculate actual delta 
        --sentAmount = (ecoBefore.stored.MASS or 0) - (ecoAfter.stored.MASS or 0)
        sentAmount = (econData.stored.MASS or 0) * mass
        sentResource = num.frmt(sentAmount) .. ' mass'  
        showNotification = GameOptions['SSB_MessageWhen_SharingMass'] 
    elseif energy > 0 then 
        --sentAmount = (ecoBefore.stored.ENERGY or 0) - (ecoAfter.stored.ENERGY or 0)
        sentAmount = (econData.stored.ENERGY or 0) * energy
        sentResource = num.frmt(sentAmount)  .. ' energy'  
        showNotification = GameOptions['SSB_MessageWhen_SharingEngy'] 
    end
    if sentAmount > 1 then        
        local target = armiesData[armyTarget].nickname  
        local sender = armiesData[armySender].nickname  
        --local target = Stats.armies[armyTarget].nickname 
        --local sender = Stats.armies[armySender].nickname 
        if showNotification  then
           SendMessage('sent ' .. sentResource .. ' to ' .. target, sender) 
        end

        SimCallback( { Func = "GiveResourcesToPlayer",
                   Args = { From = armySender, To = armyTarget, 
                   Mass = mass, Energy = energy, }} )
    end
end
--- shares selected units of current army with specified target army if they are allies
function SendUnits(armyTarget, allUnits)
    local armySender = GetFocusArmy()
    if not CanShare(armySender, armyTarget) then return end
    
    if allUnits then
        UISelectionByCategory("ALLUNITS", false, false, false, false)
    end

    local selection = GetSelectedUnits()
    if not selection then return end

    local units = 0  
    for i,bp in selection do
       if not bp:IsInCategory("COMMAND") then
            units = units + 1
        end
    end
    -- transfer selected units
    SimCallback( { Func = "GiveUnitsToPlayer", 
                   Args = { From = armySender, To = armyTarget }, }, true)
    if units > 0 and GameOptions['SSB_MessageWhen_SharingUnits']  then 
        local armyName = armiesData[armyTarget].nickname  
        --local armyName = Stats.armies[armyTarget].nickname  
        local msg = 'sent ' .. units
        if units == 1 then 
            msg = msg ..' unit to ' .. armyName
        else 
            msg = msg ..' units to ' .. armyName
        end 
        SendMessage(msg) 
    end 
end
function RequestUnits(armyTarget)
    local armySender = GetFocusArmy()
    if not CanShare(armySender, armyTarget) then return end

    local armyName = armiesData[armyTarget].nickname
    msg = { to = 'allies', Chat = true }
    msg.text =  'Can you give me one Engineer, ' .. armyName .. '?'

    SessionSendChatMessage(FindClients(), msg)
end
function RequestResource(armyTarget, resource)
    local armySender = GetFocusArmy()
    if not CanShare(armySender, armyTarget) then return end
     
    local armyName = armiesData[armyTarget].nickname
    msg = { to = 'allies', Chat = true }
    msg.text = 'Can you give me some ' .. resource .. ', ' .. armyName .. '?' 
    --msg.echo = true
    SessionSendChatMessage(FindClients(), msg)
end
