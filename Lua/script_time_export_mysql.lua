--[[script_time_export_mysql.lua
auteur : papoo

maj : 31/12/2017
date : 01/01/2017
Principe : 
exporter les données de compteurs, Températures, etc.. sur une base de données de type MySql
Le script est lu toutes les minutes mais n'exporte les données que toutes les 15 minutes
http://easydomoticz.com/forum/viewtopic.php?f=17&t=5368 
et
http://easydomoticz.com/forum/viewtopic.php?f=17&t=5369
http://pon.fr/exporter-des-donnees-vers-mysql/
https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_export_mysql.lua
]]--

--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local nom_script = "export mysql"
local version = "0.11"
local debugging = false  	-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local url = "http://192.168.1.25/mesgraphs/loggermulti.php"

local les_devices = {}; 
-- si vous souhaitez remonter les valeurs d'un device qui en comporte plusieurs (ex: température et hygrométrie extérieure) 
-- renseigner le nom de la valeur à remonter (à partir de la deuxième valeur) ainsi que le numéro d'ordre dans canal (voir exemples ci dessous Puissance Lave Linge et Puissance Sèche Linge )
les_devices[#les_devices+1] = {device="Compteur Eau Chaude", nom="Cpt Eau Chaude", canal="1"}
les_devices[#les_devices+1] = {device="Compteur Eau Froide", nom="Cpt Eau Froide", canal="1"}
les_devices[#les_devices+1] = {device="Compteur Gaz", nom="Cpt Gaz", canal="1"}
les_devices[#les_devices+1] = {device="Compteur Lumières", nom="Cpt lumieres", canal=""}
les_devices[#les_devices+1] = {device="Compteur Prises", nom="Cpt prises", canal=""}
les_devices[#les_devices+1] = {device="Compteur Technique", nom="Cpt technique", canal=""}
les_devices[#les_devices+1] = {device="EDF", nom="edf", canal="2"}
les_devices[#les_devices+1] = {device="Frigo (Consommation)", nom="Frigo", canal="1"}
les_devices[#les_devices+1] = {device="Lave Linge (Consommation)", nom="Lave Linge", canal="1"}
les_devices[#les_devices+1] = {device="Frigo (Consommation)", nom="Puissance Frigo", canal="2"}
les_devices[#les_devices+1] = {device="Lave Linge (Consommation)", nom="Puissance Lave Linge", canal="2"}
les_devices[#les_devices+1] = {device="Sèche Linge (Consommation)", nom="Puissance Sèche Linge", canal="2"}
les_devices[#les_devices+1] = {device="EDF", nom="Puissance Totale", canal="1"}
les_devices[#les_devices+1] = {device="Sèche Linge (Consommation)", nom="Sèche Linge", canal="1"}
les_devices[#les_devices+1] = {device="Temperature Bureau", nom="temp bureau", canal="1"}
les_devices[#les_devices+1] = {device="Temperature Cuisine", nom="temp cuisine", canal="1"}
les_devices[#les_devices+1] = {device="Temperature départ chauffage", nom="temp départ chauffage", canal="1"}
les_devices[#les_devices+1] = {device="Temperature Entree", nom="temp entree", canal="1"}
les_devices[#les_devices+1] = {device="Temperature retour chauffage", nom="temp retour chauffage", canal="1"}
les_devices[#les_devices+1] = {device="Temperature Salon", nom="temp salon", canal="1"}
les_devices[#les_devices+1] = {device="DJU", nom="DJU Météo France", canal="1"}
les_devices[#les_devices+1] = {device="DJU 2", nom="DJU Intégrales", canal="1"}
les_devices[#les_devices+1] = {device="Energie consommée chauffage", nom="Energie", canal="1"}
local feeds =""
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------

--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------

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
--============================================================================================== 
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------

commandArray = {}
time=os.date("*t")
--if ((time.min-1) % 2) == 0 then  -- export des données toutes les 2 minutes
if ((time.min-1) % 15) == 0 then  -- export des données toutes les 15 minutes
voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)


    for i,d in ipairs(les_devices) do
        v=otherdevices[d.device]
	c=tonumber(d.canal)
			voir_les_logs("--- --- --- ".. sans_accent(d.device) .." = "..(v or "nil"),debugging)
            print(sans_accent(d.device))
			voir_les_logs("--- --- --- canal = "..(c or "nil"),debugging)
			if v~= nil then v,nbCommas=string.gsub(v,";",";") end-- verification de la presence d'un ou plusieurs point virgule => valeurs multiples
	   if nbCommas >= 1 and c ~= nil then
			voir_les_logs("--- --- --- valeurs multiples dans ".. sans_accent(d.device) .." = ".. v,debugging)
			voir_les_logs("--- --- ---  Nb de point virgule = "..(nbCommas or "nil"),debugging) 
			local valeurs = split(v,";")
			voir_les_logs("--- --- ---  valeur 1 = "..(valeurs[1] or "nil"),debugging)
			voir_les_logs("--- --- ---  valeur 2 = "..(valeurs[2] or "nil"),debugging)
			voir_les_logs("--- --- ---  valeur 3 = "..(valeurs[3] or "nil"),debugging)
			voir_les_logs("--- --- ---  valeur 4 = "..(valeurs[4] or "nil"),debugging)
			
		feeds = feeds .. '&f'.. i .. '=' .. url_encode(d.nom) .. '&v' .. i .. '=' .. valeurs[c]
		elseif d.nom ~= nil then
		feeds = feeds .. '&f'.. i.. '=' .. url_encode(d.nom) .. '&v' .. i .. '=' .. v
        else
        feeds = feeds .. '&f'.. i.. '=' .. url_encode(d.device) .. '&v' .. i .. '=' .. v
		end
    I = i    
	end

        feeds = string.gsub (feeds, ".000", "") 
  
    url = url .. "?feeds=" .. I
    voir_les_logs("--- --- ---Envoi valeurs dans la base de données",debugging)
    voir_les_logs("curl -m5 " .. "'".. url .. feeds .."'",debugging)
    voir_les_logs("--- --- ---i a une valeur de : "..I,debugging)
os.execute("curl -m5 " .. "'".. url .. feeds .."'")

voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end -- if time
-- ============================================================================
return commandArray	