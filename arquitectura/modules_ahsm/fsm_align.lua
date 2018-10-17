local ahsm = require("ahsm")
local robot = require("robot")

--[[
rfsm_timeevent.set_gettime_hook(function() 
  return  os.gettime(true)
end)
--]]

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

 
local stop_s = ahsm.state{}
local rotate_s = ahsm.state{}
local pan_s = ahsm.state{}
local back_s = ahsm.state{}

local t_rotate_pan1 = ahsm.transition{ 
    src= rotate_s, 
    tgt= pan_s, 
    events={ 'no_object' }, 
    effect=function() set_w(ROTATION_SPEED) end,
  }
  
 local t_rotate_pan2 = ahsm.transition{ 
    src= rotate_s, 
    tgt= pan_s,  
    events={ 'find_object' },
    effect=function() set_w(-ROTATION_SPEED) end,
  }
  
local t_pan_back = ahsm.transition{ 
    src=pan_s, 
    tgt=back_s, 
    events={ 'loosing_object' },
    effect=invert_w,
  }
  
local t_back_stop = ahsm.transition{ 
    src=back_s,
    tgt=stop_s,
    events={ back_s.EV_DONE },
    effect=function() set_w(0) end,
  }
  
local t_stop_back = ahsm.transition{ 
    src=stop_s,
    tgt=back_s,
    events={ stop_s.EV_DONE },
    effect=function() set_w(0) end,
  }
  
  
local align = ahsm.state {
  states = { stop=stop_s, rotate=rotate_s, pan=pan_s,back=back_s },
  transitions = { t_rotate_pan1, t_rotate_pan2, t_pan_back, t_back_stop, t_stop_back },
  initial = rotate_s,
}

return align

