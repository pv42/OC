return { parse = function(...)
  local o = {}
  for k, v in pairs(table.pack(...)) do
    if k ~= "n" then
      if v:sub(1, 1) == "-" then
        o[v:sub(2)] = true
      end
    end
  end
  return {}, o
end }