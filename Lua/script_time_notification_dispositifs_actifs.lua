--[[
script_time_notification_dispositifs_actifs.lua
Principe : être notifié lorsqu'un device reste à "On" ou "open" plus de X minutes
possibilités de gestion des temps avant notification par groupes ou personnalisés par device
Possibilités de personnaliser le type de notification pour chaque device
Date Création : 22/12/2017 
Date MAJ : 26/12/2017
http://easydomoticz.com/forum/viewtopic.php?f=17&t=5540
http://pon.fr/notification-dispositifs-actifs-en-lua
]]--

--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------
local debugging = true  			-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local nom_script = 'Notification dispositifs actifs'
local version = '1.12'
local defaut_delai = "10"           -- délai en minutes par défaut avant notification pour tout les devices non personnalisés
local delai_portes = "5"            -- délai en minutes par défaut avant notification pour les devices du groupe portes
local delai_fenetres = "60"         -- délai en minutes par défaut avant notification pour les devices du groupe fenêtres
local delai_lumieres = "120"        -- délai en minutes par défaut avant notification pour les devices du groupe lumieres
local delai_TV = "150"              -- délai en minutes par défaut avant notification pour les devices du groupe TV
local delai_ordinateurs = "180"            -- délai en minutes par défaut avant notification pour les devices du groupe ordinateurs
local les_devices = {};
-- comment remplir le tableau les_devices ?  
-- device = le nom du dispositif à surveiller
-- type_device = le nom du groupe auquel appartient le device à surveiller : porte, fenetres, lumiere, TV.  
-- delai = délai particulier à n'utiliser que sur le device concerné, inhibe le délai affecté au groupe. si aucun délai particulier, nil.
-- si type_device = nil et delai = nil le délai defaut_delai sera appliqué.
-- Pour activer un ou plusieurs mode de notifications particuliers renseigner subsystem
-- les différentes valeurs de subsystem acceptées sont : gcm;http;kodi;lms;nma;prowl;pushalot;pushbullet;pushover;pushsafer
-- pour plusieurs modes de notification séparez chaque mode par un point virgule. si subsystem = nil toutes les notifications seront activées.
-- etat = état du dispositif à surveiller "On" Ou "Off"
-- les_devices[#les_devices+1] = {device="", type_device ="", delai = nil, subsystem = nil, etat = ""}
les_devices[#les_devices+1] = {device="porte entree", type_device ="portes", delai = nil, subsystem = nil, etat = "On"} -- 1er device délai en minutes
les_devices[#les_devices+1] = {device="porte cave",  type_device = "portes", delai = nil, subsystem = nil, etat = "On"} -- 2eme device
les_devices[#les_devices+1] = {device="fenetre douche",  type_device = "fenetres", delai = nil, subsystem = nil, etat = "On"} -- 3eme device
les_devices[#les_devices+1] = {device="lumiere_rdc_2",  type_device = "lumieres", delai = nil, subsystem = "pushbullet", etat = "On"} -- 4eme device
les_devices[#les_devices+1] = {device="TV Sony",  type_device = "TV", delai = nil, subsystem = nil, etat = "On"} -- 5eme device
les_devices[#les_devices+1] = {device="TV Salon",  type_device = "TV", delai = "150", subsystem = nil, etat = "On"} -- 6eme device
les_devices[#les_devices+1] = {device="I7-3500",  type_device = "ordinateurs", delai = "360", subsystem = nil, etat = "On"} -- 7eme device
les_devices[#les_devices+1] = {device="Synology",  type_device = "ordinateurs", delai = "2", subsystem = nil, etat = "Off"} -- 8eme device
les_devices[#les_devices+1] = {device="Routeur MiWiFi",  type_device = "ordinateurs", delai = "2", subsystem = nil, etat = "Off"} -- 9eme device
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
t1 = os.time()
local open
--------------------------------------------
-------------Fonctions----------------------
-------------------------------------------- 
function voir_les_logs (s, debugging) -- nécessite la variable local debugging
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>")
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>")
		end
    end
end	-- usage : voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
--============================================================================================== 
function ConvTime(timestamp) -- convertir un timestamp 
   y, m, d, H, M, S = timestamp:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
   return os.time{year=y, month=m, day=d, hour=H, min=M, sec=S}
end
--============================================================================================== 
function round(value, digits) -- arrondi
  local precision = 10^digits
  return (value >= 0) and
      (math.floor(value * precision + 0.5) / precision) or
      (math.ceil(value * precision - 0.5) / precision)
end
--============================================================================================== 
function return_delai(type_device, delai)
    if  type_device == "portes" and delai == nil then 
        return delai_portes
    elseif  type_device == "fenetres" and delai == nil then
        return delai_fenetres
    elseif  type_device == "lumieres" and delai == nil then 
        return delai_lumieres
    elseif  type_device == "TV" and delai == nil then 
        return delai_TV
    elseif  type_device == "ordinateurs" and delai == nil then 
        return delai_ordinateurs        
    elseif delai ~= nil then 
        return delai        
    else
        return defaut_delai
    end
end

--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
commandArray = {}
voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
	for k,v in pairs(les_devices) do  -- On parcourt chaque device
        local Vtype = v.type_device
        local Vdelai = v.delai
        local Delai = tonumber(return_delai(Vtype, Vdelai))
        if otherdevices_lastupdate[v.device] ~= nil then
            t2 = ConvTime(otherdevices_lastupdate[v.device])
            difference = (os.difftime (t1, t2))
    --============================= Etat à On ou "" =======================================         
            if (otherdevices[v.device] == 'Open' or otherdevices[v.device] == 'On' and (v.etat == "" or v.etat == 'On')) then -- on n'affiche que les devices à ON ou open
                if Vtype  ~= nil and Vtype ~= "" then 
                    voir_les_logs('=========== Etat du device '.. v.device ..' : '.. otherdevices[v.device] ..' delai : '.. Delai ..' type : '.. Vtype  ..' ===========',debugging)
                else  
                    voir_les_logs('=========== Etat du device '.. v.device ..' : '.. otherdevices[v.device] ..' ===========',debugging) 
                end
            voir_les_logs("=========== maintenant : ".. round(tonumber(t1)/60,0) .." - dernier changement d\'etat : ".. round(tonumber(t2)/60,0) .." - Difference : " .. round(tonumber(difference)/60,0) .."mn ===========",debugging)
            end 
            if (otherdevices[v.device] == 'Open' or otherdevices[v.device] == 'On' and difference > ((tonumber(Delai)*60)-20) and difference < (tonumber(Delai)*60)+40 and (v.etat == "" or v.etat == 'On' or v.etat == 'on')) then -- si le delai est dépassée de moins d'une minute (pour une seule notification)
            voir_les_logs('=========== delai dépassé pour le device '.. v.device ..' : '.. otherdevices[v.device],debugging)
                if v.type_device == "lumieres" or v.type_device == "TV" then open = "allumée" elseif v.type_device == "ordinateurs" then open = "allumé" else  open = "ouverte" end
                if v.subsystem ~= nil then
                    commandArray['SendNotification'] = 'Attention#'.. v.device ..' est restée '..open ..' depuis ' .. Delai ..' mn!#0###'.. v.subsystem ..''
                else
                    commandArray['SendNotification'] = 'Attention#'.. v.device ..' est restée '..open ..' depuis ' .. Delai ..' mn!'
                end
            end
    --============================= Etat à Off ===========================================
            if (otherdevices[v.device] == 'Close' or otherdevices[v.device] == 'Off' and v.etat == 'Off') then -- on n'affiche que les devices à Off
                if Vtype  ~= nil and Vtype ~= "" then 
                    voir_les_logs('=========== Etat du device '.. v.device ..' : '.. otherdevices[v.device] ..' delai : '.. Delai ..' type : '.. Vtype  ..' ===========',debugging)
                else  
                    voir_les_logs('=========== Etat du device '.. v.device ..' : '.. otherdevices[v.device] ..' ===========',debugging) 
                end
            voir_les_logs("=========== maintenant : ".. round(tonumber(t1)/60,0) .." - dernier changement d\'etat : ".. round(tonumber(t2)/60,0) .." - Difference : " .. round(tonumber(difference)/60,0) .."mn ===========",debugging)
            end 
            if (otherdevices[v.device] == 'Close' or otherdevices[v.device] == 'Off' and difference > ((tonumber(Delai)*60)-20) and difference < (tonumber(Delai)*60)+40 and (v.etat == 'Off' or v.etat == 'off')) then -- si le delai est dépassée de moins d'une minute (pour une seule notification)
            voir_les_logs('=========== delai dépassé pour le device '.. v.device ..' : '.. otherdevices[v.device],debugging)
                if v.type_device == "lumieres" or v.type_device == "TV" then open = "éteinte" elseif v.type_device == "ordinateurs" then open = "éteint" else  open = "fermée" end
                if v.subsystem ~= nil then
                    commandArray['SendNotification'] = 'Attention#'.. v.device ..' est restée '..open ..' depuis ' .. Delai ..' mn!#0###'.. v.subsystem ..''
                else
                    commandArray['SendNotification'] = 'Attention#'.. v.device ..' est restée '..open ..' depuis ' .. Delai ..' mn!'
                end
            end        
        else
        print (v.device.. " n\'existe pas")
        end
    end -- end for
voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
return commandArray