--[[ 
script_device_CMD2boutons.lua
auteur : papoo

MAJ : 28/04/2018
Création : 31/07/2016
Principe :
 ce script permet de simuler un troisième bouton "STOP" sur une télécommande 2 boutons,
 si un deuxième appui sur le même bouton est effectué en moins d'une minute.
 Associé à un boitier VRT pour la commande de deux volets roulants, ce script permettra l'arrêt du volet concerné
 ]]--

--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging = true  -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir 
local ip = '127.0.0.1:8080'   -- user:pass@ip:port de domoticz
local vrt = '192.168.1.127' -- Adresse IP du VRT
local tempo = 30
local switchs={} ;   
	switchs[0] = {nom="Volet Douche", canal="1"}
	switchs[1] = {nom="Chambre 1", canal="2"}
	-- switchs[3]=''

     
--------------------------------------------
----------- Fin variables à éditer ---------
-------------------------------------------- 
local nom_script = 'Simuler un bouton STOP'
local version = '1.13'	
time = os.date("*t")  
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
--------------------------------------------
function timedifference(s)
   year = string.sub(s, 1, 4)
   month = string.sub(s, 6, 7)
   day = string.sub(s, 9, 10)
   hour = string.sub(s, 12, 13)
   minutes = string.sub(s, 15, 16)
   seconds = string.sub(s, 18, 19)
   t1 = os.time()
   t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
   difference = os.difftime (t1, t2)
   return difference
end

function url_encode(str)
   if (str) then
   str = string.gsub (str, "\n", "\r\n")
   str = string.gsub (str, "([^%w ])",
   function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   end
   return str
end 
--]]
--------------------------------------------
-------------- Fin Fonctions ---------------
-------------------------------------------- 
commandArray = {}

    voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
   for key, valeur in pairs(switchs) do
		--if(uservariables['CMD_'.. valeur.nom ..'_'.. otherdevices[valeur.nom]] == nil) then
        --  commandArray[#commandArray+1]={['OpenURL']=ip..'/json.htm?type=command&param=saveuservariable&vname=CMD_'..url_encode(valeur.nom)..'_'.. otherdevices[valeur.nom] ..'&vtype=2&vvalue='..url_encode(otherdevices_lastupdate[valeur.nom])
		--	voir_les_logs("--- --- --- creation variable manquante CMD_"..valeur.nom.."_".. otherdevices[valeur.nom] .."  --- --- --- ",debugging)
        --elseif (devicechanged[valeur.nom] and timedifference(uservariables['CMD_'..valeur.nom..'_'..otherdevices[valeur.nom]]) < 60) then
		if (devicechanged[valeur.nom] and timedifference(uservariables['CMD_'..valeur.nom..'_'..otherdevices[valeur.nom]]) < tempo) then
		   commandArray[#commandArray+1]={['OpenURL']= vrt.."/ctrl.cgi?vr"..valeur.canal.."=2"}
           voir_les_logs("--- --- --- Deuxieme appui sur la telecommande ".. valeur.nom ..",  arret du volet --- --- --- ",debugging)		
        elseif(devicechanged[valeur.nom] and uservariables['CMD_'.. valeur.nom..'_'.. otherdevices[valeur.nom]] ~= nil ) then
			commandArray[#commandArray+1] = {['Variable:CMD_'.. valeur.nom..'_'..otherdevices[valeur.nom]] = tostring(otherdevices_lastupdate[valeur.nom])}	
			voir_les_logs("--- --- --- mise a jour variable CMD_".. valeur.nom .."_"..otherdevices[valeur.nom].."  --- --- --- ",debugging)	
        end
    end
    voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)


return commandArray 
