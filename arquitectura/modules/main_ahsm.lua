--- Main program using ahsm.
-- Uses state machines to control the robot. This program is intended to
-- be loaded from the autorun.lua script as `dofile 'main_ahsm'`.  
-- This program loads and initalizes @{robot} and ahsm.  
-- Configuration is loaded using `nvs.read("ahsm", parameter) calls`, where the
-- available parameters are:  
--  
--* `"debugger"` the debug output system, like ahsm's "debug_plain". Defaults to nil (disabled)  
--  
--* `"root"` a composite state to be used as root for the state machine. This must be the name of library to be required, which will return an ahsm state. Defaults to "states.test"  
--  
--* `"timestep"` time in ms between sweeps to check for timed out transitions. Defaults to 10  
-- @script main_ahsm


robot = require 'robot'  -- global
--robot.init()

local ahsm = require 'ahsm'
ahsm.get_time = os.gettime
local hsm

-- initialize debugging
do
  local debuggername = nvs.read("ahsm", "debugger", nil)
  if debuggername then
    local debugger = require( debuggername )
    ahsm.debug = debugger.out
  end
end

-- load root state
do
  local rootname = nvs.read("ahsm", "root", "states.test")
  local root = require( rootname )
  hsm = ahsm.init(root)
  robot.hsm = hsm
end

-- We must keep looping for reacting to state timeouts
local step = nvs.read("ahsm", "timestep", 10)
while true do 
  hsm.loop()
  tmr.sleepms(step)
end
