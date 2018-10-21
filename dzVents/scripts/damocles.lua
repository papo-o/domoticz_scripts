--[[
name : damocles.lua
auteur : papoo
creation : 26/08/2018
mise à  jour : 21/10/2018

Install SNMP on Raspberry Pi
Log in to you Raspberry Pi and issue:

sudo apt-get install snmpd
sudo apt-get install snmp

Reboot your Pi:
sudo reboot

Check if SNMP is up and running, issue:
snmpget -c PASSWORD -v1 -O qv DAMOCLESIPADDRESS 1.3.6.1.2.1.1.5.0

Replace PASSWORD with the Community name you entered while setting up your DAMOCLES
Replace DAMOCLESIPADDRESS with the ip address of your DAMOCLES
You should get something like this:
Damocles 1208
Then create:
1 device Switch
x meter device   
--]]

    local DAMOCLESIp = "192.168.100.200"                                 -- DAMOCLES IP Address
    local CommunityPassword = "private"                               -- SNMP Password
    local DAMOCLES = "Damocles"                                       -- DAMOCLES Switch
    local DOMOTICZ_CPT_1 = "Compteur Eau Froide"                      -- DOMOTICZ CPT 1 Eau Froide
    local DOMOTICZ_CPT_2 = "Compteur Eau Chaude"                      -- DOMOTICZ CPT 2 Eau Chaude
    local DOMOTICZ_CPT_3 = "Compteur Gaz"                             -- DOMOTICZ CPT 3 gaz
    local DOMOTICZ_CPT_4 = "Compteur Prises"                          -- DOMOTICZ CPT 4 Prises
    local DOMOTICZ_CPT_5 = "Compteur Lumières"                        -- DOMOTICZ CPT 5 Lumiere 
    local DOMOTICZ_CPT_6 = "Compteur Technique"                       -- DOMOTICZ CPT 6 Technique
    local OID_CPT_1 = ".1.3.6.1.4.1.21796.4.6.1.3.1.6.1.1005"         -- DOMOTICZ CPT 1 Eau Froide
    local OID_CPT_2 = ".1.3.6.1.4.1.21796.3.4.1.1.6.2"                -- DOMOTICZ CPT 2 Eau Chaude
    local OID_CPT_3 = ".1.3.6.1.4.1.21796.3.4.1.1.6.3"                -- DOMOTICZ CPT 3 gaz
    local OID_CPT_4 = ".1.3.6.1.4.1.21796.3.4.1.1.6.4"                -- DOMOTICZ CPT 4 Prises
    local OID_CPT_5 = ".1.3.6.1.4.1.21796.3.4.1.1.6.5"                -- DOMOTICZ CPT 5 Lumiere 
    local OID_CPT_6 = ".1.3.6.1.4.1.21796.3.4.1.1.6.6"                -- DOMOTICZ CPT 6 Technique

    local pir_cave ="pir cave"
    local lumiere_cave = "Lumiere cave"
   
