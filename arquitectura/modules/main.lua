local ahsm = require("ahsm")
local robot = require("robot")

local align = require("fsm_align")
--local model = assert(rfsm.load("fsm_align.lua"))

robot.init()
robot.omni.set_enable()

local fsm = ahsm.init( align )

-- Events for fsm_on_off
---[[
local height_period = 50 -- period of distance measurements
local height_threshold = 251
local height_histeresis = 3

---[[
local function send(e)
  print('<', e)
  fsm.send_event(e)
end
local function loop(e)
  print( '===', fsm.loop())
end
--]]

--[[
local dump_dist = function(b)
    if b then
      send('e_floor')
    else
      send('e_not_floor')
    end
end

robot.height.get_dist_thresh(height_period, height_threshold, height_histeresis, dump_dist)
--]]


-- Events for fsm_algin
---[[
local no_object = function(norm_d, id_align)
  if (norm_d[id_align] == 0) then
    send('no_object')
  end
end
robot.laser_ring.no_object = no_object

local find_object = function(norm_d, id_align)
  if (norm_d[id_align] ~= 0) then
    send('find_object')
    --print("find_object")
  end
end
robot.laser_ring.find_object = find_object

local loosing_object = function(norm_d, id_align, previous_d)
  if (previous_d[id_align] > norm_d[id_align]) then
    send('loosing_object')
    --print("loosing_object")
  end
end
robot.laser_ring.loosing_object = loosing_object
--]]


--[[
local function main()
  while true do
    --print("step in")
    idle = rfsm.step(fsm, 1)
    --print("step out")
    tmr.sleepms(10)
    --thread.list(false, false, true)
  end
end
--]]

---[[

while 1 do 
    fsm.loop()
    tmr.sleepms(10)
end
--]]

--main()