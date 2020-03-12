--- Main program using ahsm.
-- Uses state machines to control the robot. This program is intended to
-- be loaded from the @{autorun} script. To achieve this, set `nvs.write("autorun", "main" "main_ahsm.lua")`.
-- This program loads and initalizes @{robot} and ahsm.
--
-- Configuration is loaded using `nvs.read("ahsm", parameter)` calls, where the
-- available parameters are:
--
--* `"debugger"` the debug output system, like ahsm's "debug_plain". Defaults to nil (disabled)
--
--* `"dot_period"` if positive, a period in sec for printing a dot graph of the root state machine. Defaults to -1 (disabled)
--
--* `"root"` a composite state to be used as root for the state machine. This must be the name of library to be required, which will return an ahsm state. Defaults to "states.test"
--
--* `"timestep"` time in ms between sweeps to check for timed out transitions. Defaults to 10
--
--* `"stacksize"` ram asigned to ahsm thread in bytes. Defaults to nil, meaning use firmware default (typically 8096)
-- @script main_ahsm


robot = require 'robot'  -- global
--robot.init()

local ahsm = require 'ahsm'
ahsm.get_time = os.gettime
local hsm

-- initialize debugging

do
  local debuggername = nvs.read("ahsm", "debugger", nil)
  print('main_ahsm debugger:', debuggername)
  if debuggername then
    local debugger = require( debuggername )
    ahsm.debug = debugger.out
  end
end

-- load root state
do
  local rootname = nvs.read("ahsm", "root", "states.test") or "states.test"
  print('main_ahsm loading:', rootname)
  local root = require( rootname )
  hsm = ahsm.init(root)
  robot.hsm = hsm

  -- state dumper
  do
    local period = nvs.read("ahsm", "dot_period", -1) or -1
    --local count = nvs.read("ahsm", "dot_count", math.huge) or math.huge
    if period>0 then
      thread.start(function()
          local to_dot = require 'to_dot'
          while true do
            to_dot.to_function(root, print)
            thread.sleep(period)
          end
        end)
    end
  end

end

-- We must keep looping for reacting to state timeouts
local step = nvs.read("ahsm", "timestep", 10) or 10
print('main_ahsm timestep:', step)

local stacksize = tonumber(nvs.read("ahsm", "stacksize", nil) or nil)
if stacksize==nil then
  print('ahsm stack set to firmware default')
else
  print('ahsm stack:', stacksize)
end


thread.start( function()
    while true do
      hsm.loop()
      tmr.sleepms(step)
    end
  end, stacksize, nil, nil, 'ahsm_loop')

print 'ahsm started:'
thread.list(false, false, true)
