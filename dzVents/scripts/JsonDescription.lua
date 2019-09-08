
--[[
original script by rrozema Generic auto-off : https://www.domoticz.com/forum/viewtopic.php?f=72&t=23717&p=205159&hilit=auto+off#p201976
author = papoo
maj : 08/09/2019
this version need a waaren script, Universal function notification :
https://www.domoticz.com/forum/viewtopic.php?f=59&t=26542#p204958
https://pon.fr/dzvents-fonction-de-notification-universelle/

blog url : https://pon.fr/dzvents-script-de-notification-ultime-mais-pas-que
forum url : https://easydomoticz.com/forum/viewtopic.php?f=17&t=8167
github url : https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/JsonDescription.lua


This script will run every minute and can automatically send an 'Off' command to turn off any device after
it has been on for some specified time. Each device can be individually configured by putting json coded
settings into the device's description field. The settings currently supported are:
- "auto_off_minutes" : <time in minutes>
- "auto_off_motion_device" : "<name of a motion detection device>"
If "auto_off_minutes" is not set, the device will never be turned off by this script. If
"auto_off_minutes" is set and <time in minutes> is a valid number, the device will be turned off when it
is found to be on plus the device's lastUpdate is at least <time in minutes> minutes old. This behavior
can be further modified by specifying a valid device name after "auto_off_motion_device". When a motion
device is specified and the device's lastUpdate is at least <time in minutes> old, the device will not
be turned off until the motion device is off and it's lastUpdate is also <time in minutes> old.
Specifying "auto_off_motion_device" without specifying "auto_off_minutes" does nothing.

Example 1:
turn off the device after 2 minutes :
Exemple 1 :
éteindre l'appareil après 2 minutes :
{
"auto_off_minutes": 2
}

Example 2:
turn off the device when it has been on for 5 minutes and no motion has been detected by
    the "Overloop: Motion" device :
Exemple 2 : éteindre l'appareil lorsqu'il est allumé depuis 5 minutes et qu'aucun mouvement n'a été détecté par
    le dispositif "Overloop: Motion":

{
"auto_off_minutes": 5,
"auto_off_motion_device": "Overloop: Motion"
}

Example 3: turn off the device when it has been on for 2 minutes and no motion has been detected by
    either of the "Overloop: Motion" or the "Trap: Motion" devices:
exemple 3: éteindre l'appareil lorsqu'il est allumé depuis 2 minutes et qu'aucun mouvement n'a été détecté par
    l’un des dispositifs "Overloop: Motion" ou "Trap: Motion":

{
"auto_off_minutes": 2,
"auto_off_motion_device": {"Overloop": "Motion", "Trap": "Motion"}
}

With this new version you can :
    - be notified if temperature and or hygrometry exceed min or max threshold.
    - be notified if device is on, off or out
    you can mix the desired notifications, such as only the maximum temperature rise,
    or the minimum and maximum humidity, or do not set quiet hours, or minimum temperature and timout
    if you want to use the notification functions, the frequency of notifications is necessary
Avec cette nouvelle version vous pouvez :
    - être averti après le délai défini si la température et / ou l'hygrométrie dépassent le seuil minimal ou maximal.
    - être averti si un périphérique est allumé, éteint ou hors service
    vous pouvez mélanger les notifications souhaitées, telles que uniquement le dépassement de température maxi,
    ou  l'hygrométrie mini et maxi, ou ne pas définir d'heures calmes, ou température mini et timeout
    si vous souhaitez utiliser les fonctions de notification,  la fréquence de notifications est nécessaire


Example 4 : be notified if temperature or hygrometry exceed min or max threshold for a number of minutes
    with notifications frequency in minutes and quiet hours notification
Exemple 4 : être averti si la température ou l'hygrométrie dépasse les seuils minimal ou maximal pendant un certain nombre de minutes
    avec fréquence de notifications en minutes et notification des heures calmes

{
 "low_threshold_temp": 10,
 "high_threshold_temp": 40,
 "duration_exceeded_temp": 20,
 "low_threshold_hr": 25,
 "high_threshold_hr": 75,
 "duration_exceeded_hr": 20,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }

Example 5 : be notified if device is on since x minutes
    with notifications frequency in minutes and quiet hours notification
Exemple 5 : être averti si le périphérique est allumé depuis x minutes
    avec fréquence de notifications en minutes et notification des heures calmes

  {
 "time_active_notification": 120,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }

Example 6 : be notified if device is off since x minutes
    with notifications frequency in minutes and quiet hours notification
Exemple 6 : être averti si le périphérique est éteint depuis x minutes
    avec fréquence de notifications en minutes et notification des heures calmes

  {
 "time_inactive_notification": 2,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }

Example 7 : be notified if device is out since x minutes
    with notifications frequency in minutes and quiet hours notification
Exemple 7 : être averti si le périphérique est hors service depuis x minutes
    avec fréquence de notifications en minutes et notification des heures calmes

 {
"timeout_notification": 1440,
"frequency_notifications": 60,
"quiet_hours":"23:00-07:15"
  }

Example 8 : be notified if a device% exceeds the minimum or maximum thresholds
    with frequency of notifications in minutes and notification of quiet hours
Exemple 8 : être averti si un périphérique % dépasse les seuils minimal ou maximal
    avec fréquence de notifications en minutes et notification des heures calmes

  {
 "low_threshold_percent": 10,
 "high_threshold_percent": 40,
 "duration_exceeded_percent": 20,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }

Example 9 : be notified if a Custom Sensor device exceeds the minimum or maximum thresholds
    with frequency of notifications in minutes and notification of quiet hours
Exemple 9 :être averti si un périphérique Custom Sensor dépasse les seuils minimal ou maximal
    avec fréquence de notifications en minutes et notification des heures calmes

  {
 "low_threshold_custom": 1000,
 "high_threshold_custom": 4000,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }


Example 10: Be notified if an Alert device exceeds a predefined threshold (1,2,3 or 4)
    with frequency of notifications in minutes and notification of quiet hours
Exemple 10 : être averti si un périphérique Alert dépasse un seuil prédéfini (1,2,3 ou 4)
    avec fréquence de notifications en minutes et notification des heures calmes

  {
 "high_threshold_color": 4,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }
========================================================
Fonctionnalités proposées par denis_brasseur

Example 11: Be notified if a device's battery is below a low threshold
    with frequency of notifications in minutes and notification of quiet hour
Exemple 11 : être averti si la batterie d'un périphérique est inférieure un seuil bas
    avec fréquence de notifications en minutes et notification des heures calmes

  {
 "low_battery_level": 30,
 "high_threshold_temp": -15,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }


Example 12: Be notified if the signal level (zwave, rfxcom) of a device is below a low threshold
    with frequency of notifications in minutes and notification of quiet hour
Exemple 12 : être averti si le niveau de signal (zwave, rfxcom) d'un périphérique est inférieure un seuil bas
    avec fréquence de notifications en minutes et notification des heures calmes

  {
 "low_signal_level": 2,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }


Example 13: Be notified if a power device exceeds a high threshold or a low threshold set
Exemple 13 : être averti si un périphérique puissance dépasse un seuil haut ou un seuil bas défini

  {
 "low_watt_usage": 0,
 "high_watt_usage": 10000,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }

 Example 14: Be notified if an intensity device exceeds a high threshold or a low threshold set
 Exemple 14 : être averti si un périphérique intensité dépasse un seuil haut ou un seuil bas défini

  {
 "low_current_usage": 0,
 "high_current_usage": 60,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }

  Example 15 : turn on the device after x minutes:
  Exemple 15 : allumer l'appareil après x minutes:

{
"auto_on_minutes": 1
}
========================================================

Example 16 : be notified if device is off since x minutes
    with notifications frequency in minutes and quiet hours notification only on telegram notifications
    Notification systems available:
    GOOGLE_CLOUD_MESSAGING, HTTP, KODI, LOGITECH_MEDIASERVER, NMA, PROWL, PUSHALOT, PUSHBULLET,PUSHOVER, PUSHSAFER, TELEGRAM
Exemple 16 : être averti si le périphérique est éteint depuis x minutes
    avec fréquence de notifications en minutes et notification des heures calmes seulement via les notifications TELEGRAM
    Systèmes de notification disponibles :
    GOOGLE_CLOUD_MESSAGING, HTTP, KODI, LOGITECH_MEDIASERVER, NMA, PROWL, PUSHALOT, PUSHBULLET,PUSHOVER, PUSHSAFER, TELEGRAM

  {
  "subsystems" : "TELEGRAM",
 "time_inactive_notification": 2,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }

Example 17 : be notified if device is off since x minutes
    with notifications frequency in minutes and quiet hours notification only on TELEGRAM and PUSHBULLET notifications
    Notification systems available:
    GOOGLE_CLOUD_MESSAGING, HTTP, KODI, LOGITECH_MEDIASERVER, NMA, PROWL, PUSHALOT, PUSHBULLET,PUSHOVER, PUSHSAFER, TELEGRAM
    For multi-system notification, separate the systems with a comma.
Exemple 17 : être averti si le périphérique est éteint depuis x minutes
    avec fréquence de notifications en minutes et notification des heures calmes seulement via les notifications TELEGRAM et PUSHBULLET
    Systèmes de notification disponibles :
    GOOGLE_CLOUD_MESSAGING, HTTP, KODI, LOGITECH_MEDIASERVER, NMA, PROWL, PUSHALOT, PUSHBULLET,PUSHOVER, PUSHSAFER, TELEGRAM
    Pour une notification sur plusieurs systèmes, séparez les systèmes par une virgule.

  {
  "subsystems" : "TELEGRAM,PUSHBULLET",
 "time_inactive_notification": 2,
 "frequency_notifications": 60,
 "quiet_hours":"23:00-07:15"
  }

  Example 18 : dim a light at define level(s) and time(s) 
  exemple 18  : moduler une lumière à niveau(x) et heure(s) définis
  {
  "dimTo" : {"level" : 50, "hour" : "16:01", "level" : 0, "hour" : "16:05", "level" : 75, "hour" : "16:07"}
  }
  
--]]

