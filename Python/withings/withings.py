#!/usr/bin/python
# -*- coding: utf-8 -*-
#Créez une application de développeur à partir de l'application partenaire Withings (https://developer.health.nokia.com/partner/dashboard),
#vous obtiendrez une clé API (CONSUMER_KEY) et un secret API(CONSUMER_SECRET) à renseigner dans ce script
#Ce site Web api de Withings vous aidera à obtenir des informations supplémentaires concernant votre compte (étape 1 à l'étape 3). 
#Pensez à noter s'il vous plaît :
#• Oauth_signature
#• oauth_token
#• À l'étape 1, vous pouvez laisser le champ «Callback URL» vierge.

import sys; sys.path.insert(0,'/usr/local/lib/python3.5/dist-packages/')
import pickle, json
import datetime
import urllib, urllib.request as urllib2#, hashlib,subprocess
from get_withings_data import WithingsAuth, WithingsApi  # projet initial https://github.com/maximebf/python-withings

####################################################################################################
######################################## variable à éditer #########################################

CONSUMER_KEY = ''       # clé API
CONSUMER_SECRET = '' # secret API
#domoticz settings
domoticz_host           = '127.0.0.1'    # Url domoticz
domoticz_port           = '8080'            # port
domoticz_url            = 'json.htm'        # Ne pas modifier

idx_weight              = '717'   # renseigner l'idx du device Poids associé si souhaité (custom sensor, nom de l'axe : kg)
idx_fat_free_mass       = '1288'      # renseigner l'idx du device Masse hors graisse associé si souhaité, sinon laisser vide '' (custom sensor, nom de l'axe : kg)
idx_fat_ratio           = '1289'      # renseigner l'idx du device Pourcentage graisse associé si souhaité, sinon laisser vide '' (custom sensor, nom de l'axe : %)
idx_fat_mass_weight     = '1290'      # renseigner l'idx du device Masse grasse associé si souhaité, sinon laisser vide '' (custom sensor, nom de l'axe : kg)
idx_heart_pulse         = '881'   # renseigner l'idx du device Rythme cardiaque associé si souhaité, sinon laisser vide '' (custom sensor, nom de l'axe : bpm)
idx_muscle_mass         = '1291'      # renseigner l'idx du device Masse musculaire associé si souhaité, sinon laisser vide '' (custom sensor, nom de l'axe : kg)
idx_hydration           = '1292'      # renseigner l'idx du device Taux d'hydratation associé si souhaité, sinon laisser vide '' (custom sensor, nom de l'axe : %)
idx_bone_mass           = '1293'      # renseigner l'idx du device Masse osseuse associé si souhaité, sinon laisser vide '' (custom sensor, nom de l'axe : kg)
idx_pulse_wave_velocity = ''      # renseigner l'idx du device Vitesse d'onde de pouls associé si souhaité, sinon laisser vide '' (custom sensor, nom de l'axe : m/s)
debugging = False                 # True pour voir les logs dans la console log Dz et en ligne de commande, ou False pour ne pas les voir (attention aux majuscules)

#################################### fin  variables à éditer #######################################
####################################################################################################

def log(message):
  if debugging == True:
    print (message)

def domoticzrequest (url):
  request = urllib2.Request(url)
  response = urllib2.urlopen(request)
  return response.read()

auth = WithingsAuth(CONSUMER_KEY, CONSUMER_SECRET)

try:
    #with open(sys.path[0] + '/pickled_creds', 'rb') as pf:
    with open('./pickled_creds', 'rb') as pf:
        credentials = pickle.load(pf)
    pass	
except IOError:	
    authorize_url = auth.get_authorize_url()
    print("Go to %s allow the app and copy your oauth_verifier" % authorize_url)
    oauth_verifier = input('Please enter your oauth_verifier: ')
    credentials = auth.get_credentials(oauth_verifier)
    # save new credentials to file
    with open('./pickled_creds', 'wb') as pf:
        pickle.dump(credentials, pf)
    pass
	
creds = credentials #auth.get_credentials(oauth_verifier)
client = WithingsApi(creds)
user = client.get_user()
log("User %s" % user)
measures = client.get_measures(limit=10)

if idx_weight != None:

  domoticzurl = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=devices&rid=" + idx_weight
  json_object = json.loads(domoticzrequest(domoticzurl).decode('utf-8'))
  if json_object["status"] == "OK":
    if json_object["result"][0]["idx"] == idx_weight:
      lastupdate = json_object["result"][0]["LastUpdate"]
      log("lastupdate: %s " % lastupdate)


if measures[0].date != None:
  date = measures[0].date
elif  measures[1].date != None:
  date = measures[1].date  
