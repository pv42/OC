local component = require("component")
local ENABLE_LOG = false
local log
if ENABLE_LOG then
  log = require("log")
  log.connectFile("/tmp/thorns_log")
end

local thornsgui = {}
thornsgui.SCROLLBAR_AUTO = 85 -- the values dont matter
thornsgui.SCROLLBAR_ALWAYS = 86
thornsgui.SCROLLBAR_NEVER = 87
local gpu = component.gpu
local event = require("event")
local dragHandler
local dropHandler
gpu.clickSensitive = {}
--
local white = 0xffffff
local light_gray = 0xbfbfbf
local gray = 0x7f7f7f
local dark_gray = 0x3f3f3f
local black = 0x000000

local function drawFilledBox(x, y, x_size, ysize, color)
  gpu.setBackground(color)
  gpu.fill(x, y, x_size, ysize, " ")
end

---creates a fake gpu with a draw area offset by x/y_pos, the draw areas top left has the coords x/y_start for inner purpusess, the draw areas size is limited to x/y_size
---the the last 4 args may all be nil
---@param x_pos number draw area x offset
---@param y_pos number draw area y offset
---@param x_start number draw area's (inner) left coordinate, may be nil
---@param y_start number draw area's (inner) top coordinate, may be nil
---@param x_size number draw area's x size, may be nil
---@param y_size number draw area's y size, may be nil
---@return table fake gpu table
local function createFakeGPU(x_pos, y_pos, x_start, y_start, x_size, y_size)
  checkArg(1, x_pos, "number")
  checkArg(2, y_pos, "number")
  local g = {}
  g.parent = gpu
  g.z = gpu.z or 0
  g.z = g.z + 1
  if g.z > 10 then
    error("to gpu stack limit reached")
  end
  if ENABLE_LOG then
    log.i("creating fake GPU at z=" .. g.z)
  end
  g.pos = { x = x_pos, y = y_pos }
  g.start = { x = x_start, y = y_start }
  g.setForeground = gpu.setForeground
  g.setBackground = gpu.setBackground
  g.getPaletteColor = gpu.getPaletteColor
  g.clickSensitive = {}
  if x_start then
    -- optional but you need both or none
    checkArg(3, x_start, "number", "nil") -- nil just for better print
    checkArg(4, y_start, "number")
    checkArg(5, x_size, "number")
    checkArg(6, y_size, "number")
    g.fill = function(x, y, xs, ys, c)
      if x > x_start + x_size - 1 or y > y_start + y_size - 1 then
        return
      end -- if lwr limit is oob discart
      if x + xs - 1 > x_size then
        xs = x_size - x + 1
      end -- upr clipping
      if y + ys - 1 > y_size then
        ys = y_size - y + 1
      end
      if x < x_start then
        -- lwr clipping
        x = x_start
        xs = xs + x_start - x
      end
      if y < y_start then
        y = y_start
        ys = ys + y_start - y
      end
      g.parent.fill(x + x_pos - x_start, y + y_pos - y_start, xs, ys, c)
    end
    g.set = function(x, y, text, flip)

      if ENABLE_LOG then
        log.i("fakegpu:set " .. x .. "," .. y .. " #=" .. #text)
      end
      if flip then
        error("flip not supported in limited fake gpus")
      end
      checkArg(1, x, "number")
      checkArg(1, x, "number")
      checkArg(1, x, "number")
      if x > x_start + x_size - 1 or y > y_start + y_size - 1 then
        return
      end -- if lwr limit is oob discart
      if x < x_start then
        -- x lwr clipping
        text = text:sub(1 + x_start - x)
      end -- upr x clipping 
      if #text > x_size - 1 + x_start - x then
        text = text:sub(1, x_start + x_size - x)
      end
      g.parent.set(x + x_pos - 1, y + y_pos - 1, text, false)
    end
    g.getResolution = function()
      return x_size - x_start + 1, y_size - y_start + 1
    end
  else
    -- unlimited draw area
    g.fill = function(x, y, xs, ys, c)
      g.parent.fill(x + x_pos - 1, y + y_pos - 1, xs, ys, c)
    end
    g.set = function(x, y, text, flip)
      g.parent.set(x + x_pos - 1, y + y_pos - 1, text, flip)
    end
  end
  return g
end

thornsgui.Button = {}
thornsgui.Button.__index = thornsgui.Button

---creates a Button with text
---@param x_pos number x position
---@param y_pos number y position
---@param x_size number x size
---@param y_size number y size
---@param text string buttons text
---@public
function thornsgui.Button:create(x_pos, y_pos, x_size, y_size, text)
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
  btn.size.x = x_size
  btn.size.y = y_size
  btn.color = {}
  btn.color.text = white
  btn.color.bg = light_gray
  btn.text = text
  btn.onClick = function()
  end -- should be overwriten
  table.insert(gpu.clickSensitive, btn)
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
function thornsgui.Button:handleClick(x, y)
  if x >= self.pos.x and y >= self.pos.y and x < self.pos.x + self.size.x and y < self.pos.y + self.size.y then
    if (self.onClick ~= nil) then
      self.onClick(x, y)
    end
    return true
  else
    return false
  end
end

thornsgui.Text = {}
thornsgui.Text.__index = thornsgui.Text

---create
---@param x number
---@param y number
---@param text string
function thornsgui.Text:create(x, y, text)
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
  txt.color.bg = white
  txt.color.text = black
  return txt
end

function thornsgui.Text:draw()
  if ENABLE_LOG then
    log.i("drawing text")
  end
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
  if ele.size.x > self.size.x then
    self.size.x = ele.size.x
  end
  self.size.y = self.size.y + ele.size.y
end

function thornsgui.VerticalView:removeElement(ele)
  checkArg(1, ele, "table")
  for i = 1, #(self.elements) do
    if ele == self.elements[i] then
      table.remove(self.elements, i)
    end
  end
  self.size.y = self.size.y - ele.size.y
end

function thornsgui.VerticalView:draw()
  local cx = self.pos.x
  local cy = self.pos.y
  for _, ele in pairs(self.elements) do
    ele.pos.x = cx
    ele.pos.y = cy
    ele:draw()
    cy = cy + ele.size.y
  end
end

-- clear the views part of the screem  
function thornsgui.VerticalView:clear(color)
  color = color or white
  gpu.setBackground(color)
  gpu.fill(self.pos.x, self.pos.y, self.size.x, self.size.y, " ")
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
  if ele.size.y > self.size.y then
    self.size.y = ele.size.y
  end
  self.size.x = self.size.x + ele.size.x
end

function thornsgui.HorizontalView:draw()
  local cx = self.pos.x
  local cy = self.pos.y
  for _, ele in pairs(self.elements) do
    ele.pos.x = cx
    ele.pos.y = cy
    ele:draw()
    cx = cx + ele.size.x
  end
end

thornsgui.Custom = {}
thornsgui.Custom.__index = thornsgui.Custom

function thornsgui.Custom:create(xsize, ysize, drawfunc)
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
  if ENABLE_LOG then
    log.i("drawing hsb")
  end
  self.drawfunc(createFakeGPU(self.pos.x, self.pos.y))
end

function thornsgui.Custom:handleClick(x, y, btn)
  checkArg(1, x, "number")
  checkArg(2, y, "number")
  if x >= self.pos.x and y >= self.pos.y and x < self.pos.x + self.size.x and y < self.pos.y + self.size.y then
    if (self.onClick ~= nil) then
      self.onClick(x, y, btn)
    end
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
  vsb.onScroll = function()
  end -- change this; value is float
  vsb.value = 0
  vsb.maxvalue = 1
  vsb._topbtn = thornsgui.Button:create(vsb.pos.x, vsb.pos.y, 1, 1, "^")
  vsb._topbtn.onClick = function()
    vsb.value = vsb.value - 1
    vsb:_mOnScroll()
  end
  vsb._btmbtn = thornsgui.Button:create(vsb.pos.x + vsb.size.x - 1, vsb.pos.y, 1, 1, "v")
  vsb._btmbtn.onClick = function()
    vsb.value = vsb.value + 1
    vsb:_mOnScroll()
  end
  vsb._scrollpart = thornsgui.Button:create(1, 1, 1, 1, " ") -- pos is overwritten anyways
  vsb._scrollpart.onClick = function(_, y0)
    --ignore x
    checkArg(2, y0, "number")
    local v0 = vsb.value
    local y0_ = y0
    vsb._scrollpart.color.bg = dark_gray
    vsb._scrollpart:draw()
    dragHandler = function(_, y)
      --ignore y
      vsb.value = v0 + (y - y0_) * vsb.maxvalue / (vsb.size.y - 4)
      vsb:_mOnScroll()
    end
    dropHandler = function()
      --unregister handlers
      vsb._scrollpart.color.bg = light_gray
      vsb._scrollpart:draw()
      dragHandler = nil
      dropHandler = nil
    end
  end
  return vsb
end

-- private
function thornsgui.VerticalScrollbar:_mOnScroll()
  if self.value < 0 then
    self.value = 0
  end
  if self.value > self.maxvalue then
    self.value = self.maxvalue
  end
  self.onScroll(self.value)
  -- draw
  if self.maxvalue == 0 then
    self._scrollpart.pos.y = self.pos.y + 1
  else
    self._scrollpart.pos.y = self.pos.y + 1 + (self.value / self.maxvalue) * (self.size.y - 3)
  end
  drawFilledBox(self.pos.x, self.pos.y + 1, 1, self.size.y - 2, white) -- scroll bg
  self._scrollpart:draw()
end

function thornsgui.VerticalScrollbar:draw()
  if ENABLE_LOG then
    log.i("drawing vsb")
  end

  self._scrollpart.pos.x = self.pos.x
  if self.maxvalue == 0 then
    self._scrollpart.pos.y = self.pos.y + 1
  else
    self._scrollpart.pos.y = self.pos.y + 1 + (self.value / self.maxvalue) * (self.size.y - 3)
  end
  self._topbtn.pos.x = self.pos.x
  self._topbtn.pos.y = self.pos.y
  self._btmbtn.pos.x = self.pos.x
  self._btmbtn.pos.y = self.pos.y + self.size.y - 1
  self._topbtn:draw()
  self._btmbtn:draw()
  drawFilledBox(self.pos.x, self.pos.y + 1, 1, self.size.y - 2, white) -- scroll bg
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
  hsb.onScroll = function()
  end -- change this; value is float
  hsb.value = 0 -- float
  hsb.maxvalue = 1
  hsb._leftbtn = thornsgui.Button:create(hsb.pos.x, hsb.pos.y, 1, 1, "<")
  hsb._leftbtn.onClick = function()
    hsb.value = hsb.value - 1
    hsb:_mOnScroll()
  end
  hsb._rightbtn = thornsgui.Button:create(hsb.pos.x + hsb.size.x - 1, hsb.pos.y, 1, 1, ">")
  hsb._rightbtn.onClick = function()
    hsb.value = hsb.value + 1
    hsb:_mOnScroll()
  end
  hsb._scrollpart = thornsgui.Button:create(2, 1, 2, 1, "  ") -- pos is overwritten anyways
  hsb._scrollpart.onClick = function(x0, _)
    --ignore y
    checkArg(1, x0, "number")
    local v0 = hsb.value
    local x0_ = x0
    hsb._scrollpart.color.bg = dark_gray
    dragHandler = function(x, _)
      --ignore y
      hsb.value = v0 + (x - x0_) * hsb.maxvalue / (hsb.size.x - 4)
      hsb:_mOnScroll()
    end
    dropHandler = function()
      --unregister handlers
      hsb._scrollpart.color.bg = light_gray
      dragHandler = nil
      dropHandler = nil
    end
  end
  --hsb._scrollbg = thornsgui.Text:create(1, 1, string.rep(" ", hsb.size.x - 2)) -- pos is overwritten anyways
  return hsb
end

-- private
function thornsgui.HorizontalScrollbar:_mOnScroll()
  if self.value < 0 then
    self.value = 0
  end
  if self.value > self.maxvalue then
    self.value = self.maxvalue
  end
  self.onScroll(self.value)
  -- draw
  if self.maxvalue == 0 then
    self._scrollpart.pos.x = self.pos.x + 1
  else
    self._scrollpart.pos.x = self.pos.x + 1 + (self.value / self.maxvalue) * (self.size.y - 4)
  end
  drawFilledBox(self.pos.x + 1, self.pos.y, self.size.x - 2, 1, white) -- scroll bg
  self._scrollpart:draw()
end

function thornsgui.HorizontalScrollbar:draw()
  if ENABLE_LOG then
    log.i("drawing hsb")
  end
  self._scrollpart.pos.x = self.pos.x + 1 + (self.value / self.maxvalue) * (self.size.x - 4)
  self._scrollpart.pos.y = self.pos.y
  self._leftbtn.pos.x = self.pos.x
  self._leftbtn.pos.y = self.pos.y
  self._rightbtn.pos.x = self.pos.x + self.size.x - 1
  self._rightbtn.pos.y = self.pos.y
  self._leftbtn:draw()
  self._rightbtn:draw()
  drawFilledBox(self.pos.x + 1, self.pos.y, self.size.x - 2, 1, white) -- scroll bg
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
function thornsgui.ScrollContainer:create(element, xsize, ysize)
  checkArg(1, element, "table")
  checkArg(2, xsize, "number")
  checkArg(3, ysize, "number")
  local sc = {}
  setmetatable(sc, thornsgui.ScrollContainer)
  sc.pos = { x = 1, y = 1 }
  sc.element = element
  sc.size = { x = xsize, y = ysize } -- fixed size of the container
  sc.hsb = thornsgui.HorizontalScrollbar:create(xsize - 1)
  sc.vsb = thornsgui.VerticalScrollbar:create(ysize - 1)
  sc.hsb.onScroll = function(value)
    -- redraw element
    gpu.fill(sc.pos.x, sc.pos.y, sc.size.x - 1, sc.size.y - 1, " ") -- clear element area
    local old_gpu = gpu
    gpu = createFakeGPU(sc.pos.x, sc.pos.y, sc.vsb.value + 1, value + 1, sc.size.x - 1, sc.size.y - 1)
    sc.element:draw()
    for _, v in pairs(gpu.clickSensitive) do
      -- register listeners properly
      local fe = {}
      fe.onClick = function(x, y, b)
        v.onClick(x - gpu.pos.x + gpu.start.x, y - gpu.pos.y + gpu.start.y, b)
      end
      table.insert(old_gpu.clickSensitive, fe)
    end
    gpu = old_gpu
  end
  sc.vsb.onScroll = function(value)
    gpu.fill(sc.pos.x, sc.pos.y, sc.size.x - 1, sc.size.y - 1, " ") -- clear element area
    local old_gpu = gpu
    gpu = createFakeGPU(sc.pos.x, sc.pos.y, value + 1, sc.hsb.value + 1, sc.size.x - 1, sc.size.y - 1)
    sc.element:draw()
    for _, v in pairs(gpu.clickSensitive) do
      -- register listeners properly
      local fe = {}
      fe.onClick = function(x, y, b)
        v.onClick(x - gpu.pos.x + gpu.start.x, y - gpu.pos.y + gpu.start.y, b)
      end
      table.insert(old_gpu.clickSensitive, fe)
    end
    gpu = old_gpu
  end
  if ENABLE_LOG then
    log.i("scrollContainer created")
  end
  return sc
end

function thornsgui.ScrollContainer:draw()
  if ENABLE_LOG then
    log.i("drawing scroll container")
  end
  local old_gpu = gpu
  gpu = createFakeGPU(self.pos.x, self.pos.y, self.hsb.value + 1, self.vsb.value + 1, self.size.x - 1, self.size.y - 1)
  self.element:draw()
  for _, v in pairs(gpu.clickSensitive) do
    -- register listeners properly
    local fe = {}
    fe.onClick = function(x, y, b)
      v.onClick(x - gpu.pos.x + gpu.start.x, y - gpu.pos.y + gpu.start.y, b)
    end
    table.insert(old_gpu.clickSensitive, fe)
  end
  gpu = old_gpu
  self.vsb.pos.x = self.size.x + self.pos.x - 1
  self.vsb.pos.y = self.pos.y
  self.vsb.maxvalue = self.element.size.y - self.size.y + 1
  if self.vsb.maxvalue < 0 then
    self.vsb.maxvalue = 0
  end
  self.hsb.pos.x = self.pos.x
  self.hsb.pos.y = self.size.y + self.pos.y - 1
  self.hsb.maxvalue = self.element.size.x - self.size.x + 1
  if self.hsb.maxvalue < 0 then
    self.hsb.maxvalue = 0
  end
  self.hsb:draw()
  self.vsb:draw()
end

thornsgui.Table = {}
thornsgui.Table.__index = thornsgui.Table

function thornsgui.Table:create(dim_x, dim_y, x_pos, y_pos)
  local tbl = {}
  setmetatable(tbl, thornsgui.Table)
  tbl.type = "table"
  tbl.dim = { dim_x, dim_y }
  tbl.pos = {}
  tbl.pos.x = x_pos
  tbl.pos.y = y_pos
  tbl.elements = {}
  for i = 1, dim_x do
    tbl.elements[i] = {}
  end
  tbl.setColors = function(txtc, backc, type)
    -- optional:type(string) only color a type of subelements
    for i = 1, tbl.dim[1] do
      for j = 1, tbl.dim[2] do
        if (tbl.elements[i][j] ~= nil) then
          if (type == nil or tbl.elements[i][j].type == type) then
            tbl.elements[i][j].setColors(txtc, backc)
          end
        end
      end
    end
  end
  tbl.size = function()
    error("//TODO")
  end
  return tbl
end

function thornsgui.Table:draw()
  local cx = self.pos.x
  local mx = {}
  local my = {}
  for i = 1, self.dim[1] do
    for j = 1, self.dim[2] do
      if (self.elements[i][j] ~= nil) then
        if mx[i] == nil then
          mx[i] = self.elements[i][j].size.x
        else
          mx[i] = math.max(mx[i], self.elements[i][j].size.x)
        end
        if my[j] == nil then
          my[j] = self.elements[i][j].size.y
        else
          my[j] = math.max(my[j], self.elements[i][j].size.y)
        end
      end
      if (i == self.dim[1] and my[j] == nil) then
        my[j] = 0
      end --empty
    end
    if (mx[i] == nil) then
      mx[i] = 0
    end --empty
  end
  for i = 1, self.dim[1] do
    local cy = self.pos.y
    for j = 1, self.dim[2] do
      if (self.elements[i][j] ~= nil) then
        self.elements[i][j].pos.x=cx
        self.elements[i][j].pos.y=cy
        self.elements[i][j]:draw()
      end
      cy = cy + my[j]
    end
    cx = cx + mx[i]
  end
end

function thornsgui.Table:setElement(x, y, element)
  if (x > self.dim[1] or x < 1 or y > self.dim[2] or y < 1) then
    error("Index(" .. x .. "," .. y .. ") out of boundaries: " .. self.dim[1] .. "," .. self.dim[2])
  end
  self.elements[x][y] = element
end

--[[
function thornsgui.createDropdownSelector(x, y)
  dds = {}
  dds.type = "dropdownselector"
  dds.pos = {}
  dds.pos.x = x
  dds.pos.y = y
  dds.size = {}
  dds.size.x = 1
  dds.size.y = 1
  dds.options = {}
  dds.selected = 1
  dds.addOption = function(text)
    opt = createButton(1, 1, string.len(text), 1, text)
    opt.setColors(colors.black, colors.white)
    opt.setPos(dds.pos.x, dds.pos.y)
    table.insert(dds.options, opt)
    dds.size.x = math.max(dds.size.x, opt.size.x + 1)
    dds.size.y = math.max(dds.size.y, opt.size.y)
  end
  dds.draw = function()
    if (#(dds.options) == 0) then
      error("At least one option required")
    end
    if (dds.selectBtn == nil) then
      --init selectButton
      -- +dds.size.x-1
      dds.selectBtn = createButton(dds.pos.x + dds.size.x - 1, dds.pos.y, 1, 1, "v")
      local fx = function()
        if dds.ddw == nil then
          offset_x, offset_y = 0, 0
          if out.getPosition ~= nil then
            offset_x, offset_y = out.getPosition()
            offset_x = offset_x - 1
            offset_y = offset_y - 1
          end
          dds.ddw = window.create(term_c, dds.pos.x + offset_x, dds.pos.y + 1 + offset_y, dds.size.x - 1, #(dds.options), false)
          dds.ddw.setBackgroundColor(colors.white)
          dds.ddw.clear()
          dds.ddw.visible = false

        end
        dds.ddw.visible = not dds.ddw.visible
        dds.ddw.setVisible(dds.ddw.visible)
        if (dds.ddw.visible) then
          dds.ddw.parent = out
          setOutput(dds.ddw)
          for i = 1, #(dds.options) do
            dds.options[i].setPos(1, i)
            dds.options[i].setOnClick(function()
              dds.selected = i
              dds.ddw.visible = not dds.ddw.visible
              dds.ddw.setVisible(dds.ddw.visible)
              setOutput(dds.ddw.parent)
              drawFilledBox(dds.pos.x, dds.pos.y, dds.pos.x + dds.size.x - 2, dds.pos.y + dds.size.y - 1, colors.white)--clear space
              dds.options[dds.selected].setPos(dds.pos.x, dds.pos.y)
              dds.options[dds.selected].draw()
              out.redraw()
              if (dds.onChange ~= nil) then
                dds.onChange(i, dds.options[i].text)
              end
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
    drawFilledBox(dds.pos.x, dds.pos.y, dds.pos.x + dds.size.x - 2, dds.pos.y + dds.size.y - 1, colors.white)--clear space
    dds.options[dds.selected].draw()
    dds.selectBtn.draw()
  end
  dds.setOnChange = function(f)
    dds.onChange = f
  end
  dds.setSelected = function(s)
    if (type(s) == "string") then
      for i = 1, #(dds.options) do
        if (dds.options[i].text == s) then
          s = i
          break
        end
      end
      if type(s) == string then
        error("no valid option given")
        return
      end
    end
    if (s > #(dds.options) or s < 1) then
      error("out of range")
    end
    dds.selected = s
  end
  return dds
end

function thornsgui.createTextBox(x_pos, y_pos, x_size, y_size)
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
    drawFilledBox(tb.pos.x, tb.pos.y, tb.pos.x + tb.size.x - 1, tb.pos.y + tb.size.y - 1, out.gpu().getPaletteColor(colors.black))
    out.setCursor(tb.pos.x, tb.pos.y)
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
local g = gpu
while g do
g.clickSensitive = {}
g = g.parent
end
if ENABLE_LOG then
log.i("click listeners cleared")
end
end
-- waits for and handels next click event
function thornsgui.handleNextEvent()
local ev, _, x, y, btn = event.pullMultiple("touch", "drag", "drop")
-- if in sub window calc offset:
if gpu.pos ~= nil then
local ox, oy = gpu.pos.x, gpu.pos.y
x = x - ox + 1
y = y - oy + 1
end
if ev == "touch" then
for _, cs in pairs(gpu.clickSensitive) do
if (cs:handleClick(x, y, btn)) then
break
end
end
elseif ev == "drag" then
if dragHandler then
dragHandler(x, y)
end
elseif ev == "drop" then
if dropHandler then
dropHandler(x, y)
end
end
end

local function drawImage(file)
local f, msg = io.open(file)
if not f then
if ENABLE_LOG then
log.e(msg)
end
return
end
local cont = f:read("a*")
for i = 1, #cont do
local ch = string.sub(cont, i, i)
gpu.setBackground(white) -- white per default
if string.byte(ch) >= 48 and string.byte(ch) <= 57 then
gpu.setBackground(gpu.getPaletteColor(string.byte(ch) - 48)) -- 0 .. 9
end
if string.byte(ch) >= 97 and string.byte(ch) <= 102 then
gpu.setBackground(gpu.getPaletteColor(string.byte(ch) - 87)) -- a .. f
end
if ch ~= "\n" then
io.write(" ")
else
io.write("\n")
end
end
end

function thornsgui.resetGPU()
gpu = component.gpu
end

local function clrScr()
local x, y = gpu.getResolution()
gpu.fill(1, 1, x, y, " ")
end
--shows logo
function thornsgui.showLogo(t)
gpu.setBackground(white)
clrScr()
drawImage("/usr/lib/thornslogo")
if os.sleep then
os.sleep(t)
end -- for venv
gpu.setBackground(black)
clrScr()
end
thornsgui.showLogo(0.4)

if ENABLE_LOG then
log.i("ThornsGUI loaded")
end
return thornsgui