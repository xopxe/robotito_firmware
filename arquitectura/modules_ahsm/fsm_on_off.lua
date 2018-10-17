local ahsm = require("ahsm")
local robot = require("robot")

local enable_motors = function()
  robot.omni.drive(0,0,0.008)
  robot.omni.set_enable()
end

local disable_motors = function()
  robot.omni.drive(0,0,0)
  robot.omni.set_enable(false)
end


local off_s = ahsm.state { entry=disable_motors } --state with exit func
local on_s = ahsm.state { entry=enable_motors} --state with entry func
local wait_s = ahsm.state { entry = function() end } --state with entry func


local t_off_wait    = ahsm.transition { src=off_s,  tgt=wait_s,   events={'e_floor'},} 
local t_on_off      = ahsm.transition { src=on_s,   tgt=off_s,    events={'e_not_floor'}, } 
local t_wait_on     = ahsm.transition { src=wait_s, tgt=on_s,     events={'e_restart'}, timeout=2} 
local t_wait_off    = ahsm.transition { src=wait_s, tgt=off_s,    events={'e_not_floor'},}

local on_off = ahsm.state {
  states = { on=on_s, off=off_s, wait=wait_s }, --composite state
  transitions = { t_off_wait, t_on_off, t_wait_on, t_wait_off  },
  initial = off_s, --initial state for machine
}



return on_off

