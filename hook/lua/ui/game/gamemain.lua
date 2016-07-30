local modPath = '/mods/SupremeScoreBoard/'
local modTextures = modPath..'textures/'
local modScripts  = modPath..'modules/'
 
local orgCreateUI = CreateUI
function CreateUI(isReplay, parent)
    orgCreateUI(isReplay)

    local parent = import('/lua/ui/game/borders.lua').GetMapGroup()
     
    --TODO-FAF remove
    import(modScripts .. 'score_board.lua').CreateScoreUI(parent)
    --import(modScripts .. "init.lua").init(isReplay, import('/lua/ui/game/borders.lua').GetMapGroup())
     
    --ForkThread(import(modScripts..'scoreStats.lua').syncStats)
    
end
