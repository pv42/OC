-- ifconfig.lua 

local com = require("component")
local shell = require("shell")
_, libip = pcall(require,"libip")
_, libdns = pcall(require,"libdns")
_, libtcp = pcall(require,"libtcp")

args, options = shell.parse(...)
print("ip-configuration")

if options.h then
  print(
[[Shows current network Status
ifconfig [-d | -h]
-d shows dns DNS-Cache
-h shows this help]])
  return
end

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
        if k == 6 then io.write("-TCP") end
		if k == 17 then io.write("-UDP") end
	end
	print("")
end

if libtcp ~= nil and libip ~= nil then --tcp w/o ip does not make a lot of sense
    print("")
    print("TCP (experimental)")
    print("local remote      state")
    for _,c in pairs(listConnection) do 
        io.write(c.local_port)
        io.write(string.rep(" ", math.max(6 - #tostring(c.local_port), 0)))
        io.write(c.remote_address .. ":" .. c.remote_port)
        io.write(string.rep(" ", math.max(19 - #tostring(c.remote_port) - 1 - #libip.IPtoString(c.remote_address), 0)))
        io.write(c.state)
    end
  end
end

if libudp ~= nil then
  print("")
  print("UDP-Ports    Name")
  for k,v in pairs(libudp.getHandlerList()) do 
    io.write(k)
    io.write(string.rep(" ", math.max(13 - #tostring(k), 0)))
    if k == 67 then io.write("DHCP-Server\n") 
    elseif k == 68 then io.write("DHCP-Client\n") 
    elseif k == 53 then io.write("DNS\n") 
    elseif k == 97 then io.write("wdb\n") 
    else io.write("?\n")
    end
  end
end

if libdns ~= nil and options.d then
  print("")
  print("DNS-Cache")
  print("Domain                IP")
  for name,ip in pairs(libdns.getDNSCache()) do
    local ip_str = libip.IPtoString(ip)
    print(name .. string.rep(" ", math.max(20 - #name, 0) + 1) .. ip_str)
  end
end
