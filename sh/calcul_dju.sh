#!/bin/bash

# Settings
#crontab -e
# 0 18 * * * sudo /home/pi/domoticz/scripts/sh/calcul_dju.sh

# chmod +x /home/pi/domoticz/scripts/sh/calcul_dju.sh
# sudo /home/pi/domoticz/scripts/sh/calcul_dju.sh

#===============Principe========================
#Un degré jour est calculé à partir des températures météorologiques extrêmes du lieu et du jour J : 
#- Tn : température minimale du jour J mesurée à 2 mètres du sol sous abri et relevée entre J-1 (la veille) à 18h et J à 18h UTC. 
#- Tx : température maximale du jour J mesurée à 2 mètres du sol sous abri et relevée entre J à 6h et J+1 (le lendemain) à 6h UTC. 
#- S : seuil de température de référence choisi. 
#- Moy = (Tn + Tx)/2 Température Moyenne de la journée
#Pour un calcul de déficits  de température par rapport au seuil choisi : 
#- Si S > TX (cas fréquent en hiver) : DJ = S - Moy 
#- Si S ≤ TN (cas exceptionnel en début ou en fin de saison de chauffe) : DJ = 0 
#- Si TN < S ≤ TX (cas possible en début ou en fin de saison de chauffe) : DJ = ( S –TN ) * (0.08 + 0.42 * ( S –TN ) / ( TX – TN ))
#===============================================



DOMO_IP="127.0.0.1"      # Domoticz IP Address
DOMO_PORT="8080"         # Domoticz Port
S="2"					# seuil de température de non chauffage (par convention : 18°C)
Tx_IDX="15"               # Idx de la variable Tx
Tx_uservariablename="Tx"  # Nom de la variable Tx

Tn_hold_IDX="17"        # Idx de la variable Tn_hold
Tn_hold_uservariablename="Tn_Hold"  # Nom de la variable Tn

	
        Tx=$(curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=getuservariable&idx=$Tx_IDX"| jq -r .result[].Value) 
		echo "Récupération valeur variable Tx"
		let Tx
		echo $Tx
		Tn=$(curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=getuservariable&idx=$Tn_hold_IDX"| jq -r .result[].Value) 
		let Tn
		echo "Récupération valeur variable Tn memorisé"
		echo $Tn
		Moy= echo "($Tn+$Tx)/2" |bc -l
		echo $Moy
		
		#if [ $(($S)) -gt $(($Tx)) ] # > strictement superieur
		if expr $S \> $Tx
			then 
				echo $S ">" $Tx
		#elif [ $(($S)) -le $(($Tn))  ] # inférieur ou égal
		elif expr $S \< $Tn \| $S = $Tn
			then
				echo $S "<=" $Tn
		else #if [ $((Tn)) -lt $(($S)) || $(($S)) -le $(($Tx)) ]
			#then
				echo $Tn "<" $S "<=" $Tx
		fi
		#curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=updateuservariable&idx=$Tn_hold_IDX&vname=$Tn_hold_uservariablename&vtype=2&vvalue=$Tn"
		#echo "Mise a jour valeur variable Tn_hold avec la Temperature mini"		
       #curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=updateuservariable&idx=$Tx_IDX&vname=$Tx_uservariablename&vtype=2&vvalue=-150"
		#echo "Changement valeur variable Tx a -150 pour debuter un nouveau jour"

