--- On-floor detecting state machine.
-- This state machine is usefull for powering on and off the robot
-- when placed on the floor or picked up. It uses the proximity sensor.
-- To integrate, import t nd add behavior to the states.ON and states.OFF 
-- states. Also emits events.FLOOR and events.NOTFLOOR events.  
-- For an example usage, see @{colorway.lua}

local ahsm = require 'ahsm'

-- events for proximity sensor
local e_floor = { _name="FLOOR" }
local e_not_floor = { _name="NOTFLOOR" }


-- On/Off states
local s_off = ahsm.state {
}
local s_on = ahsm.state {
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
    robot.hsm.queue_event(e_floor)
  else
    robot.hsm.queue_event(e_not_floor)
  end
end

-- root state, embeds On/Off machine and initialization code
local hsm = ahsm.state {
  events =  { FLOOR=e_floor, NOTFLOOR=e_not_floor },
  states = { OFF=s_off, ON=s_on },
  transitions = { switchon=t_on, switchoff=t_off },
  initial = s_off,
  entry = function()
    robot.floor.cb.append(floor_event)
    robot.floor.enable(true)
  end,
  exit = function()
    robot.floor.enable(false)
    robot.floor.cb.remove(floor_event)
  end,  
}

return hsm

