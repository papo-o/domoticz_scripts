--[[ daysSelectorIcons.lua
source : https://www.domoticz.com/forum/viewtopic.php?f=59&t=27501&p=210819&hilit=seticon#p210819
https://pon.fr/dzvents-afficher-le-jour-de-la-semaine-sous-forme-d-icone/
https://easydomoticz.com/forum/
icones : https://github.com/papo-o/domoticz_scripts/tree/master/Icons/Days
 update/mise à jour = 27/12/2019
--]]
local scriptName        = 'daysSelectorIcons'
local scriptVersion     = ' 1.02'
return  {   
        active = true,
        on =    {  
                       devices         = {1927}, -- change to your device(s) separated by a comma like {2479,2480} 
                    },

   logging =   {  level    =   domoticz.LOG_DEBUG,                                             -- Seulement un niveau peut être actif; commenter les autres
                -- -- -- level    =   domoticz.LOG_INFO,                                            -- Only one level can be active; comment others
                -- -- -- level    =   domoticz.LOG_ERROR,
                -- -- -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                 marker = scriptName..' v'..scriptVersion
    },

    execute = function(dz, item)
    
        local function logWrite(str,level)
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end
        local icons =     { 
                            [10] = 143,-- level correspondant à dimanche
                            [20] = 137,-- level correspondant à lundi
                            [30] = 138,-- level correspondant à mardi
                            [40] = 139,-- level correspondant à mercredi
                            [50] = 140,-- level correspondant à jeudi
                            [60] = 141,-- level correspondant à vendredi
                            [70] = 142,-- level correspondant à samedi

                        }
           
        logWrite('lastLevel '.. tostring(item.lastLevel))
        logWrite('level '.. tostring(item.level))
        if item.level ~= item.lastLevel then 
            item.setIcon(icons[item.level])
        else
            logWrite('No Icon change necessary for ' .. item.id)
        end
    end
}
