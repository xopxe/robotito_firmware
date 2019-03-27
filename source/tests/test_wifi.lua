--- Test wifi.

local TEST_SEC = 10 -- test for 10 seconds

local wifi_net = require('wifi_net')
wifi_net.init()

local dump_msg = function(msg, ip, port)
  print(ip..':'..port, msg) 
end

print('Start wifi monitoring')
wifi_net.cb.append(dump_msg)

for i = 1, TEST_SEC do
  local m = 'message'..tostring(i) 
  print ('Sending', m)
  wifi_net.broadcast( m )
  tmr.sleep(1)
end
