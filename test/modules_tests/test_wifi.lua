--- Test wifi.

local TEST_SEC = 10 -- test for 10 seconds

local wifi_net = require('wifi_net')
wifi_net.init()

local uart_write, uart_CONSOLE = uart.write, uart.CONSOLE
local table_concat = table.concat

local dump_rgb = function(s, ip, port)
  print(ip..':'..port, s) 
end

uart_write(uart_CONSOLE, 'Start wifi monitoring\r\n')
wifi_net.cb.append(dump_rgb)

for i = 1, TEST_SEC do
  local m = 'message'..tostring(i) 
  print ('Sending', m)
  wifi_net.broadcast( m )
  tmr.sleep(1)
end
