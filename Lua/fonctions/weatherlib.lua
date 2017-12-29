-------------------------------------------------------------------------------
--https://github.com/travisjeffery/awesome-wm/blob/master/weatherlib.lua
-- Some weather related routines and solar calculations. Also provides
-- unit conversion routines.
-- <p>
-- This module derives code from GWeather library which is part of
-- the <a href="http://www.gnome.org">GNOME</a> project. GWeather is available
-- at <a href="http://ftp.gnome.org/pub/GNOME/sources/libgweather/">http://ftp.gnome.org/pub/GNOME/sources/libgweather/</a>
-- and it is licensed under the terms of the
-- <a href="http://www.gnu.org/licenses/gpl-2.0.html">GNU General Public License Version 2.0</a>.
-- </p>
-- <p>
-- This module derives code from the <a href="http://www.esrl.noaa.gov/gmd/grad/solcalc/">NOAA Solar Calculator</a>.
-- Original JavaScript code at the aforementioned site is placed under public domain.
-- </p>
-- @author Tuomas Jormola
-- @copyright 2011 Tuomas Jormola <a href="mailto:tj@solitudo.net">tj@solitudo.net</a> <a href="http://solitudo.net">http://solitudo.net</a>
--  Licensed under the terms of
-- the <a href="http://www.gnu.org/licenses/gpl-2.0.html">GNU General Public License Version 2.0</a>.
--
-------------------------------------------------------------------------------

local io       = { popen = io.popen }
local math     = { abs = math.abs, acos = math.acos, asin = math.asin, atan = math.atan, atan2 = math.atan2, cos = math.cos, floor = math.floor, fmod = math.fmod, pi = math.pi, pow = math.pow, sin = math.sin, sqrt = math.sqrt, tan = math.tan }
local os       = { date = os.date, time = os.time }
local pairs    = pairs
local string   = { format = string.format }
local tostring = tostring
local tonumber = tonumber
local type     = type

module('weatherlib')


-------------------------------------------------------------------------------
-- Round numeric value to given precisions
-- @param value Value to round
-- @param precision How many decimals in the rounded value, 0 by default
-- @return Rounded value
-- @usage mathlib.round(3.673242)    -- 4
-- @usage mathlib.round(3.673242, 3) -- 3.673
function round(value, precisions)
	if value == nil or type(value) ~= 'number' then
		return nil
	end
	if precisions == nil then
		precisions = 0
	end
	if type(precisions) ~= 'number' then
		return nil
	end
	if precisions == 0 then
		return math.floor(value + 0.5)
	end
	local value_string = tostring(value):gsub('^(-?%d+)\.?(%d*)', function(f, r)
				local rlen = r:len()
				if rlen <= precisions then
					return false
				end
				local fmt = '^('
				local i = 0
				while i <= precisions do
					if i == precisions then
						d = ')(%d)'
					else
						d = '%d'
					end
					fmt = string.format('%s%s', fmt, d)
					i = i + 1
				end
				fmt = string.format('%s%%d*$', fmt)
				r = r:gsub(fmt, function(a, b)
					local n = tostring(tonumber(a) + math.floor(tonumber('0.' .. b) + 0.5))
					while n:len() < a:len() do
						n = string.format('0%s', n)
					end
					return n
				end)
				return string.format('%s.%s', f, r)
			end)
	return tonumber(value_string)
end

-------------------------------------------------------------------------------
-- Temperature units table.
-- Values from this table can be used as indices to the conversion types in the conversion table.
-- @class table
-- @name TEMPERATURE_UNITS
-- @field CELCIUS Index value for Celcius
-- @field FAHRENHEIT Index value for Fahrenheit
TEMPERATURE_UNITS = {}
for i, unit in pairs({ 'CELCIUS', 'FAHRENHEIT' }) do
	TEMPERATURE_UNITS[unit] = i
end

-------------------------------------------------------------------------------
-- Speed units table.
-- Values from this table can be used as indices to the conversion types in the conversion table.
-- @class table
-- @name SPEED_UNITS
-- @field KNOT Index value for knot
-- @field MS Index value for meters per second
-- @field KMH Index value for kilometers per hour
-- @field MPH Index value for miles per hour
SPEED_UNITS = {}
for i, unit in pairs({ 'KNOT', 'MS', 'KMH', 'MPH' }) do
	SPEED_UNITS[unit] = i
end

-------------------------------------------------------------------------------
-- Pressure units table.
-- Values from this table can be used as indices to the conversion types in the conversion table.
-- @class table
-- @name PRESSURE_UNITS
-- @field HPA Index value for hectopascal
-- @field ATM Index value for standard atmosphere
-- @field INHG Index value for inches of Mercury
PRESSURE_UNITS = {}
for i, unit in pairs({ 'HPA', 'ATM', 'INHG' }) do
	PRESSURE_UNITS[unit] = i
