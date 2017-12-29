--- weathermetrics module for Lua 5.1.
-- 
-- weathermetrics includes functions to calculate dew point
-- temperature, relative humidity, and heat index and to convert
-- between Celsius and Fahrenheit. All functions are based on
-- equations and algorithms used by the United States National
-- Weather Service.
-- License: MIT
-- @author Brooke Anderson
-- @author Roger Peng
-- @author Ported to Lua by John W. Cocula
-- @release 1.0

module("weathermetrics", package.seeall);



FAHRENHEIT = "F"
CELSIUS = "C"

----------------------------------------------------------------------------
-- Round a numeric value to the specified number of digits.
-- @usage round(value, digits)
-- @param value the value to round
-- @param digits the number of digits to preserve
-- @return the rounded value

function round(value, digits)
  local precision = 10^digits
  return (value >= 0) and
      (math.floor(value * precision + 0.5) / precision) or
      (math.ceil(value * precision - 0.5) / precision)
end

----------------------------------------------------------------------------
-- Convert from Celsius to Fahrenheit.
-- Create a temperature in Fahrenheit from a temperature in Celsius.
-- Equations are from the source code for the
-- <a href="http://www.hpc.ncep.noaa.gov/html/heatindex.shtml">US National Weather Service's 
-- online heat index calculator</a>.
-- @usage celsius_to_fahrenheit(celsius, digits)
-- @param celsius a temperature value in Celsius
-- @param digits number of digits to round converted value (defaults to 2)
-- @return a temperature in Fahrenheit from a temperature in Celsius
-- @see fahrenheit_to_celsius

function celsius_to_fahrenheit(celsius, digits) 
  return round((9/5) * celsius + 32, digits or 2)
end

----------------------------------------------------------------------------
-- Create a relative humidity value from air temperature and dew point temperature values.
-- Dew point temperature and temperature must be in the same metric (i.e., either both in 
-- Celsius or both in Fahrenheit). If necessary, use <code>fahrenheit_to_celsius</code> or 
-- <code>celsius_to_fahrenheit</code> to convert before using this function.
-- Equations are from the source code for the 
-- <a href="http://www.hpc.ncep.noaa.gov/html/heatindex.shtml">US National Weather Service's 
-- online heat index calculator</a>.
-- @usage dewpoint_to_humidity(dp, t, temperature_metric)
-- @param dp dew point temperature
-- @param t air temperature
-- @param temperature_metric temperature metric for both air temperature and dew point 
-- temperature, possible values: <code>FAHRENHEIT</code> or <code>CELSIUS</code> 
-- (defaults to <code>FAHRENHEIT</code>)
-- @return relative humidity (in %)
-- @return if the first return value is <code>nil</code>, the second return value contains
-- a message explaining why
-- @see fahrenheit_to_celsius 
-- @see celsius_to_fahrenheit
-- @see humidity_to_dewpoint

function dewpoint_to_humidity(dp, t, temperature_metric) 
  temperature_metric = temperature_metric or FAHRENHEIT

  if temperature_metric ~= CELSIUS and temperature_metric ~= FAHRENHEIT then
    return nil, "The 'temperature_metric' option can only by CELSIUS or FAHRENHEIT."
  end
  if dp > t then
    return nil, "Dew point temperature was higher than temperature. Since dew point temperature cannot be higher than air temperature, relative humidty was set to nil."
  end

  if temperature_metric == FAHRENHEIT then
    t = fahrenheit_to_celsius(t)
    dp = fahrenheit_to_celsius(dp)
  end

  return 100 * ((112 - (0.1 * t) + dp)/(112 + (0.9 * t)))^8
end

----------------------------------------------------------------------------
-- Convert from Fahrenheit to Celsius.
-- Create a temperature in Celsius from a temperature in Fahrenheit.
-- Equations are from the source code for the
-- <a href="http://www.hpc.ncep.noaa.gov/html/heatindex.shtml">US National Weather Service's 
-- online heat index calculator</a>.
-- @usage fahrenheit_to_celsius(fahrenheit, round)
-- @param fahrenheit a temperature value in Fahrenheit
-- @param digits number of digits to round converted value (defaults to 2)
-- @return a temperature in Celsius from a temperature in Fahrenheit
-- @see celsius_to_fahrenheit

function fahrenheit_to_celsius(fahrenheit, digits) 
    return round((5/9) * (fahrenheit - 32), digits or 2)
end

local function heat_index_algorithm(t, rh)
  if not tonumber(rh) or not tonumber(t) then
    return
  elseif t <= 40 then
    return t
  else
    local alpha = 61 + ((t - 68) * 1.2) + (rh * 0.094)
    local hi = 0.5*(alpha + t)
    if hi > 79 then
      hi = -42.379 + 2.04901523 * t + 10.14333127 * rh - 
          0.22475541 * t * rh - 6.83783 * 10^-3 * t^2 - 
          5.481717 * 10^-2 * rh^2 + 1.22874 * 10^-3 * t^2 * 
          rh + 8.5282 * 10^-4 * t * rh^2 - 1.99 * 10^-6 * 
          t^2 * rh^2
      if rh <= 13 and t >= 80 and t <= 112 then
        local adjustment1 = (13 - rh)/4
        local adjustment2 = math.sqrt((17 - abs(t - 95))/17)
        local total_adjustment = adjustment1 * adjustment2
        hi = hi - total_adjustment
      elseif rh > 85 and t >= 80 and t <= 87 then
        local adjustment1 = (rh - 85)/10
        local adjustment2 = (87 - t)/5
        local total_adjustment = adjustment1 * adjustment2
        hi = hi + total_adjustment
      end
    end
    return hi
  end
