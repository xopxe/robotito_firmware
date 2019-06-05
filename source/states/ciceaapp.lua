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
local remotecontrol = require 'states.remotecontrol'


local behavior_name = nvs.read("ahsm", "behavior", nil) or nil
print('behavior loading:', behavior_name)

local behavior = ahsm.state{
  entry = function()
    print("NO BEHAVIOR .... please load one")
  end
}

if (behavior_name ~= nil) then
  behavior = require( behavior_name )
end

local t_control = ahsm.transition {
  src = behavior, tgt = remotecontrol,
  events = { remotecontrol.events.WIFIMESSAGE },
}

local t_behavior = ahsm.transition {
  src = remotecontrol, tgt = behavior,
  events = { remotecontrol.events.FINCONTROL },
}

local s_on = onoff.states.ON
local s_off = onoff.states.OFF

s_off.entry = function ()
  robot.led_ring.clear()
end

s_on.states = { remotecontrol , behavior }
s_on.transitions = {t_control, t_behavior}
s_on.initial = remotecontrol

s_on.entry = function ()
  robot.omni.enable(true)
end

s_on.exit = function ()
  robot.omni.enable(false)
end


return onoff
