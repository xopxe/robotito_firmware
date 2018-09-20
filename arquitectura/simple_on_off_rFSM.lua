

-- require("fsmdbg")

local omni=require('omni')
local apds = assert(require('apds9960')) -- init apsd

assert(apds.init())
local distC = apds.proximity
assert(distC.enable())



local enable_motors = function()
  local W_ROTATE = 0.008
  omni.set_enable()
  omni.drive(0,0,W_ROTATE)
end

local disable_motors = function()
  omni.drive(0,0,0)
  omni.set_enable(false)
end

local simple_templ = rfsm.csta:new{
   idle_hook=function () os.execute("sleep 0.1") end,

   on = rfsm.sista:new{entry=function() enable_motors() end},
   off = rfsm.sista:new{entry=function() disable_motors() end},

   rfsm.trans:new{ src='off', tgt='on', events={ 'e_on' } },
   rfsm.trans:new{ src='on', tgt='off', events={ 'e_off' } },
   rfsm.trans:new{ src='initial', tgt='off' }
}

local fsm = rfsm.init(simple_templ, "simple_test")

-- callback for distC.get_dist_thresh
-- will be called when the robot is over threshold high
local dump_dist = function(b)
    if b then
      rfsm.send_events(fsm, 'e_on')
    else
      rfsm.send_events(fsm, 'e_off')
    end
    print(b)
end

-- enable distC change monitoring
distC.get_dist_thresh(ms, thershold, histeresis, dump_dist)

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
