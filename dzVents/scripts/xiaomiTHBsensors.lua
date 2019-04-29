--[[
xiaomiTHBsensors.lua
author/auteur = papoo
update/mise à jour = 29/04/2019
création = 22/04/2019
https://pon.fr/dzvents-gestion-des-sondes-xiaomi-thb-avec-le-plugin-domoticz-deconz
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/xiaomiTHBsensors.lua
https://easydomoticz.com/forum/viewtopic.php?f=15&t=7593&p=69089#p69089
--]]


local scriptName = 'xiaomiTHBsensors'
local scriptVersion = '1.1'

return {
    active = true,
    logging = {
                     level    =   domoticz.LOG_DEBUG, -- Uncomment to override the dzVents global logging setting
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
            logWrite(type(pressure))
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
            if domoticz.devices("$Humidité "..sensor) then HumiditySensor = tostring("$Humidité "..sensor) end
            if domoticz.devices("$Baromètre "..sensor) then BarometreSensor = tostring("$Baromètre "..sensor) end
            if domoticz.devices(HumiditySensor).humidity ~= nil and domoticz.devices(HumiditySensor).humidity then
                h = domoticz.devices(HumiditySensor).humidity
                hs = domoticz.devices(HumiditySensor).humidityStatusValue
                logWrite(h)
                logWrite(hs)
            end
            t = domoticz.utils.round(domoticz.devices(TemperatureSensor).temperature,1)
            logWrite(t)
            if  domoticz.devices(BarometreSensor).barometer ~= nil and domoticz.devices(BarometreSensor).barometer then
                p = tonumber(domoticz.devices(BarometreSensor).barometer)
                fcst = domoticz.devices(BarometreSensor).forecastString
                logWrite(p)
                logWrite(fcst)

            end
            if h ~= nil and p ~= nil and domoticz.devices(sensor) then
                domoticz.devices(sensor).updateTempHumBaro(t, h, hs, p, levelForecast(p))
                logWrite("mise à jour du device "..domoticz.devices(sensor).name)
           elseif h ~= nil and p == nil and domoticz.devices(sensor) then
                domoticz.devices(sensor).updateTempHum(t, h, hs)
                logWrite("mise à jour du device "..domoticz.devices(sensor).name)
           end
        end

        UpdateSensor(sensor)

    end
}
