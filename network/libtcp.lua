print("loading tcp libary")
lib = {}
--libs
if libip== nil then error("no valid internet protocol active") end
-- const
local TCP_DATA_OFFSET = 0
local TCP_RESERVED = 0
local TCP_WINDOW = 0
local TCP_CHECKSUM = 35498
local TCP_URGENT_POINTER = 0
local TCP_ACK_TIMEOUT = 10
--locals
local ports = {}

function lib.handleTCPPackeage(tcpp, senderIP)
	if ports[tcpp.destination_port] == nil then error("recived tcpp on closed port " .. tcpp.destination_port) 
	else
		conn = ports[tcpp.destination_port]
		if tcpp.flags.ACK then
			conn.packageBuffer_s[tcpp.ack] = nil
		else	
			conn.packageBuffer_r[tcpp.seq] = tcpp
			lib.sendTCPPackage(conn, nil, ack_flags(), tcpp.seq)
		end
	end
end

function lib.openConnection(target_adress_, target_port_, local_port_)
	if local_port_ == nil then local_port_ = get_free_port() end
	conn = {packageBuffer_r={}, packageBuffer_s={}, packageSendTimeStep = {}, local_port = local_port_, remote_port = target_port_,
	 remote_adress = target_adress_ ,seq = random(), ack = 0}
	ports[target_port_] = conn -- marks port as used
	conn.getNextSeq = function()
		seq = seq + 1
		return seq
	end
	ocflags = flags()
	ocflags.SYN = true
	sendTCPPackage(conn, nil, ocflags)
	tcpp = reciveTCPPackage(conn)
	if tcpp.flags.SYN and tcpp.flags.ACK then
		sendTCPPackage(conn, nil, ack_flags(), tcpp.seq)
		print("connection to " .. target_adress_ .. ":" .. target_port_ .. " opened")
	else 
		error("connection refused")
	end
    return conn
end
local function get_free_port()
	port = 256
	while ports[port] ~= nil do 
		port = port + 1
	end
	return port
end
function awaitConnection(port)
	-- body
end
function random()
	return 19 -- wtf
end
function closeConnection(conn)
	-- body
	ports(conn.ta)
end
function reciveTCPPackage(conn, isSyn)
	if isSyn then
		while #conn.packageBuffer == 0 do
			os.sleep(0.05)
		end
		for k,v in pairs(packageBuffer) do
			conn.ack = k
			return v
		end
	else
		while(conn.packageBuffer[conn.ack + 1] == nil) do
			os.sleep(0.05)
		end
		return conn.packageBuffer[conn.ack + 1]
	end
end
function sendTCPPackage( conn , data, _flags, _ack)
	if _flags == nil then _flags = flags() end
	if _ack == nil then _ack = 0 end
 	local package = { source_port = conn.local_port, destination_port = conn.remote_port, seq = conn.getNextSeq(),
 	 ack = _ack, data_offset = TCP_DATA_OFFSET, reserved = TCP_RESERVED, flags = _flags, window = TCP_WINDOW,
 	 checksum = TCP_CHECKSUM, urget_pointer = TCP_URGENT_POINTER

	}
	conn.packageBuffer_s[package.seq] = package
 	
end

local function flags()
 	fl = {
 		ECE = false, -- no collision
 		CWR = false, -- no collision reaction
 		URG = false, -- not supported 
 		ACK = false, -- no ack
 		PSH = false, -- ???
 		RST = false, -- no reset
 		FIN = false, -- no teardown
 		SYN = false  -- no handshake
 	}
 	return fl
end

local function ack_flags()
	fl = flags()
	fl.ACK = true
	return fl
end

--called by the network deamon
function lib.sendStep() 
	for port, conn in pairs(ports) do 
		for seq, package in pairs(conn.packageBuffer_s) do
			if conn.packageSendTimeStep[seq] == nil or os.time() - conn.packageSendTimeStep[seq] > TCP_ACK_TIMEOUT then 	
				lipip.sendIpPackage(conn.remote_adress, lipip.TOS_TCP, package)
				conn.packageSendTimeStep[seq] = os.time()
			end
		end
	end
end 

return lib
