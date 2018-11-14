-- ifconfig.lua 

local com = require("component")

print("ip-configuration")
if not com.isAvailable("modem") then
	print("No network hardware found")
	return
else
	local ipv4adr = "<ip libary not loaded>"
	if libip ~= nil then ipv4adr = libip.getOwnIp() end
	print("Modem:")
	print("Status: . . . . . " .. "?")
	print("physische Adresse:" .. com.modem.address)
	print("IPv4 Adresse: . . " .. ipv4adr)
end
if libip ~= nil then 
	print("")
	print("ARP-Table")

	 
	print("IPv4 adress  | time   | physical adress")
	for ipv4, entry in pairs(libip.getArpTable()) do 
			print( ipv4 .. "| " .. entry.time .. "| " .. entry.mac)
	end
	if i == 0 then print("<the ARP-table is empty>") end
end