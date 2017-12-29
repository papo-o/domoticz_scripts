#!/bin/bash

# Settings
#crontab -e
# 0 18 * * * sudo /home/pi/domoticz/scripts/sh/lance_calcul_dju.sh
# chmod +x /home/pi/domoticz/scripts/sh/lance_calcul_dju.sh
# sudo /home/pi/domoticz/scripts/sh/lancecalcul_dju.sh
DOMO_IP="127.0.0.1"      # Domoticz IP Address
DOMO_PORT="8080"         # Domoticz Port
nb_IDX="18" # IDX variable Nb Jours de Chauffage 18
uservariablename="Nb Jours de Chauffage"
uservariabletype="2"
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
urlencode() {
    # urlencode <string>

    local LANG=C
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;; 
        esac
    done
}
       nb=$(curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=getuservariable&idx=$nb_IDX"| jq -r .result[].Value)
		echo $nb
			if expr "$nb" '>' 0
			then
			echo "test condition avant calcul"
			echo $nb
		nb=$((nb+1))
		echo "test condition apres calcul"
		echo $nb
		uservariablename=$( urlencode "$uservariablename" )
		#curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevices&script=calcul_dju.lua"
		curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=updateuservariable&idx=$nb_IDX&vname=$uservariablename&vtype=$uservariabletype&vvalue=$nb"
					else
				echo $nb
		fi