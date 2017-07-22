local MAX_DEATH = 55
local BATTERY_LOW = 6000
local x,y,death -- relative to start
death = 0
x = 0
y = -1
component = require("component")
robot = require("robot")
sides = require("sides")
shell = require("shell")
computer = require("computer")
local geo = component.geolyzer
args = shell.parse(...)

function main()
  local tx = 0
  local ty = 0  
  if #args > 1 then
    tx = tonumber(args[1])
    ty = tonumber(args[2])
  end
  goTo(tx,ty)
  mine()
end

function mine()
  print("Starting mining")
  hole()
  while robot.durability() > 0.1 do
    while computer.energy() > BATTERY_LOW and robot.durability()>0.1 do
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
      hole()
    end
    chargeAndEmpty()
  end
  goToStart()
  empty()
end

function shouldMine(blockName)
  --print(blockName)
  if blockName == "minecraft:stone" then 
    return false end
  if blockName == "minecraft:obsidian" then
    return false end
  if blockName == "minecraft:air" then
    return false end
  return true
end

function hole()
  print("Hole @ x=" .. x .. " y="  .. y)
  while death < MAX_DEATH do
    death = death + 1
    mv_fw()
    checkSurroundings()
  end
  print("Hole:returning")
  robot.turnAround()
  while death>0 do
    mv_fw()
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
  while y>0 do
    mv_dwn()
  end
  robot.turnRight()
  while x>0 do
    x = x-1
    mv_fw()
  end
  robot.turnLeft()
  mv_dwn()
end

function goTo(tx, ty)
  mv_up()
  while y < ty do
    mv_up()
  end
  robot.turnLeft()
  while x < tx do
    mv_fw()
    x = x+1
  end
  robot.turnRight()
end

function mv_fw()
  while not robot.forward() do
    robot.swing()
  end
end

function mv_up()
  while not robot.up() do 
    robot.swingUp()
  end
  y = y+1
end

function mv_dwn()
  while not robot.down() do
    robot.swingDown()
  end
  y = y-1
end
main()
--chargeAndEmpty()
