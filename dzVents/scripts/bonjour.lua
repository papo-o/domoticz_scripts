
--[[ bonjour.lua
    
auteur = papoo
update/mise à jour = 10/01/2019
creation = 5/11/2018
--]]

--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------

local messages = {  " Bienvenue chez toi", 
                    " Heureux de te revoir", 
                    " il est bon de te voir rentrer", 
                    " vraiment heureux de te savoir à la maison", 
                    " super, tu es rentré", 
                    " cool, tu es déjà de retour",
                    " enfin à la maison"
                 }
local Devices = { 'Presence*' }     -- liste des devices à surveiller séparés par des virgules s'il y en a  plusieurs
local matin         = '08:00:00'    -- aucun message ne sera envoyé avant cette heure (+1 heure pour l'heure d'hiver)
local debut_soiree  = '19:00:00'    -- heure après laquelle il sera notifié bonsoir au lieu de bonjour (+1 heure pour l'heure d'hiver)
local soir          = '22:00:00'    -- aucun message ne sera envoyé après cette heure (+1 heure pour l'heure d'hiver)
local delai         = 60            -- délai avant que le script considère la personne réellement partie

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nomScript = 'Notification Bonjour'
local versionScript = '1.0'

return {
    active = true,
    on = { devices = Devices },
    
    logging =   {    level    =   domoticz.LOG_DEBUG,
                    -- level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others    
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,

                    marker = nomScript..' '..versionScript },    

    execute = function(domoticz,switch)
    
    
        local Time = require('Time')
        local t = Time().getISO()
        local today = Time(domoticz.time.rawDate ..' '..  matin).getISO()
        local evening = Time(domoticz.time.rawDate ..' '..  debut_soiree).getISO()
        local tonight = Time(domoticz.time.rawDate ..' '.. soir).getISO()
        
        if switch.active and (switch.lastUpdate.minutesAgo > delai) and (t > today) and (t < tonight) then      
        
            local function notification(message, SubSystem)
                domoticz.log("Envoi de la notification ",domoticz.LOG_DEBUG)
                if SubSystem == nil then 
                   domoticz.notify(message, message)
                else
                   domoticz.notify(message, message, 'PRIORITY_NORMAL', ' ', ' ', SubSystem)
                end 
                domoticz.log(message, domoticz.LOG_INFO)
            end
            
            local function rand(Table)
                element = Table[math.random(1, #Table)]
                return element
            end
          
            message = rand(messages)

            domoticz.log(switch.name, domoticz.LOG_DEBUG) 
            local nom = string.gsub(switch.name, 'Presence ', '')
            domoticz.log("bonjour "..nom, domoticz.LOG_DEBUG)
            domoticz.log(message, domoticz.LOG_DEBUG)
            domoticz.log("heure "..t, domoticz.LOG_DEBUG)
            domoticz.log("matin "..today, domoticz.LOG_DEBUG)
            domoticz.log("soir "..tonight, domoticz.LOG_DEBUG)
            if t < evening then
                notification("Bonjour "..nom..", "..message, {domoticz.NSS_HTTP})
                    --[[ Systèmes de notification disponibles :
                        NSS_GOOGLE_CLOUD_MESSAGING NSS_HTTP NSS_KODI NSS_LOGITECH_MEDIASERVER NSS_NMA NSS_PROWL NSS_PUSHALOT NSS_PUSHBULLET NSS_PUSHOVER NSS_PUSHSAFER
                        Pour une notification sur plusieurs systèmes, séparez les systèmes par une virgule.
                        Exemple :{domoticz.NSS_TELEGRAM, domoticz.NSS_HTTP}
                    --]]
            else
            notification("Bonsoir "..nom.." "..message, {domoticz.NSS_HTTP})
                    --[[ Systèmes de notification disponibles :
                        NSS_GOOGLE_CLOUD_MESSAGING NSS_HTTP NSS_KODI NSS_LOGITECH_MEDIASERVER NSS_NMA NSS_PROWL NSS_PUSHALOT NSS_PUSHBULLET NSS_PUSHOVER NSS_PUSHSAFER
                        Pour une notification sur plusieurs systèmes, séparez les systèmes par une virgule.
                        Exemple :{domoticz.NSS_TELEGRAM, domoticz.NSS_HTTP}
                    --]]
            end
        end
   end   
}
