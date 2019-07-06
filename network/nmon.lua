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

local function frame_type_to_str(frame_type)
  if frame_type == libip.IP_PORT then 
    return "IP" 
  elseif frame_type == libip.ARP_PORT then 
    return "ARP"
  else 
    return tostring(frame_type) 
  end
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
    if type == "modem_message" then
      local frame_type = evt[4]

      if interactive then gpu.setForeground(0xCC2200) end
      io.write("[" .. os.date("%T") .. "] ")
      if interactive then gpu.setForeground(0x44CC00) end
      io.write(frame_type_to_str(frame_type) .. string.rep(" ", math.max(6 - #tostring(frame_type_to_str(frame_type)), 0) + 1))
      if interactive then gpu.setForeground(0xB0B00F) end
      io.write(string.sub(tostring(evt[3]),1,8) .. " ")
      if interactive then gpu.setForeground(0xFFFFFF) end
      if evt.n > 2 then
        for i = 5, evt.n do
          if i == 3 then
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