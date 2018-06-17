--[[script_time_detec_fuite_eau.lua
auteur : papoo
MAJ : 13/03/2018
Création : 25/04/2016
Script LUA pour Domoticz permettant la vérification périodique de la consommation d'eau (toutes les 5 minutes) par comparaison avec l'index précédent, présent dans une variable utilisateur créée automatiquement lors de la première exécution du script.
- Si l'index compteur et l'index -5mn sont identique, le device probabilité est remis à zéro => pas de fuite.
- Si L'index compteur et l'index -5mn sont différents => Consommation d'eau, incrémentation du device probabilité de 8% et mise à jour de la variable associée.
- Si il y a une consommation d'eau continue pendant une heure =&gt; le device probabilité sera incrémenté 12 fois, donc à 96%, une très forte probabilité.
Le seuil de notification est paramétrable via la variable seuil_notification. 
Je l'ai fixé à 80%, j'ai donc une notification de surconsommation/fuite 50 à 55 minutes après le début de la consommation (le script ne exécutant que toutes les 5mn).
Vous avez la possibilité de surveiller plusieurs compteurs il suffit pour cela de les renseigner à la suite dans le tableau les_compteurs
Le script est lu toutes les minutes mais ne vérifie les données que toutes les 5 minutes.

V2 : ajout d'une période journalière de détection des micro fuites. Laps de temps personnalisable (au moins une heure) à l'issue du quel on vérifie si il y a eu une consommation.
Vous pouvez adapter l'heure et la minute à laquelle le script commence cette surveillance, pour l'adapter à votre rythme de vie. Par défaut il débute à 2h15. 
(évitez à 0 minute le système sauvegardant la BDD, les ressources sont moindre pour exécuter correctement ce script)
vous pouvez adapter le délai après lequel cette période se termine (par défaut 3 heures). arrêt de la surveillance et notification à : 2h15 + 3h = 5h15 du matin.

http://pon.fr/lua-script-de-detection-fuite-deau-v2
http://easydomoticz.com/forum/viewtopic.php?f=8&t=1913&hilit=d%C3%A9tection+fuite+eau#p16950
https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_detec_fuite_eau.lua
--]]
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging       = false                    -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif    = true                    -- active (true) ou désactive (false) ce script simplement
local url             = '127.0.0.1:8080'        -- user:pass@ip:port de domoticz
local heure           = 0			    	    -- (0-24) heure de début de la période zéro consommation
local minute          = 15                      -- (0-60) minute de début de la période zéro consommation
local delai           = 5                       -- délai en heure de la période d'observation zéro consommation
local EmailTo         = nil                     -- adresse pour être notifié par mail nil si inutilisé. Séparer les adresses par un ; exemple : 'premiere.adresse@mail.com;deuxieme.adresse@mail.com'
local notification    = 2                       -- 0: aucune notification, 1: toutes , 2: seulement en cas de fuite
local subsystem       = 'telegram'              -- les différentes valeurs de subsystem acceptées sont : gcm;http;kodi;lms;nma;prowl;pushalot;pushbullet;pushover;pushsafer;telegram
                                                -- pour plusieurs modes de notification séparez chaque mode par un point virgule (exemple : "pushalot;pushbullet"). si subsystem = nil toutes les notifications seront activées.
