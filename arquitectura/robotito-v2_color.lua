local apds = assert(require('apds9960'))
local ledpin = pio.GPIO19
local n_pins = 24
local led_pow = 10

local min_sat = 60
local min_val = 40
local max_val = 270

local colors = {
  -- {"orange", 12, 17}, -- 12
  {"yellow", 5, 70},
  {"green", 159, 180},
  {"blue", 200, 225}, -- 210
  {"rose", 255, 300}, -- 265
  {"red", 351 , 359}, -- 353

  -- {"violet", 221, 240},
}

assert(apds.init())
local distC = apds.proximity
assert(distC.enable())

local color = apds.color
assert(color.set_color_table(colors))
assert(color.set_sv_limits(min_sat,min_val,max_val))
assert(color.enable())

local led_const = require('led_ring')
local neo = led_const(ledpin, n_pins, led_pow)

local m = require('omni')
m.set_enable()

local ms_dist = 400
local ms_color = 80
local thershold = 251
local histeresis = 3

local H_OFF = {"H_OFF"}
local H_ON = {"H_ON"}
local h_state = H_OFF

local last_color = "NONE"
local tics_same_color = 0
local TICS_NEW_COLOR = 4

local x_dot = 0
local y_dot = 0
local w = 0

-- callback for distC.get_dist_thresh
-- will be called when the robot is over threshold high
local dump_dist = function(b)
      if b then
        last_color = "NONE"
        tics_same_color = 0
        h_state = H_ON
      else
        x_dot = 0
        y_dot = 0
        w = 0
        m.drive(x_dot,y_dot,w)
        -- neo.clear()
        turn_all_leds(0,0,0)
        h_state = H_OFF
      end
end

-- enable distC change monitoring
distC.get_dist_thresh(ms_dist, thershold, histeresis, dump_dist)

function turn_all_leds(r,g,b)
  if (r + g + b) == 0 then  -- draw axis
    neo.clear()
    -- neo.set_led(8, 50,0,0, true)
    -- neo.set_led(14,0,50,0 , true)
    -- neo.set_led(20, 0,0,50 , true)
    -- neo.set_led(2,160 , 100, 0, true)
    neo.set_led(2, 50,0,0, true)
    neo.set_led(8,0,50,0 , true)
    neo.set_led(14, 0,0,50 , true)
    neo.set_led(20,160 , 100, 0, true)
  else
    for pixel= 0, 24 do
      neo.set_led(pixel, r, g, b, true)
    end
  end
end

dump_rgb = function(r,g,b,a,h,s,v, c)
  local MAX_VEL = 0.06

  if h_state == H_ON then
    --print('color', c, 'sv', s, v)
    if last_color == c then
      if tics_same_color < TICS_NEW_COLOR then
        tics_same_color = tics_same_color + 1
      elseif tics_same_color == TICS_NEW_COLOR then
        -- print('new color')
        if c == "red" then
          x_dot = MAX_VEL
          y_dot = 0
          w = 0
          turn_all_leds(50,0,0)
        elseif c == 'blue' then
          x_dot = -MAX_VEL
          y_dot = 0
          w = 0
          turn_all_leds(0,0,50)
        elseif c == 'green' then
          x_dot = 0
          y_dot = MAX_VEL
          w = 0
          turn_all_leds(0,50,0)
        elseif c == 'yellow' then --or c == 'orange'  then
          x_dot = 0
          y_dot = -MAX_VEL
          w = 0
          -- turn_all_leds(255,0,140) -- violet
          -- turn_all_leds(255,70,0) -- orange
          turn_all_leds(160,100,0) -- yellow
        -- else
        --   turn_all_leds(0,0,0)
        end
        m.drive(x_dot,y_dot,w)
      end
    else
      last_color = c
      tics_same_color = 0
    end
  end
  -- print('ambient:', a, 'rgb:', r, g, b,'hsv:', h, s, v, 'name:', name)
end

-- callback for color.get_continuous
-- will be called with (r,g,b,a [,h,s,v])
-- hsv will be provided if enabled on color.get_continuous
-- r,g,b,a : 16 bits
-- h: 0..360
-- s,v: 0..255

--power on led
local led_color_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_color_pin)
pio.pin.sethigh(led_color_pin)

m.set_enable()

turn_all_leds(0,0,0)

-- enable raw color monitoring, enable hsv mode
color.get_continuous(ms_color, dump_rgb, true)

-- enable color change monitoring, enable hsv mode
-- color.get_change(ms, change_direction)

print("ready to playt with colors")
