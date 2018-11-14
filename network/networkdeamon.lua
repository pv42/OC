_G.libip = require("libip")
_G.libtcp = require("libtcp")
local modem = require("component").modem
modem.open(libip.IP_PORT)
modem.open(libip.ARP_PORT)
function start() 
	while true do
		ipdeamon()
		senddeamon()
	end
end
function iprecivedeamon()
	suc, _, from, port, _, msg = event.pull(0.1,"modem_message")
	if suc == nil then return end
	if port == libip.IP_PORT then
		libip.handleIpPackage(from, msg)
	elseif port == libip.ARP_PORT then --ARP
		if message.hardware_adress_type == 1 and msg.protocol_adress_type == libip.IP_PORT then
			libip.addToArpTable(msg.sorce_ip, msg.source_mac)
			if msg.operation == libip.ARP_OP_REQ then
				--if is request answer it
				libip.sendArpPackage(libip.ARP_OP_ANSW, msg.source_mac, msg.source_ip)
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
function senddeamon() 
	libtcp.sendStep()
end

