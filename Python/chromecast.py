#!/usr/bin/python3
from __future__ import print_function
import sys; sys.path.insert(0,'/usr/local/lib/python3.6/dist-packages/')
import time
import pychromecast #https://github.com/balloob/pychromecast/tree/master/pychromecast  sudo pip3 install pychromecast --upgrade
from gtts import gTTS #https://github.com/pndurette/gTTS  sudo pip3 install gTTS --upgrade
#import sys
URL_DOMOTICZ = 'http://192.168.100.248:8080/' # renseigner l'adresse et le port de votre domoticz
for arg in sys.argv:
	print(arg)
tts = gTTS(text=arg, lang='fr', slow=False)
tts.save("/home/pi/domoticz/www/notification.mp3")

chromecasts = pychromecast.get_chromecasts()

[cc.device.friendly_name for cc in chromecasts]
['Salon','Bureau'] # mettre le nom de votre chromecast séparé par une virgule ex: ['douche', 'salon', 'cuisine', 'chambre'] 
	
cast = next(cc for cc in chromecasts if cc.device.friendly_name == "Salon" )

cast.wait()

mc = cast.media_controller

mc.play_media(URL_DOMOTICZ+'notification.mp3', 'audio/mp3')

mc.block_until_active()

mc.pause()
time.sleep(1)
mc.play()

cast = next(cc for cc in chromecasts if cc.device.friendly_name == "Bureau" )

cast.wait()

mc = cast.media_controller

mc.play_media(URL_DOMOTICZ+'notification.mp3', 'audio/mp3')

mc.block_until_active()

mc.pause()
time.sleep(1)
mc.play()
