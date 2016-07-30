local options

function ReloadOptions()
   local Prefs = import('/lua/user/prefs.lua')
   options = Prefs.GetFromCurrentProfile('options')
end

function GetOptions(reload)
   if not options or reload then
      ReloadOptions()
   end

   return options
end

function SaveOptions(options)
   local Prefs = import('/lua/user/prefs.lua')

   Prefs.SetToCurrentProfile('options', options)
   Prefs.SavePreferences()
end

function boolstr(bool)
   if bool then
      return "true"
   else
      return "false"
   end
end
 
