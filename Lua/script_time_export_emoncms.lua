--[[script_time_export_emoncms.lua
auteur : papoo

maj : 11/03/2018
date : 18/05/2016
Principe : 
exporter les données de compteurs, Températures, etc.. sur le site https://emoncms.org/
Le script est lu toutes les minutes mais n'exporte les données que toutes les 2 minutes
http://easydomoticz.com/forum/viewtopic.php?f=17&t=2017
http://pon.fr/exporter-des-donnees-vers-le-site-emoncms/
https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_export_emoncms.lua
]]--

--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging = true  	-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif = true   -- true pour activer l'execution du script ou false pour le désactiver
local url_emoncms = 'http://emoncms.org/api/' 
local api_emoncms = 'api_emoncms' -- créer une variable de type chaine contenant votre code API Write KEY emoncms de 32 caractères
local les_devices = {}; -- pas plus de 11 devices
-- si vous souhaitez remonter les valeurs d'un device qui en comporte plusieurs (ex: température et hygrometrie extérieure) 
--renseigner le nom de la valeur à remonter (à partir de la deuxieme valeur) ainsi que le numero d'ordre dans canal (voir exemples ci dessous les_devices[9] et les_devices[17] )
-- les_devices[#les_devices+1] = {device="Compteur Eau Froide", nom="", canal=""} -- 1er compteur 
-- les_devices[#les_devices+1] = {device="Compteur Eau Chaude", nom="", canal=""} -- 2eme compteur 
-- les_devices[#les_devices+1] = {device="Compteur Gaz", nom="", canal=""}-- 3eme compteur
-- les_devices[#les_devices+1] = {device="Compteur Prises", nom="", canal=""}
-- les_devices[#les_devices+1] = {device="Compteur Lumières", nom="", canal=""}
-- les_devices[#les_devices+1] = {device="Compteur Technique", nom="", canal=""}
-- les_devices[#les_devices+1] = {device="DJU", nom="", canal=""}
les_devices[#les_devices+1] = {device="Temperature exterieure", nom="", canal=""}
les_devices[#les_devices+1] = {device="Temperature exterieure", nom="Humidité", canal=2}
les_devices[#les_devices+1] = {device="Temperature Salon", nom="", canal=""}
les_devices[#les_devices+1] = {device="Point de givrage", nom="", canal=""}
les_devices[#les_devices+1] = {device="Point de rosée", nom="", canal=""}
--les_devices[#les_devices+1] = {device="Couloir 1er étage", nom="", canal=""}
les_devices[#les_devices+1] = {device="Congélateur", nom="", canal=""}
--les_devices[#les_devices+1] = {device="Temp départ chauffage", nom="", canal=""}
--les_devices[#les_devices+1] = {device="Temp retour chauffage", nom="", canal=""}
--les_devices[#les_devices+1] = {device="Temp Parents", nom="", canal=""}
--les_devices[#les_devices+1] = {device="anémometre", nom="direction", canal=2}
local fields =""
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = "export emoncms"
local version = "2.1"
--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------
-- package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"
-- require('fonctions_perso')

function voir_les_logs (s, debugging) -- nécessite la variable local debugging
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>")
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>")
		end
    end
end	-- usage voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
--============================================================================================== 
function url_encode(str) -- encode la chaine str pour la passer dans une url 
   if (str) then
   str = string.gsub (str, "\n", "\r\n")
   str = string.gsub (str, "([^%w ])",
   function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   end
   return str
end 
--============================================================================================== 
function sans_accent(str) -- supprime les accents de la chaîne str
    if (str) then
	str = string.gsub (str,"Ç", "C")
	str = string.gsub (str,"ç", "c")
    str = string.gsub (str,"[-èéêë']+", "e")
	str = string.gsub (str,"[-ÈÉÊË']+", "E")
    str = string.gsub (str,"[-àáâãäå']+", "a")
    str = string.gsub (str,"[-@ÀÁÂÃÄÅ']+", "A")
    str = string.gsub (str,"[-ìíîï']+", "i")
    str = string.gsub (str,"[-ÌÍÎÏ']+", "I")
    str = string.gsub (str,"[-ðòóôõö']+", "o")
    str = string.gsub (str,"[-ÒÓÔÕÖ']+", "O")
    str = string.gsub (str,"[-ùúûü']+", "u")
    str = string.gsub (str,"[-ÙÚÛÜ']+", "U")
    str = string.gsub (str,"[-ýÿ']+", "y")
    str = string.gsub (str,"Ý", "Y")
     end
    return (str)
end
--===========================================================================================
function split(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end -- usage : valeurs = split(variable,";")
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
			if v~= nil then v,nbCommas=string.gsub(v,";",";") end-- vérification de la présence d'un ou plusieurs point virgule => valeurs multiples
	   if nbCommas > 1 and c ~= nil then
			voir_les_logs("--- --- --- valeurs multiples dans ".. sans_accent(d.device) .." = ".. v,debugging)
			voir_les_logs("--- --- ---  Nb de point virgule = "..(nbCommas or "nil"),debugging) 
			local valeurs = split(v,";")
			voir_les_logs("--- --- ---  valeur 1 = "..(valeurs[1] or "nil"),debugging)
			voir_les_logs("--- --- ---  valeur 2 = "..(valeurs[2] or "nil"),debugging)
			voir_les_logs("--- --- ---  valeur 3 = "..(valeurs[3] or "nil"),debugging)
			voir_les_logs("--- --- ---  valeur 4 = "..(valeurs[4] or "nil"),debugging)
       fields = fields .. '{'.. sans_accent(d.nom) .. ':' .. valeurs[c] .. '},'
		elseif v ~= nil then
    fields = fields .. '{'.. sans_accent(d.device) .. ':' .. v .. '},'
		end
	end
		fields = string.gsub (fields, ",$", "") -- suppression de la dernière virgule
        fields = url_encode(fields) -- encodage de l'URL

		voir_les_logs("--- --- --- ".. url_emoncms ..'post?apikey=' .. API_key .. '&json=' .. fields ,debugging)
	--commandArray[1]={['OpenURL']=url_emoncms ..'post?apikey=' .. API_key .. '&json=' .. fields }
	os.execute('curl -m5 "'..url_emoncms ..'post?apikey=' .. API_key .. '&json=' .. fields .. '"')
    voir_les_logs('curl -m5 "'..url_emoncms ..'post?apikey=' .. API_key .. '&json=' .. fields ..'"',debugging)
		voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end -- if time
-- ============================================================================
return commandArray	
