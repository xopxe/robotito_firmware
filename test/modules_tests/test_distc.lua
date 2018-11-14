local apds = assert(require('apds9960'))

local min_sat = 50
local min_val = 20
local max_val = 200

local omni = require('omni')

omni.set_enable()

local colors = {
  {"red", 0, 60},
  {"yellow", 60, 120},
  {"green", 120, 180},
  {"cyan", 180, 240},
  {"blue", 240, 300},
  {"magenta", 300, 360},
}

assert(apds.init())
local distC = apds.proximity
assert(distC.enable())

ms = ms or 100

thershold = threshold or 250

histeresis = histeresis or 3




-- callback for distC.get_dist_thresh
-- will be called when the robot is over threshold high
dump_dist = function(b)
  ---[[
  if (b) then
    omni.drive(0,0,1)
  else
    omni.drive(0,0,0)
  end
  --]]
  print(b)
end

local proximity_cb_list = require'cb_list'.get_list()
proximity_cb_list.append(dump_dist)

-- enable distC change monitoring
distC.get_dist_thresh(ms, thershold, histeresis, proximity_cb_list.call)
