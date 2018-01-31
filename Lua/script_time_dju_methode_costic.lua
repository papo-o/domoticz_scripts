--[[   
~/domoticz/scripts/lua/script_time_dju_methode_costic.lua
auteur : papoo
MAJ : 31/01/2018
création : 29/01/2018
Principe :
Calculer, via l'information température d'une sonde extérieure, les Degrés jour Chauffage méthode COSTIC

Création automatique du device compteur et des variables nécessaire au fonctionnement de ce script.
pour cela, uploadez ou créez ce script dans le répertoire domoticz/scripts/lua/ 
éditer éventuellement les noms des devices à créer, passez la variable script_actif à true, sauvegardez et vérifiez vos logs.

Un degré jour est calculé à partir des températures météorologiques extrêmes du lieu et du jour J : 
- Tn : température minimale du jour J mesurée à 2 mètres du sol sous abri et relevée entre J-1 (la veille) à 18h et J à 18h UTC. 
- Tx : température maximale du jour J mesurée à 2 mètres du sol sous abri et relevée entre J à 6h et J+1 (le lendemain) à 6h UTC. 
- S : seuil de température de référence choisi. 
- Moy = (Tn + Tx)/2 Température Moyenne de la journée
Pour un calcul de déficits  de température par rapport au seuil choisi : 
- Si S > TX (cas fréquent en hiver) : DJ = S - Moy 
- Si S ≤ TN (cas exceptionnel en début ou en fin de saison de chauffe) : DJ = 0 
- Si TN < S ≤ TX (cas possible en début ou en fin de saison de chauffe) : DJ = ( S – TN ) * (0.08 + 0.42 * ( S –TN ) / ( TX – TN ))

https://easydomoticz.com/forum/viewtopic.php?f=17&t=1876&p=46879#p46879
https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_dju_methode_costic.lua
--]]
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging = true  			                -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif = false                           -- active (true) ou désactive (false) ce script simplement
local temp_ext  = 'Temperature exterieure' 	        -- nom de la sonde de température extérieure
local domoticzURL = '127.0.0.1:8080'                -- user:pass@ip:port de domoticz
local var_user_djc = 'dju_methode_costic'           -- nom de la variable utilisateur de type 2 (chaine) pour le stockage temporaire des données journalières DJC
local Tn = "Tn_methode_costic"                      -- température maximale du jour J relevée entre J à 6h et J+1 (le lendemain) à 6h UTC
local Tx = "Tx_methode_costic"                      -- température minimale du jour J relevée entre J-1 (la veille) à 18h et J à 18h UTC.
local Tn_hold = "Tn_Hold_methode_costic"            -- variable de stockage de la température mini.
local S = 18                                        -- seuil de température de non chauffage, par convention : 18°C
local cpt_djc = 'DJU méthode COSTIC' 				-- nom du  dummy compteur DJC en degré
-- local heure_raz_var = 23                         -- heure de l'incrémentation du compteur DJC compteur_djc_idx et de remise à zéro de la variable utilisateur var_user_djc
-- local minute_raz_var = 59                        -- Minute de l'incrémentation du compteur DJC compteur_djc_idx et de remise à zéro de la variable utilisateur var_user_djc

-- local var_user_djf = nil                         -- nom de la variable utilisateur de type 2 (chaine) pour le stockage temporaire des données journalières DJF, nil si inutilisé
-- local cpt_djf = 'DJF'   				            -- nom du  dummy compteur DJF en degré, nil si vous ne souhaitez pas calculer les Degrés Jour Climatisation


--------------------------------------------
----------- Fin variables à éditer ---------
-------------------------------------------- 
commandArray = {}
local nom_script = 'Calcul Degrés jour Chauffage méthode COSTIC'
local version = '0.3'
local id
local djc
local somme_djc
local reste_djc

local djf
local somme_djf
local reste_djf

time=os.date("*t")

--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
curl = '/usr/bin/curl -m 15 -u domoticzUSER:domoticzPSWD '
if (package.config:sub(1,1) == '/') then
     luaDir = debug.getinfo(1).source:match("@?(.*/)")
else
     luaDir = string.gsub(debug.getinfo(1).source:match("@?(.*\\)"),'\\','\\\\')
