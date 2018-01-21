--[[
name : script_time_liveboxTV.lua.lua
auteur : papoo
date de création : 21/01/2018
Date de mise à jour : 21/01/2018
Principe : Via l'api de la livebox TV, connaitre son état et afficher la chaine en cours d'affichage
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = true  			            -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif = true                       -- active (true) ou désactive (false) ce script simplement
local device_chaine = "Chaine Livebox"          -- nom du  dummy text affichant la chaine en cours de lecture
local livebox_tv = "Livebox TV"                 -- nom du  dummy interrupteur pour connaitre l'état de la livebox TV, nil si inutilisé
local liveboxtv_ip = "http://192.168.1.12:8080"  -- adresse ip de la livebox TV
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
--------------------------------------------
------------- Autres Variables -------------
--------------------------------------------
local nom_script = 'Chaine liveboxTV'
local version = '0.1'
local les_chaines = {}
les_chaines[#les_chaines+1] = {canal="1", nom="TF1", id="192"}
les_chaines[#les_chaines+1] = {canal="10", nom="TMC", id="195"}
les_chaines[#les_chaines+1] = {canal="11", nom="NT1", id="446"}
les_chaines[#les_chaines+1] = {canal="111", nom="Vivolta", id="659"}
les_chaines[#les_chaines+1] = {canal="12", nom="NRJ 12", id="444"}
les_chaines[#les_chaines+1] = {canal="120", nom="DogTv", id="-1"}
les_chaines[#les_chaines+1] = {canal="13", nom="LCP", id="234"}
les_chaines[#les_chaines+1] = {canal="135", nom="MyZenTV", id="829"}
les_chaines[#les_chaines+1] = {canal="138", nom="NoLife", id="787"}
les_chaines[#les_chaines+1] = {canal="14", nom="France 4", id="78"}
les_chaines[#les_chaines+1] = {canal="140", nom="GINX", id="563"}
les_chaines[#les_chaines+1] = {canal="145", nom="Mangas", id="6"}
les_chaines[#les_chaines+1] = {canal="15", nom="BFMTV", id="481"}
les_chaines[#les_chaines+1] = {canal="150", nom="Trace Urban", id="325"}
les_chaines[#les_chaines+1] = {canal="151", nom="NRJ Hits TV", id="605"}
les_chaines[#les_chaines+1] = {canal="152", nom="Virgin Radio Tv", id="-1"}
les_chaines[#les_chaines+1] = {canal="153", nom="Indies Live", id="1622"}
les_chaines[#les_chaines+1] = {canal="154", nom="OFive", id="-1"}
les_chaines[#les_chaines+1] = {canal="155", nom="BBlackClasik", id="-1"}
les_chaines[#les_chaines+1] = {canal="156", nom="BBlackCaribbean", id="-1"}
les_chaines[#les_chaines+1] = {canal="16", nom="CNEWS", id="226"}
les_chaines[#les_chaines+1] = {canal="161", nom="RFMTV", id="241"}
les_chaines[#les_chaines+1] = {canal="162", nom="TraceTropical", id="753"}
les_chaines[#les_chaines+1] = {canal="164", nom="Melody", id="265"}
les_chaines[#les_chaines+1] = {canal="166", nom="myMTV", id="-1"}
les_chaines[#les_chaines+1] = {canal="17", nom="CStar", id="458"}
les_chaines[#les_chaines+1] = {canal="170", nom="Classica", id="1353"}
les_chaines[#les_chaines+1] = {canal="173", nom="EquidiaLIFE", id="64"}
les_chaines[#les_chaines+1] = {canal="176", nom="BeingSport1", id="1290"}
les_chaines[#les_chaines+1] = {canal="177", nom="OUATCH", id="-1"}
les_chaines[#les_chaines+1] = {canal="18", nom="Gulli", id="226"}
les_chaines[#les_chaines+1] = {canal="187", nom="MotorSportTV", id="237"}
les_chaines[#les_chaines+1] = {canal="19", nom="France O", id="160"}
les_chaines[#les_chaines+1] = {canal="198", nom="OLTV", id="463"}
les_chaines[#les_chaines+1] = {canal="2", nom="France 2", id="4"}
les_chaines[#les_chaines+1] = {canal="20", nom="HD1", id="1404"}
les_chaines[#les_chaines+1] = {canal="21", nom="L'Equipe21", id="1401"}
les_chaines[#les_chaines+1] = {canal="211", nom="LuckyJack", id="1061"}
les_chaines[#les_chaines+1] = {canal="214", nom="FashionTv", id="1996"}
les_chaines[#les_chaines+1] = {canal="215", nom="LuxeTv", id="531"}
les_chaines[#les_chaines+1] = {canal="217", nom="Ma chaine Etudiante", id="987"}
les_chaines[#les_chaines+1] = {canal="219", nom="Demain!", id="57"}
les_chaines[#les_chaines+1] = {canal="22", nom="6ter", id="1403"}
les_chaines[#les_chaines+1] = {canal="225", nom="LCP100%", id="992"}
les_chaines[#les_chaines+1] = {canal="226", nom="PublicSénat", id="-1"}
les_chaines[#les_chaines+1] = {canal="227", nom="France 24", id="529"}
les_chaines[#les_chaines+1] = {canal="228", nom="BFMBusines", id="1073"}
les_chaines[#les_chaines+1] = {canal="23", nom="Numéro 23", id="1402"}
les_chaines[#les_chaines+1] = {canal="232", nom="France 24 English", id="671"}
les_chaines[#les_chaines+1] = {canal="234", nom="CNN", id="53"}
les_chaines[#les_chaines+1] = {canal="235", nom="CNBC", id="51"}
les_chaines[#les_chaines+1] = {canal="236", nom="Bloomberg", id="410"}
les_chaines[#les_chaines+1] = {canal="24", nom="RMC Découverte", id="1400"}
les_chaines[#les_chaines+1] = {canal="25", nom="Chérie 25", id="1399"}
les_chaines[#les_chaines+1] = {canal="26", nom="LCI", id="112"}
les_chaines[#les_chaines+1] = {canal="27", nom="France Info", id="2111"}
les_chaines[#les_chaines+1] = {canal="3", nom="France 3", id="80"}
les_chaines[#les_chaines+1] = {canal="34", nom="Teva", id="191"}
les_chaines[#les_chaines+1] = {canal="4", nom="Canal+", id="34"}
les_chaines[#les_chaines+1] = {canal="5", nom="France 5", id="47"}
les_chaines[#les_chaines+1] = {canal="585", nom="Télé Sud", id="449"}
les_chaines[#les_chaines+1] = {canal="6", nom="M6", id="118"}
les_chaines[#les_chaines+1] = {canal="7", nom="Arte", id="111"}
les_chaines[#les_chaines+1] = {canal="8", nom="C8", id="445"}
les_chaines[#les_chaines+1] = {canal="86", nom="Disney Channel", id="58"}
les_chaines[#les_chaines+1] = {canal="9", nom="W9", id="119"}
--------------------------------------------
----------- Fin Autres Variables -----------
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
-------------------------------------------- 
	-- chemin vers le dossier lua
	if (package.config:sub(1,1) == '/') then
		 luaDir = debug.getinfo(1).source:match("@?(.*/)")
	else
		 luaDir = string.gsub(debug.getinfo(1).source:match("@?(.*\\)"),'\\','\\\\')
	end
	 curl = '/usr/bin/curl -m 5 -u domoticzUSER:domoticzPSWD '		 	-- ne pas oublier l'espace à la fin
	 json = assert(loadfile(luaDir..'JSON.lua'))()						-- chargement du fichier JSON.lua
--------------------------------------------
-- Obtenir l'idx d'un device via son nom
function GetDeviceIdxByName(deviceName) 
   for i, v in pairs(otherdevices_idx) do
      if i == deviceName then
         return v
      end
   end
   return 0
end -- exemple usage = commandArray['UpdateDevice'] = GetDeviceIdxByName('Compteur Gaz') .. '|0|' .. variable
--------------------------------------------
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
commandArray = {}
time=os.date("*t")
if script_actif == true then
voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)

--=========== Lecture json livebox TV ===============--
  local config = assert(io.popen('/usr/bin/curl "'.. liveboxtv_ip ..'/remoteControl/cmd?operation=10"'))           
  local blocjson = config:read('*all')
  config:close()
  local jsonValeur = json:decode(blocjson)

  local etat = jsonValeur.result.data.activeStandbyState
  voir_les_logs('--- --- --- etat livebox tv '..etat,debugging)

 
--=========== Vérification état Livebox TV ===============--
    if etat == '1'then 
    --commandArray[#commandArray+1]={['UpdateDevice'] = idx..'|0|'..'Arret' }
    voir_les_logs('--- --- --- Livebox tv à l\'arret',debugging)
    end
  
    if etat == '0' then
    chaine = jsonValeur.result.data.playedMediaId
        if  chaine ~= nil  then 
            voir_les_logs('--- --- --- Livebox tv en marche chaine (id) '..chaine,debugging)
            for k,v in pairs(les_chaines) do-- On parcourt chaque chaine
                if tonumber(v.id) == tonumber(chaine) then
                    voir_les_logs('--- --- --- Livebox tv en marche chaine '..v.nom,debugging)
                    if ( otherdevices[chaine] ~= v.nom and device_chaine ~= nil)  then
                    commandArray[#commandArray + 1] = { ['UpdateDevice'] = GetDeviceIdxByName(device_chaine)..'|0|'..v.nom }
                    voir_les_logs('--- --- --- idx du device chaine '..GetDeviceIdxByName(device_chaine),debugging)
                    voir_les_logs('--- --- --- Mise à jour chaine '..v.nom,debugging)    
                    end
                end
            end    
        end
    end
-- ====================================================================================================================	

voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end -- if script_actif
return commandArray