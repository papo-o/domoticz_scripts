--[[
/home/pi/domoticz/scripts/dzVents/scripts/beaufort.lua
author/auteur = papoo
update/mise à jour = 12/01/2020
creation = 12/01/2020
https://pon.fr/
https://easydomoticz.com/forum/
https://github.com/papo-o/domoticz_scripts/tree/master/dzVents/scripts/beaufort.lua


--]]

local scriptName        = 'Beaufort'
local scriptVersion     = '1.00'
local beaufortSelector  = nil
local windDevice        = 'Anémomètre'
local msWind            = true -- false if wind device is in km/h
local windAlert         = nil  -- Wind Alert Device name or nil


return {
    active = true,
    on      =   {
                    devices = {windDevice}
                },
    logging =   {    level    =   domoticz.LOG_DEBUG,
                    -- level    =   domoticz.LOG_INFO,  dz.ALERTLEVEL_GREEN,  -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,  dz.ALERTLEVEL_GREEN, -- Only one level can be active; comment others
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker = scriptName..' v'..scriptVersion },

    execute = function(dz)
    local round, coef, level = dz.utils.round, 0, nil
    local function logWrite(str,level)             -- Support function for shorthand debug log statements
        dz.log(tostring(str),level or dz.LOG_DEBUG)
    end
if msWind == true then coef = 3.6 else coef = 1 end
local vent = tonumber(dz.devices(windDevice).state*coef)
logWrite("vent : "..tostring(vent).." km/h")
vent = round(vent)
logWrite("vent arrondi : "..tostring(vent).." km/h")
local BeaufortLevel12   = "Ouragan"              -- level 120 Beaufort Selector switch
local BeaufortLevel11   = "Violente tempête"     -- level 110 Beaufort Selector switch
local BeaufortLevel10   = "Tempête"              -- level 100 Beaufort Selector switch
local BeaufortLevel09   = "Fort coup de vent"    -- level 90 Beaufort Selector switch
local BeaufortLevel08   = "Coup de vent"         -- level 80 Beaufort Selector switch
local BeaufortLevel07   = "Grand Frais"          -- level 70 Beaufort Selector switch
local BeaufortLevel06   = "Vent frais"           -- level 60 Beaufort Selector switch
local BeaufortLevel05   = "Bonne brise"          -- level 50 Beaufort Selector switch
local BeaufortLevel04   = "Jolie brise"          -- level 40 Beaufort Selector switch
local BeaufortLevel03   = "Petite brise"         -- level 30 Beaufort Selector switch
local BeaufortLevel02   = "Légère brise"         -- level 20 Beaufort Selector switch
local BeaufortLevel01   = "Très légère brise"    -- level 10 Beaufort Selector switch
local BeaufortLevel00   = "Calme"                -- level 0 Beaufort Selector switch

    if     vent >  118  then beaufortText, alertLevel, level = BeaufortLevel12, dz.ALERTLEVEL_RED, 120
    elseif vent >= 103  then beaufortText, alertLevel, level = BeaufortLevel11, dz.ALERTLEVEL_RED, 110
    elseif vent >= 89   then beaufortText, alertLevel, level = BeaufortLevel10, dz.ALERTLEVEL_RED, 100
    elseif vent >= 75   then beaufortText, alertLevel, level = BeaufortLevel09, dz.ALERTLEVEL_RED, 90
    elseif vent >= 62   then beaufortText, alertLevel, level = BeaufortLevel08, dz.ALERTLEVEL_ORANGE, 80
    elseif vent >= 50   then beaufortText, alertLevel, level = BeaufortLevel07, dz.ALERTLEVEL_ORANGE, 70
    elseif vent >= 39   then beaufortText, alertLevel, level = BeaufortLevel06, dz.ALERTLEVEL_YELLOW, 60
    elseif vent >= 29   then beaufortText, alertLevel, level = BeaufortLevel05, dz.ALERTLEVEL_YELLOW, 50
    elseif vent >= 20   then beaufortText, alertLevel, level = BeaufortLevel04, dz.ALERTLEVEL_YELLOW, 40
    elseif vent >= 12   then beaufortText, alertLevel, level = BeaufortLevel03, dz.ALERTLEVEL_GREEN, 30
    elseif vent >= 6    then beaufortText, alertLevel, level = BeaufortLevel02, dz.ALERTLEVEL_GREEN, 20
    elseif vent >= 1    then beaufortText, alertLevel, level = BeaufortLevel01, dz.ALERTLEVEL_GREEN, 10
    else                     beaufortText, alertLevel, level = BeaufortLevel00, dz.ALERTLEVEL_GREEN, 00
    end

    logWrite("beaufort text : "..tostring(beaufortText))
    logWrite("level : "..tostring(level))

    if (BeaufortSelector) then
        logWrite("switch selector name : "..dz.devices(BeaufortSelector).name)
        logWrite("switch selector id : "..dz.devices(BeaufortSelector).id)
        logWrite("last level switch selector : "..dz.devices(BeaufortSelector).lastLevel)
        if (dz.devices(BeaufortSelector).lastLevel ~= level) then
            dz.devices(BeaufortSelector).switchSelector(level)
            logWrite("update selector device")
        else
            logWrite("no update needed")
        end
        logWrite("level switch selector : "..dz.devices(BeaufortSelector).level)
        logWrite("level name switch selector : "..dz.devices(BeaufortSelector).levelName)
    end

    if windAlert ~= nil then
        if (domoticz.devices(windAlert).text ~= beaufortText or domoticz.devices(windAlert).lastUpdate.minutesAgo > 1440) then 
            domoticz.devices(windAlert).updateAlertSensor(alertLevel, beaufortText) 
            logWrite('update alert device')
        else
            logWrite('no update needed')
        end
    end

    end -- execute function
}
