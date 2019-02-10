--[[
	Prérequis : 
	Domoticz v3.8837 or later (dzVents version 2.4 or later)
	
	Sources : 	https://www.alex-braga.fr/ressources_externe/xdslbox_3.4.10.sh
				https://github.com/rene-d/sysbus
				https://github.com/NextDom/plugin-livebox/

	Livebox 3/4 stats
	
				https://easydomoticz.com/forum/viewtopic.php?f=17&t=7247
				https://github.com/papo-o/domoticz_scripts/new/master/dzVents/scripts/livebox.lua
				https://pon.fr/dzvents-toutes-les-infos-de-la-livebox-en-un-seul-script/
	
-- Authors  ----------------------------------------------------------------
	V1.0 - Neutrino - 	Domoticz
	V1.1 - Neutrino - 	Activation/désactivation du WiFi
	V1.2 - papoo - 		Liste des n derniers appels manqués, sans réponse, réussis et surveillance périphériques des connectés/déconnectés
	V1.3 - Neutrino - 	Possibilité de purger le journal d'appels
	V1.4 - papoo - 		Possibilité de rebooter la Livebox
	V1.5 - papoo - 		Correction non mise à jour des devices après RAZ de la liste des appels
	V1.6 - papoo - 		Correction horodatage heures d'appel à GMT+2
	V1.7 - papoo - 		Affichage des noms connus via fichiers de contacts
	V1.8 - Neutrino - 	Support de la Livebox 3 Play, gestion heures d'été/heure d'hiver
	V1.9 - Neutrino - 	Prise en charge du Wifi 5 GHz de la Livebox 3
	V1.10 - Neutrino - 	gestion fichier contacts inexistant, gestion périphériques différentes, version du firmware, correction de bugs,
						Optimisation du nombre de requêtes
	V1.11 - Neutrino	Uptime de la box et non de la connexion dsl
	V1.12 - JCLB		Faire sonner le téléphone
]]--
-- Variables à modifier ------------------------------------------------

local fetchIntervalMins = 1 --  intervalle de mise à jour. 
local adresseLB = '192.168.1.1' --Adresse IP de votre Livebox 4
local password = "password"
local tmpDir = "/var/tmp" --répertoire temporaire, dans l'idéal en RAM
local myOutput=tmpDir.."/Output.txt"
local myCookies=tmpDir.."/Cookies.txt"
local fichier_contacts = "/home/pi/domoticz/scripts/contacts.json"
local liveBox3 = false --true si vous avez une liveBox3/play

-- Domoticz devices
local IPWAN = nil --"IP WAN" -- Nom du capteur Text IP WAN, nil si non utilisé
local IPv6WAN = nil --"IPv6 WAN" -- Nom du capteur Text IPv6 WAN, nil si non utilisé
local DernierAppel = nil --"Dernier Appel" -- Nom du capteur Text Dernier Appel, nil si non utilisé
local UptimeLB = nil -- "Uptime Livebox"  -- Nom du capteur Text Uptime Livebox, nil si non utilisé
local internet = nil --"Internet"  -- Nom du capteur Interrupteur Internet, nil si non utilisé
local VoIP = nil --"VoIP"  -- Nom du capteur Interrupteur VoIP, nil si non utilisé
local ServiceTV = nil --"Service TV"  -- Nom du capteur Interrupteur Service TV, nil si non utilisé
local wifi24 = nil --"WiFi 2.4"  -- Nom du capteur Interrupteur wifi 2.4Ghz, nil si non utilisé
local wifi5 = nil --"WiFi 5"  -- Nom du capteur Interrupteur wifi 5Ghz, nil si non utilisé
local missedCall = 1374--nil --"Appels manqués" --"Appels manqués" -- Nom du capteur Text appels manqués, nil si non utilisé
local nbMissedCall = 4 -- Nombre d'appels manqués à afficher
local failedCall =  "Appels sans réponse" -- Nom du capteur Text appels sans réponse, nil si non utilisé
local nbFailedCall = 4 -- Nombre d'appels sans réponse à afficher
local succeededCall = 1378 --"Appels Réussis" -- Nom du capteur Text appels réussis, nil si non utilisé
local nbSucceededCall = 4 -- Nombre d'appels réussis à afficher
local clearCallList = "Effacer liste appels" -- Nom du capteur Interrupteur PushOn clearCallList
local reboot = nil -- 1297 -- Nom du capteur Interrupteur PushOn reboot
local sonner = "nil" -- Nom du capteur Interrupteur PushOn faire sonner tel
local devices_livebox_mac_adress = { -- MAC ADDRESS des périphériques à surveiller
                                        -- "18:A6:43:4B:C9:D8",
                                        -- "BC:DE:5F:GH:IJ:2K",
                                        -- "L0:M6:37:M5:O3:03",
                                        -- "P0:70:2Q:25:R9:8S",
                                    }

