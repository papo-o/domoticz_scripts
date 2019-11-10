--[[
/home/pi/domoticz/scripts/dzVents/scripts/vacancesScolaires.lua
author/auteur = papoo
update/mise à jour = 10/11/2019
création = 05/08/2017
https://pon.fr/
https://github.com/papo-o/dz_scripts/blob/master/dzVents/scripts/
https://easydz.com/forum/

V1.xx  : https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_vacances_scolaires.lua

Principe : récupérer via l'API  de data.education.gouv (https://data.education.gouv.fr/explore/dataset/fr-en-calendrier-scolaire/api/?disjunctive.description)
les informations de vacances scolaires pour une date, une zone et une academie

--]]
--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------

local zone 				= 'A'                           -- Indiquer ici la zone (A, B ou C)
local location 			= 'Limoges'                    	-- Indiquer ici l'academie (https://fr.wikipedia.org/wiki/Acad%C3%A9mie_(%C3%A9ducation_en_France))
local holidayNow 		= 'Vacances Scolaires' 			-- Indiquer ici le nom du device vacances aujourd'hui de type switch nil si inutilisé 
local holidayTomorrow 	= 'Vacances Scolaires Demain'   -- Indiquer ici le nom du device vacances demain de type switch nil si inutilisé 

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------

local scriptName        = 'Vacances Scolaires'
local scriptVersion     = '2.01'
local response 			= 'dataEducation_response'

return {
    active = true,
    on =        {       timer           =   { 'at 00:11' },
						--timer           =   { "every minute" },
                        httpResponses   =   {  response } },

    logging =   {   level    =   domoticz.LOG_DEBUG,
                    -- level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                    marker  =   scriptName..' v'..scriptVersion },

    execute = function(dz, item)

        local _ , round = dz.utils._, dz.utils.round
		local H0, H1 = 0, 0
        local function logWrite(str,level)
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end
        
		local function date2timestamp(now)
			a, b, Y, M, D = string.find(now, "(%d+)-(%d+)-(%d+)")
			return os.time{year=Y, month=M, day=D, hour=00, minute=00}
		end
        
		local Timestamp = dz.time.dDate
		--local Timestamp = date2timestamp("2019-12-20") -- pour test (uniquement sur l'année en cours)
		
        if (item.isHTTPResponse and item.trigger == response) then
            if (not item.isJSON) then
                logWrite('Last http response was not what expected. Trigger: '..item.trigger,dz.LOG_ERROR)
            else

                local holidays          = {}
				local start_date 		= {}
				local end_date			= {}
                holidays = item.json.records

                if holidays ~= nil then
                    for i, Result in ipairs( holidays ) do
                        start_date[i] = Result.fields.start_date
                        end_date[i] = Result.fields.end_date
						
						-- vacances aujourd'hui
						if (date2timestamp(start_date[i]) < Timestamp or date2timestamp(start_date[i]) == Timestamp) and (date2timestamp(end_date[i]) > Timestamp or date2timestamp(end_date[i]) == Timestamp) then
							logWrite('date de début des vacances '.. tostring(start_date[i]))
							logWrite('date de fin des vacances '.. tostring(end_date[i]))
							H0 = 1
						end
						--vacances demain
						if (date2timestamp(start_date[i]) < (Timestamp + 24*3600) or date2timestamp(start_date[i]) == (Timestamp + 24*3600)) and (date2timestamp(end_date[i]) > (Timestamp + 24*3600) or date2timestamp(end_date[i]) == (Timestamp + 24*3600)) then
							logWrite('date de début des vacances '.. tostring(start_date[i]))
							logWrite('date de fin des vacances '.. tostring(end_date[i]))
							H1 = 1
						end
                    end
					logWrite('H0 : '..tostring(H0))
					if holidayNow ~= nil then 
						if H0 == 1 then 
							dz.devices(holidayNow).switchOn().checkFirst() 
							logWrite('Device '..holidayNow..' sur ON')
						else
							dz.devices(holidayNow).switchOff().checkFirst()	
							logWrite('Device '..holidayNow..' sur OFF')
						end
					else
						logWrite('pas de device pour les vacances du jour')
					end	
					
					logWrite('H1 : '..tostring(H1))					
					if holidayTomorrow ~= nil then
						if H1 == 1 then 
							dz.devices(holidayTomorrow).switchOn().checkFirst()
							logWrite('Device '..holidayTomorrow..' sur ON')
						else
							dz.devices(holidayTomorrow).switchOff().checkFirst()
							logWrite('Device '..holidayTomorrow..' sur OFF')
						end
					else 
						logWrite('pas de device pour les vacances de demain')
					end	
                end
            end

        else
			local url = "https://data.education.gouv.fr/api/records/1.0/search/?dataset=fr-en-calendrier-scolaire&facet=start_date&facet=end_date&refine.zones=Zone+".. zone .."&rows=40&refine.start_date=".. dz.time.year .."&refine.location=".. location

            dz.openURL({
                  url = url,
                        method = "GET",
                        callback = response})
        end
    end
}
