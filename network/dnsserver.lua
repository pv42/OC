local libdns = require("libdns")

local hostlist = {}

local function handleQuerry(package) 
  if package.type ~= "Q" then error("package type querry expected") end
  local awnser = {type="R",content={}}
  for k, v in pairs(package.content) do
    awnser[k] = hostlist[k]
  end
  libudp.send()
end

libdns.setRequestHandler()