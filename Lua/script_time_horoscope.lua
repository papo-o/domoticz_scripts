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
local version = '1.23'
local horoscope = ''
local device = ''
local signe = ''
--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"   -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script
require('fonctions_perso')                                                      -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script

-- ci-dessous les lignes à décommenter en cas d'utilisation des fonctions directement dans ce script( supprimer --[[ et --]])
--[[
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
function TronquerTexte(texte, nb)  --texte à tronquer, nb limite de caractère à afficher
    local sep ="[;!?.]"
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
--------------------------------------------
function unescape(str)--remplace le code html par le caractère accentué 
    if (str) then    
    str = string.gsub( str, '&nbsp;', ' ')
    str = string.gsub( str, '&iexcl;', '¡')
    str = string.gsub( str, '&cent;', '¢')
    str = string.gsub( str, '&pound;', '£')
    str = string.gsub( str, '&curren;', '¤')
    str = string.gsub( str, '&yen;', '¥')
    str = string.gsub( str, '&brvbar;', '¦')
    str = string.gsub( str, '&sect;', '§')
    str = string.gsub( str, '&uml;', '¨')
    str = string.gsub( str, '&copy;', '©')
    str = string.gsub( str, '&ordf;', 'ª')
    str = string.gsub( str, '&laquo;', '«')
    str = string.gsub( str, '&not;', '¬')
    str = string.gsub( str, '&shy;', '­')
    str = string.gsub( str, '&reg;', '®')
    str = string.gsub( str, '&macr;', '¯')
    str = string.gsub( str, '&deg;', '°')
    str = string.gsub( str, '&plusmn;', '±')
    str = string.gsub( str, '&sup2;', '²')
    str = string.gsub( str, '&sup3;', '³')
    str = string.gsub( str, '&acute;', '´')
    str = string.gsub( str, '&micro;', 'µ')
    str = string.gsub( str, '&para;', '¶')
    str = string.gsub( str, '&middot;', '·')
    str = string.gsub( str, '&cedil;', '¸')
    str = string.gsub( str, '&sup1;', '¹')
    str = string.gsub( str, '&ordm;', 'º')
    str = string.gsub( str, '&raquo;', '»')
    str = string.gsub( str, '&frac14;', '¼')
    str = string.gsub( str, '&frac12;', '½')
    str = string.gsub( str, '&frac34;', '¾')
    str = string.gsub( str, '&iquest;', '¿')
    str = string.gsub( str, '&Agrave;', 'À')
    str = string.gsub( str, '&Aacute;', 'Á')
    str = string.gsub( str, '&Acirc;', 'Â')
    str = string.gsub( str, '&Atilde;', 'Ã')
    str = string.gsub( str, '&Auml;', 'Ä')
    str = string.gsub( str, '&Aring;', 'Å')
    str = string.gsub( str, '&AElig;', 'Æ')
    str = string.gsub( str, '&Ccedil;', 'Ç')
    str = string.gsub( str, '&Egrave;', 'È')
    str = string.gsub( str, '&Eacute;', 'É')
    str = string.gsub( str, '&Ecirc;', 'Ê')
    str = string.gsub( str, '&Euml;', 'Ë')
    str = string.gsub( str, '&Igrave;', 'Ì')
    str = string.gsub( str, '&Iacute;', 'Í')
    str = string.gsub( str, '&Icirc;', 'Î')
    str = string.gsub( str, '&Iuml;', 'Ï')
    str = string.gsub( str, '&ETH;', 'Ð')
    str = string.gsub( str, '&Ntilde;', 'Ñ')
    str = string.gsub( str, '&Ograve;', 'Ò')
    str = string.gsub( str, '&Oacute;', 'Ó')
    str = string.gsub( str, '&Ocirc;', 'Ô')
    str = string.gsub( str, '&Otilde;', 'Õ')
    str = string.gsub( str, '&Ouml;', 'Ö')
    str = string.gsub( str, '&times;', '×')
    str = string.gsub( str, '&Oslash;', 'Ø')
    str = string.gsub( str, '&Ugrave;', 'Ù')
    str = string.gsub( str, '&Uacute;', 'Ú')
    str = string.gsub( str, '&Ucirc;', 'Û')
    str = string.gsub( str, '&Uuml;', 'Ü')
    str = string.gsub( str, '&Yacute;', 'Ý')
    str = string.gsub( str, '&THORN;', 'Þ')
    str = string.gsub( str, '&szlig;', 'ß')
    str = string.gsub( str, '&agrave;', 'à')
    str = string.gsub( str, '&aacute;', 'á')
    str = string.gsub( str, '&acirc;', 'â')
    str = string.gsub( str, '&atilde;', 'ã')
    str = string.gsub( str, '&auml;', 'ä')
    str = string.gsub( str, '&aring;', 'å')
    str = string.gsub( str, '&aelig;', 'æ')
    str = string.gsub( str, '&ccedil;', 'ç')
    str = string.gsub( str, '&egrave;', 'è')
    str = string.gsub( str, '&eacute;', 'é')
    str = string.gsub( str, '&ecirc;', 'ê')
    str = string.gsub( str, '&euml;', 'ë')
    str = string.gsub( str, '&igrave;', 'ì')
    str = string.gsub( str, '&iacute;', 'í')
    str = string.gsub( str, '&icirc;', 'î')
    str = string.gsub( str, '&iuml;', 'ï')
    str = string.gsub( str, '&eth;', 'ð')
    str = string.gsub( str, '&ntilde;', 'ñ')
    str = string.gsub( str, '&ograve;', 'ò')
    str = string.gsub( str, '&oacute;', 'ó')
    str = string.gsub( str, '&ocirc;', 'ô')
    str = string.gsub( str, '&otilde;', 'õ')
    str = string.gsub( str, '&ouml;', 'ö')
    str = string.gsub( str, '&divide;', '÷')
    str = string.gsub( str, '&oslash;', 'ø')
    str = string.gsub( str, '&ugrave;', 'ù')
    str = string.gsub( str, '&uacute;', 'ú')
    str = string.gsub( str, '&ucirc;', 'û')
    str = string.gsub( str, '&uuml;', 'ü')
    str = string.gsub( str, '&yacute;', 'ý')
    str = string.gsub( str, '&thorn;', 'þ')
    str = string.gsub( str, '&yuml;', 'ÿ')
    str = string.gsub( str, '&euro;', '€')
    str = string.gsub( str, '&#(%d+);', function(n) return string.char(n) end )
    str = string.gsub( str, '&#x(%d+);', function(n) return string.char(tonumber(n,16)) end )
    str = string.gsub( str, '&amp;', '&' ) -- Be sure to do this after all others
     end
    return (str)
end

--]]
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