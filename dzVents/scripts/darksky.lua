--[[ darksky.lua for [ dzVents >= 2.4.14 (domoticz >= V4.10444)]

author/auteur = papoo
update/mise à jour = 29/07/2019
creation = 15/09/2018
https://pon.fr/dzvents-darksky-et-probabilite-de-pluie/
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/darksky.lua
https://www.domoticz.com/forum/viewtopic.php?f=59&t=24928
https://easydomoticz.com/forum/viewtopic.php?f=17&t=7136&p=58822#p58822
This script requires prior registration to the DarkSky API
Ce script nécessite l'inscription préalable à l'API DarkSky
Enter the URL and request a free API key
Entrez l'URL et demandez une clé API gratuite
https://darksky.net/dev
place this DZvents script in /domoticz/scripts/dzVents/scripts/ directory
script dzvents à placer dans le répertoire /domoticz/scripts/dzVents/scripts/

    Add, modify or delete variables proba_pluie_h [] by changing the number (hour) between []
    the name "in quotation marks" or the idx without quotes (avoid accents) of the device of percentage of rain at [x] associated time, nil if not used
    This script can potentially retrieve the 48 available time forecasts. Create as many percent virtual sensors as you would expect from the hourly forecasts.
    for my part, I only get the forecasts at 1 hour, 2 hours, 4 hours, 6 hours, 12 hours and 24 hours.
    Only 48 possible forecasts
    Ajoutez, modifiez ou supprimez les variables proba_pluie_h[] en changeant le nombre (heure) entre []
    renseigner ensuite le nom "entre guillemets" ou l'idx sans guillemets (évitez les accents) du device pourcentage probabilité pluie à [x] heure associé, nil si non utilisé
    Ce script peut potentiellement récupérer les 48 prévisions horaires disponible. Créez autant de capteurs virtuels pourcentage correspondant aux prévisions horaires que vous souhaitez.
    pour ma part, je ne récupère que les prévisions à 1 heure, 2 heures, 4 heures, 6 heures, 12 heures et 24 heures.
    Seulement 48 prévisions possible
    My DarkSky secret key, the latitude and longitude of my home are contained in 3 user variables (type string)
    Ma clé secrète DarkSky, la latitude et la longitude de mon domicile sont contenus dans 3 variables utilisateurs (type chaine)

    local DarkSkyAPIkey = domoticz.variables('api_forecast_io').value

    If you want to enter this information directly into the script, comment the line above, uncomment the following line
    Si vous souhaitez inscrire ces informations dans le script, commentez la ligne ci-dessus, décommentez la ligne suivante

    --local DarkSkyAPIkey = "1a2bf34bf56c78901f2345f6d7890f12" --fake API number

    by personalizing it with your personal data
    finally, you can choose the level of logs, only one level can be active; comment on others in the section
    en la personnalisant avec vos données personnelles.
    enfin vous pouvez choisir le niveau de "verbiage" des logs, seulement un niveau peut être actif; commenter les autres dans la section logging
--]]
local scriptName        = 'Darksky forecast'
local scriptVersion     = ' 1.2'
local proba_pluie_h     = {}
local prev_wind_h       = {}
local MoonPhaseSelect   = {}

proba_pluie_h[1]        = 'Proba Pluie 1h'
proba_pluie_h[2]        = 'Proba Pluie 2h'
proba_pluie_h[3]        = nil
proba_pluie_h[4]        = 'Proba Pluie 4h'
proba_pluie_h[5]        = nil
proba_pluie_h[6]        = 'Proba Pluie 6h'
proba_pluie_h[12]       = 'Proba Pluie 12h'
proba_pluie_h[24]       = 508
proba_pluie_h[36]       = nil
proba_pluie_h[48]       = nil

prev_wind_h[1]          = 'Vent dans 1 heure'
prev_wind_h[2]          = nil
prev_wind_h[3]          = nil
prev_wind_h[4]          = nil
prev_wind_h[5]          = nil
prev_wind_h[6]          = nil
prev_wind_h[12]         = nil
prev_wind_h[24]         = nil
prev_wind_h[36]         = nil
prev_wind_h[48]         = nil

MoonPhaseSelect[1]      = 2479  --moonPhase day 1 selector switch
MoonPhaseSelect[2]      = nil   --moonPhase day 2 selector switch
MoonPhaseSelect[3]      = nil   --moonPhase day 3 selector switch
MoonPhaseSelect[4]      = nil   --moonPhase day 4 selector switch
MoonPhaseSelect[5]      = nil   --moonPhase day 5 selector switch
MoonPhaseSelect[6]      = nil   --moonPhase day 6 selector switch
MoonPhaseSelect[7]      = nil   --moonPhase day 7 selector switch
MoonPhaseSelect[8]      = nil   --moonPhase day 8 selector switch

