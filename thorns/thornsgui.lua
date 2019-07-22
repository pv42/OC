local term = require("term")
local colors = require("colors")
local thornsgui = {}
thornsgui.SCROLLBAR_AUTO = 85 -- the values dont matter
thornsgui.SCROLLBAR_ALWAYS = 86
thornsgui.SCROLLBAR_NEVER = 87
local out = term
local event = require("event")
local dragHandler = nil
local dropHandler = nil
out.clickSensitive = {}

local function drawFilledBox(x,y,x_size,ysize,color)
  out.gpu().setBackground(color)
  out.gpu().fill(x,y,x_size,ysize," ")
end 

local function createTermOffset(ox,oy)
  local t = {}
  t.gpu =  function()
    local g = {}
    g.setForeground = out.gpu().setForeground
    g.setBackground = out.gpu().setBackground
    g.fill = function(x,y,xs,ys,c)
      out.gpu().fill(x+ox,y+oy,xs,ys,c)
    end
    g.getPaletteColor = out.gpu().getPaletteColor
    return g
  end
  t.write = out.write
  t.setCursor = function(x, y)
    out.setCursor(x + ox, y + oy)
  end
  t.clickSensitive = {}
  return t
end

thornsgui.Button = {}
thornsgui.Button.__index = thornsgui.Button

function thornsgui.Button:create(x_pos,y_pos,x_size,y_size,text)
  checkArg(1, x_pos, "number")
  checkArg(2, y_pos, "number")
  checkArg(3, x_size, "number")
  checkArg(4, y_size, "number")
  checkArg(5, text, "string")
  local btn = {}
  setmetatable(btn, thornsgui.Button)
  btn.type = "button"
  btn.pos = {}
  btn.pos.x = x_pos
  btn.pos.y = y_pos
  btn.size = {}
  btn.size.x= x_size
  btn.size.y = y_size
  btn.color = {}
  btn.color.text = out.gpu().getPaletteColor(colors.white)
  btn.color.bg = out.gpu().getPaletteColor(colors.gray)
  btn.text = text 
  btn.onClick = function() end -- should be overwriten 
  table.insert(out.clickSensitive,btn)
  return btn
end

function thornsgui.Button:draw()
    --out.setCursor(1,1) --nessescary ?
    drawFilledBox(
      self.pos.x,
      self.pos.y,
      self.size.x,
      self.size.y,
      self.color.bg
    )
    out.gpu().setForeground(self.color.text)
    out.setCursor(self.pos.x, self.pos.y)
    out.write(self.text)
end

-- don't call public
function thornsgui.Button:handleClick(x,y)
  if x >= self.pos.x and y >= self.pos.y and x < self.pos.x + self.size.x and y < self.pos.y + self.size.y then
    if(self.onClick ~= nil) then self.onClick() end 
    return true
  else 
    return false
  end
end

thornsgui.Text = {}
thornsgui.Text.__index = thornsgui.Text

function thornsgui.Text:create(x,y,text)
  checkArg(1, x, "number")
  checkArg(2, y, "number")
  checkArg(3, text, "string")
  local txt = {}
  setmetatable(txt, thornsgui.Text)
  txt.type = "text"
  txt.pos = {}
  txt.pos.x = x
  txt.pos.y = y
  txt.text = text
  txt.size = {}
  txt.size.x = string.len(text)
  txt.size.y = 1
  txt.color = {}
  txt.color.bg = out.gpu().getPaletteColor(colors.white)
  txt.color.text = out.gpu().getPaletteColor(colors.black)
  return txt
end

function thornsgui.Text:draw()
  out.gpu().setBackground(self.color.bg)
  out.gpu().setForeground(self.color.text)
  out.setCursor(self.pos.x, self.pos.y)
  out.write(self.text)
end

-- elements in a Vertical view have their x and y position managed by the view
thornsgui.VerticalView = {}
thornsgui.VerticalView.__index = thornsgui.VerticalView
function thornsgui.VerticalView:create()
  local vv = {}
  setmetatable(vv, thornsgui.VerticalView)
  vv.type = "verticalView"
  vv.size = {}
  vv.size.x = 0
  vv.size.y = 0
  vv.pos = {}
  vv.pos.x = 1
  vv.pos.y = 1
  vv.elements = {} -- dont modify manually
  return vv
end

function thornsgui.VerticalView:addElement(ele)
  checkArg(1, ele, "table")
  table.insert(self.elements, ele)
  if ele.size.x > self.size.x then self.size.x = ele.size.x end
  self.size.y = self.size.y + ele.size.y
end

function thornsgui.VerticalView:removeElement(ele)
  checkArg(1, ele, "table")
  table.remove(self.elements, ele)
  self.size.y = self.size.y - ele.size.y
end

