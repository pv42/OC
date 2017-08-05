--libs
ipv4 = require("libip")
-- const
local TCP_DATA_OFFSET = 0
local TCP_RESERVED = 0
local TCP_WINDOW = 0
local TCP_CHECKSUM = 12345
local TCP_URGENT_POINTER = 0
function sendTCPPackage( conn , data)
 	local package = { source_port = conn.sender_port, destination_port = conn.target_port, seq = conn.getNextSeq(),
 	 ack = 0, data_offset = TCP_DATA_OFFSET, reserved = TCP_RESERVED, flags = send_flags(), window = TCP_WINDOW,
 	 checksum = TCP_CHECKSUM, urget_pointer = TCP_URGENT_POINTER

	}
 	ipv4.sendIppackage(target_ip, ipv4.TOS_TCP, package)
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
