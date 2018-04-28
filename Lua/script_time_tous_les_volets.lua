--[[
name : script_time_tous_les_volets.lua
auteur : papoo
Date de mise à jour : 28/04/2018
date de création : 08/08/2016
Principe : permet d'automatiser la gestion des volets roulants 
en fonction de l'heure de levé et couché du soleil et forte luminosité
]]--

--------------------------------------------
-- Les différents états d'un volet Stopped Open Closed
--------------------------------------------
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false  			            -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif = true                       -- active (true) ou désactive (false) ce script simplement
local ip = '127.0.0.1:8080'                     -- user:pass@ip:port de domoticz
local sonde_ext = 'Temperature exterieure'      -- nom de la sonde de température extérieure
local lumiere = nil                             -- tonumber(otherdevices_svalues['Lux']) -- nom du bloc Lux de wheather underground
local lux_max = tonumber(90000)                 -- seuil à parti duquel on ferme les volets en pleine journée
local delai_apres_leve_soleil = tonumber(75)    -- délai en minutes pour l'ouverture des volets après levé du soleil
local delai_apres_couche_soleil = tonumber(45)  -- délai en minutes pour la fermeture des volets après couché du soleil
local delai_on_off = tonumber(30)               -- délai minimum en minutes pour la réouverture des volets après fermeture
local inter_vacances = 'Volets automatique'     -- Penser à créer un interrupteur Vacances valeur 'On' pour en vacances
local timeridx = nil                            -- idx du timer douche '2'
--------------------------------------------
-- Tableau des volets
--------------------------------------------
local les_volets = {}; -- les_volets[#les_volets+1] = {volet="", Type=""}
-- 1ere volet : nom du device volet 1
les_volets[#les_volets+1] = {volet="Salon sur Rue", Type="somfy"} -- Possibilité d'ajouter des équipements en relation, comme température piece, etat ouverture fenetre, etc (séparé par une  virgule)
-- 2eme volet : nom du device volet 2 
les_volets[#les_volets+1] = {volet="Salon sur Jardin", Type="somfy"} -- exemple {volet="Salon sur Jardin", temperature="Temperature Salon", fenetre="Fenetre Salon sur Jardin"}
-- 3eme volet : nom du device volet 3
les_volets[#les_volets+1] = {volet="Cuisine", Type="somfy"}
-- 4eme volet : nom du device volet 4 
les_volets[#les_volets+1] = {volet="Chambre Parents", Type="somfy"}
-- 5eme volet : nom du device volet 5 
les_volets[#les_volets+1] = {volet="Chambre 1", Type="somfy"}
-- 6eme volet : nom du device volet 6 
les_volets[#les_volets+1] = {volet="Chambre 2", Type="velux"}
-- 7eme volet : nom du device volet 7 
-- les_volets[7] = {volet="Volet Douche", Type="velux"}

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = 'Tous les volets'
local version = '1.17'
local heures = 0
local minutes = 0
local secondes = 0 
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
function round(value, digits) -- arrondi
  local precision = 10^digits
  return (value >= 0) and
      (math.floor(value * precision + 0.5) / precision) or
      (math.ceil(value * precision - 0.5) / precision)
end
--------------------------------------------
-- retourne le temps en minutes depuis la dernière màj du périphérique
function TimeDiff(device)
  timestamp = otherdevices_lastupdate[device] or device
  y, m, d, H, M, S = timestamp:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
difference = round((os.difftime(os.time(), os.time{year=y, month=m, day=d, hour=H, min=M, sec=S})/60), 0)
  return difference
end
--]]
 --------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------

commandArray = {}

voir_les_logs("========= ".. nom_script .." (v".. version ..") =========",debugging)
if script_actif == true and otherdevices[inter_vacances] == 'On' then
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
    voir_les_logs("--- --- --- Heure actuelle : "..time.."("..timeInMinutes..")",debugging)
    voir_les_logs('--- --- --- Température extérieure : '..temperature_exterieure,debugging)
    voir_les_logs("--- --- --- Heure de couché du soleil en minutes : "..timeofday['SunsetInMinutes'],debugging);
    voir_les_logs("--- --- --- Heure de fermeture des stores en minutes : "..timeofday['SunsetInMinutes']+ delai_apres_couche_soleil,debugging)
    voir_les_logs("--- --- --- Heure de levé du soleil en minutes : "..timeofday['SunriseInMinutes'],debugging);
    voir_les_logs("--- --- --- Heure d'ouverture des stores en minutes : "..timeofday['SunriseInMinutes'] + delai_apres_leve_soleil,debugging)
    voir_les_logs("--- --- --- Heure de couché du soleil en minutes : "..timeofday['SunsetInMinutes'],debugging);
    voir_les_logs("--- --- --- Heure de fermeture des stores en minutes : "..timeofday['SunsetInMinutes']+ delai_apres_couche_soleil,debugging)
    voir_les_logs("--- --- --- Heure de levé du soleil en minutes : "..timeofday['SunriseInMinutes'],debugging);
    voir_les_logs("--- --- --- Heure d'ouverture des stores en minutes : "..timeofday['SunriseInMinutes'] + delai_apres_leve_soleil,debugging)
    voir_les_logs('--- --- --- delai entre 2 mouvements des volets : '..delai_on_off..' minute(s)',debugging) 
    for k,v in pairs(les_volets) do-- On parcourt chaque volet
        voir_les_logs('--- --- ---',debugging);
        voir_les_logs('--- --- --- Gestion du volet : '..v.volet,debugging);
        voir_les_logs('--- --- --- Position du volet : '..otherdevices[v.volet],debugging)
        voir_les_logs('--- --- --- dernier mouvement du volet : '..TimeDiff(v.volet)..' minute(s)',debugging)
        -- Pendant la Journée
        if (tonumber(timeInMinutes) > timeofday['SunriseInMinutes'] + delai_apres_leve_soleil and tonumber(timeInMinutes) < timeofday['SunsetInMinutes'] + delai_apres_couche_soleil) then --Pendant la journée
            voir_les_logs('--- --- --- Apres le levé du soleil',debugging)
            if ( otherdevices[v.volet]=='Closed' or otherdevices[v.volet]=='Stopped' )	and TimeDiff(v.volet) > delai_on_off then
                voir_les_logs ('--- --- --- Le volet : "'..v.volet..'" doit être ouvert',debugging)
                voir_les_logs ('--- --- --- Le volet est Fermé ==> Ouverture',debugging)
                if ( v.Type == "somfy") then
                    commandArray[v.volet]='Off'
                else
                    commandArray[v.volet]='On'
                end
            end
            if lumiere ~= nil and ( lumiere > lux_max )	then
                voir_les_logs("--- --- --- Lux : "..lumiere,debugging)
                voir_les_logs ('--- --- --- Le volet : "'..v.volet..'" doit être fermé',debugging)
                voir_les_logs ('--- --- --- Le volet est ouvert ==> fermeture',debugging)
                if ( v.Type == "somfy") then
                    commandArray[v.volet]='On'
                else
                    commandArray[v.volet]='Off'
                end
            end
        end
        -- Pendant la Nuit	
        if (tonumber(timeInMinutes) < timeofday['SunriseInMinutes'] + delai_apres_leve_soleil or tonumber(timeInMinutes) > timeofday['SunsetInMinutes'] + delai_apres_couche_soleil) then --Pendant la nuit
            voir_les_logs('--- --- --- Apres le couché du soleil',debugging)
            if ( otherdevices[v.volet]=='Open' or otherdevices[v.volet]=='Stopped' ) then
                voir_les_logs ('--- --- --- Le volet : "'..v.volet..'" doit être fermé',debugging)
				voir_les_logs ('--- --- ---Le volet est ouvert ==> fermeture',debugging)
                if ( v.Type == "somfy") then
                    commandArray[v.volet]='On'
                else
                    commandArray[v.volet]='Off'
                end
            end
        end
    end -- end For
    else
        --désactivation du planning volet douche
        if timeridx ~= nil then 
            commandArray[#commandArray+1]={['OpenURL']=ip..'/json.htm?type=command&param=disabletimer&idx='.. timerID}
        end
end -- if vacances
voir_les_logs("======= Fin ".. nom_script .." (v".. version ..") =======",debugging)
return commandArray 
