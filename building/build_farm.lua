require("robot")
robot.select(1)
for i = 1,11 do
	for j = 1,11 do
		if j == 1 or j == 11 or i == 1 or i == 11 then
			robot.select(1)
		else 
			robot.select(11)
		end
		robot.placeDown()
		robot.forward()
	end
	robot.turnAround()
	for j = 1,11 do
		robot.forward()
	end
	robot.turnLeft()
	robot.forward
	robot.turnLeft()
end

