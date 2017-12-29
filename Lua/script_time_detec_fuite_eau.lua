--[[script_time_detec_fuite_eau.lua
auteur : papoo
MAJ : 03/04/2017
Création : 25/04/2016
Principe : 
vérification de la consommation d'eau toutes les 5mn par comparaison avec l'index précédent, présent dans une variable utilisateur 
(créée automatiquement lors de la première exécution du script). si l'index compteur et l'index -5mn sont identique le device probabilité est remis à zéro (pas de fuite)
si l'index compteur et l'index -5mn sont différents = consommation d'eau, incrémentation du device probabilité de 8% et mise à jour de la variable associée
si il y a une consommation continue pendant une heure, le device probabilité aura été incrémenté 12 fois, le device probabilité sera donc à 96% => très forte probabilité
Le seuil de notification est paramétrable via la variable seuil_notificationication . Possibilité de surveiller plusieurs compteurs
Le script est lu toutes les minutes mais ne vérifie les données que toutes les 5 minutes
http://pon.fr/script-detection-fuite-deau
http://easydomoticz.com/forum/viewtopic.php?f=8&t=1913&hilit=d%C3%A9tection+fuite+eau#p16950
]]--

--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local nom_script = "detection fuite d\'eau"
local version = "1.22"
local debugging = false  			-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local url = '127.0.0.1:8080'   	-- user:pass@ip:port de domoticz
local les_compteurs = {};
-- 1er compteur : name ="nom du device compteur 1", idx=idx et  nom (dummy) du capteur pourcentage probabilité surconsommation associé, seuil_notification= seuil pour l'envoie des notifications
les_compteurs[1] = {name="Compteur Eau Froide", idx=643, dummy="Probabilité Fuite Eau Froide", seuil_notification=50}
-- 2eme compteur : name ="nom du device compteur 2", idx=idx du capteur pourcentage probabilité surconsommation associé ("" si inexistant), seuil_notification= seuil pour l'envoie des notifications
les_compteurs[2] = {name="Compteur Eau Chaude", idx=644, dummy="Probabilité Fuite Eau Chaude", seuil_notification=85}

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------

--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"
require('fonctions_perso')
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------

commandArray = {}
time=os.date("*t")

-- ********************************************************************************

-- if time.min % 5 == 0 then
if ((time.min-1) % 5) == 0 then
	voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
			    for i,d in ipairs(les_compteurs) do
	voir_les_logs("--- --- ---  Boucle ".. i .." --- --- --- ",debugging)

    v=otherdevices[d.name]                        
					if v==nil or v=="" then                  -- multi valued ?
					v=otherdevices_svalues[d.name] or ""
					voir_les_logs("--- --- --- "..d.name.." = "..v,debugging);
					end
		
			if(uservariables[d.name] == nil) then -- Création de la variable  car elle n'existe pas
				voir_les_logs("--- --- --- La Variable " .. d.name .." n'existe pas --- --- --- ",debugging)
				commandArray['OpenURL']=url..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(d.name)..'&vtype=2&vvalue=1'
				adresse = url_encode(d.name)
				voir_les_logs("--- --- --- adresse " .. adresse .."  --- --- --- ",debugging);
				voir_les_logs("--- --- --- Création de la Variable " .. d.name .." manquante --- --- --- ",debugging)
				print('script supendu')
			else
				--voir_les_logs("--- --- --- la Variable : "..d.name.." existe",debugging);
			
					if (tonumber(uservariables[d.name]) < tonumber(v) ) then --La  variable est inferieure au compteur => consommation d'eau
						conso = tonumber(v) - tonumber(uservariables[d.name])
						voir_les_logs("--- --- --- sur le "..d.name.." il a été consommé  : " .. conso .." Litre(s) --- --- --- ",debugging)		
						commandArray[#commandArray+1] = {['Variable:'..d.name] = tostring(v)} -- Mise à jour Variable
						voir_les_logs("--- --- ---  Mise à jour de la variable "..d.name.." --- --- --- ",debugging)
						
							if(d.idx ~= "" and d.dummy ~= "") then
								voir_les_logs("--- --- --- valeur de la variable pourcentage "..otherdevices_svalues[d.dummy].."%  --- --- --- ",debugging)	--tonumber(otherdevices_svalues['lamp dimmer'])
								local result = tonumber(otherdevices_svalues[d.dummy]) + 8
								commandArray[#commandArray+1] = {['UpdateDevice'] = d.idx .. "|0|" .. result} -- Mise à jour probabilité => 8% * (60/5) = 96% en 1 heure
								
							end
					end
					if (tonumber(uservariables[d.name]) == tonumber(v) ) then -- aucune consommation 
							if(d.idx ~= "" and d.dummy ~= "") then
								local result = "0"
								commandArray[#commandArray+1] = {['UpdateDevice'] = d.idx .. "|0|" .. result} -- Mise à jour probabilité à 0%
						voir_les_logs("--- --- ---  Aucune consommation sur le "..d.name..", Mise à jour du device ".. d.idx .." ".. d.dummy .." à zéro --- --- --- ",debugging)		
								
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
	end                                            
   voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end -- if time


-- ********************************************************************************

return commandArray
