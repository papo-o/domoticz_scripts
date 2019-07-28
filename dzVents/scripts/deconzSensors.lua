--[[
deconzSensors.lua
author/auteur = papoo
update/mise à jour = 27/07/2019
creation = 22/04/2019
https://pon.fr/dzvents-gestion-des-sondes-xiaomi-thb-avec-le-plugin-domoticz-deconz
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/xiaomiTHBsensors.lua
https://easydomoticz.com/forum/viewtopic.php?f=15&t=7593&p=69089#p69089

how does this script work :
DCONZ plugin generates 3 devices for each xiaomi aqara sensor which we will name for the example, shower
shower temperature
shower humidity
shower barometer

we rename them 
$temperature shower
$humidity shower
$barometer shower

Create a dummy Temp + Humidity + Baro device

it's automatically supported by this script and will be updated with the data of $shower temperature, $shower humidity, $shower barometer that no longer appear in the Domotic temperature and Weather tabs but are still active.

if you follow this naming rule every time you add a device, you do not need to touch the script, the new device will be directly supported

this script also supports temp + humidity sensor without barometer
--]]


local scriptName = 'deconzSensors'
local scriptVersion = '1.2e'

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
    devices = {'$temperature*'}
    },

    execute = function(domoticz,sensor)
    
        local function logWrite(str,level)             -- Support function for shorthand debug log statements
            domoticz.log(tostring(str),level or domoticz.LOG_DEBUG)
        end

        local function levelForecast(pressure)
            pressure = tonumber(pressure)

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

        function deviceType(device)
            if device ~= nil then
                if domoticz.devices(device).deviceType:upper() == "GENERAL" then
                    return domoticz.devices(device).deviceSubType
                else
                    return domoticz.devices(device).deviceType
                end
            else
                return nil
            end
        end

        local function UpdateSensor(sensor)
            TemperatureSensor = sensor.name
            sensor = string.gsub (sensor.name, "$temperature ", "")
            t = domoticz.utils.round(domoticz.devices(TemperatureSensor).temperature,1)
            logWrite(t)

            logWrite(deviceType(sensor))

            if domoticz.devices("$humidity "..sensor) ~= nil then 
                HumiditySensor = tostring("$humidity "..sensor) 
                if domoticz.devices(HumiditySensor).humidity ~= nil then
                    h = domoticz.devices(HumiditySensor).humidity
                    hs = domoticz.devices(HumiditySensor).humidityStatusValue
                    logWrite("humidity : "..h)
                    logWrite("humidity status : "..hs)
                end

            end
            if deviceType(sensor) == "Temp + Humidity + Baro" then
                if domoticz.devices("$barometer "..sensor) ~= nil then 
                    BarometreSensor = tostring("$barometer "..sensor) 
                    if domoticz.devices(BarometreSensor).barometer ~= nil then
                        p = tonumber(domoticz.devices(BarometreSensor).barometer)
                        logWrite("pressure : "..p)
                    end
                end
            end

            if h ~= nil and p ~= nil and domoticz.devices(sensor) then
                domoticz.devices(sensor).updateTempHumBaro(t, h, hs, p, levelForecast(p))
                logWrite("update device "..domoticz.devices(sensor).name)
           elseif h ~= nil and p == nil and domoticz.devices(sensor) then
                domoticz.devices(sensor).updateTempHum(t, h, hs)
                logWrite("update device "..domoticz.devices(sensor).name)
           end
        end

        UpdateSensor(sensor)

    end
}
