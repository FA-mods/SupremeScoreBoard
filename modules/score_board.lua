-- ##########################################################################################
--  File:    /LUA/modules/UI/game/score.lua
--  Author:  Chris Blackwell, HUSSAR
--  Summary: Supreme Score Board in Game/Replay Sessions (see mod_info.lua for details)
--  Copyright © 2005 Gas Powered Games, Inc. All rights reserved.
-- ##########################################################################################
--  NOTE:    Contact HUSSAR, in case you are trying to 
--           implement/port this mod to latest version of FAF patch
-- http://forums.faforever.com/forums/memberlist.php?mode=viewprofile&u=9827
-- ##########################################################################################
-- current score will contain the most recent score update from the sync
--currentScores = false   -- 861
 
 -- USE A:\Users\Husar\Desktop\TMP\textures\ui\common\game\replay slider-ticks_bmp.dds

local modPath = '/mods/SupremeScoreBoard/' 
local modScripts  = modPath..'modules/'
local modTextures = modPath..'textures/'
local modInfo  = import(modPath..'mod_info.lua')

-- import local modules
local tab  = import(modScripts..'ext.tables.lua')
local str  = import(modScripts..'ext.strings.lua')
local num  = import(modScripts..'ext.numbers.lua')
local log  = import(modScripts..'ext.logging.lua') 
local ScoreMng  = import(modScripts..'score_manager.lua')
local Diplomacy = import(modScripts..'diplomacy.lua')

local Mods = import('/lua/mods.lua')

local Announcement  = import(modScripts..'announcement.lua') 
local FindClients   = import('/lua/ui/game/chat.lua').FindClients
local UIUtil        = import('/lua/ui/uiutil.lua')
local GameMain      = import('/lua/ui/game/gamemain.lua')
local Tooltip       = import('/lua/ui/game/tooltip.lua') 
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group         = import('/lua/maui/group.lua').Group
--local Bitmap        = import('/lua/maui/bitmap.lua').Bitmap
--local Checkbox      = import('/lua/maui/checkbox.lua').Checkbox
local Bitmap        = import(modScripts..'bitmap.lua').Bitmap
local Checkbox      = import(modScripts..'checkbox.lua').Checkbox
local Text          = import('/lua/maui/text.lua').Text
local Grid          = import('/lua/maui/grid.lua').Grid
local Slider        = import('/lua/maui/slider.lua').IntegerSlider
local Prefs         = import('/lua/user/prefs.lua')

--------------------------------------------------------------------------
-- Configuration Section
--------------------------------------------------------------------------
controls = {}
savedParent = false
local observerLine = false

-- session info should not changed during the game so getting it just once
local sessionReplay  = SessionIsReplay()    
local sessionInfo    = SessionGetScenarioInfo()   
local sessionOptions = sessionInfo.Options
  
-- added Stats to store info about players' armies and aggregated armies (teams)
Stats = {}
-- stores info about active score columns, e.g. eco.massIncome, units.Total
Columns = {}
GameOptions = import(modPath .. 'modules/options.lua').GetOptions(true)

log.IsEnabled = true        

local lastUnitWarning = false
local unitWarningUsed = false
local issuedNoRushWarning = false
local gameSpeed = 0
local needExpand = false
local contractOnCreate = false

local alliesInfoShowStorage = false
local alliesInfo = false

-- added configuration variables 
local boardMargin = 20
local boardWidth = 270  -- original 262
local sw = 55           -- string width for displaying value in grid columns
local iconSize = 15     -- original 14
local lineSize = iconSize + 1
local teamNumber = 1

local fontDigital   = "Zeroes Three" 
local fontMono      = "Courier New"
local fontMonoBold  = "Courier New Bold"
local fontName      = "Arial"    -- fontMono --UIUtil.bodyFont
local fontNameBold  = "Arial Bold"    
local fontSize      = 12    -- original 12

local showRoundRating = true -- false -> actual rating (not rounded)

local textColorRating   = 'ffffffff'
local textColorNickname = 'FFC1BFBF'
local textColorScore    = 'ffffffff'
local textColorMass     = 'ffb7e75f'
local textColorEngy     = 'fff7c70f'
local textColorUnits    = 'ffcfced0'
local textColorKills    = 'ffff2600'
local textColorLoses    = 'ffa0a0a0'

local armyColorDefeted  = 'ffa0a0a0'  
local armyColorAllied   = 'ff9afc98'   
local armyColorEnemy    = 'fffcb4ab'
local armyColorObserver = 'FFC3C3C3'
  
local cid = 1
-- TODO find a way to load army colors from the game instead of hard-coding them here    
-- this table is used for matching bright text color with color of an army and
-- order of colors in this table determines priority for selecting team colors
local Colors = { }
Colors[cid] = {armyColor = 'ff40bf40', textColor = 'ff40bf40'} cid=cid+1 --#ff40bf40 #ff40bf40  mid green
Colors[cid] = {armyColor = 'fffafa00', textColor = 'ffffff42'} cid=cid+1 --#fffafa00 #ffffff42  new yellow
Colors[cid] = {armyColor = 'ff9161ff', textColor = 'FFA946F4'} cid=cid+1 --#ff9161ff #FFA946F4  purple
Colors[cid] = {armyColor = 'ffe80a0a', textColor = 'FFF73C3C'} cid=cid+1 --#ffe80a0a #FFF73C3C  Cybran red ff3f15
Colors[cid] = {armyColor = 'ff436eee', textColor = 'FF6184EF'} cid=cid+1 --#ff436eee #FF6184EF  new blue 
Colors[cid] = {armyColor = 'ffffffff', textColor = 'ffffffff'} cid=cid+1 --#ffffffff #ffffffff  white
Colors[cid] = {armyColor = 'ffff32ff', textColor = 'ffff32ff'} cid=cid+1 --#ffff32ff #ffff32ff  fuschia pink
Colors[cid] = {armyColor = 'ffff873e', textColor = 'FFF17224'} cid=cid+1 --#ffff873e #FFF17224  orange (Nomads)
Colors[cid] = {armyColor = 'ff66ffcc', textColor = 'ff66ffcc'} cid=cid+1 --#ff66ffcc #ff66ffcc  aqua

Colors[cid] = {armyColor = 'ff76a101', textColor = 'ff76a101'} cid=cid+1 --#ff76a101 #ff76a101  Order Green (old)
Colors[cid] = {armyColor = 'ff9fd802', textColor = 'ff9fd802'} cid=cid+1 --#ff9fd802 #ff9fd802  Order Green (new)
Colors[cid] = {armyColor = 'ffffbf80', textColor = 'ffffbf80'} cid=cid+1 --#ffffbf80 #ffffbf80  light orange
Colors[cid] = {armyColor = 'ff2e8b57', textColor = 'ff3db874'} cid=cid+1 --#ff2e8b57 #ff3db874  dark new green
Colors[cid] = {armyColor = 'ffff88ff', textColor = 'ffff88ff'} cid=cid+1 --#ffff88ff #ffff88ff  light pink
Colors[cid] = {armyColor = 'ffb76518', textColor = 'ffe17d22'} cid=cid+1 --#ffb76518 #ffe17d22  new brown
Colors[cid] = {armyColor = 'ffa79602', textColor = 'ffa79602'} cid=cid+1 --#ffa79602 #ffa79602  Sera golden
Colors[cid] = {armyColor = 'ff901427', textColor = 'FFCB2D44'} cid=cid+1 --#ff901427 #FFCB2D44  dark red 
Colors[cid] = {armyColor = 'ff5f01a7', textColor = 'FF8C38CB'} cid=cid+1 --#ff5f01a7 #FF8C38CB  dark purple
Colors[cid] = {armyColor = 'ff2f4f4f', textColor = 'FF549090'} cid=cid+1 --#ff2f4f4f #FF549090  dark green (olive)
Colors[cid] = {armyColor = 'ff616d7e', textColor = 'ff99a3b0'} cid=cid+1 --#ff616d7e #ff99a3b0  gray
Colors[cid] = {armyColor = 'ff616d7e', textColor = 'ff99a3b0'} cid=cid+1 --#ff616d7e #ff99a3b0  gray
Colors[cid] = {armyColor = 'ff131cd3', textColor = 'FF4848DC'} cid=cid+1 --#ff131cd3 #FF4848DC  dark UEF blue (old)
Colors[cid] = {armyColor = 'FF2929e1', textColor = 'FF4848DC'} cid=cid+1 --#FF2929e1 #FF4848DC  dark UEF blue (new)

--WARN('SSB color fix Colors=' .. table.getsize(Colors))


-- initializes Stats to store info about players' armies and aggregated armies (teams)
function InitializeStats()
      
    log.Trace('InitializeStats()... '  )

    Stats.units  = ScoreMng.GetArmyTableUnits() 
    Stats.armies = {} --GetArmiesTable().armiesTable
    Stats.teams  = {}
    Stats.teamsIDs = {}
    Stats.teamsActive = false 
    Stats.teamsCount = 1
    
    Stats.map = GetMapData(sessionInfo) 
    Stats.ai  = ScoreMng.GetInfoForAI()
    
    local armies = GetArmiesTable().armiesTable
    -- table.print(armies, 'armiesTable')
    --log.Table(sessionInfo, 'sessionInfo') 
    --log.Table(__active_mods, 'active_mods')
    --log.Table(allArmies, 'armies') 
    
    -- first, collect info about all players
    for id,army in armies do 
        if (army.civilian) then 
            army.type = "civilian"  
        else --if (army.human) then
            army.type = "player"   
        end
        log.Trace('InitializeStats()... armyID='..id..', type='..army.type..', name='..army.nickname)
        if not army.civilian and army.showScore then 
            if army.human then
                army.nameshort = army.nickname
                army.namefull  = ScoreMng.GetArmyClan(army.nickname)..army.nickname 
            else
                army.nameshort = str.subs(army.nickname, "%(", "%)") or army.nickname
                army.namefull  = army.nameshort ..' ('.. str.subs(' '..army.nickname, " ", " %(") ..')'
                --army.namefull  = army.nickname
                Stats.ai.active = true
            end 
            army.icon = ScoreMng.GetArmyIcon(army.faction)
            --log.Table(army, 'army') 
            army.armyID = id
            army.eco    = ScoreMng.GetArmyTableEco()
            army.kills  = ScoreMng.GetArmyTableKills()
            army.loses  = ScoreMng.GetArmyTableLoses()
            army.units  = ScoreMng.GetArmyTableUnits()
            army.ratio  = ScoreMng.GetArmyTableRatio()
            army.rating = ScoreMng.GetArmyRating(id)
              
            army.announcements = {}
            army.announcements.exp   = 0
            army.announcements.arty  = 0
            army.announcements.nukes = 0
            army.announcements.tele  = 0
            army.announcements.acu   = 0
            
            Stats.armies[id] = army
        end
    end
    log.Trace('InitializeStats()... armies created'  )
    
    local teams = {}
    local teamsIDs = {}

    for id, army in Stats.armies do 
        if not army.civilian and army.showScore then
            local team = CreateTeam(id, armies) 
            local teamID = 0
            local teamName = ''
            -- save team if it does not exist yet
            if (teamsIDs[team.key] ~= nil) then
                teamID = teamsIDs[team.key]
                team   = teams[teamID] 
            else
                -- use negative id for teams
                teamID = Stats.teamsCount * -1
                log.Trace('InitializeStats()... saving team='..teamID..' size='..team.members.count)

                teams[teamID] = team
                teamsIDs[team.key] = teamID
                Stats.teamsCount = Stats.teamsCount + 1
                -- save team info for each player's army
                for _, armyID in team.members.ids do
                    Stats.armies[armyID].txtColor = team.txtColor or 'FFFFFF' --#FFFFFF
                end
            end
        end
    end
    log.Trace('InitializeStats()... teams created'  )
    
    Stats.armiesCount = table.getn(Stats.armies)
    Stats.teamsCount  = Stats.teamsCount - 1  
    -- activate teams only if we have at least one team with more than 1 player
    -- otherwise, it is redundant to show Stats about teams with just one player in a team
    -- because army lines will show this information 
    Stats.teamsActive = Stats.teamsCount ~= Stats.armiesCount and Stats.teamsCount > 1 
    
    local isActive = (Stats.teamsActive and "true" or "false")
    log.Trace('InitializeStats()... teamsActive = '..isActive..', teamsCount = '..Stats.teamsCount..', armiesCount = '..Stats.armiesCount)
    if Stats.teamsActive then
        if not sessionOptions.Quality then
            local min = 10000
            local max = 0
            for i,team in teams do
                min = math.min(min, team.rating.actual) 
                max = math.max(max, team.rating.actual) 
            end
            sessionOptions.Quality = min / max * 100
        end
        -- sort and store teams by their starting quadrant/location on the map
        local sortedTeams = table.sorted( table.values(teams), sort_by 'quadrant')
        for index, team in sortedTeams do 
            -- use negative id for teams so they are always below armies in UI
            local id = index * -1
            team.armyID = id 
            team.number = index
            team.nickname = str.loc('team') .. ' ' .. team.number 
            team.nameshort = team.nickname .. team.status 
            team.namefull  = team.nickname .. team.status 

            Stats.teams[id] = team
            Stats.teamsIDs[team.key] = id 

            -- save team info for each player's army
            for _, armyID in team.members.ids do
                Stats.armies[armyID].teamName = team.nickname 
                Stats.armies[armyID].teamID   = id
            end
        end
    end
    --table.print(Stats.armies[1], 'Stats.armies')
    
    --log.Table(GameOptions, 'GameOptions')
    --Settings.Share = {} [''] = 50
    --Notify.Send. = {} 
    --Settings.Share
    -- GameOptions['Send_Notifications_Shared_Mass'] 

    --SSB Send Notifications for Shared Mass  
    --SSB Send Notifications for Shared Energy  
    --SSB Send Notifications for Shared Units 
     
    Stats.sortByColumnNew = GameOptions['SSB_SortBy_Column'] 
    if not Stats.sortByColumnNew then
        Stats.sortByColumnNew = 'teamID'
        Stats.sortByColumnOld = 'score'

    elseif Stats.sortByColumnNew == 'score' then
        Stats.sortByColumnOld = 'teamID'

    elseif Stats.sortByColumnNew == 'teamID' then
        Stats.sortByColumnOld = 'score'
    end
    --Stats.sortByColumnOld = 'score'   --'armyID'                
    --Stats.sortByColumnNew = 'teamID'  -- Stats.teamsActive and 'eco.massTotal' or 'score' 

    Columns.Exists = {}
    Columns.Name = {}
    Columns.Name.Index   = 1
    Columns.Name.Current = 'nameshort'
      
    Columns.Rating = {}
    Columns.Rating.Index  = 1
    Columns.Rating.Active = 'rating.actual'
    Columns.Rating.Keys   = { 'rating.actual', 'rating.rounded' }

    Columns.Score = {}
    Columns.Score.Index   = 1
    Columns.Score.Active  = 'score'
    Columns.Score.Keys    = { 'score', 'ratio.killsToLoses'} --, 'ratio.killsToBuilt'} 
     
    Columns.Mass = {}
    Columns.Mass.Index    = 1
    Columns.Mass.Active   = 'eco.massIncome'
    Columns.Mass.Keys     = { 'eco.massIncome', 'eco.massReclaim'} --, 'eco.massTotal'}
    
    Columns.Engy = {}
    Columns.Engy.Index    = 1
    Columns.Engy.Active   = 'eco.engyIncome'
    Columns.Engy.Keys     = { 'eco.engyIncome', 'eco.engyReclaim'}  
     
    Columns.Units = {}
    Columns.Units.Index   = 1
    Columns.Units.Active  = 'units.total'
    Columns.Units.Keys    = { 'units.total', 'units.land', 'units.air', 'units.navy' }
    
    Columns.Total = {}
    Columns.Total.Index   = 1
    Columns.Total.Active  = 'eco.massTotal'
    Columns.Total.Keys    = { 'eco.massTotal', 'kills.mass' }
     