return {
    active = true,
    on      =   {   timer           =   { 'every 30 minutes' },  -- remember only 1000 requests by day, 30mn = 48 requests
                    httpResponses   =   { 'DarkSky_Trigger' }    -- Trigger the handle Json part
                },

  logging =   {  level    =   domoticz.LOG_DEBUG,                                             -- Seulement un niveau peut être actif; commenter les autres
                -- level    =   domoticz.LOG_INFO,                                            -- Only one level can be active; comment others
                -- level    =   domoticz.LOG_ERROR,
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker = scriptName..' v'..scriptVersion
                },

   data    =   {   Forecast     = {initial = {} },             -- Keep a copy of last json just in case
       },
    execute = function(domoticz, item)

        local function logWrite(str,level)             -- Support function for shorthand debug log statements
            domoticz.log(tostring(str),level or domoticz.LOG_DEBUG)
        end

        local function quadrants(degrees)
            local quadrants = {"NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"}
            
                if degrees > 348.75 or degrees <= 11.25 then
                    return "N"
                else 
                    local index = tonumber(math.floor((degrees - 11.25) / 22.5)+1)
                    return quadrants[index]
                end
        end
        local function levelMoonhase(moonphase)
            local moonPhase = "Nouvelle lune"
            local level = 10 -- level correspondant à Nouvelle lune
            if(moonphase > 0.0 and moonphase < 0.13) then
                --moonPhase = "Premier croissant"
                level = 20 -- level correspondant à Premier croissant
            elseif(moonphase > 0.12 and moonphase < 0.25) then
                --moonPhase = "Premier quartier"
                level = 30 -- level correspondant à Premier quartier
            elseif(moonphase > 0.24 and moonphase < 0.5) then
                --moonPhase = "Gibbeuse croissante"
                level = 40  -- level correspondant à Gibbeuse croissante
            elseif(moonphase > 0.49 and moonphase < 0.63) then
                --moonPhase = "Pleine lune"
                level = 50 -- level correspondant à Pleine lune
            elseif(moonphase > 0.62 and moonphase < 0.75) then
                --moonPhase = "Gibbeuse décroissante"
                level = 60 -- level correspondant à Gibbeuse décroissante
            elseif(moonphase > 0.74 and moonphase < 0.88) then
                --moonPhase = "Dernier quartier"
                level = 70 -- level correspondant à Dernier quartier
            elseif(moonphase > 0.87 and moonphase < 1.00) then
                --moonPhase = "Dernier croissant"
                level = 80 -- level correspondant à Dernier croissant
            end
            --end
            return level--moonPhase, 
        end
        local DarkSkyAPIkey = domoticz.variables('api_forecast_io').value
        --local DarkSkyAPIkey = "1a2bf34bf56c78901f2345f6d7890f12" --fake API number
        local geolocalisation = domoticz.settings.location.latitude..','..domoticz.settings.location.longitude
        --local geolocalisation = "45.87,1.30" -- latitude,longitude
        logWrite('geolocalisation : '..geolocalisation,domoticz.LOG_INFO)


        local Forecast_url  = "https://api.darksky.net/forecast/"  -- url
        local extraData = "?units=si&exclude=flags"--currently,minutely,daily,alerts,

        if (item.isTimer) then
            domoticz.openURL({
                url = Forecast_url..DarkSkyAPIkey.."/"..geolocalisation..extraData,
                callback = 'DarkSky_Trigger'
            })

        end
        if (item.isHTTPResponse and item.ok) then
            -- we know it is json but dzVents cannot detect this
            -- convert to Lua
            local json = domoticz.utils.fromJSON(item.data)
            -- json is now a Lua table
            if #item.data > 0 then
                domoticz.data.Forecast    = domoticz.utils.fromJSON(item.data)
                rt = domoticz.utils.fromJSON(item.data)
            else
                domoticz.log("Problem with response from DarkSky (no data) using data from earlier run",domoticz.LOG_ERROR)
                rt  = domoticz.data.Forecast                        -- json empty. Get last valid from domoticz.data
                if #rt < 1 then                                         -- No valid data in domoticz.data either
                    domoticz.log("No previous data. are DarkSkyAPIkey and geolocalisation ok?",domoticz.LOG_ERROR)
                    return false
                end
            end
            logWrite('heure systeme')
            local now = domoticz.time.dDate
            logWrite('now : '..now)
            j = 1
            for i = 1,48 do
                logWrite('j : '..j)
                if now > tonumber(json.hourly.data[j].time) then -- si maintenant est supérieur au timestamp lu
                    local h = domoticz.utils.round((now - tonumber(json.hourly.data[j].time)) / 3600,0)
                    logWrite("h : "..h)
                    j = j+h
                    logWrite("j : "..j)

                end
                logWrite('date :'.. os.date('%Y-%m-%d %H:%M:%S', json.hourly.data[j].time),domoticz.LOG_INFO)
                logWrite('precipProbability :' ..json.hourly.data[j].precipProbability,domoticz.LOG_INFO)
                if (proba_pluie_h[i]) then
                        domoticz.devices(proba_pluie_h[i]).updatePercentage(json.hourly.data[j].precipProbability*100)
                end

                local windSpeed         =   json.hourly.data[j].windSpeed
                local windGust          =   json.hourly.data[j].windGust
                local windBearing       =   json.hourly.data[j].windBearing
                local temperature       =   json.hourly.data[j].temperature
                local windChill         =   json.hourly.data[j].apparentTemperature
                local direction         =   quadrants(windBearing)
                logWrite('windSpeed : '..tostring(windSpeed)..' windGust : '..tostring(windGust)..' windBearing : '..tostring(windBearing)..' direction :'..tostring(direction)..' temperature : '..tostring(temperature)..' windChill : '..tostring(windChill),domoticz.LOG_INFO)

                if (prev_wind_h[i]) then
                    domoticz.devices(prev_wind_h[i]).updateWind(windBearing,tostring(direction),windSpeed,windGust,temperature,windChill)
                    logWrite('mise à jour du device '..prev_wind_h[i],domoticz.LOG_INFO)
                end
                
                if j == 48 then break end
                j = j +1
            end
            k = 1
            for k = 1,8 do
                local moonphase = json.daily.data[k].moonPhase
                logWrite('moonPhase day ' ..k..' : '..tostring(moonphase))
                logWrite(levelMoonhase(moonphase))

                if(MoonPhaseSelect[k]) then
                    domoticz.devices(MoonPhaseSelect[k]).switchSelector(levelMoonhase(moonphase))
                    logWrite("update selector device")
                end
                if j == 8 then break end
                j = j +1
            end
        end
    end
}
