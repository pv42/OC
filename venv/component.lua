local function gettputcolor(rgb)
  if rgb == 0 then
    return 0
  elseif rgb == 0xffffff then
    return 15
  elseif rgb == 0xff0000 then
    return 9
  else
    return 7
  end
end

return { gpu = {
  setBackground = function(color)
    os.execute("tput setab " .. gettputcolor(color))
  end,
  setForeground = function(color)
    os.execute("tput setaf " .. gettputcolor(color))
  end,
  getResolution = function()
    return tonumber(io.popen("tput cols"):read()), tonumber(io.popen("tput lines"):read())
  end,
  fill = function(x, y, xs, ys)
    --check for nan
    if x ~= x then
      return
    end
    if y ~= y then
      return
    end
    if type(x) ~= "number" then
      return
    end
    if type(y) ~= "number" then
      return
    end
    for i = y, y + ys - 1 do
      os.execute("tput cup " .. i - 1 .. " " .. x - 1)
      io.write(string.rep(" ", xs))
      io.flush()
    end
  end,
  set = function(x, y, text)
    if x ~= x then
      return
    end --check for nan
    if y ~= y then
      return
    end --check for nan
    if type(x) ~= "number" then
      return
    end
    if type(y) ~= "number" then
      return
    end
    os.execute("tput cup " .. y - 1 .. " " .. x - 1)
    --print(text)
    io.write(text)
    io.flush()
  end
}, modem = { address = math.random() },
         isAvailable = function(comp)
           if comp == "modem" then
             return true
           else
             return false
           end
         end,
         me_interface = {
           getItemsInNetwork = function()
             return {
               { damage = 0, hasTag = false, isCraftable = false, label = "Stone", name = "minecraft:stone", maxDamage = 0, maxSize = 64, size = 106572 }
             }
           end,
           getCraftables = function ()
             return {
               {getItemStack = function()
                 return { damage = 0, hasTag = false, isCraftable = false, label = "Sand", name = "minecraft:sand", maxDamage = 0, maxSize = 64, size = 1}
               end }
             }
           end
         }
}