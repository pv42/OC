-- Mine by pv42 
-- version 1.2.26
-- config
local MAX_depth = 58
local MAX_X = 50
local BATTERY_LOW = 6000
local DURABILITY_LOW = 0.1
local MINE_BLACKLIST = {"minecraft:stone", "minecraft:cobblestone", "minecraft:torch", "minecraft:air", "minecraft:water", "minecraft:flowing_water", "minecraft:lava", "minecraft:flowing_lava"}
-- dont change 
local x,y,depth -- relative to start

depth = 0
x = 0
y = -1
component = require("component")
robot = require("robot")
sides = require("sides")
shell = require("shell")
computer = require("computer")
math = require("math")
local inv = component.inventory_controller
local geo = component.geolyzer
local angel = false
local args = shell.parse(...)

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
  goTo(tx,ty)
  mine()
end

function hasAngel( ... )
  local solarGenDetected = false
  for addr, info in pairs(computer.getDeviceInfo()) do
    if info.class == "generic" and info.description == "Angel upgrade" then
      solarGenDetected = true
      break
    end
  end
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
    if (y%3)>1 then 
      mv_dwn()
      mv_dwn()
      x = x+1
    else 
      mv_fw()
      mv_up()
      x = x+2
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
    placeDown()
    checkSurroundings()
  end
  print("Hole:returning")
  robot.turnAround()
  while depth>0 do
    mv_fw()
    depth = depth - 1
  end
  robot.turnAround()
end

function checkSurroundings()
  if shouldMine(geo.analyze(sides.up).name) then
    robot.swingUp() end
  if shouldMine(geo.analyze(sides.down).name) then
    robot.swingDown() end 
  if shouldMine(geo.analyze(sides.left).name) then 
    robot.turnLeft()
    robot.swing()
    robot.turnRight()
  end
  if shouldMine(geo.analyze(sides.right).name) then
    robot.turnRight()
    robot.swing()
    robot.turnLeft()
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
  end
  robot.turnRight()
  while x>tx do
    x = x-1
    mv_fw()
  end
  robot.turnLeft()
  robot.turnLeft()
  while x < tx do
    mv_fw()
    x = x+1
  end
  robot.turnRight()
  while y > ty do
    mv_dwn()
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
