--[[
script_time_alarme_temperature.lua
auteur : papoo

MAJ : 28/04/2018
création : 15/08/2016

Principe : ce script vérifie toutes les deux minutes (modifiable via la variable delai) si il n'y a pas une augmentation de température anormale
sur les sondes de températures référencées dans le tableau les_devices.
vous pouvez définir un seuil de température (en °C) par sonde ou par groupe ou par défaut, actuellement 3 groupes disponible : ambiance, frigo, congel
le seuil défini par sonde est prioritaire sur le seuil par groupe qui est prioritaire sur le seuil par défaut
comparaison de chaque température au seuil fixé et envoi d'une notification si dépassement du seuil.
Si plusieurs températures sont supérieures au(x) seuil(s), envoie d'une notification pour chacune d'elle.
/!\ si le seuil est fixé trop bas, cela risque de générer beaucoup de notifications et éventuellement bloquer les services de type pushbullet.
url blog : https://pon.fr/lua-alarme-augmentation-temperature-v2
URL post : http://easydomoticz.com/forum/viewtopic.php?f=17&t=6205
URL github : https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_alarme_temperature.lua
--]]
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging = false  	            -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif    = true            -- active (true) ou désactive (false) ce script simplement
local delai = 2                         -- délai d'exécution de ce script en minutes de 1 à 59
local only_mail = false                 -- true si l'on ne souhaite être notifié que par mail, false si l'on souhaite toutes les notifications disponible.
local EmailTo = 'votre.mail@gmail.com'        -- adresse mail, séparées par ; si plusieurs
local defaut_seuil = "45"               -- seuil en °C par défaut avant notification pour tout les devices non personnalisés
local seuil_ambiance = "40"             -- seuil en °C par défaut avant notification pour les devices du groupe ambiance
local seuil_frigo = "25"                -- seuil en °C par défaut avant notification pour les devices du groupe réfrigérateur
local seuil_congel = '25'               -- seuil en °C par défaut avant notification pour les devices du groupe lumières

