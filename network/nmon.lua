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

io.write("NMon 1.0.03\n")
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
      local msg = serialization.unserialize(evt[6])
      if msg then 
        if frame_type == libip.IP_PORT then 
          if msg.target_address then
            msg.target_address = libip.IPtoString(msg.target_address)
          end
          if msg.source_address then
            msg.source_address = libip.IPtoString(msg.source_address)
          end
          if msg.protocol then 
            if msg.protocol == 17 then msg.protocol = "UDP" end
          end
        end
      end
      if interactive then gpu.setForeground(0xCC2200) end
      io.write("[" .. os.date("%T") .. "] ")
      if interactive then gpu.setForeground(0x44CC00) end
      io.write(frame_type_to_str(frame_type) .. string.rep(" ", math.max(6 - #tostring(frame_type_to_str(frame_type)), 0) + 1))
      if interactive then gpu.setForeground(0xB0B00F) end
      io.write(string.sub(tostring(evt[3]),1,8) .. " ")
      if interactive then gpu.setForeground(0xFFFFFF) end
      io.write("  " .. tostring(evt[5]))
      io.write("  " .. tostring(evt[6])) --
      io.write("\n")
    end
  until evt[1] == "interrupted"
end)
if interactive then
  gpu.setForeground(color, isPal)
end