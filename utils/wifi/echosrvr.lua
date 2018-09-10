-----------------------------------------------------------------------------
-- UDP sample: echo protocol server
-- LuaSocket sample files
-- Author: Diego Nehab
-----------------------------------------------------------------------------

local omni=require('omni')

local xdot = 0
local ydot = 0
local w = 0

local autonomous = false

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local VEL_CMD = 'speed'

omni.set_enable()

local socket = require("__socket")
host = host or "192.168.4.1"
port = port or 2018
if arg then
    host = arg[1] or host
    port = arg[2] or port
end
print("Binding to host '" ..host.. "' and port " ..port.. "...")
udp = assert(socket.udp())
assert(udp:setsockname(host, port))
-- assert(udp:settimeout(5))
ip, port = udp:getsockname()
assert(ip, port)
print("Waiting packets on " .. ip .. ":" .. port .. "...")
while 1 do
	dgram, ip, port = assert(udp:receivefrom())
	if dgram then
		print("Echoing '" .. dgram .. "' to " .. ip .. ":" .. port)
    cmd = split(dgram, '*')
    if cmd[1] == VEL_CMD then
      if #cmd == 5 then
        autonomous = false
        xdot = cmd[2]
        ydot = cmd[3]
        w = cmd[4]
        omni.drive(xdot,ydot,w)
        udp:sendto('[INFO] Speed command received (' .. xdot .. ', ' .. ydot .. ')', ip, port)
      else
        udp:sendto('[ERROR] Malformed command.', ip, port)
      end
    else
      udp:sendto('[ERROR] Unknown command: ' .. cmd[1], ip, port)
    end
	else
    print(ip)
  end
end
