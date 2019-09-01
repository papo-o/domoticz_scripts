--[[ UValert.lua 
author/auteur = papoo
update/mise à jour = 01/09/2019
création = 31/08/2019
https://pon.fr/dzvents-alerte-uv-et-temps-dexposition-en-toute-securite
https://github.com/papo-o/domoticz_scripts/blob/master/domoticzVents/scripts/UValert.lua
https://easydomoticz.com/forum/


skinType determination : Fitzpatrick Skin Types & Safe Exposure Time Calculation
The most commonly used scheme to classify a person’s skin type by their response to sun exposure in terms of the degree of burning and tanning was developed by Thomas B. Fitzpatrick, MD, PhD. As a meter of fact even the skin color of Emoji characters based on the Fitzpatrick scale.

Skin Type    Color    Typical Features    Tanning Ability    Ethnicity    Time to Burn (mins)

I    Very fair skin, white; red or blond hair; light-colored eyes; freckles likely    Always burns, does not tan    Scandinavian, Celtic    (200 * 2.5)/(3 * UVI)

II    Fair skin, white; light eyes; light hair    Burns easily, tans poorly    Northern European (Caucasian)    (200 * 3)/(3 * UVI)

III    Fair skin, cream white; any eye or hair color (very common skin type)    Tans after initial burn    Darker Caucasian (Central Europe)    (200 * 4)/(3 * UVI)

IV    Olive skin, typical Mediterranean Caucasian skin; dark brown hair; medium to heavy pigmentation    Burns minimally, tans easily    Mediterranean, Asian, Hispanic    (200 * 5)/(3 * UVI)

V    Brown skin, typical Middle Eastern skin; dark hair; rarely sun sensitive    Rarely burns, tans darkly easily    Middle eastern, Latin, light-skinned African-American, Indian    (200 * 8)/(3 * UVI)

VI    Black skin; rarely sun sensitive    Never burns, always tans darkly    Dark-skinned African American    (200 * 15)/(3 * UVI)


--]]

--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------
local UVdevice      = 'UV'          -- UV device name
local skinType      = 3             -- personalize with your skin type
local UValertDevice = 'Alerte UV'   -- Alert device name
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local scriptName        = 'Alerte aux UV'
local scriptVersion     = '1.01'
return {
    active  = true,
        on      =   {
                        devices = {UVdevice}
                    },
        -- on  =   {
                    -- timer           =   { "every minutes" },
                -- },

    logging =   {    level    =   domoticz.LOG_DEBUG,
                    -- level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                    marker  =   scriptName..' v'..scriptVersion },

    execute = function(domoticz, device)
        local round = domoticz.utils.round
        local UV_AlertText
        local function logWrite(str,level)             -- Support function for shorthand debug log statements
            domoticz.log(tostring(str),level or domoticz.LOG_DEBUG)
        end

        local function UV_Index2Alert(index)                            -- Levels as from KNMI
            local alert = domoticz.ALERTLEVEL_RED
            if     index <= 1 then alert = domoticz.ALERTLEVEL_GREY   -- very low
            elseif index <= 3 then alert = domoticz.ALERTLEVEL_GREEN  -- low
            elseif index <= 6 then alert = domoticz.ALERTLEVEL_YELLOW -- mod
            elseif index <= 8 then alert = domoticz.ALERTLEVEL_ORANGE -- high
            else                   alert = domoticz.ALERTLEVEL_RED    -- very high
            end
            return alert
        end

        local function safeTimeExposure(uvIndex, skinType)
            local coef
            if      skinType == 6 then coef = 15
            elseif  skinType == 5 then coef = 8
            elseif  skinType == 4 then coef = 5
            elseif  skinType == 3 then coef = 4
            elseif  skinType == 2 then coef = 3
            else                       coef = 2.5 end
            local   time2Burn = domoticz.utils.round(( 200 * coef) / (3 * uvIndex))
            return  time2Burn
        end
        -- -- on device trigger
        local UVindex = device.uv 

        -- --on timer trigger
        --local UVindex = domoticz.devices(UVdevice).uv

        logWrite('UV index : '..UVindex)
        logWrite('safeTimeExposure : '..safeTimeExposure(UVindex,skinType)..' minutes')

    -- Construct Alertlevel and text and update UV alert device (type = Alert)
        if UVindex > 0 then 
            UV_AlertText = 'Exposition maximale : '..safeTimeExposure(UVindex,skinType)..' mn (peau type ' .. skinType ..')'
        else
            UV_AlertText = 'Exposition maximale : Pas de limite, index UV : '..UVindex
        end
        if UValertDevice ~= nil then
            if (domoticz.devices(UValertDevice).color ~= UV_Index2Alert(UVindex) or domoticz.devices(UValertDevice).lastUpdate.minutesAgo > 1440) then 
                domoticz.devices(UValertDevice).updateAlertSensor(UV_Index2Alert(UVindex), UV_AlertText) 
                logWrite('update alert device')
            else
                logWrite('no update needed')
            end
        end
    end
}
