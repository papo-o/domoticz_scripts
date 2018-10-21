#!/bin/bash

# Settings
# chmod +x /home/pi/domoticz/scripts/sh/out.sh
# sudo /home/pi/domoticz/scripts/sh/out.sh

DAMOCLES_IP="192.168.1.200"         #  IP Address damocles
PASSWORD="private"         # SNMP Password
DOMO_IP="127.0.0.1"      # Domoticz IP Address
DOMO_PORT="8080"         # Domoticz Port

DAMOCLES_IDX="150"              # DAMOCLES IDX Etat équipement
#DOMOTICZ_INT_1_IDX="157"        # DOMOTICZ IDX interrupteur1
DAMOCLES_OUT_3_IDX="158"        # DAMOCLES IDX Reduit Chauffage
#DOMOTICZ_INT_2_IDX="159"        # DOMOTICZ IDX interrupteur2
#DAMOCLES_OUT_4_IDX="160"        # DAMOCLES IDX Sortie3
#DOMOTICZ_INT_3_IDX="161"        # DOMOTICZ IDX interrupteur3
#DAMOCLES_OUT_5_IDX="162"        # DAMOCLES IDX Sortie4
PAQUET_IDX="308"
LETTRE_IDX="309"
SONNETTE_IDX="319"
INONDATION_IDX="480"
case $1 in 
		reduit) DAMOCLES_CMD_1=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.2.1.2.3 i 1`;; # && curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DAMOCLES_OUT_3_IDX&switchcmd=On";;
		confort) DAMOCLES_CMD_1=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.2.1.2.3 i 0`;; # && curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DAMOCLES_OUT_3_IDX&switchcmd=Off";;
		paquet) curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$PAQUET_IDX&switchcmd=On";;
		lettre) curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$LETTRE_IDX&switchcmd=On";;
		inondation_ON) curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$INONDATION_IDX&switchcmd=Off";;
		inondation_OFF) curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$INONDATION_IDX&switchcmd=On";;        
		lum_cave_on) DAMOCLES_CMD_1=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.2.1.2.5 i 1`;; 
		lum_cave_off) DAMOCLES_CMD_1=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.2.1.2.5 i 0`;;        
        
		# sonnette_ON) curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$SONNETTE_IDX&switchcmd=On";;
		# sonnette_OFF) curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$SONNETTE_IDX&switchcmd=Off";;
		*);;		
esac

#allume3) DAMOCLES_CMD_2=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.2.1.2.4 i 1`;; # && curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DAMOCLES_OUT_4_IDX&switchcmd=On";;
		#eteint3) DAMOCLES_CMD_2=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.2.1.2.4 i 0`;; # && curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DAMOCLES_OUT_4_IDX&switchcmd=Off";;
		#allume4) DAMOCLES_CMD_3=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.2.1.2.5 i 1`;; # && curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DAMOCLES_OUT_5_IDX&switchcmd=On";;
		#eteint4) DAMOCLES_CMD_3=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.2.1.2.5 i 0`;; # && curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DAMOCLES_OUT_5_IDX&switchcmd=Off";;
 
