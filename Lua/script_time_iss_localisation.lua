--[[ 
script_time_iss_localisation.lua
Téléchargez JSON.lua : http://regex.info/blog/lua/json et placez le dans le répertoire de vos scripts LUA
  
auteur : papoo
version : 1.2
maj : 17/08/2016
date : 06/08/2016
principe : Récupérer via l'API http://api.open-notify.org/ les informations du prochain passage de la station ISS prés de chez vous
ainsi que le temps où elle reste visible.
La station ISS se déplace d'OUEST en EST et fait un tour complet de la terre en 90 mn. 
il est possible d'apercevoir l'ISS à l'oeil nu, la nuit par temps clair,
ses panneaux solaires d'une taille avoisinant celle d'un terrain de foot réfléchissant la lumière du soleil.
Le script récupère l'heure de levé et couché du soleil disponible dans dz et n'affiche que les passages de nuits avec la variable periode déclarée en "night"
Url Post : http://easydomoticz.com/forum/viewtopic.php?f=17&t=2310
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false  	-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local iss_device = 736  	-- renseigner l'id du device text prochain passage ISS associé si souhaité, sinon nil
local iss_visibility = 737  -- renseigner l'id du device text durée de visibilité ISS associé si souhaité, sinon nil
local latitude = "45.8" 	-- latitude du logement
local longitude = "1.3" 	-- longitude du logement
local altitude = "357"		-- altitude du logement
local periode = "night"		-- all : l'ensemble des passages même en journée, night : seulement les passages après le couché et avant le levé du soleil
--------------------------------------------
----------- Fin variables à éditer ---------
-------------------------------------------- 
local indexArray=0
local passage = nil
print('script_time_iss_localisation.lua')
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

function pairsByKeys (t, f)
  local a = {}
	for n in pairs(t) do table.insert(a, n) end
	  table.sort(a, f)
	  local i = 0      -- iterator variable
	  local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
  return iter
end

--------------------------------------------
-------------- Fin Fonctions ---------------
-------------------------------------------- 
commandArray = {}
now = os.date("*t")

if now.min % 15 == 0 then  -- execution toutes les 15 minutes
	if periode ~= tostring("night") then
	passage = "1"
	else
	passage = "8"
	end
	if latitude ~= nil and longitude ~= nil and altitude ~= nil then

			 json = (loadfile "/home/pi/domoticz/scripts/lua/JSON.lua")()  -- For Linux
		  -- json = (loadfile "D:\\Domoticz\\scripts\\lua\\json.lua")()  -- For Windows
		  -- json = (loadfile "/volume1/@appstore/domoticz/var/scripts/lua/JSON.lua")()  -- For Synology

		local config=assert(io.popen('curl --connect-timeout 10 "http://api.open-notify.org/iss-pass.json?lat='.. latitude ..'&lon='.. longitude ..'&alt='.. altitude ..'&n='.. passage ..'"'))
		local location = config:read('*all')
		local jsonLocation = json:decode(location)
		config:close()

				local iss_Presence = nil
				local iss_duration = nil
	
		
		if jsonLocation ~= nil then 
			   for i, resultat in pairs(jsonLocation.response) do
				iss_Presence=resultat.risetime
				iss_duration = resultat.duration
				local iss_time = os.date("%H:%M", iss_Presence)
				local iss_day = os.date("%d/%m/%Y", iss_Presence)
				iss_TimeInMinutes = (tonumber(os.date("%H", iss_Presence)) * 60) + tonumber(os.date("%M", iss_Presence)) -- conversion timestamp en minutes
				voir_les_logs("Timestamp Prochain passage ISS = ".. iss_Presence  .."; le ".. iss_day ..", Visibilite ISS = ".. iss_duration .."s",debugging)
			if periode ~= tostring("night") then
					voir_les_logs("Prochain passage ISS en minutes = ".. iss_TimeInMinutes,debugging)
					voir_les_logs("Visibilite ISS = ".. iss_duration .."s",debugging)					
						if iss_device ~= nil then
							commandArray[indexArray] = {['UpdateDevice'] = iss_device ..'|0|'.. tostring(iss_time)}
							indexArray=indexArray+1
						end		
						if iss_visibility ~= nil then
							commandArray[indexArray] = {['UpdateDevice'] = iss_visibility ..'|0|'.. tostring(iss_duration ..' secondes')}
							indexArray=indexArray+1
						end			
			else				
					if  iss_TimeInMinutes > timeofday['SunsetInMinutes']  or (iss_TimeInMinutes < timeofday['SunriseInMinutes'] and  iss_TimeInMinutes < timeofday['SunsetInMinutes'] )then  -- ISS non visible la journée, test si heure de passage aprés le coucher et avant le levé du soleil

					voir_les_logs("heure leve du soleil en minutes = ".. timeofday['SunriseInMinutes'],debugging)					
					voir_les_logs("Prochain passage ISS en minutes = ".. iss_TimeInMinutes,debugging)
					voir_les_logs("heure couche du soleil en minutes = ".. timeofday['SunsetInMinutes'],debugging)
					voir_les_logs("Prochain passage ISS = ".. iss_time,debugging)
					voir_les_logs("Visibilite ISS = ".. iss_duration .."s",debugging)					
						if iss_device ~= nil then
							commandArray[indexArray] = {['UpdateDevice'] = iss_device ..'|0|'.. tostring(iss_time) ..' le '..tostring(iss_day)}
							indexArray=indexArray+1
						end		
						if iss_visibility ~= nil then
							commandArray[indexArray] = {['UpdateDevice'] = iss_visibility ..'|0|'.. tostring(iss_duration ..' secondes')}
							indexArray=indexArray+1
						end	
					break 	
					else
					voir_les_logs("le prochain passage ISS = ".. iss_TimeInMinutes ..", sunrise (leve) : "..timeofday['SunriseInMinutes']..", sunset (couche) : "..timeofday['SunsetInMinutes'],debugging)
					end	
				end
			end
				
		else
					voir_les_logs("erreur lors de la recuperation des donnees de l'API",debugging)		
		end	
	else
					voir_les_logs("Il manque la latitude, la longitude ou l'altitude de votre lieu de residence",debugging)
	end
end


return commandArray
