--[[   
appel de ces fonctions :
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"
ou
package.path = package.path..";"..debug.getinfo(1).source:match("@?(.*/)").."?.lua"	-- linux

require('fonctions_perso')
ou 
dofile('home/pi/domoticz/scripts/lua/fonctions/fonctions_perso.lua')
]]--  
-- Certaines fonctions proviennent du forums officiel https://www.domoticz.com/forum/viewtopic.php?f=23&t=7642&p=87659 
-- d'autres de vil1driver https://raw.githubusercontent.com/vil1driver/lua/master/modules.lua

domoticzIP = '127.0.0.1'
domoticzPORT = '8080'
domoticzUSER = ''		-- nom d'utilisateur
domoticzPSWD = ''		-- mot de pass
domoticzPASSCODE = ''	-- pour interrupteur protégés
domoticzURL = 'http://'..domoticzIP..':'..domoticzPORT
-- chemin vers le dossier lua
-- if (package.config:sub(1,1) == '/') then
	-- luaDir = debug.getinfo(1).source:match("@?(.*/)")
-- else
    -- luaDir = string.gsub(debug.getinfo(1).source:match("@?(.*\\)"),'\\','\\\\')
-- end
curl = '/usr/bin/curl -m 15 -u domoticzUSER:domoticzPSWD '		 	-- ne pas oublier l'espace à la fin
--json = assert(loadfile(luaDir..'JSON.lua'))()						-- chargement du fichier JSON.lua

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
end	-- usage voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
--============================================================================================== 
function format(str)
   if (str) then
      str = string.gsub (str, "De", "De ")
      str = string.gsub (str, " ", "&nbsp;")
      str = string.gsub (str, "Pas&nbsp;de&nbsp;précipitations", "<font color='#999'>Pas&nbsp;de&nbsp;précipitation</font>")
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
function url_encode(str) -- encode la chaine str pour la passer dans une url 
   if (str) then
   str = string.gsub (str, "\n", "\r\n")
   str = string.gsub (str, "([^%w ])",
   function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   end
   return str
end 
--============================================================================================== 
function sans_accent(str) -- supprime les accents de la chaîne str
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
function round(value, digits) -- arrondi
	
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
   function EnumClear(Text)   -- replace the last character
      a=string.len(Text)
      b=string.sub(Text,a,a)
      if b=="," or b==" " then Text=string.sub(Text,1,a-1) end
      a=string.len(Text)
      b=string.sub(Text,a,a)
      if b=="," or b==" " then Text=string.sub(Text,1,a-1) end
      return Text
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
--notification pushbullet
function pushbullet(title,body)
--	local settings = assert(io.popen(curl..'-u '..domoticzUSER..':'..domoticzPSWD..' "'..domoticzURL..'/json.htm?type=settings"'))
	local settings = assert(io.popen(curl..'-u "'..domoticzURL..'/json.htm?type=settings"'))    
	local list = settings:read('*all')
	settings:close()
	local pushbullet_key = json:decode(list).PushbulletAPI
	os.execute(curl..'-H \'Access-Token:'..pushbullet_key..'\' -H \'Content-Type:application/json\' --data-binary \'{"title":"'..title..'","body":"'..body..'","type":"note"}\' -X POST "https://api.pushbullet.com/v2/pushes"')
end--usage: pushbullet('test','ceci est un message test')
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
end -- usage : valeurs = split(variable,";")
--============================================================================================== 
function calc_wind_chill(temperature, wind_speed)-- Calculate wind chill.
-- If temperature is low but it's windy, the temperature
-- feels lower than the actual measured temperature. Wind chill formula from
-- <a href="http://www.nws.noaa.gov/om/windchill/">http://www.nws.noaa.gov/om/windchill/</a>.
-- @param temperature Temperature in Fahrenheit, must be 50 or less
-- @param wind_speed Wind speed in miles per hour
-- @return Wind chill of the given conditions, or nil if invalid input received	
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
function calc_heat_index(temperature, humidity)-- Calculate heat index.
-- If it's hot and humidity is high,
-- temperature feels higher than what it actually is. Heat index is
-- the approximation of the human-perceived temperature in hot and moist
-- conditions. Heat index formula from
-- <a href="http://www.ukscience.org/_Media/MetEquations.pdf">http://www.ukscience.org/_Media/MetEquations.pdf</a>.
-- @param temperature Temperature in Fahrenheit, must be 80 or more
-- @param humidity Relative humidity as a percentage value between 40 and 100
-- @return Heat index of the given conditions, or nil if invalid input received
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
function calc_apparent_temperature(temperature, wind_speed, humidity) -- Calculate wind chill or heat index corrected temperature
-- @param temperature Temperature in Fahrenheit
-- @param wind_speed Wind speed in miles per hour
-- @param humidity Relative humidity as a percentage value between 0 and 100
-- @return Apparent temperature given the weather conditions
-- @see calc_wind_chill
-- @see calc_heat_index	
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
function timeDiff(dName,dType) -- retourne le temps en seconde depuis la dernière maj du péréphérique (Variable 'v' ou Device 'd' 
        if dType == 'v' then 
            updTime = uservariables_lastupdate[dName]
        elseif dType == 'd' then
            updTime = otherdevices_lastupdate[dName]
        end 
        t1 = os.time()
	y, m, d, H, M, S = updTime:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")	
    t2 = os.time{year=y, month=m, day=d, hour=H, min=M, sec=S}
        tDiff = os.difftime(t1,t2)
        return tDiff
    end -- usage: timeDiff(name,'v|d')	
--============================================================================================== 
function TimeDiff2(Time1,Time2)  --gave to difference between now and the time that a devices is last changed in minutes 
      if string.len(Time1)>12 then Time1 = ConvTime(Time1) end
      if string.len(Time2)>12 then Time2 = ConvTime(Time2) end   
      ResTime=os.difftime (Time1,Time2)
      return ResTime
--usage : TDiff = Round(TimeDiff(os.time(),otherdevices_lastupdate[DeviceManual])/60,0)
   end
--============================================================================================== 
function TronquerTexte(texte, nb)  -- texte à tronquer, Nb maximum de caractère 
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
--============================================================================================== 
function creaVar(vname,vtype,vvalue) -- pour créer une variable de type 2 nommée toto comprenant la valeur 10
	os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(vname)..'&vtype='..vtype..'&vvalue='..url_encode(vvalue)..'" &')
end -- usage :  creaVar('toto','2','10')
--============================================================================================== 
function typeof(var) -- retourne le type de la variable 'string' ou 'number'
    local _type = type(var);
    if(_type ~= "table" and _type ~= "userdata") then
        return _type;
    end
    local _meta = getmetatable(var);
    if(_meta ~= nil and _meta._NAME ~= nil) then
        return _meta._NAME;
    else
        return _type;
    end
end
--============================================================================================== 
function speak(TTSDeviceName,txt) -- envoie dans un capteur text une chaîne de caractères qui sera interceptée et lue par la custom page grâce à sa fonction MQTT
	commandArray['OpenURL'] = domoticzIP..":"..domoticzPORT..'/json.htm?type=command&param=udevice&idx='..otherdevices_idx[TTSDeviceName]..'&nvalue=0&svalue='..url_encode(txt)
end -- usage: speak('tts','bonjour nous sommes dimanche')
--============================================================================================== 
local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
--print(BinaryFormat)
if BinaryFormat == "dll" then
    function os.name()
        return "Windows"
    end
elseif BinaryFormat == "so" then
    function os.name()
        return "Linux"
    end
elseif BinaryFormat == "dylib" then
    function os.name()
        return "MacOS"
    end
end
BinaryFormat = nil

--==============================================================================================
-- Obtenir le nom d'un device via son idx
function GetDeviceNameByIDX(deviceIDX) -- source https://www.domoticz.com/forum/viewtopic.php?t=18736#p144720
    deviceIDX = tonumber(deviceIDX)
   for i, v in pairs(otherdevices_idx) do
      if v == deviceIDX then
         return i
      end
   end
   return 0
end -- exemple usage = commandArray[GetDeviceNameByIDX(383)] = 'On'
--==============================================================================================
-- Obtenir l'idx d'un device via son nom
function GetDeviceIdxByName(deviceName) 
   for i, v in pairs(otherdevices_idx) do
      if i == deviceName then
         return v
      end
   end
   return 0
end -- exemple usage = commandArray['UpdateDevice'] = GetDeviceIdxByName('Compteur Gaz') .. '|0|' .. variable
--==============================================================================================
-------------------------------------------
-------------Fin Fonctions-----------------
-------------------------------------------