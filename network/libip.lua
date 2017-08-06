--libaries
local modem = require("componet").modem
local event = require("event")
--consts public
IP_PORT = 2048 -- the oc port used to send/recive ip packages NOT the t-/ucp port which is more the ethernetframe type
IP_VERSION = 4
TRP_TCP = 5
TRP_UDP = 8
ARP_PORT = 2054
ARP_OP_REQ = 1
ARP_OP_ANSW = 2
MAC_BROADCAST = "ffff-ffffffff-ffff"
--consts private
local IPP_IHL = 20
local IPP_TOS = 0
local IPP_IDENTIFICATION = 0
local IPP_FLAGS = 0
local IPP_FRAGMENT_OFFSET = 0
local IPP_TTL = 1
-- network config
config = {}
config.local_ip = "127.0.0.1"


--IP
function sendIpPackage(target_ip, transport_protocol, _data)
	local target_mac = resolveIP(target_ip)
	if target_mac == nil then return false end
	local package = {version = 4, ihl = 0, tos = IPP_TOS, totalLenght = 0, identification = IPP_IDENTIFICATION, 
		flags = IPP_FLAGS, fragmentOffet = IPP_FRAGMENT_OFFSET, ttl = IPP_TTL, protocol = transport_protocol, 
		header_checksum = 0, source_address = getOwnIp(), target_address = target_ip, data = _data}
	modem.send(target, IP_PORT, package)
	return true
end
function handleIpPackage(sender, data)
	if data.version == 4 then
		if(data.tos ~= IPP_TOS) then
			if data.target_ip == getOwnIp() then
				if data.protocol ==  TRP_TCP  then libtcp.handleTCPPacke(data.data, sender) end 
			else 
				error("recived ipp for wrong adress, routing not active")
			end
		else
			error("invalid TOS, ip expected")
		end
	else
		error("invalid ip version")
	end
	-- body
end

-- package management
function sendBroadcast(data)
	modem.broadcast(IP_PORT, data)
end

function getOwnIp()
	return config.local_ip
end



-- ARP
local ARP_TIMEOUT = 100 
local arp_cache = {}

function sendArpPackage(op, targetmac, targetip) 
	if targetmac == nil then targetmac = MAC_BROADCAST end
	package = { hardware_adress_type = 1, protocol_adress_type = IP_PORT, operation = op, source_mac = modem.adress,
	source_ip = getOwnIp(), target_mac = targetmac, target_ip = targetip}
	if targetmac == "ffff-ffffffff-ffff" then 
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
		-- TODO wait for the answer
		os.sleep(5)
		return arp_cache[iptr].mac
	end
end

function addToArpTable(iptr, mac)
	arp_cache[iptr] = { ["mac"] = mac, ["time"] = getTime() }
end

function getArpTable()
	return arp_cache
end

local function getTime()
	return os.time()
end


modem.open(IP_PORT) -- open modem for ip
modem.open(ARP_PORT) -- open modem for arp

addToArpTable("127.0.0.1", modem.adress) --adding localhost to arptable