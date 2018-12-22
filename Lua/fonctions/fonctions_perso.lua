--[[ 
version 1.6
appel de ces fonctions :
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"
ou
package.path = package.path..";"..debug.getinfo(1).source:match("@?(.*/)").."?.lua"	-- linux

require('fonctions_perso')
ou 
dofile('home/pi/domoticz/scripts/lua/fonctions/fonctions_perso.lua')
]]-- Certaines fonctions sont les miennes 
-- d'autres proviennent du forums officiel https://www.domoticz.com/forum/viewtopic.php?f=23&t=7642&p=87659 
-- d'autres encore de vil1driver https://raw.githubusercontent.com/vil1driver/lua/master/modules.lua

domoticzIP = '127.0.0.1'
domoticzPORT = '8080'
domoticzUSER = ''		-- nom d'utilisateur
domoticzPSWD = ''		-- mot de pass
domoticzPASSCODE = ''	-- pour interrupteur protégés
domoticzURL = 'http://'..domoticzIP..':'..domoticzPORT
-- chemin vers le dossier lua
if (package.config:sub(1,1) == '/') then
	luaDir = debug.getinfo(1).source:match("@?(.*/)")
else
    luaDir = string.gsub(debug.getinfo(1).source:match("@?(.*\\)"),'\\','\\\\')
end
curl = '/usr/bin/curl -m 8 -u domoticzUSER:domoticzPSWD '		 	-- ne pas oublier l'espace à la fin
json = assert(loadfile(luaDir..'JSON.lua'))()						-- chargement du fichier JSON.lua

