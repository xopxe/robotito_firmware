--- Test proximity sensor.

local TEST_SEC = 10 -- test for 10 seconds

local proximity = require('proximity')

local dump_dist = function(b)
  print('close:', b)
end

proximity.threshold.cb.append(dump_dist)

print('Start proximity monitoring for '..TEST_SEC..'s')
proximity.threshold.enable(true)

-- run for TEST_SEC seconds
tmr.sleepms(TEST_SEC*1000)

print('Done proximity monitoring')
proximity.threshold.enable(false)
