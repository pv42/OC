--filemgr.lua
local thorns = require("thornsgui")
local fs = require("filesystem") 
local term = require("term")
local unicode = require("unicode")

local pwd = os.getenv().PWD

function stats(base_path)
  local content = {}
  for f in fs.list(base_path) do
    local full_path = fs.concat(base_path,f)
    local info = {}
    info.name = f:gsub("/+$","")
    info.isDir = fs.isDirectory(full_path)
    info.size = fs.size(full_path)
    info.ext = (info.name:match("(%.[^.]+)$") or ""):sub(2) -- regex for .xyz and then remove .
    table.insert(content, info)
  end
  return content
end

function drawFileSymbol(x,y,ext)
  if ext == "lua" or ext == "LUA" then 
    term.gpu().setBackground(0x3333ff)
  else
    term.gpu().setBackground(0x333333)
  end 
  term.gpu().setForeground(0xffffff)
  term.setCursor(x,y)
  io.write("   " .. unicode.char(0x2819) .. unicode.char(0x28bf))
  term.setCursor(x,y+1)
  io.write("     ")
  term.setCursor(x,y+2)
  io.write("     ")
  term.setCursor(x+1,y+2)
  io.write(ext)
  term.setCursor(x,y+3)
  io.write("     ")
  term.gpu().setBackground(0xffffff)
  term.gpu().setForeground(0)
end

function draw()
  term.gpu().setBackground(0xffffff)
  term.gpu().setForeground(0)
  term.clear()
  local tb = thornsgui.createTextBox(1,1,40,1)
  tb.draw()
  local x = 3
  local y = 1
  for _,f in pairs(stats(pwd)) do
    drawFileSymbol(x, y, f.ext)
    term.setCursor(x + 6, y)
    io.write(f.name)
    term.setCursor(x + 6, y+1)
    io.write(f.size)
    term.setCursor(x + 6, y+2)
    local text = ext.."-file"
    if f.isDir then text = "DIR" end
    io.write(text)
    x = x + 20
    if x > term.gpu().getResolution() - 20 and x > 3 then
      x = 3
      y = y + 5
    end 
  end
end

draw()
print("") --\n