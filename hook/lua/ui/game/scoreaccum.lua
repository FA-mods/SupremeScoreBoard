local orgUpdateScoreData = UpdateScoreData
local modPath = '/mods/SupremeScoreBoard/'

function UpdateScoreData(newData) 

  --LOG('SSB UpdateScoreData... '.. table.getsize(newData) )

  orgUpdateScoreData(newData)
  
  --TODO-FAF remove
  --scoreData = table.deepcopy(newData)
  --import(modPath .. 'modules/score_board.lua').Update(newData)
end
