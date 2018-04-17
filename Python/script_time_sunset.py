#!/usr/bin/python
debugging = False  #True  

import DomoticzEvents as DE
import datetime

script_actif = True

if script_actif == True:
  time = datetime.datetime.now() # http://sametmax.com/manipuler-les-dates-et-les-durees-en-python/
  if time.minute % 58 == 0: # pour les minutes en commençant par HH:01
  #if (time.minute-1) % 2 == 0: # pour les minutes en commençant par HH:01
  #if time.hour % 1 == 0: # pour les heures

          
      if debugging == True: 
          DE.Log("<font color='#f3031d'>Python: Le if marche!</font>")
      if DE.is_daytime:
          DE.Log("<font color='#f3031d'>Python: C'est le jour!</font>")

      if DE.is_nighttime:
          DE.Log("<font color='#f3031d'>Python: C'est la nuit!</font>")
          #DE.Log("<font color='#f3031d'>Python: Sunrise in minutes: </font>" + str(DE.sunrise_in_minutes))
          #DE.Log("Python: Sunset in minutes: " + str(DE.sunset_in_minutes))
          #DE.Log("Python: Minutes since midnight: " + str(DE.minutes_since_midnight))

          # All user_variables are treated as strings, convert as necessary    
          # for key, value in DE.user_variables.items():
              # DE.Log("Python: User-variable '{0}' has value: {1}".format(key, value))

          DE.Log("<font color='#f3031d'>Python: Heure : </font>" + str(time.hour))
          DE.Log("<font color='#f3031d'>Python: Minute : </font>" + str(time.minute))
          DE.Log("<font color='#f3031d'>Python: Jour : </font>" + str(time.day))