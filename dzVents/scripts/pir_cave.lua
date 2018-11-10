--[[
name : pir_cave.lua
auteur : papoo
creation : 10/11/2018
mise à  jour : 10/11/2018
principe : Actionner 2s le télé-rupteur  de la cave avec un détecteur pir xiaomi
  
--]]



    local pir_cave ="pir cave"
    local lumiere_cave = "Lumiere cave"
   
return {
    active = true,
    on = {
    devices = {pir_cave}
    },    
   -- on = { devices = { "your trigger device" }},
        
  logging =   { -- level    =   domoticz.LOG_INFO,                                             -- Seulement un niveau peut être actif; commenter les autres
                -- level    =   domoticz.LOG_ERROR,                                            -- Only one level can be active; comment others
                -- level    =   domoticz.LOG_DEBUG,
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker    =   "Pir Cave v1.0 "      },
    
    execute = function(dz, item)

        if(item.name == pir_cave)then
            dz.log("déclenchement pir cave ",dz.LOG_DEBUG)
            if dz.devices(pir_cave).active then
                dz.log("allumage Lumière Cave ",dz.LOG_DEBUG)
                dz.devices(lumiere_cave).switchOn().forSec(2)
            end
        end

    end
}
