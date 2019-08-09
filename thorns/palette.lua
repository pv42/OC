local gpu = require("component").gpu
for i = 0, 15 do
  local color = gpu.getPaletteColor(i)
  gpu.setBackground(color)
  if color > 0x7fffff then
    gpu.setForeground(0x0)
  else
    gpu.setForeground(0xffffff)
  end
  print(string.format("%02d: 0x%x", i, color))
end