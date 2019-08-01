function checkArg(pos,val,expected)
  if type(val) ~= expected then
    print("arg #" .. tostring(pos) .. " is " .. type(val) .. ", " .. expected .. " expected")
  end
end