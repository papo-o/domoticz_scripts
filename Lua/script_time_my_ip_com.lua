--[[
name : script_time_my_ip_com.lua
auteur : papoo
Date de mise à jour : 28/04/2018
date de création : 23/01/2018
Principe : tester, via l'api du site myip.com votre adresse publique et être notifié de chaque changement.
possibilité de tester une IP en V4 ou V6, d'être notifié seulement par mail en renseignant la variable EmailTo avec une plusieurs adresses mails, 
mais aussi avec toutes autres notifications paramétrées dans domoticz avec le choix de celles-ci (variable notification pour activer celles-ci, variable subsystem pour ne sélectionner qu'une ou plusieurs notifications parmi celles disponible
Le délai d"exécution est modifiable simplement (variable delai à renseigner en minutes) ainsi que l'activation/désactivation du fonctionnement de ce script (variable script_actif)
https://easydomoticz.com/forum/viewtopic.php?f=8&t=5732&p=48620#p48620
http://pon.fr/etre-notifie-de-son-changement-dip-publique-en-lua/
https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_my_ip_com.lua

/!\attention/!\
si vous souhaitez utiliser ce script dans l'éditeur interne, pour indiquer le chemin complet vers le fichier JSON.lua, il vous faudra changer la ligne 
json = assert(loadfile(luaDir..'JSON.lua'))()
par 
json = assert(loadfile('/le/chemin/vers/le/fichier/lua/JSON.lua'))()
exemple :
json = assert(loadfile('/home/pi/domoticz/scripts/lua/JSON.lua'))()
la reconnaissance automatique du chemin d'exécution de ce script ne fonctionnant pas dans l'éditeur interne
--]]
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false  			        -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif = true                   -- active (true) ou désactive (false) ce script simplement
local delai = 30                            -- délai d'exécution de ce script en minutes de 1 à 59 (délai entre deux appels à l'API)
local url_my_ip = "https://api.myip.com/"   -- Adresse de l'API permettant de connaitre l'IP publique
local var_my_ip = "IP Publique"             -- nom de la variable contenant l'IP publique
local type_ip = "v4"                        -- v4 pour les adresses en IPV4, v6 pour les adresses en IPV6
local domoticzURL = "127.0.0.1:8080"
local EmailTo = 'votre@mail.com'   -- adresses mail, séparées par ; si plusieurs (pour la notification par mail) nil si inutilisé
local notification = true                   -- true si l'on  souhaite être notifié  via le système de notification domoticz, sinon false.
local subsystem = "pushbullet"              -- les différentes valeurs de subsystem acceptées sont : gcm;http;kodi;lms;nma;prowl;pushalot;pushbullet;pushover;pushsafer;telegram
                                            -- pour plusieurs modes de notification séparez chaque mode par un point virgule (exemple : "pushalot;pushbullet"). si subsystem = nil toutes les notifications seront activées.
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
--------------------------------------------
------------- Autres Variables -------------
--------------------------------------------
local nom_script = 'Mon IP Publique'
local version = '0.41'
local ipv
local objet
local message

curl = '/usr/bin/curl -m 5 '		 	-- ne pas oublier l'espace à la fin

-- chemin vers le dossier lua
	if (package.config:sub(1,1) == '/') then
		 luaDir = debug.getinfo(1).source:match("@?(.*/)")
	else
		 luaDir = string.gsub(debug.getinfo(1).source:match("@?(.*\\)"),'\\','\\\\')
	end
	json = assert(loadfile(luaDir..'JSON.lua'))()						-- chargement du fichier JSON.lua
--------------------------------------------
----------- Fin Autres Variables -----------
--------------------------------------------	
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"   -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script
require('fonctions_perso')                                                      -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script

-- ci-dessous les lignes à décommenter en cas d'utilisation des fonctions directement dans ce script( supprimer --[[ et --]])
--[[function voir_les_logs (s, debugging) -- nécessite la variable local debugging
    if (debugging) then 
		if s ~= nil then
        print (s)
		else
		print ("aucune valeur affichable")
		end
    end
end	-- usage voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
--------------------------------------------
function creaVar(vname,vvalue,vtype) -- pour créer une variable nommée toto comprenant la valeur 10, de type 2
    if vtype ~= nil then
        os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(vname)..'&vtype='..vtype..'&vvalue='..url_encode(vvalue)..'" &')
    else
        os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(vname)..'&vtype=2&vvalue='..url_encode(vvalue)..'" &')
    end
