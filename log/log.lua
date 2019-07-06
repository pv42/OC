local log = {}
local tty = require("tty")
local gpu = tty.gpu()
local interactive = io.output().tty
--local color, isPal
if interactive then
  color, isPal = gpu.getForeground()
end

local function save_color()
  if interactive then
  	color, isPal = gpu.getForeground()
  end
end

local function restore_color()
  if interactive then
    gpu.setForeground(color, isPal)
  end
end

function log.e(msg)
  save_color()
  if interactive then
    gpu.setForeground(0xFF0000) -- red
  end
  io.write("[ERR] " .. msg)
  restore_color()
end

function log.w(msg)
  save_color()
  if interactive then
    gpu.setForeground(0xFFFF00) -- yellow
  end
  io.write("[WRN] " .. msg)
  restore_color()
end

function log.i(msg)
  save_color()
  if interactive then
    gpu.setForeground(0xFFFFFF) -- white
  end
  io.write("[INF] " .. msg)
  restore_color()
end

return log