
--[[
name : myIP.lua
auteur : papoo
Mise à jour : 31/03/2020
Création : 23/01/2018  V1=> https://pon.fr/etre-notifie-de-son-changement-dip-publique-en-lua/
https://pon.fr/dzvents-notification-changement-dip
https://easydomoticz.com/forum/
github : 
Principe : tester, via l'api du site myip.com votre adresse publique et être notifié de chaque changement.
possibilité de tester une IP en V4 ou V6, d'être notifié seulement par mail en renseignant la variable EmailTo avec une plusieurs adresses mails, 
mais aussi avec toutes autres notifications paramétrées dans domoticz avec le choix de celles-ci (variable notification pour activer celles-ci, variable subsystem pour ne sélectionner qu'une ou plusieurs notifications parmi celles disponible
Le délai d"exécution est modifiable simplement (variable delai à renseigner en minutes) ainsi que l'activation/désactivation du fonctionnement de ce script (variable script_actif)

]]--

local emailTo             = "mon.adresse@mail.com" -- nil si notification par mail non souhaitée
local notifications    = true                 -- false si notidfications non souhaitées
local site_url          = 'https://api.myip.com/'  -- url

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local scriptName        = 'myIP'
local scriptVersion     = '2.00'
local response          = 'myIP_response'

return {
    active = true,
    on  =   {
        timer           =   { 'every 30 minutes' },--https://www.domoticz.com/wiki/DzVents:_next_generation_LUA_scripting#timer_trigger_rules
        httpResponses   =   { response }    -- Trigger
    },
    data = {
        ip = { history = true, maxItems = 1 }
    },
    logging =   {
        level    =   domoticz.LOG_DEBUG,                -- Seulement un niveau peut être actif; commenter les autres
        -- level    =   domoticz.LOG_INFO,              -- Only one level can be active; comment others
        -- level    =   domoticz.LOG_ERROR,
        -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
    marker = scriptName..' v'..scriptVersion },

    execute = function(dz, item)
           local SubSystem = "TELEGRAM,PUSHBULLET"
                            --[[ Systèmes de notification disponibles :
                                NSS_GOOGLE_CLOUD_MESSAGING NSS_HTTP NSS_KODI NSS_LOGITECH_MEDIASERVER NSS_NMA NSS_PROWL NSS_PUSHALOT NSS_PUSHBULLET NSS_PUSHOVER NSS_PUSHSAFER
                                Pour une notification sur plusieurs systèmes, séparez les systèmes par une virgule et entourez l'ensemble par des {}.
                                Exemple :{dz.NSS_PUSHBULLET, dz.NSS_HTTP} si laissé vide, toutes les notifications dz seront activées
                            --]]
                            
        local function logWrite(str,level)              -- Support function for shorthand debug log statements
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end

        function split(s, delimiter)
            result = {};
            for match in (s..delimiter):gmatch("(.-)"..delimiter) do
                table.insert(result, match);
            end
            return result;
        end

        function notificationTable(str)
        --NSS_GOOGLE_CLOUD_MESSAGING, NSS_HTTP, NSS_KODI, NSS_LOGITECH_MEDIASERVER, NSS_NMA,NSS_PROWL, NSS_PUSHALOT, NSS_PUSHBULLET, NSS_PUSHOVER, NSS_PUSHSAFER, NSS_TELEGRAM
            if (str) then
            str = string.gsub (str,"GCM", dz.NSS_GOOGLE_CLOUD_MESSAGING)
            str = string.gsub (str,"HTTP", dz.NSS_HTTP)
            str = string.gsub (str,"LMS", dz.NSS_LOGITECH_MEDIASERVER)
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
                    dz.openURL({--https://www.domoticz.com/wiki/DzVents:_next_generation_LUA_scripting#Asynchronous_HTTP_requests
                        url = site_url,
                        callback = response
                    })
        end

        if (item.isHTTPResponse and item.ok) then
         results = dz.utils.fromJSON(item.data)
            newAddress = results.ip
            country = results.country
            cc = results.cc
            logWrite('--- --- --- Adresse IP Publique : '..tostring(newAddress))
            logWrite('--- --- --- pays : '..tostring(country))
            logWrite('--- --- --- code pays format ISO 3166-1 alpha-2 : '..tostring(cc))
            
            oldAddress = dz.data.ip.getLatest().data
            if dz.data.ip.getLatest().time.daysAgo ~= 0 then
                delay = tostring(dz.data.ip.getLatest().time.daysAgo) ..   ' jours'
            elseif dz.data.ip.getLatest().time.hoursAgo ~= 0 then 
                delay = tostring(dz.data.ip.getLatest().time.hoursAgo) ..   ' heures'
            else
                delay = tostring(dz.data.ip.getLatest().time.minutesAgo).. ' minutes'
            end
            if oldAddress ~= newAddress then 
                logWrite('--- --- --- l\'adresse IP Publique a changé '..tostring(newAddress))
                logWrite('--- --- --- l\'ancienne adresse étée '..tostring(oldAddress))
                logWrite('--- --- --- Depuis '..tostring(delay))
                if emailTo ~= nil then 
                    dz.email(
                    'l\'adresse IP Publique a changé', 
                    'la nouvelle adresse IP est : <br>'..
                    'http://'..newAddress..':8080<br>'..
                    'l\'ancienne adresse étée '..tostring(oldAddress)..'<br>'..
                    'Depuis '..tostring(delay)
                    , emailTo)
                end
                if notifications == true then
                    dz.notify("\xF0\x9F\x98\x81 l\'adresse IP Publique a changé \xF0\x9F\x98\x81", "la nouvelle adresse IP est : http://"..newAddress, dz.PRIORITY_NORMAL,dz.SOUND_DEFAULT, "" , notificationTable(SubSystem) )
                end
                dz.data.ip.add(newAddress)
                else
                logWrite('--- --- --- l\'adresse IP Publique n\'a pas changé '..tostring(newAddress))
            end
        end
     --end
end
}
