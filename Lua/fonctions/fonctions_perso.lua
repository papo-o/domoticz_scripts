--[[   
appel de ces fonctions :
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"
require('fonctions_perso')
]]--  
--------------------------------------------
-------------Fonctions----------------------
-------------------------------------------- 

function voir_les_logs (s, debugging) -- nécessite la variable local debugging
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>")
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>")
		end
    end
end	

--============================================================================================== 
function format(str)
   if (str) then
      str = string.gsub (str, "De", "De ")
      str = string.gsub (str, " ", "&nbsp;")
      str = string.gsub (str, "Pas&nbsp;de&nbsp;précipitations", "<font color='#999'>Pas&nbsp;de&nbsp;précipitations</font>")
      str = string.gsub (str, "Précipitations&nbsp;faibles", "<font color='#fbda21'>Précipitations&nbsp;faibles</font>")
      str = string.gsub (str, "Précipitations&nbsp;modérées", "<font color='#fb8a21'>Précipitations&nbsp;modérées</font>")
      str = string.gsub (str, "Précipitations&nbsp;fortes", "<font color='#f3031d'>Précipitations&nbsp;fortes</font>")
   end
   return str   
end

--============================================================================================== 
function print_r ( t )  -- afficher le contenu d'un tableau
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

--============================================================================================== 
function urlencode(str)
   if (str) then
   str = string.gsub (str, "\n", "\r\n")
   str = string.gsub (str, "([^%w ])",
   function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   end
   return str
end 

--============================================================================================== 
function sans_accent(str)
    if (str) then
	str = string.gsub (str,"Ç", "C")
	str = string.gsub (str,"ç", "c")
    str = string.gsub (str,"[-èéêë']+", "e")
	str = string.gsub (str,"[-ÈÉÊË']+", "E")
    str = string.gsub (str,"[-àáâãäå']+", "a")
    str = string.gsub (str,"[-@ÀÁÂÃÄÅ']+", "A")
    str = string.gsub (str,"[-ìíîï']+", "i")
    str = string.gsub (str,"[-ÌÍÎÏ']+", "I")
    str = string.gsub (str,"[-ðòóôõö']+", "o")
    str = string.gsub (str,"[-ÒÓÔÕÖ']+", "O")
    str = string.gsub (str,"[-ùúûü']+", "u")
    str = string.gsub (str,"[-ÙÚÛÜ']+", "U")
    str = string.gsub (str,"[-ýÿ']+", "y")
    str = string.gsub (str,"Ý", "Y")
     end
    return (str)
end

--============================================================================================== 
function accent_html(str)
    if (str) then
	str = string.gsub(str, "'", "&apos;");
	str = string.gsub(str, "â",	"&acirc;")
	str = string.gsub(str, "à",	"&agrave;")
	str = string.gsub(str, "é",	"&eacute;")
	str = string.gsub(str, "ê",	"&ecirc;")
	str = string.gsub(str, "è",	"&egrave;")
	str = string.gsub(str, "ë",	"&euml;")
	str = string.gsub(str, "î",	"&icirc;")
	str = string.gsub(str, "ï",	"&iuml;")
	str = string.gsub(str, "ô",	"&ocirc;")
	str = string.gsub(str, "œ",	"&oelig;")
	str = string.gsub(str, "û",	"&ucirc;")
	str = string.gsub(str, "ù",	"&ugrave;")
	str = string.gsub(str, "ü",	"&uuml;")
	str = string.gsub(str, "ç",	"&ccedil;")
	str = string.gsub(str, "[-ÈÉÊË']+", "E")
    str = string.gsub(str, "[-@ÀÁÂÃÄÅ']+", "A")
    str = string.gsub(str, "[-ÌÍÎÏ']+", "I")
    str = string.gsub(str, "[-ÒÓÔÕÖ']+", "O")
    str = string.gsub(str, "[-ÙÚÛÜ']+", "U")
    str = string.gsub(str, "Ý", "Y")
     end
    return (str)
end

--============================================================================================== 
   function GetUserVar(UserVar) -- Get UserVar and Print when missing
      variable=uservariables[UserVar]
      if variable==nil then
         print(".  User variable not set for : " .. UserVar)
         UserVarErr=UserVarErr+1
      end
      return variable
	  
	  --[[
Get value of a user variable, but when the user variable not exist the function prints print (". User variable not set for : " .. UserVar) to the log.
When you use this function for all the variables users who copy your script gets in logging a message which variables they must make.]]--
   end
   
--============================================================================================== 
   function File_exists(file)  --Check if file exist
     local f = io.open(file, "rb")
     if f then f:close() end
     return f ~= nil
	--   if not File_exists(LogFile) then
   end
   
--============================================================================================== 
   --function Round(num, idp)  -- arrondi
    --  local mult = 10^(idp or 0)
    --  return math.floor(num * mult + 0.5) / mult
	--utilisation => Round(ValueThatNeedsToRounded,1)  
   --end
function round(value, digits)
  local precision = 10^digits
  return (value >= 0) and
      (math.floor(value * precision + 0.5) / precision) or
      (math.ceil(value * precision - 0.5) / precision)
end

--============================================================================================== 
function fahrenheit_to_celsius(fahrenheit, digits) 
    return round((5/9) * (fahrenheit - 32), digits or 2)
end

--============================================================================================== 
function miles_to_km(miles, digits) 
    return round((miles * 1.609344), digits or 2)
end

--============================================================================================== 
   function GetValue(Text, GetNr)  -- Get the X value of a device
      Part=1	 --[[5 in this example can you change in the number of the value.
my Wind meter gives: 207.00;SSW;9;18;16.4;16.4 so I need fift value for temperature]] --
      for match in (Text..';'):gmatch("(.-)"..';') do
         if Part==GetNr then MyValue = tonumber(match) end
         Part=Part+1
      end
      return MyValue
-- Variable      = GetValue(otherdevices_svalues[DeviceName],5)  
   end
 --==============================================================================================   
   -- replace the last character
   function EnumClear(Text)
      a=string.len(Text)
      b=string.sub(Text,a,a)
      if b=="," or b==" " then Text=string.sub(Text,1,a-1) end
      a=string.len(Text)
      b=string.sub(Text,a,a)
      if b=="," or b==" " then Text=string.sub(Text,1,a-1) end
      return Text
   end
   
--============================================================================================== 
   function ConvTime(TimeX)
      year = string.sub(TimeX, 1, 4)
      month = string.sub(TimeX, 6, 7)
      day = string.sub(TimeX, 9, 10)
      hour = string.sub(TimeX, 12, 13)
      minutes = string.sub(TimeX, 15, 16)
      seconds = string.sub(TimeX, 18, 19)
      ResTime = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
      return ResTime
   end
   
--============================================================================================== 
   function TimeDiff(Time1,Time2)  --gave to difference between now and the time that a devices is last changed in minutes 
      if string.len(Time1)>12 then Time1 = ConvTime(Time1) end
      if string.len(Time2)>12 then Time2 = ConvTime(Time2) end   
      ResTime=os.difftime (Time1,Time2)
      return ResTime
	  --TDiff = Round(TimeDiff(os.time(),otherdevices_lastupdate[DeviceManual])/60,0)
   end
   
 --==============================================================================================   
 function XML_Capture(cmd,flatten)
   local f = assert(io.popen(cmd, 'r'))
   local s = assert(f:read('*a'))
   f:close()
   if flatten  then
      s = string.gsub(s, '^%s+', '')
      s = string.gsub(s, '%s+$', '')
      s = string.gsub(s, '[\n\r]+', ' ')
   end
   return s
end  

--============================================================================================== 
	function unescape(str)
	   	if string.match (str, "&") ~= nil then
	   		str = string.gsub( str, '&lt;', '<' )
	   		str = string.gsub( str, '&gt;', '>' )
	   		str = string.gsub( str, '&quot;', '"' )
	   		str = string.gsub( str, '&apos;', "'" )
	   		str = string.gsub( str, '&rsquo;', "'" )
	   		str = string.gsub( str, '&laquo;', "«" )
	   		str = string.gsub( str, '&raquo;', "»" )
	   		str = string.gsub( str, '&nbsp;', " " )
	   		str = string.gsub( str, '&Ccedil;', "Ç" )
	   		str = string.gsub( str, '&ccedil;', "ç" )
	   		str = string.gsub( str, '&Acirc;', "Â" )
	   		str = string.gsub( str, '&Ecirc;', "Ê" )
	   		str = string.gsub( str, '&Icirc;', "Î" )
	   		str = string.gsub( str, '&Ocirc;', "Ô" )
	   		str = string.gsub( str, '&Ucirc;', "Û" )
	   		str = string.gsub( str, '&#(%d+);', function(n) if tonumber(n) < 256 then return string.char(tonumber(n)) else return "" end end )
	   		str = string.gsub( str, '&#x(%d+);', function(n) if tonumber(n) < 256 then return string.char(tonumber(n,16)) else return "" end end )
	   		str = string.gsub( str, '&amp;', '&' ) -- Be sure to do this after all others
	   	end
	   	return str
	end
	
--============================================================================================== 
  function Pushbullet(Message)  -- séparer titre et message par un ;
    local pb_token = 'o.vzvYdwX71Jazyy1QcyIV9Vgj24RnTObR'
    local pb_total = Message
    local val=string.find(pb_total,";")
    local pb_title = string.sub(pb_total,1,val-1)
    local pb_body = string.sub(pb_total,val+1)
	--Pour Windows
    --local pb_command = 'c:\\Programs\\Curl\\curl -u ' .. pb_token .. ': "https://api.pushbullet.com/v2/pushes" -d type=note -d title="' .. pb_title .. '" -d body="' .. pb_body ..'"'
    --pour Linux
   local pb_command = 'curl -u ' .. pb_token .. ': "https://api.pushbullet.com/v2/pushes" -d type=note -d title="' .. pb_title .. '" -d body="' .. pb_body ..'"'
    -- Run curl command
    exec_success = os.execute(pb_command)
	-- pour utiliser cette fonction => Pushbullet('essai;text')
  end
  
--============================================================================================== 
function split(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end
--valeurs = split(variable,";")

--==============================================================================================
-- Calculate wind chill. If temperature is low but it's windy, the temperature
-- feels lower than the actual measured temperature. Wind chill formula from
-- <a href="http://www.nws.noaa.gov/om/windchill/">http://www.nws.noaa.gov/om/windchill/</a>.
-- @param temperature Temperature in Fahrenheit, must be 50 or less
-- @param wind_speed Wind speed in miles per hour
-- @return Wind chill of the given conditions, or nil if invalid input received
function calc_wind_chill(temperature, wind_speed)
	local apparent = nil
	if (temperature ~= nil and wind_speed ~= nil and temperature <= 50) then
		if (wind_speed > 3) then
			local v = math.pow(wind_speed, 0.16)
			apparent = 35.74 + 0.6215 * temperature - 35.75 * v + 0.4275 * temperature * v
		elseif (wind_speed >= 0) then
			apparent = temperature
		end
	end

	return apparent
end

--==============================================================================================
-- Calculate heat index. If it's hot and humidity is high,
-- temperature feels higher than what it actually is. Heat index is
-- the approximation of the human-perceived temperature in hot and moist
-- conditions. Heat index formula from
-- <a href="http://www.ukscience.org/_Media/MetEquations.pdf">http://www.ukscience.org/_Media/MetEquations.pdf</a>.
-- @param temperature Temperature in Fahrenheit, must be 80 or more
-- @param humidity Relative humidity as a percentage value between 40 and 100
-- @return Heat index of the given conditions, or nil if invalid input received
function calc_heat_index(temperature, humidity)
	local apparent = nil
	if (temperature ~= nil and humidity ~= nil and temperature >= 80 and humidity >= 40) then
		local t2 = temperature * temperature
		local t3 = t2 * temperature
		local h2 = humidity * humidity
		local h3 = h2 * temperature

		apparent = 16.923
		+ 0.185212 * temperature
		+ 5.37941 * humidity
		- 0.100254 * temperature * humidity
		+ 9.41695e-3 * t2
		+ 7.28898e-3 * h2
		+ 3.45372e-4 * t2 * humidity
		- 8.14971e-4 * temperature * h2
		+ 1.02102e-5 * t2 * h2
		- 3.8646e-5 * t3
		+ 2.91583e-5 * h3
		+ 1.42721e-6 * t3 * humidity
		+ 1.97483e-7 * temperature * h3
		- 2.18429e-8 * t3 * h2
		+ 8.43296e-10 * t2 * h3
		- 4.81975e-11 * t3 * h3
	end

	return apparent
end

--==============================================================================================
-- Calculate wind chill or heat index corrected temperature
-- @param temperature Temperature in Fahrenheit
-- @param wind_speed Wind speed in miles per hour
-- @param humidity Relative humidity as a percentage value between 0 and 100
-- @return Apparent temperature given the weather conditions
-- @see calc_wind_chill
-- @see calc_heat_index
function calc_apparent_temperature(temperature, wind_speed, humidity)
	-- Wind chill
	if (temperature ~= nil and wind_speed ~= nil and temperature <= 50) then
		return calc_wind_chill(temperature, wind_speed)
	-- Head index
	elseif (temperature ~= nil and humidity ~= nil and temperature >= 80 and humidity >= 40) then
		return calc_heat_index(temperature, humidity)
	end

	return temperature
end
--==============================================================================================
function getdevname4idx(deviceIDX)
	for i, v in pairs(otherdevices_idx) do
   if v == deviceIDX then
     return i
   end
 end
 return 0
end
--==============================================================================================
function ConvTime(timestamp) -- convertir un timestamp 
   y, m, d, H, M, S = timestamp:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
   return os.time{year=y, month=m, day=d, hour=H, min=M, sec=S}
end
--==============================================================================================
function validIP(ip) --https://stackoverflow.com/questions/10975935/lua-function-check-if-ipv4-or-ipv6-or-string
    -- must pass in a string value
    if ip == nil or type(ip) ~= "string" then
        return false
    end

    -- check for format 1.11.111.111 for ipv4
    local chunks = {ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")}
    if (#chunks == 4) then
        for _,v in pairs(chunks) do
            if (tonumber(v) < 0 or tonumber(v) > 255) then
                return false
            end
        end
        return true
    else
        return false
    end
--==============================================================================================    
function CreateVirtualSensor(dname, sensortype)
    -- recherche d'un hardware dummy pour l'associer au futur device
    local config = assert(io.popen(curl..'"'.. domoticzURL ..'/json.htm?type=hardware" &'))
    local blocjson = config:read('*all')
    config:close()
    local jsonValeur = json:decode(blocjson)
    if jsonValeur ~= nil then
       for Index, Value in pairs( jsonValeur.result ) do
           if Value.Type == 15 then -- hardware dummy = 15
              voir_les_logs("--- --- --- idx hardware dummy  : ".. Value.idx .." --- --- ---",debugging)
              voir_les_logs("--- --- --- Nom hardware dummy  : ".. Value.Name .." --- --- ---",debugging)                  
              id = Value.idx
           end  
       end
    end
    if id ~= nil then -- si un hardware dummy existe on peut créer le device
        voir_les_logs("--- --- --- création du device   : ".. dname .. " --- --- ---",debugging)
        voir_les_logs(curl..'"'.. domoticzURL ..'/json.htm?type=createvirtualsensor&idx='..id..'&sensorname='..url_encode(dname)..'&sensortype='..sensortype..'"',debugging)
        os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=createvirtualsensor&idx='..id..'&sensorname='..url_encode(dname)..'&sensortype='..sensortype..'"')
        voir_les_logs("--- --- --- device   : ".. dname .. " créé --- --- ---",debugging)         
    end
end
--https://github.com/domoticz/domoticz/blob/development/hardware/hardwaretypes.h    
-------------------------------------------
-------------Fin Fonctions-----------------
-------------------------------------------