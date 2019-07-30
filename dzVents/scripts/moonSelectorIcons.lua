--[[
moonSelectorIcons.lua
source : https://www.domoticz.com/forum/viewtopic.php?f=59&t=27501&p=210819&hilit=seticon#p210819
https://easydomoticz.com/forum/viewtopic.php?f=10&t=8758&p=71951#p71951
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/moonSelectorIcons.lua.lua
update/mise à jour = 29/07/2019
--]]
local scriptName        = 'moonSelectorIcons'
local scriptVersion     = ' 1.0'
return  {   
        active = true,
        on =    {  
                       devices         = {2479}, -- change to your device(s) separated by a comma like {2479,2480} 
                    },

  logging =   {  level    =   domoticz.LOG_DEBUG,                                             -- Seulement un niveau peut être actif; commenter les autres
                -- level    =   domoticz.LOG_INFO,                                            -- Only one level can be active; comment others
                -- level    =   domoticz.LOG_ERROR,
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker = scriptName..' v'..scriptVersion
                },

    execute = function(domoticz, item)
    
        local function logWrite(str,level)
            domoticz.log(tostring(str),level or domoticz.LOG_DEBUG)
        end
        local icons =     { -- level = iconNumber 
                            [10] = 129,-- level correspondant à Nouvelle lune
                            [20] = 130,-- level correspondant à Premier croissant
                            [30] = 131,-- level correspondant à Premier quartier
                            [40] = 132,-- level correspondant à Gibbeuse croissante
                            [50] = 133,-- level correspondant à Pleine lune
                            [60] = 134,-- level correspondant à Gibbeuse décroissante
                            [70] = 135,-- level correspondant à Dernier quartier
                            [80] = 136,-- level correspondant à Dernier croissant
                            --[80] = 137,
                        }
        
        local function setIcon(iconNumber) 
            local url = domoticz.settings['Domoticz url'] .. '/json.htm?type=setused&used=true&name=' .. domoticz.utils.urlEncode(item.name) ..
            '&description=' .. domoticz.utils.urlEncode(item.description) .. -- Required. If not set it will be blanked out.
            '&idx=' .. item.id .. 
            '&switchtype=' .. item.switchTypeValue ..
            '&customimage=' .. iconNumber
            logWrite(url)
            return domoticz.openURL(url)
        end    
        logWrite('lastLevel'.. tostring(item.lastLevel))
        logWrite('level'.. tostring(item.level))
        if item.level ~= item.lastLevel then 
            setIcon(icons[item.level])
        else
            domoticz.log('No Icon change necessary' .. item.id,domoticz.LOG_DEBUG)
        end
    end
}