end

----------------------------------------------------------------------------
-- Calculate heat index.
-- Create a heat index value from air temperature and either 
-- relative humidity or dew point temperature values.
-- Include air temperature <code>t</code>  and either dew point temperature <code>dp</code>  or relative 
-- humdity <code>rh</code> . You cannot specify both dew point temperature and relative humidity- 
-- this will return an error. Heat index is calculated as nil when impossible values of 
-- dew point temperature or humidity are inputted (e.g., humidity above 100% or below 0%, 
-- dew point temperature above air temperature).
-- @usage heat.index(t, dp, rh, temperature_metric, output_metric, round)
-- @param t air temperature
-- @param dp dew point temperature
-- @param rh relative humidity (in %)
-- @param temperature_metric temperature metric for air temperature and, if you're using it,
-- dew point temperature; value can be either <code>FAHRENHEIT</code> or <code>CELSIUS</code>
-- @param output_metric metric heat index should be calculated in, either 
-- <code>FAHRENHEIT</code> or <code>CELSIUS</code>
-- @param digits the number of digits to round the heat index to
-- @return A heat index value in the metric specified by <code>output_metric</code> 
-- (if <code>output_metric</code> is not specified, heat index will be returned in the same 
-- metric in which air temperature was input, specified by <code>temperature_metric</code>)
-- @return if the heat index value is <code>nil</code>, the second return value will be a
-- message explaining why.

function heat_index(t, dp, rh, temperature_metric, output_metric, digits) 
  output_metric = output_metric or temperature_metric

  if not tonumber(dp) and not tonumber(rh) then
    return nil, "You must give values for either dew point temperature ('dp') or relative humidity ('rh')."
  elseif tonumber(dp) and tonumber(rh) then
    return nil, "You can give values for either dew point temperature ('dp') or relative humidity ('rh'), but you cannot specify both to this function."
  end

  if tonumber(dp) then
    rh = dewpoint_to_humidity(t, dp, temperature_metric)
  elseif rh > 100 or rh < 0 then
    return nil, "There was an impossible value for relative humidity (below 0% or above 100%). For this observation, heat index was set to nil."
  end

  if temperature_metric == CELSIUS then
    t = celsius_to_fahrenheit(t)
  end

  local hi = heat_index_algorithm(t, rh)

  if tonumber(hi) then
    if output_metric == CELSIUS then
      hi = fahrenheit_to_celsius(hi)
    end
    hi = round(hi, digits)
  end
  
  return hi
end

----------------------------------------------------------------------------
-- Calculate dew point temperature.
-- Create a dew point temperature from air temperature and relative humidity.
-- Dew point temperature will be calculated in the same metric as the temperature
-- (as specified by the <code>temperature_metric</code> option). If you'd like dew point 
-- temperature in a different metric, use the function <code>celsius_to_fahrenheit</code> or 
-- <code>fahrenheit_to_celsius</code> on the output from this function.
-- @usage humidity_to_dewpoint(t, rh, temperature_metric)
-- @param t air temperature
-- @param rh vector of relative humidity (in %)
-- @param temperature_metric temperature metric for air temperature, either <code>FAHRENHEIT</code>
--        or <code>CELSIUS</code> (defaults to <code>FAHRENHEIT</code>)
-- @return the dew point temperatre
-- @return if the first return value is <code>nil</code>, the second return value contains a message
-- explaining why.
-- @see fahrenheit_to_celsius 
-- @see celsius_to_fahrenheit

function humidity_to_dewpoint(t, rh, temperature_metric)
  temperature_metric = temperature_metric or FAHRENHEIT
  if temperature_metric ~= CELSIUS and temperature_metric ~= FAHRENHEIT then
    return nil, "The 'temperature_metric' option can only by CELSIUS or FAHRENHEIT."
  elseif rh < 0 or rh > 100 then
    return nil, "Relative humidity was below 0% or above 100%. Since these values are impossible for relative humidity, dew point temperature was returned as nil."
  end

  if temperature_metric == FAHRENHEIT then
    t = fahrenheit_to_celsius(t)
  end

  local dewpoint = (rh/100)^(1/8) * (112 + (0.9 * t)) - 112 + (0.1 * t)

  if temperature_metric == FAHRENHEIT then
    dewpoint = celsius_to_fahrenheit(dewpoint)
  end

  return dewpoint
end


function dewPoint (T, RH)
  -- a,b,c taken from a 1980 paper by David Bolton in the Monthly Weather Review
--  local a = 6.112     -- a is not used in this approximation
  local b,c = 17.67, 243.5
  RH = math.max (RH or 0, 1e-3)
  local gamma = math.log (RH/100) + b * T / (c + T) 
  return c * gamma / (b - gamma)
end

function freezing_point(dp, t, temperature_metric) 
  temperature_metric = temperature_metric or FAHRENHEIT

  if temperature_metric ~= CELSIUS and temperature_metric ~= FAHRENHEIT then
    return nil, "The 'temperature_metric' option can only by CELSIUS or FAHRENHEIT."
  end
  if dp > t then
    return nil, "Dew point temperature was higher than temperature. Since dew point temperature cannot be higher than air temperature, relative humidty was set to nil."
  end

  if temperature_metric == FAHRENHEIT then
    t = fahrenheit_to_celsius(t)
    dp = fahrenheit_to_celsius(dp)
  end
T = t + 273.15
Td = dp + 273.15
return (Td + (2671.02 /((2954.61/T) + 2.193665 * math.log(T) - 13.3448))-T)-273.15

  
  
end