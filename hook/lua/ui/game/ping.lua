local UIUtil        = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

--local PingPath = '/game/marker/'
local PingPath = '/mods/SupremeScoreBoard/textures/common/game/marker/'

-- table of ping types. All of this data is sent to the sim and back to the UI for display on the world views
PingTypes = {                                                                    -- #3DBDCC #AE8EEF    -- #46D3E4  #FC3838
    move    = { Lifetime = 6, Ring = PingPath .. 'ping_blue_blur.dds',   ArrowColor = '3DBDCC',  TextColor = '46D3E4',   Sound = 'Cybran_Select_Radar', Mesh = 'move', },
    alert   = { Lifetime = 6, Ring = PingPath .. 'ping_yellow_blur.dds', ArrowColor = 'Yellow', TextColor = 'Yellow',  Sound = 'UEF_Select_Radar',    Mesh = 'alert_marker'},
    attack  = { Lifetime = 6, Ring = PingPath .. 'ping_red_blur.dds',    ArrowColor = 'Red',    TextColor = 'FC3838',   Sound = 'Aeon_Select_Radar',   Mesh = 'attack_marker'},
    marker  = { Lifetime = 5, Ring = PingPath .. 'ping_white_blur.dds',  ArrowColor = 'White',  TextColor = 'White',   Sound = 'UI_Main_IG_Click',    Marker = true},
--  marker  = { Lifetime = 5, Ring = PingPath .. 'ring_yellow02-blur.dds', ArrowColor = 'Yellow', Sound = 'UI_Main_IG_Click', Marker = true},
--  note that new Mesh values must exist in the \hook\meshes\game\ 
    drop    = { Lifetime = 6, Ring = PingPath .. 'ping_purple_blur.dds', ArrowColor = 'AE8EEF',  TextColor = 'AE8EEF',  Sound = 'UEF_Select_Radar',    Mesh = 'drop_marker'},
    request = { Lifetime = 6, Ring = PingPath .. 'ping_green_blur.dds',  ArrowColor = 'Lime',   TextColor = 'Lime',   Sound = 'UEF_Select_Radar',    Mesh = 'request_marker'},
}

-- waiting for https://github.com/FAForever/fa/pull/3109
-- uncomment for testing new ping types
-- PingTypes.move  = { Lifetime = 6, Ring = PingPath .. 'ping_purple_blur.dds', ArrowColor = 'AE8EEF',  TextColor = 'AE8EEF',  Sound = 'UEF_Select_Radar',    Mesh = 'drop_marker'}
-- PingTypes.alert = { Lifetime = 6, Ring = PingPath .. 'ping_green_blur.dds',  ArrowColor = 'Lime',   TextColor = 'Lime',   Sound = 'UEF_Select_Radar',    Mesh = 'request_marker'}
 