--[[ alertePollens.lua for [ domoticzVents >= 2.4 ]

author/auteur = papoo
update/mise à jour = 29/04/2019
creation = 03/04/2019
https://pon.fr/dzvents-alerte-pollens
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/alertePollens.lua
https://easydomoticz.com/forum/viewtopic.php?f=17&t=8392
--]]
--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------
local departement = "87"
        local alerte_url  = 'https://www.pollens.fr/risks/thea/counties/'  -- url
local alert_device = nil --'Pollens' -- nom ou idx du device alerte, nil si inutilisé

local risques = { -- Commentez (en ajoutant -- devant) ou décommentez (en enlevant -- devant) les risques que vous souhaitez surveiller.
                    -- "Tilleul",
                    -- "Ambroisies",
                    -- "Olivier",
                    -- "Plantain",
                    "Noisetier",
                    -- "Aulne",
                    -- "Armoise",
                    -- "Châtaignier",
                    -- "Urticacées",
                    -- "Oseille",
                    "Graminées",
                    -- "Chêne",
                    -- "Platane",
                    "Bouleau",
                    -- "Charme",
                    -- "Peuplier",
                    -- "Frêne",
                    -- "Saule",
                    -- "Cyprès",
                    }
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local scriptName        = 'Alerte Pollens'
local scriptVersion     = '1.1'


return {
    active = true,
    on      =   {   timer           =   { 'every 6 hours' },
                    httpResponses   =   { "Pollens_Trigger" }    -- Trigger the handle Json part
    },

    logging =   {
                 level    =   domoticz.LOG_DEBUG,                                           -- Seulement un niveau peut être actif; commenter les autres
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

            local niveau1, niveau2, niveau3, niveau4, niveau5, text = '', '', '', '', '', ''

            local riskLevel = rt.riskLevel
            logWrite('alerte de niveau '..riskLevel)
            
            for k, risque in pairs(risques) do
                for k, pollens in pairs(rt.risks) do
                    if pollens.pollenName == risque and pollens.level == 5 then niveau5 = niveau5.. " ".. pollens.pollenName.."," end
                    if pollens.pollenName == risque and pollens.level == 4 then niveau4 = niveau4.. " ".. pollens.pollenName.."," end
                    if pollens.pollenName == risque and pollens.level == 3 then niveau3 = niveau3.. " ".. pollens.pollenName.."," end
                    if pollens.pollenName == risque and pollens.level == 2 then niveau2 = niveau2.. " ".. pollens.pollenName.."," end
                    if pollens.pollenName == risque and pollens.level == 1 then niveau1 = niveau1.. " ".. pollens.pollenName.."," end
                end
            end

            if     niveau5 ~= '' then text, riskLevel = niveau5, 4
            elseif niveau4 ~= '' then text, riskLevel = niveau4, 3
            elseif niveau3 ~= '' then text, riskLevel = niveau3, 2
            elseif niveau2 ~= '' or niveau1 ~= '' then text, riskLevel = niveau2..niveau1, 1
            --elseif niveau2 ~= '' then text, riskLevel = niveau2, 1
            --elseif niveau1 ~= '' then text, riskLevel = niveau1, 1
            else                      text, riskLevel = "Aucune Alerte", 0
            end

            text = string.gsub (text, ",$", "")
            logWrite(text)

            if alert_device ~= nil then
                domoticz.devices(alert_device).updateAlertSensor(riskLevel, text)
            end
            logWrite("Alerte de niveau  "..riskLevel.." pour les pollens de : "..text, domoticz.LOG_INFO)
            
        end
    end
}