function thornsgui.VerticalView:draw()
  local cx = self.pos.x
  local cy = self.pos.y
  for _,ele in pairs(self.elements) do
    ele.pos.x = cx
    ele.pos.y = cy
    ele:draw()
    cy = cy + ele.size.y
  end
end

-- elements in a Horizontal view have their x and y position managed by the view
thornsgui.HorizontalView = {}
thornsgui.HorizontalView.__index = thornsgui.HorizontalView

function thornsgui.HorizontalView:create()
  local hv = {}
  setmetatable(hv, thornsgui.HorizontalView)
  hv.type = "horizontalView"
  hv.size = {}
  hv.size.x = 0
  hv.size.y = 0
  hv.pos = {}
  hv.pos.x = 1
  hv.pos.y = 1
  hv.elements = {} -- don't modify manually
  return hv
end
function thornsgui.HorizontalView:addElement(ele)
  checkArg(1, ele, "table")
  table.insert(self.elements, ele)
  if ele.size.y > self.size.y then self.size.y = ele.size.y end
  self.size.x = self.size.x + ele.size.x
end

function thornsgui.HorizontalView:draw()
  local cx = self.pos.x
  local cy = self.pos.y
  for _,ele in pairs(self.elements) do
    ele.pos.x = cx
    ele.pos.y = cy
    ele:draw()
    cx = cx + ele.size.x
  end
end



thornsgui.Custom = {}
thornsgui.Custom.__index = thornsgui.Custom

function thornsgui.Custom:create(xsize,ysize,drawfunc)
  checkArg(1, xsize, "number")
  checkArg(2, ysize, "number")
  checkArg(3, drawfunc, "function")
  local cust = {}
  setmetatable(cust, thornsgui.Custom)
  cust.type = "custom"
  cust.size = {}
  cust.size.x = xsize
  cust.size.y = ysize
  cust.pos = {}
  cust.pos.x = 1
  cust.pos.y = 1
  cust.drawfunc = drawfunc
  return cust
end

function thornsgui.Custom:draw()
  self.drawfunc(createTermOffset(self.pos.x, self.pos.y))
end

function thornsgui.Custom:handleClick(x,y)
  checkArg(1, x, "number")
  checkArg(2, y, "number")
  if x >= self.pos.x and y >= self.pos.y and x < self.pos.x + self.size.x and y < self.pos.y + self.size.y then
    if(self.onClick ~= nil) then self.onClick() end 
    return true
  else 
    return false
  end
end

function thornsgui.Custom:makeClickable()
  table.insert(out.clickSensitive, self)
end

thornsgui.HorizontalScrollbar = {}
thornsgui.HorizontalScrollbar.__index = thornsgui.HorizontalScrollbar

function thornsgui.HorizontalScrollbar:create(xsize)
  checkArg(1, xsize, "number")
  local hsb = {}
  setmetatable(hsb, thornsgui.HorizontalScrollbar)
  hsb.size = {}
  hsb.size.x = xsize
  hsb.size.y = 1 -- dont change this
  hsb.pos = {}
  hsb.pos.x = 1
  hsb.pos.y = 1
  hsb.onScroll = function(value) end -- change this; value is float
  hsb.value = 0
  hsb.maxvalue = 1
  hsb._leftbtn = thornsgui.Button:create(hsb.pos.x, hsb.pos.y, 1,1, "<")
  hsb._leftbtn.onClick = function() 
    hsb.value = hsb.value - 1
    if hsb.value < 0 then hsb.value = 0 end
    hsb.onScroll(hsb.value)
  end
  hsb._rightbtn = thornsgui.Button:create(hsb.pos.x + hsb.size.x - 1 , hsb.pos.y, 1,1, ">")
  hsb._rightbtn.onClick = function() 
    hsb.value = hsb.value + 1 
    if hsb.value > hsb.maxvalue then hsb.value = hsb.maxvalue end
    hsb.onScroll(hsb.value)
  end
  hsb._scrollpart = thornsgui.Button:create(1, hsb.pos.y, 2,1, "  ")
  hsb.scrollpart.onClick = function(x0,y0) --ignore y 
    local v0 = hsb.value
    dragHandler = function(x,y) 
      hsb.value = v0 + (x - x0) * hsb.maxvalue / (hsb.size.x - 4)
      if hsb.value < 0 then hsb.value = 0 end
      if hsb.value > hsb.maxvalue then hsb.value = hsb.maxvalue end
      hsb._scrollbg:draw()
      hsb._scrollpart.pos.x = hsb._scrollpart.pos.x + x - x0 
      hsb._scrollpart:draw()
    end --ignore y
    dropHandler = function() --unregister handlers
        dragHandler = nil
        dropHandler = nil
      end
  end
  hsb._scrollbg = thornsgui.Text:create(hsb.pos.x + 1, hsb.pos.y, string.rep(" ", hsb.size.x - 2))
  return hsb
