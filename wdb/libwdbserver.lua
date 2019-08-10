local db = {}

local libudp = require("libudp")
local libwdb = require("libwdb")
local serialization = require("serialization")
local fs = require("filesystem")
local log = require("log")
local event = require("event")

local path = "/usr/wdb/"

local function recivePackage(package)
  --package = serialization.unserialize(package_s)
  if package.x == nil or package.y == nil or package.z == nil then
    return
  end
  if db[package.x] == nil then
    db[package.x] = {}
  end
  if db[package.x][package.y] == nil then
    db[package.x][package.y] = {}
  end
  db[package.x][package.y][package.z] = package.block
  print("block " .. package.x .. "," .. package.y .. "," .. package.z)
end

local function save()
  local f, msg = io.open(path, "w")
  if not f then
    log.e("could not load chunk file " .. msg)
    return
  else
    f:write(serialization.serialize(db))
  end
  log.i("db saved")
end

local function loadChunk(filename)
  -- filename must be chunk_[x]_[z].chk
  if not filename:gmatch("chunk_[%-]?[0-9]+_[%-]?[0-9]+.chk") then
    log.e("could not load chunk file:" .. "filename does not match")
    return
  end
  local f, msg = io.open(path,"r")
  if not f then
    log.e("could not load chunk file " .. msg)
    return
  else
    log.i("chunk x,z loaded")
  end
end

local function loadDB()
  db = {}
  for f in fs.list(path) do
    loadChunk(filename)
  end
end

print("wdb 1.0 SERVER")
load()
libudp.addReceiveHandler(libwdb.PORT, recivePackage)
print("Press 'Ctrl-C' to exit")
event.pull("interrupted")
libudp.addReceiveHandler(libwdb.PORT, nil)
save()