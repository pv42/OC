if(type(_G.libip) == "table") then 
	print("ip libary is already loaded")
	return _G.libip
end

print("loading ip libary")
--libaries
local modem = require("component").modem
local event = require("event")
local serialization = require("serialization")
--consts public
local libip = {}
libip.MAC_BROADCAST = "ffff-ffffffff-ffff" -- mac broadcast address
libip.IP_BROADCAST = "255.255.255.255"
--consts private
local IP_VERSION = 4
--local TRP_TCP = 6 -- tcp package type
--local TRP_UDP = 17 -- upd package type
local IPP_IHL = 20
local IPP_TOS = 0
local IPP_IDENTIFICATION = 0
local IPP_FLAGS = 0
local IPP_FRAGMENT_OFFSET = 0
local IPP_TTL = 1
libip.IP_PORT = 2048 -- the oc port used to send/recive ip packages NOT the t-/ucp port which is more the ethernetframe type
libip.ARP_PORT = 2054 -- arp oc port
local ARP_OP_REQ = 1 -- arp request operation code
local ARP_OP_ANSW = 2 -- arp answer operation code
local ARP_REQ_TIMEOUT = 5 -- arp request timeout, after this time without an answer an ip is deamed unresolvable
-- network config
libip.config = {}
libip.config.local_ip = "127.0.0.1"


local receiveHandlers = {}

--IP
print("STEP 1 loading IPv4")

local function handleIpPackage(sender, package)
	if package.version == 4 then
		if(package.tos == IPP_TOS) then
			if package.target_ip == libip.getOwnIp() or package.target_ip == IP_BROADCAST then
				if(receiveHandlers[package.protocol] ~= nil) then
					receiveHandlers[package.protocol](package.data, package.source_address)
				else
					error("no handler for protocol " .. package.protocol)
				end 
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



print("STEP 2 loading ARP")
-- ARP
local ARP_TIMEOUT = 100 
local arp_cache = {}

local function sendArpPackage(op, targetmac, targetip) 
	if targetmac == nil then targetmac = MAC_BROADCAST end
	package = { hardware_adress_type = 1, protocol_adress_type = libip.IP_PORT, operation = op, source_mac = modem.adress,
	source_ip = libip.getOwnIp(), target_mac = targetmac, target_ip = targetip}
	if targetmac == MAC_BARP_POROADCAST then 
		modem.broadcast(ARP_PORT, serialization.serialize(package))
	else
		modem.send(targetmac, ARP_PORT, serialization.serialize(package))
	end
end

-- returns the physical address of a given ip
local function resolveIP(iptr)
	if(iptr == nil) then error("tried to resolve nil ip") end
	if(iptr == libip.IP_BROADCAST) then return libip.MAC_BROADCAST end
	if arp_cache[iptr] ~= nil then
		if os.time() - arp_cache[iptr].time > ARP_TIMEOUT then
			arp_cache[iptr] = nil
		else
			return arp_cache[iptr].mac 
		end
	end
	sendArpPackage(ARP_OP_REQ ,MAC_BROADCAST, iptr)
	wait_time = 0
    while arp_cache[iptr] == nil do -- wait for answer
        if wait_time > ARP_REQ_TIMEOUT then
            print("could not resolve ip:" .. iptr)
            return nil
        end
        os.sleep(0.5)
        wait_time = wait_time + 0.5
	end
    return arp_cache[iptr].mac
end

local function addToArpTable(iptr, mac)
	arp_cache[iptr] = { ["mac"] = mac, ["time"] = os.time() }
end



print("STEP 3 loading IP (2)")

--public
function libip.sendIpPackage(target_ip, transport_protocol, _data)
	local target_mac = resolveIP(target_ip)
	if target_mac == nil then return false end
	local package = {version = 4, ihl = 0, tos = IPP_TOS, totalLenght = 0, identification = IPP_IDENTIFICATION, 
		flags = IPP_FLAGS, fragmentOffet = IPP_FRAGMENT_OFFSET, ttl = IPP_TTL, protocol = transport_protocol, 
		header_checksum = 0, source_address = libip.getOwnIp(), target_address = target_ip, data = _data}
	if(target_mac == libip.MAC_BROADCAST) then
		modem.broadcast(libip.IP_PORT, serialization.serialize(package))
	else
		modem.send(target_mac, libip.IP_PORT, serialization.serialize(package))
	end
	return true
end


-- package management
--public
function libip.sendBroadcast(data)
	modem.broadcast(libip.IP_PORT, data)
end

--public
function libip.getOwnIp()
	return libip.config.local_ip
end


print("STEP 4 loading ARP (2)")

--public
function libip.getArpTable()
	return arp_cache
end

function libip.addReceiveHandler(protocol_id, func)
	receiveHandlers[protocol_id] = func
end

addToArpTable("127.0.0.1", modem.address) --adding localhost to arptable
addToArpTable(libip.IP_BROADCAST, libip.MAC_BROADCAST)
-- deamons
-- public 

local function ipreceivedeamon()
	suc, _, from, port, _, msg = event.pull(0.1,"modem_message")
	if suc == nil then return end
	local msgu = serialization.unserialize(msg)
	if port == libip.IP_PORT then
		handleIpPackage(from, msgu)
	elseif port == ARP_PORT then --ARP
		if msgu.hardware_adress_type == 1 and msgu.protocol_adress_type == libip.IP_PORT then
			addToArpTable(msgu.sorce_ip, msgu.source_mac)
			if msgu.operation == ARP_OP_REQ then
				--if is request answer it
				sendArpPackage(ARP_OP_ANSW, msgu.source_mac, msgu.source_ip)
			end
		else
			--not matching
			error("Invalid ARP request")
		end
	else
		--unknown "ethernet" frame type
		error("Invalid network frame type")
	end
end
local function senddeamon() 
	libtcp.sendStep()
end

function libip.run() 
	print("network deamon running")
	while true do
		ipreceivedeamon()
		senddeamon()
	end
end


print("ip libary loaded")
return libip