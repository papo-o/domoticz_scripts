--[[
name : synology2.lua
auteur : papoo
creation : 17/02/2019
mise à  jour : 18/12/2019

https://pon.fr/dzvents-supervision-dun-nas-synology-avec-snmp/
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/synology2.lua
https://easydomoticz.com/forum/viewtopic.php?f=17&t=7022
https://www.domoticz.com/forum/viewtopic.php?f=59&t=24618

For this script to work you need to enable SNMP on your synology NAS and install SNMP on your Raspberry Pi

Enable SNMP on your synology NAS
 
Go toMain Menu>Control Panel >SNMP to enable SNMP service, which allows users to monitor
Synology DiskStation network flow with the network management software.

You can use V1/V2
And set a password (Community)

Install SNMP on Raspberry Pi
Log in to you Raspberry Pi and issue:

sudo apt-get install snmpd
sudo apt-get install snmp

Reboot your Pi:
sudo reboot

Check if SNMP is up and running, issue:
snmpget -v 2c -c PASSWORD -O qv NASIPADDRESS 1.3.6.1.4.1.6574.1.5.1.0

Replace PASSWORD with the Community name you entered while setting up your NAS
Replace NASIPADDRESS with the ip address of your NAS
You should get something like this:
"DS218+" which corresponds to your Synology Model

how to choose disk capacity to monitor?

snmpwalk -v 2c -c PASSWORD NASIPADDRESS 1.3.6.1.2.1.25.2.3.1.3
results of my DS218 :

HOST-RESOURCES-MIB::hrStorageDescr.1 = STRING: Physical memory
HOST-RESOURCES-MIB::hrStorageDescr.3 = STRING: Virtual memory
HOST-RESOURCES-MIB::hrStorageDescr.6 = STRING: Memory buffers
HOST-RESOURCES-MIB::hrStorageDescr.7 = STRING: Cached memory
HOST-RESOURCES-MIB::hrStorageDescr.8 = STRING: Shared memory
HOST-RESOURCES-MIB::hrStorageDescr.10 = STRING: Swap space
HOST-RESOURCES-MIB::hrStorageDescr.31 = STRING: /
HOST-RESOURCES-MIB::hrStorageDescr.36 = STRING: /tmp
HOST-RESOURCES-MIB::hrStorageDescr.37 = STRING: /run
HOST-RESOURCES-MIB::hrStorageDescr.38 = STRING: /dev/shm
HOST-RESOURCES-MIB::hrStorageDescr.39 = STRING: /sys/fs/cgroup
HOST-RESOURCES-MIB::hrStorageDescr.40 = STRING: /run/cgmanager/fs
HOST-RESOURCES-MIB::hrStorageDescr.51 = STRING: /volume1
HOST-RESOURCES-MIB::hrStorageDescr.54 = STRING: /volume1/@docker/btrfs


then modify     OID_HDUnit, OID_HDTotal, OID_HDUsed variables with your last number choice (.38 on DSM 5.1, .41 on DSM 6.0+ or .51 on my new DS218)

if you have à DS2XX model, uncomment     -- local OID_HDtemp2='1.3.6.1.4.1.6574.2.1.1.6.1'  to show the hdd2 temperature
Then create:
1 device Switch
1 temperature device
3 percent devices
x meter device   
--]]
--------------------------------------------
-------------Fonctions----------------------
-------------------------------------------- 
function format(str)
   if (str) then
      str = string.gsub (str, " Bytes", "")
      str = string.gsub (str, " kB", "")

   end
   return str   
end

