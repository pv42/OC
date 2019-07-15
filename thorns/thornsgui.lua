local term = require("term")
local colors = require("colors")
local thornsgui = {}
local out = term

local function drawFilledBox(x,y,x_size,ysize,color)
  out.gpu().setBackground(color)
  out.gpu().fill(x,y,x_size,ysize," ")
end 
function thornsgui.createButton(x_pos,y_pos,x_size,y_size,text)
  local btn = {}
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
  btn.onClick = function() end
  btn.draw = function() 
    --out.setCursorPos(1,1) --nessescary ?
    drawFilledBox(
      btn.pos.x,
      btn.pos.y,
      btn.size.x,
      btn.size.y,
      btn.color.bg
    )
    out.gpu().setForeground(btn.color.text)
    local len = #(btn.text)
    out.setCursor(btn.pos.x, btn.pos.y)
    out.write(btn.text)
  end
  btn.handleClick = function (x,y)
    if x >= btn.pos.x and y>= btn.pos.y and x < btn.pos.x + btn.size.x and y < btn.pos.y + btn.size.y then
      if(btn.onClick ~= nil) then btn.onClick() end 
      return true
    else 
      return false
    end
  end
  btn.registerEventListener = function()
    table.insert(out.clickSensitive,btn)
  end
  return btn
end

function thornsgui.createText(x,y,text)
    txt = {}
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
    txt.draw = function()
        out.setBackgroundColor(txt.color.bg)
        out.setTextColor(txt.color.text)
        out.setCursorPos(txt.pos.x, txt.pos.y)
        out.write(text)
    end
    return txt
end

function thornsgui.createTable(dim_x,dim_y,x_pos,y_pos)
    local tbl = {}
    tbl.type = "table"
    tbl.dim = {dim_x,dim_y}
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

-- clears current out-pipes clickSensitive-mem
function thornsgui.clearClickListeners()
    out.clickSensitive = {}
end
-- waits for and handels next click event
function thornsgui.handleNextEvent()
    local ev, comp, x, y,  btn = os.pullEvent("touch")
    -- if in sub window calc offset:
    if out.getPosition ~= nil then 
        local ox,oy = out.getPosition()
        x = x-ox+1
        y = y-oy+1
    end
    for a,b in pairs(out.clickSensitive) do
        if(b.handleClick(x,y)) then break end
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