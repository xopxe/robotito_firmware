local apds = assert(require('apds9960'))
local ledpin = pio.GPIO19
local n_pins = 24

local min_sat = 100
local min_val = 20
local max_val = 200

local colors = {
  {"yellow", 0, 60},
  {"green", 120, 200},
  {"blue", 200, 230},
  {"red", 300, 360},
}

assert(apds.init())
local color = apds.color
assert(color.set_color_table(colors))
assert(color.set_sv_limits(min_sat,min_val,max_val))
assert(color.enable())

local led_const = require('led_ring')

local neo = led_const(pio.GPIO19, 24, 20)


local m = require('omni')
m.set_enable()

local ms = 100

function turn_all_leds(r,g,b)
  neo.clear()
  for pixel=0,24 do
    neo.set_led(pixel, r, g, b, true)
--    tmr.delayms(100)
  end
end

-- callback for color.get_continuous
-- will be called with (r,g,b,a [,h,s,v])
-- hsv will be provided if enabled on color.get_continuous
-- r,g,b,a : 16 bits
-- h: 0..360
-- s,v: 0..255
dump_rgb = function(r,g,b,a,h,s,v, name)
  print('ambient:', a, 'rgb:', r, g, b,'hsv:', h, s, v, 'name:', name)
end


change_direction = function(c, s, v)
  --print('color', c, 'sv', s, v)
  if c == "red" then
    m.drive(0.05,0,0)
    turn_all_leds(50,0,0)
  elseif c == 'blue' then
    m.drive(-0.05,0,0)
    turn_all_leds(0,0,50)
  elseif c == 'green' then
    m.drive(0,0.05,0)
    turn_all_leds(0,50,0)
  elseif c == 'yellow'  then
    m.drive(0,-0.05,0)
    turn_all_leds(255,255,0)
  --else
    --turn_all_leds(0,0,0)
  end

end


--power on led
local led_color_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_color_pin)
pio.pin.sethigh(led_color_pin)

m.set_enable()


-- enable raw color monitoring, enable hsv mode
--color.get_continuous(ms, dump_rgb, true)

-- enable color change monitoring, enable hsv mode
color.get_change(ms, change_direction)
