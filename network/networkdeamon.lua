local log = require("log")
local libip = require("libip")
local libtcp = require("libtcp")
local modem = require("component").modem
local thread = require("thread")
modem.open(libip.IP_PORT)
modem.open(libip.ARP_PORT)

t = thread.create(libip.run):detach()

log.i("network deamon started")