end
json = assert(loadfile(luaDir..'JSON.lua'))()-- chargement du fichier JSON.lua

--==============================================================================================
function voir_les_logs (s, debbuging)
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>");
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>");
		end
    end
end	

--==============================================================================================
function round(value, digits)
	if not value or not digits then
		return nil
	end
		local precision = 10^digits
        return (value >= 0) and
		  (math.floor(value * precision + 0.5) / precision) or
		  (math.ceil(value * precision - 0.5) / precision)
end

--============================================================================================== 
function url_encode(str) -- encode la chaine str pour la passer dans une url 
   if (str) then
   str = string.gsub (str, "\n", "\r\n")
   str = string.gsub (str, "([^%w ])",
   function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   end
   return str
end

--============================================================================================== 
function creaVar(vname,vtype,vvalue) -- pour créer une variable de type 2 nommée toto comprenant la valeur 10
	os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(vname)..'&vtype='..vtype..'&vvalue='..url_encode(vvalue)..'" &')
end -- usage :  creaVar('toto','2','10') 

--==============================================================================================
function DeviceInfos(device)  
    --[[
    inspiré de  http://www.domoticz.com/forum/viewtopic.php?f=61&t=15556&p=115795&hilit=otherdevices_SwitchTypeVal&sid=dda0949f5f3d71cb296b865a14827a34#p115795
    Attributs disponibles :
    AddjMulti; AddjMulti2; AddjValue; AddjValue2; BatteryLevel; CustomImage; Data; Description; Favorite; 
    HardwareID; HardwareName; HardwareType; HardwareTypeVal; HaveDimmer; HaveGroupCmd; HaveTimeout; ID; 
    Image; IsSubDevice; LastUpdate; Level; LevelInt; MaxDimLevel; Name; Notifications; PlanID; PlanIDs; 
    Protected; ShowNotifications; SignalLevel; Status; StrParam1; StrParam2; SubType; SwitchType; 
    SwitchTypeVal; Timers; Type; TypeImg; Unit; Used; UsedByCamera; XOffset; YOffset; idx
    --]]
local config = assert(io.popen(curl..'"'.. domoticzURL ..'/json.htm?type=devices&rid='..otherdevices_idx[device]..'"'))
local blocjson = config:read('*all')
config:close()
local jsonValeur = json:decode(blocjson)
local attrib = attribut
    if jsonValeur ~= nil then
        return json:decode(blocjson).result[1]    
    end       
end --[[usage : 
        local attribut = DeviceInfos(cpt_djc)
        if attribut.SwitchTypeVal == 0 then    end
    --]]
    
--==============================================================================================

