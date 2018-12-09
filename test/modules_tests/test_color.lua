--- Test color sensor.

local TEST_SEC = 10 -- test for 10 seconds

local color = require('color')

local dump_rgb = function(r,g,b,a,h,s,v, name)
  print('argb:', a, r, g, b,'hsvc:', h, s, v, name)
end

local dump_color_change = function(name, s, v)
  print('! color:'..tostring(name), 'sv:', s, v)
end

color.rgb_cb.append(dump_rgb)
color.color_cb.append(dump_color_change)

print('Start color monitoring for '..TEST_SEC..'s')
color.enable(true)

-- run for TEST_SEC seconds
tmr.sleepms(TEST_SEC*1000)

print('Done color monitoring')
color.enable(false)
