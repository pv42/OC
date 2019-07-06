print("loading dns libary")
local libdns = {}
local libudp = require("libudp")
-- const
local DNS_PORT = 53
local DNS_QUERRY_TIMEOUT = 10
local DNS_CACHE_TIMEOUT = 1000

local dns_cache = {}
local request_handler = nil

local function sendDNSQuerry(name)
  if dns_server == 0 then return nil end -- root dns server/dns server not set up
  libudp.send(DNS_PORT, DNS_PORT, libip.config.dns_server, {type="Q",content={[name]=0}}) -- 0 is a placeholder
end

function libdns.sendDNSRequest()
  --todo
end

function libdns.reloveDNS(name)
  if dns_cache[name] ~= nil then return dns_cache[name] end
  sendDNSQuerry(name)
  for local i = 1, 10*DNS_QUERRY_TIMEOUT do
    os.sleep(0.1)
    if dns_cache[name] ~= nil then return dns_cache[name] end
  end
  print("could not resolve" .. name)
  return nil
end

local function handlePackage(package, ip)
  if not package.content then error("received contentless dns package") end
  if package.type == "Q"  then --querry
    if request_handler then 
      request_handler(package) 
    else
      error("no dns request handler is set up")
    end
  elseif package.type = "R" then -- response
    for k, v in pairs(package.content) do
      dns_cache[k] = v
    end
  else 
    error("invalid dns package type ")
  end
end

function setRequestHandler(func) -- interface for dns server
  if type(func) ~= "function" then error("request handler must be a function") end
  request_handler = func
end

libudp.addReceiveHandler(DNS_PORT,handlePackage)