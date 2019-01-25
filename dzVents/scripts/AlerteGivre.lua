--[[   
~/home/pi/domoticz/scripts/dzVents/scripts/AlerteGivre.lua
auteur : papoo
MAJ : 25/01/2019
création : 06/05/2016
Principe :
Calculer via les informations température et hygrométrie d'une sonde extérieure
 le point de rosée, le point de givre et l'humidité absolue
pour générer une alerte givre cohérente.
http://pon.fr/script-calcul-et-alerte-givre/
http://easydomoticz.com/forum/viewtopic.php?f=21&t=1085&start=10#p17545
]]--

--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------
local device_temp_ext       = 'Temperature exterieure' 	-- nom (entre ' ') ou idx  de la sonde de température/humidité extérieure
local device_dew_point      = 'Point de rosée'			-- nom (entre ' ') ou idx de l'éventuel dummy température point de rosée si vous souhaitez le suivre sinon nil
local device_freeze_point   = 'Point de givrage'	    -- nom (entre ' ') ou idx du dummy température point de givre si vous souhaitez le suivre sinon nil
local device_hum_abs        = 'Humidité absolue'        -- nom (entre ' ') ou idx de l'éventuel dummy humidité absolue si vous souhaitez le suivre sinon nil
local device_freeze_alert   = 'Risque de givre'			-- nom (entre ' ') ou idx du dummy alert point de givre
local thresholdHumidity     = 2.8                         -- seuil humidité absolue en dessous duquel il est peu probable qu'il givre
            local SubSystem =  {
                                 -- table with one or more notification systems. 
                                 -- uncomment the notification systems that you want to be used
                                 -- Can be one or more of
                                 
                                 -- domoticz.NSS_GOOGLE_CLOUD_MESSAGING, 
                                 -- domoticz.NSS_PUSHOVER,               
                                 -- domoticz.NSS_HTTP, 
                                 -- domoticz.NSS_KODI, 
                                 -- domoticz.NSS_LOGITECH_MEDIASERVER, 
                                 -- domoticz.NSS_NMA,
                                 -- domoticz.NSS_PROWL, 
                                 -- domoticz.NSS_PUSHALOT, 
                                  --domoticz.NSS_PUSHBULLET, 
                                 -- domoticz.NSS_PUSHOVER, 
                                 -- domoticz.NSS_PUSHSAFER,
                                  domoticz.NSS_TELEGRAM,
                                }
local subject               = "/!\\ Attention /!\\"           -- sujet des notifications  
--injection dans influxDB
local influxdbUrl           = 'http://diskstation2'
local influxdbPort          = '8086'
local BDD                   = 'domoticz'
typeDonnee                  = 'Humidity'
--injection dans influxDB
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------

local scriptName = 'Alerte Givre'
local scriptVersion = '2.1'
--local fetchIntervalMins = 1 --  intervalle de mise à jour.
local message = '.'


return {
    active =  true,  -- false, -- 
    on = { 
        timer   = { 'at 07:15' },
        --timer = {'every '..tostring(fetchIntervalMins)..' minutes',},
        devices = { device_temp_ext } 	-- nom de la sonde de température/humidité extérieure'
        },
    
    logging =   {   -- level    =   domoticz.LOG_DEBUG,
                    -- level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others    
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,

                    marker = scriptName..' v'..scriptVersion },    

    execute = function(domoticz, item)
    
    -- domoticz.log("année "..domoticz.time.year, domoticz.LOG_DEBUG)
    -- domoticz.log("mois "..domoticz.time.month, domoticz.LOG_DEBUG)
    -- domoticz.log("jour "..domoticz.time.day, domoticz.LOG_DEBUG)
    -- domoticz.log("heures "..domoticz.time.hour, domoticz.LOG_DEBUG)
    -- domoticz.log("minutes "..domoticz.time.minutes, domoticz.LOG_DEBUG)    
    -- domoticz.log("secondes "..domoticz.time.seconds, domoticz.LOG_DEBUG)     
    --domoticz.log(domoticz.devices('Humidité absolue').dump(), domoticz.LOG_DEBUG)

--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 

function freezing_point(dp, t) 
	if not dp or not t or dp > t then
        return nil, " La température du point de rosée est supérieure à la température. Puisque la température du point de rosée ne peut être supérieure à la température de l'air , l\'humidité relative a été fixée à nil."
    end
    T = t + 273.15
    Td = dp + 273.15
    return domoticz.utils.round((Td + (2671.02 /((2954.61/T) + 2.193665 * math.log(T) - 13.3448))-T)-273.15, 2)
end

function hum_abs(t,hr)
    -- https://carnotcycle.wordpress.com/2012/08/04/how-to-convert-relative-humidity-to-absolute-humidity/
    -- Formule pour calculer l'humidité absolue
    -- Dans la formule ci-dessous, la température (T) est exprimée en degrés Celsius, l'humidité relative (hr) est exprimée en%, et e est la base des logarithmes naturels 2.71828 [élevée à la puissance du contenu des crochets]:
    -- Humidité absolue (grammes / m3 ) =  (6,122 * e^[(17,67 * T) / (T + 243,5)] * rh * 2,1674))/(273,15 + T)
    -- Cette formule est précise à 0,1% près, dans la gamme de température de -30 ° C à + 35 ° C
    ha = domoticz.utils.round((6.112 * math.exp((17.67 * t)/(t+243.5)) * hr * 2.1674)/ (273.15 + t),1)
    return ha
