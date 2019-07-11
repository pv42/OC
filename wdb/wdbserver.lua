local db = {}

local libudp = require("libudp")
local libwdb = require("libwdb")
local serialization = require("serialization")
local fs = require("filesystem")
local log = require("log")
local event = require("event")

local path = "/usr/misc/wdb.db"

local function recivePackage(package)
	--package = serialization.unserialize(package_s)
	if db[package.x] == nil then db[package.x] = {} end
	if db[package.x][package.y] == nil then db[package.x][package.y] = {} end
	db[package.x][package.y][package.z] = package.block 
	print("block " .. package.x .. "," ..package.y .. "," .. package.z)
end

local function save()
	local f, msg = io.open(path, "w")
	if not f then
		log.e("could not load db file " .. msg)
		return
	else
		f:write(serialization.serialize(db))
	end 
	log.i("db saved")
end

local function load()
	if not fs.exists(path) then
		f = io.open(path, "w")
		f:write("{}")
		f:close()
		log.i("created db file " .. path)
	end
	
	local f, msg = io.open(path)
	
	if not f then
		log.e("could not load db file " .. msg)
		return
	else
		local cont = f:read("a*") 
		f:close()
		local m
		db, m = serialization.unserialize(cont)
		if not db then 
			log.e("could not read db file: " .. m)
			return
		else
			log.i("db loaded")
		end
	end
end

print("wdb 1.0 SERVER")
load()
libudp.addReceiveHandler(libwdb.PORT,recivePackage)
print("Press 'Ctrl-C' to exit")
event.pull("interrupted")
libudp.addReceiveHandler(libwdb.PORT,nil)
save()