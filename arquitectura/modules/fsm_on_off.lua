local rfsm = require("rfsm")
local robot = require("robot")

local enable_motors = function()
  robot.omni.drive(0,0,0.008)
  robot.omni.set_enable()
end

local disable_motors = function()
  robot.omni.drive(0,0,0)
  robot.omni.set_enable(false)
end


local on_off = rfsm.csta:new{
   
   on = rfsm.sista:new{},
   off = rfsm.sista:new{},

   rfsm.trans:new{ src='off', tgt='on', events={ 'e_on' }, effect = enable_motors },
   rfsm.trans:new{ src='on', tgt='off', events={ 'e_off' }, effect = disable_motors },
   rfsm.trans:new{ src='initial', tgt='off' }
}

return on_off