--[[
name : script_time_pellets.lua
auteur : papoo
date de création : 15/02/2018
Date de mise à jour : 18/03/2018
Principe : ce script utilise l'api du site https://www.ecopellets.fr/ 
https://pon.fr/lua-recuperation-des-informations-du-site-ecopellets/
https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_pellets.lua
http://easydomoticz.com/forum/viewtopic.php?f=10&t=6122&p=51452#p51452
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

local debugging = true                                                      -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif = true                                                  -- active (true) ou désactive (false) ce script simplement
local delai = 30                                                             -- délai d'exécution de ce script en minutes de 1 à 59 (délai entre deux appels à l'API)
local url_info_pellets = "https://www.ecopellets.fr/appjson.php?uniqid="    -- Adresse de l'API ecopellets
local uniqid = "c49f8579b9aec326eac372e8a7xxxxx"                           -- votre uniqid
local domoticzURL = "127.0.0.1:8080"
local les_devices = {};
-- comment remplir le tableau les_devices ?  
-- device = le nom du dispositif à créer/incrémenter
-- sensortype = le ype de device à créer/incrémenter  
-- commentez les devices que vous ne souhaitez pas utiliser
-- les_devices[#les_devices+1] = {device="", nom ="", sensortype =""}
les_devices[#les_devices+1] = {device = "qtemois" , nom = "Consommation mois en cours", sensortype = 113} -- 1er device
les_devices[#les_devices+1] = {device = "prixmois" , nom = "Coût mensuel", sensortype = 113} -- 2éme device
les_devices[#les_devices+1] = {device = "tendance" , nom = "Tendance", sensortype = 113} -- 3éme device
les_devices[#les_devices+1] = {device = "stock0" , nom = "Stock zéro", sensortype = 113} -- 4éme device
les_devices[#les_devices+1] = {device = "datestock0" , nom = "Date stock zéro", sensortype = 5} -- 5éme device
les_devices[#les_devices+1] = {device = "qtelastmonth" , nom = "Quantité mois passé", sensortype = 113} -- 6éme device
les_devices[#les_devices+1] = {device = "prixlastmonth" , nom = "Coût mois passé", sensortype = 113} -- 7éme device
les_devices[#les_devices+1] = {device = "qtesept" , nom = "Quantité depuis septembre", sensortype = 113} -- 8éme device
les_devices[#les_devices+1] = {device = "coutsept" , nom = "Coût depuis septembre", sensortype = 113} -- 9éme device
les_devices[#les_devices+1] = {device = "qtestock" , nom = "État du stock", sensortype = 113} -- 10éme device
les_devices[#les_devices+1] = {device = "prixstock" , nom = "Coût du stock", sensortype = 113} -- 11éme device
les_devices[#les_devices+1] = {device = "coutotal" , nom = "Coût total", sensortype = 113} -- 12éme device
les_devices[#les_devices+1] = {device = "coutreparation" , nom = "Coût réparation", sensortype = 113} -- 13éme device
les_devices[#les_devices+1] = {device = "coutentretien" , nom = "Coût entretien", sensortype = 113} -- 14éme device

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
--------------------------------------------
------------- Autres Variables -------------
--------------------------------------------
local nom_script = 'Infos ecopellets.fr'
local version = '1.1'
curl = '/usr/bin/curl -m 5 '		 	    -- pour linux, ne pas oublier l'espace à la fin
-- curl = 'c:\\Programs\\Curl\\curl -m 5 '  -- pour windows, ne pas oublier l'espace à la fin
-- chemin vers le dossier lua
	if (package.config:sub(1,1) == '/') then
		 luaDir = debug.getinfo(1).source:match("@?(.*/)")
	else
		 luaDir = string.gsub(debug.getinfo(1).source:match("@?(.*\\)"),'\\','\\\\')
	end
	json = assert(loadfile(luaDir..'JSON.lua'))()						-- chargement du fichier JSON.lua
--json = assert(loadfile('/home/pi/domoticz/scripts/lua/JSON.lua'))() --Linux    
--------------------------------------------
----------- Fin Autres Variables -----------
--------------------------------------------	
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
function voir_les_logs(s, debugging)
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>")
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>")
		end
    end
end	

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
--------------------------------------------
function CreateVirtualSensor(dname, sensortype)
    -- recherche d'un hardware dummy pour l'associer au futur device
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

    if id ~= nil then -- si un hardware dummy existe on peut créer le device
        voir_les_logs("--- --- --- création du device   : ".. dname .. " --- --- ---",debugging)
        voir_les_logs(curl..'"'.. domoticzURL ..'/json.htm?type=createvirtualsensor&idx='..id..'&sensorname='..url_encode(dname)..'&sensortype='..sensortype..'"',debugging)
        os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=createvirtualsensor&idx='..id..'&sensorname='..url_encode(dname)..'&sensortype='..sensortype..'"')

        voir_les_logs("--- --- --- device   : ".. dname .. " créé --- --- ---",debugging)         
    end
    -- else     
        -- local attribut = DeviceInfos(dname)
        -- if attribut then
            -- if attribut.SwitchTypeVal == 0 then
                -- voir_les_logs("--- --- --- modification du device RFXMeter  : ".. dname .. " en compteur de type 3  --- --- ---",debugging) 
                -- os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=setused&idx='..otherdevices_idx[dname]..'&name='..url_encode(dname)..'&switchtype=3&used=true"')
            -- end
        -- else
            -- voir_les_logs("--- --- --- impossible d\'extraire les caractéristiques du compteur ".. dname .."  --- --- ---",debugging)
        -- end
--https://github.com/domoticz/domoticz/blob/development/hardware/hardwaretypes.h

end 
--------------------------------------------
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
local idx =  otherdevices_idx[device]   
    if idx then
        local config = assert(io.popen(curl..'"'.. domoticzURL ..'/json.htm?type=devices&rid='..otherdevices_idx[device]..'"'))
        local blocjson = config:read('*all')
        config:close()
        local jsonValeur = json:decode(blocjson)
        if jsonValeur ~= nil then
            return json:decode(blocjson).result[1]    
        end
    end    
end --[[usage : 
        local attribut = DeviceInfos(device)
        if attribut.SwitchTypeVal == 0 then    end
    --]]
    
--------------------------------------------
function ConvertCounter(devicename)
local attribut = DeviceInfos(devicename)
    if attribut then
        if attribut.SwitchTypeVal == 0 then
            voir_les_logs("--- --- --- modification du device RFXMeter  : ".. devicename .. " en compteur de type 3  --- --- ---",debugging) 
            os.execute(curl..'"'.. domoticzURL ..'/json.htm?type=setused&idx='..otherdevices_idx[devicename]..'&name='..url_encode(devicename)..'&switchtype=3&used=true"')
        end
    else
        voir_les_logs("--- --- --- impossible d\'extraire les caractéristiques du compteur ".. devicename .."  --- --- ---",debugging)
    end
end   
--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
commandArray = {}
time = os.date("*t")

if script_actif == true then
    if ((time.min-1) % delai) == 0 then -- toutes les xx minutes en commençant par xx:01    
        voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
        --=========== Lecture json ===============--
        local config = assert(io.popen(curl..' "'.. url_info_pellets .. uniqid ..'"')) 
        --end
        local blocjson = config:read('*all')
        config:close()
        local jsonValeur = json:decode(blocjson)
        if jsonValeur then
            qtemois = jsonValeur.qtemois
            prixmois = jsonValeur.prixmois
            tendance = jsonValeur.tendance
            stock0 = jsonValeur.stock0
            datestock0 = jsonValeur.datestock0
            qtelastmonth = jsonValeur.qtelastmonth
            prixlastmonth = jsonValeur.prixlastmonth
            qtesept = jsonValeur.qtesept
            coutsept = jsonValeur.coutsept
            qtestock = jsonValeur.qtestock
            prixstock = jsonValeur.prixstock
            coutotal = jsonValeur.coutotal
            coutreparation = jsonValeur.coutreparation            
            coutentretien = jsonValeur.coutentretien             
            if qtemois ~= nil then voir_les_logs('--- --- --- qtemois : '..qtemois,debugging) end
            if prixmois ~= nil then  voir_les_logs('--- --- --- prixmois : '..prixmois,debugging) end
            if tendance ~= nil then voir_les_logs('--- --- --- tendance : '..tendance,debugging) end
            if stock0 ~= nil then voir_les_logs('--- --- --- stock0 : '..stock0,debugging) end
            if datestock0 ~= nil then voir_les_logs('--- --- --- datestock0 : '..datestock0,debugging) end
            if qtelastmonth ~= nil then voir_les_logs('--- --- --- qtelastmonth : '..qtelastmonth,debugging) end
            if prixlastmonth ~= nil then voir_les_logs('--- --- --- prixlastmonth : '..prixlastmonth,debugging) end
            if qtesept ~= nil then voir_les_logs('--- --- --- qtesept : '..qtesept,debugging) end
            if coutsept ~= nil then voir_les_logs('--- --- --- coutsept : '..coutsept,debugging)
            else coutsept = 0
                voir_les_logs('--- --- --- coutsept : '..coutsept,debugging)
            end
            if qtestock ~= nil then voir_les_logs('--- --- --- qtestock : '..qtestock,debugging) end
            if prixstock ~= nil then voir_les_logs('--- --- --- prixstock : '..prixstock,debugging) end
            if coutotal ~= nil then voir_les_logs('--- --- --- coutotal : '..coutotal,debugging) end          
            if coutreparation ~= nil then voir_les_logs('--- --- --- coutreparation : '..coutreparation,debugging) 
            else
                coutreparation = 0
                voir_les_logs('--- --- --- coutreparation : '..coutreparation,debugging) 
            end             
            if coutentretien  ~= nil then  
                voir_les_logs('--- --- --- coutentretien : '..coutentretien,debugging) 
            else 
                coutentretien = 0 
                voir_les_logs('--- --- --- coutentretien : '..coutentretien,debugging) 
            end 
            for k,v in pairs(les_devices) do
                local Vdevice = v.device
                local Vnom = v.nom
                local Vtype = v.sensortype
                voir_les_logs('--- --- --- device : '..Vdevice..' nom  : '..Vnom.. ' sensortype : '..Vtype,debugging)
                if otherdevices[Vnom] == nil then
                    CreateVirtualSensor(Vnom, Vtype) 
                    voir_les_logs('--- --- --- création device : '..Vdevice.. ' sensortype : '..Vtype,debugging)
                end
                if Vtype == 113 then 
                    ConvertCounter(Vnom)
                end 
                
                
                if otherdevices[Vnom] ~= nil then

                local variable = tostring(_G[Vdevice])
                    --print(variable)
                    voir_les_logs("--- --- --- mise à jour  ".. Vnom.." : "..variable,debugging)
                    commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[Vnom] .. '|0|'..tostring(variable)} --mise à jour du device
                    voir_les_logs("--- --- --- ".. Vdevice.." a été mis à jour",debugging)
                end
            end        
        else
            voir_les_logs('--- --- --- aucun résultat à décoder',debugging)
        end --if jsonValeur
    -- ====================================================================================================================	

    voir_les_logs("======== Fin ".. nom_script .." (v".. version ..") ==========",debugging)        
    end --if time       
end -- if script_actif
return commandArray