end

-------------------------------------------------------------------------------
-- Length units table.
-- Values from this table can be used as indices to the conversion types in the conversion table.
-- @class table
-- @name LENGTH_UNITS
-- @field METER Index value for meter
-- @field KILOMETER Index value for kilometer
-- @field FOOT Index value for foot
-- @field YARD Index value for yard
-- @field MILE Index value for mile
LENGTH_UNITS = {}
for i, unit in pairs({ 'METER', 'KILOMETER', 'FOOT', 'YARD', 'MILE' }) do
	LENGTH_UNITS[unit] = i
end

-------------------------------------------------------------------------------
-- Time units table.
-- Values from this table can be used as indices to the conversion types in the conversion table.
-- @class table
-- @name TIME_UNITS
-- @field S Index value for second
-- @field M Index value for minute
-- @field H Index value for hour
TIME_UNITS = {}
for i, unit in pairs({ 'S', 'M', 'H' }) do
	TIME_UNITS[unit] = i
end

-------------------------------------------------------------------------------
-- Angle units table.
-- Values from this table can be used as indices to the conversion types in the conversion table.
-- @class table
-- @name ANGLE_UNITS
-- @field DEG Index value for degrees
-- @field RAD Index value for radians
-- @field HOUR Index value for hour
ANGLE_UNITS = {}
for i, unit in pairs({ 'DEG', 'RAD', 'HOUR' }) do
	ANGLE_UNITS[unit] = i
end

-------------------------------------------------------------------------------
-- Conversion type table.
-- Values from this table can be used as indices to the conversion table.
-- @class table
-- @name CONVERSION_TYPE
-- @field TEMPERATURE Index value temperature conversions
-- @field SPEED Index value for speed conversions
-- @field PRESSURE Index value for pressure conversions
-- @field LENGTH Index value for length conversions
-- @field TIME Index value for time conversions
-- @field ANGLE Index value for angle conversions
CONVERSION_TYPE = {}
for i, unit in pairs({ 'TEMPERATURE', 'SPEED', 'PRESSURE', 'LENGTH', 'TIME', 'ANGLE' }) do
	CONVERSION_TYPE[unit] = i
end

-------------------------------------------------------------------------------
-- Conversion table
-- @class table
-- @name conversion_table
-- @field temperature Temperature conversion routines
-- @field speed Speed conversion routines
-- @field pressure Pressure conversion routines
-- @field length Length conversion routines
-- @field time Time conversion routines
-- @field angle Angle conversion routines
conversion_table = {
	{ -- temperature
		{ -- Celcius
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round((v * 1.8) + 32, r or 1) end,
		},
		{ -- Fahrenheit
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round((v - 32) / 1.8, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
		},
	},
	{ -- speed
		{ -- knot
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round((v * 1.852) / 3.6, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 1.852, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round((v * 1.852) / 1.609344, r or 1) end,
		},
		{ -- m/s
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / (1.852 / 3.6), r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 3.6, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round((v * 3.6) / 1.609344, r or 1) end,
		},
		{ -- km/h
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 1.852, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 3.6, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 1.609344, r or 1) end,
		},
		{ -- mph
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round((v * 1.609344) / 1.852, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round((v * 1.609344) / 3.6, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 1.609344, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
		},
	},
	{ -- pressure
		{ -- hPa
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 1013.25, r or 2) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 33.8639, r or 2) end,
		},
		{ -- atm
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 1013.25, r or 2) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * (1 / 0.0334211), r or 2) end,
		},
		{ -- inHg
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 33.8639, r or 2) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 0.0334211, r or 2) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
		},
	},
	{ -- length
		{ -- meter
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 1000, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 0.3048, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 0.9144, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 1609.344, r or 1) end,
		},
		{ -- kilometer
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v * 1000 end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 0.0003048, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 0.0009144, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 1.609344, r or 1) end,
		},
		{ -- foot
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 0.3048, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 0.0003048, r or 2) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 3, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 5280, r or 2) end,
		},
		{ -- yard
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 0.9144, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 0.0009144, r or 2) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 3, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v / 1760, r or 2) end,
		},
		{ -- mile
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 1609.344, r) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 1.609344, r or 1) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 5280, r) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return round(v * 1760, r) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
		},
	},
	{ -- time
		{ -- seconds
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end local m = v % 60 v = v - m return (v / 60) + (m / 60) end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end local m = v % (60 * 60) v = v - m return (v / (60 * 60)) + (m / (60 * 60)) end,
		},
		{ -- minutes
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v * 60 end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end local m = v % 60 v = v - m return (v / 60) + (m / 60) end,
		},
		{ -- hours
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v * 60 * 60 end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v * 60 end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
		},
	},
	{ -- angle
		{ -- degrees
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return (math.fmod(v, 360) / 180) * math.pi end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return (math.fmod(v, 360) / 180) * 12 end,
		},
		{ -- radians
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v * 180 / math.pi end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v * 12 / math.pi end,
		},
		{ -- hours
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return (v / 12) * 180 end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return (v / 12) * math.pi end,
			function(v, r) if v == nil or type(v) ~= 'number' then return nil, 'Not a number' end return v end,
		},
	}
}

