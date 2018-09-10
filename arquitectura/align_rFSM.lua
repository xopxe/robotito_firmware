local rfsm = require("rfsm")
-- require("fsmdbg")

local omni=require('omni')
local apds = assert(require('apds9960')) -- init apsd
assert(apds.init())
local distC = apds.proximity
assert(distC.enable())

local ms = 50  -- period of distance measurements
local thershold = 251
local histeresis = 3
local W_ROTATE = 0.008

local TIME_OUT = 1
local current_timeout = TIME_OUT
local current_w = 0

local disable_motors = function()
  omni.drive(0,0,0)
  omni.set_enable(false)
end

local init_on_state = function()
  omni.set_enable()
  current_w = W_ROTATE
  omni.drive(0,0,current_w)
end

local align_fsm = rfsm.csta:new{
   on = rfsm.sista:new {
     pan_l = rfsm.sista:new {},
     pan_r = rfsm.sista:new {},
     find_min = rfsm.sista:new {},
     back = rfsm.sista:new {},
     aligned = rfsm.sista:new {},
     rfsm.trans:new{ src='initial', tgt='pan_l', effect=function() init_on_state() end},
     rfsm.trans:new{ src='pan_l', tgt='pan_r', events={ 'timeout' } },
     rfsm.trans:new{ src='pan_r', tgt='pan_l', events={ 'timeout' } },
     rfsm.trans:new{ src='pan_l', tgt='find_min', events={ 'see' } },
     rfsm.trans:new{ src='pan_r', tgt='find_min', events={ 'see' } },
     rfsm.trans:new{ src='find_min', tgt='back', events={ 'grows' } },
     rfsm.trans:new{ src='back', tgt='aligned', events={ 'timeout' } }
   },
   off = rfsm.sista:new{entry=function() disable_motors() end},

   rfsm.trans:new{ src='off', tgt='on', events={ 'e_on' } },
   rfsm.trans:new{ src='on', tgt='off', events={ 'e_off' } },
}

local fsm = rfsm.init(align_fsm, "align_fsm")

-- callback for distC.get_dist_thresh
-- will be called when the robot is over threshold high
local dump_dist = function(b)
    if b then
      rfsm.send_events(fsm, 'e_on')
    else
      rfsm.send_events(fsm, 'e_off')
    end
end

-- enable distC change monitoring
-- distC.get_dist_thresh(ms, thershold, histeresis, dump_dist)

-- local rfsm2uml = require("rfsm2uml")
-- rfsm2uml.rfsm2uml(fsm, 'png', "fsm.png", "Figure caption")

-- local b = true
while 1 do
--   dump_dist(b)
--   b = not b
  idle = rfsm.step(fsm, 10)
  tmr.sleepms(10)
end

-- rfsm.run()