local les_compteurs = {};
-- 1er compteur : name ="nom du device compteur 1", nom (dummy) du capteur pourcentage probabilité surconsommation associé, seuil_notification = seuil pour l'envoie des notifications
les_compteurs[#les_compteurs+1] = {name="Compteur Eau Froide", dummy="Probabilité Fuite Eau Froide", seuil_notification=85}
-- 2eme compteur : name ="nom du device compteur 2", nom (dummy) du capteur pourcentage probabilité surconsommation associé, seuil_notification= seuil pour l'envoie des notifications
les_compteurs[#les_compteurs+1] = {name="Compteur Eau Chaude", dummy="Probabilité Fuite Eau Chaude", seuil_notification=85}

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = "détection fuite d\'eau"
local version = "2.3"
--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"   -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script
require('fonctions_perso')                                                      -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script

-- ci-dessous les lignes à décommenter en cas d'utilisation des fonctions directement dans ce script( supprimer --[[ et --]])
--[[function voir_les_logs (s, debugging) -- nécessite la variable local debugging
    if (debugging) then 
		if s ~= nil then
        print (s)
		else
		print ("aucune valeur affichable")
		end
    end
end	-- usage voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
--------------------------------------------
function url_encode(str) -- encode la chaine str pour la passer dans une url 
   if (str) then
   str = string.gsub (str, "\n", "\r\n")
   str = string.gsub (str, "([^%w ])",
   function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   end
   return str
end
--]]
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
commandArray = {}
time=os.date("*t")
-- ********************************************************************************
if script_actif == true then
    if ((time.min-1) % 5) == 0 then
        voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
        for i,d in ipairs(les_compteurs) do
        voir_les_logs("--- --- ---  Boucle ".. i .." --- --- --- ",debugging)
        v=otherdevices[d.name]
        if v==nil or v=="" then                  -- multi valued ?
            v=otherdevices_svalues[d.name] or ""
        end
        voir_les_logs("--- --- --- "..d.name.." idx : ".. otherdevices_idx[d.name] .." = ".. v .." litre(s)",debugging)
            if(uservariables[d.name.."_zero"] == nil) then -- Création de la variable  car elle n'existe pas
                voir_les_logs("--- --- --- La Variable " .. d.name .." n'existe pas --- --- --- ",debugging)
                commandArray['OpenURL'] = url..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(d.name.."_zero")..'&vtype=2&vvalue=1'
                adresse = url_encode(d.name)
                voir_les_logs("--- --- --- adresse " .. adresse .."_zero  --- --- --- ",debugging);
                voir_les_logs("--- --- --- Création de la Variable " .. d.name .."_zero manquante --- --- --- ",debugging)
                print('script supendu')
            end
            if(uservariables[d.name] == nil) then -- Création de la variable  car elle n'existe pas
                voir_les_logs("--- --- --- La Variable " .. d.name .." n'existe pas --- --- --- ",debugging)
                commandArray['OpenURL']=url..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(d.name)..'&vtype=2&vvalue=1'
                adresse = url_encode(d.name)
                voir_les_logs("--- --- --- adresse " .. adresse .."  --- --- --- ",debugging);
                voir_les_logs("--- --- --- Création de la Variable " .. d.name .." manquante --- --- --- ",debugging)
                print('script supendu')
            else
                if (tonumber(uservariables[d.name]) < tonumber(v) ) then --La  variable est inférieure au compteur => consommation d'eau
                    conso = tonumber(v) - tonumber(uservariables[d.name])
                    voir_les_logs("--- --- --- sur le "..d.name.." il a été consommé  : " .. conso .." Litre(s) --- --- --- ",debugging)		
                    commandArray[#commandArray+1] = {['Variable:'..d.name] = tostring(v)} -- Mise à jour Variable
                    voir_les_logs("--- --- ---  Mise à jour de la variable "..d.name.." --- --- --- ",debugging)
                    
                    if (d.name ~= "" and otherdevices_idx[d.dummy] ~= nil) then
                        voir_les_logs("--- --- --- valeur de la variable pourcentage "..otherdevices_svalues[d.dummy].."%  --- --- --- ",debugging)	--tonumber(otherdevices_svalues['lamp dimmer'])
                        local result = tonumber(otherdevices_svalues[d.dummy]) + 8
                        commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[d.dummy] .. "|0|" .. result} -- Mise à jour probabilité => 8% * (60/5) = 96% en 1 heure
                        
                    end
                end
                if (tonumber(uservariables[d.name]) == tonumber(v) ) then -- aucune consommation 
                    if (d.name ~= "" and otherdevices_idx[d.dummy] ~= nil) then
                        local result = "0"
                        commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[d.dummy] .. "|0|" .. result} -- Mise à jour probabilité à 0%
                        voir_les_logs("--- --- ---  Aucune consommation sur le "..d.name..", Mise à jour du device ".. otherdevices_idx[d.dummy] .." ".. d.dummy .." à zéro --- --- --- ",debugging)		
                    end				
                    voir_les_logs("--- --- ---  Aucune consommation sur le "..d.name.." --- --- --- ",debugging)
                end
                if tonumber(uservariables[d.name])~= nil and tonumber(uservariables[d.name]) > tonumber(v)  then --La  variable est supérieure au compteur => Mise à jour index consommation d'eau
                    conso =  tonumber(uservariables[d.name]) - tonumber(v)
                    voir_les_logs("--- --- --- sur le "..d.name.." il a un écart de  : " .. conso .." Litre(s) --- --- --- ",debugging)		
                    commandArray[#commandArray+1] = {['Variable:'..d.name] = tostring(v)} -- Mise à jour Variable
                    voir_les_logs("--- --- ---  Mise à jour de la variable "..d.name.." --- --- --- ",debugging)
                end					
            end
            voir_les_logs("--- --- --- Probabilité à  ".. 	otherdevices[d.dummy] .."% sur le "..d.name.." --- --- --- ",debugging) 
            if tonumber(otherdevices[d.dummy]) ~= nil and tonumber(otherdevices[d.dummy]) > d.seuil_notification then
            commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte surconsommation#surconsommation sur le ' ..d.name.. '! Probabilité à ' ..tonumber(otherdevices[d.dummy]).. '%'}
            end
        end  -- end for                                          

        voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
    end -- if time

    -- ********************************************************************************

    if (time.min == minute and time.hour == heure) then
        voir_les_logs("=========== ".. nom_script .." (v".. version ..") Début Période zéro consommation ===========",debugging)
        for i,d in ipairs(les_compteurs) do
            voir_les_logs("--- --- ---  Boucle ".. i .." --- --- --- ",debugging)
            v=otherdevices[d.name]                        
            if v==nil or v=="" then                  -- multi valued ?
                v=otherdevices_svalues[d.name] or ""
            end
            voir_les_logs("--- --- --- "..d.name.." = "..v,debugging)
            commandArray[#commandArray+1] = {['Variable:'..d.name.."_zero"] = tostring(v)} -- Mise à jour Variable
            voir_les_logs("--- --- ---  Mise à jour de la variable "..d.name.."_zero --- --- --- ",debugging)        
        end --end for
        local objet = 'Surveillance consommation d\'eau'
        local message = 'Début de la période surveillance zéro consommation à  '..heure..'h'..minute
        voir_les_logs("--- --- --- ".. message .." --- --- --- ",debugging)
        if EmailTo ~= nil then commandArray[#commandArray+1] = {['SendEmail'] =  objet..'#'.. message  .. '#' .. EmailTo} end
        voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") Début Période zéro consommation =========",debugging)
    end
    
    -- ******************************************************************************** 
    
    if (time.min == minute  and time.hour == (heure + delai)) then
        voir_les_logs("=========== ".. nom_script .." (v".. version ..") Fin Période zéro consommation ===========",debugging)
        for i,d in ipairs(les_compteurs) do
            voir_les_logs("--- --- ---  Boucle ".. i .." --- --- --- ",debugging)
            v=otherdevices[d.name]                        
            if v==nil or v=="" then                  -- multi valued ?
                v=otherdevices_svalues[d.name] or ""
            end
            voir_les_logs("--- --- --- "..d.name.." = "..v,debugging)
            if (tonumber(uservariables[d.name.."_zero"]) < tonumber(v) ) then -- La  variable est inférieure au compteur => consommation d'eau
                conso = tonumber(v) - tonumber(uservariables[d.name.."_zero"])
                voir_les_logs("--- --- --- sur le "..d.name.." il a été consommé  : " .. conso .." Litre(s) --- --- --- ",debugging)		
                
                if(otherdevices_idx[d.name] ~= "" and d.dummy ~= "") then
                    voir_les_logs("--- --- --- valeur de la variable pourcentage "..otherdevices_svalues[d.dummy].."%  --- --- --- ",debugging)	--tonumber(otherdevices_svalues['lamp dimmer'])                     
                    commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[d.dummy] .. "|0|100"} -- Mise à jour probabilité à100%
                local objet = 'Surveillance consommation d\'eau'
                local message = ' Une consommation d\'eau de ' .. conso ..' Litre(s) a été détectée sur le ' .. d.name .. ' entre '..heure..'h'..minute..' et '..heure + delai ..'h'..minute                    
                voir_les_logs("--- --- --- ".. message .." --- --- --- ",debugging)
                if EmailTo ~= nil then commandArray[#commandArray+1] = {['SendEmail'] =  objet..'#'.. message  .. '#' .. EmailTo} end
                    if notification > 0 then
                        if subsystem ~= nil then
                            voir_les_logs("--- --- --- Notification système activée pour le(s) service(s) "..subsystem,debugging)
                            commandArray[#commandArray+1] = {['SendNotification'] = objet..'#Une consommation d\'eau de ' .. conso ..' Litre(s) a été détectée sur le ' .. d.name .. ' entre '..heure..'h'..minute..' et '..heure + delai ..'h'..minute..'#0###'.. subsystem ..''}
                        else
                            voir_les_logs("--- --- --- toutes les Notifications système sont activées",debugging)
                            commandArray[#commandArray+1] = {['SendNotification'] = objet..'#Une consommation d\'eau de ' .. conso ..' Litre(s) a été détectée sur le ' .. d.name .. ' entre '..heure..'h'..minute..' et '..heure + delai ..'h'..minute}
                        end
                    end 
                end

                local objet = 'Surveillance consommation d\'eau'
                local message = 'consommation d\'eau détectée entre '..heure..'h'..minute..' et '..heure + delai ..'h'..minute
                if EmailTo ~= nil then commandArray[#commandArray+1] = {['SendEmail'] =  objet..'#'.. message  .. '#' .. EmailTo} end
            else
                local objet = 'Surveillance consommation d\'eau'
                local message = 'Aucune consommation d\'eau détectée entre '..heure..'h'..minute..' et '..heure + delai ..'h'..minute  
                voir_les_logs("--- --- --- ".. message .." --- --- --- ",debugging)
                if EmailTo ~= nil then commandArray[#commandArray+1] = {['SendEmail'] =  objet..'#'.. message  .. '#' .. EmailTo} end
                voir_les_logs("--- --- --- Aucune consommation sur le "..d.name.." --- --- --- ",debugging)
                if notification == 2 then
                    if subsystem ~= nil then
                        voir_les_logs("--- --- --- Notification système activée pour le(s) service(s) "..subsystem,debugging)
                        commandArray[#commandArray+1] = {['SendNotification'] = objet..'#Aucune consommation d\'eau détectée sur le ' .. d.name .. ' entre '.. heure ..'h'.. minute ..' et '.. heure + delai ..'h'.. minute ..'#0###'.. subsystem ..''}
                    else
                        voir_les_logs("--- --- --- toutes les Notifications système sont activées",debugging)
                        commandArray[#commandArray+1] = {['SendNotification'] = objet..'#Aucune consommation d\'eau détectée sur le ' .. d.name .. ' entre '.. heure ..'h'.. minute ..' et '.. heure + delai ..'h'.. minute}
                    end
                end
            end
        end --end for
        voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") Fin Période zéro consommation =========",debugging)
    end    
end -- if script_actif
return commandArray
