local libdns = require("libdns")
local log = require("log")
local fs = require("filesystem")
local serialization = require("serialization")

local CONFIG_PATH = "/etc/dnsserver.cfg"

if not fs.exists(CONFIG_PATH) then
  f = io.open(CONFIG_PATH, "w")
  f:write("{hostlist={[\"localhost\"]=0x7f000001}}") -- 127.0.0.1
  f:close()
  log.i("created config file " .. CONFIG_PATH)
end
local f, msg = io.open(CONFIG_PATH)


local hostlist = {}

if not f then
  log.e("could not load dnsserver config: " .. msg)
else
  local cont = f:read("a*") 
  f:close()
  cfg, m = serialization.unserialize(cont)
  if cfg and cfg.hostlist then
    hostlist = cfg.hostlist
  else 
    log.e("could not parse dnsserver config: " .. m)
  end
end


local config_good = false
local cfg,m



local function handleQuerry(package, ip) 
  if package.type ~= "Q" then error("package type querry expected") end
  local content = {}
  for k, v in pairs(package.content) do
    content[k] = hostlist[k]
  end
  libdns.sendDNSResponse(ip, content)
end

libdns.setQuerryHandler(handleQuerry)
log.i("DNS server started")