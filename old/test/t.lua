local TEST_SEC = 100000 -- test for 10 seconds

local color = require('color')
local ledr = require 'led_ring'

local dump_rgb = function(r, g, b, a, h, s, v, hoff, soff, voff)
  print('rgba:', r, g, b, r+g+b, a, 'hsv:', h, s, v, 'hsvoff:', hoff, soff, voff)
end

local dump_color_change = function(name, h, s, v)
  print('COLOR:'..tostring(name), 'hsv:', h, s, v)
end

color.rgb_cb.append(dump_rgb)
color.color_cb.append(dump_color_change)

print('Start color monitoring for '..TEST_SEC..'s')
color.enable(true)

while true do
  tmr.sleep(5)
  ledr.set_all(255,0,0,true)
  tmr.sleep(5)
  ledr.set_all(0,255,0,true)
  tmr.sleep(5)
  ledr.set_all(0,0,255,true)
end

-- run for TEST_SEC seconds
tmr.sleep(TEST_SEC)

print('Done color monitoring')
color.enable(false)