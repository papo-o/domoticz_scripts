--[[   
~/domoticz/scripts/lua/script_device_givre.lua
auteur : papoo
MAJ : 27/02/2018
création : 06/05/2016
Principe :
Calculer via les informations température et hygrometrie d'une sonde exterieure
 le point de rosée ainsi que le point de givre
puis en comparant ensuite le point de givre et l'a température extérieure, création d'une alerte givre.
http://pon.fr/script-calcul-et-alerte-givre/
http://easydomoticz.com/forum/viewtopic.php?f=21&t=1085&start=10#p17545
--]]

--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = true  					-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local temp_ext  = 'Temperature exterieure' 	-- nom de la sonde de température/humidité extérieure
local dev_dew_point = 'Point de rosée'  	-- nom de l'éventuel dummy température point de rosée si vous souhaitez le suivre sinon nil
local dev_freeze_point = 'Point de givrage'	-- nom de l'éventuel dummy température point de givre si vous souhaitez le suivre sinon nil
local freeze_alert_idx = 'Risque de givre'	-- nom de l'éventuel dummy alert point de givre si vous souhaitez le suivre sinon nil
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = 'Point de rosée et point de givrage'
local version = 1.12						-- version du script

commandArray = {}

time=os.date("*t")
--if time.min % 2 == 0 then  -- si script_time
if devicechanged[temp_ext] then  -- si script_device
--print("script_device_givre.lua")
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
function voir_les_logs (s, debugging)
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>");
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>");
		end
    end
end	
function round(value, digits)
	if not value or not digits then
		return nil
	end
		local precision = 10^digits
		return (value >= 0) and
		  (math.floor(value * precision + 0.5) / precision) or
		  (math.ceil(value * precision - 0.5) / precision)
end
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
--------------------------------------------
-------------- Fin Fonctions ---------------
-------------------------------------------- 
voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
Temp, Humidity = otherdevices_svalues[temp_ext]:match("([^;]+);([^;]+)")		
voir_les_logs("--- --- --- Température Ext : ".. Temp,debugging)
voir_les_logs("--- --- --- Humidité : ".. Humidity,debugging)


	if dev_dew_point ~= nil then
		DewPoint = round(dewPoint(Temp,Humidity),2)
		voir_les_logs("--- --- --- Point de Rosée : ".. DewPoint,debugging)
		commandArray[1] = {['UpdateDevice'] = otherdevices_idx[dev_dew_point] .. "|0|" .. DewPoint} -- Mise à jour point de rosée
    end    
    if  dev_freeze_point ~= nil then   
		FreezingPoint = round(freezing_point(DewPoint, tonumber(Temp)),2)
		voir_les_logs("--- --- --- Point de Givrage : ".. FreezingPoint,debugging)
		commandArray[2] = {['UpdateDevice'] = otherdevices_idx[dev_freeze_point] .. "|0|" .. FreezingPoint} -- Mise à jour point de givrage
	end

    if dev_freeze_alert ~= nil then
        if(tonumber(Temp)<=1 and tonumber(FreezingPoint)<=0)  then
            voir_les_logs("--- --- --- Givre --- --- ---",debugging)
            commandArray[3]={['UpdateDevice'] = otherdevices_idx[dev_freeze_alert]..'|4|'..FreezingPoint}
            if (time.min == 50 and time.hour == 6) then
            commandArray['SendNotification'] = 'Alert#Présence de givre!'
            end
        elseif(tonumber(Temp)<=3 and tonumber(FreezingPoint)<=0)then
            voir_les_logs("--- --- --- Risque de Givre --- --- ---",debugging)
            commandArray[3]={['UpdateDevice'] = otherdevices_idx[dev_freeze_alert]..'|2|'..FreezingPoint}
            if (time.min == 50 and time.hour == 6) then
            commandArray['SendNotification'] = 'Alert#Risque de givre!'
            end
        else
            voir_les_logs("--- --- --- Aucun risque de Givre --- --- ---",debugging)
            commandArray[3]={['UpdateDevice'] = otherdevices_idx[dev_freeze_alert]..'|1|'..'Pas de givre'}
        end
    end
voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end	

return commandArray