-------------------------------------------------------------------------------
-- Convert a value from a unit to another.
-- This is just a shortcut to <a href="#conversion_table">conversion_table[conversion_type][from_unit][to_unit](value)</code></a>.
-- @param conversion_type <a href="#CONVERSION_TYPE"><code>CONVERSION_TYPE</code></a> value indicating the type of the conversion
-- @param from_unit Value from the <code>*_UNITS</code> matching the conversion type indicating the unit in which the current value is
-- @param to_unit Value from the <code>*_UNITS</code> matching the conversion type indicating the unit to which the current value is to be converted
-- @param value Value to convert
-- @return Converted value if no errors, nil if an error occurred
-- @return Error string if an error occurred
function convert(conversion_type, from_unit, to_unit, value)
	if not conversion_table[conversion_type] then
		return nil, 'Invalid conversion type'
	end
	if not conversion_table[conversion_type][from_unit] then
		return nil, 'Invalid from unit'
	end
	if not conversion_table[conversion_type][from_unit][to_unit] then
		return nil, 'Invalid to unit'
	end
	return conversion_table[conversion_type][from_unit][to_unit](value)
end

-------------------------------------------------------------------------------
-- Convert temperature from a unit to another. This is just a shortcut to <a href="#convert"><code>convert(CONVERSION_TYPE.TEMPERATURE, from_unit, to_unit, value)</code></a>.
-- Convert temperature from a unit to another
-- @param from_unit <a href="#TEMPERATURE_UNITS"><code>TEMPERATURE_UNITS</code></a> value indicating the unit in which the current value is
-- @param to_unit <a href="#TEMPERATURE_UNITS"><code>TEMPERATURE_UNITS</code></a> value indicating the unit to which the current value is to be converted
-- @return Converted value if no errors, nil if an error occurred
-- @return Error string if an error occurred
-- @see convert
function convert_temperature(from_unit, to_unit, value)
	return convert(CONVERSION_TYPE.TEMPERATURE, from_unit, to_unit, value)
end

-------------------------------------------------------------------------------
-- Convert speed from a unit to another. This is just a shortcut to <a href="#convert"><code>convert(CONVERSION_TYPE.SPEED, from_unit, to_unit, value)</code></a>.
-- @param from_unit <a href="#SPEED_UNITS"><code>SPEED_UNITS</code></a> value indicating the unit in which the current value is
-- @param to_unit <a href="#SPEED_UNITS"><code>SPEED_UNITS</code></a> value indicating the unit to which the current value is to be converted
-- @return Converted value if no errors, nil if an error occurred
-- @return Error string if an error occurred
-- @see convert
function convert_speed(from_unit, to_unit, value)
	return convert(CONVERSION_TYPE.SPEED, from_unit, to_unit, value)
end

-------------------------------------------------------------------------------
-- Convert pressure from a unit to another. This is just a shortcut to <a href="#convert"><code>convert(CONVERSION_TYPE.PRESSURE, from_unit, to_unit, value)</code></a>.
-- Convert pressure from a unit to another
-- @param from_unit <a href="#PRESSURE_UNITS"><code>PRESSURE_UNITS</code></a> value indicating the unit in which the current value is
-- @param to_unit <a href="#PRESSURE_UNITS"><code>PRESSURE_UNITS</code></a> value indicating the unit to which the current value is to be converted
-- @return Converted value if no errors, nil if an error occurred
-- @return Error string if an error occurred
-- @see convert
function convert_pressure(from_unit, to_unit, value)
	return convert(CONVERSION_TYPE.PRESSURE, from_unit, to_unit, value)
end

-------------------------------------------------------------------------------
-- Convert length from a unit to another. This is just a shortcut to <a href="#convert"><code>convert(CONVERSION_TYPE.LENGTH, from_unit, to_unit, value)</code></a>.
-- Convert length from a unit to another
-- @param from_unit <a href="#LENGTH_UNITS"><code>LENGTH_UNITS</code></a> value indicating the unit in which the current value is
-- @param to_unit <a href="#LENGTH_UNITS"><code>LENGTH_UNITS</code></a> value indicating the unit to which the current value is to be converted
-- @return Converted value if no errors, nil if an error occurred
-- @return Error string if an error occurred
-- @see convert
function convert_length(from_unit, to_unit, value)
	return convert(CONVERSION_TYPE.LENGTH, from_unit, to_unit, value)