-- Capteurs pour connexion xDSL seulement
local SyncATM = nil -- Nom du capteur custom Synchro ATM down, nil si non utilisé
local SyncATMup = nil -- Nom du capteur custom Synchro ATM up, nil si non utilisé
local Attn = nil -- Nom du capteur custom Attenuation de la ligne, nil si non utilisé
local MargedAttn = nil -- Nom du capteur custom Marge d'atténuation, nil si non utilisé
-- Livebox 4 seulement
local TransmitBlocks = nil  -- Nom du capteur Incremental Counter TransmitBlocks, nil si non utilisé
local ReceiveBlocks = nil  -- Nom du capteur Incremental Counter ReceiveBlocks, nil si non utilisé

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

local function get_timezone()
  local now = os.time()
  return os.difftime(now, os.time(os.date("!*t", now)))
end


function format_date(str) -- supprime les caractères T et Z de la chaîne str  et corrige l'heure suivant le fuseau horaire
	if (str) then
		_, _, A, M, j, h, m, s = string.find(str, "^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z$")
		h = h + get_timezone()/3600
		str= A.."-"..M.."-"..j.." - "..h..":"..m..":"..s
	end
	return (str)
end

function delta_date(str) -- supprime les caractères T et Z de la chaîne str  et corrige l'heure suivant le fuseau horaire
	diff = 0
	if (str) then
		_, _, A, M, j, h, m, s = string.find(str, "^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z$")
		h = h + get_timezone()/3600
		diff = os.time()-os.time{year=A, month=M, day=j, hour=h, min=m, sec=s}
	end
	return (disp_time(diff))
end



function ReverseTable(t)
	local reversedTable = {}
	local itemCount = #t
	for k, v in ipairs(t) do
		reversedTable[itemCount + 1 - k] = v
	end
	return reversedTable
end

function searchName(contacts, phoneNumber)
	name = phoneNumber
	for index, variable in pairs(contacts) do
		if variable.Phone == phoneNumber then
			name = variable.Name
			break
		end
	end
	return name
end

function searchKey(children, mac)
	key = -1
	if children then
		for index, variable in pairs(children) do
			if variable.Key == mac then
				key = index
				break
			end
		end
	end
	return key
end

local scriptName = 'Livebox'
local scriptVersion = '1.12'

