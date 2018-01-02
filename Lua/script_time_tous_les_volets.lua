--[[
name : script_time_tous_les_volets.lua
auteur : papoo
version : 1.15
date de création : 08/08/2016
Date de mise à jour : 02/01/2018
Principe : permet d'automatiser la gestion des volets roulants 
en fonction de l'heure de levé et couché du soleil et forte luminosité
]]--

---------------------------------------------------------------------------
-- Les différents états d'un volet Stopped Open Closed
---------------------------------------------------------------------------
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false  			-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local ip = '127.0.0.1:8080'   -- user:pass@ip:port de domoticz
local sonde_ext = 'Temperature exterieure' -- nom de la sonde de température extérieure
--local lumiere =  tonumber(otherdevices_svalues['Lux']) -- nom du bloc Lux de wheather underground
--local lux_max = tonumber(90000) -- seuil à parti duquel on ferme les volets en pleine journée
local delai_apres_leve_soleil = tonumber(75) -- delai en minutes pour l'ouverture des volets après levé du soleil
local delai_apres_couche_soleil = tonumber(45) -- delai en minutes pour la fermeture des volets après couché du soleil
local inter_vacances = 'Volets automatique' --Penser à créer un interrupteur Vacances valeur 'On' pour en vacances
local timeridx = nil -- idx du timer douche '2'
---------------------------------------------------------------------------
-- Tableau des volets
---------------------------------------------------------------------------
local les_volets = {}; -- les_volets[#les_volets+1] = {volet="", idx="", Type=""}
-- 1ere volet : nom du device volet 1
les_volets[#les_volets+1] = {volet="Salon sur Rue", idx=361, Type="somfy"} -- Possibilité d'ajouter des équipements en relation, comme température piece, etat ouverture fenetre, etc (séparé par une  virgule)
-- 2eme volet : nom du device volet 2 
les_volets[#les_volets+1] = {volet="Salon sur Jardin", idx=362, Type="somfy"} -- exemple {volet="Salon sur Jardin", temperature="Temperature Salon", fenetre="Fenetre Salon sur Jardin"}
-- 3eme volet : nom du device volet 3
les_volets[#les_volets+1] = {volet="Cuisine", idx=363, Type="somfy"} -- La déclaration de l'idx {idx=xxx} ne sert qu'en cas d'utilisation de la commande via json, (ligne à décommenter)
-- 4eme volet : nom du device volet 4 
les_volets[#les_volets+1] = {volet="Chambre Parents", idx=364, Type="somfy"}
-- 5eme volet : nom du device volet 5 
les_volets[#les_volets+1] = {volet="Chambre 1", idx=365, Type="somfy"}
-- 6eme volet : nom du device volet 6 
les_volets[#les_volets+1] = {volet="Chambre 2", idx=473, Type="velux"}
-- 7eme volet : nom du device volet 7 
-- les_volets[7] = {volet="Volet Douche", idx=628, Type="velux"}

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
	
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
function voir_les_logs (s, debugging)
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>")
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>")
		end
    end
end	
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------

commandArray = {}

if ( otherdevices[inter_vacances] == 'On')	then
--activation du planning volet douche
	if timeridx ~= nil then 
	commandArray[#commandArray+1]={['OpenURL']=ip..'/json.htm?type=command&param=enabletimer&idx='.. timerID}
	
	end
time=os.time()
local minutes=tonumber(os.date('%M',time))
local hours=tonumber(os.date('%H',time))
local timeInMinutes = hours * 60 + minutes;
if (minutes<10) then minutes='0'..minutes..'' end
if (hours<10) then hours='0'..hours..'' end

local time=''..hours..':'..minutes
local temperature_exterieure = otherdevices_temperature[sonde_ext]

print ("=========== Gestion Des Volets (v1.0) ===========")
voir_les_logs("--- --- --- Heure actuelle : "..time.."("..timeInMinutes..")",debugging)
voir_les_logs('--- --- --- Température extérieure : '..temperature_exterieure,debugging)
voir_les_logs("--- --- --- Heure de couché du soleil en minutes : "..timeofday['SunsetInMinutes'],debugging);
voir_les_logs("--- --- --- Heure de fermeture des stores en minutes : "..timeofday['SunsetInMinutes']+ delai_apres_couche_soleil,debugging)
voir_les_logs("--- --- --- Heure de levé du soleil en minutes : "..timeofday['SunriseInMinutes'],debugging);
voir_les_logs("--- --- --- Heure d'ouverture des stores en minutes : "..timeofday['SunriseInMinutes'] + delai_apres_leve_soleil,debugging)
--voir_les_logs("--- --- --- Lux : "..lumiere,debugging);

	for k,v in pairs(les_volets) do-- On parcourt chaque volet
voir_les_logs('--- --- ---',debugging);
 print ('--- --- --- Gestion du volet : '..v.volet)

voir_les_logs('--- --- --- Position du volet : '..otherdevices[v.volet],debugging)
-- Pendant la Journée
		if (tonumber(timeInMinutes) > timeofday['SunriseInMinutes'] + delai_apres_leve_soleil and tonumber(timeInMinutes) < timeofday['SunsetInMinutes'] + delai_apres_couche_soleil) then --Pendant la journée
voir_les_logs('--- --- --- Apres le levé du soleil',debugging)

			if ( otherdevices[v.volet]=='Closed' or otherdevices[v.volet]=='Stopped' )	then
				voir_les_logs ('--- --- --- Le volet : "'..v.volet..'" doit être ouvert',debugging)
				voir_les_logs ('--- --- --- Le volet dont l\'idx est : "'..v.idx..'" doit être Ouvert',debugging)
				 print('--- --- --- Le volet est Fermé ==> Ouverture');
				 --oss = "curl 'http://127.0.0.1:8080/json.htm?type=command&param=switchlight&idx='..v.idx..'&switchcmd=Off'
				 --os.execute(oss)
				
						if ( v.Type == "somfy") then
						commandArray[v.volet]='Off'
						else
						commandArray[v.volet]='On'
						end
				
			end
				--[[if ( lumiere > lux_max  )	then
				voir_les_logs ('--- --- --- Le volet : "'..v.volet..'" doit être fermé',debugging)
				-- voir_les_logs ('--- --- --- Le volet idx : "'..v.volet.idx..'" doit être fermé',debugging)
				 print('--- --- --- Le volet est ouvert ==> fermeture');
				--oss = "curl 'http://127.0.0.1:8080/json.htm?type=command&param=switchlight&idx='..v.idx..'&switchcmd=On'
				--os.execute(oss)
			
						if ( v.Type == "somfy") then
						commandArray[v.volet]='On'
						else
						commandArray[v.volet]='Off'
						end
							
				end]]--
		end
				
-- Pendant la Nuit	
		if (tonumber(timeInMinutes) < timeofday['SunriseInMinutes'] + delai_apres_leve_soleil or tonumber(timeInMinutes) > timeofday['SunsetInMinutes'] + delai_apres_couche_soleil) then --Pendant la nuit
voir_les_logs('--- --- --- Apres le couché du soleil',debugging)

			if ( otherdevices[v.volet]=='Open' or otherdevices[v.volet]=='Stopped' ) then
				voir_les_logs ('--- --- --- Le volet : "'..v.volet..'" doit être fermé',debugging)
				voir_les_logs ('--- --- --- Le volet dont l\'idx est : "'..v.idx..'" doit être Fermé',debugging)
				 print('--- --- ---Le volet est ouvert ==> fermeture')
				--oss = "curl 'http://127.0.0.1:8080/json.htm?type=command&param=switchlight&idx='..v.idx..'&switchcmd=On'
				--os.execute(oss)

						if ( v.Type == "somfy") then
						commandArray[v.volet]='On'
						else
						commandArray[v.volet]='Off'
						end

			end
		end
	end -- end For
voir_les_logs('--- --- ---',debugging);
print ("=========== Fin de gestion des volets ===========")
else
--désactivation du planning volet douche
	if timeridx ~= nil then 
	commandArray[#commandArray+1]={['OpenURL']=ip..'/json.htm?type=command&param=disabletimer&idx='.. timerID}
	
	end
end -- if vacances

return commandArray 