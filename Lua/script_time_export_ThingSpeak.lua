	--[[script_time_export_ThingSpeak.lua
auteur : papoo
MAJ: 28/05/2018
date : 18/05/2016
Principe : 
exporter les données de compteurs, Températures, etc.. sur le site thingspeak.com
limite de "field" par "channel" = 8 
Le script est lu toutes les minutes mais n'exporte les données que toutes les 4 minutes (temps modifiable ligne 40)
http://easydomoticz.com/forum/viewtopic.php?f=17&t=1925&p=25015
http://pon.fr/exporter-des-donnees-vers-le-site-thingspeak/
]]--

--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = true  	-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local url_thingspeak = 'https://api.thingspeak.com/' 
local api_thingspeak = 'api_thingspeak' -- creer une variable de type chaine contenant votre code API Write KEY ThingSpeak
-- si vous souhaitez remonter les valeurs d'un device qui en comporte plusieurs (ex: température et hygrometrie extérieure) 
-- renseigner le nom de la valeur à remonter (à partir de la deuxieme valeur) ainsi que le numero d'ordre dans canal (voir exemple ci dessous field 7 )
local les_devices = {}; -- pas plus de 8 devices
-- 1er compteur : device ="nom du device 1", field=field ThingSpeak associé, nom=nom du device si canal >1, canal=si valeur multiple n° du canal à utiliser
les_devices[#les_devices+1] = {device="Compteur Eau Froide", field=1, nom="", canal=""}
-- 2eme compteur : device ="nom du device 2", field=field ThingSpeak associé
les_devices[#les_devices+1] = {device="Compteur Eau Chaude", field=2, nom="", canal=""}
-- 3eme compteur : device ="nom du device 3", field=field ThingSpeak associé
les_devices[#les_devices+1] = {device="Compteur Gaz", field=3, nom="", canal=""}
les_devices[#les_devices+1] = {device="Compteur Prises", field=4, nom="", canal=""}
les_devices[#les_devices+1] = {device="Compteur Lumières", field=5, nom="", canal=""}
les_devices[#les_devices+1] = {device="Compteur Technique", field=6, nom="", canal=""}
les_devices[#les_devices+1] = {device="Temperature exterieure", field=7, nom="Humidité extérieure", canal="2"}

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = "export ThingSpeak"
local version = "1.2"
local fields =""
--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------
function voir_les_logs (s, debugging) -- nécessite la variable local debugging
    if (debugging) then 
		if s ~= nil then
        print (s)
		else
		print ("aucune valeur affichable")
		end
    end
end	-- usage voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
--------------------------------------------
function url_encode(str) -- encode la chaine str pour la passer dans une url 
   if (str) then
   str = string.gsub (str, "\n", "\r\n")
   str = string.gsub (str, "([^%w ])",
   function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   end
   return str
end 
------------------------------------------
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
--------------------------------------------
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

if ((time.min-1) % 1) == 0 then-- export des données toutes les 5 minutes en commençant par xx:01
			voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
local API_key = uservariables[api_thingspeak] 			
			voir_les_logs("--- --- --- Export vers ThingSpeak  : "..time.hour.. ":" ..time.min,debugging)

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
		 voir_les_logs("--- --- --- ".. url_thingspeak ..'update?key=' .. API_key .. fields ,debugging)
	os.execute('curl -m5 "'.. url_thingspeak ..'update?key=' .. API_key .. fields)
		 voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end -- if time
-- ============================================================================
return commandArray	
