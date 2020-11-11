local modPath = '/mods/SupremeScoreBoard/'
local modTextures = modPath..'textures/'
local modScripts  = modPath..'modules/'

local ScoreBoard = import(modScripts..'score_board.lua') 
local Diplomacy  = import(modScripts..'diplomacy.lua')
local log  = import(modScripts..'ext.logging.lua')

function SetOptions(key,value,startup) 
    local before = ScoreBoard.GameOptions[key]

    ScoreBoard.GameOptions[key] = value
    Diplomacy.GameOptions[key] = value
     
    local after = ScoreBoard.GameOptions[key]

    if key == 'SSB_SortBy_Column' then
       ScoreBoard.SortArmyLinesBy(value)
    end
    log.Trace('options changed: [' .. key .. ']  '  .. tostring(before) .. ' -> ' .. tostring(after) )
end
function GetBooleanStates()
    return {
        states = {
            {help = "", text = "<LOC _On>",  key = true },
            {help = "", text = "<LOC _Off>", key = false },
        },
    }
end
function GetColumnStates()
    return {
       states = {
           {help = "", key = 'teamID', text = "[T] Team Number" },
           {help = "", key = 'score',  text = "[S] Score Points" },
           {help = "", key = 'ratio.killsToLoses', text = "[K] Kills Ratio" },
           {help = "", key = 'nameshort',      text = "[N] Player Names" },
           {help = "", key = 'rating.rounded', text = "[R] Player Rating" },
           {help = "", key = 'eco.massIncome', text = "[M] Mass Income" },
           {help = "", key = 'eco.massTotal',  text = "[M] Mass Total" },
           {help = "", key = 'eco.massReclaim',text = "[M] Mass Reclaim" },
           {help = "", key = 'eco.engyIncome', text = "[E] Energy Income" },
           {help = "", key = 'eco.engyTotal',  text = "[E] Energy Total" },
           {help = "", key = 'eco.engyReclaim',text = "[E] Energy Reclaim" },
           {help = "", key = 'units.total',    text = "[U] Units Total" },
       },
    }
end

-- SSB Auto-Toggle options
table.insert(options.ui.items,
    {
        tip     = "Specify how quickly auto-toggle values in all columns \n \n Replay Session only",
        title   = "SSB Auto-Toggle Interval (sec)", 
        key     = 'SSB_Auto_Toggle_Interval',
        type    = 'slider',
        default = 10,
        custom  = { min = 2, max = 20, inc = 1, },
        set     = SetOptions,
    })
table.insert(options.ui.items,
    {
        tip     = "Specify whether or not auto-toggle the Score Column between: \n score points and kills ratio \n \n Replay Session only",
        title   = "SSB Auto-Toggle Score Column", 
        key     = 'SSB_Auto_Toggle_Score_Column',
        type    = 'toggle',
        default = true,
        custom  = GetBooleanStates(),
        set     = SetOptions,
    })
table.insert(options.ui.items,
    {
        tip     = "Specify whether or not auto-toggle the Mass Column between: \n income, reclaim, and total \n \n Replay Session only",
        title   = "SSB Auto-Toggle Mass Column", 
        key     = 'SSB_Auto_Toggle_Mass_Column',
        type    = 'toggle',
        default = true,
        custom  = GetBooleanStates(),
        set     = SetOptions,
    })
table.insert(options.ui.items,
    {
        tip     = "Specify whether or not auto-toggle the Energy Column between: \n income, reclaim, and total \n \n Replay Session only",
        title   = "SSB Auto-Toggle Energy Column", 
        key     = 'SSB_Auto_Toggle_Engy_Column',
        type    = 'toggle',
        default = true,
        custom  = GetBooleanStates(),
        set     = SetOptions,
    })
table.insert(options.ui.items,
    {
        tip     = "Specify whether or not auto-toggle the Total Column between: \n mass total and kills total \n \n Replay Session only",
        title   = "SSB Auto-Toggle Total Column", 
        key     = 'SSB_Auto_Toggle_Total_Column',
        type    = 'toggle',
        default = true,
        custom  = GetBooleanStates(),
        set     = SetOptions,
    })
table.insert(options.ui.items,
    {
        tip     = "Specify whether or not auto-toggle the Units Column between: \n total of all, land, naval, and air units \n \n Replay Session only",
        title   = "SSB Auto-Toggle Units Column", 
        key     = 'SSB_Auto_Toggle_Units_Column',
        type    = 'toggle',
        default = true,
        custom  = GetBooleanStates(),
        set     = SetOptions,
    }) 
-- SSB Sorting options
table.insert(options.ui.items,
    {
        tip     = "Specify default column that will be used for sorting armies and teams \n \n Replay Session only",
        title   = "SSB Sort Armies By Column", 
        key     = 'SSB_SortBy_Column',
        type    = 'toggle',
        default = 'teamID',
        custom  = GetColumnStates(),
        set     = SetOptions,
    }) 
-- SSB Notifications options
table.insert(options.ui.items,
    {
        tip     = "Specify how many notifications are displayed for built T4 units from each player \n \n Replay Session only",
        title   = "SSB Show Notifications for Built T4 Units", 
        key     = 'SSB_NotifyThresholdFor_BuiltT4',
        type    = 'slider',
        default = 5,
        custom  = { min = 0, max = 10, inc = 1, },
        set     = SetOptions,
    })
-- SSB diplomacy options
table.insert(options.ui.items,
    {
        tip     = "Specify whether or not send message to allies when sharing Units \n \n Game Session only",
        title   = "SSB Send Messages When Sharing Units", 
        key     = 'SSB_MessageWhen_SharingUnits',
        type    = 'toggle',
        default = true,
        custom  = GetBooleanStates(),
        set     = SetOptions,
    })
table.insert(options.ui.items,
    {
        tip     = "Specify whether or not send message to allies when sharing Mass resources \n \n Game Session only",
        title   = "SSB Send Messages When Sharing Mass", 
        key     = 'SSB_MessageWhen_SharingMass',
        type    = 'toggle',
        default = true,
        custom  = GetBooleanStates(),
        set     = SetOptions,
    })
table.insert(options.ui.items,
    {
        tip     = "Specify whether or not send message to allies when sharing Energy resources \n \n Game Session only",
        title   = "SSB Send Messages When Sharing Energy", 
        key     = 'SSB_MessageWhen_SharingEngy',
        type    = 'toggle',
        default = false,
        custom  = GetBooleanStates(),
        set     = SetOptions,
    }) 
    
-- SSB Ping options
table.insert(options.ui.items,
    {
        title = "SSB Ping: Shows Player's Name",
        key = 'SSB_Ping_Name',
        type = 'toggle',
        default = true,
        custom = {
            states = {
                {text = "On", key = true },
                {text = "Off", key = false },
            },
        },
    })

table.insert(options.ui.items,
    {
        title = "SSB Ping: Font Color",
        key = 'SSB_Ping_Color',
        type = 'toggle',
        default = 'ping',
        custom = {
            states = {
                { text = "White",     key = 'white' },
                { text = "Army color", key = 'army' },
                { text = "Ping color", key = 'ping' },
            },
        },
    })

table.insert(options.ui.items,
    {
        title = "SSB Ping: Font Size",
        key = 'SSB_Ping_Size',
        type = 'slider',
        default = 14,
        custom = {
            min = 10,
            max = 30,
            inc = 0,
        },
    })

table.insert(options.ui.items,
    {
        title = "SSB Ping: Additional time",
        key = 'SSB_Ping_Time',
        type = 'slider',
        default = 0,
        custom = {
            min = 0,
            max = 20,
            inc = 0,
        },
    })
