--[[
author/auteur = papoo
update/mise à jour = 08/08/2019
creation = 04/08/2019
source https://github.com/JamesSherburne/MoonPhasesLua/blob/master/main.lua
https://pon.fr/dzvents-phases-lunaires-sans-api
https://easydomoticz.com/forum/viewtopic.php?f=17&t=8789

--]]

local scriptName        = 'moon phase'
local scriptVersion     = '1.01'
local MoonPhaseSelector = 2479--nil --

    --local Waning_Crescent = "Waning Crescent"     -- level 80 MoonPhase Selector switch
    local Waning_Crescent = "Dernier croissant"     -- level 80 MoonPhase Selector switch
    --local Last_Quarter = "Last Quarter"           -- level 70 MoonPhase Selector switch
    local Last_Quarter = "Dernier quartier"         -- level 70 MoonPhase Selector switch
    --local Waning gibbous = "Waning gibbous"       -- level 60 MoonPhase Selector switch
    local Waning gibbous = "gibbeuse décroissante"  -- level 60 MoonPhase Selector switch
    --local Full_Moon = "Full Moon"                 -- level 50 MoonPhase Selector switch
    local Full_Moon = "Pleine une"                  -- level 50 MoonPhase Selector switch
    --local Waxing_gibbous = "Waxing gibbous"       -- level 40 MoonPhase Selector switch
    local Waxing_gibbous = "Gibbeuse croissante"    -- level 40 MoonPhase Selector switch
    --local First_Moon = "First Moon"               -- level 30 MoonPhase Selector switch
    local First_Moon = "Premier quartier"           -- level 30 MoonPhase Selector switch
    --local Waxing_crescent = "Waxing crescent"     -- level 20 MoonPhase Selector switch
    local Waxing_crescent = "Premier croissant"     -- level 20 MoonPhase Selector switch
    --local New_Moon = "New Moon"                   -- level 10 MoonPhase Selector switch
    local New_Moon = "Nouvelle lune"                -- level 10 MoonPhase Selector switch

return {
    active = true,
    on = { timer =   {'every hour'}},
    logging =   {    level    =   domoticz.LOG_DEBUG,
                    -- level    =   domoticz.LOG_INFO,             -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,            -- Only one level can be active; comment others
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker = scriptName..' v'..scriptVersion },

    execute = function(domoticz)
            local function logWrite(str,level)             -- Support function for shorthand debug log statements
                domoticz.log(tostring(str),level or domoticz.LOG_DEBUG)
            end

    local function julianDate(d, m, y)
        local mm, yy, k1, k2, k3, j
        yy = y - math.floor((12 - m) / 10)
        mm = m + 9
        if (mm >= 12) then
            mm = mm - 12
        end
        k1 = math.floor(365.25 * (yy + 4712))
        k2 = math.floor(30.6001 * mm + 0.5)
        k3 = math.floor(math.floor((yy / 100) + 49) * 0.75) - 38
        j = k1 + k2 + d + 59
        if (j > 2299160) then
            j = j - k3
        end
        return j
    end

    local function  moonAge(d, m, y)
        local j, ip, ag
        j = julianDate(d, m, y)
        ip = (j + 4.867) / 29.53059
        ip = ip - math.floor(ip)
        if (ip < 0.5) then
            ag = ip * 29.53059 + 29.53059 / 2
        else
            ag = ip * 29.53059 - 29.53059 / 2
        end
        logWrite(ag)
        return ag
    end

    local day = os.date("%d")
    local month = os.date("%m")
    local year = os.date("%Y")

    local theMoon = moonAge(day,month,year)
    logWrite(theMoon)

    if  theMoon >=  29  then
        moonText    = New_Moon
        level       = 10
    elseif theMoon < 29 and theMoon > 23 then
        moonText    = Waning_Crescent
        level       = 80
    elseif theMoon < 23 and theMoon > 22 then
        moonText    = Last_Quarter
        level       = 70
    elseif theMoon < 22 and theMoon > 15 then
        moonText = Waning_gibbous
        level       = 60
    elseif theMoon < 15 and theMoon > 13 then
        moonText = Full_Moon
        level       = 50
    elseif theMoon < 13 and theMoon > 8 then
        moonText = Waxing_gibbous
        level       = 40
    elseif theMoon < 8 and theMoon > 6 then
        moonText = First_Moon
        level       = 30
    elseif theMoon < 6 and theMoon > 1 then
        moonText = Waxing_crescent
        level       = 20
    else
        moonText = New_Moon
        level       = 10
    end

    logWrite("moon text : "..moonText)
    logWrite("level : "..level)

    if (MoonPhaseSelector) then
        logWrite("switch selector name : "..domoticz.devices(MoonPhaseSelector).name)
        logWrite("switch selector id : "..domoticz.devices(MoonPhaseSelector).id)
        logWrite("last level switch selector : "..domoticz.devices(MoonPhaseSelector).lastLevel)
        if (domoticz.devices(MoonPhaseSelector).lastLevel ~= level) then
            domoticz.devices(MoonPhaseSelector).switchSelector(level)
            logWrite("update selector device")
        else
            logWrite("no update needed")
        end
        logWrite("level switch selector : "..domoticz.devices(MoonPhaseSelector).level)
        logWrite("level name switch selector : "..domoticz.devices(MoonPhaseSelector).levelName)
    end

    end -- execute function
}
