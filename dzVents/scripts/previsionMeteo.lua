--[[
previsionMeteo.lua
author/auteur = papoo
update/mise à jour = 04/10/2019
création = 18/08/2019
https://pon.fr/dzvents-mise-en-cache-des-donnees-de-lapi-prevision_meteo-ch
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/previsionMeteo.lua
https://easydomoticz.com/forum/viewtopic.php?f=17&t=8865

Principe : Le site prevision-meteo.ch subit de nombreux ralentissements, rendant aléatoire l'affichage des prévisions météo sur monitor
https://pon.fr/prevision-meteo-a-3-jours/
Ce script permet la récupération des données via l'API, la modification du chemin d'accès aux icones afin de les stocker en local.
Si les données sont inaccessibles lors de l'appel de l'API, les données précédentes ne sont pas écrasées, permettant le fonctionnement continue de la page météo
Téléchargez les 36 icones météo dans le dossier dédié de monitor /home/pi/domoticz/www/monitor/icons/prevision-meteo/
https://www.prevision-meteo.ch/style/images/icon/ensoleille.png
https://www.prevision-meteo.ch/style/images/icon/nuit-claire.png
https://www.prevision-meteo.ch/style/images/icon/ciel-voile.png
https://www.prevision-meteo.ch/style/images/icon/nuit-legerement-voilee.png
https://www.prevision-meteo.ch/style/images/icon/faibles-passages-nuageux.png
https://www.prevision-meteo.ch/style/images/icon/nuit-bien-degagee.png
https://www.prevision-meteo.ch/style/images/icon/brouillard.png
https://www.prevision-meteo.ch/style/images/icon/stratus.png
https://www.prevision-meteo.ch/style/images/icon/stratus-se-dissipant.png
https://www.prevision-meteo.ch/style/images/icon/nuit-claire-et-stratus.png
https://www.prevision-meteo.ch/style/images/icon/eclaircies.png
https://www.prevision-meteo.ch/style/images/icon/nuit-nuageuse.png
https://www.prevision-meteo.ch/style/images/icon/faiblement-nuageux.png
https://www.prevision-meteo.ch/style/images/icon/fortement-nuageux.png
https://www.prevision-meteo.ch/style/images/icon/averses-de-pluie-faible.png
https://www.prevision-meteo.ch/style/images/icon/nuit-avec-averses.png
https://www.prevision-meteo.ch/style/images/icon/averses-de-pluie-moderee.png
https://www.prevision-meteo.ch/style/images/icon/averses-de-pluie-forte.png
https://www.prevision-meteo.ch/style/images/icon/couvert-avec-averses.png
https://www.prevision-meteo.ch/style/images/icon/pluie-faible.png
https://www.prevision-meteo.ch/style/images/icon/pluie-forte.png
https://www.prevision-meteo.ch/style/images/icon/pluie-moderee.png
https://www.prevision-meteo.ch/style/images/icon/developpement-nuageux.png
https://www.prevision-meteo.ch/style/images/icon/nuit-avec-developpement-nuageux.png
https://www.prevision-meteo.ch/style/images/icon/faiblement-orageux.png
https://www.prevision-meteo.ch/style/images/icon/nuit-faiblement-orageuse.png
https://www.prevision-meteo.ch/style/images/icon/orage-modere.png
https://www.prevision-meteo.ch/style/images/icon/fortement-orageux.png
https://www.prevision-meteo.ch/style/images/icon/averses-de-neige-faible.png
https://www.prevision-meteo.ch/style/images/icon/nuit-avec-averses-de-neige-faible.png
https://www.prevision-meteo.ch/style/images/icon/neige-faible.png
https://www.prevision-meteo.ch/style/images/icon/neige-moderee.png
https://www.prevision-meteo.ch/style/images/icon/neige-forte.png
https://www.prevision-meteo.ch/style/images/icon/pluie-et-neige-melee-faible.png
https://www.prevision-meteo.ch/style/images/icon/pluie-et-neige-melee-moderee.png
https://www.prevision-meteo.ch/style/images/icon/pluie-et-neige-melee-forte.png



--]]
--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------

