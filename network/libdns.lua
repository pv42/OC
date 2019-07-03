print("loading dns libary")
libdns = {}
-- const


local dns_cache = {}
function libdns.reloveDNS(name)
    if dns_cache[name] ~= nil then return dns_cache[name] end
    sendDNSRequest(name)
end