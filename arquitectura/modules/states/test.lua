-- Test ahsm state machine.
-- On and Off states, controlled by the floor proximity sensor.
-- When On, there's a led semaphor cycling trough colors.

local ahsm = require 'ahsm'

-- events for proximity sensor
local e_floor = { _name="FLOOR" }
local e_not_floor = { _name="NOTFLOOR" }

-- semaphor states, one per color
local s_green = ahsm.state {
  entry = function() robot.led_ring.clear(0,100,0) end,
}
local s_yellow = ahsm.state {
  entry = function() robot.led_ring.clear(50,50,0) end,
}
local s_red = ahsm.state {
  entry = function() robot.led_ring.clear(100,0,0) end,
}
-- transitions for semaphor colors (on timeouts)
local t_green = ahsm.transition {
  src = s_red, tgt = s_green,
  timeout = 1.0,
}
local t_yellow = ahsm.transition {
  src = s_green, tgt = s_yellow,
  timeout = 1.0,
}
local t_red = ahsm.transition {
  src = s_yellow, tgt = s_red,
  timeout = 1.0,
}

-- On/Off states
local s_off = ahsm.state {
  entry = function() robot.led_ring.clear(0,0,0) end,
}
-- the On state has the semaphor embedded
local s_on = ahsm.state {
  states = { GREEN=s_green, YELLOW=s_yellow, RED=s_red },
  transitions = { togreen=t_green, tored=t_red, toyellow=t_yellow },
  initial = s_red,
}

-- On/Off transitions on proximity events
local t_on = ahsm.transition {
  src = s_off, tgt = s_on,
  events = { e_floor },
}
local t_off = ahsm.transition {
  src = s_on, tgt = s_off,
  events = { e_not_floor },
}

-- callback for proximity sensor, emits events for state machine
local floor_event = function( v )
  if v then
    robot.hsm.send_event(e_floor)
  else
    robot.hsm.send_event(e_not_floor)
  end
end

-- root state, embeds On/Off machine and initialization code
local root = ahsm.state {
  events =  { e_floor, e_not_floor },
  states = { OFF=s_off, ON=s_on },
  transitions = { switchon=t_on, switchoff=t_off },
  initial = s_off,
  entry = function()
    robot.floor.threshold.cb.append(floor_event)
    robot.floor.threshold.enable(true)
  end,
  exit = function()
    robot.floor.threshold.enable(false)
    robot.floor.threshold.cb.remove(floor_event)
  end,  
}

return root

