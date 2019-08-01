local log = {}
function log.e(msg)
  print("[ERR] " .. msg)
end
function log.i(msg)
  print("[INF] " .. msg)
end
return log