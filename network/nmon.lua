local event = require("event")
local tty = require("tty")
local libip = require("libip")
local libtcp = require("libtcp")
local libdhcp = require("libdhcp")
local serialization = require("serialization")

local args = { ... }
local gpu = tty.gpu()
local interactive = io.output().tty
local color, isPal, evt
if interactive then
  color, isPal = gpu.getForeground()
end

local function type_to_str(frame_type, msg)
  if frame_type == libip.IP_PORT then
    if msg.protocol == 17 then
      if msg.data then
        if msg.data.destination_port == libdhcp.SERVER_PORT or msg.data.destination_port == 68 then
          return "DHCP"
        elseif msg.data.destination_port == 53 then
          return "DNS"
        end
        return "UPD/" .. tostring(msg.data.destination_port)
      else
        return "IP/17" -- invalid upd
      end
    elseif msg.protocol == 6 then
      if msg.data and msg.data.destination_port then
        return "TCP/" .. tostring(msg.data.destination_port)
      else
        return "IP/6" -- invalid TCP
      end
    else
      return "IP/" .. tostring(msg.protocol)
    end
  elseif frame_type == libip.ARP_PORT then
    if msg.protocol_address_type == 2048 then
      return "ARP/IP"
    else
      return "ARP/?"
    end
  else
    return tostring(frame_type)
  end
end

local function print_dark(str)
    if interactive then
        gpu.setForeground(0x222222)
        io.write(str)
        gpu.setForeground(0xffffff)
    else
        io.write(string.rep(" ", #str))
    end
end

-- prints relevant tcp flags (syn, ack, fin)
local function print_tcp_flags(flags)
    io.write(" ")
    if flags.ACK then
        io.write("A")
    else
        print_dark("A")
    end
    if flags.FIN then
        io.write("F")
    else
        print_dark("F")
    end
    if flags.SYN then
        io.write("S")
    else
        print_dark("S")
    end
end

io.write("NMon 1.0.06  (C) 2019 pv42\n")
io.write("Press 'Ctrl-C' to exit\n")
local suc, pcall_ret = pcall(function()
  repeat
    if #args > 0 then
      evt = table.pack(event.pullMultiple("interrupted", table.unpack(args)))
    else
      evt = table.pack(event.pull())
    end
    local evt_type = tostring(evt[1])
    if evt_type == "modem_message" then
      local frame_type = evt[4]
      local msg, e = serialization.unserialize(evt[6])
      if interactive then
        gpu.setForeground(0xCC2200)
      end
      io.write("[" .. os.date("%T") .. "] ")
      if interactive then
        gpu.setForeground(0x44CC00)
      end
      local pack_type = type_to_str(frame_type, msg)
      io.write(pack_type .. string.rep(" ", math.max(6 - #tostring(pack_type), 0) + 1))
      if interactive then
        gpu.setForeground(0xB0B00F)
      end
      io.write(string.sub(tostring(evt[3]), 1, 8))
      if interactive then
        gpu.setForeground(0xFFFFFF)
      end
      -- distance is not required io.write("  " .. tostring(evt[5]))
      if frame_type == libip.IP_PORT and msg then
        if msg.source_address then
          io.write(" " .. libip.IPtoString(msg.source_address))
        end
        if msg.target_address then
          io.write("->" .. libip.IPtoString(msg.target_address))
        end
        if msg.data then
          if msg.protocol == libtcp.TOS_TCP and msg.data.flags then
            print_tcp_flags(msg.data.flags)
            msg.data.flags = nil
          end
          io.write(" " .. serialization.serialize(msg.data))
        end
      else
        io.write("  " .. serialization.serialize(msg))
      end
      io.write("\n")
    end
  until evt[1] == "interrupted"
end)
print(pcall_ret)
if interactive then
  gpu.setForeground(color, isPal)
end