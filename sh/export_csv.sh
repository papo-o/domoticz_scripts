#!/bin/bash

#export gaz idx 156 table meter - Value
sqlite3 -separator ';' -list /home/pi/domoticz/domoticz.db "SELECT Date AS date, Value  FROM Meter WHERE DeviceRowID = 156 order by date" >> /home/pi/domoticz/Trend/Export_gaz_`date +%Y%m`.csv
#export Eau Froide idx 154 table meter -Value
sqlite3 -separator ';' -list /home/pi/domoticz/domoticz.db "SELECT Date AS date, Value  FROM Meter WHERE DeviceRowID = 154 order by date" >> /home/pi/domoticz/Trend/Export_eau_froide_`date +%Y%m`.csv
#export Eau chaude idx 320 table meter -Value
sqlite3 -separator ';' -list /home/pi/domoticz/domoticz.db "SELECT Date AS date, Value  FROM Meter WHERE DeviceRowID = 320 order by date" >> /home/pi/domoticz/Trend/Export_eau_chaude_`date +%Y%m`.csv
#export Lumieres idx 198 table meter -Value
sqlite3 -separator ';' -list /home/pi/domoticz/domoticz.db "SELECT Date AS date, Value  FROM Meter WHERE DeviceRowID = 198 order by date" >> /home/pi/domoticz/Trend/Export_lumieres_`date +%Y%m`.csv
#export Prises idx 197 table meter -Value
sqlite3 -separator ';' -list /home/pi/domoticz/domoticz.db "SELECT Date AS date, Value  FROM Meter WHERE DeviceRowID = 197 order by date" >> /home/pi/domoticz/Trend/Export_prises_`date +%Y%m`.csv
#export Technique idx 199 table meter -Value
sqlite3 -separator ';' -list /home/pi/domoticz/domoticz.db "SELECT Date AS date, Value  FROM Meter WHERE DeviceRowID = 199 order by date" >> /home/pi/domoticz/Trend/Export_technique_`date +%Y%m`.csv
#export Technique idx 716 table meter -Value
sqlite3 -separator ';' -list /home/pi/domoticz/domoticz.db "SELECT Date AS date, Value  FROM Meter WHERE DeviceRowID = 716 order by date" >> /home/pi/domoticz/Trend/EDF_`date +%Y%m`.csv