end

-- Create UI  
function CreateScoreUI(parent)
    savedParent = GetFrame(0)
    
    controls.bg = Group(savedParent)
    controls.bg.Depth:Set(10)
    
    controls.collapseArrow = Checkbox(savedParent)
    controls.collapseArrow.OnCheck = function(self, checked)
        ToggleScoreControl(not checked)
    end
    Tooltip.AddCheckboxTooltip(controls.collapseArrow, 'score_collapse')
    
    controls.bgTop = Bitmap(controls.bg)
    controls.bgBottom = Bitmap(controls.bg)
    controls.bgStretch = Bitmap(controls.bg)
    controls.armyGroup = Group(controls.bg)
    
    -- HUSSAR: increased board width to show more columns
    if sessionReplay then
        boardWidth = 415 --340 -- 380  
    else 
        boardWidth = boardWidth + 90  --280
    end    
    LayoutHelpers.SetWidth(controls.bgTop, boardWidth + boardMargin)
    LayoutHelpers.SetWidth(controls.bgBottom, boardWidth + boardMargin)
    LayoutHelpers.SetWidth(controls.bgStretch, boardWidth + boardMargin)
    
    controls.leftBracketMin = Bitmap(controls.bg)
    controls.leftBracketMax = Bitmap(controls.bg)
    controls.leftBracketMid = Bitmap(controls.bg)
    
    controls.rightBracketMin = Bitmap(controls.bg)
    controls.rightBracketMax = Bitmap(controls.bg)
    controls.rightBracketMid = Bitmap(controls.bg)
    
    controls.leftBracketMin:DisableHitTest()
    controls.leftBracketMax:DisableHitTest()
    controls.leftBracketMid:DisableHitTest()
    
    controls.rightBracketMin:DisableHitTest()
    controls.rightBracketMax:DisableHitTest()
    controls.rightBracketMid:DisableHitTest()
    
    controls.bg:DisableHitTest(true)
    controls.bgTop:DisableHitTest(true)
    controls.bgBottom:DisableHitTest(true)
    controls.bgStretch:DisableHitTest(true)
    
    SetupPlayerLines()
    
    controls.time = UIUtil.CreateText(controls.bgTop, '00:00:00', fontSize, fontMono)
    controls.time:SetColor('ff00dbff')
    controls.timeIcon = CreateInfoIcon(controls.bgTop, 'game_timer.dds')
    --controls.timeIcon:SetTexture(modTextures..'game_timer.dds')
    Tooltip.AddControlTooltip(controls.time, str.tooltip('game_timer'))
    Tooltip.AddControlTooltip(controls.timeIcon, str.tooltip('game_timer'))
    
    controls.speed = UIUtil.CreateText(controls.bgTop, '(+0/+0)', fontSize, fontMono)
    controls.speed:SetColor('ff00dbff')
    controls.speedIcon = CreateInfoIcon(controls.bgTop, 'game_speed.dds')
    --controls.speedIcon:SetTexture(modTextures..'game_speed.dds')
    Tooltip.AddControlTooltip(controls.speed, str.tooltip('game_speed'))
    Tooltip.AddControlTooltip(controls.speedIcon, str.tooltip('game_speed'))
    
    controls.quality = UIUtil.CreateText(controls.bgTop, '--%', fontSize, fontMono)
    controls.quality:SetColor('ff00dbff')
    controls.qualityIcon = CreateInfoIcon(controls.bgTop, 'game_quality.dds')
    --controls.qualityIcon:SetTexture(modTextures..'game_quality.dds')
    Tooltip.AddControlTooltip(controls.quality, str.tooltip('game_quality'))
    Tooltip.AddControlTooltip(controls.qualityIcon, str.tooltip('game_quality'))
    
    controls.units = UIUtil.CreateText(controls.bgTop, '0/0', fontSize, fontMono)
    controls.units:SetColor('ffff9900')
    controls.unitIcon = CreateInfoIcon(controls.bgTop, 'units.total.dds')
    LayoutHelpers.SetHeight(controls.unitIcon, iconSize-3)
    --controls.unitIcon:SetTexture(modTextures..'units.total.dds')
    Tooltip.AddControlTooltip(controls.units, str.tooltip('units_count'))
    Tooltip.AddControlTooltip(controls.unitIcon, str.tooltip('units_count'))
        
    SetLayout()
    
    LayoutHelpers.SetHeight(controls.timeIcon, iconSize)
    LayoutHelpers.SetHeight(controls.speedIcon, iconSize)
    LayoutHelpers.SetHeight(controls.qualityIcon, iconSize)
    LayoutHelpers.SetHeight(controls.unitIcon, iconSize)
    LayoutHelpers.SetDimensions(controls.unitIcon, iconSize-3, iconSize)
    
    --controls.timeIcon.Height:Set(iconSize)
    --controls.timeIcon.Width:Set(iconSize)
    
    --controls.speedIcon.Height:Set(iconSize)
    --controls.speedIcon.Width:Set(iconSize)
    
    --controls.qualityIcon.Height:Set(iconSize)
    --controls.qualityIcon.Width:Set(iconSize)
    
    --controls.unitIcon.Height:Set(iconSize-3)
    --controls.unitIcon.Width:Set(iconSize)
       
    GameMain.AddBeatFunction(_OnBeat, true)
    controls.bg.OnDestroy = function(self)
        GameMain.RemoveBeatFunction(_OnBeat)
    end
    
    if contractOnCreate then
        Contract()
    end
    
    controls.bg:SetNeedsFrameUpdate(true)
    controls.bg.OnFrame = function(self, delta)
        local newRight = self.Right() + (1000*delta)
        if newRight > savedParent.Right() + self.Width() then
            newRight = savedParent.Right() + self.Width()
            self:Hide()
            self:SetNeedsFrameUpdate(false)
        end
        self.Right:Set(newRight)
    end
    --controls.collapseArrow:SetCheck(true, true)
    controls.collapseArrow:SetCheck(false, false)
    
end

function SetLayout()
    if controls.bg then
        --TODO FAF replace
        import(modScripts..'score_mini.lua').SetLayout()
        --import(UIUtil.GetLayoutFilename('score')).SetLayout()
    end
end

function SetupPlayerLines()
    
    InitializeStats()
    
    local index = 1 -- counter of player/team lines
     
    if not controls.armyLines then 
       controls.armyLines = {}
    end

    controls.armyLines[index] = CreateSortLine(100)  
    index = index + 1 
     
    -- army lines always above team lines (armyId between 1 and 12+)
    for armyID, army in Stats.armies do
        if not army.civilian and army.showScore then 
            controls.armyLines[index] = CreateArmyLine(armyID, army)
            index = index + 1 
        end
    end

    if not sessionReplay then
        controls.armyLines[index] = CreateSeparatorLine(0) 
        index = index + 1 
    end

    -- team lines are always below army lines (armyID between -1 and -12)
    if Stats.teamsActive then 
        for teamID, team in Stats.teams do
            if (team.key == nil or team.armyID == nil) then
                log.Warning('SetupPlayerLines cannot find team: '..teamID) 
            else 
                controls.armyLines[index] = CreateArmyLine(team.armyID, team) 
                index = index + 1 
            end
        end
    end
  
    -- create observer's controls
    if sessionReplay then
        local observer = {}
        observer.armyID = 0 -- will be between army lines (+IDs) and team lines (-IDs) 
        observer.type = 'observer'
        observer.faction = -1
        observer.icon = ScoreMng.GetArmyIcon(observer.faction)
        observer.color = 'FFFFFFFF'
        observer.txtColor = armyColorObserver
        observer.nickname = ' ' .. string.upper(LOC("<LOC score_0003>Observer"))
        observer.nameshort = observer.nickname
        observer.namefull  = observer.nickname
        
        observerLine = CreateArmyLine(observer.armyID, observer)
        observerLine.isObsLine = true
        observerLine.nameColumn.Top:Set(observerLine.Top)
        LayoutHelpers.SetHeight(observerLine, iconSize * 3)
        observerLine.speedText = UIUtil.CreateText(controls.bgStretch, '', 15, UIUtil.bodyFont)
        observerLine.speedText:SetColor('ff00dbff')
        LayoutHelpers.AtRightIn(observerLine.speedText, observerLine, 5)
        observerLine.speedSlider = Slider(controls.bgStretch, false, -10, 10, 1, 
            UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'), 
            UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'), 
            UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'), 
            UIUtil.SkinnableFile('/dialogs/options/slider-back_bmp.dds'))
        observerLine.speedSlider.Left:Set(function() return observerLine.Left() + 10 end)
        observerLine.speedSlider.Right:Set(function() return observerLine.Right() - 25 end)
        observerLine.speedSlider.Bottom:Set(function() return observerLine.Bottom() - 5 end)
        observerLine.speedSlider._background.Left:Set(observerLine.speedSlider.Left)
        observerLine.speedSlider._background.Right:Set(observerLine.speedSlider.Right)
        observerLine.speedSlider._background.Top:Set(observerLine.speedSlider.Top)
        observerLine.speedSlider._background.Bottom:Set(observerLine.speedSlider.Bottom) 
        observerLine.speedSlider._thumb.Depth:Set(function() return observerLine.Depth() + 5 end)
        observerLine.speedSlider._background.Depth:Set(function() return observerLine.speedSlider._thumb.Depth() - 1 end)
        observerLine.speedSlider.OnValueChanged = function(self, newValue)
            observerLine.speedText:SetText(string.format("%+d", math.floor(tostring(newValue))))
        end
        observerLine.speedSlider.OnValueSet = function(self, newValue)
            ConExecute("WLD_GameSpeed "..newValue)
        end
        observerLine.speedSlider:SetValue(gameSpeed)
        observerLine.speedText:DisableHitTest()
    
        -- setting a new tooltip for game speed slider because "Lobby_Gen_GameSpeed" does not exist
        --Tooltip.AddControlTooltip(observerLine.speedSlider._thumb, 'Lobby_Gen_GameSpeed')
        Tooltip.AddControlTooltip(observerLine.speedSlider._thumb, str.tooltip('game_speed_slider'))
        Tooltip.AddControlTooltip(observerLine.speedSlider._background, str.tooltip('game_speed_slider'))

        LayoutHelpers.AtVerticalCenterIn(observerLine.speedText, observerLine.speedSlider)
        
        controls.armyLines[index] = observerLine 
        index = index + 1 
    end    
      
    --controls.armyLines[index] = CreateSeparatorLine(-100) 
    --index = index + 1 
        
    controls.armyLines[index] = CreateMapLine(-101)  
    controls.armyLines[index].isMapLine = true
    
    index = index + 1 
    controls.armyLines[index] = CreateInfoLine(-102)  
    controls.armyLines[index].isMapLine = true
    
end


function SetIconSize(icon)
    LayoutHelpers.SetDimensions(icon, iconSize, iconSize)
