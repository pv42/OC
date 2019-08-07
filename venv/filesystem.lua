local lfs = require("lfs")
return { list = function(dir)
  return lfs.dir(dir)
end, concat = function(a, b)
  return a .. "/" .. b
end, isDirectory = function(dir)
  return lfs.attributes(dir).mode == "directory"
end, size = function(path)
  return lfs.attributes(path).size
end, exists = function(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end }