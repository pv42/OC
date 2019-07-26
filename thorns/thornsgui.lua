local component = require("component")
local colors = require("colors")
local thornsgui = {}
thornsgui.SCROLLBAR_AUTO = 85 -- the values dont matter
thornsgui.SCROLLBAR_ALWAYS = 86
thornsgui.SCROLLBAR_NEVER = 87
local gpu = component.gpu
local event = require("event")
local dragHandler = nil
local dropHandler = nil
gpu.clickSensitive = {}

local function drawFilledBox(x,y,x_size,ysize,color)
  gpu.setBackground(color)
  gpu.fill(x,y,x_size,ysize," ")
end 


-- creates a fake gpu with a draw area offset by x/y_pos, the draw areas top left has the coords x/y_start for inner purpusess, the draw areas size is limited to x/y_size 
-- the the last 4 args may all be nil
local function createFakeGPU(x_pos,y_pos, x_start, y_start, x_size, y_size)
  checkArg(1, x_pos, "number")
  checkArg(2, y_pos, "number")
  local g = {}
  g.pos = {x=x_pos,y=y_pos}
  g.setForeground = gpu.setForeground
  g.setBackground = gpu.setBackground
  g.getPaletteColor = gpu.getPaletteColor
  g.clickSensitive = {} 
  if x_start then  -- optional but you need both or none
    checkArg(3, x_start, "number", "nil") -- nil just for better print
    checkArg(4, y_start, "number")
    checkArg(5, x_size, "number") 
    checkArg(6, y_size, "number")
    g.fill = function(x,y,xs,ys,c)
      if x > x_start + x_size - 1 or y > y_start + y_size - 1 then return end -- if lwr limit is oob discart
      if x + xs - 1 > x_size then xs = x_size - x + 1 end -- upr clipping 
      if y + ys - 1 > y_size then ys = y_size - y + 1 end 
      if x < x_start then x = x_start end -- lwr clipping
      if y < y_start then y = y_start end
      gpu.fill(x+x_pos,y+y_pos,xs,ys,c)
    end
    g.set = function(x,y,text,flip)
      if flip then error("flip not supported in limited fake gpus") end
      if x > x_start + x_size - 1 or y > y_start + y_size - 1 then return end -- if lwr limit is oob discart
      -- todo x clipping (y clipping is not importatant) 
      gpu.set(x+x_pos,y+y_pos, text, false)
    end
  else -- unlimited draw area
    g.fill = function(x,y,xs,ys,c)
      gpu.fill(x+x_pos,y+y_pos,xs,ys,c)
    end
    g.set = function(x,y,text,flip)
      gpu.set(x+x_pos,y+y_pos, text, flip)
    end
  end
  return g
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
  btn.color.text = gpu.getPaletteColor(colors.white)
  btn.color.bg = gpu.getPaletteColor(colors.gray)
  btn.text = text 
  btn.onClick = function() end -- should be overwriten 
  table.insert(gpu.clickSensitive,btn)
  return btn
end

-- reinsert into click sensitive table, don't use it unless you cleared the table
function thornsgui.Button:readdListener()
  table.insert(gpu.clickSensitive, self)
end

function thornsgui.Button:draw()
    drawFilledBox(
      self.pos.x,
      self.pos.y,
      self.size.x,
      self.size.y,
      self.color.bg
    )
    gpu.setForeground(self.color.text)
    gpu.set(self.pos.x, self.pos.y, self.text)
end

-- don't call public
function thornsgui.Button:handleClick(x,y)
  if x >= self.pos.x and y >= self.pos.y and x < self.pos.x + self.size.x and y < self.pos.y + self.size.y then
    if(self.onClick ~= nil) then self.onClick(x,y) end 
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
  txt.color.bg = gpu.getPaletteColor(colors.white)
  txt.color.text = gpu.getPaletteColor(colors.black)
  return txt
end

function thornsgui.Text:draw()
  gpu.setBackground(self.color.bg)
  gpu.setForeground(self.color.text)
  gpu.set(self.pos.x, self.pos.y, self.text)
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
  for i = 1, #(self.elements) do
    if ele == self.elements[i] then table.remove(self.elements, i) end
  end
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

-- clear the views part of the screem  
function thornsgui.VerticalView:clear()
  gpu.fill(self.pos.x,self.pos.y, self.size.x, self.size.y, " ")
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
  self.drawfunc(createFakeGPU(self.pos.x, self.pos.y))
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
  table.insert(gpu.clickSensitive, self)
end


