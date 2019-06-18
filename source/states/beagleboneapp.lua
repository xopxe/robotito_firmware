--- Use color patches to select movement direction.
-- The robot will move in the direction indicated by the led lights when
-- detects a color patch on the floor of the same color. If you pick the
-- robot up it powers down.
--
-- This is a state machine to be run using @{main_ahsm}. For this set
-- `nvs.write("ahsm", "root", "states.colorway")` and then run `dofile'main_ahsm.lua'`,
-- or simply set `nvs.write("autorun", "main", "main_ahsm.lua")` for autorun.
-- @hsm colorway.lua

-- color events

local ahsm = require 'ahsm'
local onoff = require 'states.onoff'

local s_on = onoff.states.ON
local s_off = onoff.states.OFF

s_on.entry = function ()
  robot.omni.enable(true)
  print("STATE - ON")
end

s_on.exit = function ()
  robot.omni.enable(false)
end

s_off.exit = function ()
  print("STATE - OFF")
end

return onoff
