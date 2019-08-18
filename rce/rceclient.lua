local tcp = require("libtcp")
local libip = require("libip")
local PORT = 5793
print("rce-client") -- rci stands for remote code execution
print("enter remote ip")
local ip_str = io.read()
local ip = libip.StringtoIP(ip_str)
repeat
  local suc, conn = pcall(tcp.Connection.open,nil,ip,PORT) -- tcp.Connection:open(ip,PORT)
  if not suc then print("Connection could not be established:" .. conn .. " retrying ..") end
  while suc do
    print("connected")
    local cmd = io.read()
    conn:send(cmd)
    print(conn:receive())
  end
until(suc)
