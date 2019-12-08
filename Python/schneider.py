#domoticz settings

domoticz_host           = '127.0.0.1'    # Url domoticz
domoticz_port           = '8080'            # port
domoticz_url            = 'json.htm'        # Ne pas modifier
script_version			    = '1.0'

compteurs = [[1448,150], [1449,151], [2975,152], [2976,153]]

from pymodbus.client.sync import ModbusTcpClient as ModbusClient
import urllib.request as urllib2
from pymodbus.constants import Endian
from pymodbus.payload import BinaryPayloadDecoder
client = ModbusClient('192.168.1.78', port=502)
client.connect()
def volt(slave):
    return client.read_holding_registers(3027, 2, unit=slave)
    
def ampere(slave):
    return client.read_holding_registers(2999, 2, unit=slave)
    
def puissance(slave):
    return client.read_holding_registers(3053, 2, unit=slave)
    
def cosphi(slave):
    return client.read_holding_registers(3083, 2, unit=slave)    
    
def energie(slave):
    return client.read_holding_registers(3203, 8, unit=slave)
    
def float(Result, Round):
    decoder = BinaryPayloadDecoder.fromRegisters(Result.registers, byteorder=Endian.Big, wordorder=Endian.Big)
    return round(decoder.decode_32bit_float() ,Round) 
    
def INT64(Result, Round):
    decoder = BinaryPayloadDecoder.fromRegisters(Result.registers, byteorder=Endian.Big, wordorder=Endian.Big)
    return round(decoder.decode_64bit_int() ,Round)

client.close()


for i in range(len(compteurs)):
	url = "http://" + domoticz_host + ":" + domoticz_port + "/" + domoticz_url + "?type=command&param=udevice&idx=" + str(compteurs[i][0]) + "&nvalue=0&svalue=" + str(float(puissance(compteurs[i][1]), 0)) + ";" + str(INT64(energie(compteurs[i][1]), 0))
	urllib2.urlopen(url , timeout = 5)    
	# print(url)
	# print("=" * 70)
	# print("compteur ")
	# print(compteurs[i][1])	
	# print("-" * 60)
	# print("volts V ")
	# print(float(volt(compteurs[i][1]), 1))
	# print("-" * 60)
	# print("ampere(s) A ")
	# print(float(ampere(compteurs[i][1]), 2))
	# print("-" * 60)
	# print("puissance W ")
	# print(float(puissance(compteurs[i][1]), 0))
	# print("-" * 60)
	# print("facteur de puissance ")
	# print(float(cosphi(compteurs[i][1]), 2))
	# print("-" * 60)
	# print("energie Wh ")
	# print(INT64(energie(compteurs[i][1]), 0))
