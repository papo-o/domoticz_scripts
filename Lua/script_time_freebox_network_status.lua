--[[
source : https://sites.google.com/site/au66bis/domoticz/scripts-lua/script_time_network_status 
https://easydomoticz.com/forum/viewtopic.php?f=10&t=3825&start=10#p35974
http://pon.fr/network-status-via-freebox-en-lua/
Procédure pour obtenir APPTOKEN http://easydomoticz.com/forum/viewtopic.php?f=7&t=289&p=5042&hilit=freebox#p5042
MAJ : 23/12/2017
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local nom_script = "FreeBox Network Status"
local version = "1.3"
local debugging = false  			-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
freebox_appid="Domoticz.app" --uservariables["freebox_appid"]
-- Créer une variable "freebox_mac_adress_smartphones" avec les MAC ADDRESS des smartphones. Le séparateur est ";"
freebox_mac_adress_smartphones=uservariables["freebox_mac_adress_smartphones"]
freebox_mac_adress_surveillance=uservariables["freebox_mac_adress_surveillance"]
-- Créer une variable "freebox_mac_adress_surveillance" avec les MAC ADDRESS des Smartphones N' entrant PAS en compte pour l'alarme. Le séparateur est ";"
freebox_apptoken=uservariables["freebox_apptoken"]
-- URL des API A CHANGER
apiFreeboxv4="http://mafreebox.freebox.fr/api/v4"
apiDomoticz="http://127.0.0.1:8080/json.htm?"
-- Session Token
session_token=""
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local patternMacAdresses = string.format("([^%s]+)", ";")

--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------   
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"
require('fonctions_perso')

function readAll(file)
    local f = io.open(file, "rb")
	if(f == nil) then
		return ""
	else
		local content = f:read("*all")
		f:close()
		return content
	end
end
-- Fonction de la connexion à la Freebox
-- Authentification pour récupérer le tokenDeSession
function connectToFreebox()
	voir_les_logs("Connexion a la Freebox",debugging)
	local TMPDIR_CHALLENGE = "/media/Freebox/Trend/challenge.tmp"
	local TMPDIR_APPTOKEN =  "/media/Freebox/Trend/apptoken.tmp"
	local TMPDIR_SESSIONTOKEN =  "/media/Freebox/Trend/sessiontoken.tmp"	
	-- CHALLENGE : Appel de login pour charger le challenge
	os.execute("curl -s " .. apiFreeboxv4 .. "/login > " .. TMPDIR_CHALLENGE)
	local json_challenge = JSON:decode(readAll(TMPDIR_CHALLENGE))
	local challenge = json_challenge.result.challenge
	voir_les_logs("  Challenge : " .. challenge,debugging)
	-- APP  TOKEN : Calcul du mot de passe
	voir_les_logs("Calcul HMAC SHA1",debugging)
	voir_les_logs("  AppToken : " .. freebox_apptoken,debugging)
	os.execute("echo -n " .. challenge .. " | openssl dgst -sha1 -hmac " .. freebox_apptoken .. " | cut -c10-200 > " .. TMPDIR_APPTOKEN)
	local password = readAll(TMPDIR_APPTOKEN)
	password=password:gsub("\n", "")
	voir_les_logs("  Password : " .. password,debugging)	
	-- CONNEXION Session Connect
	local table_app_session = {}
	table_app_session["app_id"]=freebox_appid
	table_app_session["password"]=password
	local json_app_session = JSON:encode_pretty(table_app_session)
	--	connexion à la session
	os.execute("curl -s -H \"Content-Type: application/json\" -X POST -d '" .. json_app_session .. "' " .. apiFreeboxv4 .. "/login/session/ > " .. TMPDIR_SESSIONTOKEN)
	local json_session_token = JSON:decode(readAll(TMPDIR_SESSIONTOKEN))
	session_token=json_session_token.result.session_token
	voir_les_logs("  Session Token : " .. session_token,debugging)
end
-- Fonction de la deconnexion à la Freebox
function disconnectToFreebox()
	local TMPDIR_DISCONNECT = "/media/Freebox/Trend/challenge.tmp" --"/tmp/challenge.tmp" 
	os.execute("curl -m 5 -s -H \"X-Fbx-App-Auth: " .. session_token .. "\" -X POST " .. apiFreeboxv4 .. "/login/logout > " .. TMPDIR_DISCONNECT)
	local disconnect = readAll(TMPDIR_DISCONNECT)
	voir_les_logs("  Deconnexion Freebox API : " .. disconnect)
end
-- Fonction de recherche des périphériques connectés
-- Connexion à lan/browser/pub/ pour lister les périphériques
-- @param session_token : token de session Freebox
-- @return périphériques connectés ?
function getPeripheriquesConnectes() -- liste les périphériques utilisés pour l'activation/désactivation automatique de l'alarme
	local TMP_PERIPHERIQUES = "/media/Freebox/Trend/peripheriques.tmp"
	--  Appel sur la liste des périphériques
	voir_les_logs("Recherche des peripheriques connus de la Freebox",debugging)
	local commandeurl="curl -s -H \"Content-Type: application/json\" -H \"X-Fbx-App-Auth: " .. session_token .. "\" -X GET " .. apiFreeboxv4 .. "/lan/browser/pub/"
	os.execute(commandeurl .. " > " .. TMP_PERIPHERIQUES)
	local json_peripheriques = JSON:decode(readAll(TMP_PERIPHERIQUES))
	local etatSmartphone = false
	-- Liste des périphériques
	for index, peripherique in pairs(json_peripheriques.result) do	
		for mac in string.gmatch(freebox_mac_adress_smartphones, patternMacAdresses) do
			local peripherique_mac_adress = "ether-" .. mac:lower()
			if(peripherique_mac_adress == peripherique.id)
			then
				voir_les_logs("Statut du peripherique ".. peripherique.primary_name.." [" .. mac .. "]  =>  actif:" .. tostring((peripherique.active and peripherique.reachable)),debugging)
				if(peripherique.active and peripherique.reachable) then
					etatSmartphone = true
                        if otherdevices[peripherique.primary_name] == 'Off' then
							commandArray [peripherique.primary_name]='On'
                            voir_les_logs("--- --- --- [FREEBOX] Activation de : " .. peripherique.primary_name .."  --- --- --- ",debugging)
						
                        end
							else
                        if otherdevices[peripherique.primary_name] == 'On' then    
							commandArray [peripherique.primary_name]='Off'
                            voir_les_logs("--- --- --- [FREEBOX] DesActivation de : " .. peripherique.primary_name .."  --- --- --- ",debugging)
						
                        end   
				end		
			end
		end
	end
return etatSmartphone
end
	
function getPeripheriquesConnectes2() -- liste les périphériques utilisés pour
	local TMP_PERIPHERIQUESHORSALARME = "/media/Freebox/Trend/peripheriques_hors_alarme.tmp"
	--  Appel sur la liste des périphériques
	voir_les_logs("Recherche des peripheriques connus de la Freebox (hors alarme)",debugging)
	local commandeurl="curl -s -H \"Content-Type: application/json\" -H \"X-Fbx-App-Auth: " .. session_token .. "\" -X GET " .. apiFreeboxv4 .. "/lan/browser/pub/"
	os.execute(commandeurl .. " > " .. TMP_PERIPHERIQUESHORSALARME)
	local json_other_peripheriques = JSON:decode(readAll(TMP_PERIPHERIQUESHORSALARME))
	etatPeripheriques = false
    -- Liste des périphériques HORS ALARME
	for index, other_peripherique in pairs(json_other_peripheriques.result) do	
		for mac in string.gmatch(freebox_mac_adress_surveillance, patternMacAdresses) do
			local other_peripherique_mac_adress = "ether-" .. mac:lower()
			if(other_peripherique_mac_adress == other_peripherique.id)
			then
				voir_les_logs("Statut du peripherique ".. other_peripherique.primary_name.." [" .. mac .. "]  =>  actif:" .. tostring((other_peripherique.active and other_peripherique.reachable)),debugging)
				if(other_peripherique.active and other_peripherique.reachable) then
                etatPeripheriques = true
                    if otherdevices[other_peripherique.primary_name] == 'Off' then
                        commandArray [other_peripherique.primary_name]='On'
                        voir_les_logs("--- --- --- [FREEBOX] Activation de : " .. other_peripherique.primary_name .."  --- --- --- ",debugging)
                    end
				else
                    if otherdevices[other_peripherique.primary_name] == 'On' then    
                        commandArray [other_peripherique.primary_name]='Off'
                        voir_les_logs("--- --- --- [FREEBOX] DesActivation de : " .. other_peripherique.primary_name .."  --- --- --- ",debugging)
                    end
				end		
			end
		end
	end	
return etatPeripheriques
end
-- Mise à jour de l'alarme suivant le statut des périphériques
-- @param : état des périphériques
function updateAlarmeStatus(etat_peripheriques)
	local etatActuelAlarme=otherdevices['Security Panel']
    voir_les_logs("  > Etat du panneau de securite = " .. etatActuelAlarme ,debugging)
	local SEUIL_ALARME = 1 -- temps en minute avant activation de l'alarme
	local TMPDIR_COMPTEUR_OUT = "/media/Freebox/Trend/compteur_smartphone_out.tmp"
	-- Activation de l'alarme au bout de X min
	if(not etat_peripheriques and etatActuelAlarme == "Normal") then
    --if(not etat_peripheriques) then
		compteurOff=readAll(TMPDIR_COMPTEUR_OUT)
		if(compteurOff == "") then
			compteurOff = 0
		end
		compteurOff = compteurOff + 1
		voir_les_logs("  > Compteur de mise en alarme = " .. compteurOff .. " / " .. SEUIL_ALARME,debugging)
		if(compteurOff >= SEUIL_ALARME) then
			voir_les_logs("Activation de l'alarme",debugging)
            commandArray[#commandArray+1] = {['Alarme Out']="On"}
            commandArray[#commandArray+1] = {['test presences']="Off"}          
			compteurOff = 0
		end
		os.execute("echo " .. compteurOff .. " > " .. TMPDIR_COMPTEUR_OUT)
	elseif(etat_peripheriques and etatActuelAlarme == "Arm Away") then
    -- Désactivation immédiate
		
        commandArray[#commandArray+1] = {['Alarme Out']="On"}
        commandArray[#commandArray+1] = {['test presences']="On"}
		voir_les_logs("Desactivation de l'alarme",debugging)

		os.execute("echo 0 > " .. TMPDIR_COMPTEUR_OUT)
	
	elseif(etat_peripheriques) then
		os.execute("echo 0 > " .. TMPDIR_COMPTEUR_OUT)
        commandArray[#commandArray+1] = {['test presences']="On"}
        voir_les_logs("Remise a zero du compte de l'alarme",debugging)
		
	end	
end
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
commandArray = {}
time=os.date("*t")
if time.min ~= 0 then -- execution toutes les minutes sauf à xx:00
		voir_les_logs("[FREEBOX] Statuts des peripheriques reseau Freebox",debugging)
	-- Boucle principale
    
	if( freebox_apptoken == nil or freebox_appid == nil or freebox_mac_adress_smartphones == nil or freebox_mac_adress_surveillance == nil ) then
		error("[FREEBOX] Les variables {freebox_apptoken}, {freebox_appid}, {freebox_mac_adress_smartphones}, {freebox_mac_adress_surveillance} ne sont pas definies dans Domoticz")
		return 512
	else
		voir_les_logs("Test de presence des appareils d'adresses MAC (" .. freebox_mac_adress_smartphones .. ")",debugging)
        voir_les_logs("Test de presence des appareils d'adresses MAC (" .. freebox_mac_adress_surveillance .. ")",debugging)
		JSON = (loadfile "/home/pi/domoticz/scripts/lua/JSON.lua")() -- one-time load of the routines
		-- Connexion à la Freebox
		connectToFreebox()
		-- Recherche des périphériques connectés
		peripheriques_up = getPeripheriquesConnectes()
		-- Recherche des périphériques connectés  (HORS ALARME)
		getPeripheriquesConnectes2()
		updateAlarmeStatus(peripheriques_up)
		-- Déconnexion à la Freebox
		disconnectToFreebox()
	end
end --if time	
return commandArray