thornsgui.VerticalScrollbar = {}
thornsgui.VerticalScrollbar.__index = thornsgui.VerticalScrollbar
-- TODO
function thornsgui.VerticalScrollbar:create(ysize)
  checkArg(1, ysize, "number")
  local vsb = {}
  setmetatable(vsb, thornsgui.VerticalScrollbar)
  vsb.size = {}
  vsb.size.x = 1 -- dont change this
  vsb.size.y = ysize 
  vsb.pos = {}
  vsb.pos.x = 1
  vsb.pos.y = 1
  vsb.onScroll = function(value) end -- change this; value is float
  vsb.value = 0
  vsb.maxvalue = 1
  vsb._topbtn = thornsgui.Button:create(vsb.pos.x, vsb.pos.y, 1,1, "^")
  vsb._topbtn.onClick = function() 
    vsb.value = vsb.value - 1
    if vsb.value < 0 then 
      vsb.value = 0 
    end
    vsb.onScroll(vsb.value)
    -- draw
    vsb._scrollpart.pos.y = vsb.pos.y + 1 + (vsb.value / vsb.maxvalue) * (vsb.size.y - 3)
    drawFilledBox(vsb.pos.x, vsb.pos.y + 1, 1, vsb.size.y - 2, 0xffffff) -- scroll bg
    vsb._scrollpart:draw()
  end
  vsb._btmbtn = thornsgui.Button:create(vsb.pos.x + vsb.size.x - 1 , vsb.pos.y, 1,1, "v")
  vsb._btmbtn.onClick = function() 
    vsb.value = vsb.value + 1 
    if vsb.value > vsb.maxvalue then 
      vsb.value = vsb.maxvalue 
    end
    vsb.onScroll(vsb.value)
    -- draw
    vsb._scrollpart.pos.x = vsb.pos.x + 1 + (vsb.value / vsb.maxvalue) * (vsb.size.x - 3)
    
    drawFilledBox(vsb.pos.x, vsb.pos.y + 1, 1, vsb.size.y - 2, 0xffffff) -- scroll bg
    vsb._scrollpart:draw()
  end
  vsb._scrollpart = thornsgui.Button:create(1, 1, 2,1, " ") -- pos is overwritten anyways
  vsb._scrollpart.onClick = function(_,y0) --ignore x
    checkArg(2,y0,"number")
    local v0 = vsb.value
    local y0_ = y0
    dragHandler = function(_,y) --ignore y
      vsb.value = v0 + (y - y0_) * vsb.maxvalue / (vsb.size.y - 4)
      if vsb.value < 0 then vsb.value = 0 end
      if vsb.value > vsb.maxvalue then vsb.value = vsb.maxvalue end
      drawFilledBox(vsb.pos.x, vsb.pos.y + 1, 1, vsb.size.y - 2, 0xffffff) -- scroll bg
      vsb._scrollpart.pos.y = vsb.pos.y + 1 + (vsb.value / vsb.maxvalue) * (vsb.size.y - 3)
      vsb._scrollpart:draw()
    end 
    dropHandler = function() --unregister handlers
      dragHandler = nil
      dropHandler = nil
    end
  end
  return vsb
end

function thornsgui.VerticalScrollbar:draw()
  self._scrollpart.pos.x = self.pos.x
  self._scrollpart.pos.y = self.pos.y  + 1 + (self.value / self.maxvalue) * (self.size.y - 3)
  self._topbtn.pos.x = self.pos.x
  self._topbtn.pos.y = self.pos.y
  self._btmbtn.pos.x = self.pos.x
  self._btmbtn.pos.y = self.pos.y + self.size.y - 1
  self._topbtn:draw()
  self._btmbtn:draw()
  drawFilledBox(self.pos.x, self.pos.y + 1, 1, self.size.y - 2, 0xffffff) -- scroll bg
  self._scrollpart:draw()
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
    if hsb.value < 0 then 
      hsb.value = 0 
    end
    hsb.onScroll(hsb.value)
    -- draw
    hsb._scrollpart.pos.x = hsb.pos.x + 1 + (hsb.value / hsb.maxvalue) * (hsb.size.x - 4)
    hsb._scrollbg:draw()
    hsb._scrollpart:draw()
  end
  hsb._rightbtn = thornsgui.Button:create(hsb.pos.x + hsb.size.x - 1 , hsb.pos.y, 1,1, ">")
  hsb._rightbtn.onClick = function() 
    hsb.value = hsb.value + 1 
    if hsb.value > hsb.maxvalue then 
      hsb.value = hsb.maxvalue 
    end
    hsb.onScroll(hsb.value)
    -- draw
    hsb._scrollpart.pos.x = hsb.pos.x + 1 + (hsb.value / hsb.maxvalue) * (hsb.size.x - 4)
    hsb._scrollbg:draw()
    hsb._scrollpart:draw()
  end
  hsb._scrollpart = thornsgui.Button:create(1, 1, 2,1, "  ") -- pos is overwritten anyways
  hsb._scrollpart.onClick = function(x0,_) --ignore y 
    checkArg(1,x0,"number")
    local v0 = hsb.value
    local x0_ = x0
    dragHandler = function(x,_) --ignore y
      hsb.value = v0 + (x - x0_) * hsb.maxvalue / (hsb.size.x - 4)
      if hsb.value < 0 then hsb.value = 0 end
      if hsb.value > hsb.maxvalue then hsb.value = hsb.maxvalue end
      hsb._scrollbg:draw()
      hsb._scrollpart.pos.x = hsb.pos.x + 1 + (hsb.value / hsb.maxvalue) * (hsb.size.x - 4)
      hsb._scrollpart:draw()
    end 
    dropHandler = function() --unregister handlers
      dragHandler = nil
      dropHandler = nil
    end
  end
  hsb._scrollbg = thornsgui.Text:create(1, 1, string.rep(" ", hsb.size.x - 2)) -- pos is overwritten anyways
  return hsb
