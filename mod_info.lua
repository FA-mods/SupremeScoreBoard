-- ####################################################################################################
name        = "Supreme Score Board v1.21"
-- ####################################################################################################
version     = 1.21
uid         = "HUSSAR-PL-a1e2-c4t4-scfa-ssbmod-v1210"
author      = "HUSSAR" -- http://forums.faforever.com/memberlist.php?mode=viewprofile&u=9827
copyright   = "HUSSAR, free to re-use code as long as you credit me in your mod"
description = "Improves score board and replays by adding more columns, team stats, players sorting, filtering units by type, kill/lose ratio, fixed UI updates lags! (HUSSAR)"
icon        = "/mods/SupremeScoreBoard/mod_icon.png"
url         = "http://forums.faforever.com/viewtopic.php?f=41&t=10887"
selectable  = true
enabled     = true
ui_only     = true
exclusive   = false
requiresNames = { }
requires    = { }
-- this mod will conflict with all mods that modify score.lua file:
conflicts   = { 
    "9B5F858A-163C-4AF1-B846-A884572E61A5", -- lazyshare
    "b0059a8c-d9ab-4c30-adcc-31c16580b59d", -- lazyshare v6
    "c31fafc0-8199-11dd-ad8b-0866200c9a68", -- coloured allies in score
    "b2cde810-15d0-4bfa-af66-ec2d6ecd561b", -- eco manager v3
    "ecbf6277-24e3-437a-b968-EcoManager-v4",
    "ecbf6277-24e3-437a-b968-EcoManager-v6",
    "ecbf6277-24e3-437a-b968-EcoManager-v5",
    "ecbf6277-24e3-437a-b968-EcoManager-v7",
    "0faf3333-1122-633s-ya-VX0000001000",   -- eco info - sharing among your team
    "89BF1572-9EA8-11DC-1313-635F56D89591", -- 
    "f8d8c95a-71e7-4978-921e-8765beb328e8", -- 
    "HUSSAR-PL-a1e2-c4t4-scfa-ssbmod-v1100",
    }
before = { }
after = { }

