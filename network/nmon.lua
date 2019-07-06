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
    local type = tostring(evt[1]) 
    if type ~= "modem_message" then
      if interactive then gpu.setForeground(0xCC2200) end
      io.write("[" .. os.date("%T") .. "] ")
      if interactive then gpu.setForeground(0x44CC00) end
      io.write(type .. string.rep(" ", math.max(10 - #tostring(evt[1]), 0) + 1))
      if interactive then gpu.setForeground(0xB0B00F) end
      io.write(string.sub(tostring(evt[2]),1,8) .. " "))
      if interactive then gpu.setForeground(0xFFFFFF) end
      if evt.n > 2 then
        for i = 3, evt.n do
          if i == 4 then
            if evt[i] == libip.IP_PORT then 
              io.write("  IP") 
            elseif evt[i] == libip.ARP_PORT then 
              io.write("  ARP")
            else 
              io.write("  " .. tostring(evt[i])) 
            end
          elseif i == 3 then
            io.write("  " .. string.sub(tostring(evt[i]),1,8))
          else  
            io.write("  " .. tostring(evt[i]))
          end
        end
      end
      io.write("\n")
    end
  until evt[1] == "interrupted"
end)
if interactive then
  gpu.setForeground(color, isPal)
end