elif measures[2].date != None:
  date = measures[1].date 
  
log("Date derniere mesure :%s " %date)

lastupdate = datetime.datetime.strptime(lastupdate, '%Y-%m-%d %H:%M:%S')
if date > lastupdate:
  log("la derniere mesure est plus recente que la derniere mise à jour :%s " %lastupdate)
else:
  log("la derniere mesure est égale à la derniere mise à jour :%s " %lastupdate)

####################################################################################################
if measures[0].weight != None:
  weight = measures[0].weight

elif measures[1].weight != None:
  weight = measures[1].weight

elif measures[2].weight != None:
  weight = measures[2].weight  

log("votre poid est de : %s kg" % weight) 
#uploading values to domoticz
if idx_weight != None and weight != None:
  if date > lastupdate:
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx_weight + "&nvalue=0&svalue=" + str(weight)
    urllib2.urlopen(url , timeout = 5)
  if debugging == True:   
    #uploading log message to domoticz
    log_weight = urllib.quote(("Withings : votre poid est de : ").encode("utf-8"))
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=addlogmessage&message=" + log_weight + str(weight) +"%20kg"
    urllib2.urlopen(url , timeout = 5)
    
####################################################################################################
if measures[0].fat_free_mass != None:
  fat_free_mass = measures[0].fat_free_mass
  
elif measures[1].fat_free_mass != None: 
  fat_free_mass = measures[1].fat_free_mass
  
elif measures[2].fat_free_mass != None:
  fat_free_mass = measures[2].fat_free_mass
  
log("votre masse libre (muscle + os) est de %s kg" % fat_free_mass)
  
if idx_fat_free_mass != None and fat_free_mass != None:
  if date > lastupdate:
    #uploading values to domoticz
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx_fat_free_mass + "&nvalue=0&svalue=" + str(fat_free_mass)
    urllib2.urlopen(url , timeout = 5)  
  if debugging == True:  
    #uploading log message to domoticz
    log_fat_free_mass = urllib.quote(("Withings : votre masse libre (muscle + os) est de : ").encode("utf-8"))
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=addlogmessage&message=" + log_fat_free_mass + str(fat_free_mass) +"%20kg"
    urllib2.urlopen(url , timeout = 5)

####################################################################################################
if measures[0].fat_ratio != None:
  fat_ratio = measures[0].fat_ratio
  
elif measures[1].fat_ratio != None:
  fat_ratio = measures[1].fat_ratio
  
elif measures[2].fat_ratio != None:
  fat_ratio = measures[2].fat_ratio
  
log("votre masse graisseuse represente : %s pourcent" % fat_ratio)  

if idx_fat_ratio != None and fat_ratio != None:
  if date > lastupdate:  
    #uploading values to domoticz
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx_fat_ratio + "&nvalue=0&svalue=" + str(fat_ratio)
    urllib2.urlopen(url , timeout = 5)
  if debugging == True:  
    #uploading log message to domoticz
    log_fat_ratio = urllib.quote(("Withings : votre masse graisseuse represente : ").encode("utf-8"))
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=addlogmessage&message=" + log_fat_ratio + str(fat_ratio) +"%20pourcent"
    urllib2.urlopen(url , timeout = 5)
   
####################################################################################################  
if measures[0].fat_mass_weight != None:
  fat_mass_weight =  measures[0].fat_mass_weight
  
elif measures[1].fat_mass_weight != None:
  fat_mass_weight =  measures[1].fat_mass_weight  
  
elif measures[2].fat_mass_weight != None:
  fat_mass_weight =  measures[2].fat_mass_weight
  
log("votre masse graisseuse est de : %s kg" % fat_mass_weight)

#uploading values to domoticz
if idx_fat_mass_weight != None and fat_mass_weight != None:   
  if date > lastupdate:
    #uploading values to domoticz 
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx_fat_mass_weight + "&nvalue=0&svalue=" + str(fat_mass_weight)
    urllib2.urlopen(url , timeout = 5)  
  if debugging == True:   
    #uploading log message to domoticz
    log_fat_mass_weight = urllib.quote(("Withings : votre masse graisseuse est de ").encode("utf-8"))
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=addlogmessage&message=" + log_fat_mass_weight + str(fat_mass_weight) +"%20kg"
    urllib2.urlopen(url , timeout = 5)
    
####################################################################################################  
if measures[0].heart_pulse != None:
  heart_pulse = measures[0].heart_pulse 
 
elif measures[1].heart_pulse != None:
  heart_pulse = measures[1].heart_pulse
  
elif measures[2].heart_pulse != None:
  heart_pulse = measures[2].heart_pulse

