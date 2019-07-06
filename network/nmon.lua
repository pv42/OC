local event = require("event")
local tty = require("tty")
local libip = require("libip")
 
local args = {...}
local gpu = tty.gpu()
local interactive = io.output().tty
local color, isPal, evt
if interactive then
  color, isPal = gpu.getForeground()
end
io.write("Press 'Ctrl-C' to exit\n")
pcall(function()
  repeat
    if #args > 0 then
      evt = table.pack(event.pullMultiple("interrupted", table.unpack(args)))
    else
      evt = table.pack(event.pull())
    end
    if interactive then gpu.setForeground(0xCC2200) end
    io.write("[" .. os.date("%T") .. "] ")
    if interactive then gpu.setForeground(0x44CC00) end
    local type = tostring(evt[1]) 
    io.write(type .. string.rep(" ", math.max(10 - #tostring(evt[1]), 0) + 1))
    if interactive then gpu.setForeground(0xB0B00F) end
    io.write(tostring(evt[2]) .. string.rep(" ", 37 - #tostring(evt[2])))
    if interactive then gpu.setForeground(0xFFFFFF) end
    if evt.n > 2 then
      for i = 3, evt.n do
        if type == "modem_message" and i == 4 then
          if evt[i] == libip.IP_PORT then io.write("  IP") end
          if evt[i] == libip.ARP_PORT then io.write("  ARP") end
        else
          io.write("  " .. tostring(evt[i]))
        end
      end
    end
   
    io.write("\n")
  until evt[1] == "interrupted"
end)
if interactive then
  gpu.setForeground(color, isPal)
end