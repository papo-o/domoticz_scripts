--[[
name : hwg_pwr.lua
auteur : papoo
creation : 26/08/2018
mise à  jour : 28/08/2018

Install SNMP on Raspberry Pi
Log in to you Raspberry Pi and issue:

sudo apt-get install snmpd
sudo apt-get install snmp

Reboot your Pi:
sudo reboot

Check if SNMP is up and running, issue:
snmpget -c private -v1 -O qv hwg_pwrIPADDRESS 1.3.6.1.2.1.1.5.0

Replace PASSWORD with the Community name you entered while setting up your hwg_pwr
Replace hwg_pwrIPADDRESS with the ip address of your hwg_pwr
You should get something like this:
hwg_pwr 1208
Then create:
1 device Switch
x meter device   
--]]

    local hwg_pwrIp = "192.168.100.210"                               -- hwg_pwr IP Address
    local CommunityPassword = "private"                               -- SNMP Password
    local hwg_pwr = "hwg-pwr"                                         -- hwg_pwr Switch
    local DOMOTICZ_CPT_1 = "Compteur Eau Froide"                      -- DOMOTICZ CPT 1 Eau Froide
    local OID_CPT_1 = ".1.3.6.1.4.1.21796.4.6.1.3.1.6.1.1005"         -- DOMOTICZ CPT 1 Eau Froide
   
return {
    active = true,
    on = {
    timer = {'every minute'},
    devices = { hwg_pwr, DOMOTICZ_CPT_1 }
    },    
   -- on = { devices = { "your trigger device" }},
        
  logging =   { -- level    =   domoticz.LOG_INFO,                                             -- Seulement un niveau peut être actif; commenter les autres
                level    =   domoticz.LOG_ERROR,                                            -- Only one level can be active; comment others
                -- level    =   domoticz.LOG_DEBUG,
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker    =   "Damoclès Monitor v1.01 "      },
    
    execute = function(dz)
        local i = 0
        local results = {}
        local command = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..hwg_pwrIp..' '..OID_CPT_1
        dz.log('snmpget -c '..CommunityPassword..' -v1 -O qv '..hwg_pwrIp..' '..OID_CPT_1,dz.LOG_DEBUG)
        local handle = assert(io.popen(command))
        for line in handle:lines() do
        --for i, line in pairs(handle) do
        --   dz.log(line,dz.LOG_DEBUG)
        results[i] =  line
            i = i + 1
        end
        handle:close()
        if results[0] then
            dz.log("CPT1 : "..results[0],dz.LOG_DEBUG)
            dz.log("index CPT1 : "..dz.devices(DOMOTICZ_CPT_1).counter,dz.LOG_DEBUG) 
            if dz.devices(DOMOTICZ_CPT_1).counter < (results[0]/1000) then
                dz.devices(DOMOTICZ_CPT_1).updateCounter(results[0])
                dz.log("Maj compteur 1",dz.LOG_DEBUG)
                end
            end
     
        if results[0] then
                dz.log("Requete SNMP correcte ",dz.LOG_DEBUG)
                dz.devices(hwg_pwr).switchOn().checkFirst()
            else
                dz.log("Requete SNMP incorrecte ",dz.LOG_DEBUG)
                dz.devices(hwg_pwr).switchOff().checkFirst()
            end
            
    end
}
