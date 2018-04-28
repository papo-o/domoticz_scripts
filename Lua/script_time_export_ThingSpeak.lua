--[[
script_time_export_ThingSpeak.lua
auteur : papoo
MAJ: 28/04/2018
date : 18/05/2016
Principe : 
exporter les données de compteurs, Températures, etc.. sur le site thingspeak.com
limite de "field" par "channel" = 8 
Le script est lu toutes les minutes mais n'exporte les données que toutes les 4 minutes (temps modifiable ligne 40)
http://easydomoticz.com/forum/viewtopic.php?f=17&t=1925&p=25015
http://pon.fr/exporter-des-donnees-vers-le-site-thingspeak/
--]]

--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false  	-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local url_thingspeak = 'https://api.thingspeak.com/' 
local api_thingspeak = 'api_thingspeak' -- creer une variable de type chaine contenant votre code API Write KEY ThingSpeak

local les_devices = {}; -- pas plus de 8 devices
-- 1er compteur : name ="nom du device 1", field=field ThingSpeak associé
les_devices[#les_devices+1] = {name="Compteur Eau Froide", field=1}
-- 2eme compteur : name ="nom du device 2", field=field ThingSpeak associé
les_devices[#les_devices+1] = {name="Compteur Eau Chaude", field=2}
-- 3eme compteur : name ="nom du device 3", field=field ThingSpeak associé
les_devices[#les_devices+1] = {name="Compteur Gaz", field=3}
les_devices[#les_devices+1] = {name="Compteur Prises", field=4}
les_devices[#les_devices+1] = {name="Compteur Lumières", field=5}
les_devices[#les_devices+1] = {name="Compteur Technique", field=6}
les_devices[#les_devices+1] = {name="DJU", field=7}

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = "export ThingSpeak"
local version = "1.15"
local fields =""
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
-- if time.min % 4 == 0 then  -- export des données toutes les 4 minutes
if ((time.min-1) % 5) == 0 then
    voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
    local API_key = uservariables[api_thingspeak] 			
    voir_les_logs("--- --- --- Export vers ThingSpeak  : "..time.hour.. ":" ..time.min,debugging)
    for i,d in ipairs(les_devices) do
        v=otherdevices[d.name]                        -- v is the value attached to device d
        voir_les_logs(d.name.." = "..(v or "nil"),debugging);
        voir_les_logs("--- --- --- Heure actuelle : ".. time.hour .. ":" ..time.min,debugging)
        if v==nil or v=="" or v=="Open" then                  -- multi valued ?
            v=otherdevices_svalues[d.name] or ""
            voir_les_logs("--- --- --- ".. d.name .." = ".. v .." & field".. d.field ,debugging)
        end
        fields = fields .. '&field'.. d.field .. '=' .. v	
        voir_les_logs("--- --- --- " .. fields ,debugging)
    end
    voir_les_logs("--- --- --- ".. url_thingspeak ..'update?key=' .. API_key .. fields ,debugging)
    --commandArray[1]={['OpenURL']=url_thingspeak ..'update?key=' .. API_key .. fields }
    os.execute('curl -m5 "'.. url_thingspeak ..'update?key=' .. API_key .. fields)
    voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end -- if time
--------------------------------------------====
return commandArray	