end

-------------------------------------------------------------------------------
-- Convert time from a unit to another. This is just a shortcut to <a href="#convert"><code>convert(CONVERSION_TYPE.TIME, from_unit, to_unit, value)</code></a>.
-- Convert time from a unit to another
-- @param from_unit <a href="#TIME_UNITS"><code>TIME_UNITS</code></a> value indicating the unit in which the current value is
-- @param to_unit <a href="#TIME_UNITS"><code>TIME_UNITS</code></a> value indicating the unit to which the current value is to be converted
-- @return Converted value if no errors, nil if an error occurred
-- @return Error string if an error occurred
-- @see convert
function convert_time(from_unit, to_unit, value)
	return convert(CONVERSION_TYPE.TIME, from_unit, to_unit, value)
end

-------------------------------------------------------------------------------
-- Convert angle from a unit to another. This is just a shortcut to <a href="#convert"><code>convert(CONVERSION_TYPE.ANGLE, from_unit, to_unit, value)</code></a>.
-- Convert angle from a unit to another
-- @param from_unit <a href="#ANGLE_UNITS"><code>ANGLE_UNITS</code></a> value indicating the unit in which the current value is
-- @param to_unit <a href="#ANGLE_UNITS"><code>ANGLE_UNITS</code></a> value indicating the unit to which the current value is to be converted
-- @return Converted value if no errors, nil if an error occurred
-- @return Error string if an error occurred
-- @see convert
function convert_angle(from_unit, to_unit, value)
	return convert(CONVERSION_TYPE.ANGLE, from_unit, to_unit, value)
end

-------------------------------------------------------------------------------
-- Calculate relative humidity.
-- Formula from <a href="http://www.gorhamschaffler.com/humidity_formulas.htm">http://www.gorhamschaffler.com/humidity_formulas.htm</a>.
-- @param temperature Temperature in Celcius
-- @param dewpoint Dewpoint in Celcius
-- @return Relative humidity as a percentage value between 0 and 100 or nil if invalid arguments
function calc_humidity(temperature, dewpoint)
	if not temperature or not dewpoint then
		return nil
	end
	local esat = 6.11 * math.pow(10, (7.5 * temperature) / (237.7 + temperature))
	local esurf = 6.11 * math.pow(10, (7.5 * dewpoint) / (237.7 + dewpoint))
	return round((esurf / esat) * 100)
end

-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- Calculate timezone offset from UTC in seconds for the given timezone.
-- Uses external command date(1). Takes Daylight Saving Time into account
-- if the local date command supports that. Tested only on Ubuntu Linux 10.04
-- and Solaris 10 operating systems. May not be very portable.
-- @param timezone Timezone name, e.g. Europe/Helsinki, Asia/Bangkok, US/Pacific
-- @return Timezone offset in seconds from UTC. Positive for timezones ahead
-- of UTC, negative for timezones behind UTC.
-- @usage weatherlib.calc_timezone_offset('Europe/Helsinki') -- 7200
-- @usage weatherlib.calc_timezone_offset('Asia/Bangkok')    -- 28800
-- @usage weatherlib.calc_timezone_offset('US/Pacific')      -- -28800
function calc_timezone_offset(timezone)
	local timezone_command = 'date +%z'
	if timezone then
		timezone_command = string.format('TZ="%s" %s', timezone, timezone_command)
	end
	local fd = io.popen(timezone_command)
	local timezone_string = fd:read('*l'):gsub('\n*$', '')
	fd:close()
	local sign, hours, minutes = timezone_string:match('^([+-])(%d%d)(%d%d)$')
	if sign and hours and minutes then
		sign = tonumber(sign .. '1')
		hours = tonumber(hours) * sign
		minutes = tonumber(minutes) * sign
		return (60 * 60 * hours) + (60 * minutes)
	end
	return nil
end

-- Moon phase stuff from GWeather

local LUNAR_MEAN_LONGITUDE    = 218.316
local LUNAR_PERIGEE_MEAN_LONG = 318.15
local LUNAR_NODE_MEAN_LONG    = 125.08
local LUNAR_PROGRESSION       = 13.176358
local LUNAR_INCLINATION       = convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, 5.145396)

local function epoch_to_january_2000(t)
	return t - 946727935.816
end