end

function thornsgui.HorizontalScrollbar:draw()
  self._scrollpart.pos.x = self.pos.x + 1 + (self.value / self.maxvalue) * (self.size.x - 4)
  self._scrollpart.pos.y = self.pos.y
  self._scrollbg.pos.y = self.pos.y
  self._scrollbg.pos.x = self.pos.x + 1
  self._leftbtn.pos.x = self.pos.x
  self._leftbtn.pos.y = self.pos.y
  self._rightbtn.pos.x = self.pos.x + self.size.x - 1
  self._rightbtn.pos.y = self.pos.y
  self._leftbtn:draw()
  self._rightbtn:draw()
  self._scrollbg:draw()
  self._scrollpart:draw()
end

thornsgui.ScrollContainer = {}
thornsgui.ScrollContainer.__index = thornsgui.ScrollContainer
--[[
 draw ^
 Area |
 spacev
 <--->  
]]
function thornsgui.ScrollContainer:create(element,xsize,ysize)
  local sc = {}
  setmetatable(sc, thornsgui.ScrollContainer)
  sc.pos = {x=1,y=1}
  sc.element = element
  sc.size = {x=xsize,y=ysize} -- fixed size of the container
  sc.hsb = thornsgui.HorizontalScrollbar:create(xsize - 1)
  sc.vsb = thornsgui.VerticalScrollbar:create(ysize - 1)
  sc.hsb.onScroll = function(value) -- todo 
  end
  sc.vsb.onScroll = function(value)
  end
  return sc
end

function thornsgui.ScrollContainer:draw()
  local oldgpu = gpu
  gpu = createFakeGPU(self.pos.x, self.pos.y, self.vsb.value+1, select.hsb.value +1,self.size.x, self.size.y)
  self.element:draw()
  gpu = oldgpu
  self.vsb.pos.x = self.size.x + self.pos.x - 1
  self.vsb.pos.y = self.pos.y
  self.vsb.maxvalue = self.element.size.y - self.size.y + 1
  if self.vsb.maxvalue < 0 then self.vsb.maxvalue = 0 end
  self.hsb.pos.x = self.pos.x
  self.hsb.pos.y = self.size.y + self.pos.y - 1
  self.hsb.maxvalue = self.element.size.x - self.size.x + 1
  if self.hsb.maxvalue < 0 then self.hsb.maxvalue = 0 end
  self.hsb:draw()
  self.vsb:draw()
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
    gpu.clickSensitive = {}
end
-- waits for and handels next click event
function thornsgui.handleNextEvent()
  local ev, _, x, y,  btn = event.pullMultiple("touch","drag","drop")
  -- if in sub window calc offset:
  if gpu.pos ~= nil then 
    local ox,oy = gpu.pos.x, gpu.pos.y
    x = x-ox+1
    y = y-oy+1
  end
  if ev == "touch" then
    for _,cs in pairs(gpu.clickSensitive) do
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
    gpu.setBackground(gpu.getPaletteColor(colors.white)) -- white per default
    if string.byte(ch) >= 48 and string.byte(ch) <= 57 then
      gpu.setBackground( gpu.getPaletteColor(string.byte(ch) - 48)) -- 0 .. 9
    end
    if string.byte(ch) >= 97 and string.byte(ch) <= 102 then
      gpu.setBackground( gpu.getPaletteColor(string.byte(ch) - 87)) -- a .. f
    end
    if ch ~= "\n" then 
      io.write(" ") 
    else
      io.write("\n")
    end 
  end
end

local function clrScr()
  local x,y = gpu.getResolution()
  gpu.fill(1,1,x,y," ")
end
--shows logo
function thornsgui.showLogo(t)
    gpu.setBackground(gpu.getPaletteColor(colors.white))
    clrScr()
    drawImage("/usr/lib/thornslogo")
    os.sleep(t)
    gpu.setBackground(gpu.getPaletteColor(colors.black))
    clrScr()
end
thornsgui.showLogo(0.4)

return thornsgui