--------------------------------------------------------------------------------------
--[[ TODO
 add configuration window for hiding columns, changing font size, background opacity etc.
 add ping info about players (lua/modules/ui/game/connectivity.lua)
 show acu kills and mvp kill ratio  
 group players colors before selecting team color to avoid green team color if two green players are in two teams
 
--]] 
--------------------------------------------------------------------------------------
-- MOD HISTORY
--------------------------------------------------------------------------------------
--[[ v1.2 BY HUSSAR - January, 2016
--------------------------------------------------------------------------------------
NEW FEATURES:
--------------------------------------------------------------------------------------
- (all sessions) added replay ID below map info line
- (all sessions) added calculation of game quality/balance if this value is not present in session options
- (game session) added buttons for sharing mass/energy/units with allied human players (faster than LazyShare) 
- (game session) added buttons for sharing mass/energy/units with allied AI players 
- (game session) added chat notifications for transferred amount of mass/energy to allied players
- (game session) added chat notifications for transferred number of units to allied players
- (game session) added separator lines between players' lines and teams' lines in game session 
- (replay session) changed reclaim column to show reclaim values (works with latest FAF beta patch)
- (replay session) added auto-hiding multifunction panel because it is not used in replays at all
- (replay session) added auto-switching between score columns (e.g. units types air|land|naval)
- (replay session) clicking on a column toggle will disable auto-switching columns 
--------------------------------------------------------------------------------------
FIXES:
--------------------------------------------------------------------------------------
- fixed coloring of player names when they are not in teams (e.g. Phantom games)
- fixed coloring of player names in replay session
- fixed information in tooltips 
- fixed conditions for checking ranked games
- fixed teams statistics by including score data for dead players  
- fixed team status that shows how many players are still alive
- fixed detection of dead players in sandbox games
- fixed placement of icons in the sort line
- fixed alignment of top line with its background
- fixed very long map names by truncating them to 30 chars
- changed background of the score board to darker color (better visibility of player names)
- changed units column to show air/land/navy/all instead of cumulative values, e.g. air + navy
- changed ranking column to show exact values in ladder games and rounded values in regular games
- changed coloring of player names and now they will match color of team
- changed column with player names to include clan tags (if they exist)
--]]
--------------------------------------------------------------------------------------
--[[ v1.1 BY HUSSAR - October 5, 2015
--------------------------------------------------------------------------------------
- fixed info about active mods in replay session
- fixed status of game raking
- fixed tooltip about game quality/balance
- added coloring of player names based on team color 
- thanks to testers: Petricpwnz, Anihilnine
--]]
--------------------------------------------------------------------------------------
--[[ v1.0 BY HUSSAR - September 25, 2015
--------------------------------------------------------------------------------------
FEATURES:
--------------------------------------------------------------------------------------
- added team lines that sums up statistics for allied players
- added column with filters to show count of air/land/navy/base units  
- added column for total mass of collected/killed/lost
- added column for players rating to prevent clipping by score values
- added toggle to show and sort players by their army rating
- added toggle to show and sort players by total mass collected
- added toggle to show and sort players by total mass reclaimed*
- added toggle to show and sort players by total energy reclaimed*
- added toggle to show and sort players by total energy collected
- added toggle to show and sort players by their clan tags
- added toggle to show and sort players by Kills-to-Loses Ratio
- added toggle to show and sort players by Kills-to-Built Ratio
- added toggle to sort players by current mass income
- added toggle to sort players by current energy income
- added toggle to sort players by current score value
- added toggle to sort players by their army name
- added toggle to sort players by their clan tag
- added toggle to sort players by their team id
- added sorting by two columns when value in the first sorting are equal, e.g. sorting by team ID and then by mass income
- added team status showing alive/maximum players 
- added rendering players names with red/green when in players view to show allies/enemies 
- added calculation of AI rating based on AI type and AI cheat modifiers
- added field showing game quality based on network connection between players
- added tooltips for all new UI elements in the score panel
- added info about map size
- added icons with improved quality for mass, energy, units
- added icons with info about game restrictions
- added icons with info about active mods
- added icons with info about unit sharing
- added icons with info about victory conditions
- added icons with info about AI multipliers
- added notifications about 1st experimental unit built by a player
- changed game time/speed fields into two fields   
- changed unit counter to show unit count of all armies (in observer view) or just player's units (in player view) 

*Pending FAF patch that will actually add reclaim values to score data and thus enable them to show in score panel 

--------------------------------------------------------------------------------------
FIXES:
--------------------------------------------------------------------------------------
- fixed missing tooltip for game speed slider
- fixed performance in updating score panel by limiting number of for loops (n*n-times to n-times)
- fixed issues with performing operations on uninitialized values of score data
- fixed redundant function calls to GetArmiesTable().armiesTable
- fixed redundant function calls to GetFocusArmy()
- fixed redundant function calls to SessionIsReplay()
- fixed redundant function calls to SessionGetScenarioInfo()
- fixed redundant imports of some LUA scripts (e.g. announcement.LUA)
--]]
--------------------------------------------------------------------------------------
--[[ TEST NOTES:
-- maps big:    Seton's Clutch, The Dark Heart, Seraphim Glaciers, Twin Rivers
-- maps small:  Balvery Mountains Diversity
-- players:     Lainelas, Blackheart, Blackdeath, Foley, BRNKoINSANITY 
-- ai           Neptune, EntropicVoid on The Dark Heart
-- max teams    Fractal Cancer, Seraphim Glaciers, White Fire 
-- clans        SGI Nequilich e VoR
                
logs line =  line# in this file + # of lines in original score.LUA (620) 630
--]]  
--------------------------------------------------------------------------------------