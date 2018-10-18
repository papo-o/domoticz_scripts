--[[
	Prérequis : 
	Domoticz v3.8837 or later (dzVents version 2.4 or later)
	
	Sources : 	https://www.alex-braga.fr/ressources_externe/xdslbox_3.4.10.sh
				https://github.com/rene-d/sysbus
				https://github.com/NextDom/plugin-livebox/

	Livebox 4 stats

                https://easydomoticz.com/forum/viewtopic.php?f=17&t=7247
                https://github.com/papo-o/domoticz_scripts/new/master/dzVents/scripts/livebox.lua
                https://pon.fr/dzvents-toutes-les-infos-de-la-livebox-en-un-seul-script/
	
	-- Authors  ----------------------------------------------------------------
	V1.0 - Neutrino - Domoticz
	V1.1 - Neutrino - Activation/désactivation du WiFi
    	V1.2 - papoo - Liste des n derniers appels manqués, sans réponse, réussis et surveillance périphériques des connectés/déconnectés
	V1.3 - Neutrino - Possibilité de purger le journal d'appels
    	V1.4 - papoo - Possibilité de rebooter la Livebox
	V1.5 - papoo - Correction non mise à jour des devices après RAZ de la liste des appels 
]]--
-- Variables à modifier ------------------------------------------------

local fetchIntervalMins = 1 --  intervalle de mise à jour. 
local adresseLB = '192.168.1.1' --Adresse IP de votre Livebox 4
local password = "123456"
local tmpDir = "/var/tmp" --répertoire temporaire, dans l'idéal en RAM
local myOutput=tmpDir.."/Output.txt"
local myCookies=tmpDir.."/Cookies.txt"

-- Domoticz devices
local SyncATM = nil --"Sync ATM" -- Nom du capteur custom Synchro ATM down, nil si non utilisé
local SyncATMup = nil --"Sync ATM up" -- Nom du capteur custom Synchro ATM up, nil si non utilisé
local Attn = nil --"Attn" -- Nom du capteur custom Attenuation de la ligne, nil si non utilisé
local MargedAttn = nil --"Marge d'Attn" -- Nom du capteur custom Marge d'atténuation, nil si non utilisé
local IPWAN = nil --"IP WAN" -- Nom du capteur Text IP WAN, nil si non utilisé
local IPv6WAN = nil --"IPv6 WAN" -- Nom du capteur Text IPv6 WAN, nil si non utilisé
local DernierAppel = nil --"Dernier Appel" -- Nom du capteur Text Dernier Appel, nil si non utilisé
local UptimeLB = nil -- "Uptime Livebox"  -- Nom du capteur Text Uptime Livebox, nil si non utilisé
local TransmitBlocks = nil --"TransmitBlocks"  -- Nom du capteur Incremental Counter TransmitBlocks, nil si non utilisé
local ReceiveBlocks = nil --"ReceiveBlocks"  -- Nom du capteur Incremental Counter ReceiveBlocks, nil si non utilisé
local internet = nil --"Internet"  -- Nom du capteur Interrupteur Internet, nil si non utilisé
local VoIP = nil --"VoIP"  -- Nom du capteur Interrupteur VoIP, nil si non utilisé
local ServiceTV = nil --"Service TV"  -- Nom du capteur Interrupteur Service TV, nil si non utilisé
local wifi24 = nil --"WiFi 2.4"  -- Nom du capteur Interrupteur wifi 2.4Ghz, nil si non utilisé
local wifi5 = nil --"WiFi 5"  -- Nom du capteur Interrupteur wifi 5Ghz, nil si non utilisé
local missedCall = nil --"Appels manqués" -- Nom du capteur Text appels manqués, nil si non utilisé
local nbMissedCall = 4 -- Nombre d'appels manqués à afficher
local failedCall = nil -- "Appels sans réponse" -- Nom du capteur Text appels sans réponse, nil si non utilisé
local nbFailedCall = 4 -- Nombre d'appels sans réponse à afficher
local succeededCall = nil -- "Appels Réussis" -- Nom du capteur Text appels réussis, nil si non utilisé
local nbSucceededCall = 4 -- Nombre d'appels réussis à afficher
local clearCallList = "Effacer liste appels" -- Nom du capteur Interrupteur PushOn clearCallList
local reboot = 1297 -- Nom du capteur Interrupteur PushOn reboot
local devices_livebox_mac_adress = { -- MAC ADDRESS des périphériques à surveiller
                                        "18:A6:43:4B:C9:D8",
                                        "BC:DE:5F:GH:IJ:2K",
                                        "L0:M6:37:M5:O3:03",
                                        "P0:70:2Q:25:R9:8S",

                                    }
