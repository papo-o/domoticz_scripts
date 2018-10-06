--[[ darksky.lua for [ domoticzVents >= 2.4 ]
    
author/auteur = papoo
update/mise à jour = 06/10/2018
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
--]]               
local proba_pluie_h = {}
--[[
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
    local geolocalisation = domoticz.variables('Latitude').value..","..domoticz.variables('Longitude').value

    If you want to enter this information directly into the script, comment the two lines above, uncomment the following two lines
    Si vous souhaitez inscrire ces informations dans le script, commentez les deux lignes ci-dessus, décommentez les deux lignes suivantes
    
    --local DarkSkyAPIkey = "1a2bf34bf56c78901f2345f6d7890f12" --fake API number
    --local geolocalisation = "45.87,1.30" -- latitude,longitude 
    
    by personalizing them with your personal data
    finally, you can choose the level of logs, only one level can be active; comment on others in the section
    en les personnalisant avec vos données personnelles. 
    enfin vous pouvez choisir le niveau de "verbiage" des logs, seulement un niveau peut être actif; commenter les autres dans la section logging
--]]
proba_pluie_h[1]= "Proba Pluie 1h"     			
proba_pluie_h[2]= "Proba Pluie 2h"     			 
proba_pluie_h[3]= nil    			            
proba_pluie_h[4]= "Proba Pluie 4h"    			
proba_pluie_h[5]= nil    			            
proba_pluie_h[6]= "Proba Pluie 6h"   			
proba_pluie_h[12]= "Proba Pluie 12h"    		
proba_pluie_h[24]= 508   			
proba_pluie_h[36]= nil   			            
proba_pluie_h[48]= nil

return {
    active = true,
    on      =   {   timer           =   { 'every 30 minutes' },  -- remember only 1000 requests by day, 30mn = 48 requests
                    httpResponses   =   { "DarkSky_Trigger" }    -- Trigger the handle Json part
                },

  logging =   { -- level    =   domoticz.LOG_INFO,                                             -- Seulement un niveau peut être actif; commenter les autres
                -- level    =   domoticz.LOG_ERROR,                                            -- Only one level can be active; comment others
                level    =   domoticz.LOG_DEBUG,
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker    =   "Darksky Rain Probability v1.03 "      },

   data    =   {   rainForecast     = {initial = {} },             -- Keep a copy of last json just in case
   },
    execute = function(domoticz, item)
        local DarkSkyAPIkey = domoticz.variables('api_forecast_io').value
        local geolocalisation = domoticz.variables('Latitude').value..","..domoticz.variables('Longitude').value
        --local DarkSkyAPIkey = "1a2bf34bf56c78901f2345f6d7890f12" --fake API number
        --local geolocalisation = "45.87,1.30" -- latitude,longitude 
        

        local Forecast_url  = "https://api.darksky.net/forecast/"  -- url
        local extraData = "?units=ca&exclude=currently,minutely,daily,alerts,flags" 

        local function debugMessage(message)
            domoticz.log(message,domoticz.LOG_DEBUG)
        end
        
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
                domoticz.data.rainForecast    = domoticz.utils.fromJSON(item.data)
                rt = domoticz.utils.fromJSON(item.data)
            else
                domoticz.log("Problem with response from DarkSky (no data) using data from earlier run",domoticz.LOG_ERROR)
                rt  = domoticz.data.rainForecast                        -- json empty. Get last valid from domoticz.data
                if #rt < 1 then                                         -- No valid data in domoticz.data either
                    domoticz.log("No previous data. are DarkSkyAPIkey and geolocalisation ok?",domoticz.LOG_ERROR)
                    return false
                end
            end    
            debugMessage("heure systeme")
            debugMessage(os.date('%Y-%m-%d %H:%M:%S', time))
            
            local now = tonumber(os.time(os.date("*t")))
            j = 1
            for i = 1,48 do

                 if now > tonumber(json.hourly.data[j].time) then 
                    local h = domoticz.utils.round((now - tonumber(json.hourly.data[j].time)) / 3600,0)
                    j = j+h
                    debugMessage("j : "..j)
                     
                end 
                 
                    if proba_pluie_h[i] then  
                            debugMessage("heure "..i)
                            debugMessage(os.date('%Y-%m-%d %H:%M:%S', json.hourly.data[j].time))
                            debugMessage(json.hourly.data[j].time)
                            debugMessage(json.hourly.data[j].precipProbability)
                            domoticz.devices(proba_pluie_h[i]).updatePercentage(json.hourly.data[j].precipProbability*100)
                    end
                if j == 48 then break end    
                j = j +1
                
            end    
        end
    end   
}
