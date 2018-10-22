local apds = assert(require('apds9960'))
local ledpin = pio.GPIO19
local n_pins = 24

local min_sat = 100
local min_val = 20
local max_val = 200

local colors = {
  {"yellow", 21, 60},
  {"green", 120, 200},
  {"blue", 200, 220},
  {"red", 300, 360},
  {"orange", 0, 20},
  {"violet", 221, 240},
}

assert(apds.init())
local distC = apds.proximity
assert(distC.enable())

local color = apds.color
assert(color.set_color_table(colors))
assert(color.set_sv_limits(min_sat,min_val,max_val))
assert(color.enable())

local led_const = require('led_ring')

local neo = led_const(pio.GPIO19, 24, 10)


local m = require('omni')
m.set_enable()

local ms_dist = 400
local ms_color = 100
local thershold = 251
local histeresis = 3

local H_OFF = {"H_OFF"}
local H_ON = {"H_ON"}
local h_state = H_OFF

-- callback for distC.get_dist_thresh
-- will be called when the robot is over threshold high
local dump_dist = function(b)
      if b then
        h_state = H_ON
      else
        h_state = H_OFF
        m.drive(0,0,0)
      end
end

-- enable distC change monitoring
distC.get_dist_thresh(ms_dist, thershold, histeresis, dump_dist)

function turn_all_leds(r,g,b)
  -- neo.clear()
  for pixel=0,24 do
    neo.set_led(pixel, r, g, b, true)
    tmr.delayms(1)
  end
end

set_motors_from_color = function(c)
  local MAX_VEL = 0.08
  if h_state == H_ON then
    --print('color', c, 'sv', s, v)
    if c == "red" then
      m.drive(MAX_VEL,0,0)
      turn_all_leds(50,0,0)
    elseif c == 'blue' then
      m.drive(-MAX_VEL,0,0)
      turn_all_leds(0,0,50)
    elseif c == 'green' then
      m.drive(0,MAX_VEL,0)
      turn_all_leds(0,50,0)
    elseif c == 'orange'  then
      m.drive(0,-MAX_VEL,0)
      turn_all_leds(255,70,0) -- orange
      -- turn_all_leds(255,0,255) -- violet
      -- turn_all_leds(255,255,0) -- yellow
    --else
      --turn_all_leds(0,0,0)
    end
  end
end

change_direction = function(c, s, v)
  set_motors_from_color(c)
end

-- callback for color.get_continuous
-- will be called with (r,g,b,a [,h,s,v])
-- hsv will be provided if enabled on color.get_continuous
-- r,g,b,a : 16 bits
-- h: 0..360
-- s,v: 0..255
dump_rgb = function(r,g,b,a,h,s,v, name)
  -- print('ambient:', a, 'rgb:', r, g, b,'hsv:', h, s, v, 'name:', name)
  set_motors_from_color(name)
end

--power on led
local led_color_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_color_pin)
pio.pin.sethigh(led_color_pin)

m.set_enable()


-- enable raw color monitoring, enable hsv mode
color.get_continuous(ms_color, dump_rgb, true)

-- enable color change monitoring, enable hsv mode
-- color.get_change(ms, change_direction)
