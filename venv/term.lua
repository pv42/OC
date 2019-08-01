require("init")
local component = require("component")
return { gpu = function()
  return component.gpu
end, clear = function()
  --os.execute("tput clear")
  component.gpu.fill(1,1,component.gpu.getResolution())
end }