--[[XiaomiMP3.lua
source = https://www.domoticz.com/wiki/Xiaomi_Gateway_(Aqara)
https://pon.fr/
https://easydomoticz.com/forum/
github : https://github.com/papo-o/domoticz_scripts/xiaomiMP3.lua
update/mise à jour = 30/03/2020

--]]
local scriptName        = 'Xiaomi MP3'
local scriptVersion     = ' 2.00'

return {
    active  = true,
    on = {
        devices =   { 'Mid Value' }
    },

     logging =   
    {   level    =   domoticz.LOG_DEBUG,           -- Seulement un niveau peut être actif; commenter les autres
        -- level    =   domoticz.LOG_INFO,         -- Only one level can be active; comment others
        -- level    =   domoticz.LOG_ERROR,
        -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
        marker = scriptName..' v'..scriptVersion
    },

    execute = function(domoticz, item)
    
        local function logWrite(str,level)
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end

        Calcvalue = (tonumber(item.svalues) + 10000)
        dz.variables('XiaomiMP3').set( Calcvalue )
        logWrite('Xiaomi Gateway jouera le son stocké dans la banque '..Calcvalue)
        dz.devices('Xiaomi Gateway MP3').switchOn()

    end
}
