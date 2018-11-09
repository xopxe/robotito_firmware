
-- Initializing WIFI
net.wf.setup(
  net.wf.mode.AP,
  "robotito-guille",
  "robotito",
  net.wf.powersave.NONE
)
net.wf.start()

-- Socket UDP

local socket = require("__socket")

local host = "192.168.4.1"
local port = 2018
local ip_broadcast =  "192.168.4.255"

local message_id = 0

print("Binding to host '" ..host.. "' and port " ..port.. "...")

local udp = assert(socket.udp())

udp:setoption('broadcast', true)
assert(udp:setsockname(host, port))

-- END Socket UDP

local ahsm = require 'ahsm'
ahsm.get_time = assert(os.gettime)

local debugger=require 'debug_plain'
debugger.print = function (msg)
  udp:sendto(message_id .. ' :: ' .. msg, ip_broadcast, port)
  message_id = message_id + 1
end

ahsm.debug = debugger.out

local robot = require 'robot'
robot.init()
robot.omni.set_enable()

-- get parameters
local filename = 'fsm_on_off.lua'

-- load hsm
local root = assert(dofile(filename))
local hsm = ahsm.init( root )  -- create fsm from root composite state
robot.fsm = hsm

-- run hsm
repeat
  local next_t = hsm.loop()

until false --next_t
