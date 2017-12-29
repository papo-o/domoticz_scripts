--[[     Calcul DJU du jour
name : script_variable_calcul_dju.lua
auteur : papoo
version : 1.15
mise à jour : 17/08/2016
création : 08/05/2016

Principe :
Un degré jour est calculé à partir des températures météorologiques extrêmes du lieu et du jour J : 
- Tn : température minimale du jour J mesurée à 2 mètres du sol sous abri et relevée entre J-1 (la veille) à 18h et J à 18h UTC. 
- Tx : température maximale du jour J mesurée à 2 mètres du sol sous abri et relevée entre J à 6h et J+1 (le lendemain) à 6h UTC. 
- S : seuil de température de référence choisi. 
- Moy = (Tn + Tx)/2 Température Moyenne de la journée
Pour un calcul de déficits  de température par rapport au seuil choisi : 
- Si S > TX (cas fréquent en hiver) : DJ = S - Moy 
- Si S ≤ TN (cas exceptionnel en début ou en fin de saison de chauffe) : DJ = 0 
- Si TN < S ≤ TX (cas possible en début ou en fin de saison de chauffe) : DJ = ( S –TN ) * (0.08 + 0.42 * ( S –TN ) / ( TX – TN ))
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false  					-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local S = 18 								-- seuil de température de non chauffage (par convention : 18°C)
local temp_ext  = 'Temperature exterieure' 	-- nom de la sonde extérieure
local var_chauffage="Nb Jours de Chauffage" -- nom de la variable permettant de compter le nombre de jour de chauffage et de connaitre l'état du chauffage  0 = Arret, >0 Nb de jours
local url = '127.0.0.1:8080'   			-- user:pass@ip:port de domoticz
local idx_dju = 474 						-- IDX du compteur virtuel DJU à créer avant de lancer ce script
local name_dju = "DJU" 						-- Nomp du compteur virtuel DJU à créer avant de lancer ce script

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------

--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
function voir_les_logs (s, debugging)
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>")
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>")
		end
    end
end	

function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str   
end 

function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
commandArray = {}

if uservariablechanged[var_chauffage] then

voir_les_logs("=========== Calcul DJU (v1.0) ===========",debugging)
--[[		if(uservariables[var_chauffage] == nil) then -- Création de la variable Tx car elle n'existe pas
		voir_les_logs("--- --- --- La Variable " .. var_chauffage .." n'existe pas --- --- --- ",debugging)
		         commandArray['OpenURL']=url..'/json.htm?type=command&param=saveuservariable&vname='..url_encode(var_chauffage)..'&vtype=2&vvalue=1'
		 adresse = url_encode(var_chauffage)
		voir_les_logs("--- --- --- adresse " .. adresse .."  --- --- --- ",debugging)
		voir_les_logs("--- --- --- Création Variable " .. var_chauffage .." manquante --- --- --- ",debugging)
        print('script supendu')
			else
]]--	
	total_dju = string.match(otherdevices_svalues[name_dju], "%d+%.*%d*")
			voir_les_logs("--- --- --- Total DJU : ".. total_dju .." DJU",debugging)
		
	if (tonumber(uservariables[var_chauffage]) > 0) then --le chauffage est allumé, calcul des DJU
		voir_les_logs("--- --- --- Nb de jour de chauffage : " .. tonumber(uservariables[var_chauffage]) .." --- --- --- ",debugging)
		
		max_min = string.match(otherdevices_svalues[temp_ext], "%d+%.*%d*")
		t_max_min = tonumber(max_min)
		voir_les_logs("--- --- --- Température Ext : "..t_max_min,debugging)

		TN = tonumber(uservariables['Tn_Hold'])
		TX = tonumber(uservariables['Tx'])
		MOY = tonumber((TN + TX) / 2)

		if (S > TX) then
			voir_les_logs("--- --- --- Température de référence supérieure à Variable Tx : ".. TX,debugging)
			voir_les_logs("--- --- --- Température de référence : ".. S,debugging)
			voir_les_logs("--- --- --- Variable TX : ".. TX,debugging)
			voir_les_logs("--- --- --- Moyenne : ".. MOY,debugging)
			DJ = round(S - MOY)
			voir_les_logs("--- --- --- DJU : ".. DJ,debugging)
			-- commandArray['UpdateDevice']= idx_dju ..'|0|'.. tostring(DJ)
			DJ = tonumber(DJ) + tonumber(total_dju) -- on ajoute les DJU du jour à l'index précédent
			commandArray[#commandArray+1] = {['UpdateDevice'] = idx_dju..'|0|'..tostring(DJ)}
			
			commandArray[#commandArray+1] = {['Variable:Tx'] = tostring(-50)} -- Réinitialisation variable Tx
			

		elseif (S <= TN) then
			voir_les_logs("--- --- --- Température de référence inférieure ou égale à Variable Tn : ".. TN,debugging)
		--commandArray['Variable:Tx'] = tostring(t_max_min) -- mise à jour de la variable tx
			voir_les_logs("--- --- --- Température de référence : ".. S,debugging)
			voir_les_logs("--- --- --- Variable Tn : ".. TN,debugging)
			voir_les_logs("--- --- --- Moyenne : ".. MOY,debugging)
			DJ = 0
			voir_les_logs("--- --- --- DJU : ".. DJ,debugging)	
			DJ = tonumber(total_dju) -- on renvoi l'index du jour précédent
			-- commandArray['UpdateDevice']= idx_dju ..'|0|'.. tostring(DJ)
			DJ = tonumber(DJ) + tonumber(total_dju) -- on ajoute les DJU du jour à l'index précédent
			commandArray[#commandArray+1] = {['UpdateDevice'] = idx_dju..'|0|'..tostring(DJ)}
			
			commandArray[#commandArray+1] = {['Variable:Tx'] = tostring(-50)} -- Réinitialisation variable Tx
			
		else 
			voir_les_logs("--- --- --- Température de référence comprise entre Tn et Tx",debugging)
			-- commandArray['Variable:Tx'] = tostring(t_max_min) -- mise à jour de la variable tx
			voir_les_logs("--- --- --- Température de référence : ".. S,debugging)
			voir_les_logs("--- --- --- Variable TN : ".. TN,debugging)
			voir_les_logs("--- --- --- Variable TX : ".. TX,debugging)
			voir_les_logs("--- --- --- Moyenne : ".. MOY,debugging)
			S_TN = 	S - TN
			voir_les_logs("--- --- --- S - TN : ".. S_TN,debugging)
			TX_TN = TX - TN
			voir_les_logs("--- --- --- TX - TN : ".. TX_TN,debugging)
			DJ =  round(S_TN  * ("0.08" + "0.42" * S_TN / TX_TN))
			--DJ = ( S – TN ) * ('0.08' + '0.42' * ( S – TN ) / ( TX - TN ))
			voir_les_logs("--- --- --- DJU : ".. DJ,debugging)
			--commandArray['UpdateDevice']= idx_dju ..'|0|'.. tostring(DJ)
			DJ = tonumber(DJ) + tonumber(total_dju) -- on ajoute les DJU du jour à l'index précédent
			commandArray[#commandArray+1] = {['UpdateDevice'] = idx_dju..'|0|'..tostring(DJ)}
			
			commandArray[#commandArray+1] = {['Variable:Tx'] = tostring(-50)} -- Réinitialisation variable Tx
	
		end
	--commandArray['Variable:'.. var_chauffage]=tostring(tonumber(uservariables[var_chauffage])+1)  -- Ajoute un jour de chauffage supplémentaire dans la variable			
	else -- Le chauffage est éteint, pas de calcul de DJU
		voir_les_logs("--- --- --- Nb de jour de chauffage : " .. tonumber(uservariables[var_chauffage]) .." --- --- --- ",debugging)
		voir_les_logs("--- --- --- Le chauffage est arrêté --- --- --- ",debugging)
		commandArray[#commandArray+1] = {['Variable:Tx'] = tostring(-50)} -- Réinitialisation variable Tx
		
		commandArray[#commandArray+1] = {['UpdateDevice'] = idx_dju..'|0|0'} -- Remise à zéro des Dju
		
	end

		
voir_les_logs("=========== Fin Calcul DJU (v1.0) ===========",debugging)
end	
return commandArray


