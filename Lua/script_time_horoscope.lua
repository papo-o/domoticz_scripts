--[[
name : script_time_horoscope.lua
auteur : papoo
Mise à jour : 01/04/2017 Changement de site + troncage de texte
date : 26/06/2016
Principe :
 Ce script a pour but de remonter les informations du site https://astro.rtl.fr/horoscope-jour-gratuit/ dans un device texte 
 sur domoticz pour un signe donné et de nous alerter le cas écheant selon le niveau de notification choisi
 Fil de discussion : https://easydomoticz.com/forum/viewtopic.php?f=17&t=2176&p=34662#p34662
]]--
-- ========================================================================
-- Variables à éditer
-- ========================================================================
local nom_script = "Horoscope"
local version = "1.16"
local signe = "cancer" --[[ renseigner le signe choisi en minuscule sans accent : belier, taureau, gemeaux, cancer, lion, vierge, 
balance, scorpion, sagittaire, capricorne, verseau, poissons ]]--
local horoscope_device = 342	-- renseigner l'idx du device texte associé (dummy - text)
local horoscope_variable = nil	-- renseigner le nom de la variable associée ou nil
local send_notification = 0 -- 0: notifications désactivées, 1: notifications actives
local debugging = false  	-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
-- ========================================================================
-- Fin Variables à éditer
-- ========================================================================
	
-- ======================================================================== 
-- Fonctions
-- ========================================================================
function voir_les_logs (s)
    if (debugging) then 
        print ("<font color='#f3031d'>".. s .."</font>");
    end
end	
--============================================================================================== 
function TronquerTexte(texte, nb)  --texte à tronquer, nb limite de caractère à afficher
local sep ="[!?.]"
local DernierIndex = nil
texte = string.sub(texte, 1, nb)
local p = string.find(texte, sep, 1)
DernierIndex = p
while p do
    p = string.find(texte, sep, p + 1)
    if p then
        DernierIndex = p
    end
end
return(string.sub(texte, 1, DernierIndex))
end
-- ======================================================================== 
-- Fin Fonctions
-- ========================================================================

commandArray = {}
time = os.date("*t")

--if (time.hour == 00 and time.min == 20) then -- tout les matins à 00h20
 if (time.min == 20 and ((time.hour == 7) or (time.hour == 13) or (time.hour == 18))) then -- 3 éxecutions du script par jour à 7H20, 13h20 et 18H20
-- if time.hour % 2 == 0 then -- toutes les deux heures
-- if (time.hour%1 == 0 and time.min == 10)  then -- Toutes les heures et 10 minutes
-- if time.min% 1 == 0 then 

voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)

    local rid = assert(io.popen("/usr/bin/curl -m5 https://astro.rtl.fr/horoscope-jour-gratuit/".. signe))
    local testhtml = rid:read('*all')
            rid:close()

for instance in testhtml:gmatch("<body>(.-)</body>") do
			voir_les_logs('--- --- --- boucle for --- --- --',debugging);
div, horoscope=instance:match('<h2>En résumé</h2>(.-)<p class="text">(.-)</p>')
end	
horoscope = TronquerTexte(horoscope, 240)

	if horoscope ~= nil  and signe ~= nil then
	
		voir_les_logs("--- --- --- ".. signe .." : ".. horoscope,debugging)
			
		if horoscope_device ~= nil then
		commandArray[#commandArray+1] = {['UpdateDevice'] = horoscope_device..'|0|'.. horoscope}
		
		end
		if horoscope_variable ~= nil then	
		commandArray[#commandArray+1] = {['Variable:'.. horoscope_variable] = tostring(horoscope)}
		
		end	
		if send_notification > 0 then
		commandArray[#commandArray+1] = {['SendNotification'] = 'horoscope pour le signe du '.. signe ..'#'.. horoscope}
		
		end
		
	end
voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)	
end -- if time
return commandArray