end

function thornsgui.HorizontalScrollbar:draw()
  self._scrollpart.pos.x = self.pos.x + 1 + (self.value / self.maxvalue) * (self.size.x - 4)
  self._scrollpart.pos.y = self.pos.y
  self._leftbtn.pos.x = self.pos.x
  self._leftbtn.pos.y = self.pos.y
  self._serightbtn.pos.x = self.pos.x
  self._serightbtn.pos.y = self.pos.y + self.size.x - 1
  self._leftbtn:draw()
  self._serightbtn:draw()
  self._scrollbg:draw()
  self._scrollpart:draw()
end

--[[
function thornsgui.createTable(dim_x,dim_y,x_pos,y_pos)
    local tbl = {}
    tbl.type = "table"
    tbl.dim = {dim_x, dim_y}
    tbl.pos = {}
    tbl.pos.x = x_pos
    tbl.pos.y = y_pos
    tbl.elements = {}
    for i=1,dim_x do
        tbl.elements[i] = {}
    end
    tbl.draw = function()
        local cx = tbl.pos.x
        local mx = {}
        local my = {}
        for i=1,tbl.dim[1] do
            for j=1,tbl.dim[2] do
                if(tbl.elements[i][j]~=nil) then 
                    if mx[i] == nil then 
                        mx[i] = tbl.elements[i][j].size.x 
                    else
                        mx[i] = math.max(mx[i],tbl.elements[i][j].size.x)
                    end
                    if my[j] == nil then 
                        my[j] = tbl.elements[i][j].size.y 
                    else
                        my[j] = math.max(my[j],tbl.elements[i][j].size.y) 
                    end
                end
                if(i == tbl.dim[1] and my[j] == nil ) then my[j] = 0 end --empty
            end
            if(mx[i] == nil) then mx[i] = 0 end --empty
        end
        for i=1,tbl.dim[1] do
            local cy=tbl.pos.y
            for j=1,tbl.dim[2] do
                if(tbl.elements[i][j]~=nil) then 
                    tbl.elements[i][j].setPos(cx,cy)
                    tbl.elements[i][j].draw() 
                end
                cy = cy + my[j]
            end
            cx = cx + mx[i]
        end
    end
    tbl.setElement = function(x,y,element)
        if(x>tbl.dim[1] or x<1 or y>tbl.dim[2] or y<1) then error("Index("..x..","..y..") out of boundaries: " .. tbl.dim[1] .. "," .. tbl.dim[2]) end
       
        tbl.elements[x][y] = element
    end
    tbl.setColors = function(txtc,backc,type) -- optional:type(string) only color a type of subelements
        for i = 1,tbl.dim[1] do
            for j = 1,tbl.dim[2] do
                if(tbl.elements[i][j]~=nil ) then 
                    if(type == nil or tbl.elements[i][j].type == type) then tbl.elements[i][j].setColors(txtc,backc) end
                end
            end
        end
    end
    tbl.size = function() 
        error("//TODO")
    end
    return tbl
end


function thornsgui.createDropdownSelector(x,y)
    dds = {}
    dds.type="dropdownselector"
    dds.pos  = {}
    dds.pos.x = x
    dds.pos.y = y
    dds.size = {}
    dds.size.x = 1
    dds.size.y = 1
    dds.options = {}
    dds.selected = 1
    dds.addOption = function(text)
        opt = createButton(1,1,string.len(text),1,text)
        opt.setColors(colors.black,colors.white)
        opt.setPos(dds.pos.x,dds.pos.y)
        table.insert(dds.options,opt)
        dds.size.x = math.max(dds.size.x,opt.size.x+1)
        dds.size.y = math.max(dds.size.y,opt.size.y)
    end
    dds.draw = function()
        if(#(dds.options) == 0) then error("At least one option required") end
        if(dds.selectBtn == nil) then --init selectButton 
            -- +dds.size.x-1
            dds.selectBtn = createButton(dds.pos.x+dds.size.x-1,dds.pos.y,1,1,"v")
            local fx = function()
                if dds.ddw == nil then 
                    offset_x,offset_y = 0,0
                    if out.getPosition ~= nil then 
                        offset_x,offset_y = out.getPosition() 
                        offset_x = offset_x - 1
                        offset_y = offset_y -1
                    end
                    dds.ddw = window.create(term_c,dds.pos.x + offset_x, dds.pos.y+1 + offset_y,dds.size.x-1, #(dds.options),false)
                    dds.ddw.setBackgroundColor(colors.white)
                    dds.ddw.clear()
                    dds.ddw.visible = false
                    
                end
                dds.ddw.visible = not dds.ddw.visible
                dds.ddw.setVisible(dds.ddw.visible)
                if (dds.ddw.visible) then
                    dds.ddw.parent = out
                    setOutput(dds.ddw)
                    for i =1,#(dds.options) do
                        dds.options[i].setPos(1,i)
                        dds.options[i].setOnClick(function()
                            dds.selected = i
                            dds.ddw.visible = not dds.ddw.visible
                            dds.ddw.setVisible(dds.ddw.visible)
                            setOutput(dds.ddw.parent)
                            drawFilledBox(dds.pos.x,dds.pos.y,dds.pos.x+dds.size.x-2,dds.pos.y+dds.size.y-1,colors.white)--clear space
                            dds.options[dds.selected].setPos(dds.pos.x,dds.pos.y)
                            dds.options[dds.selected].draw()
                            out.redraw()
                            if (dds.onChange ~= nil) then dds.onChange(i,dds.options[i].text) end
                        end)
                        dds.options[i].registerEventListener()
                        dds.options[i].draw()
                    end
                    dds.ddw.redraw() --?
                else
                    setOutput(dds.ddw.parent)
                    out.redraw()
                    dds.ddw.redraw()
                end
            end
            dds.selectBtn.setOnClick(fx)
            dds.selectBtn.registerEventListener()
        end
        drawFilledBox(dds.pos.x,dds.pos.y,dds.pos.x+dds.size.x-2,dds.pos.y+dds.size.y-1,colors.white)--clear space
        dds.options[dds.selected].draw()
        dds.selectBtn.draw()
    end
    dds.setOnChange = function(f)
        dds.onChange = f
    end
    dds.setSelected = function(s)
        if(type(s)=="string") then
            for i=1,#(dds.options) do
                if(dds.options[i].text == s) then 
                    s = i 
                    break
                end
            end
            if type(s)==string then
                error("no valid option given")
                return 
            end
        end
        if(s>#(dds.options) or s < 1) then error("out of range") end
        dds.selected = s
    end
    return dds
end

function thornsgui.createTextBox(x_pos,y_pos,x_size,y_size)
    tb = {}
    tb.pos = {}
    tb.pos.x = x_pos
    tb.pos.y = y_pos
    tb.size = {}
    tb.size.x = x_size
    tb.size.y = y_size
    tb.color = {}
    tb.hint = {}
    tb.hint.text = "<hint>"
    tb.hint.color = out.gpu().getPaletteColor(colors.lightGray)
    tb.draw = function()
        drawFilledBox(tb.pos.x,tb.pos.y,tb.pos.x + tb.size.x - 1,tb.pos.y + tb.size.y - 1,out.gpu().getPaletteColor(colors.black))
        out.setCursor(tb.pos.x,tb.pos.y)
        out.setForeground(tb.hint.color)
        io.write()
        out.setCursorBlink(true)
    end
    tb.setHintText = function(txt)
        tb.hint.text = txt
    end
    tb.setHintColor = function(color)
        tb.hint.color = color
    end
end
]]--

-- clears current out-pipes clickSensitive-mem
function thornsgui.clearClickListeners()
    out.clickSensitive = {}
end
-- waits for and handels next click event
function thornsgui.handleNextEvent()
  local ev, _, x, y,  btn = event.pullMultiple("touch","drag","drop")
  -- if in sub window calc offset:
  if out.getPosition ~= nil then 
    local ox,oy = out.getPosition()
    x = x-ox+1
    y = y-oy+1
  end
  if ev == "touch" then
    for _,cs in pairs(out.clickSensitive) do
      if(cs:handleClick(x,y, btn)) then break end
    end
  elseif ev == "drag" then
    if dragHandler then dragHandler(x,y) end
  elseif ev == "drop" then 
    if dropHandler then dropHandler(x,y) end
  end
end

local function drawImage(file)
  local f,msg = io.open(file)
  if not f then error(msg) end
  local cont = f:read("a*")
  for i=1,#cont do 
    local ch = string.sub(cont, i,i)
    out.gpu().setBackground(out.gpu().getPaletteColor(colors.white)) -- white per default
    if string.byte(ch) >= 48 and string.byte(ch) <= 57 then
      out.gpu().setBackground( out.gpu().getPaletteColor(string.byte(ch) - 48)) -- 0 .. 9
    end
    if string.byte(ch) >= 97 and string.byte(ch) <= 102 then
      out.gpu().setBackground( out.gpu().getPaletteColor(string.byte(ch) - 87)) -- a .. f
    end
    if ch ~= "\n" then 
      io.write(" ") 
    else
      io.write("\n")
    end 
  end
end

--shows logo
function showLogo(t)
    out.gpu().setBackground(out.gpu().getPaletteColor(colors.white))
    out.clear()
    drawImage("/usr/lib/thornslogo")
    os.sleep(t)
    out.gpu().setBackground(out.gpu().getPaletteColor(colors.black))
    out.clear()
end
showLogo(0.4)

return thornsgui