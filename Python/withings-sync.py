#!/usr/bin/env python3
"""
withing Health to domoticz Connect Weight Updater 

based from Nokia Health to Garmin Connect Weight Updater
__author__ = "Jacco Geul"
__version__ = "0.1.0"
__license__ = "GPLv3"

1) Ce script utilise la librairie python-nokia https://github.com/orcasgit/python-nokia 
que vous pouvez installer sur votre machine via la commande 
sudo pip3 install nokia
ou
wget https://raw.githubusercontent.com/orcasgit/python-nokia/master/bin/nokia
Copier ensuite ce script dans votre répertoire de scripts python dans domoticz. Pour moi :  /home/pi/domoticz/scripts/python/nokia-weight-sync.py
et personnalisez les idx de vos capteurs, votre taille, etc.

2) Pour le fonctionnement de cette librairie et de ce script, il vous faudra notamment les librairies :
arrow, requests, requests-oauthlib, pytz
et python3.x

3)https://account.withings.com/partner/add_oauth2 Enregistrez une application auprès de Nokia Health et obtenez vos consumer key et consumer secret.
Pour le logo, logo: les exigences sont assez strictes,  n'hésitez pas à utiliser celui-ci https://github.com/magnific0/nokia-weight-sync/blob/master/logo256w.png
Pour le callback :
-vous pouvez choisir n'importe quoi, mais si vous souhaitez effectuer l'autorisation automatisée (vous serez invité à le faire), vous devez choisir le nom d'hôte / ip et le port avec soin. Par exemple, http://localhost: 8087 .
- localhost: si vous exécutez nokia-weight-sync et effectuez l'autorisation dans un navigateur sur le même appareil. Cela doit être remplacé par ip / nom d'hôte local ou public si vous l'exécutez sur une autre machine.
- 8087: un port qui n'est probablement pas utilisé par d'autres services. Pour une configuration à distance, assurez-vous que le port n'est pas protégé par un pare-feu.
- http: https est disponible, mais nécessite une configuration supplémentaire de certificats.

4) Lors de la première utilisation, vous devez créer un fichier de configuration en exécutant la commande suivante :
python3 /home/pi/domoticz/scripts/python/nokia-weight-sync.py setup nokia
Il vous sera demandé : 
Please enter the client id: saisir ID du client (Consumer Access)
Please enter the consumer secret: saisir Secret d'application (Consumer Secret)
Please enter the callback url known by Nokia: l'URL de callback définie précédemment ex: http://192.168.100.250:8087
Spin up HTTP server to automate authorization? [y/n] : saisir Y
Visit: https://account.withings.com/oauth2_user/authorize2?response_type=code&client_id=1...&redirect_uri=http%3A%2F%2F192.168.100.250%3A8087&scope=user.metrics&state=...
and select your user and click "Allow this app". une adresse très longue s'affiche, prenez soin de vérifier que vous la copiez dans son intégralité puis collez la dans votre navigateur préféré. Authentifiez vous, sélectionnez l'utilisateur dont vous souhaitez récupérer les données, puis cliquez sur le bouton autorisez
le processus lancé en ligne de commande devrait ce terminer si vous l'url de callback fonctionne et que le port choisi n'est pas bloqué par votre box ou parefeu

5) tester le fonctionnement du script en ligne de commande via :
python3 /home/pi/domoticz/scripts/python/nokia-weight-sync.py sync

un fois le fonctionnement validé, vous pouvez mettre la variable debugging à False afin de ne plus afficher ces données dans les logs

6) créez un cronjob avec la commande 
crontab -e 
et ajouter la ligne suivante :
*/1 * * * * python3 /home/pi/domoticz/scripts/python/withings-sync.py sync > /dev/null 2>&1
pour une exécution toutes les minutes

après chaque pesée les mesures seront mises à jour sur domoticz
"""
__author__ = "papoo"
__version__ = "1.01"
__date__ = "10/11/2018"
__date_maj__= "11/11/2018"
__url__ = "https://python-recuperation-des-donnees-api-withings-avec-oauth-2-0"
__url_github__ = "https://github.com/papo-o/domoticz_scripts/blob/master/Python/withings-sync.py"
__url_forum__ = "https://easydomoticz.com/forum/viewtopic.php?f=17&t=7428"

