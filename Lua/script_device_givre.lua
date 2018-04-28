--[[   
~/domoticz/scripts/lua/script_device_givre.lua
auteur : papoo
MAJ : 28/02/2018
création : 06/05/2016
Principe :
Calculer via les informations température et hygrométrie d'une sonde extérieure
 le point de rosée ainsi que le point de givre
puis en comparant ensuite le point de givre et l'a température extérieure, création d'une alerte givre.
http://pon.fr/script-calcul-et-alerte-givre/
http://easydomoticz.com/forum/viewtopic.php?f=21&t=1085&start=10#p17545
https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_device_givre.lua
--]]

--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false  					-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local temp_ext  = 'Temperature exterieure' 	-- nom de la sonde de température/humidité extérieure
local dev_dew_point = 'Point de rosée'  	-- nom de l'éventuel dummy température point de rosée si vous souhaitez le suivre sinon nil
local dev_freeze_point = 'Point de givrage'	-- nom de l'éventuel dummy température point de givre si vous souhaitez le suivre sinon nil
local dev_hum_abs_point = 'Humidité absolue'-- nom de l'éventuel dummy humidité absolue si vous souhaitez le suivre sinon nil
local dev_freeze_alert = 'Risque de givre'	-- nom de l'éventuel dummy alert point de givre si vous souhaitez le suivre sinon nil

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = 'Point de rosée et point de givrage'
local version = 1.2						-- version du script

commandArray = {}

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
function dewPoint (T, RH)
	local b,c = 17.67, 243.5
	RH = math.max (RH or 0, 1e-3)
	local gamma = math.log (RH/100) + b * T / (c + T) 
	return c * gamma / (b - gamma)
end
function freezing_point(dp, t) 
	if not dp or not t or dp > t then
    return nil, " La température du point de rosée est supérieure à la température. Puisque la température du point de rosée ne peut être supérieure à la température de l'air , l\'humidité relative a été fixée à nil."
end

T = t + 273.15
Td = dp + 273.15
return (Td + (2671.02 /((2954.61/T) + 2.193665 * math.log(T) - 13.3448))-T)-273.15
  
end

function hum_abs(t,hr)
-- https://carnotcycle.wordpress.com/2012/08/04/how-to-convert-relative-humidity-to-absolute-humidity/
-- Formule pour calculer l'humidité absolue
-- Dans la formule ci-dessous, la température (T) est exprimée en degrés Celsius, l'humidité relative (hr) est exprimée en%, et e est la base des logarithmes naturels 2.71828 [élevée à la puissance du contenu des crochets]:
-- Humidité absolue (grammes / m3 ) =  (6,122 * e^[(17,67 * T) / (T + 243,5)] * rh * 2,1674))/(273,15 + T)
-- Cette formule est précise à 0,1% près, dans la gamme de température de -30 ° C à + 35 ° C
ha = round((6.112 * math.exp((17.67 * t)/(t+243.5)) * hr * 2.1674)/ (273.15 + t),1)
return ha
end

--------------------------------------------
-------------- Fin Fonctions ---------------
-------------------------------------------- 

time=os.date("*t")
--if time.min % 2 == 0 then  -- si script_time
if devicechanged[temp_ext] then  -- si script_device
--print("script_device_givre.lua")

    voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
    Temp, Humidity = otherdevices_svalues[temp_ext]:match("([^;]+);([^;]+)")		
    voir_les_logs("--- --- --- Température Ext : ".. Temp,debugging)
    voir_les_logs("--- --- --- Humidité : ".. Humidity,debugging)

	if dev_dew_point ~= nil then
		DewPoint = round(dewPoint(Temp,Humidity),2)
		voir_les_logs("--- --- --- Point de Rosée : ".. DewPoint,debugging)
		commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[dev_dew_point] .. "|0|" .. DewPoint} -- Mise à jour point de rosée
    end    
    if  dev_freeze_point ~= nil then   
		FreezingPoint = round(freezing_point(DewPoint, tonumber(Temp)),2)
		voir_les_logs("--- --- --- Point de Givrage : ".. FreezingPoint,debugging)
		commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[dev_freeze_point] .. "|0|" .. FreezingPoint} -- Mise à jour point de givrage
	end

    if  dev_hum_abs_point ~= nil then   
        hum_abs_point = hum_abs(Temp, Humidity)
		voir_les_logs("--- --- --- Humidité absolue : ".. hum_abs_point,debugging)
		commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[dev_hum_abs_point] .. "|0|" .. hum_abs_point} -- Mise à jour humidité absolue
	end    
    
    
    if dev_freeze_alert ~= nil then
        if(tonumber(Temp)<=1 and tonumber(FreezingPoint)<=0)  then
            voir_les_logs("--- --- --- Givre --- --- ---",debugging)
            commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[dev_freeze_alert]..'|4|'..FreezingPoint}
            if (time.min == 50 and time.hour == 6) then
            commandArray['SendNotification'] = 'Alert#Présence de givre!'
            end
        elseif(tonumber(Temp)<=3 and tonumber(FreezingPoint)<=0)then
            voir_les_logs("--- --- --- Risque de Givre --- --- ---",debugging)
            commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[dev_freeze_alert]..'|2|'..FreezingPoint}
            if (time.min == 50 and time.hour == 6) then
            commandArray['SendNotification'] = 'Alert#Risque de givre!'
            end
        else
            voir_les_logs("--- --- --- Aucun risque de Givre --- --- ---",debugging)
            commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[dev_freeze_alert]..'|1|'..'Pas de givre'}
        end
    end
voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end	

return commandArray


