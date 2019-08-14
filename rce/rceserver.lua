local tcp = require("libtcp")
local PORT = 5793

print("running rce-server on port " .. PORT)
while true do
  local __conn = tcp.Connection:listen(PORT)
  print("connected")
  while true do
    local __data = conn.receive()
    if __data == "exit" then break end
    local __code, msg = load(__data)
    if not __code then
      __conn:send("{nil," .. msg .. "}")
    else
      local ret = table.pack(pcall(__code))
      __conn:send(serialization.serialize(ret))
    end
  end
  conn:close()
end