local scriptName = 'Json Description'
local scriptVersion = '1.04'

return {
    active = true,
    on = {

        -- timer triggers
        timer = {
            'every minute'
        }
    },

    -- custom logging level for this script
    logging = {
                -- level    =   domoticz.LOG_DEBUG,
                 level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker = scriptName..' v'..scriptVersion
   },
    -- permet de stocker les valeurs des périphériques avec "duration_exceeded_" sous /home/pi/domoticz/scripts/dzVents/data/__data_JsonDescription.lua
   data = {
        managedValue = { history = true, maxItems = 3600, maxHours = 6 },
        managedId = { history = true, maxItems = 3600, maxHours = 6 },
    },
    execute = function(domoticz, triggeredItem, info)
        local cnt = 0
        local now = domoticz.time
        local minute
        if string.len(now.min) == 1 then minute = '0'..now.min else minute = now.min end
        local Time = now.hour..":"..minute

        --permet de lire les valeurs des périphériques avec "duration_exceeded_temp", "low_threshold_hr", "high_threshold_hr" ou  "duration_exceeded_hr"
        local function managed(domoticz, id, duration_exceeded, high_threshold, low_threshold)
            test_high_threshold = true
            test_low_threshold = true
            x = 0
            domoticz.data.managedId.forEach(
                function(item)
                    x = x + 1
                    if item.data == id then
                        timeNotif = tonumber(item.time.minutesAgo)
                        local value = domoticz.data.managedValue.get(x)
                        if timeNotif < duration_exceeded then -- on test si l'ancienneté de la valeur est < à la valeur duration_exceeded_temp
                            if high_threshold ~= nil then -- si la value est < à la valeur de ref, on passe la variable à false => pas d'envoi de notification
                                if value.data <= high_threshold then test_high_threshold = false end
                            end
                            if low_threshold ~= nil then -- si la value est > à la valeur de ref, on passe la variable à false => pas d'envoi de notification
                                if value.data >= low_threshold then test_low_threshold = false end
                            end
                        end
                    end
                end
            )
            return test_high_threshold, test_low_threshold

        end
        
        local function split(s, delimiter)
        if s ~= nil then
            result = {};
            for match in (s..delimiter):gmatch("(.-)"..delimiter) do
                table.insert(result, match);
            end
        else
            result = {""};
        end
        return result;
        end

        local function notificationTable(str)
        --NSS_GOOGLE_CLOUD_MESSAGING, NSS_HTTP, NSS_KODI, NSS_LOGITECH_MEDIASERVER, NSS_NMA,NSS_PROWL, NSS_PUSHALOT, NSS_PUSHBULLET, NSS_PUSHOVER, NSS_PUSHSAFER, NSS_TELEGRAM
            if (str) then
            str = string.gsub (str,"GCM", domoticz.NSS_GOOGLE_CLOUD_MESSAGING)
            str = string.gsub (str,"GOOGLE_CLOUD_MESSAGING", domoticz.NSS_GOOGLE_CLOUD_MESSAGING)
            str = string.gsub (str,"HTTP", domoticz.NSS_HTTP)
            str = string.gsub (str,"LMS", domoticz.NSS_LOGITECH_MEDIASERVER)
            str = string.gsub (str,"LOGITECH_MEDIASERVER", domoticz.NSS_LOGITECH_MEDIASERVER)
            str = string.gsub (str,"NMA", domoticz.NSS_NMA)
            str = string.gsub (str,"PROWL", domoticz.NSS_PROWL)
            str = string.gsub (str,"PUSHALOT", domoticz.NSS_PUSHALOT)
            str = string.gsub (str,"PUSHOVER", domoticz.NSS_PUSHOVER)
            str = string.gsub (str,"PUSHSAFER", domoticz.NSS_PUSHSAFER)
            str = string.gsub (str,"PUSHBULLET", domoticz.NSS_PUSHBULLET)
            str = string.gsub (str,"TELEGRAM", domoticz.NSS_TELEGRAM)
            end
        return (split(str,','))
        end

        local subject               = "\xE2\x9A\xA0 /!\\ Attention /!\\ \xE2\x9A\xA0"           -- sujet des notifications

        domoticz.devices().forEach(
            function(device)
                cnt = cnt + 1
                local frequency_notifications = nil
                local quiet_hours = nil
                local message = nil
                local subSystems = nil

                local description = device.description
                local j = string.find(tostring(description), '^{.*}$')

                if description ~= nil and description ~= '' and j ~= nil then

                    local ok, settings = pcall( domoticz.utils.fromJSON, description)
                    if ok and settings then

                        if settings.subsystems ~= nil then -- systeme(s) de notification
                            subSystems = settings.subsystems
                            domoticz.log('le(s) systeme(s) de notification pour '.. device.name .. ' est(sont)  ' .. subSystems, domoticz.LOG_DEBUG)
                        end


                        if settings.frequency_notifications ~= nil then -- fréquence de notification
                            frequency_notifications = settings.frequency_notifications
                            domoticz.log('la fréquence de notification pour '.. device.name .. ' est de  ' .. settings.frequency_notifications.." minutes", domoticz.LOG_DEBUG)
                        end

                        if settings.quiet_hours ~= nil then -- période silencieuse
                            quiet_hours = settings.quiet_hours
                            domoticz.log('la période silencieuse de notification pour '.. device.name .. ' est définie entre  ' .. quiet_hours, domoticz.LOG_DEBUG)
                        end
                        
                        if settings.auto_off_motion_device ~= nil then -- 
                            domoticz.log(device.name .. ' AutoOff type : ' .. type(settings.auto_off_motion_device), domoticz.LOG_DEBUG)
                            if type(settings.auto_off_motion_device) == "string" then
                                domoticz.log(device.name .. ' est asservie au device : ' .. settings.auto_off_motion_device, domoticz.LOG_DEBUG)
                            elseif type(settings.auto_off_motion_device) == "table" then
                                domoticz.log(device.name .. ' AutoOff type : ' .. type(settings.auto_off_motion_device), domoticz.LOG_DEBUG)
                                local devices = ""
                                local types = ""
                                for i,v in pairs(settings.auto_off_motion_device) do
                                    
                                devices = devices .. v ..", "
                                types = types .. i ..", "
                                
                                end
                                domoticz.log(device.name .. ' est asservie aux devices : ' .. devices, domoticz.LOG_DEBUG)
                                domoticz.log('de type : ' .. types, domoticz.LOG_DEBUG)
                            end
                        end

                        if settings.dimTo ~= nil then -- 
                            if type(settings.dimTo) == "string" then
                                domoticz.log(device.name .. ' impossible de traiter la fonction dimTo manque un élément', domoticz.LOG_DEBUG)
                            elseif type(settings.dimTo) == "table" then

                                local params = ""
                                local types = ""
                                for i,v in pairs(settings.dimTo) do
                                    
                                params = params .. v ..", "
                                types = types .. i ..", "
                                
                                end
                                domoticz.log(device.name .. ' a pour paramètres : ' .. params, domoticz.LOG_DEBUG)
                                domoticz.log('de type : ' .. types, domoticz.LOG_DEBUG)
                            end
                        end

                        if device.temperature ~= nil and settings.high_threshold_temp ~= nil then  -- seuil haut température
                            domoticz.log(device.name .. ' a un seuil temperature haute défini à  ' .. settings.high_threshold_temp..'°C', domoticz.LOG_DEBUG)
                        end

                        if device.temperature ~= nil and settings.low_threshold_temp ~= nil then  -- seuil bas température
                            domoticz.log(device.name .. ' a un seuil temperature basse défini à  ' .. settings.low_threshold_temp..'°C', domoticz.LOG_DEBUG)
                        end

                        if device.percentage ~= nil and settings.high_threshold_percent ~= nil then  -- seuil haut %
                            domoticz.log(device.name .. ' a un seuil % haut défini à  ' .. settings.high_threshold_percent..'%', domoticz.LOG_DEBUG)
                        end

                        if device.percentage ~= nil and settings.low_threshold_percent ~= nil then  -- seuil bas %
                            domoticz.log(device.name .. ' a un seuil % bas défini à  ' .. settings.low_threshold_percent..'%', domoticz.LOG_DEBUG)
                        end

                        --sensorType
                        if device.sensorType ~= nil and settings.high_threshold_custom ~= nil then  -- seuil haut sensorType
                            domoticz.log(device.name .. ' a un seuil haut défini à  ' .. settings.high_threshold_custom..' '..device.sensorUnit, domoticz.LOG_DEBUG)
                        end

                        if device.sensorType ~= nil and settings.low_threshold_custom ~= nil then  -- seuil bas sensorType
                            domoticz.log(device.name .. ' a un seuil bas défini à  ' .. settings.low_threshold_custom..' '..device.sensorUnit, domoticz.LOG_DEBUG)
                        end

                        --low_watt_usage
                        if device.WhActual ~= nil and settings.low_watt_usage ~= nil then  -- seuil bas sensorType
                            domoticz.log(device.name .. ' a un seuil bas défini à  ' .. settings.low_watt_usage..' Wh', domoticz.LOG_DEBUG)
                        end

                        if device.WhActual ~= nil and settings.high_watt_usage ~= nil then  -- seuil bas sensorType
                            domoticz.log(device.name .. ' a un seuil haut défini à  ' .. settings.high_watt_usage..' Wh', domoticz.LOG_DEBUG)
                        end

                        if device.current ~= nil and settings.low_current_usage ~= nil then  -- seuil bas sensorType
                            domoticz.log(device.name .. ' a un seuil bas défini à  ' .. settings.low_current_usage..' A', domoticz.LOG_DEBUG)
                        end

                        if device.current ~= nil and settings.high_current_usage ~= nil then  -- seuil bas sensorType
                            domoticz.log(device.name .. ' a un seuil haut défini à  ' .. settings.high_current_usage..' A', domoticz.LOG_DEBUG)
                        end
                        --=========================================================================================================================
                        if device.level ~= nil and settings.dimToLevel ~= nil and settings.dimToHour ~= nil then  -- seuil bas sensorType
                            domoticz.log(device.name .. ' a un changement de luminosité défini à  ' .. settings.dimToLevel..' a '..settings.dimToHour, domoticz.LOG_DEBUG)
                        end
                        --=========================================================================================================================

                        if device.state == 'Off' or device.state == 'Close' then    -- Alarme dispositif inactif
                            if settings.time_active_notification ~= nil then
                                domoticz.log('Le délai est fixé à '.. settings.time_active_notification.. ' minutes.', domoticz.LOG_DEBUG)
                            end
                        elseif device.state == 'On' or device.state == 'Open' then   -- Alarme dispositif actif
                            if settings.time_inactive_notification ~= nil then
                                domoticz.log('Le délai est fixé à '.. settings.time_inactive_notification.. ' minutes.', domoticz.LOG_DEBUG)
                            end
                        end

                        -- Alarme dispositif injoignable
                        if settings.timeout_notification and device.timedOut then
                            domoticz.log(device.name .. ' est injoignable. Sa dernière activité remonte à ' .. device.lastUpdate.minutesAgo .. ' minutes.', domoticz.LOG_INFO)
                            message = device.name .. ' est injoignable depuis '.. tostring(settings.timeout_notification) ..' minutes'
                            domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                        end

                        --batterie
                        if device.batteryLevel ~= nil and device.batteryLevel ~= 255 and settings.low_battery_level ~= nil then
                            domoticz.log('Le niveau de batterie de '.. device.name .. ' est de  ' .. device.batteryLevel .. '%', domoticz.LOG_INFO)
                            if settings.low_battery_level ~= nil and device.batteryLevel < settings.low_battery_level then  -- seuil bas batterie
                                domoticz.log(device.name .. ' a un niveau de batterie de ' .. device.batteryLevel..'%', domoticz.LOG_INFO)
                                message = 'Le niveau de batterie '.. device.name .. ' est inférieur au seuil défini ('..settings.low_battery_level..'%). Valeur : '..tostring(domoticz.utils.round(device.batteryLevel, 1)) ..'%'
                                --domoticz.log(message, domoticz.LOG_INFO)
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end
                        end

                        --low_signal_level
                        if device.signalLevel ~= nil and settings.low_signal_level ~= nil then
                            domoticz.log('Le niveau de signal de '.. device.name .. ' est de  ' .. device.signalLevel, domoticz.LOG_INFO)
                            if settings.low_signal_level ~= nil and device.signalLevel < settings.low_signal_level then  -- seuil bas signal
                                domoticz.log(device.name .. ' a un niveau de signal de ' .. device.signalLevel, domoticz.LOG_INFO)
                                message = 'Le niveau de signal '.. device.name .. ' est inférieur au seuil défini ('..settings.low_signal_level..'). Valeur : '..device.signalLevel
                                --domoticz.log(message, domoticz.LOG_INFO)
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end
                        end

                        --low_watt_usage
                        if device.WhActual ~= nil and settings.low_watt_usage ~= nil then
                            domoticz.log('Le niveau de puissance de '.. device.name .. ' est de  ' .. device.WhActual..' Wh', domoticz.LOG_INFO)
                            if settings.low_watt_usage ~= nil and device.WhActual < settings.low_watt_usage then  -- seuil bas puissance
                                domoticz.log(device.name .. ' a un niveau de puissance de ' .. device.WhActual..' Wh', domoticz.LOG_INFO)
                                message = 'Le niveau de puissance '.. device.name .. ' est inférieur au seuil défini ('..settings.low_watt_usage..'). Valeur : '..device.WhActual..' Wh'
                                --domoticz.log(message, domoticz.LOG_INFO)
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end
                        end

                        if device.WhActual ~= nil and settings.high_watt_usage ~= nil then
                            domoticz.log('Le niveau de puissance de '.. device.name .. ' est de  ' .. device.WhActual..' Wh', domoticz.LOG_INFO)
                            if settings.high_watt_usage ~= nil and device.WhActual > settings.high_watt_usage then  -- seuil haut puissance
                                domoticz.log(device.name .. ' a un niveau de puissance de ' .. device.WhActual..' Wh', domoticz.LOG_INFO)
                                message = 'Le niveau de puissance '.. device.name .. ' est superieur au seuil défini ('..settings.high_watt_usage..'). Valeur : '..device.WhActual..' Wh'
                                --domoticz.log(message, domoticz.LOG_INFO)
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end
                        end

                        --low_current_usage
                        if device.current ~= nil and settings.low_current_usage ~= nil then
                            domoticz.log('Le niveau de '.. device.name .. ' est de  ' .. tostring(domoticz.utils.round(device.current, 0))..' A', domoticz.LOG_INFO)
                            if settings.low_current_usage ~= nil and device.current < settings.low_current_usage then  -- seuil bas intensite
                                domoticz.log(device.name .. ' a un niveau de ' .. tostring(domoticz.utils.round(device.current, 0)), domoticz.LOG_INFO)
                                message = 'Le niveau de '.. device.name .. ' est inférieur au seuil défini ('..settings.low_current_usage..'). Valeur : '..tostring(domoticz.utils.round(device.current, 0))..' A'
                                --domoticz.log(message, domoticz.LOG_INFO)
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end
                        end

                        --current
                        if device.current ~= nil and settings.high_current_usage ~= nil then
                            
                            if settings.high_current_usage ~= nil and device.current > settings.high_current_usage then  -- seuil haut intensite
                                domoticz.log(device.name .. ' a un niveau de ' .. tostring(domoticz.utils.round(device.current, 0)), domoticz.LOG_INFO)
                                message = 'Le niveau '.. device.name .. ' est superieur au seuil défini ('..settings.high_current_usage..'). Valeur : '..tostring(domoticz.utils.round(device.current, 0))..' A'
                                --domoticz.log(message, domoticz.LOG_INFO)
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end
                        end

                        --dimTo
                        if device.level ~= nil and settings.dimTo ~= nil then 
                            local dimToLevel
                            local dimToHour
                            if type(settings.dimTo) == "table" then
                                for i,v in pairs(settings.dimTo) do
                                    if i == "hour" then dimToHour = v 
                                    domoticz.log(device.name .. ' a une heure de variation fixée à : ' .. dimToHour, domoticz.LOG_INFO)
                                    elseif i == "level" then dimToLevel = v
                                    domoticz.log(device.name .. ' a une niveau de variation fixée à : ' .. dimToLevel, domoticz.LOG_INFO)
                                    end
                                    if Time == dimToHour and dimToLevel ~= nil then device.dimTo(dimToLevel) end
                                end
                            end
                        end

                        if device.state == 'Off' or device.state == 'Close' then
                         -- Alarme dispositif inactif
                            domoticz.log(device.name .. ' est à l\'état ' .. device.state, domoticz.LOG_INFO)
                            if settings.time_inactive_notification ~= nil and device.lastUpdate.minutesAgo >= settings.time_inactive_notification then
                                domoticz.log(device.name .. ' est inactif depuis ' .. device.lastUpdate.minutesAgo .. ' minutes. Le délai est fixé à '.. settings.time_inactive_notification.. ' minutes.', domoticz.LOG_INFO)
                                message = 'Le délai d\'inactivité fixé à '.. settings.time_inactive_notification .. ' minutes pour '.. device.name .. ' est dépassé'
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end

                        elseif device.temperature ~= nil or device.humidity ~= nil then
                        -- Alarme température
                            if device.temperature ~= nil and (settings.low_threshold_temp ~= nil or settings.high_threshold_temp ~= nil)  then
                                --test settings.duration_exceeded_temp
                                test_high_threshold = true
                                test_low_threshold = true
                                if settings.duration_exceeded_temp ~= nil then
                                    domoticz.data.managedValue.add(domoticz.utils.round(device.temperature, 2))
                                    domoticz.data.managedId.add(device.id)
                                    if settings.high_threshold_temp ~= nil then high_threshold_temp = settings.high_threshold_temp else high_threshold_temp = nil end
                                    if settings.low_threshold_temp ~= nil then low_threshold_temp = settings.low_threshold_temp else low_threshold_temp = nil end
                                    test_high_threshold, test_low_threshold = managed(domoticz, device.id, settings.duration_exceeded_temp, high_threshold_temp, low_threshold_temp)
                                end
                                domoticz.log('La température mesurée par '.. device.name .. ' est de  ' .. tostring(domoticz.utils.round(device.temperature, 1)) ..'°C', domoticz.LOG_INFO)
                                if settings.low_threshold_temp ~= nil and device.temperature < settings.low_threshold_temp and test_low_threshold == true then  -- seuil bas température
                                    domoticz.log(device.name .. ' a un seuil temperature basse défini à  ' .. settings.low_threshold_temp..'°C', domoticz.LOG_INFO)
                                    message = 'La température mesurée par '.. device.name .. ' est inférieure au seuil défini ('..settings.low_threshold_temp..'°C)' --. Valeur : '..tostring(domoticz.utils.round(device.temperature, 1)) ..'°C'
                                    if settings.duration_exceeded_temp ~= nil then
                                        domoticz.data.managedValue.add(settings.low_threshold_temp)
                                        domoticz.data.managedId.add(device.id)
                                    end
                                    domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                                end
                                if settings.high_threshold_temp ~= nil and device.temperature > settings.high_threshold_temp and test_high_threshold == true then  -- seuil haut température
                                    domoticz.log(device.name .. ' a un seuil temperature haute défini à  ' .. settings.high_threshold_temp..'°C', domoticz.LOG_INFO)
                                    message = 'La température mesurée par '.. device.name ..' est supérieure au seuil défini ('..settings.high_threshold_temp..'°C)' --. Valeur : '..tostring(domoticz.utils.round(device.temperature, 1)) ..'°C'
                                    if settings.duration_exceeded_temp ~= nil then
                                        domoticz.data.managedValue.add(settings.high_threshold_temp)
                                        domoticz.data.managedId.add(device.id)
                                    end
                                    domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                                end
                            end

                        -- alarme hygrométrie
                            if device.humidity ~= nil and (settings.low_threshold_hr ~= nil or settings.high_threshold_hr ~= nil)  then
                                --test settings.duration_exceeded_hr
                                test_high_threshold = true
                                test_low_threshold = true
                                if settings.duration_exceeded_hr ~= nil then
                                    domoticz.data.managedValue.add(device.humidity)
                                    domoticz.data.managedId.add(device.id)
                                    if settings.high_threshold_hr ~= nil then high_threshold_hr = settings.high_threshold_hr else high_threshold_hr = nil end
                                    if settings.low_threshold_hr ~= nil then low_threshold_hr = settings.low_threshold_hr else low_threshold_hr = nil end
                                    test_high_threshold, test_low_threshold = managed(domoticz, device.id, settings.duration_exceeded_hr, high_threshold_hr, low_threshold_hr)
                                end
                                domoticz.log('L\'hygrometrie mesurée par '.. device.name .. ' est de  ' .. tostring(device.humidity)..'%hr', domoticz.LOG_INFO)
                                if settings.low_threshold_hr ~= nil and device.humidity < settings.low_threshold_hr and test_low_threshold == true then -- seuil bas hygrométrie
                                    domoticz.log(device.name .. ' a un seuil hygrometrie bassse défini à  ' .. settings.low_threshold_hr..'%hr', domoticz.LOG_INFO)
                                    message = 'L\'humidité mesurée par '.. device.name .. ' est inférieure au seuil défini ('..settings.low_threshold_hr..'%hr).' -- Valeur : '..tostring(device.humidity)..'%hr'
                                    if settings.duration_exceeded_hr ~= nil then
                                        domoticz.data.managedValue.add(settings.low_threshold_hr)
                                        domoticz.data.managedId.add(device.id)
                                    end
                                    domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                                end
                                if settings.high_threshold_hr and device.humidity > settings.high_threshold_hr and test_high_threshold == true then -- seuil haut hygrométrie
                                    domoticz.log(device.name .. ' a un seuil hygrometrie haute défini à  ' .. settings.high_threshold_hr..'%hr', domoticz.LOG_INFO)
                                    message = 'L\'humidité mesurée par '.. device.name .. ' est supérieure au seuil défini ('..settings.high_threshold_hr..'%hr).' -- Valeur : '..tostring(device.humidity)..'%hr'
                                    if settings.duration_exceeded_hr ~= nil then
                                        domoticz.data.managedValue.add(settings.high_threshold_hr)
                                        domoticz.data.managedId.add(device.id)
                                    end
                                    domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                                end
                            end

                        elseif device.state == 'On' or device.state == 'Open' then
                        -- Alarme dispositif actif
                            domoticz.log(device.name .. ' est à l\'état ' .. device.state, domoticz.LOG_INFO)
                            if settings.time_active_notification ~= nil and device.lastUpdate.minutesAgo >= settings.time_active_notification then
                                domoticz.log(device.name .. ' est actif depuis ' .. device.lastUpdate.minutesAgo .. ' minutes. Le délai est fixé à '.. settings.time_active_notification.. ' minutes.', domoticz.LOG_INFO)
                                message = 'Le délai fixé à '.. settings.time_active_notification .. ' minutes pour '.. device.name .. ' est dépassé'
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end

                        -- auto on
                            if settings.auto_on_minutes ~= nil and device.lastUpdate.minutesAgo >= settings.auto_on_minutes then
                                if settings.state == 'Off' then
                                    domoticz.log('Allumage de '..device.name .. ' car inactif depuis ' .. settings.auto_on_minutes .. ' minutes.', domoticz.LOG_INFO)
                                    device.switchOn()
                                end
                            end
                            --auto off

                            if settings.auto_off_minutes ~= nil and device.lastUpdate.minutesAgo >= settings.auto_off_minutes then
                                if settings.auto_off_motion_device == nil then
                                    domoticz.log('Extinction de '..device.name .. ' car actif depuis ' .. settings.auto_off_minutes .. ' minutes.', domoticz.LOG_INFO)
                                    device.switchOff()
                                elseif type(settings.auto_off_motion_device) == "string" then
                                    local motion_device = domoticz.devices(settings.auto_off_motion_device)
                                    if motion_device.state == 'Off' then
                                        domoticz.log('Extinction de '.. device.name .. ' car aucune détection de mouvement dans la piece depuis ' .. settings.auto_off_minutes .. ' minutes.', domoticz.LOG_INFO)
                                        device.switchOff()
                                    end
                                elseif type(settings.auto_off_motion_device) == "table" then
                                    local off = true
                                    for i,v in pairs(settings.auto_off_motion_device) do
                                        --domoticz.log("l'état de " .. domoticz.devices(v) .. ' est à : ' .. domoticz.devices(v).state, domoticz.LOG_DEBUG)
                                        if domoticz.devices(v).state ~= 'Off' and i == "restartTimer" and domoticz.devices(v).lastUpdate.minutesAgo >= settings.auto_off_minutes then
                                            off = false
                                        elseif domoticz.devices(v).state ~= 'Off' and i ~= "restartTimer" then
                                            off = false
                                        end
                                    end
                                    if off then
                                        domoticz.log('Extinction de '.. device.name .. ' car aucune détection de mouvement dans la piece depuis  ' .. settings.auto_off_minutes .. ' minutes.', domoticz.LOG_INFO)
                                        device.switchOff()
                                    end
                                end
                            end

                       elseif device.sensorType ~= nil and (settings.high_threshold_custom ~= nil or settings.low_threshold_custom ~= nil)  then
                        --alarme custom sensor
                            domoticz.log('La valeur mesurée par '.. device.name .. ' est de  ' .. tostring(domoticz.utils.round(device.state, 1)) .. device.sensorUnit, domoticz.LOG_INFO)
                            if settings.low_threshold_custom ~= nil and tonumber(device.state) < settings.low_threshold_custom then -- seuil bas %
                                domoticz.log(device.name .. ' a un seuil bas défini à  ' .. settings.low_threshold_custom..device.sensorUnit, domoticz.LOG_INFO)
                                message = 'La valeur mesurée par '.. device.name .. ' est inférieure au seuil défini ('..settings.low_threshold_custom..device.sensorUnit..').' -- Valeur : '..tostring(domoticz.utils.round(device.state, 1))..device.sensorUnit
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end
                            if settings.high_threshold_custom ~= nil and tonumber(device.state) > settings.high_threshold_custom then -- seuil haut %
                                domoticz.log(device.name .. ' a un seuil haut défini à  ' .. settings.high_threshold_custom..device.sensorUnit, domoticz.LOG_INFO)
                                message = 'La valeur mesurée par '.. device.name ..' est supérieure au seuil défini ('..settings.high_threshold_custom..device.sensorUnit..').' -- Valeur : '..tostring(domoticz.utils.round(device.state, 1))..device.sensorUnit
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end

                        elseif device.percentage ~= nil and (settings.high_threshold_percent ~= nil or settings.low_threshold_percent ~= nil)  then
                            -- test settings.duration_exceeded_hr
                            test_high_threshold = true
                            test_low_threshold = true
                            if settings.duration_exceeded_percent ~= nil then
                                domoticz.data.managedValue.add(device.percentage)
                                domoticz.data.managedId.add(device.id)

                                if settings.high_threshold_percent ~= nil then high_threshold_percent = settings.high_threshold_percent else high_threshold_percent = nil end
                                if settings.low_threshold_percent ~= nil then low_threshold_percent = settings.low_threshold_percent else low_threshold_percent = nil end
                                test_high_threshold, test_low_threshold = managed(domoticz, device.id, settings.duration_exceeded_percent, high_threshold_percent, low_threshold_percent)
                            end
                            -- alarme pourcentage
                            domoticz.log('La valeur mesurée par '.. device.name .. ' est de  ' .. tostring(domoticz.utils.round(device.percentage, 1)) ..'%', domoticz.LOG_INFO)
                            if settings.low_threshold_percent ~= nil and device.percentage < settings.low_threshold_percent and test_low_threshold == true then  -- seuil bas %
                                domoticz.log(device.name .. ' a un seuil % bas défini à  ' .. settings.low_threshold_percent..'%', domoticz.LOG_INFO)
                                message = 'La valeur mesurée par '.. device.name .. ' est inférieure au seuil défini ('..settings.low_threshold_percent..'%).' -- Valeur : '.. tostring(domoticz.utils.round(device.percentage, 1)) ..'%'
                                if settings.duration_exceeded_percent ~= nil then
                                    domoticz.data.managedValue.add(settings.low_threshold_percent)
                                    domoticz.data.managedId.add(device.id)
                                end
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end
                            if settings.high_threshold_percent ~= nil and device.percentage > settings.high_threshold_percent and test_high_threshold == true then  -- seuil haut %
                                domoticz.log(device.name .. ' a un seuil % haut défini à  ' .. settings.high_threshold_percent..'%', domoticz.LOG_INFO)
                                message = 'La valeur mesurée par '.. device.name ..' est supérieure au seuil défini ('..settings.high_threshold_percent..'%).' -- Valeur : '.. tostring(domoticz.utils.round(device.percentage, 1)) ..'%'

                                if settings.duration_exceeded_percent ~= nil then
                                    domoticz.data.managedValue.add(settings.high_threshold_percent)
                                    domoticz.data.managedId.add(device.id)
                                end
                                domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
                            end

                        elseif device.color ~= nil and settings.high_threshold_color ~= nil and device.color > settings.high_threshold_color then
                            -- notification alerte
                            domoticz.log('Le seuil d\'alerte de '.. device.name .. ' est de  ' .. tostring(device.color), domoticz.LOG_INFO)
                            message = 'Le seuil d\'alerte de  '.. device.name ..' est supérieur au seuil défini ('..settings.high_threshold_color..'). Valeur : '.. tostring(device.color) ..' alerte : '.. tostring(device.text)
                            domoticz.helpers.managedNotify(domoticz, subject, message, notificationTable(subSystems), frequency_notifications , quiet_hours)
            end
                        else
                            domoticz.log( 'la description de '.. device.name ..' n\'est pas au format json. Ignorer cet appareil.', domoticz.LOG_ERROR)
                        end
                            domoticz.log('--------------------------------------------------------------------------------------------------', domoticz.LOG_INFO)
                    end
                end
            )

        domoticz.log(tostring(cnt) .. ' devices scannés.', domoticz.LOG_INFO)
    end
}
