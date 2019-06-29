libip = require("libip")
libdhcp = require("libdhcp")
libudp = require("libudp")

libip.config.local_ip = "192.168.0.1"

libudp.addReceiveHandler(libudp.SERVER_PORT, handlediscover)

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
	if(package.operation = libdhcp.OP_DISCOVER)
		local ip = getFreeIp()
		if(if == nil) then return end
		libdhcp.dhcpoffer(ip)
	elseif(package.operation = libdhcp.OP_REQUEST)
		if package.
	else
	end
end





