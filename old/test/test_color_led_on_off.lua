local apds = assert(require('apds9960'))

local min_sat = nvs.read("color_sensor","min_sat")
local min_val = nvs.read("color_sensor","min_val")
local max_val = nvs.read("color_sensor","max_val")

local colors = {
  {"red", nvs.read("color_sensor","min_h_red"), nvs.read("color_sensor","max_h_red")},
  {"yellow", nvs.read("color_sensor","min_h_yellow"), nvs.read("color_sensor","max_h_green")},
  {"green", nvs.read("color_sensor","min_h_green"), nvs.read("color_sensor","max_h_green")},
  {"blue", nvs.read("color_sensor","min_h_blue"), nvs.read("color_sensor","max_h_blue")},
  {"magenta", nvs.read("color_sensor","min_h_magenta"), nvs.read("color_sensor","max_h_magenta")},
}

assert(apds.init())
local color = apds.color
assert(color.set_color_table(colors))
assert(color.set_sv_limits(min_sat,min_val,max_val))
assert(color.enable())

ms = ms or 100



-- callback for color.get_continuous
-- will be called with (r,g,b,a [,h,s,v])
-- hsv will be provided if enabled on color.get_continuous
-- r,g,b,a : 16 bits
-- h: 0..360
-- s,v: 0..255

local led_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_pin)

local led_on = false
local dif_h = 0
local pre_h = 0

dump_rgb = function(r,g,b,a,h,s,v, name)
  -- print('ambient:', a, 'rgb:', r, g, b,'hsv:', h, s, v, 'name:', name)
  -- uart.write(uart.CONSOLE, 'ambient: ' .. a .. '. color: ' .. name .. '. h: ' .. h .. '. s: ' .. s .. '. v: ' .. v .. '\r\n')
  uart.write(uart.CONSOLE, 'ambient: ' .. a .. '. color: ' .. name .. '. h: ' .. h .. '. s: ' .. s .. '. v: ' .. v ..  '. dif_h: ' .. dif_h .. '\r\n')
  if led_on then
    dif_h = h - pre_h
    --power on led
    pio.pin.setlow(led_pin)
  else
    pre_h = h
    --power on led
    pio.pin.sethigh(led_pin)
  end

  led_on = not led_on
end

dump_rgb_simple = function(r,g,b,a,h,s,v, name)
  -- print('ambient:', a, 'rgb:', r, g, b,'hsv:', h, s, v, 'name:', name)
  -- uart.write(uart.CONSOLE, 'ambient: ' .. a .. '. color: ' .. name .. '. h: ' .. h .. '. s: ' .. s .. '. v: ' .. v .. '\r\n')
  uart.write(uart.CONSOLE, 'ambient: ' .. a .. '. color: ' .. name .. '. h: ' .. h .. '. s: ' .. s .. '. v: ' .. v .. '\r\n')
end

-- callback for get_change
-- will be called with (color, s, v)
-- color: one of "red", "yellow", "green", "cyan", "blue", "magenta"
-- s,v: 0..255
dump_color_change = function(c, s, v)
  print('color', c, 'sv', s, v)
end

print('Start color monitoring')
-- enable raw color monitoring, enable hsv mode
color.get_continuous(ms, dump_rgb, true)

-- enable color change monitoring, enable hsv mode
-- color.get_change(ms, dump_color_change)

--[[
while true do
  tmr.sleepms(50)
  print (color.get_rgb())
end
--]]

-- run for 60 seconds
tmr.sleepms(60*1000)

-- stop monitoring distances
color.get_continuous(false)
color.get_change(false)

pio.pin.setlow(led_pin)

print('Stop color monitoring')