local function mean_ecliptic_longitude(d)
	return 280.46457166 + d / 36525 * 35999.37244981
end

local function perigee_longitude(d)
	return 282.93768193 + d / 36525 * 0.32327364
end

local function eccentricity(d)
	return 0.01671123 - d / 36525 * 0.00004392
end

local function sun_ecliptic_longitude(t)
	if type(t) == 'table' then
		t = os.time(t)
	end

	-- Start with an estimate based on a fixed daily rate
	local ndays = epoch_to_january_2000(t) / 86400
	local meanAnom = convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD,
			mean_ecliptic_longitude(ndays) - perigee_longitude(ndays))

	-- Approximate solution of Kepler's equation:
	-- Find E which satisfies  E - e sin(E) = M (mean anomaly)
	local eccenAnom = meanAnom
	local e = eccentricity(ndays)

	local delta = eccenAnom - e * math.sin(eccenAnom) - meanAnom
	while 1e-12 < math.abs(delta) do
		eccenAnom = eccenAnom - delta / (1 - e * math.cos(eccenAnom))
		delta = eccenAnom - e * math.sin(eccenAnom) - meanAnom
	end

	-- Earth's longitude on the ecliptic
	longitude = math.fmod(convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD,
			perigee_longitude(ndays)) + 2 * math.atan(math.sqrt((1 + e) / (1 - e)) * math.tan(eccenAnom / 2)), 2 * math.pi)
	if longitude < 0 then
		longitude = longitude + 2 * math.pi
	end

	return longitude
end

local function ecliptic_obliquity(t)
	if type(t) == 'table' then
		t = os.time(t)
	end

	local jc = epoch_to_january_2000(t) / (36525 * 86400)
	local eclip_secs = 84381.448 - (46.84024 * jc) - (59.e-5 * jc * jc) + (1.813e-3 * jc * jc * jc)
	return convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, eclip_secs / 3600)
end

local function ecl2equ(t, eclipLon, eclipLat)
	local mEclipObliq = ecliptic_obliquity(t)

	local ra = convert_angle(ANGLE_UNITS.RAD, ANGLE_UNITS.HOUR, math.atan2((math.sin (eclipLon) * math.cos (mEclipObliq) - math.tan (eclipLat) * math.sin(mEclipObliq)), math.cos (eclipLon)))
	if ra < 0 then
		ra = ra + 24
	end
	local decl = math.asin((math.sin(eclipLat) * math.cos(mEclipObliq)) + math.cos(eclipLat) * math.sin(mEclipObliq) * math.sin(eclipLon))
	return ra, decl
end

-------------------------------------------------------------------------------
-- Calculate moon phase and latitude at given time
-- @param t Seconds since epoch or os.date table, universal time
-- @return Moon phase in degrees between 0 and 360
-- @return Moon latitude
function calc_moon(t)
	if type(t) == 'table' then
		t = os.time(t)
	end

	local ndays = epoch_to_january_2000(t) / 86400
	local sunMeanAnom_d = math.fmod(mean_ecliptic_longitude(ndays) - perigee_longitude(ndays), 360)
	local sunEclipLong_r = sun_ecliptic_longitude (t)
	--  5: moon's mean anomaly
	local moonLong_d = math.fmod(LUNAR_MEAN_LONGITUDE + (ndays * LUNAR_PROGRESSION), 360)
	--  6: ascending node mean longitude
	local moonMeanAnom_d = math.fmod(moonLong_d - (0.1114041 * ndays) - (LUNAR_PERIGEE_MEAN_LONG + LUNAR_NODE_MEAN_LONG), 360)
	local ascNodeMeanLong_d = math.fmod (LUNAR_NODE_MEAN_LONG - (0.0529539 * ndays), 360)
	--  7: eviction
	local eviction_d = 1.2739 * math.sin(convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, 2 * (moonLong_d - convert_angle(ANGLE_UNITS.RAD, ANGLE_UNITS.DEG, sunEclipLong_r)) - moonMeanAnom_d))
	local sinSunMeanAnom = math.sin(convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, sunMeanAnom_d))
	local Ae = 0.1858 * sinSunMeanAnom
	--  8: annual equation
	local A3 = 0.37   * sinSunMeanAnom
	--  9: "third correction"
	moonMeanAnom_d = moonMeanAnom_d + eviction_d - Ae - A3
	local moonMeanAnom_r = convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, moonMeanAnom_d)
	-- 10: equation of center
	local Ec = 6.2886 * math.sin (moonMeanAnom_r)
	-- 11: "yet another correction"
	local A4 = 0.214 * math.sin (2 * moonMeanAnom_r)

	-- Steps 12-14 give the true longitude after correcting for variation
	moonLong_d = moonLong_d + eviction_d + Ec - Ae + A4 + (0.6583 * math.sin(2 * (moonMeanAnom_r - sunEclipLong_r)))

	-- 15: corrected longitude of node
	local corrLong_d = ascNodeMeanLong_d - 0.16 * sinSunMeanAnom

	-- Calculate ecliptic latitude (16-19) and longitude (20) of the moon,
	-- then convert to right ascension and declination.
	-- l''-N'
	local lN_r = convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, moonLong_d - corrLong_d)
	local lambda_r = convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, corrLong_d) + math.atan2(math.sin(lN_r) * math.cos(LUNAR_INCLINATION),  math.cos(lN_r))
	local beta_r = math.asin(math.sin(lN_r) * math.sin(LUNAR_INCLINATION))
	local ra_h, decl_r = ecl2equ (t, lambda_r, beta_r)

	-- The phase is the angle from the sun's longitude to the moon's 
	local moonphase = math.fmod(15 * ra_h - convert_angle(ANGLE_UNITS.RAD, ANGLE_UNITS.DEG, sunEclipLong_r), 360)
	if moonphase < 0 then
		moonphase = moonphase + 360
	end
	local moonlatitude = convert_angle(ANGLE_UNITS.RAD, ANGLE_UNITS.DEG, decl_r)
	return moonphase, moonlatitude
