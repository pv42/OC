local libip = require("libip")
local libudp = require("libudp")
local os = require("os")

local libdhcp = {}

libdhcp.SERVER_PORT = 67
local CLIENT_PORT = 68
local TIMEOUT = 10

libdhcp.OP_DISCOVER = 1
local OP_OFFER = 2
libdhcp.OP_REQUEST = 3
local OP_PACK = 5
local OP_PACK = 6

local state = 0 -- 0-idle   1-wait for offer   2-wait for pack
local requested_ip = 0

local function dhcpdiscover()
	libudp.send(CLIENT_PORT, libdhcp.SERVER_PORT, libip.IP_BROADCAST, {operation = libdhcp.OP_DISCOVER})
end

function libdhcp.dhcpoffer(offer_ip)
	libudp.send(libdhcp.SERVER_PORT, CLIENT_PORT, libip.IP_BROADCAST, {operation = OP_OFFER, offer = offer_ip})
end

local function dhcprequest(server_ip, req_ip)
	print("sending dhcp req for " .. libip.IPtoString(req_ip) .. " to " .. libip.IPtoString(server_ip))
	libudp.send(CLIENT_PORT, libdhcp.SERVER_PORT, server_ip, {operation = libdhcp.OP_REQUEST, request = req_ip})
end

-- acknogledge (Boolean), if true send pack else send nak
function libdhcp.dhcpacknowledge(acknowledge)
	if(acknoledge) then 
		op = OP_PACK
	else
		op = OP_NAK
	end
	libudp.send(libdhcp.SERVER_PORT, CLIENT_PORT, libip.IP_BROADCAST, {operation = op})
end

local function handlepack(package)
	state = 0
	if(package.operation == OP_PACK) then
		state = 0
		libip.config.local_ip = requested_ip
	elseif (package.operation == OP_NAK) then
		error("dhcp request denied")
	else
		error("unexpected dhcp op type")
	end
end

local function handleoffer(package, sender_ip) 
	state = 2
	if(package.operation == OP_OFFER and package.offer ~= nil) then
		requested_ip = package.offer
		dhcprequest(sender_ip, package.offer)
		libudp.addReceiveHandler(CLIENT_PORT, handlepack)
	else
		error("unexpected dhcp op type")
	end
end

function libdhcp.requestIP()
	libudp.addReceiveHandler(CLIENT_PORT, handleoffer)
	dhcpdiscover()
	-- check for timeouts
	state = 1
	local i = 0
	while(i < TIMEOUT and state == 1) do
		os.sleep(1)
		i = i+1
	end
	if state == 1 then 
		error("dhcp server did not send an offer")
		libudp.addReceiveHandler(CLIENT_PORT,nil)
	end
	while(i < TIMEOUT and state == 2) do
		os.sleep(1)
		i = i+1
	end
	if state == 2 then 
		error("dhcp server did not acknogledge")
		libudp.addReceiveHandler(CLIENT_PORT,nil)
	end
end

return libdhcp