-- Mine by pv42 
-- version 1.2.26
-- config
local MAX_depth = 58
local MAX_X = 50
local BATTERY_LOW = 20000
local DURABILITY_LOW = 0.1
local MINE_BLACKLIST = {"minecraft:stone", "minecraft:cobblestone", "minecraft:torch", "minecraft:air", "minecraft:water", "minecraft:flowing_water", "minecraft:lava", "minecraft:flowing_lava"}
-- dont change 
local x,y,depth -- relative to start

depth = 0
x = 0
y = -1
local component = require("component")
local robot = require("robot")
local sides = require("sides")
local shell = require("shell")
local computer = require("computer")
local math = require("math")
local inv = component.inventory_controller
local geo = component.geolyzer
local msg, libwdb = pcall(require,"libwdb")
local msg, libgps 

local gx,gy,gz
local grot

if not libwdb then 
  print("libwdb could not be loaded, disabling: " .. msg)
else
  msg, libgps = pcall(require,"libwdb")
  if not libgps then
    print("libgps could not be loaded, disabling: " .. msg)
    libwdb = nil
  else
    gx,gy,gz = gps.locate()
    gy = gy + 1
    if not gx then
      print("can't determine position") 
      libwdb = nil
    else 
      -- determine rotation
      mv_fw() -- z++
      dx,dy,dz = gps.locate()
      if dz > gz then grot = 0 -- z+ -> gz +
      elseif dx > gx then grot = 1 -- z+ -> gx +
      elseif dz < gz then grot = 2 -- z+ -> gz-
      elseif dz < gz then grot = 3 end -- z+ -> gx -
    end
  end
end

local function getGX(x,z) 
  if grot == 0 then return gx + x
  elseif grot == 1 then return gx + z 
  elseif grot == 2 then return gx - x 
  elseif grot == 3 then return gx - z end
end

local function getGZ(x,z) 
  if grot == 0 then return gz + z
  elseif grot == 1 then return gz - x 
  elseif grot == 2 then return gz - z
  elseif grot == 3 then return gz + x end
end


local angel = false
local args = shell.parse(...)

function sendAir(z)
 if not libwdb then return end
 if not z then z = 0 end
 libwdb.sendBlock(getGX(x,z),y,getGZ(x,z),"minecraft:air") 
end

function hasAngel( ... )
  local angelDetected = false
  for addr, info in pairs(computer.getDeviceInfo()) do
    if info.class == "generic" and info.description == "Angel upgrade" then
      angelDetected = true
      break
    end
  end
end

function main()
  print("Mine v1.2.26")
  angel = hasAngel()
  local tx = 0
  local ty = 0  
  if #args > 1 then
    tx = tonumber(args[1])
    ty = tonumber(args[2])
  end
  print("Starting @ " .. tx .. ", " .. ty)
  os.sleep(2)
  if libwdb then libwdb.connect() end
  goTo(tx,ty)
  mine()
  if libwdb then libwdb.disconnect() end
end

function mine()
  print("Starting mining")
  while robot.durability() > DURABILITY_LOW do
    hole()
    if computer.energy() <= BATTERY_LOW then chargeAndEmpty() end
    goToNextHole()
  end
  goToStart()
  empty()
end

function goToNextHole()
  if x >= MAX_X - 1 then 
    floor = math.floor(y/3) + 1
    goTo(floor % 3, 3 * floor) 
  else 
    robot.turnLeft() 
    mv_fw()
    x = x+1
    sendAir()
    if (y%3)>1 then 
      mv_dwn()
      sendAir()
      mv_dwn()
      sendAir()
    else 
      mv_fw()
      x = x+1
      sendAir()
      mv_up()
      sendAir()
    end
    robot.turnRight()
  end
end

function shouldMine(blockName)
  for i,name in ipairs(MINE_BLACKLIST) do 
    if blockName == name then return false end
  end 
  return true
end

