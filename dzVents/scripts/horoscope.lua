
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
local scriptVersion     = '2.01'

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
        local ascii =  {
        ['&nbsp;'] =' ', ['&iexcl;'] ='¡', ['&cent;'] ='¢', ['&pound;'] ='£', ['&curren;'] ='¤', ['&yen;'] ='¥', ['&brvbar;'] ='¦', ['&sect;'] ='§', ['&uml;'] ='¨', ['&copy;'] ='©', ['&ordf;'] ='ª', ['&laquo;'] ='«', ['&not;'] ='¬', ['&shy;'] ='­',
        ['&reg;'] ='®', ['&macr;'] ='¯', ['&deg;'] ='°', ['&plusmn;'] ='±', ['&sup2;'] ='²', ['&sup3;'] ='³', ['&acute;'] ='´', ['&micro;'] ='µ', ['&para;'] ='¶', ['&middot;'] ='·', ['&cedil;'] ='¸', ['&sup1;'] ='¹', ['&ordm;'] ='º', ['&raquo;'] ='»',
        ['&frac14;'] ='¼', ['&frac12;'] ='½', ['&frac34;'] ='¾', ['&iquest;'] ='¿', ['&Agrave;'] ='À', ['&Aacute;'] ='Á', ['&Acirc;'] ='Â', ['&Atilde;'] ='Ã', ['&Auml;'] ='Ä', ['&Aring;'] ='Å', ['&AElig;'] ='Æ', ['&Ccedil;'] ='Ç', ['&Egrave;'] ='È', ['&Eacute;'] ='É',
        ['&Ecirc;'] ='Ê', ['&Euml;'] ='Ë', ['&Igrave;'] ='Ì', ['&Iacute;'] ='Í', ['&Icirc;'] ='Î', ['&Iuml;'] ='Ï', ['&ETH;'] ='Ð', ['&Ntilde;'] ='Ñ', ['&Ograve;'] ='Ò', ['&Oacute;'] ='Ó', ['&Ocirc;'] ='Ô', ['&Otilde;'] ='Õ', ['&Ouml;'] ='Ö', ['&times;'] ='×',
        ['&Oslash;'] ='Ø', ['&Ugrave;'] ='Ù', ['&Uacute;'] ='Ú', ['&Ucirc;'] ='Û', ['&Uuml;'] ='Ü', ['&Yacute;'] ='Ý', ['&THORN;'] ='Þ', ['&szlig;'] ='ß', ['&agrave;'] ='à', ['&aacute;'] ='á', ['&acirc;'] ='â', ['&atilde;'] ='ã', ['&auml;'] ='ä', ['&aring;'] ='å',
        ['&aelig;'] ='æ', ['&ccedil;'] ='ç', ['&egrave;'] ='è', ['&eacute;'] ='é', ['&ecirc;'] ='ê', ['&euml;'] ='ë', ['&igrave;'] ='ì', ['&iacute;'] ='í', ['&icirc;'] ='î', ['&iuml;'] ='ï', ['&eth;'] ='ð', ['&ntilde;'] ='ñ', ['&ograve;'] ='ò', ['&oacute;'] ='ó',
        ['&ocirc;'] ='ô', ['&otilde;'] ='õ', ['&ouml;'] ='ö', ['&divide;'] ='÷', ['&oslash;'] ='ø', ['&ugrave;'] ='ù', ['&uacute;'] ='ú', ['&ucirc;'] ='û', ['&uuml;'] ='ü', ['&yacute;'] ='ý', ['&thorn;'] ='þ', ['&yuml;'] ='ÿ', ['&euro;'] ='€',['&#039;'] = "'" , ['&#034;'] = '"', ['&amp;']='&'
        }
        for code, char in pairs(ascii) do 
            str = str:gsub(code, char )
        end
        return str
    end
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
