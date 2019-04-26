--[[ alertePollens.lua for [ domoticzVents >= 2.4 ]

author/auteur = papoo
update/mise à jour = 26/04/2019
creation = 03/04/2019
https://pon.fr/dzvents-alerte-pollens
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/alertePollens.lua
https://easydomoticz.com/forum/viewtopic.php
--]]
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local departement = 87
        local alerte_url  = 'https://www.pollens.fr/risks/thea/counties/'  -- url
local alert_device = 'Pollens' -- nom ou idx du device alerte, nil si inutilisé
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local scriptName        = 'Alerte Pollens'
local scriptVersion     = '1.0'
local text = ''

return {
    active = true,
    on      =   {   timer           =   { 'every 6 hours' },  -- remember only 1000 requests by day, 30mn = 48 requests
                    httpResponses   =   { "Pollens_Trigger" }    -- Trigger the handle Json part
    },

    logging =   {  
                -- level    =   domoticz.LOG_DEBUG,                                             -- Seulement un niveau peut être actif; commenter les autres
                -- level    =   domoticz.LOG_INFO,                                            -- Only one level can be active; comment others
                -- level    =   domoticz.LOG_ERROR,
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker = scriptName..' v'..scriptVersion }, 

                data    =   {   alertePollens     = {initial = {} },             -- Keep a copy of last json just in case
    },
    execute = function(domoticz, item)

        local function logWrite(str,level)             -- Support function for shorthand debug log statements
            domoticz.log(tostring(str),level or domoticz.LOG_DEBUG)
        end

        if (item.isTimer) then
            domoticz.openURL({
                url = alerte_url..departement,
                callback = 'Pollens_Trigger'
            })
        end

        if (item.isHTTPResponse and item.ok) then
            -- we know it is json but dzVents cannot detect this
            -- convert to Lua
            local json = domoticz.utils.fromJSON(item.data)
            -- json is now a Lua table
            if #item.data > 0 then
                domoticz.data.alertePollens    = domoticz.utils.fromJSON(item.data)
                rt = domoticz.utils.fromJSON(item.data)
            else
                domoticz.log("Problem with response from Pollens (no data) using data from earlier run",domoticz.LOG_ERROR)
                rt  = domoticz.data.alertePollens                        -- json empty. Get last valid from domoticz.data
                if #rt < 1 then                                         -- No valid data in domoticz.data either
                    domoticz.log("No previous data. are Pollens url ok?",domoticz.LOG_ERROR)
                    return false
                end
            end

            logWrite("niveau de risque : "..rt.riskLevel)
            local riskLevel = rt.riskLevel
            --local riskLevel = 2
            for k, pollens in pairs(rt.risks) do
                if pollens.level == riskLevel then
                    logWrite('alerte de niveau '..pollens.level..' pour le pollen '..pollens.pollenName)
                    text = " "..pollens.pollenName..","..text
                elseif pollens.level == (riskLevel-1) then
                    logWrite('alerte de niveau '..pollens.level..' pour le pollen '..pollens.pollenName)
                    text = " "..pollens.pollenName..","..text
                end

            end
            text = string.gsub (text, ",$", "")
            logWrite(text)
            if riskLevel == nil then
                riskLevel = 0
                text = "Aucune donnée"
            end
            if alert_device ~= nil then
                domoticz.devices(alert_device).updateAlertSensor(riskLevel, text)
                
            end
            


        end
    end
}