end
function CreateArmyLine(armyID, army)
    local group = Group(controls.bgStretch)
    
    log.Trace('CreateArmyLine()...  armyID = '..armyID..',   color = '..army.color..',   txtColor = '..tostring(army.txtColor)..', type='..army.type..', name = '..army.nickname)
    -- HUSSAR: created players' score board using these columns:
    -- --------+---------+--------+------+--------+------------+--------------+--------------------------+
    -- session | icon    | number | text | number | number     | number       | number    | number       |
    -- --------+---------+--------+------+--------+------------+--------------+--------------------------+
    -- Game    | faction | rating | name | score  |            |              |           |              |
    -- Replay  | faction | rating | name | score  | massIncome | energyIncome | massTotal | unitsCount   |
    -- --------+---------+--------+------+--------+------------+--------------+--------------------------+
    
    -- HUSSAR: re-arranged players' info that is shared between Game and Replay sessions so that it is defined only once  
    
    local position = 0 -- keep track of horizontal position of data columns
    -- players have positive index, teams have negative index, and zero is for observer
    local isPlayerArmy = army.type == 'player'  --armyID > 0
    local isTeamArmy = army.type == 'team'      --armyID < 0
    local isObserver = army.type == 'observer'  --armyID == 0
    local isSharing = Diplomacy.CanShare(GetFocusArmy(), armyID)
    
    local textColor = army.txtColor --textColorNickname
    --if isPlayerArmy then textColor = army.txtColor end
    --if isTeamArmy   then textColor = army.txtColor end
      
    group.isArmyLine = isPlayerArmy
    group.isTeamLine = isTeamArmy
    group.armyID = armyID
     
    group.faction = Bitmap(group)
    group.faction:SetTexture(army.icon) -- ScoreMng.GetArmyIcon(army.faction))    
    SetIconSize(group.faction)
    group.faction:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.faction, group, position)
    
    group.color = Bitmap(group.faction)
    group.color:SetSolidColor(army.color)
    group.color.Depth:Set(function() return group.faction.Depth() - 1 end)
    group.color:DisableHitTest()
    LayoutHelpers.FillParent(group.color, group.faction)
      
    position = position + iconSize + 1
    -- create rating data column
    if army.rating and (isPlayerArmy or isTeamArmy) then
        -- HUSSAR: added a new column to:
        -- show players' rating on the left side of players' names to make it more visible
        -- and prevents clipping players' ratings by score values
        local ratingValue = isPlayerArmy and army.rating.rounded or army.rating.actual
        --(showRoundRating and army.rating.rounded or army.rating.actual) 
        --if (isPlayerArmy) then ratingValue = army.rating.rounded and showRoundRating or army.rating.actual end
        --if (isTeamArmy) then ratingValue = army.rating.actual and showRoundRating end
        local ratingStr = string.format("%4.0f", ratingValue)
        group.rating = UIUtil.CreateText(group, ratingStr, fontSize, fontMono)
        group.rating:DisableHitTest()
        group.rating:SetColor(textColor)
        LayoutHelpers.AtLeftIn(group.rating, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.rating, group)
        position = position + sw - 18 -- offset for rating text 12
    end
            
    local armyName = army.namefull -- army.nameshort   
    
    group.nameColumn = UIUtil.CreateText(group, armyName, fontSize, fontName)
    group.nameColumn:DisableHitTest() 
    group.nameColumn:SetColor(textColor)
    LayoutHelpers.AtLeftIn(group.nameColumn, group, position)
    LayoutHelpers.AtVerticalCenterIn(group.nameColumn, group)
    
    if string.len(armyName) > 30 and not sessionReplay then
        armyName = string.sub(armyName, 1, 30) .. '...'
        group.nameColumn:SetText(armyName)
    end

    if isPlayerArmy and not sessionReplay then -- and isSharing 

        local tip = ''
        position = iconSize * 2   -- offset score column
        group.shareUnitsIcon = CreateInfoIcon(group, 'units.total.dds')
        --group.shareUnitsIcon:SetTexture(modTextures..'units.total.dds')
        LayoutHelpers.AtRightIn(group.shareUnitsIcon, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.shareUnitsIcon, group)        
        SetIconSize(group.shareUnitsIcon)
        group.shareUnitsIcon.armyID = armyID
        group.shareUnitsIcon.OnClick = function(self, eventModifiers)
            if eventModifiers.Right then 
                 Diplomacy.RequestUnits(self.armyID) 
             elseif eventModifiers.Shift then 
                 Diplomacy.SendUnits(self.armyID, true) -- share all units
             elseif not eventModifiers.Shift then 
                 Diplomacy.SendUnits(self.armyID, false) -- share selected units
             end         
        end 
        Tooltip.AddControlTooltip(group.shareUnitsIcon, str.tooltip('share_units'))
        
        position = position + iconSize + 5
        group.shareEngyIcon = CreateInfoIcon(group, 'eco.engyIncome.dds')
        --group.shareEngyIcon:SetTexture(modTextures..'eco.engyIncome.dds')
        LayoutHelpers.AtRightIn(group.shareEngyIcon, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.shareEngyIcon, group)
        SetIconSize(group.shareEngyIcon)
        group.shareEngyIcon.armyID = armyID
        group.shareEngyIcon.OnClick = function(self, eventModifiers)
            if eventModifiers.Right then 
                Diplomacy.RequestResource(self.armyID, 'energy')
            elseif eventModifiers.Shift then 
                Diplomacy.SendResource(self.armyID, 0, 100) -- Share 100% energy
            elseif not eventModifiers.Shift then 
                Diplomacy.SendResource(self.armyID, 0, 50) -- Share 50% energy
            end 
        end 
        Tooltip.AddControlTooltip(group.shareEngyIcon, str.tooltip('share_engy'))
        
        -- UI for showing allied players' energy stats
        position = position + iconSize + 3
        group.engyColumn = UIUtil.CreateText(group, '0', fontSize, fontName)
        group.engyColumn:DisableHitTest()
        group.engyColumn:SetColor(textColorEngy)
        LayoutHelpers.AtRightIn(group.engyColumn, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.engyColumn, group)

        position = position + 30
        group.shareMassIcon = CreateInfoIcon(group, 'eco.massIncome.dds')
        --group.shareMassIcon:SetTexture(modTextures..'eco.massIncome.dds')
        LayoutHelpers.AtRightIn(group.shareMassIcon, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.shareMassIcon, group)
        SetIconSize(group.shareMassIcon)
        group.shareMassIcon.armyID = armyID
        group.shareMassIcon.OnClick = function(self, eventModifiers)
            if eventModifiers.Right then 
                Diplomacy.RequestResource(self.armyID, 'mass')
            elseif eventModifiers.Shift then 
                Diplomacy.SendResource(self.armyID, 100, 0) -- Share 100% mass
            elseif not eventModifiers.Shift then 
                Diplomacy.SendResource(self.armyID, 50, 0) -- Share 50% mass
            end
        end
        Tooltip.AddControlTooltip(group.shareMassIcon, str.tooltip('share_mass'))

        -- UI for showing allied players' mass stats
        position = position + iconSize + 2
        group.massColumn = UIUtil.CreateText(group, '0', fontSize, fontName)
        group.massColumn:DisableHitTest()
        group.massColumn:SetColor(textColorMass)
        LayoutHelpers.AtRightIn(group.massColumn, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.massColumn, group)
    end

    -- create score data column
    if isPlayerArmy or isTeamArmy then
    
        group.scoreColumn = UIUtil.CreateText(group, '   ', fontSize, fontName)
        group.scoreColumn:DisableHitTest()
        group.scoreColumn:SetColor(textColorScore)
        
        if sessionReplay then
            -- offset player's score position in Replay session
            position = (sw * 4)  
            LayoutHelpers.AtRightIn(group.scoreColumn, group, position)
            LayoutHelpers.AtVerticalCenterIn(group.scoreColumn, group)
        else
            -- offset by 3 share icons in Game session 
            position = 0 --(iconSize + 3) * 3
            --LayoutHelpers.AtRightIn(group.scoreColumn, group)
            LayoutHelpers.AtRightIn(group.scoreColumn, group, position)
            LayoutHelpers.AtVerticalCenterIn(group.scoreColumn, group)
        end
        
        -- clip player's name by left of score value   
        group.nameColumn.Right:Set(group.scoreColumn.Left)
        --group.nameColumn.Right:Set(position - sw)
        group.nameColumn:SetClipToWidth(true)
    end
    
    -- TODO figure out if it is possible to ACCESS and show info about allied players in Sim mod!
    -- show more player's info only in Replay session 
    if ((isPlayerArmy or isTeamArmy) and sessionReplay) then
        
        -- show player's mass icon
        position = (sw * 3)
        group.massIcon = Bitmap(group)
        group.massIcon:SetTexture(modTextures..'eco.massIncome.dds')
        LayoutHelpers.AtRightIn(group.massIcon, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.massIcon, group)
        SetIconSize(group.massIcon)
        -- show player's mass column
        position = (sw * 3) + iconSize + 1
        group.massColumn = UIUtil.CreateText(group, '0', fontSize, fontName)
        group.massColumn:DisableHitTest()
        group.massColumn:SetColor(textColorMass)
        LayoutHelpers.AtRightIn(group.massColumn, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.massColumn, group)
        
        -- show player's energy icon
        position = (sw * 2) 
        group.engyIcon = Bitmap(group)
        group.engyIcon:SetTexture(modTextures..'eco.engyIncome.dds')
        LayoutHelpers.AtRightIn(group.engyIcon, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.engyIcon, group)
        SetIconSize(group.engyIcon)
        -- show player's energy column
        position = (sw * 2) + iconSize + 1
        group.engyColumn = UIUtil.CreateText(group, '0', fontSize, fontName)
        group.engyColumn:DisableHitTest()
        group.engyColumn:SetColor(textColorEngy)
        LayoutHelpers.AtRightIn(group.engyColumn, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.engyColumn, group)
            
        -- HUSSAR: added a new column to: 
        -- show total produced mass by a player since that is better indicator than just mass reclaim
        -- besides mass reclaim is not synchronized in score data and it cannot be synchronized in UI mods! 
        -- synchronization of mass reclaim in score data would require a change in AIBrain.lua (Game File)
        position = (sw * 1) 
        -- show player's mass total icon
        group.totalIcon = Bitmap(group)
        group.totalIcon:SetTexture(modTextures..'eco.massTotal.dds')
        LayoutHelpers.AtRightIn(group.totalIcon, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.totalIcon, group)        
        SetIconSize(group.totalIcon)
        -- show player's mass total value
        position = (sw * 1) + iconSize + 1
        group.totalColumn = UIUtil.CreateText(group, '0', fontSize, fontName)
        group.totalColumn:DisableHitTest()
        group.totalColumn:SetColor(textColorMass)
        LayoutHelpers.AtRightIn(group.totalColumn, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.totalColumn, group)
                
        -- HUSSAR: added a new column to:
        -- show total units owned by a player since that is good indicator of army strength 
        -- also observer does not have to switch army view to see unit count of a player
        position = (sw * 0) 
        -- show player's units total icon 
        group.unitIcon = Bitmap(group)
        group.unitIcon:SetTexture(modTextures..'units.total.dds')
        LayoutHelpers.AtRightIn(group.unitIcon, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.unitIcon, group)
        SetIconSize(group.unitIcon)
        -- show player's units total value 
        position = (sw * 0) + iconSize + 1
        group.unitColumn = UIUtil.CreateText(group, '0', fontSize, fontName)
        group.unitColumn:DisableHitTest()
        group.unitColumn:SetColor(textColorUnits)
        LayoutHelpers.AtRightIn(group.unitColumn, group, position)
        LayoutHelpers.AtVerticalCenterIn(group.unitColumn, group)
    end
     
    --local groupHeight = iconSize + 2
    --if (isObserver) then groupHeight = groupHeight + 10 end
        
    LayoutHelpers.SetDimensions(group, boardWidth, lineSize)
    
    -- enable switching view to players' armies or observer 
    if (isPlayerArmy or isObserver) and sessionReplay then
        group.bg = Bitmap(group)
        group.bg:SetSolidColor('00000000')
        group.bg.Height:Set(group.faction.Height)
        group.bg.Left:Set(group.faction.Right)
        group.bg.Right:Set(group.Right)
        group.bg.Top:Set(group.faction.Top)
        group.bg:DisableHitTest()
        group.bg.Depth:Set(group.Depth)
        group.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                group.bg:SetSolidColor('ff777777')
            elseif event.Type == 'MouseExit' then
                group.bg:SetSolidColor('00000000')
            elseif event.Type == 'ButtonPress' then
                ConExecute('SetFocusArmy '..tostring(self.armyID-1))
            end
        end
    else    
        group:DisableHitTest()
        group.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                alliesInfoShowStorage = true
                alliesInfo:SetText("Storage of Allies")
            elseif event.Type == 'MouseExit' then
                alliesInfoShowStorage = false
                alliesInfo:SetText("Income of Allies")
            end
        end
    end
    
    return group
end
 
function CreateSortBoxBase(group, column, customPath)
    local iconPath = customPath or modTextures .. column ..'.dds'
    local checkbox = Checkbox(group,
          iconPath, --'_btn_up.dds'),
          iconPath, --'_btn_over.dds'),
          iconPath, --'_over.dds'),
          iconPath, --'_over.dds'),
          iconPath, --'_btn_dis.dds'),
          iconPath, --'_btn_dis.dds'),
          'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
    
    LayoutHelpers.SetDimensions(checkbox, iconSize, iconSize)
    checkbox:UseAlphaHitTest(true) 
    checkbox:SetHighlight(true, 0.8, 1.0)
    
    return checkbox
end

function CreateSortBoxForEcoColumn(group, column, isMass)
    local checkbox = CreateSortBoxBase(group, column)

    checkbox.OnClick = function(self, eventModifiers)
        self:ToggleCheck()
        if isMass then
             Columns.Mass.Active = column
             GameOptions['SSB_Auto_Toggle_Mass_Column'] = false
        else
             Columns.Engy.Active = column 
             GameOptions['SSB_Auto_Toggle_Engy_Column'] = false
        end 
        if eventModifiers.Right then 
            SortArmyLinesBy(column)
        else
            UpdateArmyLines(column)
        end
    end
    
    return checkbox
end
function CreateSortBoxForUnitsColumn(group, column)
    local checkbox = CreateSortBoxBase(group, column)

    checkbox.OnClick = function(self, eventModifiers) 
        Columns.Units.Active = column 
        GameOptions['SSB_Auto_Toggle_Units_Column'] = false
        if eventModifiers.Right then 
            SortArmyLinesBy(column)
        else --if left click
            UpdateArmyLines(column)
        end
    end     
    return checkbox        
end
function CreateSortBoxForScoreColumn(group, column)
    local checkbox = CreateSortBoxBase(group, column)

    checkbox.OnClick = function(self, eventModifiers)
        Columns.Score.Active = column 
        GameOptions['SSB_Auto_Toggle_Score_Column'] = false
        if eventModifiers.Right then 
            SortArmyLinesBy(column)
        else --if left click
            UpdateArmyLines(column)
        end
    end
    return checkbox
end
function CreateSortBoxForRatingColumn(group, column)
    local checkbox = CreateSortBoxBase(group, column)

    checkbox.OnClick = function(self, eventModifiers)
        Columns.Rating.Active = column  
        if eventModifiers.Right then 
            SortArmyLinesBy(column)
        else --if left click
            UpdateArmyLines(column)
        end
    end
    return checkbox
end
function CreateSortBoxForNameColumn(group, column, icon)
    local checkbox = CreateSortBoxBase(group, column, modTextures..icon ..'.dds')

    checkbox.OnClick = function(self, eventModifiers)
        Columns.Name.Active = column  
        if eventModifiers.Right then 
            SortArmyLinesBy(column)
        else --if left click
            UpdateArmyLines(column)
        end
    end
    return checkbox
end
function CreateSortBoxForTotalColumn(group, column)
    local checkbox = CreateSortBoxBase(group, column)

    checkbox.OnClick = function(self, eventModifiers)
        Columns.Total.Active = column 
        GameOptions['SSB_Auto_Toggle_Total_Column'] = false
        if eventModifiers.Right then 
            SortArmyLinesBy(column)
        else --if left click
            UpdateArmyLines(column)
        end
    end
    return checkbox
end
function CreateSortBoxForGenericColumn(group, column, icon)
    local checkbox = CreateSortBoxBase(group, column, modTextures..icon ..'.dds')

    checkbox.OnClick = function(self, eventModifiers)
        SortArmyLinesBy(column) 
    end
    return checkbox