from optparse import OptionParser
import configparser

from oauthlib.oauth2 import MobileApplicationClient
import urllib.parse
import nokia
import os.path
import sys
import base64
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse
import ssl
import pickle, json
import datetime
import pytz
nokia_auth_code = None

####################################################################################################
######################################## Start of custom variable ##################################

#domoticz settings
domoticz_host           = '127.0.0.1'    # Url domoticz
domoticz_port           = '8080'            # port
domoticz_url            = 'json.htm'        # Ne pas modifier
debugging				= True		    # True pour voir les logs dans la console log Dz et en ligne de commande, ou False pour ne pas les voir (attention aux majuscules)

votre_taille            =  182          # renseigner votre taille en cm pour le calcul de votre IMC dans le cas ou l'information ne serait pas disponible via l'API          

idx_weight              = '717'		    # renseigner l'idx du device Poids associé si souhaité (custom sensor, nom de l'axe : kg)
idx_body_mass_index     = '1418'		# renseigner l'idx du device IMC associé si souhaité (custom sensor, nom de l'axe : kg/m2)
idx_fat_free_mass       = '1288'		# renseigner l'idx du device Masse hors graisse associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : kg)
idx_fat_ratio           = '1289'		# renseigner l'idx du device Ratio graisse associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : %)
idx_lean_ratio          = '1419'		# renseigner l'idx du device Ratio masse maigre associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : %)
idx_fat_mass_weight     = '1290'		# renseigner l'idx du device Masse grasse associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : kg)
idx_heart_pulse         = '881'         # renseigner l'idx du device Rythme cardiaque associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : bpm)
idx_muscle_mass         = '1291'		# renseigner l'idx du device Masse musculaire associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : kg)
idx_muscle_mass_ratio   = '1420'		# renseigner l'idx du device Ratio Masse musculaire associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : %)
idx_hydration           = '1421'		# renseigner l'idx du device Masse hydratation associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : kg)
idx_hydration_ratio     = '1292'		# renseigner l'idx du device Taux d'hydratation associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : %)
idx_bone_mass           = '1422'		# renseigner l'idx du device Masse osseuse associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : kg)
idx_bone_mass_ratio     = '1293'		# renseigner l'idx du device Ratio Masse osseuse associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : %)
idx_pulse_wave_velocity = None		    # renseigner l'idx du device Vitesse d'onde de pouls associé si souhaité, sinon laisser None (custom sensor, nom de l'axe : m/s)

timezone				= pytz.UTC

#################################### End of custom variable ########################################
####################################################################################################

# Extremely basic HTTP server for handling authorization response
class AuthorizationRepsponseHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global nokia_auth_code
        nokia_auth_code = parse_qs(urlparse(self.path).query).get('code', None)[0]
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write('<html><body><h1>Authorization successful!</h1></body></html>'.encode('utf-8'))

# Do command processing
class MyParser(OptionParser):
    def format_epilog(self, formatter):
        return self.epilog

usage = "usage: %prog [options] command [service]"
epilog = """
Commands:
  setup, sync

Service:
  nokia

Copyright (c) 2018 by Jacco Geul <jacco@geul.net>
Licensed under GNU General Public License 3.0 <https://github.com/magnific0/nokia-weight-sync/blob/master/LICENSE>
"""
dir_path = os.path.dirname(os.path.abspath(__file__))
parser = MyParser(usage=usage,epilog=epilog,version=__version__)

parser.add_option('-k', '--key', dest='key', help="Key/Username")
parser.add_option('-s', '--secret', dest='secret', help="Secret/Password")
parser.add_option('-u', '--callback', dest='callback', help="Callback/redirect URI")
parser.add_option('-a', '--authorization-server', dest='auth_serv', action="store_true", default=None, help="Authorization server")
parser.add_option('-c', '--config', dest='config', default='config.ini', help="Config file")