return {
	active = true,
	logging = {
					-- level	=   domoticz.LOG_DEBUG, -- Uncomment to override the dzVents global logging setting
					-- level	=   domoticz.LOG_INFO, -- Seulement un niveau peut être actif; commenter les autres
					-- level	=   domoticz.LOG_ERROR,											
					-- level	=   domoticz.LOG_DEBUG,
					-- level	=   domoticz.LOG_MODULE_EXEC_INFO,
		marker = scriptName..' '..scriptVersion
	},
	on = {
		timer = {
			'every '..tostring(fetchIntervalMins)..' minutes',
		},
	devices = {wifi5,wifi24,clearCallList,reboot,sonner}
	},

	execute = function(domoticz, item)
		local function readLuaFromJsonFile(fileName)
			local file = io.open(fileName, 'r')
			if file then
				local contents = file:read('*a')
				local lua_value = domoticz.utils.fromJSON(contents)
				io.close(file)
				return lua_value
			end
			return nil
		end
		--Connexion et récupération du cookies
		os.execute("curl -s -o \""..myOutput.."\" -X POST -c \""..myCookies.."\" -H 'Content-Type: application/x-sah-ws-4-call+json' -H 'Authorization: X-Sah-Login' -d \"{\\\"service\\\":\\\"sah.Device.Information\\\",\\\"method\\\":\\\"createContext\\\",\\\"parameters\\\":{\\\"applicationName\\\":\\\"so_sdkut\\\",\\\"username\\\":\\\"admin\\\",\\\"password\\\":\\\""..password.."\\\"}}\" http://"..adresseLB.."/ws > /dev/null")

		--Lecture du cookies pour utilisation ultérieure
		myContextID = os.capture("tail -n1 \""..myOutput.."\" | sed 's/{\"status\":0,\"data\":{\"contextID\":\"//1'| sed 's/\",//1' | sed 's/\"groups\":\"http,admin//1' | sed 's/\"}}//1'")
		domoticz.log('Context : '..myContextID, domoticz.LOG_DEBUG)
		
		if (item.isTimer)then
			
			--Données de connexion
			if SyncATM or SyncATMup or Attn or MargedAttn then
				MIBs=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"NeMo.Intf.data\\\",\\\"method\\\":\\\"getMIBs\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
				domoticz.log('MIBs : '..MIBs, domoticz.LOG_DEBUG)
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
					
					-- if UptimeLB then Uptime = disp_time(lbAPIData.status.dsl.dsl0.LastChange)
					-- domoticz.log('Uptime : '..Uptime, domoticz.LOG_INFO)
					-- domoticz.devices(UptimeLB).updateText(Uptime) end
		   
				end
			end
			
			-- Volume de données échangées
			if TransmitBlocks or ReceiveBlocks then
				DSLstats=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"NeMo.Intf.dsl0\\\",\\\"method\\\":\\\"getDSLStats\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
				domoticz.log('DSLstats : '..DSLstats, domoticz.LOG_DEBUG)
				local lbAPIDataDSL = domoticz.utils.fromJSON(DSLstats)
				if lbAPIDataDSL.status == nil then
					domoticz.log('Lecture de la MIBs DSL impossible', domoticz.LOG_ERROR)
				else
					domoticz.log("TransmitBlocks : "..lbAPIDataDSL.status.TransmitBlocks)
					if TransmitBlocks then domoticz.devices(TransmitBlocks).update(0,lbAPIDataDSL.status.TransmitBlocks) end
					domoticz.log("ReceiveBlocks : "..lbAPIDataDSL.status.ReceiveBlocks)
					if ReceiveBlocks then domoticz.devices(ReceiveBlocks).update(0,lbAPIDataDSL.status.ReceiveBlocks) end
				end
			end
			
			--État WiFi
			if wifi24 or wifi5 then
				wifi=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"NeMo.Intf.lan\\\",\\\"method\\\":\\\"getMIBs\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
				domoticz.log('wifi : '..wifi, domoticz.LOG_DEBUG)
				local lbAPIDataWifi = domoticz.utils.fromJSON(wifi)
				if lbAPIDataWifi.status == nil then
					domoticz.log('Lecture de la MIBs Wifi impossible', domoticz.LOG_ERROR)
				else
					if wifi24 then 
						domoticz.log('Wifi 2.4 Ghz : '..lbAPIDataWifi.status.wlanvap.wl0.VAPStatus, domoticz.LOG_INFO)
						if (lbAPIDataWifi.status.wlanvap.wl0.VAPStatus == 'Up' and domoticz.devices(wifi24).active == false)then
							domoticz.devices(wifi24).switchOn().silent()
						elseif (lbAPIDataWifi.status.wlanvap.wl0.VAPStatus ~= 'Up' and domoticz.devices(wifi24).active)then
							domoticz.devices(wifi24).switchOff().silent()
						end
					end	
					
					if wifi5 then
						if (lbAPIDataWifi.status.wlanvap.eth6)then
							domoticz.log('Wifi 5 Ghz : '..lbAPIDataWifi.status.wlanvap.eth6.VAPStatus, domoticz.LOG_INFO)
							if (lbAPIDataWifi.status.wlanvap.eth6.VAPStatus == 'Up' and domoticz.devices(wifi5).active == false)then
								domoticz.devices(wifi5).switchOn().silent()
							elseif (lbAPIDataWifi.status.wlanvap.eth6.VAPStatus ~= 'Up' and domoticz.devices(wifi5).active)then
								domoticz.devices(wifi5).switchOff().silent()
							end
						else
							--support de la livebox3
							domoticz.log('Wifi 5 Ghz : '..lbAPIDataWifi.status.wlanvap.wl1.VAPStatus, domoticz.LOG_INFO)
							if (lbAPIDataWifi.status.wlanvap.wl1.VAPStatus == 'Up' and domoticz.devices(wifi5).active == false)then
								domoticz.devices(wifi5).switchOn().silent()
							elseif (lbAPIDataWifi.status.wlanvap.wl1.VAPStatus ~= 'Up' and domoticz.devices(wifi5).active)then
								domoticz.devices(wifi5).switchOff().silent()
							end
						end
					end	
				end
			end 
			
			--Dernier Appel reçu ou émis
			local missedCallList = ""
			local failedCallList = ""
			local succeededCallList = ""
			if DernierAppel or missedCall or failedCall or succeededCall then
				callList=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"VoiceService.VoiceApplication\\\",\\\"method\\\":\\\"getCallList\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
				domoticz.log('callList : '..callList, domoticz.LOG_DEBUG)
				local lbAPIDataCallList = domoticz.utils.fromJSON(callList)
				if lbAPIDataCallList.status == nil then
					domoticz.log('Lecture de la MIBs Téléphonie impossible', domoticz.LOG_ERROR)
				else
					domoticz.log('CallList : '..#lbAPIDataCallList.status, domoticz.LOG_INFO)
					if (#lbAPIDataCallList.status>0) then
						contacts = readLuaFromJsonFile(fichier_contacts)
						if contacts == nil then contacts = {} end 
						domoticz.log('Dernier Appel : '..lbAPIDataCallList.status[#lbAPIDataCallList.status].remoteNumber, domoticz.LOG_INFO)
						domoticz.log('Dernier Appel : '..traduction(lbAPIDataCallList.status[#lbAPIDataCallList.status].callType), domoticz.LOG_INFO)
						NumeroEtat = searchName(contacts, lbAPIDataCallList.status[#lbAPIDataCallList.status].remoteNumber) .. " - "..lbAPIDataCallList.status[#lbAPIDataCallList.status].callType
						if DernierAppel and domoticz.devices(DernierAppel).text ~= traduction(NumeroEtat) then
								domoticz.devices(DernierAppel).updateText(traduction(NumeroEtat))
						end
						-- x Appels manqués, sans réponse, réussis
						for i, call in ipairs(ReverseTable(lbAPIDataCallList.status)) do
							if call.callType == "missed" and nbMissedCall > 0 then
								--domoticz.log(call.remoteNumber .. " " .. traduction(call.callType) .. " " .. format_date(call.startTime), domoticz.LOG_INFO)
								missedCallList = missedCallList .. searchName(contacts, call.remoteNumber) .. " - " .. format_date(call.startTime) .. "\n"
								nbMissedCall = nbMissedCall - 1
							end
							if call.callType == "failed" and nbFailedCall > 0 then
								--domoticz.log(call.remoteNumber .. " " .. traduction(call.callType) .." ".. format_date(call.startTime), domoticz.LOG_INFO)
								failedCallList = failedCallList .. call.remoteNumber .." - ".. format_date(call.startTime) .. "\n"
								nbFailedCall = nbFailedCall - 1
							end
							if call.callType == "succeeded" and nbSucceededCall > 0 then
								--domoticz.log(call.remoteNumber .. " " .. traduction(call.callType) .. " " .. format_date(call.startTime), domoticz.LOG_INFO)
								succeededCallList = succeededCallList .. searchName(contacts, call.remoteNumber) .. " - " .. format_date(call.startTime) .. "\n"
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
			end
			
			if firmware or devices_livebox_mac_adress or ServiceTV or VoIP or UptimeLB then
				LAN=os.capture("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..myContextID.."\" -d \"{\\\"service\\\":\\\"Devices.Device.HGW\\\",\\\"method\\\":\\\"topology\\\",\\\"parameters\\\":{}}\" http://"..adresseLB.."/ws")
				LAN=LAN:gsub('"SerialNumber ... ','"SerialNumber" : "'):gsub(" ... ",'     ')
				domoticz.log('LAN : '..LAN, domoticz.LOG_DEBUG)
				LAN = domoticz.utils.fromJSON(LAN)
			--Version du firmware
				if LAN.status[1].SoftwareVersion and firmware then
					domoticz.log("Version Firmware : "..LAN.status[1].SoftwareVersion,domoticz.LOG_INFO)
					if domoticz.devices(firmware).text ~= LAN.status[1].SoftwareVersion then
						domoticz.devices(firmware).updateText(LAN.status[1].SoftwareVersion)
					end
				end
			
			--Uptime
				uptime = LAN.status[1]['Children']
				for l=1,#uptime do -- récupération de l'arbre des périphériques LAN
					if uptime[l]["Key"]== "lan" then
						uptime = uptime[l]
						break
					end
				end
				if uptime.FirstSeen and UptimeLB then
					uptime = delta_date(uptime.FirstSeen) 
					domoticz.log("Uptime : "..uptime,domoticz.LOG_INFO)
					if domoticz.devices(UptimeLB).text ~= uptime then
						domoticz.devices(UptimeLB).updateText(uptime)
					end
				end
				
			--Etat du Service TV
				if LAN.status[1].IPTV and ServiceTV then
					domoticz.log("IPTV : "..tostring(LAN.status[1].IPTV),domoticz.LOG_INFO)
					if (LAN.status[1].IPTV)then
						domoticz.devices(ServiceTV).switchOn().checkFirst()
					else
						domoticz.devices(ServiceTV).switchOff().checkFirst()
					end
				end
				
			--Etat du Service VoIP
				if LAN.status[1].Telephony and VoIP then
					domoticz.log("Telephony : "..tostring(LAN.status[1].Telephony),domoticz.LOG_INFO)
					if (LAN.status[1].Telephony)then
						domoticz.devices(VoIP).switchOn().checkFirst()
					else
						domoticz.devices(VoIP).switchOff().checkFirst()
					end
				end
				
			--Etat du Service Internet
				if LAN.status[1].Internet and internet then
					domoticz.log("Internet : "..tostring(LAN.status[1].Internet),domoticz.LOG_INFO)
					if (LAN.status[1].Internet)then
						domoticz.devices(internet).switchOn().checkFirst()
					else
						domoticz.devices(internet).switchOff().checkFirst()
					end
				end
				
			-- IP WAN
				if LAN.status[1].ConnectionIPv4Address and IPWAN then
					domoticz.log("IP WAN : "..LAN.status[1].ConnectionIPv4Address,domoticz.LOG_INFO)
					if  domoticz.devices(IPWAN).text ~= LAN.status[1].ConnectionIPv4Address then
						domoticz.devices(IPWAN).updateText(LAN.status[1].ConnectionIPv4Address)
					end
				end

			-- IPv6WAN
				if LAN.status[1].ConnectionIPv6Address and IPv6WAN then
					domoticz.log("IPv6 WAN : "..LAN.status[1].ConnectionIPv6Address,domoticz.LOG_INFO)
					if  domoticz.devices(IPv6WAN).text ~= LAN.status[1].ConnectionIPv6Address then
						domoticz.devices(IPv6WAN).updateText(LAN.status[1].ConnectionIPv6Address)
					end
				end
			

			--Présence de périphériques
				LAN = LAN.status[1]['Children']
				for l=1,#LAN do -- récupération de l'arbre des périphériques LAN
					if LAN[l]["Key"]== "lan" then
						LAN = LAN[l]['Children']
						break
					end
				end
				local k=-1
				for i=1,#devices_livebox_mac_adress do -- recherche de l'adresse MAC et son statut
					for j=1,#LAN do
						if(LAN[j]['DiscoverySource'] == "selflan")then
							k=searchKey(LAN[j]['Children'],devices_livebox_mac_adress[i])
							if (k~=-1 and LAN[j]['Children'][k]['Active'])then
								domoticz.log('switch : '..LAN[j]['Children'][k]['Name'].." On", domoticz.LOG_INFO)
								if (domoticz.devices(LAN[j]['Children'][k]['Name']))then
									domoticz.devices(LAN[j]['Children'][k]['Name']).switchOn().checkFirst()
								end	
								break
							elseif (k~=-1 and LAN[j]['Children'][k]['Active']==false)then
								domoticz.log('switch : '..LAN[j]['Children'][k]['Name'].." Off", domoticz.LOG_INFO)
								if (domoticz.devices(LAN[j]['Children'][k]['Name']))then
									domoticz.devices(LAN[j]['Children'][k]['Name']).switchOff().checkFirst()
								end
								break
							end
						end
					end
					if (k==-1) then
						domoticz.log('mac : '..devices_livebox_mac_adress[i].." introuvable", domoticz.LOG_INFO)
					end
				end
			end
			
		else
			if(item.name == wifi5)then
				if liveBox3 then chip='wifi1_ath' else chip='wifi0_quan' end
				os.execute("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..
					myContextID.."\" -d \"{\\\"service\\\":\\\"NeMo.Intf.lan\\\",\\\"method\\\":\\\"setWLANConfig\\\",\\\"parameters\\\":{\\\"mibs\\\":{\\\"penable\\\":{\\\""..chip.."\\\":{\\\"PersistentEnable\\\":"..
					tostring(item.active)..", \\\"Enable\\\":true}}}}}\" http://"..adresseLB.."/ws &")
				domoticz.log("wifi5 "..tostring(item.active),domoticz.LOG_INFO)
			elseif(item.name == wifi24)then
				if liveBox3 then chip='wifi0_ath' else chip='wifi0_bcm' end
				os.execute("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..
					myContextID.."\" -d \"{\\\"service\\\":\\\"NeMo.Intf.lan\\\",\\\"method\\\":\\\"setWLANConfig\\\",\\\"parameters\\\":{\\\"mibs\\\":{\\\"penable\\\":{\\\""..chip.."\\\":{\\\"PersistentEnable\\\":"..
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
				
			elseif(item.name == sonner)then
				os.execute("curl -s -b \""..myCookies.."\" -X POST -H 'Content-Type: application/x-sah-ws-4-call+json' -H \"X-Context: "..
					myContextID.."\" -d \"{\\\"parameters\\\":{}}\" http://"..adresseLB.."/sysbus/VoiceService/VoiceApplication:ring &")
				domoticz.log("sonner "..tostring(item.active),domoticz.LOG_INFO)
			end
		end
		--Déconnexion et suppression des fichiers temporaires
		os.execute("curl -s -b "..myCookies.." -X POST http://"..adresseLB.."/logout &")
		os.execute('rm "'..myCookies..'" "'..myOutput..'" &')
	end
}
