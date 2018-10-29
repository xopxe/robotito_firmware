local ahsm = require 'ahsm'
local robot = require 'robot'

local drive = function(v, w)
  robot.omni.drive(v, 0, w) --FIXME forward?
end

local vel = 0.1
local pan_w = 0.3
local pan_time = 0.5
local pan_time_ms = math.floor(pan_time*1000)
local correcting_time = 0.1
local correcting_w = 0.5

local e_correct_left = {_name = 'corr_left'}
local e_correct_right = {_name = 'corr_right'}
local e_pan_timedout = {_name = 'pan_tmout'}

local e_d_reading = {_name = 'd_reading'}

local veldiff_thrsh = vel*0.01
local avg_vel_left = 0
local avg_vel_right = 0

local tmr_pan

local s_pan_right = ahsm.state {
  doo = function ()
    local veldiff = avg_vel_right - avg_vel_left
    if veldiff > veldiff_thrsh then 
      robot.fsm.send_event (e_correct_right)
    elseif veldiff < -veldiff_thrsh then 
      robot.fsm.send_event (e_correct_left)
    else
      drive(vel, pan_w)
    end
  end,
}

local s_pan_left = ahsm.state {
  doo = function ()
    drive(vel, -pan_w)
  end,
}

local s_correcting = ahsm.state {
}


local t_pan_left = ahsm.transition { 
  src = s_pan_right, 
  tgt = s_pan_left,
  events = {e_pan_timedout},
  effect = function()
    tmr_pan:stop()
    tmr_pan:start()
  end,
}

local t_pan_right = ahsm.transition { 
  src = s_pan_left,
  tgt = s_pan_right, 
  events = {e_pan_timedout},
  effect = function()
    tmr_pan:stop()
    tmr_pan:start()
  end,
}

local t_correct_right = ahsm.transition { 
  src = s_pan_right,
  tgt = s_correcting,
  events = {
    e_correct_right,
  },
  effect = function()
    drive(vel, correcting_w)
  end, 
}

local t_correct_left = ahsm.transition { 
  src = s_pan_right,
  tgt = s_correcting,
  events = {
    e_correct_left,
  },
  effect = function()
    drive(vel, -correcting_w)
  end, 
}

local t_corrected = ahsm.transition { 
  src = s_correcting,
  tgt = s_pan_right, 
  timeout = correcting_time,  
}

local reading_cb = function ()
  e_d_reading.readings = robot.laser_ring.norm_d
  robot.fsm.send_event (e_d_reading)
end


local s_goto = ahsm.state {
  states = {
    correcting = s_correcting,
    pan_left = s_pan_left, 
    pan_right = s_pan_right
  },
  transitions = {t_correct_left, t_correct_right, t_corrected, t_pan_left, t_pan_right},
  entry = function ()
    tmr_pan = tmr.attach(pan_time_ms, function()
        robot.fsm.send_event(e_pan_timedout)
      end)
    robot.laser_ring.cb_list.add(reading_cb)
  end,
  exit = function ()
    tmr:detach()
    robot.laser_ring.cb_list.remove(reading_cb)
  end,
  initial = s_pan_right,
}


return s_goto

