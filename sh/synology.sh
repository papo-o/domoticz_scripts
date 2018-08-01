 #!/bin/bash
 #https://www.domoticz.com/wiki/NAS_Monitoring#Synology
 # Settings
 
 NASIP="192.168.100.250"          # NAS IP Address
 PASSWORD="monpassword"           # SNMP Password
 DOMO_IP="127.0.0.1"           # Domoticz IP Address
 DOMO_PORT="8080"              # Domoticz Port
 NAS_IDX="799"                 # NAS Switch IDX
 NAS_HD1_TEMP_IDX="800"        # NAS HD1 Temp IDX
 #NAS_HD2_TEMP_IDX="3"         # NAS HD2 Temp IDX
 NAS_CPU_IDX="801"             # NAS CPU IDX
 NAS_MEM_IDX="802"             # NAS MEM IDX
 NAS_HD_SPACE_PERC_IDX="803"   # NAS HD Space IDX in %
 NAS_HD_SPACE_IDX="804"        # NAS HD Space IDX in Go

 
 
 # Check if NAS in online 
 
  PINGTIME=`ping -c 1 -q $NASIP | awk -F"/" '{print $5}' | xargs`
 
 # echo $PINGTIME
if expr "$PINGTIME" \> 0 > /dev/null 2>&1 ; then
    curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=devices&rid=$NAS_IDX" | grep "Status" | grep "On" > /dev/null 2>&1

    if [ $? -eq 0 ] ; then
        # echo "NAS already ON"

        # Temperature HD1
        HDtemp1=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.6574.2.1.1.6.0`
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD1_TEMP_IDX&nvalue=0&svalue=$HDtemp1" > /dev/null 2>&1

        # Temperature HD2
        #HDtemp2=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.6574.2.1.1.6.1`
        # Send data
        #curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD2_TEMP_IDX&nvalue=0&svalue=$HDtemp2"

        # Free space volume in Go
        HDUnit=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.4.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDTotal=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.5.41` # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDUsed=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.6.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        #HDFree=$((($HDTotal - $HDUsed) * $HDUnit / 1024 / 1024 / 1024))

        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD_SPACE_IDX&nvalue=0&svalue=$HDFree" > /dev/null 2>&1

        # Free space volume in percent
        HDTotal=`snmpget -c $PASSWORD -v2c -O qv $NASIP .1.3.6.1.2.1.25.2.3.1.5.41` # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDUsed=`snmpget -c $PASSWORD -v2c -O qv $NASIP .1.3.6.1.2.1.25.2.3.1.6.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDFreePerc=$((($HDUsed * 100) / $HDTotal))
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD_SPACE_PERC_IDX&nvalue=0&svalue=$HDFreePerc" > /dev/null 2>&1

        # CPU utilisation
        CpuUser=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.11.9.0`
        CpuSystem=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.11.10.0`
        CpuUse=$(($CpuUser + $CpuSystem))
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_CPU_IDX&nvalue=0&svalue=$CpuUse" > /dev/null 2>&1

        # Free Memory Available in %
        MemAvailable=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.13.0`
        MemAvailableinMo=$(($MemAvailable / 1024))
        #MemUsepercent=$((($MemAvailableinMo * 100) / 1024))
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_MEM_IDX&nvalue=0&svalue=$MemAvailableinMo" > /dev/null 2>&1

    else
        # echo "NAS ON"
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$NAS_IDX&switchcmd=On" > /dev/null 2>&1

        # Temperature HD1
        HDtemp1=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.6574.2.1.1.6.0`
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD1_TEMP_IDX&nvalue=0&svalue=$HDtemp1" > /dev/null 2>&1

        # Temperature HD2
        HDtemp2=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.6574.2.1.1.6.1`
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD2_TEMP_IDX&nvalue=0&svalue=$HDtemp2" > /dev/null 2>&1

        # Free space volume in Go
        HDUnit=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.4.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDTotal=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.5.41` # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDUsed=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.6.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDFree=$((($HDTotal - $HDUsed) * $HDUnit / 1024 / 1024 / 1024))

        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD_SPACE_IDX&nvalue=0&svalue=$HDFree" > /dev/null 2>&1

        # Free space volume in percent
        HDTotal=`snmpget -c $PASSWORD -v2c -O qv $NASIP .1.3.6.1.2.1.25.2.3.1.5.41` # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDUsed=`snmpget -c $PASSWORD -v2c -O qv $NASIP .1.3.6.1.2.1.25.2.3.1.6.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDFreePerc=$((($HDUsed * 100) / $HDTotal))
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD_SPACE_PERC_IDX&nvalue=0&svalue=$HDFreePerc" > /dev/null 2>&1

        # CPU utilisation
        CpuUser=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.11.9.0`
        CpuSystem=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.11.10.0`
        CpuUse=$(($CpuUser + $CpuSystem))
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_CPU_IDX&nvalue=0&svalue=$CpuUse" > /dev/null 2>&1

        # Free Memory Available in %
        MemAvailable=`snmpget -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.13.0`
        MemAvailableinMo=$(($MemAvailable / 1024))
        #MemUsepercent=$((($MemAvailableinMo * 100) / 1024))
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_MEM_IDX&nvalue=0&svalue=$MemAvailableinMo" > /dev/null 2>&1

    fi

else
    curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=devices&rid=$NAS_IDX" | grep "Status" | grep "Off" > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        # echo "NAS already OFF"
        exit
    else
        # echo "NAS OFF"
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$NAS_IDX&switchcmd=Off" > /dev/null 2>&1
    fi
fi
