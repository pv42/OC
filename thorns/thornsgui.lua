local term = require("term")
local gpu = require("component").gpu
local colors = require("colors")
local thronsgui = {}

local function drawFilledBox(x,y,x_size,ysize,color)
  gpu.setBackground(color)
  gpu.fill(x,y,x_size,ysize," ")
end 
function thronsgui.createButton(x_pos,y_pos,x_size,y_size,text)
    local btn = {}
    btn.type = "button"
    btn.pos = {}
    btn.pos.x = x_pos
    btn.pos.y = y_pos
    btn.size = {}
    btn.size.x= x_size
    btn.size.y = y_size
    btn.color = {}
    btn.color.text = colors.white
    btn.color.bg = colors.gray
    btn.text=text 
    btn.onClick = function() end
    btn.draw=function () 
        --out.setCursorPos(1,1) --nessescary ?
        drawFilledBox(
            btn.pos.x,
            btn.pos.y,
            btn.pos.x + btn.size.x-1,
            btn.pos.y + btn.size.y-1,
            btn.color.bg
        )
        gpu.setForeground(btn.color.text)
        local len = #(btn.text)
        term.setCursor(btn.pos.x, btn.pos.y)
        term.write(btn.text)
    end
    btn.setPos = function(x_,y_)
        btn.pos.x = x_
        btn.pos.y = y_
    end
    btn.setColors = function(textc,backc)
        btn.color.bg = backc
        btn.color.text = textc
    end
    btn.handleClick = function (x,y)
        if(x >= btn.pos.x and y>= btn.pos.y and x < btn.pos.x + btn.size.x and y < btn.pos.y + btn.size.y) then
            if(btn.onClick ~= nil) then btn.onClick() end 
            return true
        else 
            return false
        end
    end
    btn.registerEventListener = function()
        table.insert(out.clickSensitive,btn)
    end
    btn.setOnClick = function(f)
        btn.onClick = f
    end
    return btn
end

return thronsgui