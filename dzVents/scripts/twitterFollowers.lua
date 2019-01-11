--[[ twitterFollowers.lua for [ domoticzVents >= 2.4 ]
    
author/auteur = papoo
update/mise à jour = 10/01/2019
creation = 10/01/2019
https://pon.fr/dzvents-suivre-le-nombre-dabonnes-dun-compte-twitter
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/twitterFollowers.lua
https://easydomoticz.com/forum/viewtopic.php?f=17&t=7809
--]]
--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------
local twitterName = 'pap_oo'
local deviceTwitter = '@pap_oo'         -- nom (entre ' ') ou idx du custom device twitter, nil si non utilisé
local intervalleMiseAJourEnMinutes = 30   -- intervalle de mise à jour du script.
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nomScript = 'nombre de Followers sur twitter'
local versionScript = '1.0'

return {
    active = true,
    on      =     
                {   timer           =   { 'every '..tostring(intervalleMiseAJourEnMinutes)..' minutes',},
                    httpResponses   =   { nomScript }    -- Trigger the handle Json part
                },

  logging =   { level    =   domoticz.LOG_INFO,
                marker = nomScript..' '..versionScript
               },

    
    execute = function(domoticz, reponse)

        local twitter_API_url  = 'https://cdn.syndication.twimg.com/widgets/followbutton/info.json?screen_names='..twitterName  -- url


        if (reponse.isTimer) then
            domoticz.openURL({
                url = twitter_API_url,
                callback = nomScript
            })

        end
        if (reponse.isHTTPResponse and reponse.ok) then
            if (reponse.data) then
               reponse.data = string.gsub (reponse.data, '%[', "")
               reponse.data = string.gsub (reponse.data, '%]', "")
               json = domoticz.utils.fromJSON(reponse.data)
               domoticz.log(tostring(json.name)..' à '..tostring(json.followers_count)..' followers sur twitter sous le pseudo de '..tostring(json.screen_name),domoticz.LOG_INFO)
               if json.followers_count and deviceTwitter then
                    domoticz.devices(deviceTwitter).updateCustomSensor(tonumber(json.followers_count))
               end
            end
   
        end
    end   
}
