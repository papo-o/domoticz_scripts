--[[
alerteMoustiques.lua for [ domoticzVents >= 2.4 ]
API proposée par domo89 > https://easydomoticz.com/forum/viewtopic.php?t=8386&p=69054#p69054
author/auteur = papoo
update/mise à jour = 26/04/2019
création = 26/04/2019
https://pon.fr/dzvents-alerte-moustiques
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/moustiques.lua
https://easydomoticz.com/forum/viewtopic.php
Si vous souhaitez suivre les deux alertes (général moustiques et moustiques tigre) créez deux instances de ce script

les risques se présentent sous 2 formes :

– Les risques des moustiques en général, qui ne donne aucune information d’ordre sanitaire. Elle commente la météo des moustiques et signale la présence de moustiques qui peuvent provoquer des inconforts.

– Les risques du moustique tigre qui nécessite une surveillance particulière, puisque celui-ci est en train de coloniser progressivement le territoire hexagonal, et qu’il est potentiellement dangereux puisque vecteur de la dengue et du chikungunya.

pour l'ensemble des moustiques, les couleurs ont les significations suivantes :

Vert : Rien à signaler

Jaune : les conditions météorologiques sont dites favorables pour une prolifération des moustiques, dans les zones géographiques < à 1500 mètres d’altitude.

Orange : vigilance moustiques a dans ce cas reçu des informations nous signalant des foyers de piqures. Ces déclarations nous proviennent de sources fiables ou bien sont vérifiées localement avant d’être publiées, et en général, ces foyers de piqûres créent localement une nuisance au-delà de la norme habituellement constatée et acceptée.

Rouge : La couleur rouge est réservée aux états d’alerte sanitaire.

Le détail et l’étendue de ces alertes figure dans les informations spécifiques listées sur la page réservée au département concerné du site. Pour y accéder, il suffit de cliquer sur le dit département dans la carte de France située en page d’accueil.

Concernant les risques du moustique Tigre, les légendes sont les suivantes:

Vert : Rien à Signaler-Veille Sanitaire.C’est l’état normal d’une situation  ou rien de particulier n’est à déclarer, mais le dispositif de « veille sanitaire » permanent est en place, organisé autour des Agences Régionales de Santé et qui permet de détecter tout cas significatif, le plus rapidement possible.

Jaune : Surveillance Entomologique. Un dispositif supplémentaire de veille est mis en place dans certains départements, en général motivés par la crainte d’une menace particulière. Il s’agit d’un dispositif de surveillance entomologique qui prévoit :

-l’identification de zones sur une carte territoriale, sur lesquelles des observations sont effectuées sur le terrain tout au long de la saison et qui permettent de voir évoluer la présence de gites larvaires. Dans ces zones, on observe des gites naturels mais on installe aussi des pièges pondoirs.

-des équipes mobilisées pour faire ces observations et les analyser

Orange : Interception ponctuelle du moustique Tigre.Le moustique Tigre a été intercepté (et authentifié) de manière ponctuelle, au moins une fois au cours des 5  dernières années. On ne peut pas encore dire s’il est implanté durablement ou s’il va pouvoir disparaître.

Rouge : Moustique Tigre implanté et actif. Le moustique Tigre est « implanté et actif ». Cette espèce en effet a la capacité de s’adapter aux conditions hivernales rigoureuses de certaines de nos régions, et peut assez rapidement réapparaître  chaque année, avec les beaux jours

Pourpre: cas de maladie déclarée. Cette couleur est réservée pour les départements où un ou plusieurs des cas de maladies « autochtones » (dengue ou chikungunya) sont recensés, avec plusieurs stades, propres aux phénomènes épidémiques
--]]
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local departement       = 87 --département
local url = 'https://vigilance-moustiques.com/maps-manager/public/json/'
local typeMoustique = 1 
--1 = moustiques en général, alerte qui ne donne aucune information d’ordre sanitaire. Elle commente la météo des moustiques et signale la présence de moustiques qui peuvent provoquer des inconforts
--2 = uniquement moustique tigre qui nécessite une surveillance particulière, puisque celui-ci est en train de coloniser progressivement le territoire hexagonal, et qu’il est potentiellement dangereux puisque vecteur de la dengue et du chikungunya
local alert_device = "Moustiques" -- nom ou idx du device alerte, nil si inutilisé
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local scriptName        = 'Alerte moustiques'
local scriptVersion     = '1.0'
local alerteMoustique   = "alerteMoustique"..typeMoustique


return {
    active = true,
    --on = { timer =   {'at 21:52 on mon'}},
    on = {  timer =   {'every 6 hours'},
            httpResponses   =   { "vigilance-moustiques_Trigger"..typeMoustique }    -- Trigger the handle Json part
        },
            logging =   {   -- level    =   domoticz.LOG_DEBUG,
                            -- level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                            -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others
                            -- level    =   domoticz.LOG_MODULE_EXEC_INFO,

            marker = scriptName..' v'..scriptVersion },
            data    =   {   alerteMoustique     = {initial = {} },             -- Keep a copy of last json just in case
    },

    execute = function(domoticz, item)

            local function logWrite(str,level)             -- Support function for shorthand debug log statements
                domoticz.log(tostring(str),level or domoticz.LOG_DEBUG)
            end

            local function getData(departement,data)
                local data = data.alertes
                local mStatus = nil
                local colorType = nil
                for colorType in pairs(data) do
                    --logWrite(colorType)
                    for k, department in pairs(data[colorType]) do
                        if tostring(department) == tostring(departement) then
                            logWrite("département : "..department)
                            mStatus = colorType
                            logWrite("couleur risque : "..colorType)
                            break
                        end
                    end
                end
                logWrite("mStatus : ".. tostring(mStatus))
                return mStatus
            end

            local function getDataFromColor(color)
                code = 0
                text = "Risque Très Faible"
                if color == "jaune" then 
                    code = 1
                    text = "Risque Faible"
                elseif color == "orange" then
                    code = 2
                    text = "Risque Modéré"
                elseif color == "rouge" then
                    code = 3
                    text = "Risque Élevé"
                elseif color == "pourpre" then
                    code = 4
                    text = "Risque Très Élevé"
                end
                logWrite(tostring(code.." "..text))
                return code,text
            end

            if (item.isTimer) then
                domoticz.openURL({
                url = url..typeMoustique,
                callback = 'vigilance-moustiques_Trigger'..typeMoustique
            })

        end
        if (item.isHTTPResponse and item.ok) then
            -- we know it is json but dzVents cannot detect this
            -- convert to Lua
            local json = domoticz.utils.fromJSON(item.data)
            -- json is now a Lua table
            if #item.data > 0 then
                domoticz.data.alerteMoustique    = domoticz.utils.fromJSON(item.data)
                rt = domoticz.utils.fromJSON(item.data)
            else
                logWrite("Problem with response from vigilance-moustiques.com (no data) using data from earlier run",domoticz.LOG_ERROR)
                rt  = domoticz.data.alerteMoustique                        -- json empty. Get last valid from domoticz.data
                if #rt < 1 then                                            -- No valid data in domoticz.data either
                    logWrite("No previous data. are vigilance-moustiques.com, ok?",domoticz.LOG_ERROR)
                    return false
                end
            end

            if alert_device ~= nil then
                domoticz.devices(alert_device).updateAlertSensor(getDataFromColor(getData(departement,rt)))
            else
                getDataFromColor(getData(departement,rt))
            end
        end
    end -- execute function
}
