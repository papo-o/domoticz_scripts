--[[ ~/home/pi/domoticz/scripts/dzVents/scripts/airQuality.lua
Based on this script : http://www.domoticz.com/forum/viewtopic.php?f=59&t=22080&start=20#p216650
Minimal dzVents Version: 2.4.19
auteur : papoo
MAJ : 10/06/2019
création : 08/06/2019
Principe :
Ce script a pour but d'interroger l'API du site http://http://aqicn.org pour récupérer les informations de pollutions
Cette API utilise une clé gratuite, Il faut donc s'incrire sur http://aqicn.org/data-platform/token/  pour avoir accès à cette clé de 40 caractères
data from http://waqi.info/
An API key is required and can be aquired here ==> http://aqicn.org/data-platform/token/


https://pon.fr/dzvents-qualite-de-lair-et-donnees-meteorologiques
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/airQuality.lua
v1.x : https://pon.fr/qualite-de-lair-dans-le-monde/
]]--
local token_aqicn = 'api_aqicn'-- aqicn token chaine user variable name. if you don't want to use a user variable, change the value of the apiKey variable
local scriptName = 'airQuality'
local scriptVersion = '2.0'
return {
    active =  true, -- false,
    on =    {
                timer           = { "every 15 minutes" },
                httpResponses   = { "waqi*" }                            -- matches callback wildcard
            },

        data    =   {
                        safedMessage = { history = true, maxItems = 100 , maxHours = 168 }
                    },

        logging =   {   level   =   domoticz.LOG_DEBUG,
                        marker  =   scriptName..' v'..scriptVersion },

    execute = function(dz, triggerItem)

        local apiKey            = dz.variables(token_aqicn).value -- if you don't want to use a user variable, change this by your aqicn token like "123456789123456789" 
        --local defaultLocation   = "51.852062;4.507676"
        local defaultLocation   =  dz.settings.location.latitude ..";".. dz.settings.location.longitude  --using the location data declared in the parameters, utilisation des données de localisation déclarées dans les parametres
        local sensorType

        if dz.data.safedMessage.get(1) == nil then
            dz.data.safedMessage.add("Init")
        end

        local geo   = { nearby  = defaultLocation,        -- to get station closest to your home
                        so2     = "",--"51.867238;4.354981",   -- if value for this item cannot be obtained from "nearby"
                        co      = "",--"51.986119;4.934413",   -- else keep this as an empty string
                        pm25    = "",
                        pm10    = "45.873333332057;1.308",--dispo
                        o3      = "45.873333332057;1.308",--dispo
                        no2     = "",
                        aqi     = "",
                        w       = "",
                        wg      = "45.873333332057;1.308",
                        t       = "",
                        r       = "",
                        h       = "",
                        d       = "",
                        p       = "",
                      }

        local sensors = {    -- enter device index Numbers or 0 for sensor and alert "
                        so2     = { sensor = 0,  alert = 0},  -- Sulphur Dioxide
                        co      = { sensor = 0,  alert = 0},  -- Carbon Monoxyde
                        pm25    = { sensor = 0,  alert = 0},
                        pm10    = { sensor = 1140, alert = 1141},
                        o3      = { sensor = 0,  alert = 0},  -- Ozone
                        no2     = { sensor = 1143,  alert = 1142},-- Nitrogen Dioxide
                        aqi     = { sensor = 0,  alert = 0, aqiSensor = 0},      -- additional Air Quality sensor
                        w       = { sensor = 1144},-- wind
                        wg      = { sensor = 1146},-- wind gust
                        t       = { sensor = 0},-- Temperature
                        r       = { sensor = 0},-- rain (precipitation)
                        h       = { sensor = 0},-- Relative Humidity
                        d       = { sensor = 0},-- Dew
                        p       = { sensor = 0},-- Atmostpheric Pressure
                        }

        local sensorTypes = { alert = "Alert", aqi = "Air Quality", custom = "Custom Sensor",}

        local function responseType(str)   -- strip waqi_ from string
            return str:gsub("waqi_","")
        end

        local function errorMessage(message,notify)   -- Add entry to log and notify to all subsystems
            dz.log(message,dz.LOG_ERROR)
            if notify then
                dz.notify(message)
            end
        end

        local function callPollutionURL(location,callback,delay)
            local delay = delay or 1
            local url   = "http://api.waqi.info/feed/geo:".. location .. "/?token=" .. apiKey
            dz.openURL({    url         = url,
                            method      = "GET",
                            callback    = callback
                       }).afterSec(delay)
        end

        local function getAirQualityData()
            local delay = 1
            for callType, location in pairs(geo) do
                if location ~= "" then
                    callPollutionURL(location,"waqi_" .. callType,delay)
                    delay = delay + 30
                end
            end
        end

        local function alertLevelAQI(value)
            if value < 50 then return dz.ALERTLEVEL_GREEN,"Excellent" end
            if value < 100 then return dz.ALERTLEVEL_YELLOW,"Moyen" end
            if value < 150 then return dz.ALERTLEVEL_ORANGE,"Pollué" end
            return dz.ALERTLEVEL_RED,"Dangereux"
        end

        function deviceType(device)
            if device ~= nil then
                if dz.devices(device).deviceType:upper() == "GENERAL" then
                    return dz.devices(device).deviceSubType
                else
                    return dz.devices(device).deviceType
                end
            else
                return nil
            end
        end


        local function setSensor(sensor,value)
            if sensor ~= 0 and value ~= nil then

                if deviceType(sensor) == sensorTypes.custom then
                    dz.devices(sensor).updateCustomSensor(value)
                elseif deviceType(sensor) == sensorTypes.aqi then
                    dz.devices(sensor).updateAirQuality(value)
                else
                    local alertLevel, alertText = alertLevelAQI(value)
                    local alertString = alertText .. "(" .. tostring(value) .. ")"
                    if dz.devices(sensor).text ~= alertString then
                        dz.devices(sensor).updateAlertSensor(alertLevel, alertString)
                    end
                end
            end
        end

        local function handleResponse(type)
            local rt = triggerItem.json                        -- rt is just a reference to the data no actual copy is done
            dz.log("triggerItem.data : "..triggerItem.data,dz.LOG_DEBUG)
            if triggerItem.json ~= nil and rt.data ~= nil and tonumber(rt.data.aqi) then
                if type == "nearby" then
                    rt.data.iaqi["aqi"] = {}; rt.data.iaqi["aqi"].v = rt.data.aqi    -- handle exception in iaqi as aqi is stored elsewhere
                    for nearbyType, location in pairs(geo) do
                        if nearbyType ~= "nearby" and location == "" then               -- No other location for this type
                            handleResponse(nearbyType)
                        end
                    end
                else
                    for setDevice, idx in pairs(sensors[type]) do
                        if idx ~= 0 then
                            dz.log("setDevice " .. setDevice, dz.log_DEBUG)
                            dz.log("idx " .. idx, dz.log_DEBUG)
                            dz.log("sensors[type] " .. tostring(sensors[type]), dz.log_DEBUG)
                            dz.log("rt " .. tostring(rt), dz.log_DEBUG)
                            dz.log("rt.data " .. tostring(rt.data), dz.log_DEBUG)
                            dz.log("rt.data.iaqi " .. tostring(rt.data.iaqi), dz.log_DEBUG)
                            dz.log("rt.data.iaqi[type] " .. tostring(rt.data.iaqi[type]), dz.log_DEBUG)
                                if rt.data.iaqi[type] ~= nil then setSensor(idx,rt.data.iaqi[type:lower()].v) end
                        end
                    end
                end
            else
                errorMessage("This should not happen")   -- aqi should always be there and set
                if dz.data.safedMessage.get(1).time.secondsAgo > 30 then
                    errorMessage("I will call url again")   -- aqi should always be there and set
                    callPollutionURL(geo[responseType(triggerItem.trigger)],triggerItem.trigger,1)
                    dz.data.safedMessage.add("Extra call to openURL for " .. triggerItem.trigger)
                end
            end
        end

        if triggerItem.isHTTPResponse then
           if triggerItem.ok and triggerItem.isJSON then
               handleResponse(responseType(triggerItem.trigger))
           else
               errorMessage("Problem with response from waqi",true)
           end
        else
            getAirQualityData()
        end
    end
}
