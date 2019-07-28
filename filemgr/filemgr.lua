--filemgr.lua
local thorns = require("thornsgui")
local fs = require("filesystem") 
local term = require("term")
local unicode = require("unicode")

local pwd = os.getenv().PWD
local prev_wd = nil
local next_wd = nil
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

function drawFileSymbol(gpu,x,y,ext)
  if ext == "lua" or ext == "LUA" then 
    gpu.setBackground(0x3333ff)
  else
    gpu.setBackground(0x333333)
  end 
  gpu.setForeground(0xffffff)
  gpu.set(x, y,"   " .. unicode.char(0x2819) .. unicode.char(0x28bf))
  gpu.set(x,  y+1, "     ")
  gpu.set(x,  y+2, "     ")
  gpu.set(x+1,y+2, ext)
  gpu.set(x,  y+3, "     ")
  gpu.setBackground(0xffffff)
  gpu.setForeground(0x000000)
end

function drawFolderSymbol(gpu,x,y)
  gpu.setBackground(0x333333)
  gpu.setForeground(0xffffff)
  gpu.set(x, y, "     ")
  gpu.set(x, y+1, "     ")
  gpu.set(x, y+2, "     ")
  gpu.set(x, y+3, "     ")
  gpu.setBackground(0xffffff)
  gpu.setForeground(0x000000)
end
local function sizeString(size)
  if size < 1000 then return string.format("%dB", size) end
  if size < 10240 then return string.format("%.2fkiB", size/1024) end
  if size < 102400 then return string.format("%.1fkiB", size/1024) end
  if size < 1024000 then return string.format("%.0fkiB", size/1024) end
  return string.format("%.0fMiB", size/1048576) 
end

function drawStats()
  local vv = thorns.VerticalView:create()
  local hv = thorns.HorizontalView:create()
  
  for _,f in pairs(stats(pwd)) do
    local df = function(gpu)
      if f.isDir then 
        drawFolderSymbol(gpu, 1, 1)
      else
        drawFileSymbol(gpu, 1, 1, f.ext)
      end
      gpu.set(7, 1, f.name)
      gpu.set(7, 2, sizeString(f.size))
    
      local text = f.ext .. "-file"
      if f.ext == "" then text = "file" end
      if f.isDir then text = "DIR" end
      gpu.set(7, 3, text)
    end
    local custom = thorns.Custom:create(20, 5, df)
    if f.isDir then 
      custom:makeClickable()
      custom.onClick = function() 
        prev_wd = pwd
        pwd = pwd .. "/" .. f.name
      end
    end
    if hv.size.x + custom.size.x > term.gpu().getResolution() - 1 then
      vv:addElement(hv)
      hv = thorns.HorizontalView:create()
    end
    hv:addElement(custom)
  end
  vv:addElement(hv)
  return vv
end

function draw()
  term.gpu().setBackground(0xffffff)
  term.gpu().setForeground(0x000000)
  term.clear()
  thorns.clearClickListeners()
  local vv0 = thorns.VerticalView:create()
  local head = thorns.HorizontalView:create()
  local pwd_v = pwd
  if pwd_v == "" then pwd_v = "/" end
  local titletext = thorns.Text:create(1,1,"FileMgr - " .. pwd_v .. string.rep(" ", term.gpu().getResolution() - 12 - #pwd))
  local exitBtn = thorns.Button:create(1,1,2,1," X")
  exitBtn.color.text = 0xffffff -- white
  exitBtn.color.bg = 0xff0000 -- red
  exitBtn.onClick = function()
    stop = true
  end
  head:addElement(titletext)
  head:addElement(exitBtn)
  vv0:addElement(head)
  local prevBtn = thorns.Button:create(1,1,3,1," <")
  prevBtn.onClick = function()
    next_wd = pwd
    pwd = prev_wd
  end
  local nextBtn = thorns.Button:create(1,1,3,1," >")
  local parentBtn = thorns.Button:create(1,1,3,1," ^")
  parentBtn.onClick = function()
    prev_wd = pwd
    pwd = fs.realPath(pwd .."/..")
  end
  local menu = thorns.HorizontalView:create()
  menu:addElement(prevBtn)
  menu:addElement(nextBtn)
  menu:addElement(thorns.Text:create(1,1," ")) -- placeholder
  menu:addElement(parentBtn)
  vv0:addElement(menu)
  local statsView = drawStats()
  local oldwd = pwd
  
  local xs,ys = term.gpu().getResolution()
  ys = ys - 2 -- one line for title and one line for menu
  local sc = thorns.ScrollContainer:create(statsView,xs,ys)
  vv0:addElement(sc)
        
  vv0:draw()
  while not stop do
    if oldwd ~= pwd then
        statsView:clear()
        vv0:removeElement(statsView)
        thorns.clearClickListeners()
        -- readd staying btns
        nextBtn:readdListener()
        prevBtn:readdListener()
        exitBtn:readdListener()
        parentBtn:readdListener()
        statsView = drawStats()
        local pwd_v = pwd
        if pwd_v == "" then pwd_v = "/" end
        titletext.text = "FileMgr - " .. pwd_v .. string.rep(" ", term.gpu().getResolution() - 12 - #pwd)
        titletext:draw()
        
        local xs,ys = term.gpu().getResolution()
        ys = ys - 2 -- one line for title and one line for menu
        local sc = thorns.ScrollContainer:create(statsView,xs,ys)
        vv0:addElement(sc)
        vv0:draw()
    end
    oldwd = pwd
    thorns.handleNextEvent()
  end
end
function main()
  thorns.clearClickListeners()
  draw()
  thorns.clearClickListeners()
  term.gpu().setBackground(0x000000)
  term.gpu().setForeground(0xffffff)
  term.clear()
  term.setCursor(1,1)
end

main()