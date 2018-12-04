--- Test laser ring.

local TEST_SEC = 10 -- test for 10 seconds

local laser=require('laser_ring')
laser.init()

local dump_ranges = function(d1, d2, d3, d4, d5, d6)
  print ('dist (mm):', d1, d2, d3, d4, d5, d6)
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

