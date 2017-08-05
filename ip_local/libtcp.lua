--libs
libip = require("libip")
-- const
local TCP_DATA_OFFSET = 0
local TCP_RESERVED = 0
local TCP_WINDOW = 0
local TCP_CHECKSUM = 12345
local TCP_URGENT_POINTER = 0
--locals
local ports = {}


function openConnection(sender_port_, target_adress_, target_port_)
	conn = {packageBuffer={},sender_port = sender_port_, target_port = target_port_, target_adress = target_adress_ ,seq = random()}
	lipip.sendIpPackage(target_adress, lipip.TOS_TCP, package)
end
function random()
	return 19
end
function closeConnection(conn)
	-- body
end
function reciveTCPPackage(conn)
	-- body
end
function sendTCPPackage( conn , data)
 	local package = { source_port = conn.sender_port, destination_port = conn.target_port, seq = conn.getNextSeq(),
 	 ack = 0, data_offset = TCP_DATA_OFFSET, reserved = TCP_RESERVED, flags = send_flags(), window = TCP_WINDOW,
 	 checksum = TCP_CHECKSUM, urget_pointer = TCP_URGENT_POINTER

	}
 	lipip.sendIpPackage(conn.target_adress, lipip.TOS_TCP, package)
end

local function send_flags()
 	fl = {
 		ECE = false -- no collision
 		CWR = false -- no collision reaction
 		URG = false -- not supported 
 		ACK = false -- no ack
 		PSH = false -- ???
 		RST = false -- no reset
 		FIN = false -- no teardown
 		SYN = false -- no handshake
 	}
 	return fl
end
