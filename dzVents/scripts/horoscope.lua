
--[[
name : script_time_horoscope.lua
auteur : papoo
Mise à jour : 30/03/2020
Création : 26/06/2016 =>V1.x https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_horoscope.lua
https://pon.fr/dzvents-horoscope-v2
https://easydomoticz.com/forum/
github : https://github.com/papo-o/domoticz_scripts/horoscope.lua
Principe :
 Ce script a pour but de remonter les informations du site https://astro.rtl.fr/horoscope-jour-gratuit/ dans un device texte
 sur domoticz pour un signe donné et de nous alerter le cas échéant selon le niveau de notification choisi
 Fil de discussion : https://easydomoticz.com/forum/viewtopic.php?f=17&t=2176&p=34662#p34662
 https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_horoscope.lua
]]--
local les_horoscopes = {
            { device = 'Horoscope 1',  signe = 'belier'},
            { device = 'Horoscope 2',    signe = 'capricorne'},
            { device = 'Horoscope 3',  signe = 'vierge'},
            { device = 'Horoscope 4',    signe = 'balance'},
                        }

local site_url  = 'https://astro.rtl.fr/horoscope-jour-gratuit'  -- url
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local scriptName        = 'Horoscope'
local scriptVersion     = '2.0'

return {
    active = true,
    on  =   {
        timer           =   { 'every 6 hours' },--https://www.domoticz.com/wiki/DzVents:_next_generation_LUA_scripting#timer_trigger_rules
        httpResponses   =   { 'belier','taureau','gemeaux','cancer','lion','vierge','balance','scorpion','sagittaire','capricorne','verseau','poissons' }    -- Trigger
        --httpResponses   =   { 'cancer','capricorne' }    -- Trigger
    },
    logging =   {
        level    =   domoticz.LOG_DEBUG,                -- Seulement un niveau peut être actif; commenter les autres
        -- level    =   domoticz.LOG_INFO,              -- Only one level can be active; comment others
        -- level    =   domoticz.LOG_ERROR,
        -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
     marker = scriptName..' v'..scriptVersion },
    execute = function(dz, item)

        local function logWrite(str,level)              -- Support function for shorthand debug log statements
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end
--------------------------------------------
        local function TronquerTexte(texte, nb)  -- texte à tronquer, Nb maximum de caractère
        local sep ="[?;!.]"
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
function unescape(str)--remplace le code html
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

--------------------------------------------
        if (item.isTimer) then
            for index,record in pairs(les_horoscopes) do-- On parcourt chaque horoscope
                device = record.device
                if device ~= nil and device ~= '' and dz.devices(device).name ~= nil then
                    logWrite('--- --- --- traitement '..device..'  --- --- --')
                    signe = record.signe
                    dz.openURL({--https://www.domoticz.com/wiki/DzVents:_next_generation_LUA_scripting#httpResponses
                        url = site_url..'/'..signe,
                        callback = signe
                    })
                end
            end --for
        end

        if (item.isHTTPResponse and item.ok) then
                    logWrite('--- --- --- traitement   --- --- --')
            for index,record in pairs(les_horoscopes) do-- On parcourt chaque horoscope
                device = record.device
                if dz.utils.deviceExists(record.device) then
                    logWrite('--- --- --- traitement '..device..'  --- --- --')
                    signe = record.signe
                    if item.trigger == signe then
                        logWrite('--- --- --- traitement signe '..item.trigger..'  --- --- --')
                        for instance in item.data:gmatch("<body>(.-)</body>") do
                            div, horoscope=instance:match('<h2>En résumé</h2>(.-)<p class="text">(.-)</p>')
                        end
                        horoscope = TronquerTexte(unescape(horoscope), 240)
                        logWrite(horoscope)
                        dz.devices(record.device).updateText(horoscope or 'Pas d\'horoscope aujourd\'hui') 
                    end
                end
            end --for
        end

     end
    }
