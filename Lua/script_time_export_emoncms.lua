--[[script_time_export_emoncms.lua
auteur : papoo

maj : 26/11/2017
date : 18/05/2016
Principe : 
exporter les données de compteurs, Températures, etc.. sur le site https://emoncms.org/
Le script est lu toutes les minutes mais n'exporte les données que toutes les 2 minutes
http://easydomoticz.com/forum/viewtopic.php?f=17&t=2017
http://pon.fr/exporter-des-donnees-vers-le-site-emoncms/
]]--

--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local nom_script = "export emoncms"
local version = "2.03"
local script_actif = true   -- true pour activer l'execution du script ou false pour le désactiver
local debugging = false  	-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local url_emoncms = 'http://emoncms.org/api/' 
local api_emoncms = 'api_emoncms' -- créer une variable de type chaine contenant votre code API Write KEY emoncms de 32 caractères

local les_devices = {}; -- pas plus de 11 devices
-- si vous souhaitez remonter les valeurs d'un device qui en comporte plusieurs (ex: température et hygrometrie extérieure) 
--renseigner le nom de la valeur à remonter (à partir de la deuxieme valeur) ainsi que le numero d'ordre dans canal (voir exemples ci dessous les_devices[9] et les_devices[17] )
les_devices[#les_devices+1] = {device="Compteur Eau Froide", nom="", canal=""} -- 1er compteur 
les_devices[#les_devices+1] = {device="Compteur Eau Chaude", nom="", canal=""} -- 2eme compteur 
les_devices[#les_devices+1] = {device="Compteur Gaz", nom="", canal=""}-- 3eme compteur
les_devices[#les_devices+1] = {device="Compteur Prises", nom="", canal=""}
les_devices[#les_devices+1] = {device="Compteur Lumières", nom="", canal=""}
les_devices[#les_devices+1] = {device="Compteur Technique", nom="", canal=""}
les_devices[#les_devices+1] = {device="DJU", nom="", canal=""}
les_devices[#les_devices+1] = {device="Temperature exterieure", nom="", canal=""}
les_devices[#les_devices+1] = {device="Temperature exterieure", nom="Humidité", canal=2}
les_devices[#les_devices+1] = {device="Temperature Salon", nom="", canal=""}
les_devices[#les_devices+1] = {device="Point de givrage", nom="", canal=""}
les_devices[#les_devices+1] = {device="Point de rosée", nom="", canal=""}
les_devices[#les_devices+1] = {device="Couloir 1er étage", nom="", canal=""}
--les_devices[#les_devices+1] = {device="Temp départ chauffage", nom="", canal=""}
--les_devices[#les_devices+1] = {device="Temp retour chauffage", nom="", canal=""}
--les_devices[#les_devices+1] = {device="Temp Parents", nom="", canal=""}
--les_devices[#les_devices+1] = {device="anémometre", nom="direction", canal=2}
local fields =""
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------

--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"
require('fonctions_perso')
 
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------

commandArray = {}
time=os.date("*t")
if ((time.min-1) % 2) == 0 and script_actif == true then  -- export des données toutes les 2 minutes
voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
voir_les_logs("--- --- --- Export vers emoncms  : "..time.hour.. ":" ..time.min,debugging)
local API_key = uservariables[api_emoncms] 
    for i,d in ipairs(les_devices) do
    v=otherdevices[d.device]
	c=tonumber(d.canal)
			voir_les_logs("--- --- --- ".. sans_accent(d.device) .." = "..(v or "nil"),debugging)
			voir_les_logs("--- --- --- canal = "..(c or "nil"),debugging)
			if v~= nil then v,nbCommas=string.gsub(v,";",";") end-- verification de la presence d'un ou plusieurs point virgule => valeurs multiples
	   if nbCommas > 1 and c ~= nil then
			voir_les_logs("--- --- --- valeurs multiples dans ".. sans_accent(d.device) .." = ".. v,debugging)
			voir_les_logs("--- --- ---  Nb de point virgule = "..(nbCommas or "nil"),debugging) 
			local valeurs = split(v,";")
			voir_les_logs("--- --- ---  valeur 1 = "..(valeurs[1] or "nil"),debugging)
			voir_les_logs("--- --- ---  valeur 2 = "..(valeurs[2] or "nil"),debugging)
			voir_les_logs("--- --- ---  valeur 3 = "..(valeurs[3] or "nil"),debugging)
			voir_les_logs("--- --- ---  valeur 4 = "..(valeurs[4] or "nil"),debugging)
			fields = fields .. '{'.. d.nom .. ':' .. valeurs[c] .. '},'
		elseif v ~= nil then
            fields = fields .. '{'.. d.device .. ':' .. v .. '},'
		end
	end
		fields = string.gsub (fields, ",$", "") -- suppression de la derniere virgule
		fields = url_encode(sans_accent(fields)) -- suppression des caractères accentués
		voir_les_logs("--- --- --- ".. url_emoncms ..'post?apikey=' .. API_key .. '&json=' .. fields ,debugging)
	--commandArray[1]={['OpenURL']=url_emoncms ..'post?apikey=' .. API_key .. '&json=' .. fields }
	os.execute('curl -m5 "'..url_emoncms ..'post?apikey=' .. API_key .. '&json=' .. fields)
		voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end -- if time
-- ============================================================================
return commandArray	