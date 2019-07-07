--libs
local log = require("log")
local libip = require("libip") 
local serialization = require("serialization")
log.i("loading tcp libary")
libtcp = {}
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


local function get_free_port()
  port = 512
  while ports[port] ~= nil do 
    port = port + 1
  end
  return port
end

local function random()
  return 19 -- wtf, not even a fair dice roll
end


local function flags(ack)
  fl = {
    ECE = false, -- no collision
    CWR = false, -- no collision reaction
    URG = false, -- not supported 
    ACK = ack, -- no ack
    PSH = false, -- ???
    RST = false, -- no reset
    FIN = false, -- no teardown
    SYN = false  -- no handshake
  }
  return fl
end

local function syn_flags(ack)
  fl = flags(ack)
  fl.SYN = true
  return fl
end

local function fin_flags(ack)
  fl = flags(ack)
  fl.FIN = true
  return fl
end 

--class connection

libtcp.Connection = {}
libtcp.Connection.__index = libtcp.Connection

function libtcp.Connection:open(target_adress_, target_port_, local_port_)
  if local_port_ == nil then local_port_ = get_free_port() end
  local conn = {packageBuffer_r={}, packageBuffer_s={}, packageSendTimeStep = {},
    local_port = local_port_, remote_port = target_port_,
    remote_adress = target_adress_ ,seq = random(), ack = 0}
  setmetatable(conn,libtcp.Connection)
  ports[local_port_] = conn -- marks port as used
  ocflags = flags()
  ocflags.SYN = true
  sendTCPPackage(conn, nil, ocflags)
  tcpp = conn:recivePackage()
  if tcpp.flags.SYN and tcpp.flags.ACK then
    sendTCPPackage(conn, nil, ack_flags(), tcpp.seq)
    print("connection to " .. target_adress_ .. ":" .. target_port_ .. " opened")
  else 
    error("connection refused")
  end
    return conn
end


function libtcp.Connection:await(port)
  if ports[port] ~= nil then error("port is already used") end
  local conn = {packageBuffer_r={}, packageBuffer_s={}, packageSendTimeStep = {},
    local_port = port, remote_port =nil,remote_adress = nil, -- not set yet
    seq = random(), ack = 0}
  setmetatable(conn,libtcp.Connection)
  ports[port] = conn
  return conn
end

function libtcp.Connection:getNextSeq()
  self.seq = self.seq + 1
  return self.seq
end

function libtcp.Connection:recivePackage(isSyn)
  if isSyn then
    while #self.packageBuffer_r == 0 do
      os.sleep(0.05)
    end
    for k,v in pairs(packageBuffer) do
      self.ack = k
      return v
    end
  else
    while self.packageBuffer_r[conn.ack + 1] == nil) do
      os.sleep(0.05)
    end
    return conn.packageBuffer[conn.ack + 1]
  end
end

function libtcp.Connection:sendPackage(data, _flags)
  if _flags == nil then _flags = flags() end
  if _ack == nil then _ack = 0 end
  local package = { source_port = conn.local_port, destination_port = conn.remote_port, seq = self.getNextSeq(),
   ack = _ack, data_offset = TCP_DATA_OFFSET, reserved = TCP_RESERVED, flags = _flags, window = TCP_WINDOW,
   checksum = TCP_CHECKSUM, urget_pointer = TCP_URGENT_POINTER

  }
  self.packageBuffer_s[package.seq] = package
end


function libtcp.Connection:close()
  -- todo teardown
  ports[self.local_port] = nil
end


-- end class

function libtcp.handleTCPPackeage(tcpps, senderIP)
	local tcpp = serialization.serialize(tcpps)
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

--called by the network deamon
function libtcp.sendStep() 
	for port, conn in pairs(ports) do 
		for seq, package in pairs(conn.packageBuffer_s) do
			if conn.packageSendTimeStep[seq] == nil or os.time() - conn.packageSendTimeStep[seq] > TCP_ACK_TIMEOUT then 	
				lipip.sendIpPackage(conn.remote_adress, lipip.TOS_TCP, package)
				conn.packageSendTimeStep[seq] = os.time()
			end
		end
	end
end 

return libtcp
