libip = require("libip")
libudp = require("libudp")
libdhcp = require("libdhcp")
log = require("log")

libip.config.local_ip = libip.StringtoIP("192.168.0.1")

local address_table = {}
local mac_table = {}

local DNS_SERVER = libip.StringtoIP("192.168.0.1")

local function getFreeIp()
	for i =10,250 do
		local a = libip.StringtoIP("192.168.0." .. i)
		if(address_table[a] == nil) then
			return a
		end 
	end
	return nil
end

local function handlePackage(package, ip, mac)
	if package.operation == libdhcp.OP_DISCOVER then
		local fip = nil 
    if mac_table[mac] then
      fip = mac_table[mac]
    else 
      fip = getFreeIp()
		  mac_table[mac] = fip
    end
    if fip == nil then return end
    address_table[fip] = "offer"
		libdhcp.dhcpoffer(fip, DNS_SERVER)
	elseif package.operation == libdhcp.OP_REQUEST  then
		if address_table[package.request] == "offer" and mac_table[mac] == package.request then
			libdhcp.dhcpacknowledge(true)
			address_table[package.request] = "inuse"
		else 
			libdhcp.dhcpacknowledge(false)
      log.w("DHCP ack denied a-t: " .. address_table[package.request])
		end
	else
	end
end

libudp.addReceiveHandler(libdhcp.SERVER_PORT, handlePackage)
log.i("DHCP server running")




