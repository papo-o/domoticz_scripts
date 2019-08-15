--[[
stopCommand.lua
author/auteur = papoo
update/mise à jour = 15/08/2019
création = 15/08/2019
https://pon.fr/dzvents-bouton-stop-sur-telecommande-de-volet-2-boutons
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/stopCommand.lua
https://easydomoticz.com/forum/

Principe :
 ce script permet de simuler un troisième bouton "STOP" sur une télécommande 2 boutons,
 si un deuxième appui sur le même bouton est effectué en moins de 30 secondes.
 Associé à un boitier VRT pour la commande de deux volets roulants, ce script permettra l'arrêt du volet concerné
--]]

local vrt = '192.168.10.207' -- Adresse IP du VRT
local tempo = 30
local switchs={} ;   
    switchs[0] = {nom="Volet Douche", canal="1"}
    switchs[1] = {nom="Volet Chambre", canal="2"}
local scriptName = 'Stop Command'
local scriptVersion = '0.1'


return {
    active = true,
    on = {
    devices = {"Volet Douche", "Volet Chambre"}
    },
    logging = {
        -- level    =   domoticz.LOG_DEBUG, -- Uncomment to override the dzVents global logging setting
        level    =   domoticz.LOG_INFO,  -- Seulement un niveau peut être actif; commenter les autres
        -- level    =   domoticz.LOG_ERROR,
        -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
         marker = scriptName..' '..scriptVersion
    },
    execute = function(domoticz,sensor)
    
        local function logWrite(str,level)             -- Support function for shorthand debug log statements
            domoticz.log(tostring(str),level or domoticz.LOG_DEBUG)
        end
        for key, valeur in pairs(switchs) do
            if (domoticz.changedDevices(valeur.nom) and domoticz.devices(valeur.nom).lastUpdate.secondsAgo < tempo) then
               domoticz.openURL(vrt.."/ctrl.cgi?vr"..valeur.canal.."=2")
               logWrite("--- --- --- Deuxieme appui sur la telecommande ".. valeur.nom ..",  arret du volet --- --- --- ",domoticz.LOG_INFO)
            end
        end
    end
}