log("votre rythme cardiaque est de : %s bpm" % heart_pulse)

if idx_heart_pulse != None and heart_pulse != None:
  if date > lastupdate:
    #uploading values to domoticz  
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx_heart_pulse + "&nvalue=0&svalue=" + str(heart_pulse)
    urllib2.urlopen(url , timeout = 5)  
  if debugging == True:   
    #uploading log message to domoticz
    log_heart_pulse = urllib.quote(("Withings : votre rythme cardiaque est de : ").encode("utf-8"))
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=addlogmessage&message=" + log_heart_pulse + str(heart_pulse) +"%20bpm"
    urllib2.urlopen(url , timeout = 5)
    
####################################################################################################      
if measures[0].muscle_mass != None:
  muscle_mass = measures[0].muscle_mass 
   
elif measures[1].muscle_mass != None:
  muscle_mass = measures[1].muscle_mass
  
elif measures[2].muscle_mass != None:
  muscle_mass = measures[2].muscle_mass
 
log("Masse musculaire : %s kg" % muscle_mass)

if idx_muscle_mass != None and muscle_mass != None:
  if date > lastupdate:
    #uploading values to domoticz  
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx_muscle_mass + "&nvalue=0&svalue=" + str(muscle_mass)
    urllib2.urlopen(url , timeout = 5)  
  if debugging == True:   
    #uploading log message to domoticz
    log_muscle_mass = urllib.quote(("Withings : votre masse musculaire est de : ").encode("utf-8"))
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=addlogmessage&message=" + log_muscle_mass + str(muscle_mass) +"%20kg"
    urllib2.urlopen(url , timeout = 5)
    
####################################################################################################
if measures[0].hydration != None:
  hydration = measures[0].hydration 
   
elif measures[1].hydration != None:
  hydration = measures[1].hydration
  
elif measures[2].hydration != None:
  hydration = measures[2].hydration

log("hydration : %s pourcent" % hydration)
if idx_hydration != None and hydration != None:
  if date > lastupdate:
    #uploading values to domoticz
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx_hydration + "&nvalue=0&svalue=" + str(hydration)
    urllib2.urlopen(url , timeout = 5)  
  if debugging == True:   
    #uploading log message to domoticz
    log_hydration = urllib.quote(("Withings : votre taux d'hydratation est de : ").encode("utf-8"))
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=addlogmessage&message=" + log_hydration + str(hydration) +"%20pourcent"
    urllib2.urlopen(url , timeout = 5)
    
  ####################################################################################################
if measures[0].bone_mass != None:
  bone_mass = measures[0].bone_mass 
   
elif measures[1].bone_mass != None:
  bone_mass = measures[1].bone_mass
  
elif measures[2].bone_mass != None:
  bone_mass = measures[2].bone_mass

log("masse osseuse : %s kg" % bone_mass)  

if idx_bone_mass != None and bone_mass != None:
  if date > lastupdate:  
    #uploading values to domoticz  
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx_bone_mass + "&nvalue=0&svalue=" + str(bone_mass)
    urllib2.urlopen(url , timeout = 5)  
  if debugging == True:   
    #uploading log message to domoticz
    log_bone_mass = urllib.quote(("Withings : votre masse osseuse represente : ").encode("utf-8"))
    url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=addlogmessage&message=" + log_bone_mass + str(bone_mass) +"%20pourcent"
    urllib2.urlopen(url , timeout = 5)
    
  ####################################################################################################
# if measures[0].pulse_wave_velocity != None:
  # pulse_wave_velocity = measures[0].pulse_wave_velocity 
   
# elif measures[1].pulse_wave_velocity != None:
  # pulse_wave_velocity = measures[1].pulse_wave_velocity
  
# elif measures[2].pulse_wave_velocity != None:
  # pulse_wave_velocity = measures[2].pulse_wave_velocity

# log("vitesse onde de pouls : %s" % pulse_wave_velocity)
  
# if idx_pulse_wave_velocity != None and pulse_wave_velocity != None:
  # if date > lastupdate:
    ## uploading values to domoticz  
    # url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx_pulse_wave_velocity + "&nvalue=0&svalue=" + str(pulse_wave_velocity)
    # urllib2.urlopen(url , timeout = 5)  
  # if debugging == True:   
    ## uploading log message to domoticz
    # log_pulse_wave_velocity = urllib.quote(("Withings : votre vitesse d'onde de pouls est de : ").encode("utf-8"))
    # url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=addlogmessage&message=" + log_pulse_wave_velocity + str(pulse_wave_velocity)
    # urllib2.urlopen(url , timeout = 5) 
    
  ####################################################################################################