local les_devices = {};
-- comment remplir le tableau les_devices ?  
-- device = le nom du dispositif à surveiller
-- type_device = le nom du groupe auquel appartient le device à surveiller : ambiance, frigo, congel.  Si aucun groupe particulier, nil.
-- seuil = seuil particulier à n'utiliser que sur le device concerné, inhibe le seuil affecté au groupe et le seuil par défaut . Si aucun seuil particulier, nil.
-- si type_device = nil et seuil = nil le seuil defaut_seuil sera appliqué.
-- Pour activer un ou plusieurs mode de notifications particuliers renseigner subsystem
-- les différentes valeurs de subsystem acceptées sont : gcm;http;kodi;lms;nma;prowl;pushbullet;pushover;pushsafer;telegram
-- pour plusieurs modes de notification séparez chaque mode par un point virgule. si subsystem = nil toutes les notifications seront activées.
-- les_devices[#les_devices+1] = {device="", type_device ="", seuil = nil, subsystem = nil}
les_devices[#les_devices+1] = {device="Temperature Salon",  type_device = "ambiance", seuil = nil, subsystem = "pushbullet"} -- 1er device, seuil en °C
les_devices[#les_devices+1] = {device="Temperature Cave",  type_device = "ambiance", seuil = nil, subsystem = nil} -- 2eme device
les_devices[#les_devices+1] = {device="Temperature Parents",  type_device = "ambiance", seuil = nil, subsystem = nil} -- 3eme device
les_devices[#les_devices+1] = {device="Temperature Bureau",  type_device = "ambiance", seuil = nil, subsystem = nil} -- 4eme device
les_devices[#les_devices+1] = {device="Temperature Cuisine",  type_device = "ambiance", seuil = nil, subsystem = nil} -- 5eme device
les_devices[#les_devices+1] = {device="Temperature Douche",  type_device = "ambiance", seuil = nil, subsystem = nil} -- 6eme device
les_devices[#les_devices+1] = {device="Réfrigérateur",  type_device = "frigo", seuil = nil, subsystem = "telegram"} -- 7eme device
les_devices[#les_devices+1] = {device="Congélateur",  type_device = "congel", seuil = nil, subsystem = "telegram"} -- 8eme device
les_devices[#les_devices+1] = {device="Temperature 1", type_device ="ambiance", seuil = nil, subsystem = nil} -- 9eme device
les_devices[#les_devices+1] = {device="Temperature 2",  type_device = "ambiance", seuil = nil, subsystem = nil} -- 10eme device
les_devices[#les_devices+1] = {device="Temperature Entree",  type_device = "ambiance", seuil = nil, subsystem = nil} -- 11eme device
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = "Alarme température"
local version = "2.01"
local message = {}
local alarmes = 0
local seuil_notification = nil
commandArray = {}
--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"   -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script
require('fonctions_perso')                                                      -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script

-- ci-dessous les lignes à décommenter en cas d'utilisation des fonctions directement dans ce script( supprimer --[[ et --]])
--[[ function voir_les_logs (s, debugging) -- nécessite la variable local debugging
    if (debugging) then 
		if s ~= nil then
        print (s)
		else
		print ("aucune valeur affichable")
		end
    end
end	-- usage voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
--]]
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
time=os.date("*t")
  
if script_actif == true then
    if ((time.min-1) % delai) == 0 then -- toutes les xx minutes en commençant par xx:01.  xx définissable via la variable delai
        voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)

        for k,v in pairs(les_devices) do 
            local Vtype = v.type_device
            local Vseuil = v.seuil
            local V=otherdevices_temperature[v.device]
            if v.seuil ~= nil then 
                seuil_notification  = v.seuil
            else 
                if Vtype ~= nil then 
                    if Vtype == "ambiance" then seuil_notification = seuil_ambiance 
                    elseif Vtype == "frigo" then seuil_notification = seuil_frigo 
                    elseif Vtype == "congel" then seuil_notification = seuil_congel 
                    end
                else 
                    seuil_notification = defaut_seuil    
                end
                voir_les_logs("--- --- --- seuil de notification : ".. seuil_notification .."°C",debugging)
            end

            voir_les_logs("--- --- --- device value "..v.device.." = "..(V or "nil"),debugging)
            if V~= nil then
                if string.match(V, ';')  then
                V=V:match('^(.-);')
                voir_les_logs("--- --- --- svalue "..v.device.." = "..(V or "nil"),debugging)
                end	
                
              
                if  tonumber(seuil_notification) < tonumber(V) then
                    alarmes = alarmes+1
                    table.insert(message, 'température '..v.device..' : '..V..'°C, supérieure au seuil fixé à '..seuil_notification..'°C <br>')
                    if only_mail ~= true then
                        if v.subsystem ~= nil then
                            commandArray['SendNotification'] = 'Attention#température '..v.device..' : '..V..'°C, supérieure au seuil fixé à '..seuil_notification..'°C!#0###'.. v.subsystem ..''
                        else
                            commandArray['SendNotification'] = 'Attention#température '..v.device..' : '..V..'°C, supérieure au seuil fixé à '..seuil_notification..'°C!'
                        end                        
                    end
                end
            end                                            
        end

        if alarmes >= 1 then
            if only_mail == true and EmailTo ~= nil then
                voir_les_logs("--- --- --- Nb d'alarmes : "..alarmes,debugging)
                objet = 'Alerte température '..os.date("%H:%M")
                commandArray['SendEmail']= objet..'#'.. table.concat(message)  .. '#' .. EmailTo
                voir_les_logs("--- --- --- Objet:"..objet,debugging)
                voir_les_logs("--- --- --- Corps du message: "..table.concat(message),debugging)
                voir_les_logs("--- --- --- Destinataire: "..EmailTo,debugging)
            end
        end    
      voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
    end -- if time
end -- if script actif
return commandArray
