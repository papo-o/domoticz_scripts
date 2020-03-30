--[[poubelles.lua
Creation =28/03/2018
https://pon.fr/
https://easydomoticz.com/forum/
icones : https://github.com/papo-o/domoticz_scripts/poubelles.lua
update/mise à jour = 30/03/2020
Principe : afficher les jours de ramassage des differentes poubelles
--]]
local scriptName        = 'Poubelles'
local scriptVersion     = ' 1.02'

return {
    active = true,
        on  = {
            timer = { 'at 07:10 on tue', 'at 07:10 on wed', 'at 22:03 on wed' }
            },

    logging =   
    {   level    =   domoticz.LOG_INFO,                -- Seulement un niveau peut être actif; commenter les autres
        -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others
        -- level    =   domoticz.LOG_DEBUG,
        -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
        marker = scriptName..' v'..scriptVersion
            },

    execute = function(dz, timer)
        local function logWrite(str,level)
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end
        
        if (timer.trigger == 'at 07:10 on tue') then
            dz.devices('Poubelle Verte').switchOn().checkFirst()
            logWrite("Poubelle Verte à On")

        elseif (timer.trigger == 'at 07:10 on wed') then
            dz.devices('Poubelle Verte').switchOff().checkFirst()
            logWrite("Poubelle Verte à Off")
            dz.devices('Poubelle Bleue').switchOn().checkFirst()
            logWrite("Poubelle Bleue à On")

        elseif (timer.trigger == 'at 22:03 on wed') then
            dz.devices('Poubelle Verte').switchOff().checkFirst()
            logWrite("Poubelle Verte à Off")
            dz.devices('Poubelle Bleue').switchOff().checkFirst()
            logWrite("Poubelle Bleue à Off")
        end
    end
}