function hole()
  print("Hole @ x=" .. x .. " y="  .. y)
  while depth < MAX_depth do
    depth = depth + 1
    mv_fw()
    sendAir(depth)
    placeDown()
    checkSurroundings(depth)
  end
  print("Hole:returning")
  robot.turnAround()
  while depth>0 do
    mv_fw()
    sendAir(depth)
    depth = depth - 1
  end
  robot.turnAround()
end

function checkSurroundings(depth)
  local u = geo.analyze(sides.up).name
  local d = geo.analyze(sides.down).name
  local l = geo.analyze(sides.left).name
  local r = geo.analyze(sides.right).name
  if shouldMine(u) then
    robot.swingUp() 
    if libwdb then libwdb.sendBlock(getGX(x,depth), y+1, getGZ(x,depth), "air") end
  else
    if libwdb then libwdb.sendBlock(getGX(x,depth), y+1, getGZ(x,depth), u) end
  end
  if shouldMine(d) then
    robot.swingDown() 
    if libwdb then libwdb.sendBlock(getGX(x,depth), y-1, getGZ(x,depth), "air") end
  else
    if libwdb then libwdb.sendBlock(getGX(x,depth), y-1, getGZ(x,depth), d) end
  end
  if shouldMine(l) then 
    robot.turnLeft()
    robot.swing()
    robot.turnRight()
    if libwdb then libwdb.sendBlock(getGX(x+1,depth), y, getGZ(x+1,depth), "air") end
  else
    if libwdb then libwdb.sendBlock(getGX(x+1,depth), y, getGZ(x+1,depth), l) end
  end
  if shouldMine(r) then
    robot.turnRight()
    robot.swing()
    robot.turnLeft()
    if libwdb then libwdb.sendBlock(getGX(x-1,depth), y, getGZ(x-1,depth), "air") end
  else
    if libwdb then libwdb.sendBlock(getGX(x-1,depth), y, getGZ(x-1,depth), r) end
  end
end

function empty()
  print("emptying")
  robot.turnRight()
  for slot = 1,robot.inventorySize() do
    robot.select(slot)
    robot.drop()
  end
  robot.drop()
  robot.turnLeft()
end

function chargeAndEmpty()
  print("back to charge/empty")
  local ox = x
  local oy = y
  goToStart()
  empty()
  while not (computer.energy() > (0.95 * computer.maxEnergy())) do
    os.sleep(3)
  end
  print("fully charged")
  goTo(ox,oy)
end

function goToStart()
  goTo(0,-1)
  print("went to start")
end

function goTo(tx, ty)
  while y < ty do
    mv_up()
    sendAir()
  end
  robot.turnRight()
  while x>tx do
    x = x-1
    mv_fw()
    sendAir()
  end
  robot.turnLeft()
  robot.turnLeft()
  while x < tx do
    mv_fw()
    x = x+1
    sendAir()
  end
  robot.turnRight()
  while y > ty do
    mv_dwn()
    sendAir()
  end
end

function mv_fw()
  local sucses, reason = robot.forward()
  while not sucses do
    robot.swing()
    sucses, reason = robot.forward()
    if reason == "impossible move" then
      placeDown()
    end
  end
end

function mv_up()
  local sucses, reason = robot.up()
  while not sucses do 
    robot.swingUp()
    sucses, reason = robot.up()
  end
  y = y+1
end

function mv_dwn()
  local sucses, reason = robot.down()
  while not sucses do
    sucses, reason = robot.down()
    robot.swingDown()
  end
  y = y-1
end

function placeDown()
  for slot = 1,robot.inventorySize() do
    if inv.getStackInInternalSlot(slot) ~= nil then
      name = inv.getStackInInternalSlot(slot).name
      if name == "minecraft:stone" or name == "minecraft:cobblestone" then 
        robot.select(slot)
        break
      end
    end  
  end
  robot.placeDown()
end

main()
