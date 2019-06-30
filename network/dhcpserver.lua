libip = require("libip")
libudp = require("libudp")
libdhcp = require("libdhcp")


libip.config.local_ip = "192.168.0.1"

local address_table = {}

local function getFreeIp()
	for i in range(10,250) do
		local a = "192.168.0." .. i
		if(address_table[a] == nil) then
			address_table[a] = "offer"
			return a
		end 
	end
	return nil
end

local function handlePackage(package)
	if(package.operation == libdhcp.OP_DISCOVER) then
		local ip = getFreeIp()
		if(ip == nil) then return end
		libdhcp.dhcpoffer(ip)
	elseif(package.operation == libdhcp.OP_REQUEST) then
		if address_table[package.request] == "offer" then
			libdhcp.dhcppack(true)
			address_table[package.request] = "inuse"
		else 
			libdhcp.dhcppack(false)
		end
	else
	end
end

libudp.addReceiveHandler(libdhcp.SERVER_PORT, handlePackage)





