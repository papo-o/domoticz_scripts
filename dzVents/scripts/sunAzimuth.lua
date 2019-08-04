--[[ sunAzimuth.lua for [ dzVents >= 2.4.14 (domoticz >= V4.10444)]

author/auteur = papoo
update/mise à jour = 04/08/2019
creation = 04/08/2019

place this DZvents script in /domoticz/scripts/dzVents/scripts/ directory
script dzvents à placer dans le répertoire /domoticz/scripts/dzVents/scripts/
https://pon.fr/dzvents-altitude-et-azimut-du-soleil-sans-api/
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/sunAzimuth.lua
--]]


local scriptName        = 'sun azimuth'
local scriptVersion     = '1.0'

local solarAltitude     = 'Altitude du soleil' -- name or idx without '' of the sun altitude device, nil if not used
local solarAzimuth       = 'Azimut du soleil' -- name or idx without '' of the sun azimuth device, nil if not used

return {
    active = true,
    on = { timer =   {'every minute'}},
    logging =   {    level    =   domoticz.LOG_DEBUG,
                    -- level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others    
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker = scriptName..' v'..scriptVersion }, 

    execute = function(domoticz)

        local function logWrite(str,level)             -- Support function for shorthand debug log statements
            domoticz.log(tostring(str),level or domoticz.LOG_DEBUG)
        end

        local latitude  = domoticz.settings.location.latitude
        --local latitude  = '45.83'
        logWrite('latitude : '..latitude)
        local longitude = domoticz.settings.location.longitude
        --local longitude = '1.26'
        logWrite('longitude : '..longitude)
        
        local function sunposition(latitude, longitude, time)-- solar altitude, azimuth (degrees)
        --source https://stackoverflow.com/questions/35467309/position-of-the-sun-azimuth-in-lua
            time = time or os.time()
            if type(time) == 'table' then time = os.time(time) end

            local date = os.date('*t', time)
            local timezone = (os.time(date) - os.time(os.date('!*t', time))) / 3600
            if date.isdst then timezone = timezone + 1 end

            local utcdate = os.date('*t', time - timezone * 3600)
            local latrad = math.rad(latitude)
            local fd = (utcdate.hour + utcdate.min / 60 + utcdate.sec / 3600) / 24
            local g = (2 * math.pi / 365.25) * (utcdate.yday + fd)
            local d = math.rad(0.396372 - 22.91327 * math.cos(g) + 4.02543 * math.sin(g) - 0.387205 * math.cos(2 * g)
              + 0.051967 * math.sin(2 * g) - 0.154527 * math.cos(3 * g) + 0.084798 * math.sin(3 * g))
            local t = math.rad(0.004297 + 0.107029 * math.cos(g) - 1.837877 * math.sin(g)
              - 0.837378 * math.cos(2 * g) - 2.340475 * math.sin(2 * g))
            local sha = 2 * math.pi * (fd - 0.5) + t + math.rad(longitude)

            local sza = math.acos(math.sin(latrad) * math.sin(d) + math.cos(latrad) * math.cos(d) * math.cos(sha))
            local saa = math.acos((math.sin(d) - math.sin(latrad) * math.cos(sza)) / (math.cos(latrad) * math.sin(sza)))

            return 90 - math.deg(sza), math.deg(saa)
        end

        local function getSunPos(lat, long, time)
            findTime = {}
            findTime.hour, findTime.min = time.hour, time.min
            fixedAzimuthLast, fixedAzimuth = 0, 0
            for i=0,23 do
                for j=0,59 do
                    time.hour, time.min = i, j
                    local altitude, azimuth = sunposition(lat, long, time)
                    -- fix azimuth
                    if fixedAzimuthLast < azimuth then 
                        fixedAzimuthLast = azimuth
                        fixedAzimuth = fixedAzimuthLast
                    else
                        fixedAzimuth = fixedAzimuthLast + (180 - azimuth)
                    end
                    -- find azimuth at target time
                    if findTime.hour == i and findTime.min == j then
                        -- final result
                        return altitude, fixedAzimuth
                    end
                end
            end
        end

        altitude, azimuth = getSunPos(latitude, longitude, os.date('*t', os.time()))
        logWrite('solar altitude : '..domoticz.utils.round(altitude),2)
        logWrite('solar azimut : '..domoticz.utils.round(azimuth),2)
        if (solarAltitude) and (altitude) then domoticz.devices(solarAltitude).updateCustomSensor(altitude) end
        if (solarAzimuth) and (azimuth) then domoticz.devices(solarAzimuth).updateCustomSensor(azimuth) end

    end -- execute function
}