--------------------------------------------
-------------- Fin Fonctions ---------------
-------------------------------------------- 
if script_actif == true then
    voir_les_logs("========= ".. nom_script .." (v".. version ..") =========",debugging)
    if otherdevices[cpt_djc] == nil then
        -- recherche d'un hardware dummy pour l'associer au futur compteur
    	local config = assert(io.popen(curl..'"'.. domoticzURL ..'/json.htm?type=hardware" &'))
        local blocjson = config:read('*all')
        config:close()
        local jsonValeur = json:decode(blocjson)
			if jsonValeur ~= nil then
			   for Index, Value in pairs( jsonValeur.result ) do
                   if Value.Type == 15 then -- hardware dummy = 15
                      voir_les_logs("--- --- --- idx hardware dummy  : ".. Value.idx .." --- --- ---",debugging)
                      voir_les_logs("--- --- --- Nom hardware dummy  : ".. Value.Name .." --- --- ---",debugging)                  
                      id = Value.idx
                   end  
			   end
			end
        if id ~= nil then 
            voir_les_logs("--- --- --- création du device RFXMeter  : ".. cpt_djc .. " --- --- ---",debugging) 
            os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=createvirtualsensor&idx='..id..'&sensorname='..url_encode(cpt_djc)..'&sensortype=113"')                      
        end
    else     
        local attribut = DeviceInfos(cpt_djc)
        if attribut.SwitchTypeVal == 0 then
            voir_les_logs("--- --- --- modification du device RFXMeter  : ".. cpt_djc .. " en compteur de type 3  --- --- ---",debugging) 
            os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=setused&idx='..otherdevices_idx[cpt_djc]..'&name='..url_encode(cpt_djc)..'&switchtype=3&used=true"')
        end
    end -- if otherdevices[cpt_djc]
    
    -- calcul DJCvoir_les_logs("--- --- --- Température Ext : "..temperature,debugging) 
    if otherdevices_svalues[temp_ext] ~= nil then
     
        if (uservariables[Tx] == nil) then creaVar(Tx,2,"-150")end
        if (uservariables[Tn] == nil) then creaVar(Tn,2,150)end
        if (uservariables[Tn_hold] == nil) then creaVar(Tn_hold,2,150)end
        
        if (uservariables[Tx] ~= nil) and (uservariables[Tn] ~= nil) and (uservariables[Tn_hold] ~= nil) then
            temperature = tonumber(string.match(otherdevices_svalues[temp_ext], "%d+%.*%d*"))
            voir_les_logs("--- --- --- Température Ext : "..temperature,debugging)            
            if temperature < S then --si la température extérieure est inférieure au seuil S défini dans les variables
            voir_les_logs("--- --- --- Température Extérieure inférieure au seuil de ".. S .."°c",debugging)
                if temperature < tonumber(uservariables[Tn]) then
                    voir_les_logs("--- --- --- Température Extérieure inférieure à Variable Tn : "..uservariables[Tn],debugging)
                    commandArray[#commandArray+1] = {['Variable:'.. Tn] = tostring(temperature)} -- mise à jour de la variable tn
                    voir_les_logs("--- --- --- mise à jour de la Variable Tn  --- --- --- ",debugging)
                elseif temperature > tonumber(uservariables[Tx]) then
                    voir_les_logs("--- --- --- Température Extérieure supérieure à Variable Tx : "..uservariables[Tx],debugging)
                    commandArray[#commandArray+1] = {['Variable:'.. Tx] = tostring(temperature)} -- mise à jour de la variable tx
                    voir_les_logs("--- --- --- mise à jour de la Variable Tx  --- --- --- ",debugging)	
                end
            end    
        end
    else
        voir_les_logs("--- --- le device : ".. temp_ext .." n\'existe pas --- ---",debugging)
    end -- fin si otherdevices_svalues[temp_ext] ~= nil 

if (time.min == 0 and time.hour == 2) then 
local temp_mini = tonumber(uservariables[Tn])
commandArray[#commandArray+1] = {['Variable:'.. Tn_Hold] = tostring(temp_mini)} -- mise à jour de la variable Tn_Hold
commandArray[#commandArray+1] = {['Variable:'.. Tn] = tostring(150)} -- ré-initialisation de la variable Tn
end
if (time.min == 0 and time.hour == 18) then 
    local temp_mini_hold = tonumber(uservariables[Tn_hold])
    if temp_mini ~= 150 then
        local temp_maxi = tonumber(uservariables[Tx])
        local moyenne = tonumber((temp_mini_hold + temp_maxi)/2)
        S = tonumber(S)

        if S > temp_maxi then
            djc = S - moyenne
        elseif S <= temp_mini_hold then
            djc = 0   
        elseif temp_mini_hold < S and S < temp_maxi then 
            local a = S - temp_mini_hold
            local b = temp_maxi - temp_mini_hold
            --local c = 0.08 + 0.42 * ( a / b)
            --local d = 
            djc = a * ( 0.08 + 0.42 * a / b )
            djc = round(djc,0)
                --djc = ( S – temp_mini_hold ) * (0.08 + 0.42 * ( S – temp_mini_hold ) / ( temp_maxi – temp_mini_hold ) )
        end
        commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[cpt_djc] .. '|0|'..tostring(djc)} --mise à jour du compteur
        commandArray[#commandArray+1] = {['Variable:'.. Tx] = tostring(-150)} -- mise à jour de la variable Tx
    else
        voir_les_logs("--- --- --- Calcul impossible, il n\'y a pas de Température minimum enregistrée, attendre le prochain calcul",debugging)
    end
end

    -- fin calcul DJC et DJF
    -- --==============================================================================================

    voir_les_logs("======= Fin ".. nom_script .." (v".. version ..") =======",debugging)
end
return commandArray