end

-- Solar Calculation stuff from
-- http://www.esrl.noaa.gov/gmd/grad/solcalc/

local function is_leap_year(yr)
	return ((yr % 4 == 0 and yr % 100 ~= 0) or yr % 400 == 0)
end

local days_in_months = {
	31,
	28,
	31,
	30,
	31,
	30,
	31,
	31,
	30,
	31,
	30,
	31,
}

local function calc_julian_date(date)
	local year, month, day = date.year, date.month, date.day
	if is_leap_year(year) and month == 2 then
		if day > 29 then
			day = 29
		end
	 else
		if day > days_in_months[month] then
			day = days_in_months[month]
		end
	end
	if month <= 2 then
		year = year - 1
		month = month + 12
	end
	local A = math.floor(year / 100)
	local B = 2 - A + math.floor(A / 4)
	local jd = math.floor(365.25 * (year + 4716)) + math.floor(30.6001 * (month + 1)) + day + B - 1524.5
	return jd
end

local function calc_date_from_julian_date(jd)
	local z = math.floor(jd + 0.5)
	local f = (jd + 0.5) - z
	local A
	if z < 2299161 then
		A = z
	else
		local alpha = math.floor((z - 1867216.25) / 36524.25)
		A = z + 1 + alpha - math.floor(alpha / 4)
	end
	local B = A + 1524
	local C = math.floor((B - 122.1) / 365.25)
	local D = math.floor(365.25 * C)
	local E = math.floor((B - D) / 30.6001)
	local day = B - D - math.floor(30.6001 * E) + f
	local month
	if E < 14 then
		month = E - 1
	else
		month = E - 13
	end
	local year
	if month > 2 then
		year = C - 4716
	else
		year = C - 4715
	end
	local date = os.date('*t')
	date.sec = 0
	date.min = 0
	date.hour = 0
	date.day = day
	date.month = month
	date.year = year
	return date
end
	
local function calc_day_of_the_year_from_julian_date(jd)
	local date = calc_date_from_julian_date(jd)
	local k = 2
	if (is_leap_year(date.year)) then
		k = 1
	end
	local doy = math.floor((275 * date.month) / 9) - k * math.floor((date.month + 9) / 12) + date.day - 30
	return doy
end

local function calc_julian_century(jd)
	return (jd - 2451545) / 36525
end

local function calc_mean_obliquity_of_ecliptic(t)
	local seconds = 21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))
	local e0 = 23 + (26 + (seconds / 60)) / 60
	return e0		-- in degrees
end

local function calc_obliquity_correction(t)
	local e0 = calc_mean_obliquity_of_ecliptic(t)
	local omega = 125.04 - 1934.136 * t
	local e = e0 + 0.00256 * math.cos(convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, omega))
	return e		-- in degrees
end

local function calc_sun_mean_longitude(t)
	local L0 = 280.46646 + t * (36000.76983 + t * (0.0003032))
	while L0 > 360 do
		L0 = L0 - 360
	end
	while L0 < 0 do
		L0 = L0 + 360
	end
	return L0		-- in degrees
end

function calc_earth_orbit_eccentricity(t)
	local e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
	return e		-- unitless
end

local function calc_sun_geometry_mean_anomaly(t)
	local M = 357.52911 + t * (35999.05029 - 0.0001537 * t)
	return M		-- in degrees
end

