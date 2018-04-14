#!/opt/bin/bash

###########################################
# Firmware Livebox 4 = 2.22.8 g0-f-sip-fr #
#     Script mis a jour le 03/06/2017     #
###########################################

#script source https://blog.tetsumaki.net/articles/2015/10/recuperation-dinformations-livebox-play.html

#############################
# Déclaration des variables #
#############################
myLivebox=192.168.1.1
myPassword=1a2b3c

#myBashDir=/home/pi/domoticz/scripts/sh/livebox/
myBashDir=/home/pi/domoticz/Trend

myOutput=$myBashDir/myOutput.txt
myCookies=$myBashDir/myCookies.txt

########################################
# Connexion et recuperation du cookies #
########################################
curl -s -o "$myOutput" -X POST -c "$myCookies" -H 'Content-Type: application/x-sah-ws-4-call+json' -H 'Authorization: X-Sah-Login' -d "{\"service\":\"sah.Device.Information\",\"method\":\"createContext\",\"parameters\":{\"applicationName\":\"so_sdkut\",\"username\":\"admin\",\"password\":\"$myPassword\"}}" http://$myLivebox/ws > /dev/null

##################################################
# Lecture du cookies pour utilisation ultérieure #
##################################################
myContextID=$(tail -n1 "$myOutput" | sed 's/{"status":0,"data":{"contextID":"//1'| sed 's/",//1' | sed 's/"groups":"http,admin//1' | sed 's/"}}//1')

###############################################################################################
# Envoi des commandes pour récupérer les informations et écriture dans un fichier TXT séparé #
###############################################################################################
#getDSLStats=`curl -s -b "$myCookies" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H "X-Context: $myContextID" -d "{\"service\":\"NeMo.Intf.dsl0\",\"method\":\"getDSLStats\",\"parameters\":{}}" http://$myLivebox/ws`
#getMIBs=`curl -s -b "$myCookies" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H "X-Context: $myContextID" -d "{\"service\":\"NeMo.Intf.data\",\"method\":\"getMIBs\",\"parameters\":{}}" http://$myLivebox/ws`
#getWanStatus=`curl -s -b "$myCookies" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H "X-Context: $myContextID" -d "{\"service\":\"NMC\",\"method\":\"getWANStatus\",\"parameters\":{}}" http://$myLivebox/ws`
#getDeviceInfo=`curl -s -b "$myCookies" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H "X-Context: $myContextID" -d "{\"service\":\"DeviceInfo\",\"method\":\"get\",\"parameters\":{}}" http://$myLivebox/ws`
getDevices=`curl -s -b "$myCookies" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H "X-Context: $myContextID" -d "{\"service\":\"Devices\",\"method\":\"get\",\"parameters\":{}}" http://$myLivebox/ws`
#getDevices=`curl -s -b "$myCookies" -X POST -H 'Content-Type: application/json\' -H "X-Context: $myContextID" -d "{\"service\":\"Devices\",\"method\":\"get\",\"parameters\":{}}" http://$myLivebox/ws`

#echo $getDSLStats > $myBashDir/DSLStats.txt
#echo $getMIBs > $myBashDir/MIBs.txt
#echo $getWanStatus > $myBashDir/WanStatus.txt
#echo $getDeviceInfo > $myBashDir/DeviceInfo.txt
echo $getDevices > $myBashDir/Devices.txt
#######################################################
# Deconnexion et suppression des fichiers temporaires #
#######################################################
curl -s -b "$myCookies" -X POST http://$myLivebox/logout
rm "$myCookies" "$myOutput"