-------------------------------------------
-------------Fin Fonctions-----------------
-------------------------------------------

    local NasIp = "diskstation2"                            -- NAS IP Address
    local CommunityPassword = "synology"                    -- SNMP Password
    local NAS = "Synology"                                  -- NAS Switch
    local NAS_TEMP = "Synology Temp"
    local NAS_CPU = "Synology Utilisation CPU"              -- NAS CPU 
    local NAS_MEM = "Synology Utilisation RAM"              -- NAS MEM 
    local NAS_HD_SPACE_PERC = "Synology Occupation Disque"  -- NAS HD Space  in %
    local NAS_HD_SPACE = "Synology Espace Disponible"       -- NAS HD Space  in Go (custom sensor)
    local NAS_HDD1_TEMP = "Synology HDD1 Temp"              -- NAS HD1 Temp, nil if unused 
    local NAS_HDD2_TEMP = nil                               -- NAS HD2 Temp, nil if unused
    local NAS_HDD3_TEMP = nil                               -- NAS HD3 Temp, nil if unused
    local NAS_HDD4_TEMP = nil                               -- NAS HD4 Temp, nil if unused
	local NAS_UPLOAD    = nil                               -- NAS upload in ko/s, nil if unused
	local NAS_DOWNLOAD   = nil                               -- NAS download in ko/s, nil if unused
    local OID_NAS_TEMP = '1.3.6.1.4.1.6574.1.2.0'
    local OID_HDUnit = '1.3.6.1.2.1.25.2.3.1.4.51'          -- OID HD Unit Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+ or .51 on my DS218
    local OID_HDTotal = '1.3.6.1.2.1.25.2.3.1.5.51'         -- OID Total space volume in Go Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+ or .51 on my DS218
    local OID_HDUsed = '1.3.6.1.2.1.25.2.3.1.6.51'          -- OID Space used volume in Go Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+ or .51 on my DS218
    local OID_CpuUser = '1.3.6.1.4.1.2021.11.9.0'           -- OID CPU user
    local OID_CpuSystem = '1.3.6.1.4.1.2021.11.10.0'        -- OID CPU System
    local OID_MemAvailable = '1.3.6.1.4.1.2021.4.13.0'      -- OID Free Memory Available
    local OID_MemTotalSwap = '1.3.6.1.4.1.2021.4.3.0'       -- OID MemTotalSwap
    local OID_MemTotalReal = '1.3.6.1.4.1.2021.4.5.0'       -- OID MemTotalReal
    local OID_MemTotalFree = '1.3.6.1.4.1.2021.4.11.0'      -- OID MemTotalFree
    local OID_HDtemp1 = '1.3.6.1.4.1.6574.2.1.1.6.0'        -- OID Temperature HDD1   
    local OID_HDtemp2 = '1.3.6.1.4.1.6574.2.1.1.6.1'        -- OID Temperature HDD2 
    local OID_HDtemp3 = '1.3.6.1.4.1.6574.2.1.1.6.2'        -- OID Temperature HDD3
    local OID_HDtemp4 = '1.3.6.1.4.1.6574.2.1.1.6.3'        -- OID Temperature HDD4
	local OID_ifHCOutOctets = '1.3.6.1.2.1.2.2.1.16.3'		-- OID ifHCOutOctets if not work try 1.3.6.1.2.1.2.2.1.16.1 or 1.3.6.1.2.1.2.2.1.16.2
	local OID_ifHCInOctets = '1.3.6.1.2.1.2.2.1.10.3'		-- OID ifHCInOctets if not work try 1.3.6.1.2.1.2.2.1.10.1 or 1.3.6.1.2.1.2.2.1.10.2
    --local OID_Raid_Status = '1.3.6.1.4.1.6574.3.1.1.3.0'        -- OID Raid Status
    --local OID_Physical_Memory_Units = '1.3.6.1.2.1.25.2.3.1.4.1'
    --local OID_Physical_Memory_Size = '1.3.6.1.2.1.25.2.3.1.5.1'
    --local OID_Physical_Memory_Used = '1.3.6.1.2.1.25.2.3.1.6.1'
    --local OID_system_memory_total = '1.3.6.1.4.1.2021.4.5.0'
    --local OID_system_memory_free = '1.3.6.1.4.1.2021.4.6.0'
    --local OID_system_vsmemory_shared = '1.3.6.1.4.1.2021.4.13.0'
    --local OID_system_vsmemory_buffer = '1.3.6.1.4.1.2021.4.14.0'

   