(options, args) = parser.parse_args()

if len(args) == 0:
    print("Missing command!")
    print("Available commands: setup, sync")
    sys.exit(1)

command = args.pop(0)

config = configparser.ConfigParser()
config.read(options.config)

def setup_nokia( options, config ):
    """ Setup the Nokia Health API
    """
    global nokia_auth_code
    if options.key is None:
        print("To set a connection with Nokia Health you must have registered an application at https://account.withings.com/partner/add_oauth2 .")
        options.key = input('Please enter the client id: ')

    if options.secret is None:
        options.secret = input('Please enter the consumer secret: ')

    if options.callback is None:
        options.callback = input('Please enter the callback url known by Nokia: ')

    if options.auth_serv is None:
        auth_serv_resp = input('Spin up HTTP server to automate authorization? [y/n] : ')
        if auth_serv_resp is 'y':
            options.auth_serv = True
        else:
            options.auth_serv = False

    if options.auth_serv:
        callback_parts = urlparse(options.callback)
        httpd_port = callback_parts.port
        httpd_ssl = callback_parts.scheme == 'https'
        if not httpd_port:
            httpd_port = 443 if httpd_ssl else 80
        certfile = None
        if httpd_ssl and not certfile:
            print("Your callback url is over https, but no certificate is present.")
            print("Change the scheme to http (also over at Nokia!) or specify a certfile above.")
            exit(0)

    auth = nokia.NokiaAuth(options.key, options.secret, options.callback)
    authorize_url = auth.get_authorize_url()
    print("Visit: %s\nand select your user and click \"Allow this app\"." % authorize_url)

    if options.auth_serv:
        httpd = HTTPServer(('', httpd_port), AuthorizationRepsponseHandler)
        if httpd_ssl:
            httpd.socket = ssl.wrap_socket(httpd.socket, certfile=certfile, server_side=True)
        httpd.socket.settimeout(100)
        httpd.handle_request()
    else:
        print("After redirection to your callback url find the authorization code in the url.")
        print("Example: https://your_original_callback?code=abcdef01234&state=XFZ")
        print("         example value to copy: abcdef01234")
        nokia_auth_code = input('Please enter the authorization code: ')
    creds = auth.get_credentials(nokia_auth_code)

    if not config.has_section('nokia'):
        config.add_section('nokia')

    config.set('nokia', 'consumer_key', options.key)
    config.set('nokia', 'consumer_secret', options.secret)
    config.set('nokia', 'callback_uri', options.callback)
    config.set('nokia', 'access_token', creds.access_token)
    config.set('nokia', 'token_expiry', creds.token_expiry)
    config.set('nokia', 'token_type', creds.token_type)
    config.set('nokia', 'refresh_token', creds.refresh_token)
    config.set('nokia', 'user_id', creds.user_id)



def save_config():
    # New Nokia tokens (if refreshed)
    if client_nokia:
        creds = client_nokia.get_credentials()
        if config.get('nokia', 'access_token') is not creds.access_token:
            config.set('nokia', 'access_token', creds.access_token)
            config.set('nokia', 'token_expiry', creds.token_expiry)
            config.set('nokia', 'refresh_token', creds.refresh_token)

    with open(options.config, 'w') as f:
        config.write(f)
        f.close()
    if debugging == True:
        print("Config file saved to %s" % options.config)

def auth_nokia( config ):
    """ Authenticate client with Nokia Health
    """
    creds = nokia.NokiaCredentials(config.get('nokia', 'access_token'),
                                   config.get('nokia', 'token_expiry'),
                                   config.get('nokia', 'token_type'),
                                   config.get('nokia', 'refresh_token'),
                                   config.get('nokia', 'user_id'),
                                   config.get('nokia', 'consumer_key'),
                                   config.get('nokia', 'consumer_secret')
                                   )
    client = nokia.NokiaApi(creds)
    return client

