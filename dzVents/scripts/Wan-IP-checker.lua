--[[
Stocker le script sous le nom Wan-IP-checker.lua dans domoticz/scripts/dzVents/scripts   
script originel : Emme (Milano, Italy) https://www.domoticz.com/forum/viewtopic.php?t=14489
modifié légèrement par Manjh http://www.domoticz.com/forum/viewtopic.php?f=65&t=16266&start=120#p171957
modifié par papoo (22/02/2018) pour suppression de l'utilisation du fichier temporaire et création du device text si inexistant

 Le script va:
 1. récupérer votre adresse IP publique actuelle et la stocker dans le device text  auto créé
 2. la comparer à l'IP précédente
 3. vous envoyer un message d'avertissement si les deux adresses sont différentes via les notifications domoticz et mettre à jour le device text
 documentation DzVents : https://www.domoticz.com/wiki/DzVents:_next_generation_LUA_scripting
 
 
 
--]]

return {
	on = {
		timer = {
            'every 30 minutes'
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
        
        local dzb           = domoticz.LOG_FORCE -- domoticz.LOG_INFO or domoticz.LOG_MODULE_EXEC_INFO or domoticz.LOG_DEBUG or domoticz.LOG_ERROR or domoticz.LOG_FORCE
        local script        = 'Wan-IP-checker'
        local version       = '1.0'
        local devIP         = domoticz.devices(devName)    
        local getIP         = 'https://4.ifcfg.me/'
        local actIP         = ''
        local info          = ''
        
        
		if (item.isTimer) and devIP then -- si le device existe on exécute normalement le script
        domoticz.log(script..' Version : '..version)
        local currIP        = devIP.text
        info = assert(io.popen(curl..getIP))
        actIP = info:read('*all')
        info:close()
        if actIP == nil then actIP = 'Impossible de récupérer l\'adresse IP publique' end 
        
        if actIP ~= currIP then
            msgTxt = 'L\'IP publique a changé : '..currIP..' ==> '..actIP
            domoticz.log(msgTxt, dzb)
            domoticz.notify('Attention! Changement d\'IP publique : '..location, msgTxt, domoticz.PRIORITY_EMERGENCY)
            devIP.updateText(actIP)

        else 
            domoticz.log('L\'adresse IP publique n\'a pas changé', dzb)
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
                                domoticz.log('L\'ID du hardware Dummy est : '..id, dzb)
                            end
                        end
                            if id ~= nil then 
                                os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=createdevice&idx='..id..'&sensorname='..domoticz.utils.urlEncode(devName)..'&sensormappedtype=0xF313"')
                                domoticz.log('création du nouveau device text', dzb)                            
                            end                        

                    end
                else
                    domoticz.log('Un problème est survenu lors de la gestion de la demande', domoticz.LOG_ERROR)
                    domoticz.log(item, domoticz.LOG_ERROR)
                end
            end
        
	end
}