end
--------------------------------------------
-------------- Fin Fonctions ---------------
-------------------------------------------- 

--temperature, Humidity = otherdevices_svalues[device_temp_ext]:match("([^;]+);([^;]+)")	
temperature = domoticz.devices(device_temp_ext).temperature
humidity = domoticz.devices(device_temp_ext).humidity
dewPoint = domoticz.utils.round(domoticz.devices(device_temp_ext).dewPoint, 2)
freezingPoint = freezing_point(dewPoint, temperature)
absHumidity = hum_abs(temperature,humidity)
domoticz.log("--- --- --- Température Ext :     ".. domoticz.utils.round(temperature, 2) .." °C", domoticz.LOG_DEBUG)
domoticz.log("--- --- --- Humidité :            ".. humidity .." %", domoticz.LOG_DEBUG)
domoticz.log("--- --- --- point de rosée :      ".. dewPoint .." °C", domoticz.LOG_DEBUG)
domoticz.log("--- --- --- point de givre :      ".. freezingPoint .." °C", domoticz.LOG_DEBUG)
domoticz.log("--- --- --- Humidité Absolue :    ".. absHumidity .." g/m³", domoticz.LOG_DEBUG)
    --if (item.device == device_temp_ext) then
        
        if device_dew_point    ~= nil  then domoticz.devices(device_dew_point).updateTemperature(dewPoint) end -- Mise à jour point de rosée
        if device_freeze_point ~= nil  then domoticz.devices(device_freeze_point).updateTemperature(freezingPoint) end -- Mise à jour point de givrage
        if device_hum_abs      ~= nil  then 
            domoticz.devices(device_hum_abs).updateCustomSensor(absHumidity)    
            --injection dans influxDB
            local nom = string.gsub(domoticz.devices(device_hum_abs).name, ' ', '-') 
            os.execute("curl -i -XPOST '"..influxdbUrl..":"..influxdbPort.."/write?db="..BDD.."' --data-binary '"..typeDonnee..",idx="..domoticz.devices(device_hum_abs).idx..",name='"..nom.."' value="..absHumidity.."'")
            --injection dans influxDB   
        end -- Mise à jour humidité absolue
            -- updateAlertSensor(level, text): Function. Level can be domoticz.ALERTLEVEL_GREY, ALERTLEVEL_GREEN, ALERTLEVEL_YELLOW, ALERTLEVEL_ORANGE, ALERTLEVEL_RED   

        if(tonumber(temperature) <= 1 and tonumber(freezingPoint) <= 0) and absHumidity > thresholdHumidity then
            domoticz.log("--- --- --- Givre --- --- ---", domoticz.LOG_DEBUG)
            message = "Présence de givre"
            if tonumber(domoticz.devices(device_freeze_alert).color) ~= 4 then domoticz.devices(device_freeze_alert).updateAlertSensor(domoticz.ALERTLEVEL_RED, freezingPoint.."°C") end

        elseif(tonumber(temperature) <= 1 and tonumber(freezingPoint) <= 0) and absHumidity < thresholdHumidity then
            domoticz.log("--- --- --- Givre peu probable --- --- ---", domoticz.LOG_DEBUG)
            message = "Givre peu probable malgré la température"
            if tonumber(domoticz.devices(device_freeze_alert).color) ~= 3 then domoticz.devices(device_freeze_alert).updateAlertSensor(domoticz.ALERTLEVEL_YELLOW, freezingPoint.."°C") end        
            
        elseif(tonumber(temperature) <= 3 and tonumber(freezingPoint) <= 0 )then
            domoticz.log("--- --- --- Risque de Givre --- --- ---", domoticz.LOG_DEBUG)
            message = "Risque de givre"
            if tonumber(domoticz.devices(device_freeze_alert).color) ~= 2 then domoticz.devices(device_freeze_alert).updateAlertSensor(domoticz.ALERTLEVEL_ORANGE, freezingPoint.."°C") end
        else
            domoticz.log("--- --- --- Aucun risque de Givre --- --- ---", domoticz.LOG_DEBUG)
            message = nil
            if tonumber(domoticz.devices(device_freeze_alert).color) ~= 1 then domoticz.devices(device_freeze_alert).updateAlertSensor(domoticz.ALERTLEVEL_GREEN, 'Pas de givre') end
        --end
        end
    if (item.trigger == 'at 07:15') and message ~= nil then
        domoticz.log("--- --- --- notification alerte Givre --- --- ---", domoticz.LOG_DEBUG)
        if SubSystem == nil then 
            domoticz.notify(subject, message)
        else
        domoticz.notify(subject, message, domoticz.PRIORITY_NORMAL, domoticz.SOUND_INTERMISSION,"",  SubSystem)
        end 
    end

end   
}
