--[[
name : script_time_prealarme incendie.lua
auteur : papoo

MAJ : 28/04/2018
création : 15/08/2016

Principe : ce script vérifie toutes les deux minutes si il n'y a pas une augmentation de température anormale dans une des pièces référencées dans le tableau les_températures.
il compare chaque température au seuil fixé par la variable  seuil_notification (en °C). Si une ou plusieurs températures sont supérieures à ce seuil, envoie d'une notification pour chacune d'elle.
/!\ si le seuil est fixé trop bas, cela risque de générer beaucoup de notifications et éventuellement bloquer les services de type pushbullet.
URL post : http://easydomoticz.com/forum/viewtopic.php?f=17&t=2319
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging = false  	-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif    = true                    -- active (true) ou désactive (false) ce script simplement
local seuil_notification = 40 		-- seuil température au delà duquel les notifications d'alarme seront envoyées
local les_temperatures = {"Temperature 1", "Temperature 2", "Temperature Entree", "Temperature Salon", "Temperature Cave", "Temperature Parents", "Temperature Bureau", "Temperature Cuisine", "Temperature Douche"}; --, "Temp Douche"
local only_mail = true -- true si l'on ne souhaite être notifié que par mail, false si l'on souhaite toutes les notifications disponible.
local EmailTo = 'votre.mail@gmail.com'  -- adresse mail, séparées par ; si plusieurs

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = "préalarme incendie"
local version = "1.11"
local message = {}
local alarmes = 0
commandArray = {}
--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"
require('fonctions_perso')
-------------------------------------------- 
-------------- Fin Fonctions ---------------
--------------------------------------------
time=os.date("*t")
  
if script_actif == true then
    if time.min % 2 == 0 then
                    voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
                voir_les_logs("--- --- --- seuil de notification ".. seuil_notification .."°C",debugging)
        for i,d in ipairs(les_temperatures) do
            
             local v=otherdevices[d]                        
                    voir_les_logs("--- --- --- device value "..d.." = "..(v or "nil"),debugging)
                        
                if v~= nil then
                
                        if string.match(v, ';')  then
                        v=v:match('^(.-);')
                        voir_les_logs("--- --- --- svalue "..d.." = "..(v or "nil"),debugging)
                        end			
                
                    if tonumber(v) > tonumber(seuil_notification) then
                    alarmes = alarmes+1
                    table.insert(message, 'température '..d..' : '..v..'°C, supérieure au seuil fixé à '..seuil_notification..'°C <br>')
                        if only_mail ~= true then
                        commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte préalarme incendie#température '..d..' : '..v..'°C, supérieure au seuil fixé à '..seuil_notification..'°C'}
                        
                        end
                    end
                end                                            
            end

        if alarmes >= 1 and only_mail == true then
            voir_les_logs("--- --- --- Nb d'alarmes : "..alarmes,debugging)
            objet = 'Alerte préalarme incendie '..os.date("%H:%M")
            commandArray['SendEmail']= objet..'#'.. table.concat(message)  .. '#' .. EmailTo
            voir_les_logs("--- --- --- Objet:"..objet,debugging)
            voir_les_logs("--- --- --- Corps du message: "..table.concat(message),debugging)
            voir_les_logs("--- --- --- Destinataire: "..EmailTo,debugging)
        end
      voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
    end -- if time
end -- if script actif
return commandArray
