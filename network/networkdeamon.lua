local log = require("log")
local libip = require("libip")
local libtcp = require("libtcp")
local libtcp = require("libdhcp")
local modem = require("component").modem
local thread = require("thread")
local fs = require("filesystem")
local serialization = require("serialization")
local libdhcp = require("libdhcp")
modem.open(libip.IP_PORT)
modem.open(libip.ARP_PORT)

local CONFIG_PATH = "/etc/network.cfg"

if not fs.exists(CONFIG_PATH) then
	f = io.open(CONFIG_PATH, "w")
	f:write("{ip = \"0.0.0.0\",dhcp=true}")
	f:close()
	log.i("created config file " .. CONFIG_PATH)
end
local f, msg = io.open(CONFIG_PATH)

local config_good = false
local cfg,m

if not f then
	log.e("could not load ip config: " .. msg)
else
	local cont = f:read("a*") 
	f:close()
	cfg, m = serialization.unserialize(cont)
	if not cfg then 
		log.e("could not read config: " .. m)
	else
		config_good = true
		if cfg.ip then libip.config.local_ip = libip.StringtoIP(cfg.ip) end
	end
end

t = thread.create(libip.run):detach()

if config_good then
	if cfg.dhcp then libdhcp.requestIP() end
end
log.i("network deamon started")