
-- v1.00 Auteur Remb0  https://gadget-freakz.com/2018/04/make-you-sunscreen-smart-with-dzvents-scripting/
-- v1.1 papoo traduction, suppression log csv, ajout notifications subsystem... 

-- Définir tous les capteurs qui doivent être pris en compte pour la fermeture du store
local sensors = {
    temperature = {
        active = true,
        device = 'Temperature exterieure',
        closeRule = function(device)
        return device.temperature <= 22
        end
        },
    wind = {
        active = true,
        device = 'Anémomètre',
        closeRule = function(device)
        return device.speed >= 50 or device.gust >= 150
        end
        },
    rain = {
        active = true,
        device = 'Pluviomètre',
        closeRule = function(device)
        return device.rainRate > 0
        end
        },
    rainExpected = {
        active = false,
        device = 'IsItGonnaRain', -- Ce doit être un capteur virtuel de type "pourcentage"
        closeRule = function(device)
        return device.percentage > 15
        end
        },
    uv = {
        active = true,
        device = 'UV Index',
        closeRule = function(device)
        return device.uv <= 2
        end
        },
    lux = {
        active = false,
        device = 'Lux',
        closeRule = function(device)
        return device.lux <= 500
        end
        }
}

local sunscreenDevice = 'Store' -- Définissez le nom de votre périphérique d'écran solaire (type on/off ou blind)
local dryRun = 'N'              -- Activer ce mode de fonctionnement (Y) pour tester le script de protection solaire sans activer réellement le store
                                
local manualOverrideSwitch = 'presences'-- Définissez le nom d'un commutateur virtuel que vous pouvez utiliser pour désactiver le script d'automatisation du store.
                                -- Définir sur false pour désactiver cette fonctionnalité
local timeBetweenOpens = 30     -- Minutes à attendre après la fermeture du store avant de l'ouvrir à nouveau.
local notification = "Y"  -- (Y) Active les notifications, (N) les désactive 
local SubSystem =   domoticz.NSS_TELEGRAM--[[ Systèmes de notification disponibles :
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
        -- level = domoticz.LOG_INFO,                                             -- Seulement un niveau peut être actif; commenter les autres
        -- level = domoticz.LOG_ERROR,
        level = domoticz.LOG_DEBUG,
        -- level = domoticz.LOG_MODULE_EXEC_INFO,
    marker = 'STORE v1.2 '
    },
    execute = function(domoticz)

    -- FUNCTIONS

    local function switchOn(sunscreen, message)
        if (sunscreen.state == 'Closed' or sunscreen.state == 'Off') then
            if dryRun == 'N' then
                sunscreen.switchOn()
                if notification == "Y" then
                    if SubSystem == nil then 
                        domoticz.notify('Store', message)
                    else
                        domoticz.notify('Store', message, '', '', '', SubSystem)
                    end 
                end
            end
            domoticz.log(message, domoticz.LOG_INFO)
        else
            domoticz.log('Le store est déjà baissé' , domoticz.LOG_INFO)
        end
    end

    local function switchOff(sunscreen, message)
        if (sunscreen.state == 'Open' or sunscreen.state == 'On') then
            if dryRun == 'N' then
                sunscreen.switchOff()
                if notification == "Y" then
                    if SubSystem == nil then 
                        domoticz.notify('Store', message)
                    else
                        domoticz.notify('Store', message, '', '', '', SubSystem)
                    end 
                end
            end
            domoticz.log(message, domoticz.LOG_INFO)
        end
    end

    -- PROGRAM STARTS

    if (manualOverrideSwitch and domoticz.devices(manualOverrideSwitch).state == 'On') then
        domoticz.log('Le script store automatique est désactivé manuellement', domoticz.LOG_DEBUG)
        return
    end

    local sunscreen = domoticz.devices(sunscreenDevice)
    -- Le store doit toujours être remonté pendant la nuit
    if (domoticz.time.isNightTime) then
        switchOff(sunscreen, 'Fermeture du store, c\'est la nuit')
        message = 'Fermeture du store, c\'est la nuit'
        return
    end
    -- Check all sensor tresholds and if any exeeded close sunscreen
    for sensorType, sensor in pairs(sensors) do
        if (sensor['active'] == true) then
            local device = domoticz.devices(sensor['device'])
            local closeRule = sensor['closeRule']
            domoticz.log('Checking sensor: ' .. sensorType, domoticz.LOG_DEBUG)
            if (closeRule(device)) then
                switchOff(sunscreen, sensorType .. ' seuil dépassé, remontée du store')
                domoticz.log(sensorType .. ' seuil dépassé', domoticz.LOG_DEBUG)
                message = (sensorType .. ' seuil dépassé')
                -- Return early when we exeed any tresholds
                return
            end
        else
            domoticz.log('Sonde non active ignorée : ' .. sensorType, domoticz.LOG_DEBUG)
        end
    end

    -- Tous les seuils sont corrects, le store peut être abaissé
    domoticz.log('Dernière action du store (en minutes) : ' .. sunscreen.lastUpdate.minutesAgo, domoticz.LOG_DEBUG)
    domoticz.log('Minutes à attendre après la fermeture du store avant de l\'ouvrir à nouveau : ' .. timeBetweenOpens, domoticz.LOG_DEBUG)
    if (sunscreen.lastUpdate.minutesAgo > timeBetweenOpens) then
        message = 'Le soleil brille, tous les seuils sont corrects, abaissement du store'
        switchOn(sunscreen, message)
    end

end
}