--libaries 
local modem = require("modem")
local event = require("event")
--consts public
IP_PORT = 2048 -- the oc port used to send/recive ip packages NOT the t-/ucp port which is more the ethernetframe type
IP_VERSION = 4
ARP_PORT = 2054
ARP_OP_REQ
ARP_OP_ANSW
--consts private
local IPP_IHL = 20
local IPP_TOS = 0
local IPP_IDENTIFICATION = 0
local IPP_FLAGS = 0
local IPP_FRAGMENT_OFFSET = 1
local IPP_TTL = 1
--IP
function sendIpPackage(target, transport_protocol, data)
	local package = {version = 4, ihl = 0, tos = IPP_TOS, totalLenght = 0, identification = IPP_IDENTIFICATION, 
		flags = IPP_FLAGS, fragmentOffet = IPP_FRAGMENT_OFFSET, ttl = IPP_TTL, protocol = transport_protocol, 
		header_checksum = 0, source_address = getOwnIP(), target_address = target}
	modem.send(target, IP_PORT, package)
end
-- package management
function sendBroadcast(data)
	modem.broadcast(IP_PORT, data)
end

-- ARP
local ARP_TIMEOUT = 100 
local arp_cache = {}
function sendArpPackage(op, targetmac, targetip) 
	if targetmac = nil then targetmac = "ffff-ffffffff-ffff" end
	package = { hardware_adress_type = 1, protocol_adress_type = IP_PORT, operation = op, source_mac = modem.adress,
	source_ip = getOwnIp(), target_mac = targetmac, target_ip = targetip}
	if targetmac = "ffff-ffffffff-ffff" then 
		modem.broadcast(ARP_PORT, package)
	else
		modem.send(targetmac, ARP_PORT, package)
	end
end
function resolveIP(iptr)
	if arp_cache[iptr] ~= nil then
		if getTime() - arp_cache[iptr].time > ARP_TIMEOUT then
			arp_cache[iptr] = nil
		else
			return arp_cache[iptr].mac 
		end
	else
		sendBroadcast("R:" + iptr)
		-- wait for the answer
	end
end

function addToArpTable(iptr, mac)
	arp_cache[iptr] = { ["mac"] = mac, ["time"] = getTime() }
end

local function getTime()
	return 0
end