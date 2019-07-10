-- ifconfig.lua 

local com = require("component")
_, libip = pcall(require,"libip")
_, libdns = pcall(require,"libdns")

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
	print("IPv4 adress     time    physical adress")
	for ipv4, entry in pairs(libip.getArpTable()) do
      local ip_str = libip.IPtoString(ipv4)
			print(ip_str .. string.rep(" ", math.max(15 - #ip_str, 0) + 1) .. entry.time .. " " .. entry.mac)
	end
	if i == 0 then print("<the ARP-table is empty>") end
	print("")
	print("loaded used transport protocolls:")
	local first = true
	for k,v in pairs(libip.getHandlerList()) do 
		if first then
		 first = false
		else
		 io.write(", ")
		end
		io.write(k)
	end
	print("")
end

if libdns ~= nil then
  print("")
  print("DNS-Cache")
  print("Domain           IP")
  for name,ip in pairs(libdns.getDNSCache()) do
    local ip_str = libip.IPtoString(ip)
    print(name .. string.rep(" ", math.max(20 - #name, 0) + 1) .. ip_str)
  end
end
