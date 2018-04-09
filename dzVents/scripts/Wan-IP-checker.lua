--[[
Stocker le script sous le nom Wan-IP-checker.lua dans le répertoire domoticz/scripts/dzVents/scripts   
script originel : Emme (Milano, Italy) https://www.domoticz.com/forum/viewtopic.php?t=14489
modifié légèrement par Manjh http://www.domoticz.com/forum/viewtopic.php?f=65&t=16266&start=120#p171957
modifié par papoo le 22/02/2018 pour suppression de l'utilisation du fichier temporaire, test de l'adresse IP résultante de la requête et création du device text si inexistant
MAJ le : 05/04/2018
Le script est exécuté toutes les 30 minutes (modifiable) et va :
 1. créer un nouveau custom device de type text si un hardware correspondant existe (Dummy (Does nothing, use for virtual switches only)) ce n'est pas immédiat attendre au moins les 30 premières minutes avant de s’inquiéter
 2. récupérer votre adresse IP publique actuelle et la stocker dans le device text  auto créé (il faudra attendre 30 minutes supplémentaires pour que le device se mette à jour)
 3. la comparer à l'IP précédente
 4. vous envoyer un message d'avertissement si les deux adresses sont différentes via les notifications domoticz et mettre à jour le device text avec la nouvelle adresse
 documentation DzVents : https://www.domoticz.com/wiki/DzVents:_next_generation_LUA_scripting
 
 https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/Wan-IP-checker.lua
 https://pon.fr/dzvents-changement-dip-publique/
 http://easydomoticz.com/forum/viewtopic.php?f=17&t=5977
--]]

return {
    active = true,
	on = {
		timer = {
            'every 2 hours'
            --'every 2 minutes'
            --'every minute'
            --'every 30 minutes'
	},
        
        logging = { -- La section de journalisation facultative vous permet de remplacer le paramètre de journalisation globale de dzVents 
                    -- comme défini dans Configuration> Paramètres> Autre> Système d'événements> Niveau de journalisation dzVents. 
                    -- Cela peut être pratique lorsque vous voulez que ce script ait une journalisation de débogage étendue pendant que le reste de votre script s'exécute en mode silencieux. 
            level = domoticz.LOG_ERROR, -- domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR, domoticz.LOG_FORCE,
            marker = '[WAN IP]'
    },
        
		httpResponses = {
			'trigger' -- doit correspondre au callback passé à la commande openURL ne pas modifier si vous ne savez pas ce que vous faite
		}
	},
	execute = function(domoticz, item)
--------------------------------------------      
------------ Variables à éditer ------------
-------------------------------------------- 
        local devName       = 'Adresse IP publique'
        local location      = 'test RPI2' -- votre information de localisation: utilisé dans le sujet du message d'avertissement
        local domoticzURL   = 'http://127.0.0.1:8080'
        local curl          = '/usr/bin/curl -m 5 ' -- chemin vers curl        
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------         
        
        local script        = 'Wan-IP-checker'
        local version       = '1.4'
        local devIP         = domoticz.devices(devName)    
        --local getIP         = 'https://4.ifcfg.me/'
        local getIP         = 'http://whatismyip.akamai.com/'        
        local actIP         = ''
        local info          = ''
        local testIP        = ''

   
        
		if (item.isTimer) and devIP then -- si le device existe on exécute normalement le script

            domoticz.log(script..' Version : '..version)
            local currIP        = devIP.text
            info = assert(io.popen(curl..getIP))
            actIP = info:read('*all')
            info:close()
                domoticz.log('Adresse IP résultante : '..actIP)
                -- test validité adresse IP
                local chunks = {actIP:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")} 
                if (#chunks == 4) then
                    for _,v in pairs(chunks) do
                        if (tonumber(v) < 0 or tonumber(v) > 255) then
                            domoticz.log('Adresse IP résultante invalide')
                            testIP = false
                        end
                    end
                    domoticz.log('Adresse IP résultante valide')
                    testIP = true
                else
                    domoticz.log('Adresse IP résultante invalide')
                    testIP = false
                end
                -- fin test validité adresse IP
                if actIP == nil or testIP == false then 
                    actIP = 'Impossible de récupérer l\'adresse IP publique'  
                           
                elseif actIP ~= currIP  and testIP == true then
                    msgTxt = 'L\'IP publique a changé : '..currIP..' ==> '..actIP
                    domoticz.log(msgTxt)
                    --[[ pour une notification sur un seul système, les différents systèmes disponibles sont :
                        NSS_GOOGLE_CLOUD_MESSAGING NSS_HTTP NSS_KODI NSS_LOGITECH_MEDIASERVER NSS_NMA NSS_PROWL NSS_PUSHALOT NSS_PUSHBULLET NSS_PUSHOVER NSS_PUSHSAFER
                        la syntaxe diverge de la notification standard il faut ajouter deux champs supplémentaires
                        exemple : domoticz.notify('test notification pushbullet ', "message test", domoticz.PRIORITY_EMERGENCY,'','',domoticz.NSS_PUSHBULLET)
                        CAD => ,'','',domoticz.NSS_PUSHBULLET à la fin avant la parenthèse
                    --]]
                    domoticz.notify('Attention! Changement d\'IP publique : '..location, msgTxt, domoticz.PRIORITY_EMERGENCY,'','',domoticz.NSS_TELEGRAM)
                    devIP.updateText(actIP)

                else 
                    domoticz.log('Adresse précédente : '..currIP)
                    domoticz.log('Pas de changement d\'adresse IP publique')
                end 
            
        elseif (item.isTimer) and devIP == nil then-- si le device n'existe pas tente de trouver l'IDX du Hardware dummy
                    
                domoticz.openURL({
                    url = domoticzURL .. '/json.htm?type=hardware',
                    method = 'GET',
                    callback = 'trigger', -- voir httpResponses ci-dessus.
                })
                domoticz.log('Timer event')

        end

        if (item.isHTTPResponse) and devIP == nil  then -- si le device n'existe pas on créé le device text
            

                if (item.statusCode == 200) then
                    if (item.isJSON) then
                        domoticz.log('Fichier JSON détecté')
                        local jsonValeur = domoticz.utils.fromJSON(item.data)
                        for Index, Value in pairs( jsonValeur.result ) do
                            if Value.Type == 15 then -- hardware dummy = 15
                                id = Value.idx
                                domoticz.log('L\'ID du hardware Dummy est : '..id)
                            end
                        end
                            if id ~= nil then 
                                os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=createdevice&idx='..id..'&sensorname='..domoticz.utils.urlEncode(devName)..'&sensormappedtype=0xF313"')
                                domoticz.log('création du nouveau device text')                            
                            end 

                    end
                else
                    domoticz.log('Un problème est survenu lors de la gestion de la demande', domoticz.LOG_ERROR)
                    domoticz.log(item, domoticz.LOG_ERROR)
                end
            end
        

	end
}