end
-- creates a line with toggles for sorting army/team lines by score, name, mass, energy, etc.
function CreateSortLine(armyID)
     
    log.Trace('CreateSortLine()...  armyID = '..armyID )
    local sortby = Group(controls.bgStretch)
    sortby:DisableHitTest(true)
    sortby.armyID = armyID 
    sortby.isSortLine = true
    sortby.isArmyLine = false
    sortby.isTeamLine = false
    
    -- keep track of horizontal position of data columns
    local position = 0 
    
    sortby.teamID = CreateSortBoxForGenericColumn(sortby, 'teamID', 'army_teams')
    LayoutHelpers.AtLeftIn(sortby.teamID, sortby, position)
    LayoutHelpers.AtVerticalCenterIn(sortby.teamID, sortby)
    Tooltip.AddControlTooltip(sortby.teamID, str.tooltip('army_teams'))
        
    position = position + iconSize + 8
    sortby.ratingR = CreateSortBoxForRatingColumn(sortby, 'rating.rounded')
    LayoutHelpers.AtLeftIn(sortby.ratingR, sortby, position)
    LayoutHelpers.AtVerticalCenterIn(sortby.ratingR, sortby)
    Tooltip.AddControlTooltip(sortby.ratingR, str.tooltip('army_rating'))

    position = position + iconSize + 15 --sw -- offset for rating text 
    sortby.nameshort = CreateSortBoxForNameColumn(sortby, 'namefull', 'army_namesfull')
    LayoutHelpers.AtLeftIn(sortby.nameshort, sortby, position)
    LayoutHelpers.AtVerticalCenterIn(sortby.nameshort, sortby)
    Tooltip.AddControlTooltip(sortby.nameshort, str.tooltip('army_namefull'))
     
    sortby.score = CreateSortBoxForScoreColumn(sortby, 'score')
    if sessionReplay then 
        position = (sw * 4)  
        LayoutHelpers.AtRightIn(sortby.score, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.score, sortby)
    else
        position = 0 --(iconSize + 3) * 3 -- offset by 3 share icons
        LayoutHelpers.AtRightIn(sortby.score, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.score, sortby)
         
        alliesInfo = UIUtil.CreateText(controls.bgTop, "Income of Allies", fontSize, fontName)
        alliesInfo:SetColor('ECECEC') -- #ECECEC
        LayoutHelpers.AtRightIn(alliesInfo, sortby, 50)
        LayoutHelpers.AtVerticalCenterIn(alliesInfo, sortby)
    end

    if sessionReplay or sessionOptions.Score ~= 'no' then
        Tooltip.AddControlTooltip(sortby.score, str.tooltip('army_score'))
    else
        Tooltip.AddControlTooltip(sortby.score, str.tooltip('army_status'))
    end
     
    -- show more player's info only in Replay session  
    if sessionReplay then 
     
        position = position + iconSize + 1
        sortby.killsToLoses = CreateSortBoxForScoreColumn(sortby, 'ratio.killsToLoses')
        LayoutHelpers.AtRightIn(sortby.killsToLoses, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.killsToLoses, sortby)
        Tooltip.AddControlTooltip(sortby.killsToLoses, str.tooltip('ratio.killsToLoses'))

        position = position + iconSize + 1
        sortby.killsToBuilt = CreateSortBoxForScoreColumn(sortby, 'ratio.killsToBuilt')
        LayoutHelpers.AtRightIn(sortby.killsToBuilt, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.killsToBuilt, sortby)
        Tooltip.AddControlTooltip(sortby.killsToBuilt, str.tooltip('ratio.killsToBuilt'))
        
        -- ================================================
        -- create sort boxes for mass column
        -- ================================================
        position = (sw * 3) 
        local massToggles = { 'massIncome', 'massReclaim'}
        sortby.massIncome = CreateSortBoxForEcoColumn(sortby,'eco.massIncome', true)
        LayoutHelpers.AtRightIn(sortby.massIncome, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.massIncome, sortby)
        Tooltip.AddControlTooltip(sortby.massIncome, str.tooltip('eco.massIncome'))
    
        position = position + iconSize + 1
        sortby.massReclaim = CreateSortBoxForEcoColumn(sortby,'eco.massReclaim', true)
        LayoutHelpers.AtRightIn(sortby.massReclaim, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.massReclaim, sortby)
        Tooltip.AddControlTooltip(sortby.massReclaim, str.tooltip('eco.massReclaim'))
   
        position = position + iconSize + 1
        sortby.massTotal = CreateSortBoxForEcoColumn(sortby,'eco.massTotal', true)
        LayoutHelpers.AtRightIn(sortby.massTotal, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.massTotal, sortby)
        Tooltip.AddControlTooltip(sortby.massTotal, str.tooltip('eco.massTotal'))
      
        -- ================================================
        -- create sort boxes for energy column
        -- ================================================
        position = (sw * 2) 
        sortby.engyIncome = CreateSortBoxForEcoColumn(sortby,'eco.engyIncome')
        LayoutHelpers.AtRightIn(sortby.engyIncome, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.engyIncome, sortby)
        Tooltip.AddControlTooltip(sortby.engyIncome, str.tooltip('eco.engyIncome'))
    
        position = position + iconSize + 1
        sortby.engyReclaim = CreateSortBoxForEcoColumn(sortby,'eco.engyReclaim')
        LayoutHelpers.AtRightIn(sortby.engyReclaim, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.engyReclaim, sortby)
        Tooltip.AddControlTooltip(sortby.engyReclaim, str.tooltip('eco.engyReclaim'))
    
        position = position + iconSize + 1
        sortby.engyTotal = CreateSortBoxForEcoColumn(sortby,'eco.engyTotal')
        LayoutHelpers.AtRightIn(sortby.engyTotal, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.engyTotal, sortby)
        Tooltip.AddControlTooltip(sortby.engyTotal, str.tooltip('eco.engyTotal'))
        
        -- ================================================
        -- create sort boxes for total column
        -- ================================================
        position = (sw * 1) 
        sortby.totalMass = CreateSortBoxForTotalColumn(sortby, 'eco.massTotal')
        LayoutHelpers.AtRightIn(sortby.totalMass, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.totalMass, sortby)
        Tooltip.AddControlTooltip(sortby.totalMass, str.tooltip('eco.massTotal'))
    
        position = position + iconSize + 1
        sortby.totalMassKills = CreateSortBoxForTotalColumn(sortby, 'kills.mass')
        LayoutHelpers.AtRightIn(sortby.totalMassKills, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.totalMassKills, sortby)
        Tooltip.AddControlTooltip(sortby.totalMassKills, str.tooltip('kills.mass'))
     
        position = position + iconSize + 1
        sortby.totalMassLoses = CreateSortBoxForTotalColumn(sortby, 'loses.mass')
        LayoutHelpers.AtRightIn(sortby.totalMassLoses, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.totalMassLoses, sortby)
        Tooltip.AddControlTooltip(sortby.totalMassLoses, str.tooltip('loses.mass'))

        -- HUSSAR: added a new column to:
        -- show total units owned by a player since that is good indicator of army strength 
        -- also observer does not have to switch army view to see unit count of a player
        -- ================================================
        -- create sort boxes for type of units column
        -- ================================================
        position = (sw * 0) 
        sortby.unitsNavy = CreateSortBoxForUnitsColumn(sortby,'units.total')
        LayoutHelpers.AtRightIn(sortby.unitsNavy, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.unitsNavy, sortby)
        Tooltip.AddControlTooltip(sortby.unitsNavy, str.tooltip('units.total'))
     
        position = position + iconSize - 3
        sortby.unitsAir = CreateSortBoxForUnitsColumn(sortby,'units.land')
        LayoutHelpers.AtRightIn(sortby.unitsAir, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.unitsAir, sortby)
        Tooltip.AddControlTooltip(sortby.unitsAir, str.tooltip('units.land'))
        
        position = position + iconSize - 4
        sortby.unitsLand = CreateSortBoxForUnitsColumn(sortby,'units.air')
        LayoutHelpers.AtRightIn(sortby.unitsLand, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.unitsLand, sortby)
        Tooltip.AddControlTooltip(sortby.unitsLand, str.tooltip('units.air'))
             
        position = position + iconSize - 3
        sortby.unitsNavy = CreateSortBoxForUnitsColumn(sortby,'units.navy')
        LayoutHelpers.AtRightIn(sortby.unitsNavy, sortby, position)
        LayoutHelpers.AtVerticalCenterIn(sortby.unitsNavy, sortby)
        Tooltip.AddControlTooltip(sortby.unitsNavy, str.tooltip('units.navy'))
     
        end 
     
    LayoutHelpers.SetDimensions(sortby, boardWidth, iconSize + 5)
    
    return sortby
end
function CreateSeparatorLine(armyID)
    local line = Group(controls.bgStretch)
    line:DisableHitTest(true)
    line.armyID = armyID
    line.isSortLine = true
    line.isArmyLine = false
    line.isTeamLine = false
    LayoutHelpers.SetDimensions(line, boardWidth, iconSize)
     
    line.bmp = Bitmap(line)
    line.bmp:SetTexture(modTextures..'score_seperator.dds')
    
    line.bmp:DisableHitTest(true)
    LayoutHelpers.SetDimensions(line.bmp, boardWidth, iconSize)
    --LayoutHelpers.AtHorizontalCenterIn(line.bmp, line)
    LayoutHelpers.AtRightIn(line.bmp, line)
    LayoutHelpers.AtVerticalCenterIn(line.bmp, line)
    return line   
end
function CreateMapLine(armyID)

    log.Trace('CreateMapLine()... ') 
    local group = Group(controls.bgStretch)    
    group.armyID = armyID
  
    local mapInfo = Stats.map.info 
     
    group.name = UIUtil.CreateText(group, mapInfo, fontSize, fontName)
    group.name:DisableHitTest()
    group.name:SetColor('ffffffff')
     
    LayoutHelpers.AtVerticalCenterIn(group.name, group, 1)
    LayoutHelpers.AtHorizontalCenterIn(group.name, group)
      
    LayoutHelpers.SetDimensions(group, boardWidth, lineSize + 2) 
    
    group:DisableHitTest()
    
    return group
end

-- store parameters for ranked games
local GameStatus = {}  

function CreateInfoLine(armyID)
    local logSource = 'CreateInfoLine()... '
    local group = Group(controls.bgStretch)
    group.armyID = armyID
     
    log.Trace(logSource)
        
    GameStatus.HasLockedTeams = str.lower(sessionOptions.TeamLock) == "locked"
    GameStatus.HasNoCheating = str.lower(sessionOptions.CheatsEnabled) == "false"
    GameStatus.HasNoPrebuilt = str.lower(sessionOptions.PrebuiltUnits) == "off"
    GameStatus.HasNoRushOff = str.lower(sessionOptions.NoRushOption) == "off"
    GameStatus.HasFogOfWar = str.lower(sessionOptions.FogOfWar) == "explored"
     
    if (not GameStatus.HasLockedTeams) then
        log.Trace(logSource..'game is not ranked because teams are unlocked')
    end 
    if (not GameStatus.HasNoCheating) then
        log.Trace(logSource..'game is not ranked because cheating is on')
    end 
    if (not GameStatus.HasNoPrebuilt) then
        log.Trace(logSource..'game is not ranked because prebuilt is on')
    end 
    if (not GameStatus.HasNoRushOff) then
        log.Trace(logSource..'game is not ranked because No Rush is on')
    end 
    if (not GameStatus.HasFogOfWar) then
        log.Trace(logSource..'game is not ranked because Fog of War is off')
    end 
    
    local position = 0
    local seperator = 4
    group.vc = CreateInfoIconVictory(group)
    LayoutHelpers.AtVerticalCenterIn(group.vc, group)
    LayoutHelpers.AtLeftIn(group.vc, group, position)
          
    position = position + iconSize + seperator
    group.sc = CreateInfoIconSharing(group)
    LayoutHelpers.AtVerticalCenterIn(group.sc, group)
    LayoutHelpers.AtLeftIn(group.sc, group, position)
           
    position = position + iconSize + seperator
    group.ur = CreateInfoIconRestrictions(group)
    LayoutHelpers.AtVerticalCenterIn(group.ur, group)
    LayoutHelpers.AtLeftIn(group.ur, group, position)
      
    position = position + iconSize + seperator
    group.mods = CreateInfoIconMods(group)
    LayoutHelpers.AtVerticalCenterIn(group.mods, group)
    LayoutHelpers.AtLeftIn(group.mods, group, position)
         
    position = position + iconSize + seperator
    group.ai = CreateInfoIconAI(group)
    LayoutHelpers.AtVerticalCenterIn(group.ai, group)
    LayoutHelpers.AtLeftIn(group.ai, group, position)
      
    position = position + iconSize + seperator
    group.rank = CreateInfoIconRanked(group)
    LayoutHelpers.AtVerticalCenterIn(group.rank, group)
    LayoutHelpers.AtLeftIn(group.rank, group, position)
         
    position = position + iconSize + seperator
    LayoutHelpers.SetDimensions(group, position, lineSize)
    group:DisableHitTest()
    
    local center = Group(controls.bgStretch)    
    center.armyID = armyID
    LayoutHelpers.SetDimensions(center, boardWidth, lineSize + 2)  
    center:DisableHitTest()
   
    LayoutHelpers.AtVerticalCenterIn(group, center)
    LayoutHelpers.AtHorizontalCenterIn(group, center)
             
    local replayID = ScoreMng.GetReplayId()
    if replayID then
        group.replayID = UIUtil.CreateText(center, ' ID: '..replayID, fontSize, fontName)
        --group.replayID:DisableHitTest()
        group.replayID:SetColor('FFC3C3C3') 
        LayoutHelpers.AtVerticalCenterIn(group.replayID, center)
        LayoutHelpers.AtLeftIn(group.replayID, center)
        Tooltip.AddControlTooltip(group.replayID, str.tooltip('game_id'))
    end    
    
    if modInfo.version and modInfo.author then
        local info = 'SSB' .. string.format(" v%01.1f ", modInfo.version)
        group.version = UIUtil.CreateText(center, info, fontSize, fontName)
        --group.version:DisableHitTest()
        group.version:SetColor('FF5E5E5E') --#FF5E5E5E  
        --group.version:StreamText(info, 20) 
        LayoutHelpers.AtVerticalCenterIn(group.version, center)
        LayoutHelpers.AtRightIn(group.version, center)
        Tooltip.AddControlTooltip(group.version, str.tooltip('game_ver'))
    end
        
    return center
end
function CreateInfoIcon(parent, iconName)
   local icon = Bitmap(parent)
   icon:SetTexture(modTextures..iconName)
   LayoutHelpers.SetDimensions(icon, iconSize, iconSize)
   icon:UseAlphaHitTest(true) 
   icon:SetSounds(true) 
   icon:SetHighlight(true, 0.8, 1.0)
   return icon
end
function CreateInfoIconVictory(parent)
    
    local vc = sessionOptions.Victory and string.lower(sessionOptions.Victory) or 'unknown'
    local key = 'vc_'.. vc
    
    local tooltipText = str.loc(key) 
    local tooltipBody = str.loc(key..'_info') 
    
    if (vc == 'demoralization') then
        GameStatus.HasAssassination = true
    else
        GameStatus.HasAssassination = false
    end
        
    local iconName = 'game_victory_' 
    iconName = iconName..(GameStatus.HasAssassination and 'on.dds' or 'off.dds')
    
    local icon = CreateInfoIcon(parent, iconName)
    Tooltip.AddControlTooltip(icon, { text=tooltipText, body=tooltipBody})
    return icon
end


local UnitsRestrictions = import('/lua/ui/lobby/UnitsRestrictions.lua') 

function GetUnitTech(bp)
    local cats = table.hash(bp.Categories)
    if cats['TECH1'] then return 'T1' end
    if cats['TECH2'] then return 'T2' end
    if cats['TECH3'] then return 'T3' end
    if cats['COMMAND'] then return 'T0' end
    if cats['EXPERIMENTAL'] then return 'T4' end
    return ""