local function calc_equation_of_time(t)
	local epsilon = calc_obliquity_correction(t)
	local l0 = calc_sun_mean_longitude(t)
	local e = calc_earth_orbit_eccentricity(t)
	local m = calc_sun_geometry_mean_anomaly(t)

	local y = math.tan(convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, epsilon) / 2)
	y = y * y

	local sin2l0 = math.sin(2 * convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, l0))
	local sinm   = math.sin(convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, m))
	local cos2l0 = math.cos(2 * convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, l0))
	local sin4l0 = math.sin(4 * convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, l0))
	local sin2m  = math.sin(2 * convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, m))

	local Etime = y * sin2l0 - 2 * e * sinm + 4 * e * y * sinm * cos2l0 - 0.5 * y * y * sin4l0 - 1.25 * e * e * sin2m
	return convert_angle(ANGLE_UNITS.RAD, ANGLE_UNITS.DEG, Etime) * 4 -- in minutes of time
end

local function calc_sun_mean_longitude(t)
	local L0 = 280.46646 + t * (36000.76983 + t * 0.0003032)
	while L0 > 360 do
		L0 = L0 - 360
	end
	while L0 < 0 do
		L0 = L0 + 360
	end
	return L0		-- in degrees
end

local function calc_sun_equation_of_center(t)
	local m = calc_sun_geometry_mean_anomaly(t)
	local mrad = convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, m)
	local sinm = math.sin(mrad)
	local sin2m = math.sin(mrad+mrad)
	local sin3m = math.sin(mrad+mrad+mrad)
	local C = sinm * (1.914602 - t * (0.004817 + 0.000014 * t)) + sin2m * (0.019993 - 0.000101 * t) + sin3m * 0.000289
	return C		-- in degrees
end

local function calc_sun_true_longitude(t)
	local l0 = calc_sun_mean_longitude(t)
	local c = calc_sun_equation_of_center(t)
	local O = l0 + c
	return O		-- in degrees
end

local function calc_sun_apparent_longitude(t)
	local o = calc_sun_true_longitude(t)
	local omega = 125.04 - 1934.136 * t
	local lambda = o - 0.00569 - 0.00478 * math.sin(convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, omega))
	return lambda		-- in degrees
end

local function calc_sun_declination(t)
	local e = calc_obliquity_correction(t)
	local lambda = calc_sun_apparent_longitude(t)

	local sint = math.sin(convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, e)) * math.sin(convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, lambda))
	local theta = convert_angle(ANGLE_UNITS.RAD, ANGLE_UNITS.DEG, math.asin(sint))
	return theta		-- in degrees
end

local function calc_sunrise_hour_angle(lat, solar_dec)
	local lat_rad = convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, lat)
	local sd_rad  = convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, solar_dec)
	local ha_arg = (math.cos(convert_angle(ANGLE_UNITS.DEG, ANGLE_UNITS.RAD, 90.833)) / (math.cos(lat_rad) * math.cos(sd_rad)) - math.tan(lat_rad) * math.tan(sd_rad))
	local ha = math.acos(ha_arg)
	return ha		-- in radians (for sunset, use -ha)
end

local function calc_sunrise_or_sunset_julian_utc(is_rise, jd, latitude, longitude)
	local t = calc_julian_century(jd)
	local eq_time = calc_equation_of_time(t)
	local solar_dec = calc_sun_declination(t)
	local hour_angle = calc_sunrise_hour_angle(latitude, solar_dec)
	if not is_rise then
		hour_angle = -hour_angle
	end
	local delta = longitude + convert_angle(ANGLE_UNITS.RAD, ANGLE_UNITS.DEG, hour_angle)
	local time_utc = 720 - (4 * delta) - eq_time	-- in minutes
	return time_utc
end

local function is_number(value)
	return type(value) == 'number' and value == value
end

local function calc_time_object(minutes, date)
	if minutes >= 0 and minutes < 1440 then
		local float_hour = minutes / 60
		local hour = math.floor(float_hour)
		local float_minute = 60 * (float_hour - math.floor(float_hour))
		local minute = math.floor(float_minute)
		local float_sec = 60 * (float_minute - math.floor(float_minute))
		local second = math.floor(float_sec + 0.5)
		if second > 59 then
			second = 0
			minute = minute + 1
		end
		if second >= 30 then
			minute = minute + 1
		end
		if minute > 59 then
			minute = 0
			hour = hour + 1
		end
		local time_object = os.date('*t')
		time_object.sec = second
		time_object.min = minute
		time_object.hour = hour
		time_object.day = date.day
		time_object.month = date.month
		time_object.year = date.year
		return os.date('*t', os.time(time_object))
	else
		return nil
	end