return {
    active = true,
    on = {
    timer = {'every minute'}
    },    
   -- on = { devices = { "your trigger device" }},
        
  logging =   {    level    =    domoticz.LOG_DEBUG,                                             -- Seulement un niveau peut être actif; commenter les autres
                -- level    =   domoticz.LOG_INFO,                                            -- Only one level can be active; comment others
                -- level    =   domoticz.LOG_ERROR,
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                   marker    =   "Synology Monitor v1.41 "      },
 	data = {
 		ifHCInOctets =  { history = true, maxItems = 2 },
		ifHCOutOctets = { history = true, maxItems = 2 },
	},
    execute = function(dz)
		local i, lastIfHCInOctets, lastIfHCOutOctets, ifHCInSecondsAgo, IfHCOutSecondsAgo, upload, download, round, results = 0, 0, 0, 0, 0, 0, 0, dz.utils.round, {}
		dz.data.ifHCOutOctets.add('0')
		dz.data.ifHCInOctets.add('0')
	
		if dz.data.ifHCOutOctets.getOldest() ~= nil then 
			lastIfHCOutOctets = dz.data.ifHCOutOctets.getOldest().data 
			ifHCOutSecondsAgo = dz.data.ifHCOutOctets.getOldest().time.secondsAgo
		end
		if dz.data.ifHCInOctets.getOldest() ~= nil then 
			lastIfHCInOctets = dz.data.ifHCInOctets.getOldest().data
			ifHCInSecondsAgo = dz.data.ifHCInOctets.getOldest().time.secondsAgo 
		end	
		dz.log("last ifHCOutOctets : "..tostring(lastIfHCOutOctets).." at "..tostring(ifHCOutSecondsAgo).." seconds ago",dz.LOG_DEBUG) 	
		dz.log("last ifHCInOctets : "..tostring(lastIfHCInOctets).." at "..tostring(ifHCInSecondsAgo).." seconds ago",dz.LOG_DEBUG) 
		
		
		
        local command = 'snmpget -v 2c -c '..CommunityPassword..' -O qv '..NasIp..' '..OID_NAS_TEMP..' '..OID_HDUnit..' '..OID_HDTotal..' '..OID_HDUsed..' '..OID_CpuUser..' '..OID_CpuSystem..' '
			..OID_MemAvailable ..' '.. OID_MemTotalSwap ..' '..OID_MemTotalReal..' '..OID_MemTotalFree..' '..OID_HDtemp1..' '..OID_HDtemp2..' '..OID_HDtemp3..' '..OID_HDtemp4..' '..OID_ifHCOutOctets..' '
			..OID_ifHCInOctets --..' '..OID_Physical_Memory_Units ..' '..OID_Physical_Memory_Used..' '..OID_Physical_Memory_Size ..' '..OID_system_memory_total ..' '..OID_system_memory_free ..' '.. OID_system_vsmemory_shared ..' '.. OID_system_vsmemory_buffer 
        local handle = assert(io.popen(command))
        for line in handle:lines() do
            results[i] =  format(line)
            i = i + 1
        end
        handle:close()
        if results[0] then
            dz.log("NASTemp : "..results[0],dz.LOG_DEBUG)
            if NAS_TEMP then dz.devices(NAS_TEMP).update(0,results[0]) end
            end
        if results[1] then dz.log("HDUnit : "..results[1],dz.LOG_DEBUG) end
        if results[2] then dz.log("HDTotal : "..results[2],dz.LOG_DEBUG) end
        if results[3] then dz.log("HDUsed : "..results[3],dz.LOG_DEBUG) end
        if results[4] then dz.log("CpuUser : "..results[4],dz.LOG_DEBUG) end
        if results[5] then dz.log("CpuSystem : "..results[5],dz.LOG_DEBUG) end
        
        if results[1] and results[2] then

           HDTotalGo = dz.utils.round((results[2] *  results[1] / 1024 / 1024 / 1024/1024),2)
           dz.log("HDTotalGo : "..HDTotalGo,dz.LOG_DEBUG)
        end
         if results[1] and results[3] then
           HDUsedGo = dz.utils.round(((results[3]) *  results[1] / 1024 / 1024 / 1024/1024), 2)
        end       

        if results[1] and results[2] and results[3] then
            HDFreeGo = dz.utils.round(((results[2] - results[3]) *  results[1] / 1024 / 1024 / 1024/1024),2)
        end
        if HDFreeGo then 
            dz.log("HDFreeGo : "..HDFreeGo,dz.LOG_DEBUG) 
            dz.devices(NAS_HD_SPACE).update(0,HDFreeGo)
            end 
        if results[2] and results[3] then         
            HDFreePerc = dz.utils.round(((results[3] * 100) / results[2]), 0)
        end
        if HDFreePerc then 
            dz.log("HDFreePercent : "..HDFreePerc,dz.LOG_DEBUG)
            dz.devices(NAS_HD_SPACE_PERC).update(0,HDFreePerc)
            end
        if results[4] and results[5] then
            CpuUsed = (results[4] + results[5])
        end
        if CpuUsed then 
            dz.log("CpuUsed : "..CpuUsed,dz.LOG_DEBUG)
            dz.devices(NAS_CPU).update(0,CpuUsed)
            end

        if results[7] then
            dz.log("memTotalSwap: "..tostring(results[7]),dz.LOG_DEBUG)
        end
        if results[8] then
            dz.log("memTotalReal: "..tostring(results[8]),dz.LOG_DEBUG)
        end
        if results[9] then
            dz.log("memTotalFree: "..tostring(results[9]),dz.LOG_DEBUG)
        end

        if results[7] and results[8] and results[9] then
            MemUsedPerc = dz.utils.round(100-results[9]*100/(results[7]+results[8]), 0)
        end
        if MemUsedPerc then 
            dz.log("MemUsedPercent : "..MemUsedPerc,dz.LOG_DEBUG)
            dz.devices(NAS_MEM).update(0,MemUsedPerc)
        end

        if results[10] then 
            dz.log("HDTemp1 : "..tostring(results[10]),dz.LOG_DEBUG) 
            if NAS_HDD1_TEMP ~= nil then dz.devices(NAS_HDD1_TEMP).update(0,results[10]) end
        end
        if results[11] then 
            dz.log("HDTemp2 : "..tostring(results[11]),dz.LOG_DEBUG) 
            if NAS_HDD2_TEMP ~= nil then dz.devices(NAS_HDD2_TEMP).update(0,results[11]) end
        end
        if results[12] then 
            dz.log("HDTemp3 : "..tostring(results[12]),dz.LOG_DEBUG) 
            if NAS_HDD3_TEMP ~= nil then dz.devices(NAS_HDD3_TEMP).update(0,results[12]) end
        end
        if results[13] then 
            dz.log("HDTemp4 : "..tostring(results[13]),dz.LOG_DEBUG) 
            if NAS_HDD4_TEMP ~= nil then dz.devices(NAS_HDD4_TEMP).update(0,results[13]) end
        end

        if results[14] then 
            dz.log("ifHCOutOctets : "..tostring(results[14]),dz.LOG_DEBUG) 
			dz.data.ifHCOutOctets.add(tostring(results[14]))
			if tonumber(lastIfHCOutOctets) > 0 and tonumber(results[14]) > tonumber(lastIfHCOutOctets) then upload = round(((tonumber(results[14]) - tonumber(lastIfHCOutOctets)) / tonumber(ifHCOutSecondsAgo) / 1024)) end
			if NAS_UPLOAD ~= nil then dz.devices(NAS_UPLOAD).update(0,tostring(upload)) end
		end
        if results[15] then 
            dz.log("ifHCInOctets : "..tostring(results[15]),dz.LOG_DEBUG) 
			dz.data.ifHCInOctets.add(tostring(results[15]))	
			if tonumber(lastIfHCInOctets) > 0 and tonumber(results[15]) > tonumber(lastIfHCInOctets) then download = round(((tonumber(results[15]) - tonumber(lastIfHCInOctets)) / tonumber(ifHCInSecondsAgo) / 1024)) end
			if NAS_DOWNLOAD ~= nil then dz.devices(NAS_DOWNLOAD).update(0,tostring(download)) end		
		end

		dz.log("Upload : "..tostring(upload).."ko/s, Download : "..tostring(download).."ko/s",dz.LOG_DEBUG) 


        if results[0] and results[5] and results[6] then
                dz.log("Requete SNMP correcte ",dz.LOG_DEBUG)
                dz.devices(NAS).switchOn().checkFirst()
            else
                dz.log("Requete SNMP incorrecte ",dz.LOG_DEBUG)
                dz.devices(NAS).switchOff().checkFirst()
            end

        --RAID Status :
        --OK(1), Repairing(2), Migrating(3), Expanding(4), Deleting(5), Creating(6), RaidSyncing(7), RaidParityChecking(8), RaidAssembling(9), Canceling(10), Degraded(11), Creashed(12)
    end
}
