--[[
vigilanceMeteoFrance.lua
author/auteur = papoo
update/mise à jour = 13/06/2020
création = 28/04/2018
Principe : Ce script a pour but de remonter les informations de vigilance de météoFrance
Les informations disponibles sont :
- couleur vigilance météo (Rouge, Orange, Jaune, Vert)
- risque associé : vent violent, pluie-inondation, orages, inondations, neige-verglas, canicule, grand-froid, avalanche, vagues-submersion
Une vigilance peut ne pas être associée à  un risque. dans ce cas, affichage de la mention "vigilance météo".

URL forum : http://easydomoticz.com/forum/viewtopic.php?f=17&t=5492
URL blog : http://pon.fr/vigilance-meteofrance-v2/
URL github : https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_vigilance_meteofrance_v2.lua


--]]
--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------
local departement              = 87                   -- renseigner votre numéro de département sur 2 chiffres exemples : 01 ou 07 ou 87 
local alert_device             = 'Vigilance Météo'    -- renseigner le nom de l'éventuel device alert vigilance météo associé (dummy - alert)

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local scriptName        = 'Vigilance météo France'
local scriptVersion     = '2.0'
local response = "vigilance_meteoFrance"
return {
    active = true,
    on =        {       timer           =   { "every minute"},
                        httpResponses   =   {  response } },

    logging =   {   -- level    =   domoticz.LOG_DEBUG,
                       level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                    marker  =   scriptName..' v'..scriptVersion },

    execute = function(dz, item)

        local devAlert, _ , round = dz.devices(alert_device), dz.utils._, dz.utils.round

        local function logWrite(str,level)
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end

        local function seuilAlerte(level)
            if level == 0 or level == nil then return dz.ALERTLEVEL_GREY end
            if level == 1 then return dz.ALERTLEVEL_GREEN end
            if level == 2 then return dz.ALERTLEVEL_YELLOW end
            if level == 3 then return dz.ALERTLEVEL_ORANGE end
            if level == 4 then return dz.ALERTLEVEL_RED end
        end
        local function risqueTxt(nombre)
          if nombre == 1 then return "vent violent" 
          elseif nombre == 2 then return "pluie-inondation" 
          elseif nombre == 3 then return "orages" 
          elseif nombre == 4 then return "inondations" 
          elseif nombre == 5 then return "neige-verglas" 
          elseif nombre == 6 then return "canicule" 
          elseif nombre == 7 then return "grand-froid" 
          elseif nombre == 8 then return "avalanche"
          elseif nombre == 9 then return "vagues-submersion"
            else return "Vigilance Météo" end
        end
        local function EnumClear(Text)   -- replace the last character
            a=string.len(Text)
            b=string.sub(Text,a,a)
            if b=="," or b==" " then Text=string.sub(Text,1,a-1) end
            a=string.len(Text)
            b=string.sub(Text,a,a)
            if b=="," or b==" " then Text=string.sub(Text,1,a-1) end
            return Text
        end

        if (item.isHTTPResponse and item.trigger == response) then
            local abr = dz.utils.fromXML(item.data,"erreurXML") 
            local dv = abr.CV.DV
            local textAlert = ""
            local vigilanceColor

            for i, departements in ipairs(dv) do
                for _, result in pairs(departements) do
                    logWrite(result.dep)
                    logWrite(result.coul)
                    if tonumber(result.dep) == departement then 
                        logWrite("departement : "..result.dep)
                        logWrite("Couleur vigilance : "..result.coul)
                        vigilanceColor = tonumber(result.coul)
                        if dv[i].risque then 
                            risques = dv[i].risque
                            for _, risques in pairs(risques) do 
                                for _, risque in pairs(risques) do
                                    if risque.val then 
                                        logWrite(risqueTxt(tonumber(risque.val)))
                                        
                                        textAlert = textAlert .. risqueTxt(tonumber(risque.val)) .. ", "
                                    end
                                end
                            end
                        end
                    end
                end
            end
            text = EnumClear(textAlert)
            logWrite("vigilance ".. vigilanceColor .. text .. " pour le département " .. departement,dz.LOG_INFO)

            if alert_device ~= nil then
                if devAlert.color ~= vigilanceColor or devAlert.lastUpdate.minutesAgo > 1440 then
                    devAlert.updateAlertSensor(seuilAlerte(vigilanceColor), text)
                elseif devAlert.text ~= text then
                    devAlert.updateAlertSensor(seuilAlerte(vigilanceColor), text)
                end
            end

        else
            local url = "http://vigilance2019.meteofrance.com/data/NXFR33_LFPW_.xml"
            dz.openURL({
                  url = url,
                        method = "GET",
                        callback = response})
        end
    end
}
