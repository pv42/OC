require("init")
return { pull = function(filter) --emulated after 3s
  io.flush()
  os.execute("sleep 1s")
  return "modem_message", 1, 2, 3, 4, "{a=5,data={}}"
end,pullMultiple = function(filter)
end }