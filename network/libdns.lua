print("loading dns libary")
lib = {}
-- const


local dns_cache = {}
function lib.reloveDNS(name)
    if dns_cache[name] ~= nil then return dns_cache[name] end
    sendDNSRequest(name)
end