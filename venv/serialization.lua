local function serialize(root)
  if type(root) == "table" then
    local str = "}"
    local colon
    for k, v in pairs(root) do
      if colon then
        str = "," .. str
      end
      colon = true
      str = k .. "=" .. serialize(v)  .. str
    end
    str = "{" ..str
    return str
  else
    return tostring(root)
  end
end

return {
  serialize = serialize,
  unserialize = function(str)
    if type(str) ~= "string" then error("string expected got " .. type(str)) end
    return load("return " .. str)()
  end
}