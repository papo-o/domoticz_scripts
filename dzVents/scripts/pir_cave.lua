--[[
name : pir_cave.lua
auteur : papoo
creation : 10/11/2018
mise à jour : 24/11/2019
principe : Actionner 2s le télé-rupteur  de la cave avec un ou plusieurs détecteurs pir xiaomi

--]]



--local pir_cave ={"pir escalier cave", "pir cellier"}
local pir_cave = {"pir cellier", "pir Cellier","pir escalier cave"}
local lumiere_cave = "Lumiere cave"
local delai = 5 -- minimum 2 minutes
local scriptName        = 'Pir Cave'
local scriptVersion     = '1.04'

return {
    active = true,
    on = {
    -- devices = {"pir cellier", "pir escalier cave", "pir Cellier",}
    devices = pir_cave
    },

  logging =   { level    =   domoticz.LOG_DEBUG,                                             -- Seulement un niveau peut être actif; commenter les autres
                -- level    =   domoticz.LOG_INFO,                                            -- Only one level can be active; comment others
                -- level    =   domoticz.LOG_ERROR,
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker = scriptName..' v'..scriptVersion },

    execute = function(dz, item)

        local function logWrite(str,level)             -- Support function for shorthand debug log statements
        dz.log(tostring(str),level or dz.LOG_DEBUG)
        end

        --if (dz.devices(lumiere_cave).lastUpdate.minutesAgo > (delai-1)) then
        if dz.devices(lumiere_cave).active == false then
            logWrite("déclenchement "..item.name,dz.LOG_DEBUG)

            logWrite("allumage Lumière Cave ",dz.LOG_DEBUG)
            dz.devices(lumiere_cave).switchOn().checkFirst()
			dz.devices(lumiere_cave).switchOff().afterMin(delai)
			
        elseif 
                --dz.devices(lumiere_cave).active 
            --and 
			dz.devices(lumiere_cave).lastUpdate.minutesAgo < (delai -1) 
            and dz.devices(lumiere_cave).lastUpdate.minutesAgo > 1 
            then
				dz.devices(lumiere_cave).cancelQueuedCommands()
				dz.devices(lumiere_cave).switchOff().afterMin(delai)
                --dz.devices(lumiere_cave).switchOn().forMin(delai)
        else
            logWrite("aucune action nécessaire")
        end
        --end

    end
}
