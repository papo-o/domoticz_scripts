#!/bin/sh

#############
# 
# Script de sauvegarde de l'image complète du RPI
# Transmission d'une notification pushbullet avant et après l'opération
# modification du script http://easydomoticz.com/forum/viewtopic.php?f=17&t=227&hilit=sauvegarde+freebox&start=50#p44641
#############
. ./include_passwd # fichier comprenant l'api pushbullet

# Emplacement a sauvegarder
RPI_FILE=/dev/mmcblk0
# Chemin montage disque distant
MOUNT_PATH=/home/pi/domoticz/
# Repertoire sauvegarde
SAVE_PATH=/Backup_img/
# Formatage date pour nom du fichier et logs
DATE_BCK=`date +%Y-%m-%d_%H-%M`
# Nom du fichier de sauvegarde
BCK_FILE=RPI3-domoticz-${DATE_BCK}.img.gz
# Nombre de sauvegarde à conserver
KEEP_SAVE=4
# Filtre de recherche
FILE_FILTER="RPI3*img.gz"

# Format de date en seconde
S_DEBUT=`date +%s`

############# notification Pushbullet
title='%20'$DATE_BCK  #'Debut%20de%20la%20sauvegarde%20image%20du%20serveur%20domoticz.'
body='Debut%20de%20la%20sauvegarde%20image%20du%20serveur%20domoticz.'
curl -u $api: https://api.pushbullet.com/v2/pushes -d type=note -d title=$title -d body=$body
############# notification Pushbullet
# répertoires à exclure 

# Sauvegarde sur le répertoire distant
echo $DATE_BCK' '$message
sudo ls -1t ${MOUNT_PATH}${SAVE_PATH}${FILE_FILTER} | tail -n +$KEEP_SAVE | xargs rm -rf
dd if=${RPI_FILE} | pigz -9 -p 3 > ${MOUNT_PATH}${SAVE_PATH}${BCK_FILE}

# Formatage de la date de fin et de l'heure
D_FIN=`date +%Y%m%d-%Hh%M`

# Découpe pour mise en seconde
S_FIN=`date +%s`

# Calcul de la durée d'execution
DUREE_EN_SEC=$(($S_FIN-$S_DEBUT))

# Remise en Heure - Minute - Seconde
DUREE_H=$(($DUREE_EN_SEC/3600))
DUREE_M=$((($DUREE_EN_SEC%3600)/60))
DUREE_S=$((($DUREE_EN_SEC%3600)%60))

echo $D_FIN' '$message

############# notification Pushbullet
title='%20'$DATE_FIN'%20'$H_FIN #'Fin de la sauvegarde image du serveur domoticz.'
body='Fin%20de%20la%20sauvegarde%20image%20du%20serveur%20domoticz.%20Duree%20du%20traitement%20'$DUREE_H'-'$DUREE_M'-'$DUREE_S
curl -u $api: https://api.pushbullet.com/v2/pushes -d type=note -d title=$title -d body=$body
############# notification Pushbullet
