#!/bin/sh
#############
#
# Script de sauvegarde de l'image complète du serveur Domoticz sur une Freebox V6
# url du script : http://easydomoticz.com/forum/viewtopic.php?f=17&t=227
# pour nas synology https://easydomoticz.com/forum/viewtopic.php?f=17&t=2759#p24968
#############

#. ./include_passwd # comprend les identifiants pour acceder à la freebox et transmission des SMS via FreeMobile

# user_box='' #; export user_box
# pass_box='' #; export pass_box
api='' # api pushbullet
# Formatage de la date debut et de l'heure
DATE_DEBUT=`date +%Y-%m-%d`
H_DEPART=`date +%H:%M:%S`
DEBUT_EN_SEC=$(($(echo $H_DEPART | cut -d':' -f1)*3600+$(echo $H_DEPART | cut -d':' -f2)*60+$(echo $H_DEPART | cut -d':' -f3)))

# Transmission d'un premier sms
title='%20'$DATE_DEBUT'%20'$H_DEPART  #'Debut%20de%20la%20sauvegarde%20image%20du%20serveur%20domoticz.'
body='Debut%20de%20la%20sauvegarde%20image%20du%20serveur%20domoticz.'
#curl -s -i -k "https://smsapi.free-mobile.fr/sendmsg?user=$user&pass=$pass&msg=$message"
curl -u $api: https://api.pushbullet.com/v2/pushes -d type=note -d title=$title -d body=$body

# Montage de la Freebox
#echo "Montage de la Freebox"
#/sbin/mount.cifs //mafreebox.freebox.fr/Disque\ dur/ /media/Freebox/ -o user=$user_box,pass=$pass_box

# Sauvegarde sur la Freebox
#echo "Sauvegarde sur la Freebox"
#dd if=/dev/mmcblk0 | gzip -9 > /media/fFreebox/Backup_img/srv-domoticz-${DATE_DEBUT}'-'$H_DEPART.img.gz

# http://easydomoticz.com/forum/viewtopic.php?f=17&t=227&hilit=sauvegarde+freebox&start=30#p15069
# pour trouver le nom de la partition sur la carte sd => sudo fdisk -l    
#dd if=/dev/mmcblk0 | pigz -9 -p 3 > /media/Freebox/backup_img/srv-domoticz-${DATE_DEBUT}'-'$H_DEPART.img.gz
dd if=/dev/mmcblk0 | pigz -9 -p 3 > /home/pi/domoticz/Backup_img/srv-domoticz-${DATE_DEBUT}'-'$H_DEPART.img.gz
# Démontage de la Freebox
#echo "Démontage de la Freebox"
#/bin/umount /mnt/freebox

# Formatage de la date de fin et de l'heure
DATE_FIN=`date +%Y-%m-%d`
H_FIN=`date +%H:%M:%S`

# Découpe pour mise en seconde
FIN_EN_SEC=$(($(echo $H_FIN | cut -d':' -f1)*3600+$(echo $H_FIN | cut -d':' -f2)*60+$(echo $H_FIN | cut -d':' -f3)))

# Calcul de la durée d'execution
DUREE_EN_SEC=$(($FIN_EN_SEC-$DEBUT_EN_SEC))

# Remise en Heure - Minute - Seconde
DUREE_H=$(($DUREE_EN_SEC/3600))
DUREE_M=$((($DUREE_EN_SEC%3600)/60))
DUREE_S=$((($DUREE_EN_SEC%3600)%60))

# Transmission sms avec heure de fin et la durée
#message=${DATE_FIN}' '$H_FIN' Fin de la sauvegarde image du serveur domoticz. Durée du traitement #'$DUREE_H':'$DUREE_M':'$DUREE_S
#curl -s -i -k "https://smsapi.free-mobile.fr/sendmsg?user=$user&pass=$pass&msg=$message"



title='%20'$DATE_FIN'%20'$H_FIN #'Fin de la sauvegarde image du serveur domoticz.'
body='Fin%20de%20la%20sauvegarde%20image%20du%20serveur%20domoticz.%20Duree%20du%20traitement%20'$DUREE_H':'$DUREE_M':'$DUREE_S
curl -u $api: https://api.pushbullet.com/v2/pushes -d type=note -d title=$title -d body=$body

#sec=ntlm
