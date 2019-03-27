-----------------------------------------------------------------------------
-- UDP sample: echo protocol client
-- LuaSocket sample files
-- Author: Diego Nehab
-----------------------------------------------------------------------------
local socket = require("socket")
host = host or "192.168.4.1"
port = port or 2018
if arg then
    host = arg[1] or host
    port = arg[2] or port
end
--host = socket.dns.toip(host)
udp = assert(socket.udp())
assert(udp:setpeername(host, port))
print("Using remote host '" ..host.. "' and port " .. port .. "...")

w = 0.01
while 1 do
	line = "speed*0*0*" .. w .. "*0"
  print(line)
	assert(udp:send(line))
  socket.sleep(1) -- seg
  w = -w
end
