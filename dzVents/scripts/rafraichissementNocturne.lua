--[[
rafraichissementNocturne.lua
author/auteur = papoo
update/mise à jour = 02/01/2020
creation = 24/06/2017
github https://github.com/domoticz_scripts/dzVents/scripts/rafraichissementNocturne.lua
blog https://pon.fr/
forum http://easydomoticz.com/forum/viewtopic.php?f=17&t=4343#p38107
ce script utilise la fonction de notification universelle https://pon.fr/dzvents-fonction-de-notification-universelle/
--]]

local scriptName        		= 'Rafraichissement nocturne'
local scriptVersion     		= '2.0'
local seuil_notification 		= 25 	        	                    -- seuil température intérieure au delà duquel les notifications seront envoyées
local deltaT 					= 2                                                -- Delta T entre T° interieure et T° extérieure avant notification 
local frequency_notifications 	= 3600
local quiet_hours 				= "23:00-07:15"
local subSystems				= "TELEGRAM,PUSHBULLET" --NSS_GOOGLE_CLOUD_MESSAGING, NSS_HTTP, NSS_KODI, NSS_LOGITECH_MEDIASERVER, NSS_NMA,NSS_PROWL, NSS_PUSHALOT, NSS_PUSHBULLET, NSS_PUSHOVER, NSS_PUSHSAFER, NSS_TELEGRAM
local temp_ext 					= 'Temperature exterieure' 	                    -- nom de la sonde extérieure
local les_temperatures 			= {
								'Temperature Entree',
								'Temperature Salon',
								'Temperature Parents',
								'Temperature Bureau',
								'Temperature Cuisine',
								'Douche'
		} -- Liste de vos sondes intérieures séparées par une virgule
local subject               	= "\xE2\x9A\xA0 /!\\ Ouverture des fenetres recommandee /!\\ \xE2\x9A\xA0" 

return {
    active = true,
    on = { timer =   {'every 10 minutes'}},
	--on = { timer =   {'every minute'}},
    -- logging =   {    level    =   domoticz.LOG_DEBUG,
                    -- -- level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                    -- -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others
                    -- -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                -- marker = scriptName..' v'..scriptVersion },
				
	

    execute = function(dz)
		local round = dz.utils.round
		--local _ = require('lodash')
		local function logWrite(str,level)             -- Support function for shorthand debug log statements
			dz.log(tostring(str),level or dz.LOG_DEBUG)
		end
		
		local function split(s, delimiter)
			if s ~= nil then
				result = {};
				for match in (s..delimiter):gmatch("(.-)"..delimiter) do
					table.insert(result, match);
				end
			else
				result = {""};
			end
			return result;
		end


		local function notificationTable(str)
		--NSS_GOOGLE_CLOUD_MESSAGING, NSS_HTTP, NSS_KODI, NSS_LOGITECH_MEDIASERVER, NSS_NMA,NSS_PROWL, NSS_PUSHALOT, NSS_PUSHBULLET, NSS_PUSHOVER, NSS_PUSHSAFER, NSS_TELEGRAM
			if (str) then
			str = string.gsub (str,"GCM", dz.NSS_GOOGLE_CLOUD_MESSAGING)
			str = string.gsub (str,"GOOGLE_CLOUD_MESSAGING", dz.NSS_GOOGLE_CLOUD_MESSAGING)
			str = string.gsub (str,"HTTP", dz.NSS_HTTP)
			str = string.gsub (str,"LMS", dz.NSS_LOGITECH_MEDIASERVER)
			str = string.gsub (str,"LOGITECH_MEDIASERVER", dz.NSS_LOGITECH_MEDIASERVER)
			str = string.gsub (str,"NMA", dz.NSS_NMA)
			str = string.gsub (str,"PROWL", dz.NSS_PROWL)
			str = string.gsub (str,"PUSHALOT", dz.NSS_PUSHALOT)
			str = string.gsub (str,"PUSHOVER", dz.NSS_PUSHOVER)
			str = string.gsub (str,"PUSHSAFER", dz.NSS_PUSHSAFER)
			str = string.gsub (str,"PUSHBULLET", dz.NSS_PUSHBULLET)
			str = string.gsub (str,"TELEGRAM", dz.NSS_TELEGRAM)
			end
			return (split(str,','))
		end
		
		local tempExt = round(dz.devices(temp_ext).temperature,2)
			  logWrite("le device  : "..tostring(dz.devices(temp_ext).name).." indique une température de "..tostring(tempExt).."°C")		
		local i = 0
		local tempsInt = 0
        for _, name in ipairs(les_temperatures) do
			i = i + 1
			local dev = dz.devices(name)
            if dev.temperature then
				logWrite("le device  : "..tostring(dev.name).." indique une température de "..tostring(round(dev.temperature,2)).."°C")
				tempsInt = tempsInt + dev.temperature
			end
        end
		logWrite("nombre de sondes intérieures parcourues est de "..tostring(i))
		tempsInt = round(tempsInt/i)
		logWrite("la moyenne ambiante intérieure est de  "..tostring(tempsInt).."°C")
		if (tempsInt + deltaT) > tempExt and seuil_notification < tempExt then 
			logWrite("la moyenne ambiante intérieure moins le deltat T est de  "..tostring(tempsInt - deltaT).."°C")
			dz.helpers.managedNotify(dz, subject, "Ouverture des fenêtres recommandée, la température moyenne ambiante intérieure est supérieure de "..deltaT.."°C à la temperature extérieure" , notificationTable(subSystems), frequency_notifications , quiet_hours)
		end
	        -- dz.devices(les_temperatures).forEach(
				-- function(device)
					-- logWrite("le device  : "..tostring(device.name).." a une température de "..tostring(device.temperature))


				-- end
			-- )
	-- local temp = dz.devices().filter(function(device)
		-- return _.includes(les_temperatures, device.name)
	-- end)
-- print_table(temp)
    end -- execute function
}