end
function CreateInfoIconRestrictions(parent)
    local restrictions = sessionOptions.RestrictedCategories
    local restrictionCount = table.getsize(restrictions)
    local presetsCount = 0
    local unitsCount = 0
    local tooltipBody = ''
    local tooltipLines = 20
    
    if restrictionCount == 0 then 
        GameStatus.HasNoRestrictions = true
        tooltipBody = str.loc('ur_NONE')
    else
        log.Table(restrictions, 'restrictions')
   
        GameStatus.HasNoRestrictions = false
        log.Trace('CreateInfoIconRestrictions()... game not ranked because ' .. restrictionCount ..' unit restrictions')
        log.Table(restrictions,'restrictions')

        local presets = UnitsRestrictions.GetPresetsData()
        local presetsNames = ''
        local unitsNames = ''
        
        for _, restriction in restrictions do
            local bp = __blueprints[restriction]
            local preset = presets[restriction]
 
            if preset then 
                presetsCount = presetsCount + 1
                presetsNames = '- '.. LOCF(preset.name)..'\n '..presetsNames
            elseif bp then
                if unitsCount < tooltipLines then 
                    unitsCount = unitsCount + 1
                    local unit = ''
                    if bp.Description then unit = LOCF(bp.Description)
                    elseif bp.Name  then   unit = LOCF(bp.Name)
                    end
                    unitsNames = '- No ' .. GetUnitTech(bp) .. ' '..unit..'\n '..unitsNames
                end 
            end
        end 
        if presetsCount > 0 then
            tooltipBody = ' Presets (' .. presetsCount .. '): \n ' .. presetsNames 
        end 
        local customCount = restrictionCount - presetsCount
        if customCount > 0 then
            tooltipBody = tooltipBody .. ' Custom (' .. customCount .. '): \n ' .. unitsNames 
        end 

        if customCount > tooltipLines then
            local other = customCount - unitsCount
            tooltipBody = tooltipBody .. ' - plus ' .. other .. ' more...'
        end

    end

    --log.Trace('restrictions='..tooltipBody)
    local restrictionInfo = presetsCount ..'/'.. (restrictionCount - presetsCount)
    
    local tooltipText = str.loc('ur')..' ('..restrictionCount..')'
    
    local iconName = 'game_restrictions_' 
    iconName = iconName..(GameStatus.HasNoRestrictions and 'off.dds' or 'on.dds')
    
    local icon = CreateInfoIcon(parent, iconName)
    Tooltip.AddControlTooltip(icon, { text=tooltipText, body=tooltipBody})
    return icon
end
function CreateInfoIconSharing(parent)
    local tooltipShare = ''
    local tooltipCap = ''
    
    if (sessionOptions.Share == nil or 
        sessionOptions.Share == "yes") then
        tooltipShare = str.loc('sc_yes')  
    else -- full share
        tooltipShare = str.loc('sc_no') 
    end
     
    if (sessionOptions.ShareUnitCap == nil or 
        sessionOptions.ShareUnitCap == "none") then 
        tooltipCap = str.loc('suc_none')  
    elseif (sessionOptions.ShareUnitCap == "allies") then
        tooltipCap = str.loc('suc_allies')  
    elseif (sessionOptions.ShareUnitCap == "all") then
        tooltipCap = str.loc('suc_all') 
    end
    
    local isDefault = (GameStatus.HasSendUnits) -- and GameStatus.HasShareCaps)
    
    local tooltipText = str.loc('sc')  
    local tooltipBody = '- '..tooltipCap..'\n - '..tooltipShare
     
    local iconName = 'game_share_' .. 'on.dds'
    --iconName = iconName..(isDefault and 'on.dds' or 'off.dds')
    
    local icon = CreateInfoIcon(parent, iconName) 
    Tooltip.AddControlTooltip(icon, { text=tooltipText, body=tooltipBody} )
    return icon
end 
function CreateInfoIconAI(parent)
    local tooltipText = str.loc('ai_info')..(Stats.ai.active and ' ON' or ' OFF')
    local tooltipBody = ''
    tooltipBody = '- Income: '..Stats.ai.info.income..'\n '..tooltipBody
    tooltipBody = '- Build:  '..Stats.ai.info.build..'\n '..tooltipBody  
    tooltipBody = '- Omni:   '..Stats.ai.info.omni..'\n '..tooltipBody
     
    if (Stats.ai.active) then
        GameStatus.HasNoAI = false
    else
        GameStatus.HasNoAI = true
    end
        
      
    local iconName = 'game_ai_' 
    iconName = iconName..(GameStatus.HasNoAI and 'off.dds' or 'on.dds')
    
    local icon = CreateInfoIcon(parent, iconName)
    Tooltip.AddControlTooltip(icon, { text=tooltipText, body=tooltipBody} )
    return icon
end
function CreateInfoIconRanked(parent)

    local logSource = 'CreateInfoLine()... '
    local tooltipBody = str.loc('game_ranked_info') 
    local tooltipText = str.loc('game_ranked')
    
    -- game is ranked:
    -- if it is ladder game or
    -- if default game options are set
    
    local isGameRanked = true    
    -- check if the game has ladder ranking
    if (sessionOptions.Ranked) then
        isGameRanked = true
        tooltipBody = str.loc('game_ranked_ladder') 
    else
        for key,condition in tab.GetPairs(GameStatus) do
            if (condition) then
                tooltipBody = tooltipBody..'\n +'
                tooltipBody = tooltipBody..str.loc('game_ranked_'..key)
            end   
        end
        for key,condition in tab.GetPairs(GameStatus) do
            if (not condition) then
                log.Trace(logSource ..'game not ranked because ' .. key .. ' = false')
                isGameRanked = false
                tooltipBody = tooltipBody..'\n -  '
                tooltipBody = tooltipBody..str.loc('game_ranked_'..key)
            end   
        end
    end         
    
    tooltipText = tooltipText..(isGameRanked and ' ON' or ' OFF')
    
    local iconName = 'game_rank_' 
    iconName = iconName..(isGameRanked and 'on.dds' or 'off.dds')
     
    local icon = CreateInfoIcon(parent, iconName)
    Tooltip.AddControlTooltip(icon, { text=tooltipText, body=tooltipBody} )
    return icon
end
function CreateInfoIconMods(parent)
    local mods = { }
    mods.UI  = { Info = '', Count = 0 }
    mods.SIM = { Info = '', Count = 0 }

    --TODO add check for phantom-x mod (essionInfo.Options.Phantom_PhantNumber ~= nil)
    --TODO add check for black ops mod
    --TODO add check for LABSwars, Diamond, King of the hill, murder party, the nomads, supreme destruction
    --TODO add check for survival in map script file
    
    for k, mod in __active_mods do -- mods.Active do
        mod.type = mod.ui_only and 'UI' or 'SIM'
        mods[mod.type].Info  = mod.type .. ' - '..mod.name..'\n ' .. mods[mod.type].Info
        mods[mod.type].Count = mods[mod.type].Count + 1 
        log.Trace('CreateInfoIconMods()... '..mod.type..' '..mod.name)
    end
    local modCount = mods.SIM.Count..'/'.. mods.UI.Count
    
    local tooltipBody = mods.UI.Info .. mods.SIM.Info-- uioMods .. simMods
    local tooltipText = str.loc('game_mods')..' ('.. modCount ..')'
    tooltipText = tooltipText..'                              . '
    
    GameStatus.HasNoSimMods = mods.SIM.Count == 0
    
    local iconName = 'game_mods_' ..(GameStatus.HasNoSimMods and 'off.dds' or 'on.dds')
       
    local icon = CreateInfoIcon(parent, iconName)
    Tooltip.AddControlTooltip(icon, { text=tooltipText, body=tooltipBody} )
    return icon
end
--------------------------------------------------------------------------
-- Data functions
--------------------------------------------------------------------------

-- get army Stats using deep table search, column = Stats.'eco.massIncome'
function GetStatsForArmyID(armyID, column, useFormatting)
    -- default to army Stats with out formatting
    if useFormatting == nil then useFormatting = false end
   
    local army = {}
    if armyID > 0 then -- players
       army = Stats.armies[armyID] 
    else -- teams
       army = Stats.teams[armyID] 
    end
   
    return GetStatsForArmy(army, column, useFormatting) 
end
function GetStatsForArmy(army, column, useFormatting)
    -- default to army stats with formatting
    if useFormatting == nil then useFormatting = true end
    
    if army == nil then
        log.Warning('GetStatsForArmy -> army is nil and column is '..column) 
        return -1
    end
     
    local val = tab.Get(army, column)
    -- don't format strings
    if type(val) == "string" then
        useFormatting = false
    end
    
    if not useFormatting then
        return val
    else -- override formatting for these columns
        if (column == 'ratio.killsToBuilt' or 
            column == 'ratio.killsToLoses' or
            column == 'ratio.builtToLoses') then
            val = string.format("%01.2f", val) 
        elseif (column == 'rating.rounded' or 
                column == 'rating.actual') then
            val = string.format("%4.0f", val)  
        else
            val = num.frmt(val)
        end
        
        return val
    end
end
-- create team for index or player's army
function CreateTeam(armyIndex, armies)
    --log.Trace('InitializeStats()... creating team for army='..armyIndex)
     
    local team = {} 
    team.key = ''
    team.dead = false
    team.faction = -2 -- used for T symbol
    team.icon = ScoreMng.GetArmyIcon(team.faction)
            
    team.nickname  = "TEAM"
    team.nameshort = "TEAM"
    team.namefull  = "TEAM"
    team.type = "team"
    team.color = 'ffffffff'
    team.txtColor = 'ffffffff'
    team.colors = {}
    
    team.score = 0 
    team.units = ScoreMng.GetArmyTableUnits() 
    team.ratio = ScoreMng.GetArmyTableRatio()
    team.kills = ScoreMng.GetArmyTableKills() 
    team.loses = ScoreMng.GetArmyTableLoses() 
    team.eco   = ScoreMng.GetArmyTableEco() 
    team.rating = {}
    team.rating.actual = 0
    team.rating.rounded = 0
    
    team.number = 0
    team.members = {}
    team.members.alive = 0
    team.members.count = 0
    team.members.ids   = {}
    team.quadrant = 4

    --map.quadrant
    for armyID,army in armies do 
        --if army.civilian or armyID == armyIndex then continue end
        if not army.civilian and IsAlly(armyID, armyIndex) then
            --log.Trace('InitializeStats()... creating team for army='..armyIndex .. ' allied with '.. armyID)
    
            -- use first player's color as team's color 
            if (team.key == '') then team.color = army.color end
            
            -- build unique key for the team using id of allied players
            team.key = team.key..armyID
            team.rating.actual = team.rating.actual + army.rating.actual
            team.quadrant = math.min(team.quadrant, Stats.map.quadrants[army.name] or 4)

            table.insert(team.members.ids, armyID)
            table.insert(team.colors, army.color)
        end
    end
    log.Trace('InitializeStats()... creating team for army='..armyIndex .. ' finished '.. team.key .. ' quadrant' .. team.quadrant)
    
    -- assume all players are alive and these values will be updated OnBeat
    team.members.alive   = table.getn(team.members.ids)
    team.members.count   = table.getn(team.members.ids)
    
    team.rating.actual  = team.rating.actual / team.members.count
    team.rating.rounded = num.round100(team.rating.actual)
    
    --team.colorsCount = table.getn(team.colors)
   
    UpdateTeamStatus(team, armies) 
    UpdateTeamColor(team, armies)
    
    return team
end
function IsArmyAlive(armyID)
    local armies = GetArmiesTable().armiesTable 
    return IsArmyAlive(armyID, armies)
end
function IsArmyAlive(armyID, armies)
    local army = armies[armyID]
    return not army.outOfGame
end
 
function GetMapData(sessionInfo)
    local map = {}
    --map.name = LOCF("<LOC gamesel_0002>Map: %s", sessionInfo.name)
    map.name = LOCF("<LOC gamesel_0002>%s", sessionInfo.name)
    map.size = {}
    map.size.pixels = {
        width = sessionInfo.size[1],
        height = sessionInfo.size[2]
    } 
    map.size.actual = {
        width  = (5 * math.floor(map.size.pixels.width / 256)),
        height = (5 * math.floor(map.size.pixels.height / 256))
    } 
    map.size.info = '('
    map.size.info = map.size.info..map.size.actual.width .." x " 
    map.size.info = map.size.info..map.size.actual.height.." km)" 
   
    local w = map.size.pixels.width 
    local h = map.size.pixels.height 
    local w2 = map.size.pixels.width / 2
    local h2 = map.size.pixels.height / 2 
    
    local nameLength = string.len(map.name) 
    if nameLength > 35 then
       map.name = string.sub(map.name,1,35) .. '...'
    end
    map.info = map.name..' '..map.size.info
      
    local saveData = {}
    doscript('/lua/dataInit.lua', saveData)
    doscript(SessionGetScenarioInfo().save, saveData)

    map.positions = {}
    map.quadrants = {}
    for name, markers in saveData.Scenario.MasterChain['_MASTERCHAIN_'].Markers do
        if string.find(name, "ARMY_*") then
            local x = markers.position[1]
            local y = markers.position[3]
            map.positions[name] = markers.position
            if x < w2 and y < h2 then       map.quadrants[name] = 1
            elseif x >= w2 and y < h2 then  map.quadrants[name] = 2
            elseif x >= w2 and y >= h2 then map.quadrants[name] = 3
            else                            map.quadrants[name] = 4
            end
        end
    end
    
    table.print(map.quadrants, 'SSB map.quadrants')
    --table.print(saveData, 'saveData')
    
    return map
end

--------------------------------------------------------------------------
-- Update functions
--------------------------------------------------------------------------
function UpdateRatioFor(army)
     
    local skipAcuUpdates = 5.0
        
    local killsMass = army.kills.mass
    local killsEngy = army.kills.engy
    -- exclude ACU kills for more comparable ratio between players
    if (army.kills.acu > 0) then
        -- there is small delay in sync. between ACU kills and mass kill
        -- so skip a few updates of ACU kills to prevents temp. negative ratio
        if (army.kills.acu > army.kills.tmp) then
            army.kills.tmp = army.kills.tmp + (1.0 / skipAcuUpdates)
        else
            -- TODO look up cost of ACU instead of hard coding it here
            killsMass = killsMass - (army.kills.acu * 18000)
            killsEngy = killsEngy - (army.kills.acu * 5000000)
        end
    end
    
    local losesMass = army.loses.mass
    local losesEngy = army.loses.engy
    -- exclude ACU loses for more comparable ratio between players
    if (army.loses.acu > 0) then
        -- there is small delay in sync. between ACU loses and mass loses
        -- so skip a few updates of ACU loses to prevents temp. negative ratio
        if (army.loses.acu > army.loses.tmp) then
            army.loses.tmp = army.loses.tmp + (1.0 / skipAcuUpdates)
        else
            -- TODO look up cost of ACU instead of hard coding it here
            losesMass = losesMass + (army.loses.acu * 18000)
            losesEngy = losesEngy + (army.loses.acu * 5000000)
        end
    end
    -- use both mass and energy to calculate player's ratios
    local massBuiltRatio = num.div(killsMass, army.units.mass)
    local engyBuiltRatio = num.div(killsEngy, army.units.engy)
    army.ratio.killsToBuilt = (massBuiltRatio + engyBuiltRatio) / 2.0  
    
    local massLostRatio = num.div(killsMass, losesMass)
    local engyLostRatio = num.div(killsEngy, losesEngy)
    army.ratio.killsToLoses = (massLostRatio + engyLostRatio) / 2.0  
      
    local massRatio = num.div(army.units.mass, losesMass)
    local engyRatio = num.div(army.units.engy, losesEngy)
    army.ratio.builtToLoses = (massRatio + engyRatio) / 2.0  
 
    
