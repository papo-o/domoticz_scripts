 
--[[ ~/domoticz/scripts/lua/script_device_givre_auto.lua
 auteurs : papoo&deennoo
 MAJ : 28/04/2018
 création : 06/05/2016
 Principe : a une heure donnée, va chercher les prévisions de température pour dans 12h puis va calculer le point de givre
 en comparant ensuite le point de givre et la température reçue, création d'une alerte givre.
 /!\attention/!\
si vous souhaitez utiliser ce script dans l'éditeur interne, pour indiquer le chemin complet vers le fichier JSON.lua, il vous faudra changer la ligne 
json = assert(loadfile(luaDir..'JSON.lua'))()
par 
json = assert(loadfile('/le/chemin/vers/le/fichier/lua/JSON.lua'))()
exemple :
json = assert(loadfile('/home/pi/domoticz/scripts/lua/JSON.lua'))()
la reconnaissance automatique du chemin d'exécution de ce script ne fonctionnant pas dans l'éditeur interne
--]]
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false					    -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local dew_point_idx = nil				    -- idx de l'éventuel dummy température point de rosée si vous souhaitez le suivre
local freeze_point_idx = nil				    -- idx du dummy température point de givre
local freeze_alert_idx = nil				    -- idx du dummy alert point de givre
local heure = 19						    -- heure de déclenchement
local minute = 03						    -- minute de déclenchement
local Longitude = "Longitude"			    -- nom de la variable utilisateur contenant les données de longitude
local Latitude = "Latitude"				    -- nom de la variable utilisateur contenant les données de latitude
local api_forecast_io = "api_forecast_io"	-- nom de la variable utilisateur contenant les données de l'API de forecast.io

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = "prévision et alerte givre"
local version = "1.24"
local api = ""
local long = ""
local lat = ""
curl = '/usr/bin/curl -m 5 '		 	-- ne pas oublier l'espace à la fin

-- chemin vers le dossier lua
	if (package.config:sub(1,1) == '/') then
		 luaDir = debug.getinfo(1).source:match("@?(.*/)")
	else
		 luaDir = string.gsub(debug.getinfo(1).source:match("@?(.*\\)"),'\\','\\\\')
	end
	json = assert(loadfile(luaDir..'JSON.lua'))()						-- chargement du fichier JSON.lua

commandArray = {}
time=os.date("*t")
if (time.min == minute and time.hour == heure) then
--if ((time.min-1) % 2) == 0 then  -- export des données toutes les 2 minutes    
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
------------------------------------------ 
function round(value, digits)
	if not value or not digits  then
		return nil
	end
  local precision = 10^digits
  return (value >= 0) and
      (math.floor(value * precision + 0.5) / precision) or
      (math.ceil(value * precision - 0.5) / precision)
end
--]]
------------------------------------------ 
function freezing_point(d, t) 
 if not d or not t or (d > t  and t > 0) then
    return nil, " La temperature du point de rosee est superieure à la temperature. Puisque la temperature du point de rosee ne peut être superieure à la temperature de l'air , l\'humidite relative a ete fixee à nil."
	end

T = t + 273.15
Td = d + 273.15
return (Td + (2671.02 /((2954.61/T) + 2.193665 * math.log(T) - 13.3448))-T)-273.15
  
end

--------------------------------------------
-------------- Fin Fonctions ---------------
-------------------------------------------- 
voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
api = uservariables[api_forecast_io]
if api ~= nil then voir_les_logs("--- --- --- api : ".. api,debugging) end    
	long = uservariables[Longitude]
if long ~= nil then voir_les_logs("--- --- --- Longitude : ".. long,debugging) end    
	lat = uservariables[Latitude]
if lat ~= nil then voir_les_logs("--- --- --- Latitude : ".. lat,debugging) end    
	config=assert(io.popen(curl ..'"https://api.forecast.io/forecast/'.. api ..'/'.. lat ..','.. long ..'?units=ca&exclude=currently,minutely,daily,alerts,flags"'))
    voir_les_logs('curl -m5 "https://api.forecast.io/forecast/'.. api ..'/'.. lat ..','.. long ..'?units=ca&exclude=currently,minutely,daily,alerts,flags"',debugging)
	blocjson = config:read('*all')
	config:close()
	jsonValeur = json:decode(blocjson)
	temp  = jsonValeur.hourly.data[12].apparentTemperature
	dew   = jsonValeur.hourly.data[12].dewPoint

    if temp ~= nil then voir_les_logs("--- --- --- Temperature Ext : ".. temp,debugging) end
    if dew ~= nil then voir_les_logs("--- --- --- Point de Rosee : ".. dew,debugging) end 
    
    if dew ~= nil and temp ~= nil then
        if dew_point_idx ~= nil then
            commandArray[1] = {['UpdateDevice'] = dew_point_idx .. "|0|" .. dew} -- Mise à jour point de rosee
        end   
   
        FreezingPoint = freezing_point(dew, tonumber(temp))

		if FreezingPoint ~= nil then
				FreezingPoint = round(tonumber(FreezingPoint),2)
                voir_les_logs("--- --- --- Point de Givrage : ".. FreezingPoint,debugging)
            if freeze_point_idx ~= nil then
				commandArray[2] = {['UpdateDevice'] = freeze_point_idx .. "|0|" .. FreezingPoint} -- Mise à jour point de givrage
			end

           if(tonumber(temp)<=1 and tonumber(FreezingPoint)<=0)then
                voir_les_logs("--- Givre Demain Matin ---",debugging)
                if freeze_alert_idx ~= nil then commandArray[3]={['UpdateDevice'] = freeze_alert_idx..'|4|'..FreezingPoint} end
                commandArray['SendNotification'] = 'Alert#Presence de givre demain matin!'
           elseif(tonumber(temp)<=3 and tonumber(FreezingPoint)<=0)then
                voir_les_logs("--- Risque de Givre Demain Matin ---",debugging)
                if freeze_alert_idx ~= nil then commandArray[3]={['UpdateDevice'] = freeze_alert_idx..'|2|'..FreezingPoint} end
                commandArray['SendNotification'] = 'Alert#Risque de givre demain matin!'
            elseif(tonumber(temp)<=0 and tonumber(FreezingPoint)>tonumber(-2)) then
                voir_les_logs("--- Givre Demain Matin ---",debugging)
                if freeze_alert_idx ~= nil then commandArray[3]={['UpdateDevice'] = freeze_alert_idx..'|4|'..FreezingPoint} end
                commandArray['SendNotification'] = 'Alert#Presence de givre demain matin!'  
           else
                voir_les_logs("--- --- --- Aucun risque de Givre --- --- ---",debugging)
                if freeze_alert_idx ~= nil then commandArray[3]={['UpdateDevice'] = freeze_alert_idx..'|1|'..'Pas de givre'} end
            end 
        else
            voir_les_logs("=========== La temperature du point de rosee est superieure a la temperature. Puisque la temperature du point de rosee ne peut etre superieure a la temperature de l'air , l\'humidite relative a ete fixee à nil ===========",debugging)
            if tonumber(dew)<= -4 then
                voir_les_logs("--- Risque de Givre Demain Matin ---",debugging)
                if freeze_alert_idx ~= nil then commandArray[3]={['UpdateDevice'] = freeze_alert_idx..'|2|'..FreezingPoint} end
                commandArray['SendNotification'] = 'Alert#Risque de givre demain matin!'
            end
        end
	else
        voir_les_logs("=========== Calcul du Point de rosee et du point de givrage impossible aucune donnee a traiter ===========",debugging)
	end	
        voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end

return commandArray




