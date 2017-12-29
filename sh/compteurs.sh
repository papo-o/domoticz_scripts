#!/bin/bash

# Settings
#crontab -e
# */2 * * * * sudo /home/pi/domoticz/scripts/sh/compteurs.sh
# chmod +x /home/pi/domoticz/scripts/sh/compteurs.sh
# sudo /home/pi/domoticz/scripts/sh/compteurs.sh

DAMOCLES_IP="192.168.1.20"         #  IP Address damocles
HWG_PWR_IP="192.168.1.21"         #  IP Address damocles
PASSWORD="private"         # SNMP Password
DOMO_IP="192.168.1.24"      # Domoticz IP Address
DOMO_PORT="8080"         # Domoticz Port

DAMOCLES_IDX="150"               # DAMOCLES Switch IDX
DOMOTICZ_CPT_1_IDX="154"        # IDX DOMOTICZ CPT 1 Eau Froide
DOMOTICZ_CPT_2_IDX="320"        # IDX DOMOTICZ CPT 2 Eau Chaude
DOMOTICZ_CPT_3_IDX="156"        # IDX DOMOTICZ CPT 3 gaz
DOMOTICZ_CPT_4_IDX="197"        # IDX DOMOTICZ CPT 4 Prises
DOMOTICZ_CPT_5_IDX="198"        # IDX DOMOTICZ CPT 5 Lumiere 
DOMOTICZ_CPT_6_IDX="199"        # IDX DOMOTICZ CPT 6 Technique


# DOMOTICZ_INT_1_IDX="157"        # DOMOTICZ IDX interrupteur1
# DAMOCLES_OUT_1_IDX="158"        # DAMOCLES IDX Reduit Chauffage
#DOMOTICZ_INT_2_IDX="159"        # DOMOTICZ IDX interrupteur2
#DAMOCLES_OUT_2_IDX="158"        # DAMOCLES IDX Sortie2

# Controle si DAMOCLES est online 

