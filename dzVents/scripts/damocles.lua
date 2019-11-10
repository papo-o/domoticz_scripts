--[[
name : damocles.lua
auteur : papoo
creation : 10/11/2018
mise à  jour : 10/11/2019

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

    local DAMOCLESIp = "192.168.1.20"                                 -- DAMOCLES IP Address
    local CommunityPassword = "private"                               -- SNMP Password
    local DAMOCLES = "Damocles"                                       -- DAMOCLES Switch

    local DZ_CPT_2 = "Compteur Eau Chaude"                      -- DOMOTICZ CPT 2 Eau Chaude
    local DZ_CPT_3 = "Compteur Gaz"                             -- DOMOTICZ CPT 3 gaz
    local DZ_CPT_4 = nil --"Compteur Prises"                          -- DOMOTICZ CPT 4 Prises
    local DZ_CPT_5 = nil -- "Compteur Lumières"                        -- DOMOTICZ CPT 5 Lumiere
    local DZ_CPT_6 = "Compteur Technique"                       -- DOMOTICZ CPT 6 Technique
    local OID_CPT_2 = ".1.3.6.1.4.1.21796.3.4.1.1.6.2"                -- DOMOTICZ CPT 2 Eau Chaude
    local OID_CPT_3 = ".1.3.6.1.4.1.21796.3.4.1.1.6.3"                -- DOMOTICZ CPT 3 gaz
    local OID_CPT_4 = ".1.3.6.1.4.1.21796.3.4.1.1.6.4"                -- DOMOTICZ CPT 4 Prises
    local OID_CPT_5 = ".1.3.6.1.4.1.21796.3.4.1.1.6.5"                -- DOMOTICZ CPT 5 Lumiere
    local OID_CPT_6 = ".1.3.6.1.4.1.21796.3.4.1.1.6.6"                -- DOMOTICZ CPT 6 Technique


return {
    active = true,
    on = {
    timer = {'every minute'}
    },

	logging =   { level    =   domoticz.LOG_DEBUG,                                             -- Seulement un niveau peut être actif; commenter les autres
				-- level    =   domoticz.LOG_ERROR,                                            -- Only one level can be active; comment others
				-- level    =   domoticz.LOG_INFO,
				-- level    =   domoticz.LOG_MODULE_EXEC_INFO,
				marker    =   "Damoclès Monitor v1.23 "      },

    execute = function(dz)

        local function logWrite(str,level)
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end

        local i = 0
        local results = {}
        local command = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..DAMOCLESIp..' '..OID_CPT_2..' '..OID_CPT_3..' '..OID_CPT_4..' '..OID_CPT_5..' '..OID_CPT_6
        logWrite(command)
        local handle = assert(io.popen(command))
        for line in handle:lines() do
        --   logWrite(line)
            results[i] =  line
            i = i + 1
        end
        handle:close()
        -- if results[0] then
            -- logWrite("CPT2 : "..results[0])
            -- logWrite("index CPT2 : "..dz.devices(DZ_CPT_2).counter)
            -- if dz.devices(DZ_CPT_2).counter < (results[0]/1000) then
                -- dz.devices(DZ_CPT_2).updateCounter(results[0])
                -- logWrite("Maj compteur 2")
                -- elseif dz.devices(DZ_CPT_2).counter > (results[0]/1000) then
                    -- logWrite("Maj compteur 2 sur damoclès")
                    -- local write_cpt1 = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..OID_CPT_2..' i '..DZ_CPT_2
                    -- local handle1 = assert(io.popen(write_cpt1))
                    -- handle1:close()
                -- end
            -- end
        if results[1] then
            logWrite("CPT3 : "..results[1])
            logWrite("index CPT3 : "..dz.devices(DZ_CPT_3).counter)
            if dz.devices(DZ_CPT_3).counter < (results[1]/100) then
                dz.devices(DZ_CPT_3).updateCounter(results[1]*10)
                logWrite("Maj compteur 3")
            elseif dz.devices(DZ_CPT_3).counter > (results[1]/100) then
                logWrite("Maj compteur 3 sur damoclès")
                local write_cpt3 = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..OID_CPT_3..' i '..tonumber(dz.devices(DZ_CPT_3).counter)/10
                local handle1 = assert(io.popen(write_cpt3))
                handle1:close()
                end
            end
        -- if results[2] and dz.devices(DZ_CPT_4) ~= nil then
            -- logWrite("CPT4 : "..results[2])
            -- logWrite("index CPT4 : "..dz.devices(DZ_CPT_4).counter)
            -- if dz.devices(DZ_CPT_4).counter < (results[2]/1000) then
                -- dz.devices(DZ_CPT_4).updateCounter(results[2])
                -- logWrite("Maj compteur 4")
                -- elseif dz.devices(DZ_CPT_4).counter > (results[2]/1000) then
                    -- logWrite("Maj compteur 4 sur damoclès")
                    -- local write_cpt1 = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..OID_CPT_4..' i '..DZ_CPT_4
                    -- local handle1 = assert(io.popen(write_cpt1))
                    -- handle1:close()
                -- end
            -- end
        -- if results[3] and dz.devices(DZ_CPT_5) ~= nil then
            -- logWrite("CPT5 : "..results[3])
            -- logWrite("index CPT5 : "..dz.devices(DZ_CPT_5).counter)
            -- if dz.devices(DZ_CPT_5).counter < (results[3]/1000) then
                -- dz.devices(DZ_CPT_5).updateCounter(results[3])
                -- logWrite("Maj compteur 5")
                -- elseif dz.devices(DZ_CPT_5).counter > (results[3]/1000) then
                    -- logWrite("Maj compteur 5 sur damoclès")
                    -- local write_cpt5 = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..OID_CPT_5..' i '..DZ_CPT_5
                    -- local handle1 = assert(io.popen(write_cpt5))
                    -- handle1:close()
                -- end
            -- end
        if results[4] then
            logWrite("CPT6 : "..results[4])
            logWrite("index CPT6 : "..dz.devices(DZ_CPT_6).counter)
            if dz.devices(DZ_CPT_6).counter < (results[4]/1000) then
                dz.devices(DZ_CPT_6).updateCounter(results[4])
                logWrite("Maj compteur 6")
                elseif dz.devices(DZ_CPT_6).counter > (results[4]/1000) then
                    logWrite("Maj compteur 6 sur damoclès")
                    local write_cpt6 = 'snmpget -c '..CommunityPassword..' -v1 -O qv '..OID_CPT_6..' i '..tonumber(dz.devices(DZ_CPT_6).counter)
					logWrite("write CPT6 : "..tostring(write_cpt6))
                    local handle1 = assert(io.popen(write_cpt6))
                    handle1:close()
                end
            end


        if results[0] and results[1] and results[2] and results[3] and results[4] then
                logWrite("Requete SNMP correcte ")
                dz.devices(DAMOCLES).switchOn().checkFirst()
            else
                logWrite("Requete SNMP incorrecte ")
                dz.devices(DAMOCLES).switchOff().checkFirst()
            end

    end
}
