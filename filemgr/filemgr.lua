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

function drawFileSymbol(out,x,y,ext)
  if ext == "lua" or ext == "LUA" then 
    out.gpu().setBackground(0x3333ff)
  else
    out.gpu().setBackground(0x333333)
  end 
  out.gpu().setForeground(0xffffff)
  out.setCursor(x,y)
  out.write("   " .. unicode.char(0x2819) .. unicode.char(0x28bf))
  out.setCursor(x,y+1)
  out.write("     ")
  out.setCursor(x,y+2)
  out.write("     ")
  out.setCursor(x+1,y+2)
  out.write(ext)
  out.setCursor(x,y+3)
  out.write("     ")
  out.gpu().setBackground(0xffffff)
  out.gpu().setForeground(0)
end

function draw()
  term.gpu().setBackground(0xffffff)
  term.gpu().setForeground(0)
  term.clear()
  local hv0 = thorns.HorizontalView:create()
  for _,f in pairs(stats(pwd)) do
    local df = function(out)
      drawFileSymbol(out, 1, 1, f.ext)
      out.setCursor(4, 1)
      out.write(f.name)
      out.setCursor(4, 2)
      out.write(f.size)
      out.setCursor(4, 3)
      local text = ext .. "-file"
      if f.isDir then text = "DIR" end
      out.write(text)
    end
    local custom = thorns.Custom:create(5,5,df)
    hv0:addElement(custom)
  end
  hv0:draw()
end

draw()
print("") --\n