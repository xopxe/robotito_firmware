local rfsm = require("rfsm")
local rfsm_timeevent = require("rfsm_timeevent")
local robot = require("robot")

rfsm_timeevent.set_gettime_hook(function() 
  local up = os.uptime(true)
  return up.secs, 0
end)

local ROTATION_SPEED = 0.008
local w_rotate = 0

local set_w = function(w)
  print("setting SPEED")
  w_rotate = w
  robot.omni.drive(0,0,w_rotate)
end

local invert_w = function()
  w_rotate = -w_rotate
  robot.omni.drive(0,0,w_rotate)
end


local align = rfsm.csta:new{
   
  stop = rfsm.sista:new{},
  rotate = rfsm.sista:new{},
  pan = rfsm.sista:new{},
  back = rfsm.sista:new{},

  rfsm.trans:new{ 
    src='rotate', 
    tgt='pan', 
    events={ 'no_object' }, 
    effect=function() set_w(ROTATION_SPEED) end,
  },
  rfsm.trans:new{ 
    src='rotate', 
    tgt='pan', 
    events={ 'find_object' },
    effect=function() set_w(-ROTATION_SPEED) end,
  },
  rfsm.trans:new{ 
    src='pan', 
    tgt='back', 
    events={ 'loosing_object' },
    effect=invert_w,
  },
  rfsm.trans:new{ 
    src='back',
    tgt='stop',
    events={ 'e_after(1)' },
    effect=function() set_w(0) end,
  },
  rfsm.trans:new{ 
    src='initial',
    tgt='rotate',
    effect=function() set_w(0) end,
  }
}

return align

