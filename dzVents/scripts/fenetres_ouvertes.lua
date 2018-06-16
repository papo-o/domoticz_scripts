-- v1.00 Auteur papoo 
-- https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/fenetres_ouvertes.lua
-- https://pon.fr/dzvents-notification-fenetres-ouvertes-sur-risques-meteorologiques/
-- https://easydomoticz.com/forum/viewtopic.php?f=17&t=6649
-- Définir tous les capteurs et les seuils qui doivent être pris en compte pour la notification des fenêtres restées ouvertes 
local sensors = {

    vent = {
        active = true,
        device = 'Anémomètre',
        closeRule = function(device)
        return device.speed >= 50 or device.gust >= 100   -- vitesse et rafale
        end
        },
    pluie = {
        active = true,
        device = 'Pluviometre',
        closeRule = function(device)
        return device.rainRate > 0
        end
        },
    probabilite_pluie = {
        active = true,
        device = 'Proba Pluie 1h', -- Ce doit être un capteur virtuel de type "pourcentage"
        closeRule = function(device)
        return device.percentage > 30
        end
        },
    alerte_meteo = {
        active = false,
        device = 'Vigilance Météo', -- Ce doit être un capteur virtuel de type "Alerte"
        closeRule = function(device)
        return device.color > 2  -- vert = 0, jaune = 1, orange = 2, rouge = 3
        end
        },
    alerte_pluie = {
        active = true,
        device = 'Alerte Pluie', -- Ce doit être un capteur virtuel de type "Alerte"
        closeRule = function(device)
        return device.color > 1  -- vert = 0, jaune = 1, orange = 2, rouge = 3
        end
        }
 
}
local FENETRES = { 'fenetre douche', 'fenetre 2'} 
--local FENETRES = { 'fenetre*'} 
local SubSystem =   nil --domoticz.NSS_TELEGRAM --domoticz.NSS_PUSHBULLET 
                    --[[ Systèmes de notification disponibles :
                        NSS_GOOGLE_CLOUD_MESSAGING NSS_HTTP NSS_KODI NSS_LOGITECH_MEDIASERVER NSS_NMA NSS_PROWL NSS_PUSHALOT NSS_PUSHBULLET NSS_PUSHOVER NSS_PUSHSAFER
                        Pour une notification sur plusieurs systèmes, séparez les systèmes par une virgule et entourez l'ensemble par des {}.
                        Exemple :{domoticz.NSS_TELEGRAM, domoticz.NSS_HTTP}
                    --]]
local message = '.'

return {
    active = true,
    on = {
    timer = {'every minute'}
    },
    logging = {
        level = domoticz.LOG_INFO,                                             -- Seulement un niveau peut être actif; commenter les autres
        -- level = domoticz.LOG_ERROR,
        -- level = domoticz.LOG_DEBUG,
        -- level = domoticz.LOG_MODULE_EXEC_INFO,
    marker = 'NOTIFICATION FENETRES OUVERTES '
    },
    data    =   {   state                 = { initial = ""                  }},    -- thanks waaren for persistent data notification
                        
    execute = function(domoticz, _)
    local conditionDeviceState              = "Off"        
    -- FUNCTIONS
    local function notification(fenetre, message)

            domoticz.log("État state avant notif : "  .. domoticz.data.state,domoticz.LOG_DEBUG)
            domoticz.log("État condition avant notif : "  .. conditionDeviceState,domoticz.LOG_DEBUG)
            if conditionDeviceState ~= domoticz.data.state then
                domoticz.log("Envoi de la notification ",domoticz.LOG_INFO)
                if SubSystem == nil then 
                    domoticz.notify(fenetre, message)
                else
                    domoticz.notify(fenetre, message, '', '', '', SubSystem)
                end 
                domoticz.log(message, domoticz.LOG_INFO)
                domoticz.data.notificationSent = domoticz.time.raw      -- Store time of notification 
                domoticz.data.state = "On"
            else
                domoticz.log("Aucune notification à envoyer pour le moment",domoticz.LOG_INFO)        
            end
    end
    -- démarrage programme

local fenetres = domoticz.devices().filter(FENETRES)
fenetres.forEach(function(fenetre)
domoticz.log('état '.. fenetre.name ..' : ' .. fenetre.state, domoticz.LOG_DEBUG)
if fenetre.state == "On" or fenetre.state == "Open" then  

    for sensorType, sensor in pairs(sensors) do
        if (sensor['active'] == true) then
            local device = domoticz.devices(sensor['device'])
            local closeRule = sensor['closeRule']
            domoticz.log('Checking sensor: ' .. sensorType, domoticz.LOG_DEBUG)
            if (closeRule(device)) then
                domoticz.log(sensorType .. ' seuil dépassé', domoticz.LOG_INFO)
                domoticz.log('attention '.. fenetre.name ..' est resté ouverte', domoticz.LOG_INFO)
                conditionDeviceState = "On"
                notification('attention ',fenetre.name..' est resté ouverte ' .. sensorType .. ' seuil dépassé') 

                -- Retour anticipé au script en cas de seuil dépassé
                return
            end
        else
            domoticz.log('Sonde non active ignorée : ' .. sensorType, domoticz.LOG_DEBUG)
        end
    end
end    
end)-- forEach

            if domoticz.data.state ~= conditionDeviceState then   -- il y a changement d'état?
               domoticz.data.state = conditionDeviceState
            else
            domoticz.log("Reset state non nécessaire",domoticz.LOG_DEBUG)
            end
            domoticz.log("État state: "  .. domoticz.data.state,domoticz.LOG_DEBUG)
            domoticz.log("État condition: "  .. conditionDeviceState,domoticz.LOG_DEBUG)    

end
}
