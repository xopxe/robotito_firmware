--- Test color sensor.

local TEST_SEC = 10 -- test for 10 seconds

local apds = require('apds')
apds.init()

local color = apds.color

local dump_rgb = function(r,g,b,a,h,s,v, name)
  print('argb:', a, r, g, b,'hsvc:', h, s, v, name)
end

local dump_color_change = function(name, s, v)
  print('! color:'..tostring(name), 'sv:', s, v)
end

color.light(true) --power on led

color.continuous.cb.append(dump_rgb)
color.change.cb.append(dump_color_change)

print('Start color monitoring for '..TEST_SEC..'s')
color.continuous.enable(true, true)
color.change.enable(true)

-- run for TEST_SEC seconds
tmr.sleepms(TEST_SEC*1000)

print('Done color monitoring')
color.continuous.enable(false)
color.change.enable(false)

color.light(false)