end

local function calc_time_date_object(jd, minutes, date)
	local time_object = calc_time_object(minutes, date)
	local date_object = calc_date_from_julian_date(jd)
	date_object.sec = time_object.sec
	date_object.min = time_object.min
	date_object.hour = time_object.hour
	return date_object
end

local function calc_next_prev_sunrise_or_sunset(is_next, is_rise, jd, latitude, longitude, tz, is_dst)
	is_dst = is_dst or false
	local julian_day = jd
	local increment = -1
	if is_next then
		increment = 1
	end

	local time = calc_sunrise_or_sunset_julian_utc(is_rise, julian_day, latitude, longitude)
	while not is_number(time) do
		julian_day = julian_day + increment
		time = calc_sunrise_or_sunset_julian_utc(is_rise, julian_day, latitude, longitude)
	end
	local time_local = time + tz * 60
	if is_dst then
		time_local = time_local + 60
	end
	while time_local < 0 or time_local >= 1440 do
		local incr = -1
		if time_local < 0 then
			incr = 1
		end
		time_local = time_local + (incr * 1440)
		julian_day = julian_day - incr
	end
	return julian_day
end

function calc_sunrise_or_sunset(is_rise, date, latitude, longitude, timezone)
	local jd = calc_julian_date(date)
	local time_utc = calc_sunrise_or_sunset_julian_utc(is_rise, jd, latitude, longitude)
	local new_time_utc = calc_sunrise_or_sunset_julian_utc(is_rise, jd + time_utc / 1440, latitude, longitude)
	local julian_day
	if is_number(new_time_utc) then
		local time_local = new_time_utc + (timezone * 60)
		if date.isdst then
			time_local = time_local + 60
		end
		if time_local >= 0 and time_local < 1440 then
			return calc_time_object(time_local, date)
		else
			local julian_day = jd
			local increment = -1
			if time_local < 0 then
				increment = 1
			end
			while time_local < 0 or time_local >= 1440 do
				time_local = time_local + (increment * 1440)
				julian_day = julian_day - increment
			end
			return calc_time_date_object(julian_day, time_local, date)
		end
	else -- no sunrise/set found
		local doy = calc_day_of_the_year_from_julian_date(jd)
		if (latitude > 66 and doy > 79 and doy < 267) or (latitude < -66.4 and (doy < 83 or doy > 263)) then
			--previous sunrise/next sunset
			if is_rise then -- find previous sunrise
				julian_day = calc_next_prev_sunrise_or_sunset(false, is_rise, jd, latitude, longitude, timezone, date.isdst)
			else -- find next sunset
				julian_day = calc_next_prev_sunrise_or_sunset(true, is_rise, jd, latitude, longitude, timezone, date.isdst)
			end
			return calc_date_from_julian_date(julian_day)
		else   --previous sunset/next sunrise
			if is_rise then -- find previous sunrise
				julian_day = calc_next_prev_sunrise_or_sunset(true, is_rise, jd, latitude, longitude, timezone, date.isdst)
			else -- find next sunset
				julian_day = calc_next_prev_sunrise_or_sunset(false, is_rise, jd, latitude, longitude, timezone, date.isdst)
			end
			return calc_date_from_julian_date(julian_day)
		end
	end
end

-------------------------------------------------------------------------------
-- Calculate the time of sunrise at the given date and location.
-- Routines from the JavaScript code at <a href="http://www.esrl.noaa.gov/gmd/grad/solcalc/">http://www.esrl.noaa.gov/gmd/grad/solcalc/</a>.
-- @param date an os.date table representing the date for which to calculate the time of sunrise
-- @param latitude Latitude of the location
-- @param longitude Longitude of the location
-- @param timezone Timezone as an offset in hours from UTC at the given location
-- @return os.date table that holds the date and time when sunrise occurs
function calc_sunrise(date, latitude, longitude, timezone)
	return calc_sunrise_or_sunset(true, date, latitude, longitude, timezone)
end

-------------------------------------------------------------------------------
-- Calculate the time of sunset at the given date and location.
-- Routines from the JavaScript code at <a href="http://www.esrl.noaa.gov/gmd/grad/solcalc/">http://www.esrl.noaa.gov/gmd/grad/solcalc/</a>.
-- @param date an os.date table representing the date for which to calculate the time of sunset
-- @param latitude Latitude of the location
-- @param longitude Longitude of the location
-- @param timezone Timezone as an offset in hours from UTC at the given location
-- @return os.date table that holds the date and time when sunset occurs
function calc_sunset(date, latitude, longitude, timezone)
	return calc_sunrise_or_sunset(false, date, latitude, longitude, timezone)
end
