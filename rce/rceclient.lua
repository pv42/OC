local tcp = require("libtcp")
local libip = require("libip")
local PORT = 5793
print("rce-client") -- rci stands for remote code execution
print("enter remote ip")
local ip_str = io.read()
local ip = libip.StringtoIP(ip_str)
local conn = tcp.Connection:open(ip,PORT)
while true do
  print("connected")
  local cmd = io.read()
  conn:send(cmd)
  print(conn:receive())
end