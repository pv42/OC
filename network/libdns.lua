print("loading dns libary")
local libdns = {}
local libip = require("libip")
local libudp = require("libudp")
local log = require("log")
-- const
local DNS_PORT = 53
local DNS_QUERRY_TIMEOUT = 10
local DNS_CACHE_TIMEOUT = 1000

local dns_cache = {}
local querry_handler = nil

local function sendDNSQuerry(name)
  if libip.config.dns_server == 0 then 
    log.w("no dns server set up, edit /etc/network.cfg")
    return nil
  end -- root dns server/dns server not set up
  libudp.send(DNS_PORT, DNS_PORT, libip.config.dns_server, {type="Q",content={[name]=0}}) -- 0 is a placeholder
end

function libdns.sendDNSRequest(ip, content)
  libudp.send(DNS_PORT, DNS_PORT, ip, {type="R",content=content})
end

function libdns.resolveDNS(name)
  if dns_cache[name] ~= nil then return dns_cache[name] end
  sendDNSQuerry(name)
  for i = 1, 10*DNS_QUERRY_TIMEOUT do
    os.sleep(0.1)
    if dns_cache[name] ~= nil then return dns_cache[name] end
  end
  print("could not resolve '" .. name .. "'")
  return nil
end

local function handlePackage(package, ip)
  if not package.content then error("received contentless dns package") end
  if package.type == "Q"  then --querry
    if querry_handler then 
      querry_handler(package, ip) 
    else
      error("no dns querry handler is set up")
    end
  elseif package.type == "R" then -- response
    for k, v in pairs(package.content) do
      dns_cache[k] = v
    end
  else 
    error("invalid dns package type ")
  end
end

function libdns.setQuerryHandler(func) -- interface for dns server
  if type(func) ~= "function" then error("querry handler must be a function") end
  querry_handler = func
end

libudp.addReceiveHandler(DNS_PORT,handlePackage)
dns_cache["localhost"] = 0x7f000001 -- 127.0.0.1

function libdns.getDNSCache()
  return dns_cache
end

return libdns