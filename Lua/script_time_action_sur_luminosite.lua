--[[   
~/domoticz/scripts/lua/script_time_action_sur_luminosite.lua
auteur : papoo
MAJ : 28/04/2018
création : 02/01/2018
Principe :
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging = false  			                -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local lum ='Luminosité Salon'
local seuil = 2
local lum_rdc_1 = 'lumiere_rdc_3'
local delai_apres_leve_soleil = tonumber(0) -- delai en minutes 
local delai_apres_couche_soleil = tonumber(60) -- delai en minutes 
--------------------------------------------
----------- Fin variables à éditer ---------
-------------------------------------------- 
commandArray = {}
local nom_script = 'Action sur seuil luminosité'
local version = '0.02'
time=os.date("*t")
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
curl = '/usr/bin/curl -m 15 -u domoticzUSER:domoticzPSWD '
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
function round(value, digits)
	if not value or not digits then
		return nil
	end
		local precision = 10^digits
		return (value >= 0) and
		  (math.floor(value * precision + 0.5) / precision) or
		  (math.ceil(value * precision - 0.5) / precision)
end
--]]
--------------------------------------------
function calc_dju(temperature)
dju  = tonumber((18 - temperature)*1/1440)
return dju
end
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
-------------------------------------------- 
function creaVar(vname,vtype,vvalue) -- pour créer une variable de type 2 nommée toto comprenant la valeur 10
	os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(vname)..'&vtype='..vtype..'&vvalue='..url_encode(vvalue)..'" &')
end -- usage :  creaVar('toto','2','10')  
--------------------------------------------
-- Obtenir le nom d'un device via son idx
function GetDeviceNameByIDX(deviceIDX) -- https://www.domoticz.com/forum/viewtopic.php?t=18736#p144720
    deviceIDX = tonumber(deviceIDX)
   for i, v in pairs(otherdevices_idx) do
      if v == deviceIDX then
         return i
      end
   end
   return 0
end -- exemple usage = commandArray[GetDeviceNameByIDX(383)] = 'On'
--------------------------------------------
-- Obtenir l'idx d'un device via son nom
function GetDeviceIdxByName(deviceName) 
   for i, v in pairs(otherdevices_idx) do
      if i == deviceName then
         return v
      end
   end
   return 0
end -- exemple usage = commandArray['UpdateDevice'] = GetDeviceIdxByName('Compteur Gaz') .. '|0|' .. variable
--------------------------------------------
-- Function to strip charachters
function
 stripchars(str, chrs)
 local s = str:gsub("["..chrs.."]", '')
 return s
end
--------------------------------------------
-------------- Fin Fonctions ---------------
-------------------------------------------- 
time=os.time()
local minutes=tonumber(os.date('%M',time))
local hours=tonumber(os.date('%H',time))
local timeInMinutes = hours * 60 + minutes;
if (minutes<10) then minutes='0'..minutes..'' end
if (hours<10) then hours='0'..hours..'' end

local time=''..hours..':'..minutes
voir_les_logs("========= ".. nom_script .." (v".. version ..") =========",debugging)
voir_les_logs("--- --- --- Heure actuelle : "..time.."("..timeInMinutes..")",debugging)
voir_les_logs("--- --- --- Heure de couché du soleil en minutes : "..timeofday['SunsetInMinutes'],debugging);
voir_les_logs("--- --- --- Heure de fermeture des stores en minutes : "..timeofday['SunsetInMinutes']+ delai_apres_couche_soleil,debugging)
voir_les_logs("--- --- --- Heure de levé du soleil en minutes : "..timeofday['SunriseInMinutes'],debugging);


if (tonumber(timeInMinutes) < timeofday['SunriseInMinutes'] + delai_apres_leve_soleil or tonumber(timeInMinutes) > timeofday['SunsetInMinutes'] + delai_apres_couche_soleil) then --Pendant la nuit
    if otherdevices_svalues[lum] ~= nil then
        voir_les_logs("--- --- Luminosité salon : ".. otherdevices_svalues[lum] .." lux --- ---",debugging) 
    end    
    if tonumber(otherdevices_svalues[lum]) >  tonumber(seuil) then
        if otherdevices[lum_rdc_1]=='Off' then commandArray[lum_rdc_1]='On' end
        voir_les_logs("--- --- Luminosité salon au dessus du seuil: ".. otherdevices[lum_rdc_1] .." --- ---",debugging) 
    else
        if otherdevices[lum_rdc_1]=='On' then commandArray[lum_rdc_1]='Off' end
        voir_les_logs("--- --- Luminosité salon en dessous du seuil: ".. otherdevices[lum_rdc_1] .." --- ---",debugging)
    end
end    
voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)

return commandArray


