--[[   
~/domoticz/scripts/lua/script_time_dju.lua
auteur : papoo
MAJ : 07/01/2018
création : 26/12/2017
Principe :
Calculer, via l'information température d'une sonde extérieure, les Degrés jour Chauffage et Réfrigération "intégrales"
https://easydomoticz.com/forum/viewtopic.php?f=17&t=1876&p=46879#p46879
https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_dju.lua

trouvez le coefficient moyen de conversion Gaz/kwh pour votre commune sur https://www.grdf.fr/particuliers/services-gaz-en-ligne/coefficient-conversion
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging = false  			                -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local temp_ext  = 'Temperature exterieure' 	        -- nom de la sonde de température extérieure
local domoticzURL = '127.0.0.1:8080'                -- user:pass@ip:port de domoticz
local var_user_djc = 'dju'                          -- nom de la variable utilisateur de type 2 (chaine) pour le stockage temporaire des données journalières DJC
local cpt_djc = 'DJU 2' 				            -- nom du  dummy compteur DJC en degré
local heure_raz_var = 23                            -- heure de l'incrémentation du compteur DJC compteur_djc_idx et de remise à zéro de la variable utilisateur var_user_djc
local minute_raz_var = 59                           -- Minute de l'incrémentation du compteur DJC compteur_djc_idx et de remise à zéro de la variable utilisateur var_user_djc

local var_user_djr = nil                            -- nom de la variable utilisateur de type 2 (chaine) pour le stockage temporaire des données journalières DJR, nil si inutilisé
local cpt_djr = 'DJR'   				            -- nom du  dummy compteur DJR en degré, nil si vous ne souhaitez pas calculer les Degrés Jour Climatisation

local coef_gaz = 10.83                              -- coefficient moyen gaz pour votre commune
local cpt_gaz = 'Compteur Gaz'                      -- nom de votre compteur gaz, nil si vous ne souhaitez pas calculer l'énergie consommée             
local cpt_nrj = 'Energie consommée chauffage'       -- nom du dummy compteur nrj, nil si vous ne souhaitez pas totaliser l'énergie consommée en Wh
local var_user_gaz = 'conso_gaz'                    -- nom de la variable utilisateur de type 2 (chaine) pour le stockage temporaire des données

--------------------------------------------
----------- Fin variables à éditer ---------
-------------------------------------------- 
commandArray = {}
local nom_script = 'Calcul Degrés jour Chauffage et Réfrigération'
local version = '1.30'

local djc
local somme_djc
local reste_djc

local conso_gaz
local conso_nrj
local index_nrj

local djr
local somme_djr
local reste_djr

time=os.date("*t")
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
curl = '/usr/bin/curl -m 15 -u domoticzUSER:domoticzPSWD '
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
function calc_djc(temperature) -- calcul des degrés jour mode chauffage
djc  = tonumber((18 - temperature)*1/1440)
return djc
end
--==============================================================================================
function calc_djr(temperature)-- calcul des degrés jour mode réfrigération proposé par thuglife
djr  = tonumber((temperature - 18)*1/1440)
return djr
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
-- Obtenir le nom d'un device via son idx
function GetDeviceNameByIDX(deviceIDX) -- https://www.domoticz.com/forum/viewtopic.php?t=18736#p144720
    deviceIDX = tonumber(deviceIDX)
   for i, v in pairs(otherdevices_idx) do
      if v == deviceIDX then
         return i
      end
   end
   return 0
end -- exemple usage = commandArray[GetDeviceNameByIDX(383)] = 'On'
  
--==============================================================================================
-- Obtenir l'idx d'un device via son nom
function GetDeviceIdxByName(deviceName) 
   for i, v in pairs(otherdevices_idx) do
      if i == deviceName then
         return v
      end
   end
   return 0
end -- exemple usage = commandArray['UpdateDevice'] = GetDeviceIdxByName('Compteur Gaz') .. '|0|' .. variable

--============================================================================================== 
function timeDiff(dName,dType) -- retourne le temps en seconde depuis la dernière maj du péréphérique (Variable 'v' ou Device 'd' 
        if dType == 'v' then 
            updTime = uservariables_lastupdate[dName]
        elseif dType == 'd' then
            updTime = otherdevices_lastupdate[dName]
        end 
        t1 = os.time()
	y, m, d, H, M, S = updTime:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")	
    t2 = os.time{year=y, month=m, day=d, hour=H, min=M, sec=S}
        tDiff = os.difftime(t1,t2)
        return tDiff
    end -- usage: timeDiff(name,'v|d')	
--------------------------------------------
-------------- Fin Fonctions ---------------
-------------------------------------------- 

voir_les_logs("========= ".. nom_script .." (v".. version ..") =========",debugging)
-- calcul DJC et DJR
if otherdevices_svalues[temp_ext] ~= nil then
    if (uservariables[var_user_djc] == nil) then creaVar(var_user_djc,2,0)end
    
    temperature = tonumber(string.match(otherdevices_svalues[temp_ext], "%d+%.*%d*"))
    if temperature < 18 then --si la température extérieure est inférieure à 18
        voir_les_logs("--- --- Température extérieure : ".. temperature .."°C inférieure à 18°C --- ---",debugging)
        djc = calc_djc(temperature)
        voir_les_logs("--- --- DJC : ".. round(djc,5) .." --- ---",debugging)
        voir_les_logs("--- --- Variable DJC : ".. round(tonumber(uservariables[var_user_djc]),4) .." --- ---",debugging)
        somme_djc = tonumber(uservariables[var_user_djc]) + djc
        voir_les_logs("--- --- somme DJC : ".. round(somme_djc,4) .." --- ---",debugging)   
        commandArray[#commandArray+1] = {['Variable:'.. var_user_djc] = tostring(somme_djc)}
        cpt_djc_index = otherdevices_svalues[cpt_djc]
        voir_les_logs("--- --- compteur DJC : ".. cpt_djc_index .." --- ---",debugging)
    else --si la température extérieure est supérieure à 18 
        voir_les_logs("--- --- Température extérieure : ".. temperature .."°C  supérieure à 18°C --- ---",debugging)
        djr = calc_djr(temperature)
        voir_les_logs("--- --- DJR : ".. round(djr,5) .." --- ---",debugging)
        voir_les_logs("--- --- Variable DJR : ".. round(tonumber(uservariables[var_user_djr]),4) .." --- ---",debugging)
        somme_djr = tonumber(uservariables[var_user_djr]) + djr
        voir_les_logs("--- --- somme DJR : ".. round(somme_djr,4) .." --- ---",debugging)   
        commandArray[#commandArray+1] = {['Variable:'.. var_user_djr] = tostring(somme_djr)}
        cpt_djr_index = otherdevices_svalues[cpt_djr]
        voir_les_logs("--- --- compteur DJR : ".. cpt_djr_index .." --- ---",debugging)
        somme_djc = tonumber(uservariables[var_user_djc])
        voir_les_logs("--- --- somme DJC : ".. somme_djc .." --- ---",debugging)
    end -- fin si temp ext
 
    if tonumber(uservariables[var_user_djc]) > 1 and cpt_djc ~= nil then -- si variable djc supérieure à 1 on incrémente le compteur de 1 et on réduit la variable de 1 
    voir_les_logs("--- --- mise a jour compteur DJC --- ---",debugging)   
    reste_djc = tonumber(uservariables[var_user_djc]) - 1
        if timeDiff(cpt_djc,'d') < 119 then  -- on vérifie si le compteur à été rafraichi depuis moins de deux minutes si c'est le cas on soustrait 1 de la variable
            voir_les_logs("--- --- dernier rafraichissement compteur DJC : ".. timeDiff(cpt_djc,'d') .." secondes --- ---",debugging)
            commandArray[#commandArray+1] = {['Variable:'.. var_user_djc] = tostring(reste_djc)}            
            voir_les_logs("--- --- reste DJC : ".. tonumber(uservariables[var_user_djc]) .." --- ---",debugging)
        else  -- si le compteur n'as pas été rafraichi depuis moins de 2 minutes on l'incrémente de 1
            cpt_djc_index = tonumber(cpt_djc_index) + 1
            commandArray[#commandArray+1] = {['UpdateDevice'] = GetDeviceIdxByName(cpt_djc) .. '|0|'..tostring(cpt_djc_index)}
        end
    end
    if var_user_djr ~= nil then 
        if (uservariables[var_user_djr] == nil) then creaVar(var_user_djr,2,0)end
        if tonumber(uservariables[var_user_djr]) > 1 and cpt_djr ~= nil then -- si variable djr supérieure à 1 on incrémente le compteur de 1 et on réduit la variable de 1
        voir_les_logs("--- --- mise a jour compteur DJR --- ---",debugging)   
        reste_djr = tonumber(uservariables[var_user_djr]) - 1
            if timeDiff(cpt_djr,'d') < 119 then  -- on vérifie si le compteur à été rafraichi depuis moins de deux minutes si c'est le cas on soustrait 1 de la variable
                voir_les_logs("--- --- dernier rafraichissement compteur DJR : ".. timeDiff(cpt_djr,'d') .." secondes --- ---",debugging)
                commandArray[#commandArray+1] = {['Variable:'.. var_user_djr] = tostring(reste_djr)}           
                voir_les_logs("--- --- reste DJR : ".. tonumber(uservariables[var_user_djr]) .." --- ---",debugging)
            else  -- si le compteur n'as pas été rafraichi depuis moins de 2 minutes on l'incrémente de 1
                cpt_djr_index = tonumber(cpt_djr_index) + 1
                commandArray[#commandArray+1] = {['UpdateDevice'] = GetDeviceIdxByName(cpt_djr) .. '|0|'..tostring(cpt_djr_index)}
            end
        end 
    end    
else
    voir_les_logs("--- --- le device : ".. temp_ext .." n\'existe pas --- ---",debugging)
end -- fin si otherdevices_svalues[temp_ext] ~= nil 
-- fin calcul DJC et DJR
--==============================================================================================

-- calcul nrj consommée
if otherdevices_svalues[cpt_gaz] ~= nil then
    if (uservariables[var_user_gaz] == nil) then creaVar(var_user_gaz,2,0)end
    voir_les_logs("--- --- Compteur gaz : ".. otherdevices_svalues[cpt_gaz]/100 .." m3 --- ---",debugging) -- /100 car compteur gaz en décalitres, 1 impulsion tous les 0.01 m3
    voir_les_logs("--- --- Précédent index gaz : ".. uservariables[var_user_gaz]/100 .." m3 --- ---",debugging)-- /100 car compteur gaz en décalitres 1 impulsion tous les 0.01 m3
    conso_gaz = tonumber(otherdevices_svalues[cpt_gaz]/100) - tonumber(uservariables[var_user_gaz]/100) -- /100 car compteur gaz en décalitres, 1 impulsion tous les 0.01 m3
    voir_les_logs("--- --- Consommation gaz : ".. round(conso_gaz,4) .." m3 --- ---",debugging)
        if tonumber(conso_gaz) > 0 then
            conso_nrj = conso_gaz * coef_gaz -- transformation en kWh
            voir_les_logs("--- --- Coeff conversion gaz : ".. coef_gaz .." --- ---",debugging)   
            voir_les_logs("--- --- Consommation nrj : ".. conso_nrj .." kWh--- ---",debugging)
            
            if cpt_nrj ~= nil then
              index_nrj = otherdevices_svalues[cpt_nrj]
              voir_les_logs("--- --- Compteur nrj : ".. index_nrj .." kWh --- ---",debugging)
              conso_nrj = tonumber(conso_nrj) + tonumber(index_nrj)
                commandArray[#commandArray+1] = {['UpdateDevice'] = GetDeviceIdxByName(cpt_nrj) .. '|0|' .. conso_nrj}
            end
        end
    commandArray[#commandArray+1] = {['Variable:'.. var_user_gaz] = tostring(otherdevices_svalues[cpt_gaz])}
end
-- fin calcul nrj consommée
voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)

return commandArray