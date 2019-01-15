--- Test laser ring.

local TEST_SEC = 60 -- test for 60 seconds

local laser=require('laser_ring')
local ledr=require('led_ring')

local dump_ranges = function(d1, d2, d3, d4, d5, d6)
  print ('dist (mm):', d1, d2, d3, d4, d5, d6)
  local d = laser.norm_d
  for i=1, 6 do
    local v = 100-d[i]
    ledr.set_segment(i, v, v, v)
  end
  ledr.update()
end

-- pick one of the next two
laser.cb.append(laser.get_reading_cb())
--laser.cb.append(laser.get_filtering_cb())

laser.cb.append(dump_ranges)

print('Start monitoring ranges for '..TEST_SEC..'s')
laser.enable(true)

-- run for TEST_SEC seconds
tmr.sleepms(TEST_SEC*1000)

print('Done monitoring ranges')
laser.enable(false)

ledr.clear()
