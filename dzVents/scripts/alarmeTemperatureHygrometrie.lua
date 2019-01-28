--[[
alarmeTemperatureHygrometrie.lua
auteur : papoo

MAJ : 26/01/2019
création : 15/08/2016

Principe : ce script vérifie toutes les minutes si il n'y a pas une augmentation (ou une diminution) de température (ou d'hygrométrie) anormale
sur les sondes de températures/hygrométrie référencées dans le tableau les_devices.
vous pouvez définir un seuil de température (en °C) ou d'humidité (en %hr) par sonde, par groupe ou par défaut, actuellement 5 groupes disponible : ambiance, frigo, congel, materiel et humidite
le seuil défini par sonde est prioritaire sur le seuil par groupe qui est prioritaire sur le seuil par défaut.
Vous pouvez définir le 'sens' de déclenchement augmentation de la valeur en dessus du seuil ou  diminution de la valeur en dessous du seuil
comparaison de chaque valeur au seuil fixé et envoi d'une notification si dépassement du seuil.
Si plusieurs valeurs de sonde dépassent le(s) seuil(s), envoie d'une notification pour chacune d'elle.
définir le délai en minutes entre deux notifications d'une même alarme, par défaut delai configuré à 1440 minutes  = 24 heures (modifiable)
url blog : https://pon.fr/dzvents-alarme-temperature-et-hygrometrie-v3
URL post : http://easydomoticz.com/forum/viewtopic.php?f=17&t=6205
URL github : https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/alarmeTemperatureHygrometrie.lua
--]]
--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------
local email             = false                                     -- true si l'on ne souhaite être notifié que par mail, false si l'on souhaite 
local notification            = true                                      -- mettre à false si vous ne voulez pas de notification
local adresseMail      = 'pvotre.adresse@mail.com'                      -- adresse mail, séparées par ; si plusieurs
local defaut_seuil      = '45'                                      -- seuil en °C par défaut avant notification pour tous les devices non personnalisés
local seuil_ambiance    = '40'                                      -- seuil en °C par défaut avant notification pour les devices du groupe ambiance
local seuil_frigo       = '25'                                      -- seuil en °C par défaut avant notification pour les devices du groupe refrigerateur
local seuil_congel      = '-10'                                     -- seuil en °C par défaut avant notification pour les devices du groupe congelateur
local seuil_materiel    = '75'                                      -- seuil en °C par défaut avant notification pour les devices du groupe materiel
local seuil_humidite    = '70'                                      -- seuil en % hr par défaut avant notification pour les devices du groupe humidite
local delai             = '1440'                                    -- nombre de minutes entre deux notifications d'une même alarme (1440 pour une seule notification par jour)
local sujet             = "/!\\ Attention, alarme /!\\"             -- sujet des notifications 
local les_devices = {
-- comment remplir le tableau les_devices ?  
-- ['nom'] = le nom du dispositif à surveiller
-- ['groupe'] = le nom du groupe auquel appartient le device à surveiller : ambiance, frigo, congel, humidite.  Si aucun groupe particulier, nil.
-- ['seuil'] = seuil particulier à n'utiliser que sur le device concerné, inhibe le seuil affecté au groupe et le seuil par défaut . Si aucun seuil particulier, nil.
-- si ['groupe'] = nil et ['seuil'] = nil le seuil defaut_seuil sera appliqué.
-- Pour activer un ou plusieurs mode de notifications particuliers renseigner subsystem
-- les différentes valeurs de subsystem acceptées sont : gcm;http;kodi;lms;nma;prowl;pushbullet;pushover;pushsafer;telegram
-- pour plusieurs modes de notification séparez chaque mode par un point virgule. si ['systemeNotification'] = nil toutes les notifications seront activées.
-- { ['nom'] ="", ['groupe'] ="", ['type'] = "temperature, ['seuil'] = nil, ['sens'] = 'augmentation', ['systemeNotification'] = nil}

{ ['nom'] = 'Temperature Salon',        ['groupe'] = 'ambiance', ['type'] = 'temperature', ['seuil'] = 35,  ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Salon',        ['groupe'] = 'humidite', ['type'] = 'humidite',    ['seuil'] = 70,  ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Salon',        ['groupe'] = 'humidite', ['type'] = 'humidite',    ['seuil'] = 25,  ['sens'] = 'diminution'  ,},
{ ['nom'] = 'Temperature Cave',         ['groupe'] = 'ambiance', ['type'] = 'temperature', ['seuil'] = nil, ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Parents',      ['groupe'] = 'ambiance', ['type'] = 'temperature', ['seuil'] = nil, ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Bureau',       ['groupe'] = 'ambiance', ['type'] = 'temperature', ['seuil'] = nil, ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Cuisine',      ['groupe'] = 'ambiance', ['type'] = 'temperature', ['seuil'] = nil, ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Douche',       ['groupe'] = 'ambiance', ['type'] = 'temperature', ['seuil'] = nil, ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Douche',       ['groupe'] = 'humidite', ['type'] = 'humidite',    ['seuil'] = 70,  ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Garage',       ['groupe'] = 'ambiance', ['type'] = 'temperature', ['seuil'] = nil, ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Cellier',      ['groupe'] = 'ambiance', ['type'] = 'temperature', ['seuil'] = nil, ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Entree',       ['groupe'] = 'ambiance', ['type'] = 'temperature', ['seuil'] = nil, ['sens'] = 'augmentation',},
{ ['nom'] = 'Temperature Raspberry',    ['groupe'] = 'materiel', ['type'] = 'temperature', ['seuil'] = nil, ['sens'] = 'augmentation',},
{ ['nom'] = 'Synology Temp',            ['groupe'] = 'materiel', ['type'] = 'temperature', ['seuil'] = 50,  ['sens'] = 'augmentation',},
};
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nomScript = 'Alarme T° et HR'
local versionScript = '3.0'

return {
    active = true,
    on = { timer = {'every minute'}
    },
    
    logging =   { 
--------------------------------------------
------------- Niveau log à éditer ----------
--------------------------------------------    
                    -- level    =   domoticz.LOG_DEBUG,
                    -- level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others    
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
--------------------------------------------
----------- Fin niveau log à éditer --------
-------------------------------------------- 
                    marker              = nomScript..' v'..versionScript
                },    
    data = { 	    envoiNotification       = { history = true, maxMinutes = tonumber(delai)-1 }},

    execute = function(domoticz)
--------------------------------------------
---------- Notifications à éditer ----------
--------------------------------------------   
    local tableNotification     =     {
                                     -- tableau avec un ou plusieurs systèmes de notification. 
                                     -- décommentez le(s) système(s) de notification que vous souhaitez utiliser.

                                     -- domoticz.NSS_GOOGLE_CLOUD_MESSAGING, 
                                     -- domoticz.NSS_PUSHOVER,               
                                     -- domoticz.NSS_HTTP, 
                                     -- domoticz.NSS_KODI, 
                                     -- domoticz.NSS_LOGITECH_MEDIASERVER, 
                                     -- domoticz.NSS_NMA,
                                     -- domoticz.NSS_PROWL, 
                                     -- domoticz.NSS_PUSHALOT, 
                                      domoticz.NSS_PUSHBULLET, 
                                     -- domoticz.NSS_PUSHOVER, 
                                     -- domoticz.NSS_PUSHSAFER,
                                      domoticz.NSS_TELEGRAM,
                                    }
--------------------------------------------
-------- Fin Notifications à éditer --------
--------------------------------------------                                    
                                    
        for i, deviceToCheck in pairs(les_devices) do
            local nom                   = deviceToCheck['nom']
            local groupe                = deviceToCheck['groupe']
			local seuil                 = deviceToCheck['seuil']
            if seuil == nil then 
                if groupe ~= nil then 
                    if groupe == 'humidite' then 
                        seuil = tonumber(seuil_humidite)
                    elseif groupe == 'frigo' then 
                        seuil = tonumber(seuil_frigo)
                    elseif seuil == 'congel' then
                        seuil = tonumber(seuil_congel)
                    elseif groupe == 'ambiance' then
                        seuil = tonumber(seuil_ambiance)
                    elseif groupe == 'materiel' then
                        seuil = tonumber(seuil_materiel)                        
                    elseif groupe == nil then 
                    seuil = tonumber(defaut_seuil)
                    end
                end
            end
            local Type                  = deviceToCheck['type']
            domoticz.log("groupe : "..tostring(groupe).." type : "..tostring(Type).." seuil : "..tostring(seuil), domoticz.LOG_DEBUG)
            local valeur = ''
            if Type == 'humidite' then
                valeur                  = tonumber(domoticz.devices(nom).humidity)
            else
                valeur                  = tonumber(domoticz.devices(nom).temperature)
            end
            valeur                      = domoticz.utils.round(valeur,1)
            local sens                  = deviceToCheck['sens'] 
                if sens == 'diminution' then
                    declench = 'inférieur'
                else
                    declench = 'supérieur'
                end
            local systemeNotification = deviceToCheck['systemeNotification']
            if Type == 'humidite' then
                message = "La sonde ".. tostring(nom) .." avec un seuil d\'alarme "..tostring(declench).." à "..tostring(seuil).." %, est à "..tostring(valeur).." %"
            else
                message = "La sonde ".. tostring(nom) .." avec un seuil d\'alarme "..tostring(declench).." à "..tostring(seuil)..", est à "..tostring(valeur).." °C"
            end
            nomtype = string.gsub (nom..Type, " ", "")
            if (valeur >= seuil and sens == 'augmentation') or (valeur <= seuil and sens == 'diminution') then
                domoticz.data.envoiNotification.forEach(function(item)
                    if item.data == nomtype then 
                        timeNotif = tonumber(item.time.minutesAgo)
                    end
                end)
                domoticz.log("dernière notification de l\'alarme sonde "..tostring(nom).." : "..tostring(timeNotif).." minutes", domoticz.LOG_INFO)
                if  timeNotif == nil  or (timeNotif ~= nil and timeNotif >= tonumber(delai)) then 
                    if email then domoticz.email(sujet,message,adresseMail) end
                    if notification then domoticz.notify(sujet, message, domoticz.PRIORITY_NORMAL, domoticz.SOUND_INTERMISSION,"",  tableNotification ) end                
                    domoticz.data.envoiNotification.add(nomtype)
                end   
            end
            timeNotif = nil
        end -- for    
    end   
}

