local rfsm = require("rfsm")
local robot = require("robot")

--local model = assert(rfsm.load("fsm_on_off.lua"))
local model = assert(rfsm.load("fsm_align.lua"))
local fsm = rfsm.init(model)

robot.init()

-- Events for fsm_on_off
--[[
local height_period = 50 -- period of distance measurements
local height_threshold = 251
local height_histeresis = 3

local dump_dist = function(b)
    if b then
      rfsm.send_events(fsm, 'e_on')
    else
      rfsm.send_events(fsm, 'e_off')
    end
end

robot.height.get_dist_thresh(height_period, height_threshold, height_histeresis, dump_dist)
--]]


-- Events for fsm_algin
---[[
local no_object = function(norm_d, id_align)
  if (norm_d[id_align] == 0) then
    rfsm.send_events(fsm, 'no_object')
    --print("no_object")
  end
end
robot.laser_ring.no_object = no_object

local find_object = function(norm_d, id_align)
  if (norm_d[id_align] ~= 0) then
    rfsm.send_events(fsm, 'find_object')
    --print("find_object")
  end
end
robot.laser_ring.find_object = find_object

local loosing_object = function(norm_d, id_align, previous_d)
  if (previous_d[id_align] > norm_d[id_align]) then
    rfsm.send_events(fsm, 'loosing_object')
    --print("loosing_object")
  end
end
robot.laser_ring.loosing_object = loosing_object
--]]


---[[
local function main()
  while true do
    idle = rfsm.step(fsm, 10)
    tmr.sleepms(10)
  end
end
--]]

main()