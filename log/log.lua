local log = {}
local tty = require("tty")
local gpu = tty.gpu()
local interactive = io.output().tty
local f = io.output()
--local color, isPal
if interactive then
  local color, isPal = gpu.getForeground()
end

function log.connectFile(path)
  f = io.open(path,"a+")
end

function log.closeFile(path)
  f:flush()
  f:close()
  f = io.output()
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
  f:write("[ERR] " .. msg .. "\n")
  f:flush()
  restore_color()
end

function log.w(msg)
  save_color()
  if interactive then
    gpu.setForeground(0xFFFF00) -- yellow
  end
  f:write("[WRN] " .. msg .. "\n")
  f:flush()
  restore_color()
end

function log.i(msg)
  save_color()
  if interactive then
    gpu.setForeground(0xFFFFFF) -- white
  end
  f:write("[INF] " .. msg .. "\n")
  f:flush()
  restore_color()
end

return log