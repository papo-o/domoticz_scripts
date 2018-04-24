#!/bin/bash


myLivebox=192.168.1.1
myPassword=monmotdepasse

#myBashDir=/home/pi/domoticz/scripts/sh/livebox/
myBashDir=/home/pi/domoticz/Trend

myOutput=$myBashDir/rebootlivebox_context.txt
myCookies=$myBashDir/rebootlivebox_cookies.txt

########################################
# Connexion et récupération du cookies #
########################################
curl -s -o "$myOutput" -X POST -c "$myCookies" -H 'Content-Type: application/x-sah-ws-4-call+json' -H 'Authorization: X-Sah-Login' -d "{\"service\":\"sah.Device.Information\",\"method\":\"createContext\",\"parameters\":{\"applicationName\":\"so_sdkut\",\"username\":\"admin\",\"password\":\"$myPassword\"}}" http://$myLivebox/ws > /dev/null

##################################################
# Lecture du cookies pour utilisation ultérieure #
##################################################
myContextID=$(tail -n1 "$myOutput" | sed 's/{"status":0,"data":{"contextID":"//1'| sed 's/",//1' | sed 's/"groups":"http,admin//1' | sed 's/"}}//1')
curl -i -b "$myCookies" -X POST -H 'Content-Type: application/json' -H 'X-Context: '$myContextID'' -d '{"parameters":{}}' http://$myLivebox/sysbus/NMC:reboot
rm "$myCookies" "$myOutput"