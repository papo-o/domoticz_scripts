--[[ moonSelectorIcons.lua
update/mise à jour = 15/10/2019
source : https://www.domoticz.com/forum/viewtopic.php?f=59&t=27501&p=210819&hilit=seticon#p210819
https://pon.fr/ddzvents-darksky-probabilite-de-vent-et-phases-lunaires/
https://easydomoticz.com/forum/viewtopic.php?f=10&t=8758&p=71951#p71951
pour afficher un icone personnalisé à chaque nouvelle phase lunaire il vous faut uploader 
(Réglages=>Plus d'options=> Icones personnalisés) sans les décompresserc hacun des packs d'icones suivants
dans l'ordre c'est plus facile : MoonPhases1NM, MoonPhases2WC, MoonPhases3FQ, etc
icones : https://github.com/papo-o/domoticz_scripts/tree/master/Icons/MoonPhases
pour connaitre le numero de chaque iconeuploadé, comptez vos icônes perso en commençant à 101 pour le premier
puis modifiez la référence des icones (129 à 136 dans ce script) pour afficher vos icones. 
ainsi que la (es) référence(s) au(x) device(s) selector (dans l'exemple ci dessous l'idx 2479)
 
--]]
local scriptName        = 'moonSelectorIcons'
local scriptVersion     = ' 1.01'
return  {   
        active = true,
        on =    {  
                       devices         = {2479}, -- change to your device(s) separated by a comma like {2479,2480} 
                    },

   logging =   {  level    =   domoticz.LOG_DEBUG,                                             -- Seulement un niveau peut être actif; commenter les autres
                -- -- level    =   domoticz.LOG_INFO,                                            -- Only one level can be active; comment others
                -- -- level    =   domoticz.LOG_ERROR,
                -- -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker = scriptName..' v'..scriptVersion
                },

    execute = function(dz, item)
    
        local function logWrite(str,level)
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end
		local icons =     { 
                            [10] = 129,-- level correspondant à Nouvelle lune MoonPhases1NM
                            [20] = 130,-- level correspondant à Premier croissant MoonPhases2WC
                            [30] = 131,-- level correspondant à Premier quartier MoonPhases3FQ
                            [40] = 132,-- level correspondant à Gibbeuse croissanteMoonPhases4WG
                            [50] = 133,-- level correspondant à Pleine lune MoonPhases5FM
                            [60] = 134,-- level correspondant à Gibbeuse décroissante MoonPhases6WG
                            [70] = 135,-- level correspondant à Dernier quartier MoonPhases7LQ
                            [80] = 136,-- level correspondant à Dernier croissant MoonPhases8WC
				}
        
        local function setIcon(iconNumber) 
            local url = dz.settings['Domoticz url'] .. '/json.htm?type=setused&used=true&name=' .. dz.utils.urlEncode(item.name) ..
            '&description=' .. dz.utils.urlEncode(item.description) .. -- Required. If not set it will be blanked out.
            '&idx=' .. item.id .. 
            '&switchtype=' .. item.switchTypeValue ..
            '&customimage=' .. iconNumber
            logWrite(url)
            return dz.openURL(url)
        end    
        logWrite('lastLevel'.. tostring(item.lastLevel))
        logWrite('level'.. tostring(item.level))
        if item.level ~= item.lastLevel then 
            setIcon(icons[item.level])
        else
            dz.log('No Icon change necessary' .. item.id,dz.LOG_DEBUG)
        end
    end
}