end -- usage :  creaVar('toto','10','2') ou creaVar('toto','10')
--------------------------------------------
function url_encode(str) -- encode la chaine str pour la passer dans une url 
   if (str) then
   str = string.gsub (str, "\n", "\r\n")
   str = string.gsub (str, "([^%w ])",
   function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   end
   return str
end 
--]]
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
commandArray = {}
time = os.date("*t")

if script_actif == true then
    if ((time.min-1) % delai) == 0 then -- toutes les xx minutes en commençant par xx:01    
        voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)

        --=========== Lecture json ===============--
        if type_ip == "v6" then ipv = 6 else ipv = 4 end
        -- local config = assert(io.popen(curl..'-6 "'.. url_my_ip ..'"'))
        -- else 
        voir_les_logs('--- --- --- '..curl..'-'..ipv..' "'.. url_my_ip ..'"',debugging)
        local config = assert(io.popen(curl..'-'..ipv..' "'.. url_my_ip ..'"')) 
        --end
        local blocjson = config:read('*all')
        config:close()
        local jsonValeur = json:decode(blocjson)
        if jsonValeur then
            local adresse = jsonValeur.ip
            local country = jsonValeur.country
            local cc = jsonValeur.cc

            voir_les_logs('--- --- --- Adresse IP Publique : '..adresse,debugging)
            voir_les_logs('--- --- --- pays : '..country,debugging)
            voir_les_logs('--- --- --- code pays format ISO 3166-1 alpha-2 : '..cc,debugging)
            --=========== Variable  ===============--
            if var_my_ip ~= nil and var_my_ip ~= "" then -- le nom de la variable utilisateur a-t-il été renseigné ?
                if(uservariables[var_my_ip] == nil) then -- Création de la variable  car elle n'existe pas
                    voir_les_logs("--- --- --- La Variable " .. var_my_ip .." n'existe pas --- --- --- ",debugging)
                    voir_les_logs("--- --- --- adresse " .. adresse .."  --- --- --- ",debugging);
                    voir_les_logs("--- --- --- Création de la Variable " .. var_my_ip .." manquante --- --- --- ",debugging)
                    creaVar(var_my_ip, 'adresse inconnue',2)
                    print('script supendu')
                else
                    voir_les_logs("--- --- --- La Variable " .. var_my_ip .." est à : ".. uservariables[var_my_ip],debugging)
                end
            --=========== Vérification  ===============--            
                if(uservariables[var_my_ip] == adresse ) then
                    voir_les_logs("--- --- --- adresse " .. adresse .."  --- --- --- ",debugging);                
                else 
                    commandArray['Variable:'.. var_my_ip] = tostring(adresse) -- mise à jour de la variable utilisateur
                    if EmailTo ~= nil then
                        message = 'La nouvelle adresse IP est maintenant => http://'..adresse..':8080'
                        voir_les_logs("--- --- --- Notification par mail activée",debugging)            
                        objet = 'Changement de l\'adresse IP  à '..os.date("%H:%M")
                        voir_les_logs("--- --- --- Objet:"..objet,debugging)
                        voir_les_logs("--- --- --- Corps du message: "..message,debugging)
                        voir_les_logs("--- --- --- Destinataire: "..EmailTo,debugging)
                        commandArray[#commandArray+1] = {['SendEmail'] =  objet..'#'.. message  .. '#' .. EmailTo}
                    else
                        voir_les_logs("--- --- --- Notification par mail désactivée",debugging)  
                    end -- if notif_mail
                    
                    if notification ~= nil then -- notifications système
                        if subsystem ~= nil then
                            voir_les_logs("--- --- --- Notification système activée pour les services "..subsystem,debugging)
                            commandArray[#commandArray+1] = {['SendNotification'] = 'Attention# L\'adresse IP vient de changer. La nouvelle adresse est maintenant : http://'..adresse..':8080#0###'.. subsystem ..''}
                        else
                            voir_les_logs("--- --- --- toutes les Notifications système sont activées",debugging)
                            commandArray[#commandArray+1] = {['SendNotification'] = 'Attention# L\'adresse IP vient de changer. La nouvelle adresse est maintenant : http://'..adresse..':8080'}
                        end
                    end
                    
                end
            else
                voir_les_logs("--- --- --- La Variable  var_my_ip n\'a pas été renseignée, impossible de surveiller le changement",debugging)        
            end
        else
            voir_les_logs('--- --- --- aucun resultat a decoder',debugging)
        end --if jsonValeur
    --------------------------------------------============================================	

    voir_les_logs("======== Fin ".. nom_script .." (v".. version ..") ==========",debugging)        
    end        
end -- if script_actif
return commandArray