local jsonFile      = '/home/pi/domoticz/www/monitor/prevision-meteo.json' -- nom du fichier (et son chemin complet) contenant les données de l'API
local iconsPath     = 'http://192.168.1.24:8080/monitor/icons/prevision-meteo/' -- adresse local où sont stockés les icones

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local scriptName        = 'Extraction prévisions météo'
local scriptVersion     = '1.01'
local response = "prevision-meteo_response"
return {
    active = true,
    on =        {       timer           =   { "every 6 minutes" },
                        httpResponses   =   {  response } },

    -- logging =   {    level    =   domoticz.LOG_DEBUG,
                    -- -- level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                    -- -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others
                    -- -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                    -- marker  =   scriptName..' v'..scriptVersion },

    execute = function(domoticz, item)

        local function logWrite ( str, level)  -- afficher le contenu d'un tableau
            local logTableWrite_cache = {}
            local function sub_logTableWrite(str, indent)
                if (logTableWrite_cache[tostring(str)]) then
                    domoticz.log(indent.."*"..tostring(str), level or domoticz.LOG_DEBUG)
                else
                    logTableWrite_cache[tostring(str)]=true
                    if (type(str)=="table") then
                        for pos,val in pairs(str) do
                            if (type(val)=="table") then
                                --domoticz.log(indent.."["..tostring(pos).."] - ["..tostring(str).."] => {", level or domoticz.LOG_DEBUG)
                                domoticz.log(indent.."["..tostring(pos).."] => {", level or domoticz.LOG_DEBUG)
                                sub_logTableWrite(val,indent..string.rep(" ",string.len(pos)+8))
                                domoticz.log(indent..string.rep(" ",string.len(pos)+6).."}", level or domoticz.LOG_DEBUG)
                            elseif (type(val)=="string") then
                                domoticz.log(indent.." "..pos..' = "'..val..'"', level or domoticz.LOG_DEBUG)
                                --domoticz.log(indent..pos..' => "'..val..'"', level or domoticz.LOG_DEBUG)
                            else
                                domoticz.log(indent.." "..pos.." = "..tostring(val), level or domoticz.LOG_DEBUG)
                                --domoticz.log(indent..pos.." = "..tostring(val), level or domoticz.LOG_DEBUG)
                            end
                        end
                    else
                        domoticz.log(indent..tostring(str), level or domoticz.LOG_DEBUG)
                    end
                end
            end
            if (type(str)=="table") then
                domoticz.log("["..tostring(str).."] => {", level or domoticz.LOG_DEBUG)
                sub_logTableWrite(str,"  ")
                domoticz.log("}", level or domoticz.LOG_DEBUG)
            else
                sub_logTableWrite(str,"  ")
            end
            print()
        end

        if (item.isHTTPResponse and item.trigger == response) then
            if (not item.isJSON) then
                logWrite('Last http response was not what expected. Trigger: '..item.trigger,domoticz.LOG_ERROR)
            else
                local contents = domoticz.utils.toJSON(item.json)
                contents = contents:gsub('https://www(.?)prevision(.?)meteo(.?)ch/style/images/icon/', iconsPath) 
                logWrite(contents)
                if contents then
                    file = io.open(jsonFile, "w+")
                    file:write( contents )
                    io.close( file )
                    --file:close()
                    logWrite('ecriture des données dans le fichier '..jsonFile)
                end
            end

        else
            local latitude  = domoticz.settings.location.latitude
                -- local latitude  = '45.85860'
                logWrite('latitude : '..latitude)
                local longitude = domoticz.settings.location.longitude
                -- local longitude = '1.23190'
                logWrite('longitude : '..longitude)
            local url = "https://www.prevision-meteo.ch/services/json/lat="..latitude.."lng="..longitude

            domoticz.openURL({
                  url = url,
                        method = "GET",
                        callback = response})
        end
    end
}