end

local unitNotifications = {
    { name = 'EXPERIMENTAL',    categories = '(EXPERIMENTAL)'},
    { name = 'T4ARTY',          categories = '(ARTILLERY * SIZE20 * TECH3) + (ARTILLERY * EXPERIMENTAL) - FACTORY'},
    { name = 'T3ARTY',          categories = '(ARTILLERY * SIZE16 * TECH3)'},
}
local unitsAnalyzer = import('/lua/ui/lobby/UnitsAnalyzer.lua')
    
-- update Stats of a player 
function UpdateUnitStats(player, scoreData)
    --TODO unitNotifications
    --if not player.units.fixed then 
    --    --LOG('player fixing ' ..  player.nameshort)
    --    player.units.fixed = true
    --    player.units.bps = {}
    --    player.units.ignore = {}
    --    for id, val in scoreData.units or {} do
    --        if __blueprints[id] then 
    --            player.units.ignore[id] = tonumber(val.built or 0)
    --            player.units.bps[id] = {} -- __blueprints[id] --{}
    --            player.units.bps[id].total = 0
    --            player.units.bps[id].name = unitsAnalyzer.GetUnitName(__blueprints[id])
    --        end
    --    end
    --end

    player.units.total = num.init(scoreData.general.currentunits.count)
    player.units.cap   = num.init(scoreData.general.currentcap.count)
    player.units.acu   = num.subt0(scoreData.units.cdr.built, scoreData.units.cdr.lost)
    player.units.exp   = num.subt0(scoreData.units.experimental.built, scoreData.units.experimental.lost)
    player.units.air   = num.subt0(scoreData.units.air.built, scoreData.units.air.lost)
    player.units.navy  = num.subt0(scoreData.units.naval.built, scoreData.units.naval.lost)
    player.units.base  = num.subt0(scoreData.units.structures.built, scoreData.units.structures.lost)
    player.units.land  = num.subt0(scoreData.units.land.built, scoreData.units.land.lost)
        
    --TODO unitNotifications
    --for id, val in scoreData.units or {} do
    --    
    --    local offset = num.init(player.units.ignore[id])
    --    if __blueprints[id] and tonumber(val.built or 0) > offset then 
    --        
    --        local name = unitsAnalyzer.GetUnitName(__blueprints[id])
    --        
    --        if not player.units.bps[id] then
    --            player.units.bps[id] = {} -- __blueprints[id] --
    --            player.units.bps[id].total = 0 
    --            player.units.bps[id].name = name
    --        else 
    --            -- offsetting blueprint stats by ignored blueprint
    --            player.units.bps[id].total = num.subt0(val.built, val.lost) - offset
    --        end
    --        -- check if we want to show notifications about built units
    --        if not player.units.bps[id].checked then
    --               player.units.bps[id].checked = true
    --            local bp = table.copy(__blueprints[id]) 
    --            bp.Categories = table.hash(bp.Categories)
    --             
    --            for _, note in unitNotifications or {} do
    --                
    --                if unitsAnalyzer.Contains(bp, note.categories) then
    --                    WARN('notifications ' ..  player.nameshort  .. '   '.. name .. ' match ' .. note.categories)
    --                    player.units.bps[id].notify = true
    --                    player.units.bps[id].noted = 0
    --                    player.units.bps[id].name  = name
    --                    break 
    --                --else
    --                --    player.units.bps[id].notify = false
    --                end
    --            end
    --            if not player.units.bps[id].notify then
    --               -- LOG(player.nameshort  .. ' notifications ' .. name .. ' no match ')
    --                --table.print(bp.Categories,'bp.Categories')
    --            end 
    --        end
    --    end
    --end

end

function UpdatePlayerStats(armyID, armies, scoreData)
    local player = Stats.armies[armyID]
    --LOG(player.nameshort  .. ' units.bps = ' .. table.getsize(player.units.bps))

    if player == nil then
        log.Error('UpdatePlayerStats player is nil for armyID: '..armyID )
        return
    end 
    
    -- get player's eco Stats from score data and initialize it to zero if nil score
    
    if not scoreData               then log.Warning('UpdatePlayerStats scoreData is nil' ) end
    if not scoreData.general       then log.Warning('UpdatePlayerStats scoreData.general is nil' ) end
    if not scoreData.general.score then log.Warning('UpdatePlayerStats scoreData.general.score is nil' ) end
    
    player.dead = armies[armyID].outOfGame --or num.init(scoreData.general.currentunits.count) == 0
    if sessionReplay then
        player.ally = true
    else 
        player.ally = Diplomacy.CanShare(GetFocusArmy(), armyID)
    end

    -- for dead/alive players, get only some score info 
    player.score = num.init(scoreData.general.score)
    -- get player's eco and initialize it to zero if nil score
    player.eco.massTotal = num.init(scoreData.resources.massin.total)
    player.eco.massSpent = num.init(scoreData.resources.massout.total)
    player.eco.engyTotal = num.init(scoreData.resources.energyin.total)
    player.eco.engySpent = num.init(scoreData.resources.energyout.total)

    -- FIX an issue reported by Gyle due to changes in structure of FAF score data
    -- checking if reclaimed mass is store in new or old score data structure
    if scoreData.resources.massin.reclaimed then
       player.eco.massReclaim = num.init(scoreData.resources.massin.reclaimed)
    else -- old score structure
       player.eco.massReclaim = num.init(scoreData.general.lastReclaimedMass)
    end
    
    -- checking if reclaimed energy is store in new or old score data structure
    if scoreData.resources.energyin.reclaimed then
        player.eco.engyReclaim = num.init(scoreData.resources.energyin.reclaimed)
    else -- old score data format
        player.eco.engyReclaim = num.init(scoreData.general.lastReclaimedEnergy)
    end

    -- get player's kills Stats from score data and initialize it to zero if they are nil
    player.kills.acu   = num.init(scoreData.units.cdr.kills)
    player.kills.exp   = num.init(scoreData.units.experimental.kills)
    player.kills.air   = num.init(scoreData.units.air.kills)
    player.kills.navy  = num.init(scoreData.units.naval.kills)
    player.kills.land  = num.init(scoreData.units.land.kills)
    player.kills.base  = num.init(scoreData.units.structures.kills)
    player.kills.count = num.init(scoreData.general.kills.count)
    player.kills.mass  = num.init(scoreData.general.kills.mass)
    player.kills.engy  = num.init(scoreData.general.kills.energy)
    -- get player's loses Stats from score data and initialize it to zero if they are nil
    player.loses.acu   = num.init(scoreData.units.cdr.lost)
    player.loses.exp   = num.init(scoreData.units.experimental.lost)
    player.loses.air   = num.init(scoreData.units.air.lost)
    player.loses.navy  = num.init(scoreData.units.naval.lost)
    player.loses.land  = num.init(scoreData.units.land.lost)
    player.loses.base  = num.init(scoreData.units.structures.lost)
    player.loses.count = num.init(scoreData.general.lost.count)
    player.loses.mass  = num.init(scoreData.general.lost.mass)
    player.loses.engy  = num.init(scoreData.general.lost.energy)
        
    player.units.mass  = num.init(scoreData.general.built.mass)
    player.units.engy  = num.init(scoreData.general.built.energy)
      
     -- UpdateUnitStats(player, scoreData)

    if player.dead then
        -- reset income and units count so that dead players do not affect team stats
        player.eco.massIncome = 0
        player.eco.engyIncome = 0
        
        player.units.total = 0
        player.units.cap   = 0
        player.units.acu   = 0
        player.units.exp   = 0
        player.units.air   = 0
        player.units.navy  = 0
        player.units.base  = 0
        player.units.land  = 0
    else
        player.eco.massIncome = num.init(scoreData.resources.massin.rate)   * 10 -- per game ticks
        player.eco.engyIncome = num.init(scoreData.resources.energyin.rate) * 10 -- per game ticks

        player.eco.massStored = num.init(scoreData.resources.storage.storedMass)
        player.eco.engyStored = num.init(scoreData.resources.storage.storedEnergy)
        UpdateUnitStats(player, scoreData)
        
        -- show announcements about built experimental units  
        if player.announcements.exp < player.units.exp and 
           player.announcements.exp < GameOptions['SSB_NotifyThresholdFor_BuiltT4'] then
           player.announcements.exp = player.units.exp
           if sessionReplay then
            
               AnnounceUnit(armyID, 'HAS BUILT AN EXPERIMENTAL UNIT!' )
               --log.Trace('scoreData ----------- ' .. player.nickname)
               --log.Table(scoreData.units, 'score Units')
               --log.Table(player.units,    'playerUnits') 
           end
        end
        --TODO unitNotifications
        --if sessionReplay then        
        --    for id, bp in player.units.bps or {} do
        --        if bp.notify and bp.total > bp.noted then
        --            bp.noted = bp.total
        --            log.Trace('ArmyAnnounce ----------- ' .. bp.name )
        --        end
        --    end
        --end
    end
 
    -- update Stats for all players that will be visible in observer view
    Stats.units.total  = Stats.units.total + player.units.total
    Stats.units.cap    = Stats.units.cap   + player.units.cap
    
    UpdateRatioFor(player) 
    
    if player.score > 0 then Columns.Exists['score'] = true end
    if player.eco.massReclaim > 0 then Columns.Exists['eco.massReclaim'] = true end
    if player.eco.massTotal > 0 then Columns.Exists['eco.massTotal'] = true end
    if player.eco.massIncome > 0 then Columns.Exists['eco.massIncome'] = true end
    if player.eco.engyTotal > 0 then Columns.Exists['eco.engyTotal'] = true end
    if player.eco.engyReclaim > 0 then Columns.Exists['eco.engyReclaim'] = true end
    if player.eco.engyIncome > 0 then Columns.Exists['eco.engyIncome'] = true end
    if player.ratio.killsToBuilt > 0 then Columns.Exists['ratio.killsToBuilt'] = true end
    if player.ratio.killsToLoses > 0 then Columns.Exists['ratio.killsToLoses'] = true end
    if player.units.total > 0 then Columns.Exists['units.total'] = true end
    if player.units.land > 0 then Columns.Exists['units.land'] = true end
    if player.units.navy > 0 then Columns.Exists['units.navy'] = true end
    if player.units.air > 0 then Columns.Exists['units.air'] = true end

    local team = Stats.teams[player.teamID]
    UpdateTeamStats(team, player)
    

    --Stats.armies[armyID] = player

    return player
end
-- update Stats a team that has the player
function UpdateTeamStats(team, player)
   
    if not Stats.teamsActive or not team then
        return
    end
    --log.Trace('UpdatePlayerStats team.key  ='..team.teamID )
    --log.Trace('UpdatePlayerStats team.size='..team.size )
    --log.Trace('UpdatePlayerStats team.name='..team.nickname )
    team.score = team.score + player.score
    
    team.eco.massTotal   = team.eco.massTotal   + player.eco.massTotal
    team.eco.massSpent   = team.eco.massSpent   + player.eco.massSpent
    team.eco.engyTotal   = team.eco.engyTotal   + player.eco.engyTotal
    team.eco.engySpent   = team.eco.engySpent   + player.eco.engySpent
    team.eco.massReclaim = team.eco.massReclaim + player.eco.massReclaim
    team.eco.engyReclaim = team.eco.engyReclaim + player.eco.engyReclaim
    -- update team's kills Stats
    team.kills.acu   = team.kills.acu   + player.kills.acu
    team.kills.exp   = team.kills.exp   + player.kills.exp
    team.kills.air   = team.kills.air   + player.kills.air
    team.kills.navy  = team.kills.navy  + player.kills.navy
    team.kills.land  = team.kills.land  + player.kills.land
    team.kills.base  = team.kills.base  + player.kills.base
    team.kills.count = team.kills.count + player.kills.count
    team.kills.mass  = team.kills.mass  + player.kills.mass
    team.kills.engy  = team.kills.engy  + player.kills.engy
    -- update team's kills Stats
    team.loses.acu   = team.loses.acu   + player.loses.acu
    team.loses.exp   = team.loses.exp   + player.loses.exp
    team.loses.air   = team.loses.air   + player.loses.air
    team.loses.navy  = team.loses.navy  + player.loses.navy
    team.loses.land  = team.loses.land  + player.loses.land
    team.loses.base  = team.loses.base  + player.loses.base
    team.loses.count = team.loses.count + player.loses.count
    team.loses.mass  = team.loses.mass  + player.loses.mass
    team.loses.engy  = team.loses.engy  + player.loses.engy
    -- dead players have no income and no units
    if not player.dead then
        -- update team's eco
        team.eco.massIncome = team.eco.massIncome + player.eco.massIncome
        team.eco.engyIncome = team.eco.engyIncome + player.eco.engyIncome
        -- update team's units
        team.units.mass  = team.units.mass  + player.units.mass
        team.units.engy  = team.units.engy  + player.units.engy
        team.units.total = team.units.total + player.units.total
        team.units.cap   = team.units.cap   + player.units.cap
        team.units.acu   = team.units.acu   + player.units.acu
        team.units.exp   = team.units.exp   + player.units.exp
        team.units.air   = team.units.air   + player.units.air
        team.units.navy  = team.units.navy  + player.units.navy
        team.units.base  = team.units.base  + player.units.base
        team.units.land  = team.units.land  + player.units.land
    end
    -- sum team/player ratio values and then average them by alive players in OnBeat function
    team.ratio.killsToBuilt = team.ratio.killsToBuilt + player.ratio.killsToBuilt
    team.ratio.killsToLoses = team.ratio.killsToLoses + player.ratio.killsToLoses
end
-- update team color based on alive members and prioritizing 'nice colors'
function UpdateTeamColor(team, armies)
    
    -- log.Trace('UpdateTeamColor  '..team.key)
    team.colorChanged = false

    -- TODO improve logic so that there is no need for color searching
    for _, item in Colors do 
        for _,armyID in team.members.ids do
            local army = armies[armyID]
            if not army.outOfGame and army.color == item.armyColor then
                --log.Trace('UpdateTeamColor()... team.color= '..army.color)
                team.color    = item.armyColor
                team.txtColor = item.textColor
                team.colorChanged = true
                return 
            end
        end
    end 
    --log.Trace('UpdateTeamStatus... DONE'..team.key)
     
