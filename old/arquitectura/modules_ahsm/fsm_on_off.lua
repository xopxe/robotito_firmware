local ahsm = require("ahsm")
local robot = require("robot")
local align_root = require("fsm_align")

local e_floor = { name="e_floor"}
local e_restart = {name="e_restart"}
local e_not_floor = {name="e_not_floor"}

local enable_motors = function()
  robot.omni.set_enable()
end

local disable_motors = function()
  robot.omni.drive(0,0,0)--
  robot.omni.set_enable(false)
end

local off_s = ahsm.state { entry=disable_motors } --state with exit func
local on_s =  align_root
local wait_s = ahsm.state { entry = function() end } --state with entry func


local t_off_wait    = ahsm.transition { src=off_s,  tgt=wait_s,   events={e_floor},} 
local t_on_off      = ahsm.transition { src=on_s,   tgt=off_s,    events={e_not_floor}, } 
local t_wait_on     = ahsm.transition { src=wait_s, tgt=on_s,     events={e_restart}, effect=function() enable_motors()end, timeout=2.0} 
local t_wait_off    = ahsm.transition { src=wait_s, tgt=off_s,    events={e_not_floor},}

local on_off = ahsm.state {
  events = {EV_FLOOR = e_floor,
    EV_RESTART = e_restart,
    EV_NOT_FLOOR = e_not_floor,},
  states = { on=on_s, off=off_s, wait=wait_s }, --composite state
  transitions = { t_off_wait, t_on_off, t_wait_on, t_wait_off  },
  initial = off_s, --initial state for machine
}

return on_off


