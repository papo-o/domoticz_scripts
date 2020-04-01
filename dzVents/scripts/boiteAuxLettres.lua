--[[boiteAuxLettres.lua
Creation =28/03/2018
https://pon.fr/
https://easydomoticz.com/forum/
icones : https://github.com/papo-o/domoticz_scripts/boiteAuxLettres.lua
update/mise à jour = 01/04/2020
Principe : Remettre à Zero les indicateurs paquet ou lettre
--]]
local scriptName        = 'Boite Aux Lettres'
local scriptVersion     = ' 2.01'
local message
local subject               = '\xE2\x9A\xA0 /!\\ Le courrier n\'a pas été ramassé /!\\ \xE2\x9A\xA0'           -- sujet des notifications
local subsystem             = 'telegram,HTTP'   -- les différentes valeurs de subsystem acceptées sont : gcm,http,kodi,lms,nma,prowl,pushalot,pushbullet,pushover,pushsafer,telegram
                                                -- pour plusieurs modes de notification séparez chaque mode par une virgule (exemple : "pushalot,pushbullet"). si subsystem = nil toutes les notifications seront activées.

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------

return {
    active  = true,
    on = {
        timer =     { 'at 19:45' },
        devices =   { 'Paquet' }
    },

    logging =
    {   level    =   domoticz.LOG_DEBUG,                -- Seulement un niveau peut être actif; commenter les autres
        -- level    =   domoticz.LOG_INFO,              -- Only one level can be active; comment others
        -- level    =   domoticz.LOG_ERROR,
        -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
        marker = scriptName..' v'..scriptVersion
    },

    execute = function(dz, item)

        local function logWrite(str,level)
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end
        local function notificationTable(str)
        --NSS_GOOGLE_CLOUD_MESSAGING, NSS_HTTP, NSS_KODI, NSS_LOGITECH_MEDIASERVER, NSS_NMA,NSS_PROWL, NSS_PUSHALOT, NSS_PUSHBULLET, NSS_PUSHOVER, NSS_PUSHSAFER, NSS_TELEGRAM
        if (str) then
            str = string.gsub (str,"GCM", dz.NSS_GOOGLE_CLOUD_MESSAGING)
            str = string.gsub (str,"GOOGLE_CLOUD_MESSAGING", dz.NSS_GOOGLE_CLOUD_MESSAGING)
            str = string.gsub (str,"HTTP", dz.NSS_HTTP)
            str = string.gsub (str,"LMS", dz.NSS_LOGITECH_MEDIASERVER)
            str = string.gsub (str,"LOGITECH_MEDIASERVER", dz.NSS_LOGITECH_MEDIASERVER)
            str = string.gsub (str,"NMA", dz.NSS_NMA)
            str = string.gsub (str,"PROWL", dz.NSS_PROWL)
            str = string.gsub (str,"PUSHALOT", dz.NSS_PUSHALOT)
            str = string.gsub (str,"PUSHOVER", dz.NSS_PUSHOVER)
            str = string.gsub (str,"PUSHSAFER", dz.NSS_PUSHSAFER)
            str = string.gsub (str,"PUSHBULLET", dz.NSS_PUSHBULLET)
            str = string.gsub (str,"TELEGRAM", dz.NSS_TELEGRAM)
        end
        return (split(str,','))
        end

        if (item.isTimer) then
         -- the timer was triggered
        local message = nil
        logWrite(dz.devices('Paquet').name.." est à " ..dz.devices('Paquet').state)
        logWrite(dz.devices('Lettre').name.." est à " ..dz.devices('Lettre').state)
        if dz.devices('Paquet').state == 'On' or dz.devices('Lettre').state == 'On' then
            message = ('Le courrier n\'a pas été ramassé')
        end
        if message then
            dz.helpers.managedNotify(dz, subject, message, notificationTable(subsystem), nil , nil)
        end

        elseif (item.isDevice and item.active) then
         -- it must be the detector
        logWrite(item.name.. " est à " ..item.state)
        logWrite(dz.devices('Lettre').name.." est à " ..dz.devices('Lettre').state)
            if item.lastUpdate.hoursAgo < 8 then
            --Si la porte a déjà été ouverte dans la journée on remet à off lettre et paquet
                dz.devices('Lettre').switchOff().checkFirst()
                item.switchOff().checkFirst()
            end
        end
    end
}
