--[[	This script switches off a device after it has consumed no or almost no power for a certain period of time.
    it switches On 

	Prerequisits
	==================================
	Domoticz v3.8837 or later (dzVents version 2.3 or later)

	CHANGE LOG: See https://www.domoticz.com/forum/viewtopic.php?f=72&t=23363

-- Authors  ----------------------------------------------------------------
	V1.0 - Wizzard72 with the help of dannybloe
    V1.1 - papoo
]]--

function lesparametres(tableau)

for t, i in pairs(tableau) do
    if t == "Switch" then  Switch = i end
    if t == "TimeOut" then  TimeOut = i end
    if t == "MinWatt" then MinWatt = i end
    if t == "MaxWatt" then MaxWatt = i end
    if t == "Notify" then Notify = i end
    if t == "Notify_On" then Notify_On = i end    
    if t == "MidValue" then MidValue = i end    
    if t == "SubSystem" then SubSystem = i end
    end

return Switch,TimeOut,MinWatt,MaxWatt,Notify,SubSystem

end
-- create a lookup table that matches a usage
-- device to the accompanying switch

local DEVICES = { -- [device consommation] = switch associé,
	['Lave Linge (Consommation)'] = 'Lave Linge',		-- You need to have a inline wall plug that measures energy,
	['Sèche Linge (Consommation)'] = 'Sèche Linge'--,	-- here you make the link between the energy device and the wall plug.
                                                        -- Adjust to your needs. Between every line you need to add a ",".
}
-- TimeOut = Temps d'inactivité avant mise à l'arrêt
-- MinWatt = seuil en dessous duquel l'équipement peut être considéré à l'arrêt
-- Maxwatt = Seuil  en dessus duquel l'équipement peut être considéré en marche
-- Notify = 'Yes' pour être notifié de l'état de l'équipement, 'No' pour ne pas l'être
-- Notify_On = 'Yes' pour être notifié de la mise en marche de l'équipement, 'No' pour ne pas l'être
-- MidValue = pour les notifications sur xiaomi gateway via un switch selector, chaque numéro correspond à un fichier son pré enregistré. nil si inutilisé
-- subSystem = subSystem de notification, nil pour l'ensemble des notifications paramétrées dans domoticz
--les subsystem disponible sont (précédé de domoticz.) : NSS_GOOGLE_CLOUD_MESSAGING, NSS_HTTP, NSS_KODI, NSS_LOGITECH_MEDIASERVER, NSS_NMA,NSS_PROWL, NSS_PUSHALOT, NSS_PUSHBULLET, NSS_PUSHOVER, NSS_PUSHSAFER, NSS_TELEGRAM

local parametres = {
['Lave Linge'] = {['TimeOut'] = 4, ['MinWatt'] = 4, ['MaxWatt'] = 15, ['Notify'] = 'Yes', ['Notify_On'] = 'No', ['MidValue'] = 1, ['SubSystem'] = 'domoticz.NSS_HTTP'},-- 'NSS_PUSBULLET'}},
['Sèche Linge'] = {['TimeOut'] = 8, ['MinWatt'] = 3, ['MaxWatt'] = 100, ['Notify'] = 'Yes', ['Notify_On'] = 'No', ['MidValue'] = 2, ['SubSystem'] = 'domoticz.NSS_HTTP'}--, 'domoticz.NSS_PUSBULLET'}},
}

local SelectorMid = 'Mid Value' --nom du Selector Switch correspondant à la gateway Xiaomi
return {
    active = true, -- active (true) ou désactive (false) le script
	logging = {
         level = domoticz.LOG_INFO,                                             -- Max. one level can be active; comment the others
        -- level = domoticz.LOG_ERROR,
        -- level = domoticz.LOG_DEBUG,
        -- level = domoticz.LOG_MODULE_EXEC_INFO,
        marker = 'FIN DE CYCLE v1.1 '
	},
	on = {
		devices = {							-- Make sure that the devices are the same as above
			'Lave Linge (Consommation)',
			'Lave Linge',
			'Sèche Linge (Consommation)',
			'Sèche Linge'
		},
	},
	data = { 								-- use exact device names to match USAGE_DEVICES
		['Lave Linge (Consommation)'] = { history = true, maxMinutes = 6 },
		['Sèche Linge (Consommation)'] = { history = true, maxMinutes = 10 }--,
	
	},

	execute = function(domoticz, device)

		if (DEVICES[device.name] ~= nil) then
		-- we have a usage sensor here
        lesparametres(parametres[DEVICES[device.name]])
    
			local switch = domoticz.devices(DEVICES[device.name])
			local history = domoticz.data[device.name]

            domoticz.log("moyenne = " .. history.avg(), domoticz.LOG_DEBUG)
			domoticz.log("timeout = " .. TimeOut, domoticz.LOG_DEBUG)
            domoticz.log("délai = " .. switch.lastUpdate.minutesAgo, domoticz.LOG_DEBUG)
			domoticz.log("MinWatt = " .. MinWatt, domoticz.LOG_DEBUG)
            domoticz.log("MaxWatt = " .. MaxWatt, domoticz.LOG_DEBUG)
            domoticz.log("MidValue = " .. MidValue, domoticz.LOG_DEBUG)
            domoticz.log("Notify = " .. Notify, domoticz.LOG_DEBUG)
            domoticz.log("Notify_On = " .. Notify_On, domoticz.LOG_DEBUG)
			history.add(device.WhActual)
			if switch.active and (history.avg() <= MinWatt) and (switch.lastUpdate.minutesAgo >= TimeOut) then
			 	switch.switchOff().checkFirst()
			end
            if (history.avg() >= MaxWatt) then
			 	switch.switchOn().checkFirst()
			end
		else
			-- device is a switch
            lesparametres(parametres[device.name])
			if (device.active and Notify == 'Yes' and Notify_On == 'Yes') then
				domoticz.notify(
					device.name .. ' Début de cycle', 
					'le '.. device.name .. ' commence son cycle, Je vous préviendrais lorsqu\'il sera terminé', 
					domoticz.PRIORITY_EMERGENCY, 
                    '',--Sound
                    '',--Extra
                    domoticz.NSS_HTTP--SubSystem
				)
			elseif (Notify == 'Yes') and (device.lastUpdate.minutesAgo >= TimeOut) then
                domoticz.log("MidValue = " .. MidValue, domoticz.LOG_DEBUG)
                domoticz.log("Notify = " .. Notify, domoticz.LOG_DEBUG)
                domoticz.log("Notify_On = " .. Notify_On, domoticz.LOG_DEBUG)
				domoticz.notify(
					device.name .. ' Cycle Terminé', --subject
					--'Cycle Terminé : '.. device.name ..'#
                    'Le '.. device.name ..' vient de se terminer', -- Message
                    domoticz.PRIORITY_EMERGENCY, --Priority
                    '',--Sound
                    '',--Extra
                    domoticz.NSS_HTTP--SubSystem
				)
                if (MidValue ~= nil) then 
                    domoticz.devices(SelectorMid).switchSelector(MidValue)
                    domoticz.log("MidValue = " .. MidValue, domoticz.LOG_DEBUG)
                end -- notification via xiaomi gateway
			end

                
		end
	end
}
