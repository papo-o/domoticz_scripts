--[[ getHolidays.lua for [ dzVents >= 2.4 ]

Start with creating a string type uservariable in domoticz (SETUP] ==>> [MORE OPTIONS] ==>> [uservariableS] ==>> [ADD] and put the name in the appropriate place between the lines starting with --++++
Next is to decide how you want the result of the check if today is a public holiday to be presented. The just created uservariable will contain the localized datestring with either the public holiday name or the userDefined_noPublicHoliday text.
Further options are:
- an integer typed uservariable:  if today is a public holiday it will be set to 1; if not it will be set to 0
- a text device: it will be set to the same text as set in the uservariable
- an alert device: as text device plus alert level 5 if today is a public holiday or
                                       alert level 2 if today is Saturday or
                                       alert level 3 if today is Sunday  or alert level 1 all other days
- a switch: On if today is a public holiday / Off if not

For one or more of these options to take effect the variable or (virtual)device must be defined in domoticz and either the name or idx must entered in the Optional section of the area surrounded by the lines starting with --++++

You can trigger the script for an initial run or for testing by updating the string type uservariable defined at the beginning.

this script collect public holiday information from Enrico Service 2.0
This is open-source software licensed under the MIT License so you can study, contribute, change or use it. (so if your country is not supported yet you could add the required XML to get it in the list)
See Enrico source code on https://github.com/jurajmajer/enrico

Supported countries in http://holidays.kayaposoft.com/ as of 22 July 2018:

Angola, Australia, Austria, Belgium, Bosnia and Herzegovina, Brazil, Canada, China, Colombia, Czech Republic, Germany, Denmark, Estonia, Finland, France, United Kingdom, Greece, Hong Kong, Croatia, Hungary, Isle of Man, Ireland, Iceland, Israel, Italy, Japan, Korea (South), Lithuania, Luxembourg, Latvia, Mexico, Macedonia, Netherlands, Norway, New Zealand, Poland, Portugal, Romania, Russian Federation, Singapore, Serbia, Slovakia, Slovenia, Sweden, Ukraine, United States of America, South Africa

(get an up to date list at https://kayaposoft.com/enrico/json/v2.0?action=getSupportedCountries )

 Script collects information for at least one year ahead and stores this in dzVents persistent data. The collection process is not done frequently as this data is kind of static. The default period between calls to kayaposoft is set to 60 days.

]]--

--++++--------------------- Mandatory: Set your values and device names below this Line --------------------------------------
local userDefined_httpResponse      = "getHolidays_Response"    -- This will trigger the script after the return
local userDefined_stringVariable    = "Vacances"                 -- Name of your uservariable created as type string (mandatory)
local userDefined_noPublicHoliday   = "n'est pas un jour férié"        -- Localized text for no public holiday
local userDefined_country           = "FRA"                      -- Also used for language
local userDefined_region            = "A"                        -- mandatory if regions are defined for your country
-- find list of valid regions at https://kayaposoft.com/enrico/json/v2.0?action=getSupportedCountries

----------------------------------------- Optional: presenting the result ----------------------------------------------------
--local userDefined_integerVariable   = "HolidayInteger"    -- Name of your uservariable if you created it as type integer or set to line to comment
--local userDefined_textDevice        = "HolidayText"       -- Name with quotes or idx without when created as virtual text device or set to line to comment
--local userDefined_alertDevice       = "HolidayAlert"      -- Name with quotes or idx without when created as virtual alert device or set to line to comment
--local userDefined_switchDevice      = 995                 -- Name with quotes or idx without when created as virtual switch or set to line to comment

--++++---------------------------- Set your values and device names above this Line --------------------------------------------

function date_en_francais(str)
    if (str) then
	str = string.gsub(str, "January", "Janvier;");
	str = string.gsub(str, "February",	"Février")
	str = string.gsub(str, "March",	"Mars")
	str = string.gsub(str, "April",	"Avril")
	str = string.gsub(str, "May",	"Mai")
	str = string.gsub(str, "June",	"Juin")
	str = string.gsub(str, "July",	"Juillet")
	str = string.gsub(str, "August",	"Août")
	str = string.gsub(str, "september",	"Septembre")
	str = string.gsub(str, "October",	"Octobre")
	str = string.gsub(str, "November",	"Novembre")
	str = string.gsub(str, "December",	"Décembre")
	str = string.gsub(str, "Monday",	"Lundi")
	str = string.gsub(str, "Tuesday",	"Mardi")
	str = string.gsub(str, "Wednesday",	"Mercredi")
	str = string.gsub(str, "Thursday", "Jeudi")
    str = string.gsub(str, "Friday", "Vendredi")
    str = string.gsub(str, "Saturday", "Samedi")
    str = string.gsub(str, "Sunday", "Dimanche")
     end
    return (str)
end


return {
    on      =   {   timer           =   { "at 00:01","at 06:03" },               -- daily run (One extra for redundancy)
                    variables       =   { userDefined_stringVariable },
                    httpResponses   =   { userDefined_httpResponse }               -- Trigger the handle Json part
                },
    logging =   {   level           =   domoticz.LOG_ERROR,
                    marker          =   "getHolidays"
                },
    data    =   {   holidays              = {initial = {} },                     -- Store holidaysTable in dzVents persistent data
                    refreshDate           = {initial = "" },
                    country               = {initial = userDefined_country },
                    region                = {initial = userDefined_region },
                },

    execute = function(dz, triggerObject)
        
        -- Compose URL and send 
        local function getHolidays(secondsFromNow)
            secondsFromNow = secondsFromNow or 1                   -- catch empty parm
            local yearsAhead         = 1 * 366 * 24 * 3600
            local getHolidays_url  = "https://kayaposoft.com/enrico/json/v2.0/" ..
                                     "?action=getHolidaysForDateRange"..
                                    "&fromDate=" .. os.date("%d-%m-%Y")  ..                              -- today
                                    "&toDate=".. os.date("%d-%m-%Y",os.time() + yearsAhead ) ..      -- today + yearsAhead years
                                    "&country=" .. userDefined_country ..
                                    "&region=" .. userDefined_region ..
                                    "&holidayType=public_holiday"

            dz.openURL  ({
                            url = getHolidays_url ,
                            method = "GET",
                            callback = userDefined_httpResponse,
                        }).afterSec(secondsFromNow)
        end

        -- walk trough the table to find today's date    
        local function processHolidays()
            local holidayTable  = dz.data.holidays
            local today         = os.date("*t")

            for i = 1,#holidayTable do
                if holidayTable[i].date.day == today.day and holidayTable[i].date.month == today.month and holidayTable[i].date.year == today.year then
                   return holidayTable[i].name[1].text                            -- holiday found
                end
            end
            return userDefined_noPublicHoliday
        end

        -- update variables and devices
        local function setDomoticzDevices(holidayName)
            local fullText  = date_en_francais(os.date(" %A %d %B, %Y")):gsub(" 0"," ") .. ": " ..  holidayName

            dz.variables(userDefined_stringVariable).set(fullText).silent()

            if userDefined_integerVariable then
                dz.variables(userDefined_integerVariable).set(0)
                if holidayName ~= userDefined_noPublicHoliday then
                    dz.variables(userDefined_integerVariable).set(1)
                end
            end

            if userDefined_textDevice then
                dz.devices(userDefined_textDevice).updateText(fullText)
            end

            if userDefined_alertDevice then
                alertTable = {dz.ALERTLEVEL_YELLOW,        -- Sunday
                              dz.ALERTLEVEL_GREEN,         -- Monday
                              dz.ALERTLEVEL_GREEN,         -- Tuesday
                              dz.ALERTLEVEL_GREEN,         -- Wednesday
                              dz.ALERTLEVEL_GREEN,         -- Thursday
                              dz.ALERTLEVEL_GREEN,         -- Fridayday
                              dz.ALERTLEVEL_ORANGE,         -- Saturday
                              dz.ALERTLEVEL_RED            -- Holiday
                                 }
                if holidayName == userDefined_noPublicHoliday then
                    dz.devices(userDefined_alertDevice).updateAlertSensor(alertTable[os.date("*t").wday], fullText)
                else
                    dz.devices(userDefined_alertDevice).updateAlertSensor(alertTable[#alertTable], fullText)
                end
            end

            if userDefined_switchDevice then
                if holidayName ~= userDefined_noPublicHoliday then
                    dz.devices(userDefined_switchDevice).switchOn().checkFirst()
                else
                    dz.devices(userDefined_switchDevice).switchOff().checkFirst()
                end
            end
        end

        -- set number of days since last refresh 
        local function daysSinceLastRefresh()
            local lastRefreshDate
            if dz.data.refreshDate ~= "" then
                lastRefreshDate = dz.data.refreshDate   -- dz.data.refreshDate was set in earlier run
            else
                lastRefreshDate = os.date("*t",1)        -- use very old date because dz.data.refreshDate is not yet set
            end
            return os.difftime(os.time(), os.time(lastRefreshDate)) / (3600*24)
        end
        
        -- Add entry to log and notify to all subsystems
        local function errorMessage(message)
            dz.log(message,dz.LOG_ERROR)
            dz.notify(message)
        end       
        
        -- Store table and date in persistent data 
        local function updatePersistentData()
            if #triggerObject.json > 0 then
                dz.data.holidays    = triggerObject.json           -- fill dz.data with the complete httpResponse
                dz.data.refreshDate = os.date('*t')         -- set refreshDate to current datetime
                return true
            else
                return false
            end
        end
        
        -- Do we need to get fresh data ? 
        local function freshData()
            local daysBetweenRefresh = 60
           
            return   dz.data.holidays[1] ~= nil  and
                     daysSinceLastRefresh() < daysBetweenRefresh and
                     userDefined_country == dz.data.country and
                     userDefined_region  == dz.data.region
        end
        
        -- Main 
        if triggerObject.isHTTPResponse then
            if triggerObject.ok then
                if updatePersistentData() then
                    setDomoticzDevices(processHolidays())
                else
                    errorMessage("Problème avec les données dans la réponse Enricp (les données semblent manquer)")   -- Forgot to enter valid country / region ?
                end
            else
                errorMessage("Problème avec la réponse Enrico  (pas ok)")
                getHolidays(600)                            -- response not OK, try again after 10 minutes
            end
        else
            if freshData() then
                setDomoticzDevices(processHolidays())
            else                                            -- dz.data does not contain any data or data needs to be refreshed
                getHolidays()
            end
        end
    end
}
