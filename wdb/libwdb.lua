local libip = require("libip")
local libdns = require("libdns")
local libudp = require("libudp")

local conn = nil

local server = "SERVER"
local server_ip = nil
local libwdb = {}

libwdb.PORT = 97

function libwdb.sendBlock(x,y,z, block)
	libudp.send(libwdb.PORT, libwdb.PORT, server_ip, {x=x,y=y,z=z,block=block})
end

function libwdb.connect()
	-- resolve dns
	server_ip = libdns.resolveDNS(server)
end

function libwdb.disconnect() 
	server_ip = nil
end
 
return libwdb