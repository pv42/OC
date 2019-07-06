robot = require("robot")

function main()
	while true do
		sandSlot = getItem("minecraft:soulsand", 4)
		skullSlot = getItem("minecraft:skull", 4)
		goIn()
		placeWither()
		goOut()
	end
end

function placeWither(sandSlot, skullSlot)
	robot.up()
	robot.select(skellSlot)
	robot.placeDown()
	robot.turnLeft()
	robot.place()
	robot.turnAround()
	robot.place()
	robot.up()
	robot.placeDown()
	robot.select(skullSlot)
	robot.place()
	robot.turnAround()
	robot.place()
	robot.up()
	robot.place()
	robot.turnRight()
	print("WARNING WITHER INCOMMING")
	robot.placeDown()
end


function goIn()
	print("TODO goIn")
end

function goOut()
	print("TODO goOut")
end

function getItem(id, count)
	print("getting " count .. "x" .. id)
	while false do
	end
	return 0
end
