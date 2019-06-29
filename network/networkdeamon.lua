_G.libip = require("libip")
_G.libtcp = require("libtcp")
local modem = require("component").modem
local thread = require("thread")
modem.open(libip.IP_PORT)
modem.open(libip.ARP_PORT)

t = thread.create(libip.run)
