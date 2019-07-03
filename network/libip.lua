print("loading ip libary")
lib = {}
--libaries
local modem = require("component").modem
local event = require("event")
--consts public
lib.IP_PORT = 2048 -- the oc port used to send/recive ip packages NOT the t-/ucp port which is more the ethernetframe type
local IP_VERSION = 4
local TRP_TCP = 5
local TRP_UDP = 8
lib.ARP_PORT = 2054
local ARP_OP_REQ = 1
local ARP_OP_ANSW = 2
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
print("STEP 1 loading IPv4")
function lib.sendIpPackage(target_ip, transport_protocol, _data)
	local target_mac = resolveIP(target_ip)
	if target_mac == nil then return false end
	local package = {version = 4, ihl = 0, tos = IPP_TOS, totalLenght = 0, identification = IPP_IDENTIFICATION, 
		flags = IPP_FLAGS, fragmentOffet = IPP_FRAGMENT_OFFSET, ttl = IPP_TTL, protocol = transport_protocol, 
		header_checksum = 0, source_address = getOwnIp(), target_address = target_ip, data = _data}
	modem.send(target, lib.IP_PORT, package)
	return true
end

function lib.handleIpPackage(sender, data)
	if data.version == 4 then
		if(data.tos ~= IPP_TOS) then
			if data.target_ip == lib.getOwnIp() then
				if data.protocol ==  TRP_TCP  then 
					--todo ??
					if libtcp ~= nil then libtcp.handleTCPPacke(data.data, sender) end 
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

-- package management
function lib.sendBroadcast(data)
	modem.broadcast(lib.IP_PORT, data)
end

function lib.getOwnIp()
	return config.local_ip
end


print("STEP 2 loading ARP")
-- ARP
local ARP_TIMEOUT = 100 
local arp_cache = {}

function lib.sendArpPackage(op, targetmac, targetip) 
	if targetmac == nil then targetmac = MAC_BROADCAST end
	package = { hardware_adress_type = 1, protocol_adress_type = lib.IP_PORT, operation = op, source_mac = modem.adress,
	source_ip = getOwnIp(), target_mac = targetmac, target_ip = targetip}
	if targetmac == MAC_BROADCAST then 
		modem.broadcast(lib.ARP_PORT, package)
	else
		modem.send(targetmac, lib.ARP_PORT, package)
	end
end

local function ipheader(lenght,ident,protocol,dest)
    local iph = {}
    iph.version=4
    iph.ihl=5
    iph.tos=1
    iph.lenght=lenght
    iph.identification=ident
    iph.flags = 1 --DF
    iph.frag_offset = 0
    iph.ttl = 32
    iph.protocol = protocol
    iph.checksum = 0xffff
    iph.source=ip
    iph.destination=dest
    return iph
end


function lib.resolveIP(iptr)
	if arp_cache[iptr] ~= nil then
		if os.time() - arp_cache[iptr].time > ARP_TIMEOUT then
			arp_cache[iptr] = nil
		else
			return arp_cache[iptr].mac 
		end
	else
		lib.sendArpPackage(ARP_OP_REQ ,MAC_BROADCAST, iptr)
		-- TODO wait for the answer
		os.sleep(5)
		return arp_cache[iptr].mac
	end
end

function lib.addToArpTable(iptr, mac)
	arp_cache[iptr] = { ["mac"] = mac, ["time"] = os.time() }
end

function lib.getArpTable()
	return arp_cache
end

function lib.IPtoString(tip)
    if tip == nil then return 0 end
    return math.floor(tip/(256*256*256)).."."..(math.floor(tip/(256*256))%256).."."..(math.floor(tip/256)%256).."."..(tip%256)
end
function lib.StringtoIP(tip)
    if tip == nil then return 0 end
    local a = str_splitChar(tip,".")
    local lip =  tonumber(a[1])
    lip = lip * 256 + tonumber(a[2])
    lip = lip * 256 + tonumber(a[3])
    lip = lip * 256 + tonumber(a[4])
    return lip
end

function lib.dhcpGetIP()
    local oip = ip
    ip = nil
    local t = 0
    while (ip==nil and t < 10) do 
        if t > 0 then log.w("DHCP timed out") end
        modem.transmit(DHCP_CHANNEL,DHCP_ANSWER_CHANNEL,os.getComputerID())
        modem.open(DHCP_ANSWER_CHANNEL)
        parallel.waitForAny(dhcp_recive,wait_5)
        modem.close(DHCP_ANSWER_CHANNEL)
        t = t+1
    end
    if (ip == nil) then 
        log.e("DHCP couldn't get network configuration. Is a DHCP-Servrer running ?")
        ip = oip 
    end
    
end

lib.addToArpTable("127.0.0.1", modem.address) --adding localhost to arptable

print("ip libary loaded")

return lib