function string_to_int ()
{
    LANG=C
	
    d=${1##*.} # partie décimale
	    #if [[ ${#1} -eq ${#d} ]]; then
     #   d=0
    #fi
    e=${1%.*}  # partie entière
    e=${e//,/}
		
    printf %.0f "$e.$d" 2>/dev/null	
}
PINGTIME=`ping -c 1 -q $DAMOCLES_IP | awk -F"/" '{print $5}' | xargs`

OUT_1=`snmpget -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.2.1.2.1` # Etat Sortie 1


IND_CPT_1=$(curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=devices&rid=$DOMOTICZ_CPT_1_IDX"| jq -r .result[].Counter) # Index Domoticz Compteur 1
IND_CPT_2=$(curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=devices&rid=$DOMOTICZ_CPT_2_IDX"| jq -r .result[].Counter) # Index Domoticz Compteur 2
IND_CPT_3=$(curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=devices&rid=$DOMOTICZ_CPT_3_IDX"| jq -r .result[].Counter) # Index Domoticz Compteur 3
IND_CPT_4=$(curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=devices&rid=$DOMOTICZ_CPT_4_IDX"| jq -r .result[].Counter) # Index Domoticz Compteur 4
IND_CPT_5=$(curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=devices&rid=$DOMOTICZ_CPT_5_IDX"| jq -r .result[].Counter) # Index Domoticz Compteur 5
IND_CPT_6=$(curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=devices&rid=$DOMOTICZ_CPT_6_IDX"| jq -r .result[].Counter) # Index Domoticz Compteur 6

CPT_1=`snmpget -c $PASSWORD -v1 -O qv  $HWG_PWR_IP .1.3.6.1.4.1.21796.4.6.1.3.1.6.1001` # Index Compteur 1
CPT_2=`snmpget -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.2` # Index Compteur 2
CPT_3=`snmpget -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.3` # Index Compteur 3
CPT_4=`snmpget -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.4` # Index Compteur 4
CPT_5=`snmpget -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.5` # Index Compteur 5
CPT_6=`snmpget -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.6` # Index Compteur 6


INT_1=$(curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=devices&rid=$DOMOTICZ_INT_1_IDX"| jq -r .result[].Status)

echo $PINGTIME
	if expr "$PINGTIME" '>' 0
			then
       echo "DAMOCLES ON"
		IND_CPT_1=${IND_CPT_1:0:6} # supprime les unités du compteur 1
		IND_CPT_2=${IND_CPT_2:0:6} # supprime les unités du compteur 2
		IND_CPT_3=${IND_CPT_3:0:6} # supprime les unités du compteur 3
		IND_CPT_4=${IND_CPT_4:0:6} # supprime les unités du compteur 4
		IND_CPT_5=${IND_CPT_5:0:6} # supprime les unités du compteur 5
		IND_CPT_6=${IND_CPT_6:0:6} # supprime les unités du compteur 6

		IND_CPT_1=$(echo "$IND_CPT_1*1000" |bc -l) #conversion en litres
		IND_CPT_1=$(string_to_int $IND_CPT_1) #suppression du .000
echo $IND_CPT_1
		IND_CPT_2=$(echo "$IND_CPT_2*1000" |bc -l) #conversion en litres
		IND_CPT_2=$(string_to_int $IND_CPT_2) #suppression du .000
echo $IND_CPT_2
		IND_CPT_3=$(echo "$IND_CPT_3*1000" |bc -l) #conversion en litres
		IND_CPT_3=$(string_to_int $IND_CPT_3) #suppression du .000
echo $IND_CPT_3
		IND_CPT_4=$(echo "$IND_CPT_4*1000" |bc -l) #conversion en litres
		IND_CPT_4=$(string_to_int $IND_CPT_4) #suppression du .000
echo $IND_CPT_4
		IND_CPT_5=$(echo "$IND_CPT_5*1000" |bc -l) #conversion en litres
		IND_CPT_5=$(string_to_int $IND_CPT_5) #suppression du .000
echo $IND_CPT_5
		IND_CPT_6=$(echo "$IND_CPT_6*1000" |bc -l) #conversion en litres
		IND_CPT_6=$(string_to_int $IND_CPT_6) #suppression du .000
echo $IND_CPT_6

		#if (( $(echo "$IND_CPT_1 $CPT_1" | awk '{print ($1 > $2)}') )); then
		#MAJ_CPT_1=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.1 i $IND_CPT_1`
			#else
		CPT_1=$(echo "$CPT_1*10" |bc -l)	
         #Envoi index Compteur 1 vers domoticz			
		curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$DOMOTICZ_CPT_1_IDX&nvalue=0&svalue=$CPT_1" > /dev/null	
			#fi
			if (( $(echo "$IND_CPT_2 $CPT_2" | awk '{print ($1 > $2)}') )); then
		MAJ_CPT_2=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.2 i $IND_CPT_2`
			else
         #Envoi Index Compteur 2 vers domoticz
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$DOMOTICZ_CPT_2_IDX&nvalue=0&svalue=$CPT_2" > /dev/null
					fi
			if (( $(echo "$IND_CPT_3 $CPT_3" | awk '{print ($1 > $2)}') )); then
		
		MAJ_CPT_3=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.3 i $IND_CPT_3`
			else
		 #Envoi Index Compteur 3 vers domoticz
         IND_CPT_3=$(echo "$IND_CPT_3*10" |bc -l) #conversion en litres
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$DOMOTICZ_CPT_3_IDX&nvalue=0&svalue=$CPT_3" > /dev/null			
			fi
			if (( $(echo "$IND_CPT_4 $CPT_4" | awk '{print ($1 > $2)}') )); then
		MAJ_CPT_4=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.4 i $IND_CPT_4`
			else
         #Envoi index Compteur 4 vers domoticz
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$DOMOTICZ_CPT_4_IDX&nvalue=0&svalue=$CPT_4" > /dev/null		
			fi
			if (( $(echo "$IND_CPT_5 $CPT_5" | awk '{print ($1 > $2)}') )); then
		MAJ_CPT_5=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.5 i $IND_CPT_5`
			else
         #Envoi Index Compteur 5 vers domoticz
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$DOMOTICZ_CPT_5_IDX&nvalue=0&svalue=$CPT_5" > /dev/null			
			fi
			if (( $(echo "$IND_CPT_6 $CPT_6" | awk '{print ($1 > $2)}') )); then
		MAJ_CPT_6=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.1.1.6.6 i $IND_CPT_6`
			else	
		 #Envoi Index Compteur 6 vers domoticz
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$DOMOTICZ_CPT_6_IDX&nvalue=0&svalue=$CPT_6" > /dev/null			
			fi	   
	   
	   
       # Envoi état damoclès
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DAMOCLES_IDX&switchcmd=On" > /dev/null
	
		
		# comparaison état interrupteur domoticz et Sortie 1 en cas de coupure de courant
				# if [ $INT_1 = "On" ] && [ $OUT_1 = 0 ]
					# then
					# DAMOCLES_CMD_1=`snmpset -c $PASSWORD -v1 -O qv  $DAMOCLES_IP .1.3.6.1.4.1.21796.3.4.2.1.2.3 i 1`	
					# fi
			 else
       # echo "DAMOCLES OFF"
   
       #Envoi état damoclès
          curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DAMOCLES_IDX&switchcmd=Off" > /dev/null
		 
			fi		  

