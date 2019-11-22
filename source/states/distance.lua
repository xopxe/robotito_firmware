local ahsm = require 'ahsm'
local omni = require('omni')
local laser = require 'laser_ring'
local leds = require 'led_ring'
local robot = robot

local v = 0.05


local e_dist = {
  {color = {10,0,0}},
  {color = {10,5,0}},
  {color = {10,10,0}},
  {color = {0,10,0}},
  {color = {0,0,10}},
  {color = {5,3,10}}
}

for i, e in ipairs(e_dist) do
  local ang = laser.sensor_angles[i]
  e.dirx = math.cos(ang)
  e.diry = math.sin(ang)
  e.mindist = 0
  e.decreasing = 0
end



--EVENTS

local e_ksearch = { _name = "KEEP_SEARCH" }
local e_back = { _name = "GO_BACK" }
local e_bsearch = { _name = "BACK_SEARCH" }
local e_reforward = { _name = "GO_REFORWARD" }
local e_forward = { _name = "GO_FORWARD" }
local e_repos = { _name = "RE_POSITION" }
local e_psearch = { name = "POS_SEARCH" }
local e_search = { _name = "SEARCH_AGAIN" }


--VARIABLES

--[[
nvs.write('laser','dmin', nil)
nvs.write('laser','dmax', 700)
--]]

local range = function(num)
  return (num > 0 and num < 100)
end

local s_far

local angle
local t_ms = laser.period -- period of distance measurements
local dtheta = (math.pi/3)/30 -- partition of pi/3
local w = -1000*dtheta/t_ms -- rad/s
--[[
t_ms ms ____ dtheta rad
1000 ms ____ w = 1000*dtheta/t_ms rad
]]--

--CALLBACKS
local argmax = function(t)
  local index = 0
  local max = 0
  for i = 1,6 do
    if (range(t[i]) and t[i] > max) then
      index = i
      max = t[i]
    end
  end
  return index
end

local callback_search = function()
  local norm_d = laser.norm_d
  leds.clear()
    for i = 1,6 do
      if(range(norm_d[i]))then
        leds.set_segment(i,e_dist[i].color[1],e_dist[i].color[2],e_dist[i].color[3],true)
        --leds.set_segment(i,10,5,0,true)
      end
    end
  angle = angle + dtheta
  if (angle < math.pi/3) then
    local previous_d = laser.previous_d
    for i = 1,6 do
      if (range(norm_d[i]) and e_dist[i].decreasing ~= -1) then
        if (norm_d[i] < previous_d[i]) then
          e_dist[i].decreasing = e_dist[i].decreasing + 1
        elseif(norm_d[i] > previous_d[i] and e_dist[i].decreasing > 0) then
          e_dist[i].mindist = norm_d[i]
          e_dist[i].decreasing = -1
        end
      end
    end
  else
    omni.drive(0,0,0)
    local d = {}
    for i = 1,6 do
      d[i] = e_dist[i].mindist
    end
    s_far = argmax(d)
    if (s_far == 0) then --every sensor is out of range
      robot.hsm.queue_event(e_ksearch) --keep state
    else
      robot.hsm.queue_event(e_back) --change state
    end
  end
end -- callback_search

local callback_back = function()
  local norm_d = laser.norm_d
  leds.clear()
    for i = 1,6 do
      if(range(norm_d[i]))then
        leds.set_segment(i,e_dist[i].color[1],e_dist[i].color[2],e_dist[i].color[3],true)
        --leds.set_segment(i,5,3,10,true)
      end
    end
  angle = angle + dtheta
  if (angle < math.pi/3) then
    local actual = norm_d[s_far]
    local max = e_dist[s_far].mindist
    local th_dist = 10
    if (math.abs(actual-max) < th_dist and range(actual)) then
      robot.hsm.queue_event(e_forward) --change state
    end
  else
    robot.hsm.queue_event(e_bsearch) --change state
  end
end


