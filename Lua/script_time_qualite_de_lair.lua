--[[
name : script_time_qualite_air.lua
auteur : papoo
date de création : 06/05/2017
Date de mise à jour : 08/05/2017
Principe : Ce script a pour but d'interroger l'API du site http://http://aqicn.org pour récupérer les informations de pollutions
Cette API utilise une clé gratuite, Il faut donc s'incrire sur http://aqicn.org/data-platform/token/  pour avoir accès à cette clé de 40 caractères
Enregistrez cette clé dans une variable utilisateur et renseignez sont nom dans token_aqicn
URL post : http://easydomoticz.com/forum/viewtopic.php?f=17&t=4044 http://pon.fr/qualite-de-lair-dans-le-monde/
Les données des polluants sont au format de l'indice de qualité de l'air commun européen (AQI) http://www.airqualitynow.eu/about_indices_definition.php
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local nom_script = "Qualité de l\'air"
local version = "1.00"
local debugging = false  			-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local dz_air_quality = nil			-- renseigner l'idx du device Qualité de l'air associé si souhaité, sinon nil (custom, nom de l'axe : AQI)
local dz_indice_alert = nil			-- renseigner l'idx du device alert pollution associé si souhaité, sinon nil (dummy - alert)
local dz_poll_dominant = nil			-- renseigner l'idx du device polluant dominant associé si souhaité, sinon nil (type text)
local dz_co = nil						-- renseigner l'idx du device monoxide de carbonne associé si souhaité, sinon nil (custom, nom de l'axe : AQI)
local dz_no2 = nil					-- renseigner l'idx du device dioxyde d'azote associé si souhaité, sinon nil (custom, nom de l'axe : AQI)
local dz_o3 = nil						-- renseigner l'idx du device Ozone associé si souhaité, sinon nil (custom, nom de l'axe : AQI)
local dz_p = nil						-- renseigner l'idx du device pression atmosphérique  associé si souhaité, sinon nil (barometre)
local dz_pm10 = nil					-- renseigner l'idx du device taux de particules associé si souhaité, sinon nil (custom, nom de l'axe : AQI)
local dz_pm25 = nil					-- renseigner l'idx du device taux de particules associé si souhaité, sinon nil (custom, nom de l'axe : AQI)
local send_notification = nil 		-- 0: aucune notification, 1: toutes, 2: (50 > Pollution <=100), 3: (100 > Pollution <=150), 4: (150 > Pollution <=200), 5: (Pollution > 200)
local token_aqicn = "api_aqicn" 	-- renseigner l'idx de la variable contenant le token aqicn de 40 caractères préalablement créé (variable de type chaine)
--[[ si vous souhaitez une localisation via votre adresse ip laissez les variables ville, latitude, et longitude à nil
	 si vous souhaitez une autre localisation utilisez la variable ville
	 si votre ville comporte plusieurs stations et que vous souhaitez récuperer les informations de la station la plus proche,
	 renseigner vos latitude longitude en laissant ville à nil
]]--
local ville = nil					-- renseigner le nom de la ville dont vous souhaitez remonter les informations de pollution ex : "limoges", nil si vous souhaitez utiliser Latitude et longitude (plus precis)
local latitude = nil 			-- renseigner la latitude du lieu dont vous souhaitez remonter les informations de pollution ex : "45.84"
local longitude = nil		 	-- renseigner la longitude du lieu dont vous souhaitez remonter les informations de pollution ex : "1.26"