return {
    active = true,
    on = {
    timer = {'every minute'},
    devices = { DAMOCLES, DOMOTICZ_CPT_2, DOMOTICZ_CPT_3, DOMOTICZ_CPT_4, DOMOTICZ_CPT_5, DOMOTICZ_CPT_6, pir_cave}
    },    
   -- on = { devices = { "your trigger device" }},
        
  logging =   { -- level    =   domoticz.LOG_INFO,                                             -- Seulement un niveau peut être actif; commenter les autres
                level    =   domoticz.LOG_ERROR,                                            -- Only one level can be active; comment others
                -- level    =   domoticz.LOG_DEBUG,
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker    =   "Damoclès Monitor v1.1 "      },
    
    execute = function(dz, item)

        if (item.isTimer)then
            local i = 0
            local results = {}
            local command = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..DAMOCLESIp..' '..OID_CPT_2..' '..OID_CPT_3..' '..OID_CPT_4..' '..OID_CPT_5..' '..OID_CPT_6 --..' '..OID_HDtemp2
            dz.log('snmpget -c '..CommunityPassword..' -v1 -O qv '..DAMOCLESIp..' '..OID_CPT_2..' '..OID_CPT_3..' '..OID_CPT_4..' '..OID_CPT_5..' '..OID_CPT_6,dz.LOG_DEBUG)
            local handle = assert(io.popen(command))
            for line in handle:lines() do
            --   dz.log(line,dz.LOG_DEBUG)
                results[i] =  line
                i = i + 1
            end
            handle:close()
            if results[0] then
                dz.log("CPT2 : "..results[0],dz.LOG_DEBUG)
                dz.log("index CPT2 : "..dz.devices(DOMOTICZ_CPT_2).counter,dz.LOG_DEBUG) 
                if dz.devices(DOMOTICZ_CPT_2).counter < (results[0]/1000) then
                    dz.devices(DOMOTICZ_CPT_2).updateCounter(results[0])
                    dz.log("Maj compteur 2",dz.LOG_DEBUG)
                    elseif dz.devices(DOMOTICZ_CPT_2).counter > (results[0]/1000) then
                    dz.log("Maj compteur 2 sur damoclès",dz.LOG_DEBUG)
                    local write_cpt1 = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..OID_CPT_2..' i '..DOMOTICZ_CPT_2
                    local handle1 = assert(io.popen(write_cpt1))
                    handle1:close()
                    end
                end
            if results[1] then 
                dz.log("CPT3 : "..results[1],dz.LOG_DEBUG)
                dz.log("index CPT3 : "..dz.devices(DOMOTICZ_CPT_3).counter,dz.LOG_DEBUG)
                if dz.devices(DOMOTICZ_CPT_3).counter < (results[1]/1000) then
                    dz.devices(DOMOTICZ_CPT_3).updateCounter(results[1])
                    dz.log("Maj compteur 3",dz.LOG_DEBUG)
                    elseif dz.devices(DOMOTICZ_CPT_3).counter > (results[1]/1000) then
                    dz.log("Maj compteur 3 sur damoclès",dz.LOG_DEBUG)
                    local write_cpt1 = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..OID_CPT_3..' i '..DOMOTICZ_CPT_3
                    local handle1 = assert(io.popen(write_cpt1))
                    handle1:close()
                    end            
                end        
            if results[2] then 
                dz.log("CPT4 : "..results[2],dz.LOG_DEBUG)
                dz.log("index CPT4 : "..dz.devices(DOMOTICZ_CPT_4).counter,dz.LOG_DEBUG)
                if dz.devices(DOMOTICZ_CPT_4).counter < (results[2]/1000) then
                    dz.devices(DOMOTICZ_CPT_4).updateCounter(results[2])
                    dz.log("Maj compteur 4",dz.LOG_DEBUG)
                    elseif dz.devices(DOMOTICZ_CPT_4).counter > (results[2]/1000) then
                    dz.log("Maj compteur 4 sur damoclès",dz.LOG_DEBUG)
                    local write_cpt1 = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..OID_CPT_4..' i '..DOMOTICZ_CPT_4
                    local handle1 = assert(io.popen(write_cpt1))
                    handle1:close()
                    end
                end        
            if results[3] then 
                dz.log("CPT5 : "..results[3],dz.LOG_DEBUG)
                dz.log("index CPT5 : "..dz.devices(DOMOTICZ_CPT_5).counter,dz.LOG_DEBUG)
                if dz.devices(DOMOTICZ_CPT_5).counter < (results[3]/1000) then
                    dz.devices(DOMOTICZ_CPT_5).updateCounter(results[3])
                    dz.log("Maj compteur 5",dz.LOG_DEBUG)
                    elseif dz.devices(DOMOTICZ_CPT_5).counter > (results[3]/1000) then
                    dz.log("Maj compteur 5 sur damoclès",dz.LOG_DEBUG)
                    local write_cpt1 = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..OID_CPT_5..' i '..DOMOTICZ_CPT_5
                    local handle1 = assert(io.popen(write_cpt1))
                    handle1:close()
                    end            
                end
            if results[4] then 
                dz.log("CPT6 : "..results[4],dz.LOG_DEBUG)
                dz.log("index CPT6 : "..dz.devices(DOMOTICZ_CPT_6).counter,dz.LOG_DEBUG)
                if dz.devices(DOMOTICZ_CPT_6).counter < (results[4]/1000) then
                    dz.devices(DOMOTICZ_CPT_6).updateCounter(results[4])
                    dz.log("Maj compteur 6",dz.LOG_DEBUG)
                    elseif dz.devices(DOMOTICZ_CPT_2).counter > (results[4]/1000) then
                    dz.log("Maj compteur 6 sur damoclès",dz.LOG_DEBUG)
                    local write_cpt1 = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..OID_CPT_6..' i '..DOMOTICZ_CPT_6
                    local handle1 = assert(io.popen(write_cpt1))
                    handle1:close()
                    end            
                end      


            if results[0] and results[1] and results[2] and results[3] and results[4]then
                    dz.log("Requete SNMP correcte ",dz.LOG_DEBUG)
                    dz.devices(DAMOCLES).switchOn().checkFirst()
                else
                    dz.log("Requete SNMP incorrecte ",dz.LOG_DEBUG)
                    dz.devices(DAMOCLES).switchOff().checkFirst()
                end
        else
            if(item.name == pir_cave)then
                if dz.devices(pir_cave).active then
                dz.devices(lumiere_cave).switchOn().forSec(2)
                end
            end
        end
    end
}
