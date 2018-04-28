--[[   
~/domoticz/scripts/lua/script_device_temp_ext.lua
auteur : papoo
version : 1.01
MAJ : 11/08/2016
création : 06/05/2016
 tx = température maximale du jour J mesurée à 2 mètres du sol sous abri et relevée entre J à 6h et J+1 (le lendemain) à 6h UTC. 
 tn = température minimale du jour J mesurée à 2 mètres du sol sous abri et relevée entre J-1 (la veille) à 18h et J à 18h UTC. 
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging = false  					-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local url = '127.0.0.1:8080'   			-- user:pass@ip:port de domoticz
local temp_ext  = 'Temperature exterieure' 	-- nom de la sonde extérieure
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = 'Mesure temperature exterieure'
local version = '1.01'
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"   -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script
require('fonctions_perso')                                                      -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script

-- ci-dessous les lignes à décommenter en cas d'utilisation des fonctions directement dans ce script( supprimer --[[ et --]])
--[[function voir_les_logs (s, debugging) -- nécessite la variable local debugging
    if (debugging) then 
		if s ~= nil then
        print (s)
		else
		print ("aucune valeur affichable")
		end
    end
end	-- usage voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
--]]
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------

commandArray = {}
if (devicechanged[temp_ext])then
voir_les_logs("=========== Mini/Maxi Température Extérieure (v1.0) ===========",debugging)
		if(uservariables['Tx'] == nil) then
		-- Création de la variable Tx si elle n'existe pas
         commandArray['OpenURL']=url..'/json.htm?type=command&param=saveuservariable&vname=Tx&vtype=2&vvalue=150'
            voir_les_logs("--- --- --- Création Variable Tx manquante --- --- --- ",debugging)
        print('script supendu')
		end
		if(uservariables['Tn'] == nil) then
         commandArray['OpenURL']=url..'/json.htm?type=command&param=saveuservariable&vname=Tn&vtype=2&vvalue=-150'
		 -- Création de la variable Tn si elle n'existe pas
            voir_les_logs("--- --- --- Création Variable Manquante Tn --- --- --- ",debugging)
        print('script supendu')
		end
max_min = string.match(otherdevices_svalues[temp_ext], "%d+%.*%d*")
t_max_min = tonumber(max_min)
	voir_les_logs("--- --- --- Température Ext : "..t_max_min,debugging)
	if (t_max_min < tonumber(uservariables['Tn'])) then
		voir_les_logs("--- --- --- Température Extérieure inférieure à Variable Tn : "..uservariables['Tn'],debugging)
		commandArray['Variable:Tn'] = tostring(t_max_min) -- mise à jour de la variable tn
		voir_les_logs("--- --- --- mise à jour de la Variable Tn  --- --- --- ",debugging)
	elseif (t_max_min > tonumber(uservariables['Tx'])) then
		voir_les_logs("--- --- --- Température Extérieure supérieure à Variable Tx : "..uservariables['Tx'],debugging)
		commandArray['Variable:Tx'] = tostring(t_max_min) -- mise à jour de la variable tx
		voir_les_logs("--- --- --- mise à jour de la Variable Tx  --- --- --- ",debugging)	
	end
end
return commandArray