--------------------------------------------
----------- Fin variables à éditer ---------
-------------------------------------------- 
local geo =""
if ville == nil and (latitude == nil or longitude == nil) then geo = 'here' elseif ville ~= nil then geo = ville else geo = 'geo:'.. latitude ..';'.. longitude end
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
json = (loadfile "/home/pi/domoticz/scripts/lua/JSON.lua")()  -- For Linux
-- json = (loadfile "D:\\domoticz\\scripts\\lua\\json.lua")()  -- For Windows
function voir_les_logs (s, debugging) -- nécessite la variable local debugging
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
time = os.date("*t")
if ((time.min-1) % 5) == 0 then -- toutes les 5 minutes en commençant par xx:01
	local API_key = uservariables[token_aqicn] 
	local config=assert(io.popen('/usr/bin/curl -m8 "https://api.waqi.info/feed/'.. geo ..'/?token='.. API_key ..'"'))

	voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
	 local blocjson = config:read('*all')
	 config:close()
	--print (blocjson)

	local jsonValeur = json:decode(blocjson)

	for valeur,i in pairs(jsonValeur.data.iaqi) do
		-- Mise à jour du devise co si il existe et si une valeur est disponible
		if valeur == 'co' then voir_les_logs("--- --- --- co : "..jsonValeur.data.iaqi.co.v .." --- --- --- ",debugging)  
				if dz_co ~= nil then commandArray[#commandArray+1] = {['UpdateDevice'] = dz_co ..'|0|'.. tostring(jsonValeur.data.iaqi.co.v)} end
		end
		-- Mise à jour du devise no2 si il existe et si une valeur est disponible
		if valeur == 'no2' then voir_les_logs("--- --- --- no2 : "..jsonValeur.data.iaqi.no2.v .." --- --- --- ",debugging)
				if dz_no2 ~= nil then commandArray[#commandArray+1] = {['UpdateDevice'] = dz_no2 ..'|0|'.. tostring(jsonValeur.data.iaqi.no2.v)} end
		end
		 -- Mise à jour du devise o3 si il existe et si une valeur est disponible
		if valeur == 'o3' then voir_les_logs("--- --- --- o3 : "..jsonValeur.data.iaqi.o3.v .." --- --- --- ",debugging)
				if dz_o3 ~= nil then commandArray[#commandArray+1] = {['UpdateDevice'] = dz_o3 ..'|0|'.. tostring(jsonValeur.data.iaqi.o3.v)} end
		end
		-- Mise à jour du devise p si il existe et si une valeur est disponible
		if valeur == 'p' then voir_les_logs("--- --- --- pression : "..jsonValeur.data.iaqi.p.v .." --- --- --- ",debugging)  
				if dz_p ~= nil then commandArray[#commandArray+1] = {['UpdateDevice'] = dz_p ..'|0|'.. tostring(jsonValeur.data.iaqi.p.v)} end
		end	
		-- Mise à jour du devise pm10 si il existe et si une valeur est disponible
		if valeur == 'pm10' then voir_les_logs("--- --- --- pm10 : "..jsonValeur.data.iaqi.pm10.v .." --- --- --- ",debugging) 
				 if dz_pm10 ~= nil then commandArray[#commandArray+1] = {['UpdateDevice'] = dz_pm10 ..'|0|'.. tostring(jsonValeur.data.iaqi.pm10.v)} end
		end	
		-- Mise à jour du devise pm25 si il existe et si une valeur est disponible
		if valeur == 'pm25' then voir_les_logs("--- --- --- pm25 : "..jsonValeur.data.iaqi.pm25.v .." --- --- --- ",debugging)  
				if dz_pm25 ~= nil then commandArray[#commandArray+1] = {['UpdateDevice'] = dz_pm25 ..'|0|'.. tostring(jsonValeur.data.iaqi.pm25.v)} end
		end

	end
		-- Mise à jour du devise aqi si il existe
		voir_les_logs("--- --- --- Qualite de l\'air : "..jsonValeur.data.aqi .." --- --- --- ",debugging)
		if dz_air_quality ~= nil then commandArray[#commandArray+1] = {['UpdateDevice'] = dz_air_quality..'|0|'.. tostring(jsonValeur.data.aqi)} end
		-- Mise à jour du devise poll_dominante si il existe
		voir_les_logs("--- --- --- polluant dominant : "..jsonValeur.data.dominentpol .." --- --- --- ",debugging)  
		if dz_poll_dominant ~= nil then commandArray[#commandArray+1] = {['UpdateDevice'] = dz_poll_dominant..'|0|'.. tostring(jsonValeur.data.dominentpol)}end

		local aqi = jsonValeur.data.aqi
		--Mise à jour du devise aqi si il existe	
		if dz_indice_alert ~= nil then	
			if tonumber(aqi) <= 50   then -- niveau 2
				commandArray[#commandArray+1] = {['UpdateDevice'] = dz_indice_alert..'|1|Pas de Pollution'}
				if send_notification > 0 and send_notification < 2 then
				commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte Pollution#Pas de Pollution!'}
				end
				voir_les_logs("--- --- --- Pas de pollution --- --- ---",debugging)

			elseif tonumber(aqi) <= 100   then -- niveau 3
				commandArray[#commandArray+1] = {['UpdateDevice'] = dz_indice_alert..'|2|Polution Faible'}
				if send_notification > 0 and send_notification < 3 then
				commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte Pollution#Pollution Faible!'}
				end
				voir_les_logs("--- --- --- Pollution Faible --- --- ---",debugging)   

			elseif tonumber(aqi) <= 150   then -- niveau 4
				commandArray[#commandArray+1] = {['UpdateDevice'] = dz_indice_alert..'|3|Pollution Forte'}
				if send_notification > 0 and send_notification < 4 then
				commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte Pollution#Pollution Forte!'}
				end
				voir_les_logs("--- --- --- Pollution Forte --- --- ---",debugging)      

			elseif tonumber(aqi) > 150  then -- niveau 5
				commandArray[#commandArray+1] = {['UpdateDevice'] = dz_indice_alert..'|4|Pollution tres forte'}
				if send_notification > 0 and send_notification < 5 then
				commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte Pollution#Pollution tres forte!'}
				end
				voir_les_logs("--- --- --- Pollution très forte --- --- ---",debugging)
			else
				voir_les_logs("niveau non defini")
			end
		end	
	if debugging == true then --affichage des informations disponibles en mod debugging
	aqi = jsonValeur.data.aqi
	url = jsonValeur.data.attributions[1].url
	name = jsonValeur.data.attributions[1].name
	lat_long = jsonValeur.data.city.geo[1]..":"..jsonValeur.data.city.geo[2]
	dominentpol = jsonValeur.data.dominentpol
	city_name = jsonValeur.data.city.name
	city_url = jsonValeur.data.city.url
	s = jsonValeur.data.time.s
	tz = jsonValeur.data.time.tz
	v = jsonValeur.data.time.v
	h = jsonValeur.data.iaqi.h.v 
	t = jsonValeur.data.iaqi.t.v 
	voir_les_logs("--- --- --- aqi : ".. aqi .." --- --- ---",debugging)
	voir_les_logs("--- --- --- url : "..url .." --- --- ---",debugging)
	voir_les_logs("--- --- --- name : ".. name .." --- --- ---",debugging)
	voir_les_logs("--- --- --- coordonnees gps : ".. lat_long .." --- --- ---",debugging)
	voir_les_logs("--- --- --- city_name : ".. city_name .." --- --- ---",debugging)
	voir_les_logs("--- --- --- city_url : ".. city_url .." --- --- ---",debugging)
	voir_les_logs("--- --- --- dominentpol : ".. dominentpol .." --- --- ---",debugging)
	voir_les_logs("--- --- --- date et heure :".. s .." --- --- ---",debugging)
	voir_les_logs("--- --- --- time zone :".. tz .." --- --- ---",debugging)
	voir_les_logs("--- --- --- timestamp :".. v .." --- --- ---",debugging)
	voir_les_logs("--- --- --- hygrometrie : ".. h .." --- --- --- ",debugging)
	voir_les_logs("--- --- --- température :".. t .." --- --- --- ",debugging)
	end 
	voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
	 
	  
end --if time

return commandArray
