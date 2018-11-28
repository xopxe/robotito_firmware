--- Test prosimity sensor.

local TEST_SEC = 10 -- test for 10 seconds

local apds = require('apds')
apds.init()

local proximity = apds.proximity
local uart_write, uart_CONSOLE = uart.write, uart.CONSOLE

local dump_dist = function(b)
  uart_write(uart_CONSOLE, 'close: '..tostring(b)..'\r\n')
end

proximity.threshold.cb.append(dump_dist)

print('Start proximity monitoring for '..TEST_SEC..'s')
proximity.threshold.enable(true)

-- run for TEST_SEC seconds
tmr.sleepms(TEST_SEC*1000)

print('Done proximity monitoring')
proximity.threshold.enable(false)