local callback_position = function()
  local norm_d = laser.norm_d
  leds.clear()
    for i = 1,6 do
      if(range(norm_d[i]))then
        leds.set_segment(i,e_dist[i].color[1],e_dist[i].color[2],e_dist[i].color[3],true)
        --leds.set_segment(i,20,0,10,true)
      end
    end
    --leds.set_segment(s_far%6 + 1,20,0,0,true)
    --leds.set_segment(s_far,0,0,20,true)

  local actual_s_far = norm_d[s_far]
  local actual_s_far_1 = norm_d[s_far%6 + 1]
  local previous = e_dist[s_far].mindist
  local th_dist = 15

  if (actual_s_far == 0 or actual_s_far_1 == 0) then
    omni.drive(0,0,0)
    robot.hsm.queue_event(e_psearch)
  elseif (actual_s_far ~= 100 and math.abs(actual_s_far - previous) < th_dist) then
    omni.drive(0,0,0)
    robot.hsm.queue_event(e_reforward)
  elseif (actual_s_far_1 ~= 100 and math.abs(actual_s_far_1 - previous) < th_dist) then
    omni.drive(0,0,0)
    s_far = s_far%6 + 1
    robot.hsm.queue_event(e_reforward)
  end

end

local callback_forward = function()
  local norm_d = laser.norm_d
  leds.clear()
    for i = 1,6 do
      if(range(norm_d[i]))then
        leds.set_segment(i,e_dist[i].color[1],e_dist[i].color[2],e_dist[i].color[3],true)
        --leds.set_segment(i,0,10,0,true)
      end
    end
  local actual= norm_d[s_far]
  local previous = e_dist[s_far].mindist
  local th_dist = 20
  if (actual > previous + th_dist or not range(actual)) then
    robot.hsm.queue_event(e_repos) --change state
  elseif (actual < 5 and range(actual)) then
    robot.hsm.queue_event(e_search)
  else
    e_dist[s_far].mindist = actual
  end
end


--STATES

local s_search = ahsm.state{
  entry = function()
    angle = 0
    for i,e in ipairs(e_dist) do
      e.mindist = 100
      e.decreasing = 0
    end
    omni.drive(0,0,w)
    laser.cb.append(callback_search)
    omni.enable(true)
  end,
  exit = function()
    laser.cb.remove(callback_search)
  end
}

local s_back = ahsm.state{
  entry = function()
    angle = 0
    omni.drive(0,0,-w)
    laser.cb.append(callback_back)
  end,
  exit = function()
    omni.drive(0,0,0)
    laser.cb.remove(callback_back)
  end
}

local s_position = ahsm.state{
  entry = function()
    omni.drive(0,0,w)
    laser.cb.append(callback_position)
  end,
  exit = function()
    omni.drive(0,0,0)
    laser.cb.remove(callback_position)
  end
}

local s_forward = ahsm.state{
  entry = function()
    local dirx = e_dist[s_far].dirx
    local diry = e_dist[s_far].diry
    omni.drive(dirx*v,diry*v,0)
    laser.cb.append(callback_forward)
  end,
  exit = function()
    omni.drive(0,0,0)
    laser.cb.remove(callback_forward)
  end
}

--TRANSITIONS

local t_reset = ahsm.transition{
  src = s_position, tgt = s_search,
  timeout = 2
}

local t_ksearch = ahsm.transition {
  src = s_search, tgt = s_search,
  events = {e_ksearch}
}

local t_back = ahsm.transition {
  src = s_search, tgt = s_back,
  events = {e_back}
}

local t_bsearch = ahsm.transition {
  src = s_back, tgt = s_search,
  events = {e_bsearch}
}

local t_forw = ahsm.transition {
  src = s_back, tgt = s_forward,
  events = {e_forward}
}

local t_reforw = ahsm.transition {
  src = s_position, tgt = s_forward,
  events = {e_reforward}
}

local t_psearch = ahsm.transition {
  src = s_position, tgt = s_search,
  events = {e_psearch}
}

local t_repos = ahsm.transition {
  src = s_forward, tgt = s_position,
  events = {e_repos}
}

local t_search = ahsm.transition {
  src = s_forward, tgt = s_search,
  events = {e_search}
}


local distance = ahsm.state {
  states = { SEARCH = s_search, BACK = s_back, POSITION = s_position, FORWARD = s_forward},
  transitions = {
    keep_search = t_ksearch,
    switch_back = t_back,
    switch_bsearch = t_bsearch,
    switch_reforw = t_reforw,
    switch_forw = t_forw,
    switch_repos = t_repos,
    switch_psearch = t_psearch,
    switch_search = t_search,
    reset_to_search = t_reset,
  },
  events = {
    e_ksearch,
    e_back,
    e_bsearch,
    e_reforward,
    e_forward,
    e_repos,
    e_psearch,
    e_search,
  },
  initial = s_search,
  entry = function()
    robot.laser_ring.enable(true)
    robot.color.enable(true)
  end,
  exit = function()
    robot.color.enable(false)
    robot.laser_ring.enable(false)
  end,
}

return distance

--dofile "main_ahsm.lua"
