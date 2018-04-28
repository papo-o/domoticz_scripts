--[[   
script_time_meteofrance_pluie.lua
Download JSON.lua : http://regex.info/blog/lua/json 
auteur : papoo
maj : 28/04/2018
date : 11/05/2016
Principe :	V1 récupérer via l'API non documentée de météo France, les informations de précipitation 
de votre commune sur un device text et/ou alert et/ou notifications. http://easydomoticz.com/forum/viewtopic.php?f=10&t=1991
			V2 en plus des fonctions de la V1, Afficher via les variables utilisateurs, les prédictions de précipitations sur une heure par pas de 5 mn sur la custom page
avec création automatiques des variables nécessaire à l'exécution de ce script.	http://easydomoticz.com/forum/viewtopic.php?f=10&t=2788
Actualisation des données toutes les 5 minutes, couleurs et texte directement récupérés via l'api	
pour trouver le code de votre commune => http://www.insee.fr/fr/methodes/nomenclatures/cog/
									Dans le cas de l'utilisation de la variable ActivePage  il vous faut ajouter 
									dans la partie mqtt du fichier frontpage_settings.js de la Custom Page ceci :

											case "d4": // nom du bouton de la télécommande
					  
											  if (message.nvalue == 0){      // status On 
											  
												 memo = $("div").find("[data-index=4]").remove();   // mémorisation page 5 et suppression
												 mySwipe.setup();                           // réorganisation
												 if (mySwipe.getPos() == 4)                     // si nous sommes sur la page supprimée
													mySwipe.slide(3);                        // déplacement vers la page précédente ( la 4 )
												 
											  }   
											  if (message.nvalue == 1){      // status Off
																
												 
												 $("div").find("[data-index=3]").after( memo );      // rajout de la page 5 juste après la page 4
												 mySwipe.setup();                           // réorganisation
												 mySwipe.slide(4);                           // déplacement vers la page rajoutée
												 
											  }  
									
									Si votre device ne s'appelle pas "d4" pnsez à modifier la variable ActivePage dans ce script avec  le même nom de device dans le fichier frontpage_settings.js
--]]



--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false				-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local ip = "127.0.0.1:8080" 		-- <username:password@>domoticz-ip<:port>
local CityCode = 870850 			-- Le code de votre ville est l'ID retourné par cette URL : http://www.meteofrance.com/mf3-rpc-portlet/rest/lieu/facet/pluie/search/nom_de_votre_ville
local text_idx = 343 				-- renseigner l'idx du device text associé si souhaité, sinon nil
local rain_alert_idx = 699  		-- renseigner l'idx du device alert associé si souhaité, sinon nil
local send_notification = 0 		-- 0: aucune notification, 1: toutes, 2: précipitations faibles, modérées et fortes, 3: modérées et fortes, 4: seulement fortes
local CustomPage = "oui"			-- pour afficher les prévisions de pluie à une heure sur la custom page via des variables, valeurs acceptées : oui ou nil
local ActivePage = "d4"				-- renseigner l'idx du device switch associé si souhaité, sinon nil pour afficher ou masquer la page des prévisions de pluie sur la custom page	


--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = "script_time_meteofrance_pluie"
local version = "2.33"
local VariablesPluie={}
VariablesPluie[1]={nom = "Pluie à 5mn",idx = "1"} 
VariablesPluie[2]={nom = "Pluie à 10mn",idx = "2"}
VariablesPluie[3]={nom = "Pluie à 15mn",idx = "3"}
VariablesPluie[4]={nom = "Pluie à 20mn",idx = "4"}
VariablesPluie[5]={nom = "Pluie à 25mn",idx = "5"}
VariablesPluie[6]={nom = "Pluie à 30mn",idx = "6"}
VariablesPluie[7]={nom = "Pluie à 35mn",idx = "7"}
VariablesPluie[8]={nom = "Pluie à 40mn",idx = "8"}
VariablesPluie[9]={nom = "Pluie à 45mn",idx = "9"}
VariablesPluie[10]={nom = "Pluie à 50mn",idx = "10"}
VariablesPluie[11]={nom = "Pluie à 55mn",idx = "11"}
VariablesPluie[12]={nom = "Pluie à 60mn",idx = "12"}

