--[[
name : script_time_horoscope.lua
auteur : papoo
Mise à jour : 10/05/2018
date : 26/06/2016
Principe :
 Ce script a pour but de remonter les informations du site https://astro.rtl.fr/horoscope-jour-gratuit/ dans un device texte 
 sur domoticz pour un signe donné et de nous alerter le cas échéant selon le niveau de notification choisi
 Fil de discussion : https://easydomoticz.com/forum/viewtopic.php?f=17&t=2176&p=34662#p34662
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging = false  	                -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif = true                   -- active (true) ou désactive (false) ce script simplement
local send_notification = 0                 -- 0: notifications désactivées, 1: notifications actives
local les_horoscopes = {}                   --[[ renseigner le signe choisi en minuscule sans accent : belier, taureau, gemeaux, cancer, lion, vierge, 
                                                 balance, scorpion, sagittaire, capricorne, verseau, poissons ]]--
les_horoscopes[#les_horoscopes+1] = {device = 'Horoscope 1', signe = 'belier'}
les_horoscopes[#les_horoscopes+1] = {device = 'Horoscope 2', signe = 'verseau'}
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = 'Horoscope'
local version = '1.24'
local horoscope = ''
local device = ''
local signe = ''
--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"   
require('fonctions_perso')                                                      
--https://github.com/papo-o/domoticz_scripts/blob/master/Lua/fonctions/fonctions_perso.lua

--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------

commandArray = {}
time = os.date("*t")
if script_actif == true then
    --if (time.hour == 00 and time.min == 20) then -- tout les matins à 00h20
     if (time.min == 20 and ((time.hour == 7) or (time.hour == 13) or (time.hour == 18))) then -- 3 exécutions du script par jour à 7H20, 13h20 et 18H20
    -- if time.hour % 2 == 0 then -- toutes les deux heures
    -- if (time.hour%1 == 0 and time.min == 10)  then -- Toutes les heures et 10 minutes
    -- if time.min% 2 == 0 then 

        voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
        for k,v in pairs(les_horoscopes) do-- On parcourt chaque horoscope
            device = v.device
            if device ~= nil and device ~= '' then voir_les_logs('--- --- --- traitement '..device..'  --- --- --',debugging) end
            signe = v.signe
            if signe ~= '' then voir_les_logs('--- --- --- signe astrologique : '..signe..'  --- --- --',debugging) end            
            local rid = assert(io.popen("/usr/bin/curl -m5 https://astro.rtl.fr/horoscope-jour-gratuit/".. signe))
            local testhtml = rid:read('*all')
            rid:close()
            for instance in testhtml:gmatch("<body>(.-)</body>") do
                div, horoscope=instance:match('<h2>En résumé</h2>(.-)<p class="text">(.-)</p>')
            end	
            horoscope = TronquerTexte(unescape(horoscope), 240)
            if horoscope ~= nil  and signe ~= nil then
                voir_les_logs("--- --- --- ".. signe .." : ".. horoscope,debugging)
                if device ~= nil and device ~= '' then
                    commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[device]..'|0|'.. horoscope}
                end
                if send_notification > 0 then
                    commandArray[#commandArray+1] = {['SendNotification'] = 'horoscope pour le signe du '.. signe ..'#'.. horoscope}
                end
            end
            voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
        end    
    end -- if time
end
return commandArray
