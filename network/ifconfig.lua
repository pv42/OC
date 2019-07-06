-- ifconfig.lua 

local com = require("component")
_, libip = pcall(require,"libip")

print("ip-configuration")
if not com.isAvailable("modem") then
	print("No network hardware found")
	return
else
	local ipv4adr = "<ip libary not loaded>"
	if libip ~= nil then ipv4adr = libip.IPtoString(libip.getOwnIp()) end
	print("Modem:")
	print("Status: . . . . . " .. "?")
	print("physische Adresse:" .. com.modem.address)
	print("IPv4 Adresse: . . " .. ipv4adr)
end
if libip ~= nil then 
	print("")
	print("ARP-Table")
	print("IPv4 adress    | time   | physical adress")
	for ipv4, entry in pairs(libip.getArpTable()) do
      local ip_str = libip.IPtoString(ipv4)
			print(ip_str .. string.rep(" ", math.max(15 - #tostring(ip_str), 0)) .. "| " .. entry.time .. "| " .. entry.mac)
	end
	if i == 0 then print("<the ARP-table is empty>") end
end
