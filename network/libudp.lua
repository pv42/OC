local libip = require("libip")

local libudp = {}

local UDP_PROTOCOL_ID = 17

local receiveHandlers = {}

function libudp.send(local_port, target_address, target_port, data)
	local package = {source_port = local_port, destination_port = target_port, data = data}
	libip.sendPackage(target_address, UDP_PROTOCOL_ID, package)
end

local function recivePackage(package)
	if(receiveHandlers[package.destination_port] ~= nil) then
		receiveHandlers[package.destination_port](package.data)
	end
end

function libip.addReceiveHandler(port, func)
	receiveHandlers[protocol_id] = func
end


libip.addRecieveHandler(UDP_PROTOCOL_ID,recivePackage)

return libudp