end
function UpdateTeamStatus(team, armies)
    --log.Trace('UpdateTeamStatus... '..team.key)
    --log.Table(team, 'team')

    team.members.alive   = 0
    for _,armyID in team.members.ids do
        if IsArmyAlive(armyID, armies) then 
            team.members.alive = team.members.alive + 1
        end
    end
   -- TODO show team status using faction icons of the team's members
    team.status = ' ('..team.members.alive..'/'..team.members.count..')' 
    team.dead   = team.members.alive == 0
     
    team.nameshort = team.nickname..team.status 
    team.namefull  = team.nickname..team.status 
    
    --log.Trace('UpdateTeamStatus... DONE'..team.key)
end

function UpdateTimer()
    -- HUSSAR: optimized updates to the controls.time UI element, 
    -- HUSSAR: added game speed info when no rush timer is counting down
    local gameInSeconds = GetGameTimeSeconds()
    local sessionSpeed = string.format("%+d/%+d", gameSpeed, GetSimRate() )
    local sessionTimer = "00:00:00"
    if sessionOptions.NoRushOption and sessionOptions.NoRushOption ~= 'Off' then
        local rushTimeOut = tonumber(sessionOptions.NoRushOption) * 60
        if rushTimeOut > gameInSeconds then
            local time = rushTimeOut - gameInSeconds
            local timeHH =  math.floor(time / 3600)
            local timeMM =  math.floor(time / 60)
            local timeSS =  math.mod(time, 60)
            sessionTimer = 'T-'..string.format("%02d:%02d:%02d", timeHH, timeMM, timeSS ) 
        end
        local gameTimeElapsed = math.floor(gameInSeconds)
        if not issuedNoRushWarning and rushTimeOut == gameTimeElapsed then
            Announcement.CreateAnnouncement('<LOC score_0001>No Rush Time Elapsed', controls.time)
            sessionOptions.NoRushOption = 'Off'
            issuedNoRushWarning = true
        end
    else
        sessionTimer = GetGameTime()       
    end
    
    -- HUSSAR: added info about game quality
    local sessionQuality = '--%'
    if sessionOptions.Quality then
       sessionQuality = string.format("%.0f%%", sessionOptions.Quality)
    end
    controls.time:SetText(string.format("%s", sessionTimer))
    controls.speed:SetText(string.format("%s", sessionSpeed))
    controls.quality:SetText(string.format("%s", sessionQuality))

    return gameInSeconds
end
function UpdateUnitsInfo(current, cap)
    controls.units:SetText(num.frmt(current).. '/'..num.frmt(cap))
    -- HUSSAR: added check to avoid displaying unit cap message for dead player
    if cap ~= 0 and cap == current then
        if (not lastUnitWarning or GameTime() - lastUnitWarning > 60) and not unitWarningUsed then
            --LOG('>>>> units: ', current, ' cap: ', cap)
            Announcement.CreateAnnouncement(LOC('<LOC score_0002>Unit Cap Reached'), controls.units)
            lastUnitWarning = GameTime()
            unitWarningUsed = true
        end
    else
        unitWarningUsed = false
    end
end
function UpdateArmyLines(column)
    
    if not sessionReplay then return end
    -- some column sorting does not require UI updating
    if column == 'rating.actual' or
       column == 'rating.rounded' or
       column == 'teamID' or
       column == 'armyID' then return end
          
    for _, line in controls.armyLines do
        -- skip lines without players/teams
        if line.isObsLine or 
           line.isMapLine or 
           line.isSortLine then 
           --continue
        else
            -- skip lines with alive players/teams 
            -- because they will be updated OnBeat()
            --if not line.dead then continue end
            --local useFormating = column ~= Columns.Rating.Active
        
            local value = GetStatsForArmyID(line.armyID, column, true)
         
            if column == Columns.Name.Active then
                line.nameColumn:SetText(value) 
                --continue
            elseif column == Columns.Rating.Active then 
                line.rating:SetText(value)
            
            elseif column == Columns.Mass.Active then
                line.massColumn:SetText(value)
                line.massIcon:SetTexture(modTextures..column..'.dds')
            
            elseif column == Columns.Engy.Active then 
                line.engyColumn:SetText(value)
                line.engyIcon:SetTexture(modTextures..column..'.dds')
            
            elseif column == Columns.Units.Active then 
                line.unitColumn:SetText(value)
                line.unitIcon:SetTexture(modTextures..column..'.dds')
            
            elseif column == Columns.Score.Active then 
                line.scoreColumn:SetText(value)
            
                if line.dead then
                    line.scoreColumn:SetColor(armyColorDefeted)
                elseif (column == 'score') then
                    line.scoreColumn:SetColor(textColorScore)
                elseif (column == 'ratio.killsToLoses') then
                    line.scoreColumn:SetColor(textColorKills)
                elseif (column == 'ratio.killsToBuilt') then
                    line.scoreColumn:SetColor(textColorMass)
                end

            elseif column == Columns.Total.Active then 
                line.totalColumn:SetText(value)
                line.totalIcon:SetTexture(modTextures..column..'.dds')
            
                if line.dead then
                    line.totalColumn:SetColor(armyColorDefeted)
                elseif (column == 'eco.massTotal') then
                    line.totalColumn:SetColor(textColorMass)
                elseif (column == 'kills.mass') then
                    line.totalColumn:SetColor(textColorKills)
                elseif (column == 'loses.mass') then
                    line.totalColumn:SetColor(textColorLoses)
                end
            
            --TODO units and score columns
            --else        
                --log.Trace('UpdateArmyLines not supported for: '..column..' ...')
            end

        end 
        
    end
end
-- resets team Stats before updating teams with their team members
function ResetTeamStats()
    Stats.units  = ScoreMng.GetArmyTableUnits() 
    
    for key,team in Stats.teams do  
        team.score = 0 
        team.eco   = ScoreMng.GetArmyTableEco()
        team.kills = ScoreMng.GetArmyTableKills()
        team.loses = ScoreMng.GetArmyTableLoses()
        team.units = ScoreMng.GetArmyTableUnits()
        team.ratio = ScoreMng.GetArmyTableRatio() 
    end
end

function KillArmyLine(line)
    line.dead = true
                            
    -- gray out faction, score, name of dead player/team
    line.faction:SetTexture(modTextures..'army_dead.dds')
    line.color:SetSolidColor('ff000000')
    line.rating:SetColor(armyColorDefeted)
    line.scoreColumn:SetColor(armyColorDefeted)
    line.nameColumn:SetColor(armyColorDefeted)
    line.nameColumn:SetFont(fontName, fontSize)
    line.rating:SetFont(fontMono, fontSize)
    
    if line.shareUnitsIcon then line.shareUnitsIcon:Hide() end
    if line.shareMassIcon then  line.shareMassIcon:Hide()  end
    if line.shareEngyIcon then  line.shareEngyIcon:Hide()  end
    if line.massColumn then     line.massColumn:Hide()  end
    if line.engyColumn then     line.engyColumn:Hide()  end

    if sessionReplay then
        line.totalColumn:SetColor(armyColorDefeted)
        line.massColumn:SetColor(armyColorDefeted)
        line.engyColumn:SetColor(armyColorDefeted)
        line.unitColumn:SetColor(armyColorDefeted) 
        line.unitColumn:SetText('0')
    end
end

local logArmyScore = false
function HighlightUI(line, isHighlighted)
   
    if isHighlighted then
        line.nameColumn:SetFont(fontNameBold, fontSize) -- 14 
        if line.rating then
            line.rating:SetFont(fontMonoBold, fontSize)
        end
    else
        line.nameColumn:SetFont(fontName, fontSize) -- 14
        if line.rating then
            line.rating:SetFont(fontMono, fontSize)
        end
    end
     
end  
--TODO-FAF remove
currentScores = {}
function Update(newScoreData)
    currentScores = table.deepcopy(newScoreData)
    --import(modPath .. 'modules/score_manager.lua').SetScoreData(currentScores)
end

local initalBeats = true
function _OnBeat()
    --TODO-FAF remove
    --local scoreData = import('/lua/ui/game/scoreaccum.lua').GetScoreData()
    --local scoreData = import(modPath .. 'modules/score_manager.lua').GetScoreData()
    --LOG('SSB OnBeat... ' .. table.getsize(currentScores))

    UpdateTimer()
    --and sessionReplay
    if initalBeats  and GetGameTimeSeconds() >= 1 then  
       initalBeats = false
       log.Trace('initialized')

        -- prevent updates of the original//old score board
        local orgScore = import('/lua/ui/game/score.lua')
        GameMain.RemoveBeatFunction(orgScore._OnBeat)

        -- offset Avatars UI by height of this score board
        --local avatars = import('/lua/ui/game/avatars.lua').controls.avatarGroup
        --avatars.Top:Set(function() return controls.bgBottom.Bottom() + 4 end)
        SetLayout()

        -- hide some not useful UI elements in in replay session because they block game world
        --import('/lua/ui/game/tabs.lua').ToggleTabDisplay(false)
        --import('/lua/ui/game/economy.lua').ToggleEconPanel(false)
        --import('/lua/ui/game/avatars.lua').ToggleAvatars(false)
        if sessionReplay then 
            import('/lua/ui/game/multifunction.lua').ToggleMFDPanel(false)
        end
    end
     
    -- HUSSAR: added variables to keep tack of all units in the game (in observer view)
    ResetTeamStats()
    --TODO-FAF remove
    if not currentScores then return end
   
    local focusedArmyID = GetFocusArmy() 
    local armies = GetArmiesTable().armiesTable
    
    if logArmyScore then
        --logArmyScore = false
        --log.Table(armies[focusedArmyID],'focusedArmy')
    end
     
    --TODO-FAF replace currentScores with currentScores
    if currentScores and controls.armyLines then
       -- first update players' lines and show new score data
       for lineID, line in controls.armyLines do
       
           -- skip lines without players or dead players
           local armyID = line.armyID
           local data = currentScores[armyID]  
           
           local player = {}
           -- Stats must be updated even for dead players so that team Stats are accurate 
           if line.isArmyLine and data then
               player = UpdatePlayerStats(armyID, armies, data)
           end
               
           if line.dead then 
               if sessionReplay and focusedArmyID == armyID then
                   UpdateUnitsInfo(0, 0) 
               end 
           elseif line.isArmyLine and data then
                  
               if sessionReplay then
                   if data.resources.massin.rate then
                       line.totalColumn:SetText(GetStatsForArmy(player, Columns.Total.Active))
                       line.massColumn:SetText(GetStatsForArmy(player, Columns.Mass.Active))
                       line.engyColumn:SetText(GetStatsForArmy(player, Columns.Engy.Active))
                       line.unitColumn:SetText(GetStatsForArmy(player, Columns.Units.Active))
                   end
               else
                   if not player.ally then
                        ToggleEconomyColumns(line, false)
                   else
                        ToggleEconomyColumns(line, true)
                        
                       -- showing eco stats of team-mates in game session
                       if data.resources.massin.rate and line.massColumn then
                          -- line.massColumn:SetText(GetStatsForArmy(player, Columns.Mass.Active))
                          -- line.engyColumn:SetText(GetStatsForArmy(player, Columns.Engy.Active))
                            if alliesInfoShowStorage then
                                line.massColumn:SetText(num.frmt(player.eco.massStored))
                                line.engyColumn:SetText(num.frmt(player.eco.engyStored))
                            else
                                line.massColumn:SetText(GetStatsForArmy(player, Columns.Mass.Active))
                                line.engyColumn:SetText(GetStatsForArmy(player, Columns.Engy.Active))
                            end
                       end
                   end
               end
               
               -- update army's score
               if player.score == -1 then
                   line.scoreColumn:SetText(LOC("<LOC _Playing>Playing"))
               else
                   line.scoreColumn:SetText(' '..GetStatsForArmy(player, Columns.Score.Active))
               end        
               
               if focusedArmyID == armyID then -- current player  
                   HighlightUI(line, true) 
                   UpdateUnitsInfo(player.units.total, player.units.cap)
                   if logArmyScore then
                      --table.print(player.units.bps,'player.units.bps')
                      --table.print(currentScores,'currentScores') 
                      --AnnounceVictory(focusedArmyID, ' has won this game!')
                      --AnnounceDeath(armyID, '', 1)
                      --AnnounceDeath(focusedArmyID, 'has been defeated by', ScoreMng.GetArmyIndex('speed2'))
                      --AnnounceDraw(focusedArmyID, 'has drawn with', ScoreMng.GetArmyIndex('speed2'))
                      logArmyScore = false
                      --LOG(' ticks ' .. ticks .. ' gameTime ' .. gameTime)
                      --log.Table(data, player.nickname..'.score')
                      --log.Table(armies[armyID],player.nickname..'.army')
                   end
               elseif focusedArmyID ~= -1 then    -- other players
                   HighlightUI(line, false) 
               else -- when observer is focused
                    -- show unit count in all armies
                   UpdateUnitsInfo(Stats.units.total, Stats.units.cap) 
                   HighlightUI(line, false) 
               end
               
               if player.dead then
                  log.Trace('OnBeat() player has died: '..player.nickname)
                  
                  if data.general.score == -1 then
                      line.scoreColumn:SetText(LOC("<LOC _Defeated>Defeated"))
                  end
                  if Stats.teamsActive then 
                      local teamId = Stats.armies[armyID].teamID
                      local team = Stats.teams[teamId]
                      UpdateTeamStatus(team, armies)
                      team.statusChanged = true
                      -- check if team color needs to change
                      --if (team.color == player.color) then
                      --    team.colorChanged = true
                      --    UpdateTeamColor(team, armies)
                      --end
                  end
                  KillArmyLine(line)
               end
           end
       end
       
       -- then update teams' lines and show score data for allied players (teams)
       for lineID, line in controls.armyLines do
           -- skip lines without teams
           local armyID = line.armyID
           local team = Stats.teams[armyID] 
               
           if Stats.teamsActive and line.isTeamLine and team then
               --log.Trace('OnBeat updating team line: '..line.armyID)
               if sessionReplay then
                   -- average ratio values for teams based on number of team members
                   team.ratio.killsToBuilt = (team.ratio.killsToBuilt / team.members.count)  
                   team.ratio.killsToLoses = (team.ratio.killsToLoses / team.members.count)  
                   line.totalColumn:SetText(GetStatsForArmy(team, Columns.Total.Active))
                   line.massColumn:SetText(GetStatsForArmy(team, Columns.Mass.Active))
                   line.engyColumn:SetText(GetStatsForArmy(team, Columns.Engy.Active))
                   line.unitColumn:SetText(GetStatsForArmy(team, Columns.Units.Active))
               end 
               -- update army's score
               if team.score <= -1 then
                  line.scoreColumn:SetText(LOC("<LOC _Playing>Playing"))
               else
                  line.scoreColumn:SetText(' '..GetStatsForArmy(team, Columns.Score.Active))
               end 
               -- update team color only for alive teams
               if team.colorChanged and not team.dead then
                  team.colorChanged = false
                  line.color:SetSolidColor(team.color)
               end
               if team.dead and not line.dead then
                  log.Trace('OnBeat() team has died: '..team.namefull)
                  KillArmyLine(line)
                   --ArmyAnnounce(team.armyID, team.nickname..' has fallen!', 'Valar Morghulis')
               end
               if team.statusChanged then
                  team.statusChanged = false
                  line.nameColumn:SetText(team.namefull) 
               end
           end
       end
       SortArmyLines()
        
       if sessionReplay then
            SwitchColumns()
       end
   end
        
   if observerLine then
       if focusedArmyID == -1 then
           logArmyScore = true
           HighlightUI(observerLine, true) 
       else
           HighlightUI(observerLine, false) 
       end
   end 
   --TODO FAF
    import(modScripts..'score_mini.lua').LayoutArmyLines()
    --import(UIUtil.GetLayoutFilename('score')).LayoutArmyLines()
   