--------------------------------------------
-------------Fonctions----------------------
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
-------------------------------------------- 
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
-------------------------------------------- 
function url_encode(str) -- encode la chaine str pour la passer dans une url 
   if (str) then
   str = string.gsub (str, "\n", "\r\n")
   str = string.gsub (str, "([^%w ])",
   function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   end
   return str
end 
-------------------------------------------- 
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
-------------------------------------------- 
function accent_html(str) --remplace les caractères accentués par le code html 
    if (str) then
	str = string.gsub(str, "'", "&apos;")
	str = string.gsub(str, "â",	"&acirc;")
	str = string.gsub(str, "à",	"&agrave;")
	str = string.gsub(str, "é",	"&eacute;")
	str = string.gsub(str, "ê",	"&ecirc;")
	str = string.gsub(str, "è",	"&egrave;")
	str = string.gsub(str, "ë",	"&euml;")
	str = string.gsub(str, "î",	"&icirc;")
	str = string.gsub(str, "ï",	"&iuml;")
    str = string.gsub(str, "ô",	"&ocirc;")
	str = string.gsub(str, "ö",	"&ouml;")
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
-------------------------------------------- 
   function File_exists(file)  --Check if file exist
     local f = io.open(file, "rb")
     if f then f:close() end
     return f ~= nil
	--   if not File_exists(LogFile) then
   end
-------------------------------------------- 
function round(value, digits)
	if not value or not digits then
		return nil
	end
		local precision = 10^digits
        return (value >= 0) and
		  (math.floor(value * precision + 0.5) / precision) or
		  (math.ceil(value * precision - 0.5) / precision)
end
-------------------------------------------- 
function fahrenheit_to_celsius(fahrenheit, digits) 
    return round((5/9) * (fahrenheit - 32), digits or 2)
end
-------------------------------------------- 
function miles_to_km(miles, digits) 
    return round((miles * 1.609344), digits or 2)
end
-------------------------------------------- 
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
--------------------------------------------   
   function EnumClear(Text)   -- replace the last character
      a=string.len(Text)
      b=string.sub(Text,a,a)
      if b=="," or b==" " then Text=string.sub(Text,1,a-1) end
      a=string.len(Text)
      b=string.sub(Text,a,a)
      if b=="," or b==" " then Text=string.sub(Text,1,a-1) end
      return Text
   end
--------------------------------------------   
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

--notification pushbullet
function pushbullet(title,body)
--	local settings = assert(io.popen(curl..'-u '..domoticzUSER..':'..domoticzPSWD..' "'..domoticzURL..'/json.htm?type=settings"'))
	local settings = assert(io.popen(curl..'-u "'..domoticzURL..'/json.htm?type=settings"'))    
	local list = settings:read('*all')
	settings:close()
	local pushbullet_key = json:decode(list).PushbulletAPI
	os.execute(curl..'-H \'Access-Token:'..pushbullet_key..'\' -H \'Content-Type:application/json\' --data-binary \'{"title":"'..title..'","body":"'..body..'","type":"note"}\' -X POST "https://api.pushbullet.com/v2/pushes"')
end--usage: pushbullet('test','ceci est un message test')
-------------------------------------------- 
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
-- function split(s, delimiter)
    -- result = {};
    -- if delimiter == nil then
               -- delimiter = "%s"
    -- end
    -- for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        -- table.insert(result, match);
    -- end
    -- return result;
-- end -- usage : valeurs = split(variable,";")
-------------------------------------------- 
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
-------------------------------------------- 
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
--------------------------------------------
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
-------------------------------------------- 
function ConvTime(timestamp) -- convertir un timestamp 
   y, m, d, H, M, S = timestamp:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
   return os.time{year=y, month=m, day=d, hour=H, min=M, sec=S}
end
-------------------------------------------- 
function timeDiff(dName,dType) -- retourne le temps en seconde depuis la dernière maj du périphérique (Variable 'v' ou Device 'd' 
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
 --------------------------------------------    
function timedifference(s)
   year = string.sub(s, 1, 4)
   month = string.sub(s, 6, 7)
   day = string.sub(s, 9, 10)
   hour = string.sub(s, 12, 13)
   minutes = string.sub(s, 15, 16)
   seconds = string.sub(s, 18, 19)
   t1 = os.time()
   t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
   difference = os.difftime (t1, t2)
   return difference  --le résultat retourné est en secondes
end
--[[ usage : 
        DATE = "2018-04-29 16:57:18"
        print(timedifference(DATE)) 
--]]
--------------------------------------------
function year_difference(s)
    return tostring(os.date("%Y")) - tostring(s)
end
-------------------------------------------- 
function TimeDiff2(Time1,Time2)  --gave to difference between now and the time that a devices is last changed in minutes 
      if string.len(Time1)>12 then Time1 = ConvTime(Time1) end
      if string.len(Time2)>12 then Time2 = ConvTime(Time2) end   
      ResTime=os.difftime (Time1,Time2)
      return ResTime
--usage : TDiff = Round(TimeDiff(os.time(),otherdevices_lastupdate[DeviceManual])/60,0)
   end
-------------------------------------------- 
function TronquerTexte(texte, nb)  -- texte à tronquer, Nb maximum de caractère 
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
function creaVar(vname,vtype,vvalue) -- pour créer une variable de type 2 nommée toto comprenant la valeur 10
	os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(vname)..'&vtype='..vtype..'&vvalue='..url_encode(vvalue)..'" &')
end -- usage :  creaVar('toto','2','10')
-------------------------------------------- 
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
-------------------------------------------- 
function speak(TTSDeviceName,txt) -- envoie dans un capteur text une chaîne de caractères qui sera interceptée et lue par la custom page grâce à sa fonction MQTT
	commandArray['OpenURL'] = domoticzIP..":"..domoticzPORT..'/json.htm?type=command&param=udevice&idx='..otherdevices_idx[TTSDeviceName]..'&nvalue=0&svalue='..url_encode(txt)
end -- usage: speak('tts','bonjour nous sommes dimanche')
-------------------------------------------- 
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

--------------------------------------------
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
--------------------------------------------
-- Obtenir l'idx d'un device via son nom
-- function GetDeviceIdxByName(deviceName) 
   -- for i, v in pairs(otherdevices_idx) do
      -- if i == deviceName then
         -- return v
      -- end
   -- end
   -- return 0
-- end -- exemple usage = commandArray['UpdateDevice'] = GetDeviceIdxByName('Compteur Gaz') .. '|0|' .. variable
--remplacé par otherdevices_idx[nom_du_device]
--------------------------------------------

function UpdateDevice(DeviceName,value) -- mettre à jour un device nommé Mon dispositif avec la valeur 10 via curl
  idx  = GetDeviceIdxByName(DeviceName)
os.execute(curl..'"'.. domoticzURL ..'//json.htm?type=command&param=udevice&idx='..idx..'&nvalue=0&svalue='..value..'" &')
end -- usage :  UpdateDevice('Mon dispositif','10'
--------------------------------------------

function telegram(msg)
commandArray[#commandArray+1] = {['OpenURL'] = 'https://api.telegram.org/bot'..TELEGRAM_API_key..'/sendMessage?chat_id='..chat_ID .. '&text=' .. msg}
end
--usage : telegram("mon message")
--------------------------------------------
function hhmmss(seconde)
    heures = seconde / 3600
    heures = math.floor(heures)
    seconde = math.fmod(seconde, 3600)
    minutes = seconde / 60
    minutes = math.floor(minutes)
    secondes = math.fmod(seconde, 60)
    --result =  heures..':'..minutes..':'..secondes
    --print(result)
    return heures, minutes, secondes
end
--------------------------------------------
function hhmm(minute)
    heures = minute / 60
    heures = math.floor(heures)
    minutes = math.fmod(minute, 60)
    --result =  heures..'h'..minutes..'mn'
    --print(result)
    return heures, minutes
end
--------------------------------------------
function DeviceInfos(device)  
    
    -- inspiré de  http://www.domoticz.com/forum/viewtopic.php?f=61&t=15556&p=115795&hilit=otherdevices_SwitchTypeVal&sid=dda0949f5f3d71cb296b865a14827a34#p115795
    -- Attributs disponibles :
    -- AddjMulti; AddjMulti2; AddjValue; AddjValue2; BatteryLevel; CustomImage; Data; Description; Favorite; 
    -- HardwareID; HardwareName; HardwareType; HardwareTypeVal; HaveDimmer; HaveGroupCmd; HaveTimeout; ID; 
    -- Image; IsSubDevice; LastUpdate; Level; LevelInt; MaxDimLevel; Name; Notifications; PlanID; PlanIDs; 
    -- Protected; ShowNotifications; SignalLevel; Status; StrParam1; StrParam2; SubType; SwitchType; 
    -- SwitchTypeVal; Timers; Type; TypeImg; Unit; Used; UsedByCamera; XOffset; YOffset; idx
    
    config = assert(io.popen(curl..'"'.. domoticzURL ..'/json.htm?type=devices&rid='..otherdevices_idx[device]..'"'))
    blocjson = config:read('*all')
    config:close()
    jsonValeur = json:decode(blocjson)
    if jsonValeur ~= nil then
        return json:decode(blocjson).result[1]    
    end       
end 
    -- usage : 
        -- local attribut = DeviceInfos(cpt_djc)
        -- if attribut.SwitchTypeVal == 0 then    end
--------------------------------------------
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
        voir_les_logs("--- --- --- creation du device   : ".. dname .. " --- --- ---",debugging)
        voir_les_logs(curl..'"'.. domoticzURL ..'/json.htm?type=createvirtualsensor&idx='..id..'&sensorname='..url_encode(dname)..'&sensortype='..sensortype..'"',debugging)
        os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=createvirtualsensor&idx='..id..'&sensorname='..url_encode(dname)..'&sensortype='..sensortype..'"')

        voir_les_logs("--- --- --- device   : ".. dname .. " créé --- --- ---",debugging)         
    end
    -- else     
        -- local attribut = DeviceInfos(dname)
        -- if attribut then
            -- if attribut.SwitchTypeVal == 0 then
                -- voir_les_logs("--- --- --- modification du device RFXMeter  : ".. dname .. " en compteur de type 3  --- --- ---",debugging) 
                -- os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=setused&idx='..otherdevices_idx[dname]..'&name='..url_encode(dname)..'&switchtype=3&used=true"')
            -- end
        -- else
            -- voir_les_logs("--- --- --- impossible d\'extraire les caractéristiques du compteur ".. dname .."  --- --- ---",debugging)
        -- end
--https://github.com/domoticz/domoticz/blob/development/hardware/hardwaretypes.h

end        
--------------------------------------------
function ConvertCounter(devicename)
local attribut = DeviceInfos(devicename)
    if attribut then
        if attribut.SwitchTypeVal == 0 then
            voir_les_logs("--- --- --- modification du device RFXMeter  : ".. devicename .. " en compteur de type 3  --- --- ---",debugging) 
            os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=setused&idx='..otherdevices_idx[devicename]..'&name='..url_encode(devicename)..'&switchtype=3&used=true"')
        end
    else
        voir_les_logs("--- --- --- impossible d\'extraire les caractéristiques du compteur ".. devicename .."  --- --- ---",debugging)
    end
end 
--------------------------------------------
function validMACaddress(s)
    mac = s:match("(%w+:%w+:%w+:%w+:%w+:%w+)")
    if mac ~= nil then return mac end
end
--------------------------------------------
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

---------------------------------------
function rand(Table) -- retourne un élément d'une table au hasard
    t = Table[math.random(1, #Table)]
    return t
end


---------------------------------------
--- functions sur les tables---source https://love2d.org/forums/viewtopic.php?t=85140
--------------------------------------------

--- Checks if the table is empty
-- @param t Table
-- @return True if empty or false otherwise
local _cache = {}
function empty_table(t)
  return next(t) == nil
end

--- Removes all values
-- @param t Table
function clear_table(t)
  for i in pairs(t) do
    t[i] = nil
  end
end

--- Counts the number of elements
-- @param t Table
-- @return Total number of elements
function count_table(t)
  local n = 0
  for _ in pairs(t) do
    n = n + 1
  end
  return n
end

--- Counts the number of unique elements
--- The number of duplicate elements can be calculated
--- by subtracting the first return value from the second
-- @param t Table
-- @return Number of unique values
-- @return Total number of elements
function ucount_table(t)
  -- clear the cache
  clear_table(_cache)
  local n = 0
  local d = 0
  for _, v in pairs(t) do
    if _cache[v] then
      d = d + 1
    else
      _cache[v] = true
    end
    n = n + 1
  end
  return n - d, n
end

--- Counts the number of occurrences of a given value
-- @param t Table
-- @param v Value
-- @return Number of occurrences
-- @return Total number of elements
function vcount_table(t, s)
  assert(s ~= nil, "second argument cannot be nil")
  local n = 0
  local d = 0
  for _, v in pairs(t) do
    if v == s then
      d = d + 1
    end
    n = n + 1
  end
  return d, n
end

--- Reverses the elements in a list
-- @param t Table
-- @param r Destination table (optional)
-- @return Reversed table
function reverse_table(t, r)
  r = r or t
  local n = #t
  if t == r then
    -- reverse in place
    for i = 1, n/2 do
      local i2 = n - i + 1
      r[i], r[i2] = r[i2], r[i]
    end
  else
    -- reverse copy
    for i = 1, n do
      r[n - i + 1] = t[i]
    end
  end
  return r
end

--- Shuffles the elements in a list
-- @param t Table
-- @param r Destination table (optional)
-- @return Reversed table
local rand = math.random
function shuffle_table(t, r)
  r = r or t
  local n = #t
  -- shuffle copy
  if t ~= r then
    for i = 1, n do
      r[i] = t[i]
    end
  end
  -- shuffle in place
  for i = n, 1, -1 do
    local j = rand(n)
    r[i], r[j] = r[j], r[i]
  end
  return r
end

--- Finds the first occurrence in a list
-- @param t Table
-- @param s Search value
-- @param o Starting index (optional)
-- @return Numeric index or nil
function find_table(t, s, o)
  o = o or 1
  assert(s ~= nil, "second argument cannot be nil")
  for i = o, #t do
    if t[i] == s then
      return i
    end
  end
end

--- Finds the last occurrence in a list
-- @param t Table
-- @param s Search value
-- @param o Starting index (optional)
-- @return Numeric index or nil
function rfind_table(t, s, o)
  o = o or #t
  assert(s ~= nil, "second argument cannot be nil")
  -- iterate in reverse
  for i = o, 1, -1 do
    if t[i] == s then
      return i
    end
  end
end

--- Recursive deep copy (internal)
--- "cache" must be empty prior to calling this function
-- @param s Source table
-- @param d Destination table
local function dcopy_table(s, d)
  -- copy elements from the source table
  for k, v in pairs(s) do
    if type(v) == "table" then
      if _cache[v] then
        -- reference cycle
        d[k] = _cache[v]
      else
        -- recursive copy
        local d2 = d[k]
        if d2 == nil then
          d2 = {}
          d[k] = d2
        end
        _cache[v] = d2
        dcopy(v, d2)
      end
    else
      d[k] = v
    end
  end
end

--- Copies the contents from one table to another
--- Overwrites existing elements in the destination table
--- Preserves table cycles
-- @param s Source table
-- @param d Destination table (optional)
-- @return Resulting table
function copy_table(s, d)
  d = d or {}
  assert(s ~= d, "source and destination tables must be different")
  -- clear the cache
  clear_table(_cache)
  -- deep copy
  dcopy(s, d)
  return d
end

-------------------------------------------
-------------Fin Fonctions-----------------
-------------------------------------------
