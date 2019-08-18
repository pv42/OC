-- libtcp by pv42

--imports
local log = require("log")
local libip = require("libip")
local serialization = require("serialization")
local math = require("math")

log.i("loading tcp libary")
if libip == nil then
  error("no valid internet protocol active")
end
libtcp = {}

-- const
local TCP_DATA_OFFSET = 0
local TCP_RESERVED = 0
local TCP_WINDOW = 0
local TCP_CHECKSUM = 35498
local TCP_URGENT_POINTER = 0
local TCP_ACK_TIMEOUT = 10
local TCP_MAX_SEND_TRIES = 3
-- connection states
local C_CLOSED = 0
local C_LISTEN = 1
local C_SYN_RCV = 2
local C_SYN_SENT = 3
local C_ESTABLISHED = 4
--
local TOS_TCP = 6
--locals
local ports = {}
--[[
 ports -> list of Sockets (tables with metatable Socket)
  socket -> port (numerical id)
         -> isOpen (boolean)
         -> list of connections (tables with metatable Connection)
]]


local function get_free_port()
  port = 512
  while ports[port] ~= nil do
    port = port + 1
  end
  return port
end

local function random()
  return math.floor(math.random() * 65535)
end

--flags
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


libtcp.Socket = {}
libtcp.Socket.__index = libtcp.Socket

function litcp.Socket:open(port)
  checkArg(1, port, "number")
  if ports[port] ~= nil then
    error("port is already used")
  end
  local sock = { port = port, isOpen = true, connections = {} }
  ports[port] = sock
  setmetatable(sock, libtcp.Socket)
  return sock
end

function libtcp.Socket:close()
  if ports[self.port] ~= self then
    error("port list mismatch")
  end
  if not self.isOpen then
    error("port already closed")
  end
  ports[self.port] = nil
  self.isOpen = false
end

libtcp.Connection = {}
libtcp.Connection.__index = libtcp.Connection


---listen waits for a connection
---@return table metatable: Connection
---@public
function libtcp.Socket:listen()
  local conn = { packageBuffer_r = {}, packageBuffer_s = {}, packageSendTimeStep = {},
                 local_port = port, remote_port = nil, remote_address = nil, -- not set yet
                 seq = random(), ack = 0, state = C_LISTEN }
  setmetatable(conn, libtcp.Connection)
  table.insert(self.connections, conn)
  local package, address = conn:mReceivePackage(0, true)
  if not package then
    error("could not establish connection")
  end
  conn.remote_port = package.destination_port
  conn.remote_address = address
  conn:send(nil, syn_flags(true))
  print("TCP:established")
  return conn
end

function libtcp.Connection:open(target_address, target_port, local_port)
  if local_port == nil then
    local_port = get_free_port()
  end
  if ports[local_port] ~= nil then
    error("port is already used")
  end
  ports[local_port] = conn -- marks port as used
  local conn = { packageBuffer_r = {}, packageBuffer_s = {},
                 local_port = local_port, remote_port = target_port,
                 remote_address = target_address, seq = random(), ack = 0, state = C_CLOSED }
  setmetatable(conn, libtcp.Connection)
  -- syn
  conn:send(nil, syn_flags())
  conn.state = C_SYN_SENT
  -- wait for syn ack
  tcpp = conn:mReceivePackage(10, true)
  if tcpp == nil then
    error("Connection could not be opened: Server did not respond")
  end
  if tcpp.flags.SYN and tcpp.flags.ACK then
    conn:send(nil, flags(true))
    conn.state = C_ESTABLISHED
    print("connection to " .. target_address .. ":" .. target_port .. " opened")
  else
    error("connection refused")
  end
  table.insert(connections, conn)
  return conn
end

---@private
function libtcp.Connection:mGetNextSeq()
  self.seq = self.seq + 1
  return self.seq
end

---receive waits for receiving of a package
---@param timeout number timeout to receive a package or 0 if no timeout
---@return table tcp package's received content
---@public
function libtcp.Connection:receive(timeout)
  return self:mReceivePackage(timeout).data
end

---mReceivePackage waits for the receiving of a package and returns it
---@param timeout number timeout to receive a package or 0 if no timeout
---@param isSyn boolean if true waits for a syn package
---@private
function libtcp.Connection:mReceivePackage(timeout, isSyn)
  if isSyn then
    local i = 0
    while #self.packageBuffer_r == 0 do
      os.sleep(0.05)
      i = i + 1
      if timeout > 0 and i >= timeout * 20 then
        return
      end
    end
    for ack, package in pairs(self.packageBuffer_r) do
      self.ack = ack
      return package
    end
  else
    while self.packageBuffer_r[self.ack + 1] == nil do
      os.sleep(0.05)
    end
    return conn.packageBuffer[self.ack + 1]
  end
end

function libtcp.Connection:send(data, _flags)
  if _flags == nil then
    _flags = flags()
  end
  if _ack == nil then
    _ack = 0
  end
  local package = { source_port = self.local_port, destination_port = self.remote_port, seq = self:mGetNextSeq(),
                    ack = _ack, data_offset = TCP_DATA_OFFSET, reserved = TCP_RESERVED, flags = _flags, window = TCP_WINDOW,
                    checksum = TCP_CHECKSUM, urget_pointer = TCP_URGENT_POINTER, data = data
  }
  self.packageBuffer_s[package.seq] = { package = package, send_try = 0, time = os.time() }
end

function libtcp.Connection:close()

  -- todo teardown
  ports[self.local_port] = nil
  connections.remove(self)
end


-- end class

function libtcp.handleTCPPackeage(tcpp, senderAddress)
  if ports[tcpp.destination_port] == nil or not ports[tcpp.destination_port].isOpen then
    error("recived tcpp on closed port " .. tcpp.destination_port)
  else
    local conns = ports[tcpp.destination_port].connections
    local conn
    for _, c in pairs(conns) do
      if (c.remote_address == senderAddress and c.remote_port == tcpp.source_port) or (c.remote_address == nil and c.remote_port == nil and c.state == C_LISTEN) then
        conn = c
        break
      end
    end
    if tcpp.flags.ACK then
      conn.packageBuffer_s[tcpp.ack] = nil -- package acknowleged, must not be send again
    end
    if not tcpp.flags.ACK or tcpp.flags.SYN then
      --syn/ack or normal
      conn.packageBuffer_r[tcpp.seq] = tcpp -- put in rec buffer and acknoledge
      lib.sendTCPPackage(conn, nil, ack_flags(), tcpp.seq)
    end
  end
end

--called by the network deamon
function libtcp.sendStep()
  for _, conn in pairs(connections) do
    if conn.state ~= C_CLOSED then
      for seq, data in pairs(conn.packageBuffer_s) do
        if data.time - os.time() > TCP_ACK_TIMEOUT then
          if data.send_try >= TCP_MAX_SEND_TRIES then
            conn.state = C_CLOSED -- too many timeouts
            log.e("connection closed due too many timeouts")
          else
            lipip.sendIpPackage(conn.remote_adress, TOS_TCP, data.package)
            data.send_try = data.send_try + 1 -- might not work
          end
        end
      end
    end
  end
end

return libtcp