-- SVP, ne rien changer sous cette ligne (sauf pour modifier le logging level)
function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

function disp_time(time)
  local days = math.floor(time/86400)
  local remaining = time % 86400
  local hours = math.floor(remaining/3600)
  remaining = remaining % 3600
  local minutes = math.floor(remaining/60)
  remaining = remaining % 60
  local seconds = remaining
  return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
end

function traduction(str) -- supprime les accents de la chaîne str
    if (str) then
	str = string.gsub (str,"missed", "manqué")
	str = string.gsub (str,"failed", "échoué")
    str = string.gsub (str,"succeeded", "réussi")    
    end
    return (str)
end
function format_date(str) -- supprime les accents de la chaîne str
    if (str) then
	str = string.gsub (str,"T", " - ")
	str = string.gsub (str,"Z", "")
    end
    return (str)
end
function ReverseTable(t)
    local reversedTable = {}
    local itemCount = #t
    for k, v in ipairs(t) do
        reversedTable[itemCount + 1 - k] = v
    end
    return reversedTable
end

local scriptName = 'Livebox'
local scriptVersion = '1.5'

local missedCallList = ""
local failedCallList = ""
local succeededCallList = ""
local patternMacAdresses = string.format("([^%s]+)", ";")

return {
	active = true,
	logging = {
                    -- level     =   domoticz.LOG_DEBUG, -- Uncomment to override the dzVents global logging setting
                    -- level    =   domoticz.LOG_INFO, -- Seulement un niveau peut être actif; commenter les autres
                    -- level    =   domoticz.LOG_ERROR,                                            
                    -- level    =   domoticz.LOG_DEBUG,
                    -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
		marker = scriptName..' '..scriptVersion
	},
	on = {
		timer = {
			'every '..tostring(fetchIntervalMins)..' minutes',
		},
    devices = {wifi5,wifi24,clearCallList,reboot}
	},

	execute = function(domoticz, item)
		--Connexion et récupération du cookies
		os.execute("curl -s -o \""..myOutput.."\" -X POST -c \""..myCookies.."\" -H 'Content-Type: application/x-sah-ws-4-call+json' -H 'Authorization: X-Sah-Login' -d \"{\\\"service\\\":\\\"sah.Device.Information\\\",\\\"method\\\":\\\"createContext\\\",\\\"parameters\\\":{\\\"applicationName\\\":\\\"so_sdkut\\\",\\\"username\\\":\\\"admin\\\",\\\"password\\\":\\\""..password.."\\\"}}\" http://"..adresseLB.."/ws > /dev/null")

		--Lecture du cookies pour utilisation ultérieure
		myContextID = os.capture("tail -n1 \""..myOutput.."\" | sed 's/{\"status\":0,\"data\":{\"contextID\":\"//1'| sed 's/\",//1' | sed 's/\"groups\":\"http,admin//1' | sed 's/\"}}//1'")
		domoticz.log('Context : '..myContextID, domoticz.LOG_DEBUG)
		
		if (item.isTimer)then
			--Envoi des commandes pour récupérer les informations
			MIBs=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"NeMo.Intf.data\\\",\\\"method\\\":\\\"getMIBs\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
			domoticz.log('MIBs : '..MIBs, domoticz.LOG_DEBUG)
			
			DSLstats=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"NeMo.Intf.dsl0\\\",\\\"method\\\":\\\"getDSLStats\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
			domoticz.log('DSLstats : '..DSLstats, domoticz.LOG_DEBUG)
			
			WAN=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"NMC\\\",\\\"method\\\":\\\"getWANStatus\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
			domoticz.log('WAN : '..WAN, domoticz.LOG_DEBUG)
			
			TVstatus=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"NMC.OrangeTV\\\",\\\"method\\\":\\\"getIPTVStatus\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
			domoticz.log('TVstatus : '..TVstatus, domoticz.LOG_DEBUG)		
			
			voip=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"VoiceService.VoiceApplication\\\",\\\"method\\\":\\\"listTrunks\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
			domoticz.log('voip : '..voip, domoticz.LOG_DEBUG)
			
			devicesList=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"Hosts\\\",\\\"method\\\":\\\"getDevices\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
			domoticz.log('devicesList : '..devicesList, domoticz.LOG_DEBUG)
			
			wifi=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"NeMo.Intf.lan\\\",\\\"method\\\":\\\"getMIBs\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
			domoticz.log('wifi : '..wifi, domoticz.LOG_DEBUG)
			
			callList=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"VoiceService.VoiceApplication\\\",\\\"method\\\":\\\"getCallList\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
			domoticz.log('callList : '..callList, domoticz.LOG_DEBUG)
			
			--Données de connexion
			local lbAPIData = domoticz.utils.fromJSON(MIBs)
			if lbAPIData.status == nil or lbAPIData == nil then
				domoticz.log('Lecture de la MIBs impossible', domoticz.LOG_ERROR)
			else
				if SyncATM then domoticz.log('ATM Down: '..lbAPIData.status.dsl.dsl0.DownstreamCurrRate, domoticz.LOG_INFO)
				domoticz.devices(SyncATM).updateCustomSensor(lbAPIData.status.dsl.dsl0.DownstreamCurrRate) end
				
				if SyncATMup then domoticz.log('ATM Up: '..lbAPIData.status.dsl.dsl0.UpstreamCurrRate, domoticz.LOG_INFO)
				domoticz.devices(SyncATMup).updateCustomSensor(lbAPIData.status.dsl.dsl0.UpstreamCurrRate) end
				
				if Attn then domoticz.log('Attn : '..tostring(lbAPIData.status.dsl.dsl0.DownstreamLineAttenuation/10)..' dB', domoticz.LOG_INFO)
				domoticz.devices(Attn).updateCustomSensor(tostring(lbAPIData.status.dsl.dsl0.DownstreamLineAttenuation/10)) end
				
				if MargedAttn then domoticz.log('Marge d\'Attn : '..tostring(lbAPIData.status.dsl.dsl0.DownstreamNoiseMargin/10)..' dB', domoticz.LOG_INFO)
				domoticz.devices(MargedAttn).updateCustomSensor(tostring(lbAPIData.status.dsl.dsl0.DownstreamNoiseMargin/10)) end
				
				if UptimeLB then Uptime = disp_time(lbAPIData.status.dhcp.dhcp_data.Uptime)
				domoticz.log('Uptime : '..Uptime, domoticz.LOG_INFO)
				domoticz.devices(UptimeLB).updateText(Uptime) end
					
				domoticz.log('IP WAN : '..lbAPIData.status.dhcp.dhcp_data.IPAddress, domoticz.LOG_INFO)
                if IPWAN and domoticz.devices(IPWAN).text ~= lbAPIData.status.dhcp.dhcp_data.IPAddress then
                    domoticz.devices(IPWAN).updateText(lbAPIData.status.dhcp.dhcp_data.IPAddress)
                end    
			end
			
			-- Volume de données échangées
			local lbAPIDataDSL = domoticz.utils.fromJSON(DSLstats)
			if lbAPIDataDSL.status == nil then
				domoticz.log('Lecture de la MIBs impossible', domoticz.LOG_ERROR)
			else
				if TransmitBlocks then domoticz.devices(TransmitBlocks).update(0,lbAPIDataDSL.status.TransmitBlocks) end
				if ReceiveBlocks then domoticz.devices(ReceiveBlocks).update(0,lbAPIDataDSL.status.ReceiveBlocks) end
			end
			
			-- Etat du lien WAN et IPv6
			local lbAPIDataInternet = domoticz.utils.fromJSON(WAN)
			if lbAPIDataInternet.status == nil then
				domoticz.log('Lecture de la MIBs impossible', domoticz.LOG_ERROR)
			else
				domoticz.log('Internet : '..lbAPIDataInternet.data.LinkState, domoticz.LOG_INFO)
                if internet then
                    if (lbAPIDataInternet.data.LinkState == 'up' and domoticz.devices(internet).active == false)then
                        domoticz.devices(internet).switchOn()
                    elseif (lbAPIDataInternet.data.LinkState ~= 'up' and domoticz.devices(internet).active)then
                        domoticz.devices(internet).switchOff()
                    end
                end    
				domoticz.log('IPv6 : '..lbAPIDataInternet.data.IPv6Address, domoticz.LOG_INFO)
                if IPv6WAN and domoticz.devices(IPv6WAN).text ~= lbAPIDataInternet.data.IPv6Address then
                    domoticz.devices(IPv6WAN).updateText(lbAPIDataInternet.data.IPv6Address)
                end    
			end	
			
			-- État service VoIP
			local lbAPIDataVoIP = domoticz.utils.fromJSON(voip)
			if lbAPIDataVoIP.status == nil then
				domoticz.log('Lecture de la MIBs impossible', domoticz.LOG_ERROR)
			else
				domoticz.log('VoIP : '..lbAPIDataVoIP.status[1].trunk_lines[1].status, domoticz.LOG_INFO)
                if VoIP then
                    if (lbAPIDataVoIP.status[1].trunk_lines[1].status == 'Up' and domoticz.devices(VoIP).active == false)then
                        domoticz.devices(VoIP).switchOn()
                    elseif (lbAPIDataVoIP.status[1].trunk_lines[1].status ~= 'Up' and domoticz.devices(VoIP).active)then
                        domoticz.devices(VoIP).switchOff()
                    end
                end    
			end
			
			--État service TV 
			local lbAPIDataTV = domoticz.utils.fromJSON(TVstatus)
			if lbAPIDataTV.data == nil then
				domoticz.log('Lecture de la MIBs impossible', domoticz.LOG_ERROR)
			else
				domoticz.log('TV : '..lbAPIDataTV.data.IPTVStatus, domoticz.LOG_INFO)
                if ServiceTV then
                    if (lbAPIDataTV.data.IPTVStatus == 'Available' and domoticz.devices(ServiceTV).active == false)then
                        domoticz.devices(ServiceTV).switchOn()
                    elseif (lbAPIDataTV.data.IPTVStatus ~= 'Available' and domoticz.devices(ServiceTV).active)then
                        domoticz.devices(ServiceTV).switchOff()
                    end
                end    
			end
			
			--État WiFi
			local lbAPIDataWifi = domoticz.utils.fromJSON(wifi)
			if lbAPIDataWifi.status == nil then
				domoticz.log('Lecture de la MIBs impossible', domoticz.LOG_ERROR)
			else
				domoticz.log('Wifi 2.4 Ghz : '..lbAPIDataWifi.status.wlanvap.wl0.VAPStatus, domoticz.LOG_INFO)
                if wifi24 then 
                    if (lbAPIDataWifi.status.wlanvap.wl0.VAPStatus == 'Up' and domoticz.devices(wifi24).active == false)then
                        domoticz.devices(wifi24).switchOn()
                    elseif (lbAPIDataWifi.status.wlanvap.wl0.VAPStatus ~= 'Up' and domoticz.devices(wifi24).active)then
                        domoticz.devices(wifi24).switchOff()
                    end
                end    
                
				domoticz.log('Wifi 5 Ghz : '..lbAPIDataWifi.status.wlanvap.eth6.VAPStatus, domoticz.LOG_INFO)
                if wifi5 then
                    if (lbAPIDataWifi.status.wlanvap.eth6.VAPStatus == 'Up' and domoticz.devices(wifi5).active == false)then
                        --domoticz.devices(wifi5).switchOn()
                        domoticz.devices(wifi5).update(1,0)
                    elseif (lbAPIDataWifi.status.wlanvap.eth6.VAPStatus ~= 'Up' and domoticz.devices(wifi5).active)then
                        domoticz.devices(wifi5).update(0,0)
                    end
                end    
			end		
			
			--Dernier Appel reçu ou émis
			local lbAPIDataCallList = domoticz.utils.fromJSON(callList)
			if lbAPIDataCallList.status == nil then
				domoticz.log('Lecture de la MIBs impossible', domoticz.LOG_ERROR)
			else
				domoticz.log('CallList : '..#lbAPIDataCallList.status, domoticz.LOG_INFO)
				if (#lbAPIDataCallList.status>0) then
					domoticz.log('Dernier Appel : '..lbAPIDataCallList.status[#lbAPIDataCallList.status].remoteNumber, domoticz.LOG_INFO)
					domoticz.log('Dernier Appel : '..traduction(lbAPIDataCallList.status[#lbAPIDataCallList.status].callType), domoticz.LOG_INFO)
					NumeroEtat = lbAPIDataCallList.status[#lbAPIDataCallList.status].remoteNumber .. " - "..lbAPIDataCallList.status[#lbAPIDataCallList.status].callType
                    if DernierAppel and domoticz.devices(DernierAppel).text ~= traduction(NumeroEtat) then
                            domoticz.devices(DernierAppel).updateText(traduction(NumeroEtat))
                    end                    
                    -- x Appels manqués, sans réponse, réussis
                    for i, call in ipairs(ReverseTable(lbAPIDataCallList.status)) do
                        if call.callType == "missed" and nbMissedCall > 0 then
                            --domoticz.log(call.remoteNumber .. " " .. traduction(call.callType) .. " " .. format_date(call.startTime), domoticz.LOG_INFO)
                            missedCallList = missedCallList .. call.remoteNumber .. " - " .. format_date(call.startTime) .. "\n"
                            nbMissedCall = nbMissedCall - 1
                        end
                        if call.callType == "failed" and nbFailedCall > 0 then
                            --domoticz.log(call.remoteNumber .. " " .. traduction(call.callType) .." ".. format_date(call.startTime), domoticz.LOG_INFO)
                            failedCallList = failedCallList .. call.remoteNumber .." - ".. format_date(call.startTime) .. "\n"
                            nbFailedCall = nbFailedCall - 1
                        end
                        if call.callType == "succeeded" and nbSucceededCall > 0 then
                            --domoticz.log(call.remoteNumber .. " " .. traduction(call.callType) .. " " .. format_date(call.startTime), domoticz.LOG_INFO)
                            succeededCallList = succeededCallList .. call.remoteNumber .. " - " .. format_date(call.startTime) .. "\n"
                            nbSucceededCall = nbSucceededCall - 1
                        end
                    end                    
                    if missedCallList == "" then missedCallList = "Aucun appel à afficher" end                        
                    domoticz.log('Appels manqués : \n'..missedCallList, domoticz.LOG_INFO)
                    if missedCall and domoticz.devices(missedCall).text ~= traduction(missedCallList) then 
                        domoticz.devices(missedCall).updateText(traduction(missedCallList))
                    end 
                    if failedCallList == "" then failedCallList = "Aucun appel à afficher" end                        
                    domoticz.log('Appels sans réponse : \n'..failedCallList, domoticz.LOG_INFO)
                    if failedCall and domoticz.devices(failedCall).text ~= traduction(failedCallList) then 
                        domoticz.devices(failedCall).updateText(traduction(failedCallList))
                    end 
                    if succeededCallList == "" then succeededCallList = "Aucun appel à afficher" end
                    domoticz.log('Appels réussis : \n'..succeededCallList, domoticz.LOG_INFO)
                    if succeededCall and domoticz.devices(succeededCall).text ~= traduction(succeededCallList) then 
                        domoticz.devices(succeededCall).updateText(traduction(succeededCallList))
                    end                     
				else
					NumeroEtat = "Aucun appel à afficher"
                    domoticz.log('Dernier Appel : '..NumeroEtat, domoticz.LOG_INFO)
                    if DernierAppel and domoticz.devices(DernierAppel).text ~= NumeroEtat then
                        domoticz.devices(DernierAppel).updateText(NumeroEtat)
                    end 
                    if missedCallList == "" then missedCallList = "Aucun appel à afficher" end                        
                    domoticz.log('Appels manqués : \n'..missedCallList, domoticz.LOG_INFO)
                    if missedCall and domoticz.devices(missedCall).text ~= traduction(missedCallList) then 
                        domoticz.devices(missedCall).updateText(traduction(missedCallList))
                    end 
                    if failedCallList == "" then failedCallList = "Aucun appel à afficher" end                        
                    domoticz.log('Appels sans réponse : \n'..failedCallList, domoticz.LOG_INFO)
                    if failedCall and domoticz.devices(failedCall).text ~= traduction(failedCallList) then 
                        domoticz.devices(failedCall).updateText(traduction(failedCallList))
                    end 
                    if succeededCallList == "" then succeededCallList = "Aucun appel à afficher" end
                    domoticz.log('Appels réussis : \n'..succeededCallList, domoticz.LOG_INFO)
                    if succeededCall and domoticz.devices(succeededCall).text ~= traduction(succeededCallList) then 
                        domoticz.devices(succeededCall).updateText(traduction(succeededCallList))
                    end                    
				end
            end
		
        local json_peripheriques = domoticz.utils.fromJSON(devicesList)
        etatPeripheriques = false
        -- Liste des périphériques
        
            for index, peripherique in pairs(json_peripheriques.status) do   
                domoticz.log("Péripherique " .. index .. " ".. peripherique.hostName .." " .. peripherique.ipAddress .. " [".. peripherique.physAddress .."] actif : ".. tostring(peripherique.active), domoticz.LOG_DEBUG)
                for i, mac in pairs(devices_livebox_mac_adress) do
                    mac = string.lower(mac)
                    if peripherique.physAddress == mac then
                    domoticz.log("Statut du périphérique ".. peripherique.hostName .." [" .. mac .. "]  =>  actif:" .. tostring(peripherique.active), domoticz.LOG_INFO)
                        if peripherique.active == true then
                        etatPeripheriques = true   
                            if domoticz.devices(peripherique.hostName) then domoticz.devices(peripherique.hostName).switchOn().checkFirst()end
                            domoticz.log("Activation de : " .. peripherique.hostName, domoticz.LOG_INFO)
                        else
                            if domoticz.devices(peripherique.hostName) then domoticz.devices(peripherique.hostName).switchOff().checkFirst()end
                            domoticz.log("DésActivation de : " .. peripherique.hostName, domoticz.LOG_INFO)
                        end		
                    end
                end
            end   
        else
			if(item.name == wifi5)then
				os.execute("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..
					myContextID.."\" -d \"{\\\"service\\\":\\\"NeMo.Intf.lan\\\",\\\"method\\\":\\\"setWLANConfig\\\",\\\"parameters\\\":{\\\"mibs\\\":{\\\"penable\\\":{\\\"wifi0_quan\\\":{\\\"PersistentEnable\\\":"..
					tostring(item.active)..", \\\"Enable\\\":true}}}}}\" http://"..adresseLB.."/ws &")
				domoticz.log("wifi5 "..tostring(item.active),domoticz.LOG_INFO)
			elseif(item.name == wifi24)then
				os.execute("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..
					myContextID.."\" -d \"{\\\"service\\\":\\\"NeMo.Intf.lan\\\",\\\"method\\\":\\\"setWLANConfig\\\",\\\"parameters\\\":{\\\"mibs\\\":{\\\"penable\\\":{\\\"wifi0_bcm\\\":{\\\"PersistentEnable\\\":"..
					tostring(item.active)..", \\\"Enable\\\":true}}}}}\" http://"..adresseLB.."/ws &")
				domoticz.log("wifi24 "..tostring(item.active),domoticz.LOG_INFO)
			elseif(item.name == clearCallList)then
				os.execute("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..
					myContextID.."\" -d \"{\\\"service\\\":\\\"VoiceService.VoiceApplication\\\",\\\"method\\\":\\\"clearCallList\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws &")
				domoticz.log("clearCallList "..tostring(item.active),domoticz.LOG_INFO)			

			elseif(item.name == reboot)then
            os.execute("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..
                    myContextID.."\" -d \"{\\\"parameters\\\":{}}\" http://"..adresseLB.."/sysbus/NMC:reboot &")
				domoticz.log("reboot "..tostring(item.active),domoticz.LOG_INFO)			
            end		
        end
		--Déconnexion et suppression des fichiers temporaires
		os.execute("curl -s -b "..myCookies.." -X POST http://"..adresseLB.."/logout &")
		os.execute('rm "'..myCookies..'" "'..myOutput..'" &')
	end
}
