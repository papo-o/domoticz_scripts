--[[
name : script_time_horoscope.lua
auteur : papoo
Mise à jour : 17/04/2018
date : 26/06/2016
Principe :
 Ce script a pour but de remonter les informations du site https://astro.rtl.fr/horoscope-jour-gratuit/ dans un device texte 
 sur domoticz pour un signe donné et de nous alerter le cas échéant selon le niveau de notification choisi
 Fil de discussion : https://easydomoticz.com/forum/viewtopic.php?f=17&t=2176&p=34662#p34662
]]--
-- ========================================================================
-- Variables à éditer
-- ========================================================================
local debugging = true  	                -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif = true                   -- active (true) ou désactive (false) ce script simplement
local send_notification = 0                 -- 0: notifications désactivées, 1: notifications actives
local les_horoscopes = {}                   --[[ renseigner le signe choisi en minuscule sans accent : belier, taureau, gemeaux, cancer, lion, vierge, 
                                                 balance, scorpion, sagittaire, capricorne, verseau, poissons ]]--
les_horoscopes[#les_horoscopes+1] = {device = 'Horoscope Cancer', signe = 'cancer'}
les_horoscopes[#les_horoscopes+1] = {device = 'Horoscope Capricorne', signe = 'capricorne'}
-- ========================================================================
-- Fin Variables à éditer
-- ========================================================================
local nom_script = 'Horoscope'
local version = '1.20'
local device = ''
local signe = ''
-- ======================================================================== 
-- Fonctions
-- ========================================================================
function voir_les_logs (s)
    if (debugging) then 
        print ("<font color='#f3031d'>".. s .."</font>")
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
if script_actif == true then
    --if (time.hour == 00 and time.min == 20) then -- tout les matins à 00h20
    if (time.min == 20 and ((time.hour == 7) or (time.hour == 13) or (time.hour == 18))) then -- 3 exécutions du script par jour à 7H20, 13h20 et 18H20
    -- if time.hour % 2 == 0 then -- toutes les deux heures
    -- if (time.hour%1 == 0 and time.min == 10)  then -- Toutes les heures et 10 minutes
    -- if time.min% 2 == 0 then 

        voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
        for k,v in pairs(les_horoscopes) do-- On parcourt chaque horoscope
            device = v.device
            voir_les_logs('--- --- --- traitement de '..device..'  --- --- --',debugging)
            signe = v.signe
            voir_les_logs('--- --- --- signe astrologique : '..signe..'  --- --- --',debugging)            
        local rid = assert(io.popen("/usr/bin/curl -m5 https://astro.rtl.fr/horoscope-jour-gratuit/".. signe))
        local testhtml = rid:read('*all')
                rid:close()

            
            for instance in testhtml:gmatch("<body>(.-)</body>") do
                div, horoscope=instance:match('<h2>En résumé</h2>(.-)<p class="text">(.-)</p>')
            end	
            horoscope = TronquerTexte(horoscope, 240)
            
            if horoscope ~= nil  and signe ~= nil and device ~= nil then
                voir_les_logs("--- --- --- ".. signe .." : ".. horoscope,debugging)
                if device ~= nil then
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