client_nokia = None
if command != 'setup':
    client_nokia = auth_nokia( config )

if command == 'setup':

    if len(args) == 1:
        service = args[0]
    else:
        print("You must provide the name of the service to setup. Available service is: nokia.")
        sys.exit(1)

    if service == 'nokia':
        setup_nokia( options, config )

    else:
        print('Unknown service (%s), available service is: nokia.')
        sys.exit(1)

elif command == 'sync':
    # user = client_nokia.get_user()
    # user_shortname = user['users'][0]['shortname']
    # user_shortname = 'DAD'
    measures = client_nokia.get_measures(limit=2)

    def log(message):
      if debugging == True:
        print(message)
        #log_message = urllib.parse.quote(("Nokia (" + str(user_shortname) + "): " + message).encode("utf-8"))
        log_message = urllib.parse.quote(("Nokia : " + message).encode("utf-8"))
        url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=addlogmessage&message=" + log_message
        urllib.request.urlopen(url , timeout = 5)

    def domoticzupdate(idx, value):
      url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx + "&nvalue=0&svalue=" + str(value)
      urllib.request.urlopen(url , timeout = 5)

    def domoticzupdateWeight(idx, value):
        url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + idx + "&svalue=" + str(value)
        urllib.request.urlopen(url , timeout = 5)

    def domoticzrequest(url):
      request = urllib.request.Request(url)
      response = urllib.request.urlopen(request)
      return response.read().decode('utf-8')
      
    if idx_weight != None:
      domoticzurl = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=devices&rid=" + idx_weight
      json_object = json.loads(domoticzrequest(domoticzurl))
      if json_object["status"] == "OK":
        if json_object["result"][0]["idx"] == idx_weight:
          lastupdate = json_object["result"][0]["LastUpdate"]
    ###############################################################################
    if measures[0].weight != None:
        x = 0
    elif measures[1].weight != None:
        x = 1
    if x != None:
        ###############################################################################          
        date = measures[x].date.isoformat()
        lastupdate = datetime.datetime.strptime(lastupdate, '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone).isoformat()
        log("Dernière mesure : %s " %date)
        log("Dernière mise à jour : %s " %lastupdate)

        should_update = date > lastupdate 
        #should_update = True #####################################################
        if should_update:
          log("Mise à jour des mesures")
        else:
          log("Aucune mise à jour nécessaire")

        ####################################################################################################
        weight = measures[x].weight

        if idx_weight != None and weight != None:
          if should_update:
            domoticzupdate(idx_weight, weight)

          if debugging == True:
            log("Votre poids : " + str(weight) + " kg")

        ####################################################################################################
        height = measures[x].height
        if height == None:
          height  = votre_taille / 100
        if idx_body_mass_index != None and height != None and weight != None:
          bmi = weight / (height*height)
          log("Indice de masse corporelle : %s kg/m2" % bmi)
          
          if should_update:
            domoticzupdate(idx_body_mass_index, bmi)

          if debugging == True:   
            log("Votre taille  : " + str(height) + " m")
            log("Votre indice de masse corporelle : " + str(bmi) + " kg/m2")
            
        ####################################################################################################
        fat_free_mass = measures[x].fat_free_mass

        if idx_fat_free_mass != None and fat_free_mass != None:
          if should_update:
            domoticzupdate(idx_fat_free_mass, fat_free_mass)

          if debugging == True:  
            log("Votre masse sans gras (muscle + os) est de " + str(fat_free_mass) + " kg")

        ####################################################################################################
        fat_ratio = measures[x].fat_ratio

        if idx_fat_ratio != None and fat_ratio != None:
          if should_update:
            domoticzupdate(idx_fat_ratio, fat_ratio)

          if debugging == True:  
            log("Votre taux de graisse : " + str(fat_ratio) + "%")

        if idx_lean_ratio != None and fat_ratio != None:
          lean_mass_ratio = 100 - fat_ratio
          
          if should_update:  
            domoticzupdate(idx_lean_ratio, lean_mass_ratio)

          if debugging == True:  
            log("Votre rapport de masse maigre : " + str(lean_mass_ratio) + "%")

        ####################################################################################################  
        fat_mass_weight =  measures[x].fat_mass_weight

        if idx_fat_mass_weight != None and fat_mass_weight != None:   
          if should_update:
            domoticzupdate(idx_fat_mass_weight, fat_mass_weight)

          if debugging == True:   
            log("Votre masse grasse : " + str(fat_mass_weight) + " kg")
            
        ####################################################################################################  
        if measures[0].heart_pulse != None:
            y = 0
        elif measures[1].heart_pulse != None:
            y = 1
        if y != None:    
            
            heart_pulse = measures[y].heart_pulse

            if idx_heart_pulse != None and heart_pulse != None:
              if should_update:
                domoticzupdate(idx_heart_pulse, heart_pulse)

              if debugging == True:   
                log("Votre pouls  : " + str(heart_pulse) + " bpm")
            
        ####################################################################################################      
        muscle_mass = measures[x].get_measure(76)

        if idx_muscle_mass != None and muscle_mass != None:
          if should_update:
            domoticzupdate(idx_muscle_mass, muscle_mass)  

          if debugging == True:   
            log("Votre masse musculaire : " + str(muscle_mass) + " kg")

        if idx_muscle_mass_ratio != None and muscle_mass != None and weight != None:
          muscle_mass_ratio = muscle_mass * 100 / weight
          
          if should_update:
            domoticzupdate(idx_muscle_mass_ratio, muscle_mass_ratio)  

          if debugging == True:   
            log("Votre rapport de masse musculaire : " + str(muscle_mass_ratio) + " %")
            
        ####################################################################################################
        hydration = measures[x].get_measure(77) 

        if idx_hydration != None and hydration != None:
          if should_update:
            domoticzupdate(idx_hydration, hydration)  

          if debugging == True:   
            log("Votre hydratation : " + str(hydration) + " kg")
            
        if idx_hydration_ratio != None and hydration != None and weight != None:
          hydration_ratio = hydration * 100 / weight
          
          if should_update:
            domoticzupdate(idx_hydration_ratio, hydration_ratio)  

          if debugging == True:   
            log("Votre taux d\'hydratation : " + str(hydration_ratio) + " %")
            
        ####################################################################################################
        bone_mass = measures[x].get_measure(88) 

        if idx_bone_mass != None and bone_mass != None:
          if should_update:  
            domoticzupdate(idx_bone_mass, bone_mass)  

          if debugging == True:   
            log("Votre masse osseuse : " + str(bone_mass) + " kg")
            
        if idx_bone_mass_ratio != None and bone_mass != None and weight != None:
          bone_mass_ratio = bone_mass * 100 / weight
          
          if should_update:  
            domoticzupdate(idx_bone_mass_ratio, bone_mass_ratio) 

          if debugging == True:   
            log("Votre rapport de masse osseuse : " + str(bone_mass_ratio) + " %")
            
        ####################################################################################################
        pulse_wave_velocity = measures[x].get_measure(91) 
          
        if idx_pulse_wave_velocity != None and pulse_wave_velocity != None:
          if should_update:
            domoticzupdate(idx_pulse_wave_velocity, pulse_wave_velocity) 

          if debugging == True:   
            log("La vitesse d\'onde de pouls: " + str(pulse_wave_velocity))
            
        ####################################################################################################
        
    if debugging == True:
        measures = client_nokia.get_measures(limit=2)[1]
        print(measures.date)
        if len(args) == 1:
            types = dict(nokia.NokiaMeasureGroup.MEASURE_TYPES)
            print(measures.get_measure(types[args[0]]))
        else:
            for n, t in nokia.NokiaMeasureGroup.MEASURE_TYPES:
                print("%s: %s" % (n.replace('_', ' ').capitalize(), measures.get_measure(t)))

else:
    print("Unknown command")
    print("Available commands: setup, sync")
    sys.exit(1)

save_config()
sys.exit(0)
