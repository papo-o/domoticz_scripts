#!/usr/bin/python
# -*- coding: utf-8 -*-

# cde_modbus.py arg:adresse arg:valeur
# adresse = adresse modbus 
# valeur = 0 forcé le coil à 0 / 1 forcé le coil à 1 / 2 inversé le coil apres lecture de l'état

import sys
from pymodbus.client.sync import ModbusTcpClient as ModbusClient

#ouverture de la communication Modbus
#l'adresse de l'automate Serveur Modbus TCP 
client = ModbusClient('192.168.1.20')

#si le nombre d'argument est supérieur à 2, prise en compte de la commande via Modbus TCP
if len(sys.argv) > 2:
	# argument 1 -> l'adresse du coil sur le serveur
	adresse = int(sys.argv[1])
	# argument 2 -> Etat du coil souhaité
	valeur = int(sys.argv[2])
	
	#en mode bouton enOcean
	if (valeur == 2):
		#lecture de l'état avant inversion de la commande
		rr = client.read_coils(adresse, 1)
		# inversion en fonction de l'état	
		if (rr.bits[0] == 1):
			rq = client.write_coil(adresse, 0)
		else:
			rq = client.write_coil(adresse, 1)
			
	#en mode bouton Domoticz , ecriture de l'état souhaité
	else:
		rq = client.write_coil(adresse,valeur)

#fermeture de la connexion Modbus TCP
client.close()
