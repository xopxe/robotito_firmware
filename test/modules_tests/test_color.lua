--- Test color sensor.

local TEST_SEC = 10 -- test for 10 seconds

local apds = require('apds')
apds.init()

local color = apds.color
local uart_write, uart_CONSOLE = uart.write, uart.CONSOLE

local dump_rgb = function(r,g,b,a,h,s,v, name)
  --print('argb:', a, r, g, b,'hsvc:', h, s, v, name)
  uart_write(uart_CONSOLE, 'ambient='..tostring(a)..' (r,g,b)=(' 
    ..tostring(r)..','..tostring(g)..','..tostring(b)..') (h,s,v)=('
    ..tostring(h)..','..tostring(s)..','..tostring(v)..') color='
    ..tostring(name)..'\r\n')
end

local dump_color_change = function(name, s, v)
  --print('color', c, 'sv', s, v)
  uart_write(uart_CONSOLE, 'color='..tostring(name)..' (s,v)=('
    ..tostring(s)..','..tostring(v)..')\r\n')
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