commandArray = {}
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"   -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script
require('fonctions_perso')                                                      -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script

-- ci-dessous les lignes à décommenter en cas d'utilisation des fonctions directement dans ce script( supprimer --[[ et --]])
--[[
function voir_les_logs (s, debugging) -- nécessite la variable local debugging
if (debugging) then 
		if s ~= nil then
        print (s)
		else
		print ("aucune valeur affichable")
		end
    end
end	-- usage voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
------------------------------------------

function format(str)
   if (str) then
      str = string.gsub (str, "De", "De ")
      str = string.gsub (str, " ", "&nbsp;")
      str = string.gsub (str, "Pas&nbsp;de&nbsp;précipitations", "<font color='#999'>Pas&nbsp;de&nbsp;précipitation</font>")
      str = string.gsub (str, "Précipitations&nbsp;faibles", "<font color='#fbda21'>Précipitations&nbsp;faibles</font>")
      str = string.gsub (str, "Précipitations&nbsp;modérées", "<font color='#fb8a21'>Précipitations&nbsp;modérées</font>")
      str = string.gsub (str, "Précipitations&nbsp;fortes", "<font color='#f3031d'>Précipitations&nbsp;fortes</font>")
   end
   return str   
end
function url_encode(str)
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
time = os.date("*t")
if ((time.min-1) % 5) == 0 then -- toutes les 5 minutes en commençant par xx:01
	--if time.min % 5 == 0 then -- toutes les 5 minutes

		voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)

	 local delay = os.time()
	-- chemin vers le dossier lua
	if (package.config:sub(1,1) == '/') then
		 luaDir = debug.getinfo(1).source:match("@?(.*/)")
	else
		 luaDir = string.gsub(debug.getinfo(1).source:match("@?(.*\\)"),'\\','\\\\')
	end
	 curl = '/usr/bin/curl -m 5 -u domoticzUSER:domoticzPSWD '		 	-- ne pas oublier l'espace à la fin
	 json = assert(loadfile(luaDir..'JSON.lua'))()						-- chargement du fichier JSON.lua
	   
	
	local config=assert(io.popen('curl -m 8 http://www.meteofrance.com/mf3-rpc-portlet/rest/pluie/'..CityCode..'.json'))
	local location = config:read('*all')
	   config:close()
		if location ~= nil then
            local jsonLocation = json:decode(location)
            if jsonLocation ~= nil then
                   local niveauPluieText={}   
                   niveauPluieText = jsonLocation.niveauPluieText
                   -- concaténation des entrées de la table et formatage
                   local PluieText = ''
                    if niveauPluieText ~= nil then
                        for Index, Value in pairs( niveauPluieText ) do
                          PluieText = PluieText..format(Value)..' '
                          voir_les_logs("--- --- --- niveauPluieText["..Index.."] : ".. Value .." --- --- ---",debugging)  
                        end
                        voir_les_logs("--- --- --- PluieText : ".. PluieText .. " --- --- ---",debugging)  
                    end
                        if CustomPage ~= nil then
                            --Récuperation des informations toutes les 5mn pour rafraichir les données des variables
                           local dataCadran={}   
                           dataCadran = jsonLocation.dataCadran
                           local InfoNiveauPluieText = {}
                           local InfoNiveauPluie = {}
                           local InfoColor = {}
                            if dataCadran ~= nil then
                                for i, Result in ipairs( dataCadran ) do
                                 InfoNiveauPluieText[i] = Result.niveauPluieText
                                 InfoNiveauPluie[i] = Result.niveauPluie
                                 InfoColor[i] = Result.color	
                                 voir_les_logs("--- --- --- index : ".. i .. "  Info : "..  InfoNiveauPluieText[i].. " Niveau : "..  InfoNiveauPluie[i] .. " couleur :" ..  InfoColor[i] .. " --- --- ---",debugging) 
                                end
                            end
                            for key, valeur in pairs(VariablesPluie) do	
                                if(uservariables[valeur.nom] == nil) then
                                    commandArray[#commandArray+1]={['OpenURL']=ip..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(valeur.nom)..'&vtype=2&vvalue='..url_encode(tostring("<font color='#".. InfoColor[key] .."'>".. InfoNiveauPluieText[key] .."</font>"))}
                                   
                                    voir_les_logs("--- --- --- creation variable manquante "..valeur.nom.."  --- --- --- ",debugging)
                                else 
                                voir_les_logs("--- --- --- key :" .. key .." - "..valeur.nom.."  --- --- --- ",debugging)
                                commandArray['Variable:'..valeur.nom] =	tostring("<font color='#".. InfoColor[key] .."'>".. InfoNiveauPluieText[key] .."</font>")
                                end
                            end	
                        end	
                   if text_idx ~= nil and PluieText ~= nil then -- pour l'affichage dans un device text
                      commandArray[#commandArray+1] = {['UpdateDevice'] = text_idx .. '|0| ' .. PluieText}
                   end
                        
                   if string.find(niveauPluieText[1], "Pas de précipitations")  then
                      if rain_alert_idx ~= nil then
                         commandArray[#commandArray+1] = {['UpdateDevice'] = rain_alert_idx..'|1|Pas de précipitations'}
                         
                             if CustomPage ~= nil and ActivePage ~= nil then 
                             commandArray[ActivePage]='Off'
                             end
                      end
                      if send_notification > 0 and send_notification < 2 then
                         commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte Météo#Pas de précipitations prévue!'}
                         
                      end
                      voir_les_logs("--- --- --- Pas de précipitations --- --- ---",debugging)

                   elseif string.find(niveauPluieText[1], "faibles")  then
                      if rain_alert_idx ~= nil then
                         commandArray[#commandArray+1] = {['UpdateDevice'] = rain_alert_idx..'|2|Précipitations Faibles'}
                         
                             if CustomPage ~= nil and ActivePage ~= nil then 
                             commandArray[ActivePage]='On'
                             end
                      end
                      if send_notification > 0 and send_notification < 3 then
                         commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte Météo#Précipitations Faibles!'}
                         
                      end
                      voir_les_logs("--- --- --- Précipitations Faibles --- --- ---",debugging)   


                   elseif string.find(niveauPluieText[1], "modérées")  then
                      if rain_alert_idx ~= nil then
                         commandArray[#commandArray+1] = {['UpdateDevice'] = rain_alert_idx..'|3|Précipitations modérées'}
                         
                             if CustomPage ~= nil and ActivePage ~= nil then 
                             commandArray[ActivePage]='On'
                             end
                      end
                      if send_notification > 0 and send_notification < 4 then
                         commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte Météo#Précipitations modérées!'}
                         
                      end
                      voir_les_logs("--- --- --- Précipitations modérées --- --- ---",debugging)      


                   elseif string.find(niveauPluieText[1], "fortes")  then
                      if rain_alert_idx ~= nil then
                         commandArray[#commandArray+1] = {['UpdateDevice'] = rain_alert_idx..'|4|Précipitations fortes'}
                         
                             if CustomPage ~= nil and ActivePage ~= nil then 
                             commandArray[ActivePage]='On'
                             end
                      end
                      if send_notification > 0 and send_notification < 5 then
                         commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte Météo#Précipitations fortes!'}
                         
                      end
                      voir_les_logs("--- --- --- Précipitations fortes --- --- ---",debugging)

                   else
                      print("niveau non defini")
                   end

                    delay = os.time() - delay 
                    voir_les_logs("--- --- --- Delai d'execution du script : " .. delay .."ms --- --- ---",debugging)	
                    voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
            else
                print("Erreur lors du decodage du fichier JSON dans le script ".. nom_script)
            end        
		else 
            print("Delai d'execution de la commande Curl trop longue dans le script ".. nom_script)
		end
end --if time
return commandArray
