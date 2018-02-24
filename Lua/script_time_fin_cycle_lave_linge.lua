-- script_time_fin_cycle_lave_linge.lua
-- source : http://www.domoticz.com/forum/viewtopic.php?f=61&t=253
-- modifié par papoo
-- MAJ : 24/02/2018

--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging                 = false                     -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local washer_status_uservar     = 'Etat Lave Linge'
local energy_consumption        = 'Conso Lave Linge'        -- Nom du device qui mesure la consommation réelle de le machine à laver (en watts)
local washer_counter_uservar    = 'Compteur Lave Linge'     -- Nom de la variable utilisateur qui contiendra la valeur précédente du compteur
local idle_minutes              = 4                         -- Délai en minutes pendant lequel la consommation devra rester en dessous de la valeur 'consumption_lower' avant notification
local consumption_upper         = 15                        -- Si l'utilisation est supérieure à cette valeur (Watts), la machine à laver a démarré
local consumption_lower         = 2                         -- Si l'utilisation est inférieure à cette valeur (Watts), la machine à laver est inactive
local name                      = 'Lave Linge'              -- Nom de l'équipement à transmettre lors de la notification
local subsystem                 = "pushbullet"              -- Les différentes valeurs de subsystem acceptées sont : gcm;http;kodi;lms;nma;prowl;pushalot;pushbullet;pushover;pushsafer;telegram
                                                            -- pour plusieurs modes de notification séparez chaque mode par un point virgule (exemple : "pushalot;pushbullet"). si subsystem = nil toutes les notifications seront activées.
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
--------------------------------------------
------------- Autres Variables -------------
--------------------------------------------
local nom_script = 'fin cycle lave linge'
local version = '1.5'
--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------   
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"
require('fonctions_perso')
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
commandArray = {}
voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
washer_usage                  = tonumber(otherdevices_svalues[energy_consumption])
-- Le commutateur virtuel est à l'arrêt, mais la consommation est supérieure au niveau configuré. L'utilisation de l'appareil a donc commencé
if (washer_usage > consumption_upper) and uservariables[washer_status_uservar] == 0 then
  commandArray['Variable:' .. washer_status_uservar]='1'
  voir_les_logs('La consommation d\'énergie actuelle (' ..washer_usage.. 'W) est au-dessus de la limite supérieure (' ..consumption_upper.. 'W), Donc le '.. name ..' a démarré!',debugging)
  commandArray['Variable:' .. washer_counter_uservar]=tostring(idle_minutes)
end

-- L'appareil n'utilise pas beaucoup d'énergie, vérification du compteur
if (washer_usage < consumption_lower) and uservariables[washer_status_uservar] == 1 then 
  commandArray['Variable:' .. washer_counter_uservar]=tostring(math.max(tonumber(uservariables[washer_counter_uservar]) - 1, 0))
  voir_les_logs('La consommation d\'énergie actuelle (' ..washer_usage.. 'W) est au-dessous de la limite inférieure (' ..consumption_lower.. 'W), Le '.. name ..' est au repos ou presque pret',debugging)
  voir_les_logs('Soustraction compteur, ancienne valeur: ' ..uservariables[washer_counter_uservar].. ' minutes',debugging)
elseif ((uservariables[washer_counter_uservar] ~= idle_minutes) and uservariables[washer_status_uservar] == 1) then
  commandArray['Variable:' .. washer_counter_uservar]=tostring(idle_minutes)
  voir_les_logs('Réinitialisation minuterie '.. name,debugging)
end

-- Le cycle est terminé
if ((uservariables[washer_status_uservar] == 1) and uservariables[washer_counter_uservar] == 0) then
  voir_les_logs('La consommation d\'énergie actuelle du '.. name ..' est de ' ..washer_usage.. 'W',debugging)
  voir_les_logs('Le '.. name ..' vient de se terminer!',debugging)
    if subsystem ~= nil then
        voir_les_logs("--- --- --- Notification système activée pour les services "..subsystem,debugging)
        commandArray[#commandArray+1] = {['SendNotification'] = 'Cycle Terminé: '.. name ..'#Le '.. name ..' vient de se terminer#0###'.. subsystem ..''}
    else
        voir_les_logs("--- --- --- toutes les Notifications système sont activées",debugging)
        commandArray[#commandArray+1] = {['SendNotification'] = 'Cycle Terminé: '.. name ..'#Le '.. name ..' vient de se terminer'}
    end

  commandArray['Mid Value']='Set Level 1' -- notification via xiaomi gateway
  commandArray['Variable:' .. washer_status_uservar]='0'
end

return commandArray