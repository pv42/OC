local libip = require("libip")

local libudp = {}

local UDP_PROTOCOL_ID = 17

local receiveHandlers = {}

--public
function libudp.send(local_port, target_port, target_address, data)
  if(type(local_port)  ~= "number" or type(target_port)  ~= "number") then error("port must be a number") end
  local package = {source_port = local_port, destination_port = target_port, data = data}
  libip.sendIpPackage(target_address, UDP_PROTOCOL_ID, package)
end

local function recivePackage(package, source_ip, source_mac)
	if(receiveHandlers[package.destination_port] ~= nil) then
		receiveHandlers[package.destination_port](package.data, source_ip, source_mac)
	end
end

--public
function libudp.addReceiveHandler(port, func)
	if(type(port) ~= "number") then error("port must be a number") end
	if(type(func) ~= "function" and func ~= nil) then error("handler must be a function or nil") end
	receiveHandlers[port] = func
end


libip.addReceiveHandler(UDP_PROTOCOL_ID,recivePackage)
return libudp