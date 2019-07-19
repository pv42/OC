--filemgr.lua
local thorns = require("thornsgui")
local fs = require("filesystem") 
local term = require("term")
local unicode = require("unicode")

local pwd = os.getenv().PWD
local stop = false

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

function drawFileSymbol(gout,x,y,ext)
  if ext == "lua" or ext == "LUA" then 
    gout.gpu().setBackground(0x3333ff)
  else
    gout.gpu().setBackground(0x333333)
  end 
  gout.gpu().setForeground(0xffffff)
  gout.setCursor(x,  y)
  gout.write("   " .. unicode.char(0x2819) .. unicode.char(0x28bf))
  gout.setCursor(x,  y+1)
  gout.write("     ")
  gout.setCursor(x,  y+2)
  gout.write("     ")
  gout.setCursor(x+1,y+2)
  gout.write(ext)
  gout.setCursor(x,  y+3)
  gout.write("     ")
  gout.gpu().setBackground(0xffffff)
  gout.gpu().setForeground(0x000000)
end

function drawFolderSymbol(gout,x,y)
  gout.gpu().setBackground(0x333333)
  gout.gpu().setForeground(0xffffff)
  gout.setCursor(x,  y)
  gout.write("     ")
  gout.setCursor(x,  y+1)
  gout.write("     ")
  gout.setCursor(x,  y+2)
  gout.write("     ")
  gout.setCursor(x,  y+3)
  gout.write("     ")
  gout.gpu().setBackground(0xffffff)
  gout.gpu().setForeground(0x000000)
end

function draw()
  local vv0 = thorns.VerticalView:create()
  local head = thorns.HorizontalView:create()
  
  local titletext = thorns.Text:create(1,1,"FileMgr - " .. pwd .. string.rep(" ", term.gpu().getResolution() - 12 - #pwd))
  local exitBtn = thorns.Button:create(1,1,2,1," X")
  exitBtn.color.text = 0xffffff -- white
  exitBtn.color.bg = 0xff0000 -- red
  exitBtn.onClick = function()
    stop = true
  end
  head:addElement(titletext)
  head:addElement(exitBtn)
  vv0:addElement(head)
  local parentBtn = thorns.Button:create(1,1,3,1," ^")
  parentBtn.onClick = function()
    pwd = fs.realPath(pwd .."/..")
  end
  vv0:addElement(parentBtn)
  local hv = thorns.HorizontalView:create()
  for _,f in pairs(stats(pwd)) do
    local df = function(gout)
      if f.isDir then 
        drawFolderSymbol(gout, 1, 1)
      else
        drawFileSymbol(gout, 1, 1, f.ext)
      end
      gout.setCursor(7, 1)
      gout.write(f.name)
      gout.setCursor(7, 2)
      gout.write(f.size)
      gout.setCursor(7, 3)
      local text = f.ext .. "-file"
      if f.ext == "" then text = "file" end
      if f.isDir then text = "DIR" end
      gout.write(text)
    end
    local custom = thorns.Custom:create(20, 5, df)
    if f.isDir then 
        custom:makeClickable()
        custom.onClick = function() 
          pwd = pwd .. "/" .. f.name
        end
    if hv.size.x + custom.size.x > term.gpu().getResolution() then
      vv0:addElement(hv)
      hv = thorns.HorizontalView:create()
    end
    hv:addElement(custom)
  end
  vv0:addElement(hv)
  vv0:draw()
  thorns.handleNextEvent()
end
function main()
  term.gpu().setBackground(0xffffff)
  term.gpu().setForeground(0x000000)
  term.clear()
  while not stop do 
    draw()
  end
  term.gpu().setBackground(0x000000)
  term.gpu().setForeground(0xffffff)
  term.clear()
  term.setCursor(1,1)
end

main()