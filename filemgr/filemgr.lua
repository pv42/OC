--filemgr.lua
local thorns = require("thornsgui")
local fs = require("filesystem") 
local term = require("term")

local pwd = os.getenv().PWD

function stats(base_path)
  local content = {}
  for f in fs.list(base_path) do
    local full_path = fs.concat(base_path,f)
    local info = {}
    info.name = f:gsub("/+$","")
    info.isDir = fs.isDirectory(full_path)
    info.size = fs.size(full_path)
    info.ext = info.name:match("(%).[^.]+)$") or ""
    table.insert(content, info)
  end
  return content
end

function drawFileSymbol(x,y,ext)
  
  term.setBackground(0x0)
  term.setForeground(0xffffff)
  term.setCursor(x,y)
  io.write("   " .. unicode.char(0x2819) .. unicode.char(0x28bf))
  term.setCursor(x,y+1)
  io.write("     ")
  term.setCursor(x,y+2)
  io.write(" " .. ext .. " ")
  term.setCursor(x,y+3)
  io.write("     ")
  term.setBackground(0xffffff)
  term.setForeground(0)
end

function draw()
  term.setBackground(0xffffff)
  term.setForeground(0)
  term.clear()
  for _,f in pairs(stats(pwd)) do
    local x = 1
    local y = 1

    drawFileSymbol(x, y, f.ext)
    term.setCursor(x, y + 5)
    io.write(f.name)
    x =x+7
  end
end

draw()