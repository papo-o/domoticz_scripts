--script_time_fin_cycle.lua

--Change the values below to reflect to your own setup
local washer_status_uservar   = 'Etat Seche Linge'
local energy_consumption      = 'Conso Sèche Linge'         --Name of Z-Wave plug that contains actual consumption of washingmachine (in Watts)
local washer_counter_uservar  = 'Compteur Seche Linge'        --Name of the uservariable that will contain the counter that is needed
local idle_minutes            = 15                               --The amount of minutes the consumption has to stay below the 'consumption_lower' value
local consumption_upper       = 200                              --If usage is higher than this value (Watts), the washingmachine has started
local consumption_lower       = 3                             --If usage is lower than this value (Watts), the washingmachine is idle for a moment/done washing
local name 					  = "Sèche Linge"
local debugging = false  			-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------   
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"
require('fonctions_perso')
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------

-- sWatt, sTotalkWh              = otherdevices_svalues['Clothes Washer Power Usage']:match("([^;]+);([^;]+)")
-- washer_usage                  = tonumber(sWatt)
washer_usage                  = tonumber(otherdevices_svalues[energy_consumption])
voir_les_logs('valeur consommmation '.. name ..' = '..washer_usage,debugging)
commandArray = {}

voir_les_logs("script_time_fin_cycle_seche_linge.lua",debugging)
--Virtual switch is off, but consumption is higher than configured level, so washing has started
if (washer_usage > consumption_upper) and uservariables[washer_status_uservar] == 0 then
  commandArray['Variable:' .. washer_status_uservar]='1'
  voir_les_logs('La consommation d\'énergie actuelle (' ..washer_usage.. 'W) est au-dessus de la limite supérieure (' ..consumption_upper.. 'W), Donc le '.. name ..' a démarré!',debugging)
  commandArray['Variable:' .. washer_counter_uservar]=tostring(idle_minutes)
end

--Washing machine is not using a lot of energy, check the counter
if (washer_usage < consumption_lower) and uservariables[washer_status_uservar] == 1 then 
  commandArray['Variable:' .. washer_counter_uservar]=tostring(math.max(tonumber(uservariables[washer_counter_uservar]) - 1, 0))
  voir_les_logs('La consommation d\'énergie actuelle (' ..washer_usage.. 'W) est au-dessous de la limite inférieure (' ..consumption_lower.. 'W), Le '.. name ..' est au repos ou presque pret',debugging)
  voir_les_logs('Soustraction compteur, ancienne valeur: ' ..uservariables[washer_counter_uservar].. ' minutes',debugging)
elseif ((uservariables[washer_counter_uservar] ~= idle_minutes) and uservariables[washer_status_uservar] == 1) then
  commandArray['Variable:' .. washer_counter_uservar]=tostring(idle_minutes)
  voir_les_logs('Réinitialisation minuterie '.. name,debugging)
end

--Washingmachine is done
if ((uservariables[washer_status_uservar] == 1) and uservariables[washer_counter_uservar] == 0) then
  voir_les_logs('La consommation d\'énergie actuelle du '.. name ..' est de ' ..washer_usage.. 'W',debugging)
  voir_les_logs('Le '.. name ..' vient de se terminer!',debugging)
  commandArray['SendNotification']='Cycle Terminé: '.. name ..'#Le '.. name ..' vient de se terminer#0'
  commandArray['Mid Value']='Set Level 2'
  commandArray['Variable:' .. washer_status_uservar]='0'
end

return commandArray