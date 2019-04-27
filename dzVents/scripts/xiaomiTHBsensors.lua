--[[
xiaomiTHBsensors.lua
author/auteur = papoo
update/mise à jour = 26/04/2019
création = 22/04/2019
https://pon.fr/dzvents-gestion-des-sondes-xiaomi-thb-avec-le-plugin-domoticz-deconz
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/xiaomiTHBsensors.lua
https://easydomoticz.com/forum/viewtopic.php?f=15&t=7593&p=69089#p69089
--]]


local scriptName = 'xiaomiTHBsensors'
local scriptVersion = '1.0'

return {
    active = true,
    logging = {
                    -- level    =   domoticz.LOG_DEBUG, -- Uncomment to override the dzVents global logging setting
                    -- level    =   domoticz.LOG_INFO,  -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
        marker = scriptName..' '..scriptVersion
    },
    on = {
    devices = {'$Température*'}
    },

    execute = function(domoticz,sensor)
        local function logWrite(str,level)             -- Support function for shorthand debug log statements
            domoticz.log(tostring(str),level or domoticz.LOG_DEBUG)
        end
        local function levelForecast(pressure)
            pressure = tonumber(pressure)
            logWrite(tostring(type(pressure)), domoticz.LOG_DEBUG)
            if type(pressure) ~= "number" then
                return domoticz.BARO_NOINFO
            elseif pressure < 1000 then 
                return domoticz.BARO_RAIN
            elseif pressure < 1020 then 
                return domoticz.BARO_CLOUDY
            elseif pressure < 1030 then 
                return domoticz.BARO_PARTLYCLOUDY
            else  
                return domoticz.BARO_SUNNY
            end

        end
        local function UpdateSensor(sensor)
            TemperatureSensor = sensor.name
            sensor = string.gsub (sensor.name, "$Température ", "")
            HumiditySensor = tostring("$Humidité "..sensor)
            BarometreSensor = tostring("$Baromètre "..sensor)
            if domoticz.devices(HumiditySensor).humidity and domoticz.devices(HumiditySensor).humidity ~= nil then
                h = domoticz.devices(HumiditySensor).humidity
                hs = domoticz.devices(HumiditySensor).humidityStatusValue
                logWrite(tostring(h), domoticz.LOG_DEBUG)
                logWrite(tostring(hs), domoticz.LOG_DEBUG)
            end
            t = domoticz.utils.round(domoticz.devices(TemperatureSensor).temperature,1)
            logWrite(tostring(t), domoticz.LOG_DEBUG)
            if domoticz.devices(BarometreSensor).barometer and domoticz.devices(BarometreSensor).barometer ~= nil then
                p = tonumber(domoticz.devices(BarometreSensor).barometer)
                fcst = domoticz.devices(BarometreSensor).forecastString
                logWrite(tostring(p), domoticz.LOG_DEBUG)
                logWrite(tostring(fcst), domoticz.LOG_DEBUG)

            end
            if h ~= nil and p ~= nil and domoticz.devices(sensor) then
                domoticz.devices(sensor).updateTempHumBaro(t, h, hs, p, levelForecast(p))
            end
        end

        UpdateSensor(sensor)

    end
}