end

local switchTime = 0

function SwitchColumns()
    local gameTime = GetGameTimeSeconds()

    local switchInterval = GameOptions['SSB_Auto_Toggle_Interval'] or 10 -- in seconds
    if switchInterval > 1 and switchInterval <= gameTime - switchTime then
       switchTime = gameTime
                 
        if GameOptions['SSB_Auto_Toggle_Mass_Column']  then
            Columns.Mass.Index = Columns.Mass.Index + 1
            if Columns.Mass.Index > tab.Size(Columns.Mass.Keys) then
               Columns.Mass.Index = 1 -- go back to first key
            end
            local column = Columns.Mass.Keys[Columns.Mass.Index]
            if Columns.Exists[column] then
               Columns.Mass.Active = column
               UpdateArmyLines(column)
            end
        end
        
        if GameOptions['SSB_Auto_Toggle_Engy_Column'] then
            Columns.Engy.Index = Columns.Engy.Index + 1
            if Columns.Engy.Index > tab.Size(Columns.Engy.Keys) then
               Columns.Engy.Index = 1 -- go back to first key
            end
            local column = Columns.Engy.Keys[Columns.Engy.Index]
            if Columns.Exists[column] then
               Columns.Engy.Active = column
               UpdateArmyLines(column)
            end 
        end

        if GameOptions['SSB_Auto_Toggle_Units_Column'] then
            Columns.Units.Index = Columns.Units.Index + 1
            if Columns.Units.Index > tab.Size(Columns.Units.Keys) then
               Columns.Units.Index = 1
            end
            local column = Columns.Units.Keys[Columns.Units.Index]
            if Columns.Exists[column] then
               Columns.Units.Active = column
               UpdateArmyLines(column)
            end  
        end

        if GameOptions['SSB_Auto_Toggle_Total_Column'] then
            Columns.Total.Index = Columns.Total.Index + 1
            if Columns.Total.Index > tab.Size(Columns.Total.Keys) then
               Columns.Total.Index = 1
            end
            local column = Columns.Total.Keys[Columns.Total.Index]
            if Columns.Exists[column] then
               Columns.Total.Active = column
               UpdateArmyLines(column)
            end  
        end

        if GameOptions['SSB_Auto_Toggle_Score_Column'] then
            Columns.Score.Index = Columns.Score.Index + 1
            if Columns.Score.Index > tab.Size(Columns.Score.Keys) then
               Columns.Score.Index = 1
            end
            local column = Columns.Score.Keys[Columns.Score.Index]
            if Columns.Exists[column] then
               Columns.Score.Active = column
               UpdateArmyLines(column)
            end   
        end
    end
end
function SortArmyLines()
    --TODO sort army lines based on user selection 
    -- in   Game Session: rating, name, score
    -- in Replay Session: rating, name, score, massIn, energyIn, massTotal, units,  
    
    -- sortBy columns:
    --  team # (team icon)
    --  rating 
    --  name
    --  score       score, ratio.killsToBuilt, ratio.builtToLoses
    --  mass        eco.massIncome, eco.massTotal 
    --  energy      eco.engyIncome eco.engyTotal 
    --  total       eco.massTotal kills.mass 
    --  units       units.total units.air units.land units.navy 

    table.sort(controls.armyLines, function(lineA,lineB)
        -- sort only line of players/teams
        if lineA.isObsLine  or lineB.isObsLine or  
           lineA.isMapLine  or lineB.isMapLine or 
           lineA.isSortLine or lineB.isSortLine then 
            return lineA.armyID >= lineB.armyID
            
        -- sort player and team lines by their army ID 
        elseif (lineA.isArmyLine and lineB.isTeamLine) or 
               (lineA.isTeamLine and lineB.isArmyLine) then
            return lineA.armyID >= lineB.armyID
        else -- sorting two players lines or two teams lines    
             -- get sort values for current sort column
            local sortValueA = GetStatsForArmyID(lineA.armyID, Stats.sortByColumnNew, false)
            local sortValueB = GetStatsForArmyID(lineB.armyID, Stats.sortByColumnNew, false)
               
            local sortIndex = num.sort(sortValueA,sortValueB)
            -- if lines have the same values then use previous sort
            if (sortIndex == 0) then
                -- get old sort column and try to sort lines
                local oldSortValueA = GetStatsForArmyID(lineA.armyID, Stats.sortByColumnOld, false)
                local oldSortValueB = GetStatsForArmyID(lineB.armyID, Stats.sortByColumnOld, false)
                sortIndex = num.sort(oldSortValueA,oldSortValueB)
                -- if lines have the same values then default to sorting by army ID
                if (sortIndex == 0) then 
                    return lineA.armyID >= lineB.armyID 
                else
                    return sortIndex 
                end
            else
                return sortIndex 
            end
            
        end
    end)
end

function SortArmyLinesBy(column)
    log.Trace('SortArmyLinesBy '..column..' ...')
    Stats.sortByColumnOld = Stats.sortByColumnNew
    Stats.sortByColumnNew = column
    --UpdateArmyIcons(column)
    UpdateArmyLines(column)
    SortArmyLines() 
end

function NoteGameSpeedChanged(newSpeed)
    gameSpeed = newSpeed
    if sessionOptions.GameSpeed and sessionOptions.GameSpeed == 'adjustable' and controls.time then
       controls.time:SetText(string.format("%s (%+d)", GetGameTime(), gameSpeed))
    end
    if observerLine then
       observerLine.speedSlider:SetValue(gameSpeed)
    end
end
--------------------------------------------------------------------------
-- Animation functions
--------------------------------------------------------------------------
function ToggleScoreControl(state)
    -- disable when in Screen Capture mode
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
        return
    end

    if not controls.bg then
        import('/lua/ui/game/objectives2.lua').ToggleObjectives()
        return
    end
    
    if UIUtil.GetAnimationPrefs() then
        if state or controls.bg:IsHidden() then
            Prefs.SetToCurrentProfile("scoreoverlay", true)
            local sound = Sound({Cue = "UI_Score_Window_Open", Bank = "Interface",})
            PlaySound(sound)
            controls.collapseArrow:SetCheck(false, true)
            controls.bg:Show()
            controls.bg:SetNeedsFrameUpdate(true)
            controls.bg.OnFrame = function(self, delta)
                local newRight = self.Right() - (1000*delta)
                if newRight < savedParent.Right() - 3 then
                    self.Right:Set(function() return savedParent.Right() - 18 end)
                    self:SetNeedsFrameUpdate(false)
                else
                    self.Right:Set(newRight)
                end
            end
        else
            Prefs.SetToCurrentProfile("scoreoverlay", false)
            local sound = Sound({Cue = "UI_Score_Window_Close", Bank = "Interface",})
            PlaySound(sound)
            controls.bg:SetNeedsFrameUpdate(true)
            controls.bg.OnFrame = function(self, delta)
                local newRight = self.Right() + (1000*delta)
                if newRight > savedParent.Right() + self.Width() then
                    self.Right:Set(function() return savedParent.Right() + self.Width() end)
                    self:Hide()
                    self:SetNeedsFrameUpdate(false)
                else
                    self.Right:Set(newRight)
                end
            end
            controls.collapseArrow:SetCheck(true, true)
        end
    else
        if state or controls.bg:IsHidden() then
            Prefs.SetToCurrentProfile("scoreoverlay", true)
            controls.bg:Show()
            local sound = Sound({Cue = "UI_Score_Window_Open", Bank = "Interface",})
            PlaySound(sound)
            controls.collapseArrow:SetCheck(false, true)
        else
            Prefs.SetToCurrentProfile("scoreoverlay", false)
            local sound = Sound({Cue = "UI_Score_Window_Close", Bank = "Interface",})
            PlaySound(sound)
            controls.bg:Hide()
            controls.collapseArrow:SetCheck(true, true)
        end
    end
end
function Expand()
    if needExpand then
        controls.bg:Show()
        controls.collapseArrow:Show()
        local sound = Sound({Cue = "UI_Score_Window_Open", Bank = "Interface",})
        PlaySound(sound)
        needExpand = false
    end
end
function Contract()
    if controls.bg then
        if not controls.bg:IsHidden() then
            local sound = Sound({Cue = "UI_Score_Window_Close", Bank = "Interface",})
            PlaySound(sound)
            controls.bg:Hide()
            controls.collapseArrow:Hide()
            needExpand = true
        else
            needExpand = false
        end
    else
        contractOnCreate = true
    end
end

function InitialAnimation(state)
    controls.bg.Right:Set(savedParent.Right() + controls.bg.Width())
    controls.bg:Hide()
    if Prefs.GetFromCurrentProfile("scoreoverlay") ~= false then
        controls.collapseArrow:SetCheck(false, true)
        controls.bg:Show()
        controls.bg:SetNeedsFrameUpdate(true)
        controls.bg.OnFrame = function(self, delta)
            local newRight = self.Right() - (1000*delta)
            if newRight < savedParent.Right() - 3 then
                self.Right:Set(function() return savedParent.Right() - 18 end)
                self:SetNeedsFrameUpdate(false)
            else
                self.Right:Set(newRight)
            end
        end
    end
end

function GetArmyLine(armyID) 
    if not controls.armyLines then return false end

    for _, line in controls.armyLines or {} do
        if line.armyID == armyID then 
            return line
        end
    end 
    return false
end
function AnnounceDeath(losersID, text, winnerID)
    local armyLine = GetArmyLine(losersID) 
    local losers = Stats.armies[losersID] 
    local winner = Stats.armies[winnerID]
      
    if armyLine and losers.namefull and winner.namefull then
        log.Trace('AnnounceDeath ' .. losers.namefull .. ' '.. text  ..' ' .. winner.namefull)
        local message = { value = text }
        local sender = { value = losers.namefull, fontColor = losers.color, icon = losers.icon }
        local target = { value = winner.namefull, fontColor = winner.color, icon = winner.icon }
        if winnerID == losersID then
           target.icon = false
           target.value = 'CTRL+K' 
        end 

        Announcement.CreateSmartAnnouncement(armyLine, sender, message, target)
        --PlaySound(Sound({Bank = 'Interface', Cue = 'UI_END_Game_Fail'}))        
        --PlayVoice(Sound({ Bank='XGG', Cue='XGG_Computer_CV01_05115' }))
                 
    end
end
function AnnounceDraw(armyID1, text, armyID2)
    local armyLine = GetArmyLine(armyID1) 
    local army1 = Stats.armies[armyID1] 
    local army2 = Stats.armies[armyID2]
      
    if armyLine and army1.namefull and army2.namefull then
        log.Trace('AnnounceDraw ' .. army1.namefull .. ' '.. text  ..'  ' .. army2.namefull)
        local message = { value = text }
        local sender = { value = army1.namefull, fontColor = army1.color, icon = army1.icon }
        local target = { value = army2.namefull, fontColor = army2.color, icon = army2.icon }
         
        Announcement.CreateSmartAnnouncement(armyLine, sender, message, target)
    end
end
function AnnounceVictory(winnerID, text)
    local armyLine = GetArmyLine(winnerID) 
    local winner = Stats.armies[winnerID] 
      
    if armyLine and winner.namefull then
        log.Trace('AnnounceVictory ' .. winner.namefull .. ' '.. text)
        local message = { value = text }
        local sender = { value = winner.namefull, fontColor = winner.color, icon = winner.icon }
        local target = nil --{ value = nil, icon = nil }
         
        Announcement.CreateSmartAnnouncement(armyLine, sender, message, target)
    end
end
function AnnounceUnit(armyID, text)
    local armyLine = GetArmyLine(armyID) 
    local army = Stats.armies[armyID] 
      
    if armyLine and army.namefull then
        log.Trace('AnnounceUnit ' .. army.namefull .. ' '.. text)
        local message = { value = text }
        local sender = { value = army.namefull, fontColor = army.color, icon = army.icon }
        local target = nil --{ value = nil, icon = nil }
         
        -- WARN('AnnounceUnit army.icon=' .. tostring(army.icon) )
        Announcement.CreateSmartAnnouncement(armyLine, sender, message, target)
    end
end
function ArmyAnnounce(armyID, text, textDesc)
    local armyLine = GetArmyLine(armyID) 
    
    if armyLine then
        --local data = {text = text, size = 14, color = 'FFEC0505', duration = 10, location = 'center'}
        --import('/lua/ui/game/textdisplay.lua').PrintToScreen(data)

        --import('/lua/ui/game/announcement.lua').CreateAnnouncement(LOC(text), armyLine, textDesc)
        Announcement.CreateAnnouncement(LOC(text), armyLine, textDesc)
    end
end

function OnGameSpeedChanged(newSpeed)
    gameSpeed = newSpeed
    if observerLine.speedSlider then
       observerLine.speedSlider:SetValue(gameSpeed)
    end
end

function DisplayPingOwner(worldView, pingData)

    -- Flash the scoreboard faction icon for the ping owner to indicate the source.
    if not pingData.Marker and not pingData.Renew then
        -- zero-based indices FTW...
        local pingOwnerIndex = pingData.Owner + 1
        -- finding the owner's UI of the ping data
        local pingOwnerLine  = GetArmyLine(pingOwnerIndex)
        -- setting the UI element we need to flash
        local toFlash = pingOwnerLine.faction

        if toFlash then
            local flashCount = 8
            local flashInterval = 0.4
            ForkThread(function()
                -- Flash the icon the appropriate number of times
                while flashCount > 0 do
                    toFlash:Hide()
                    WaitSeconds(flashInterval)
                    toFlash:Show()
                    WaitSeconds(flashInterval)
                    flashCount = flashCount - 1
                end
            end)
        end
    end

end

function ToggleEconomyColumns(line, isVisible)
    if isVisible then
        line.shareUnitsIcon:Show()
        line.shareEngyIcon:Show()
        line.shareMassIcon:Show()
        line.massColumn:Show()
        line.engyColumn:Show()
    else 
        line.shareUnitsIcon:Hide()
        line.shareEngyIcon:Hide()
        line.shareMassIcon:Hide()
        line.massColumn:Hide()
        line.engyColumn:Hide()
    end
end

