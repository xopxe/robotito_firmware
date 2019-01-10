--- Downward facing color sensor. 
-- Color definitions and setings are loaded using `nvs.read("color_sensor", parameter)` 
-- calls, where the available parameters are:  
--  
-- * `"min_sat"` If the saturaion is below this, color is 'unknown' (default is 24)  
-- * `"min_val"` If the value is below this, color is 'black' (default is 40)  
-- * `"max_val"` If the value is above this, color is 'white' (default is 270)  
-- * `"min_h_red"`, `"max_h_red"` Hue range for 'red' (default is 351, 359)  
-- * `"min_h_yellow"`, `"max_h_yellow"` Hue range for 'yellow' (default is 22, 65)   
-- * `"min_h_green"`, `"max_h_green"` ` Hue range for 'green' (default is 159, 180)   
-- * `"min_h_blue"`, `"max_h_blue"` ` Hue range for 'blue' (default is 209, 215)   
-- * `"min_h_magenta"`, `"max_h_magenta"` ` Hue range for 'magenta' (default is 255, 300)  
--
-- These parameters are used in low-level calls, and are the native 
-- 16 bits values FIXME
--
-- @module color
-- @alias M
local M = {}

-- Configure apds9960 color sensor
local apds9960r = require('apds9960')
assert(apds9960r.init())
do
  --local min_sat = nvs.read("color_sensor","min_sat", 24)
  local min_val = nvs.read("color_sensor","min_val", 40)
  local max_val = nvs.read("color_sensor","max_val", 260)
  local dh = nvs.read("color_sensor","delta_h", 10)
  local ds = nvs.read("color_sensor","delta_s", 50)
  local dv = nvs.read("color_sensor","delta_v", 50)

  local colors = {
    {"red", 
      nvs.read("color_sensor","red_h", 348), 
      nvs.read("color_sensor","red_s", 170), 
      nvs.read("color_sensor","red_v", 135), 
    },
    {"yellow", 
      nvs.read("color_sensor","yellow_h", 70), 
      nvs.read("color_sensor","yellow_s", 226), 
      nvs.read("color_sensor","yellow_v", 228), 
    },
    {"green", 
      nvs.read("color_sensor","green_h", 181), 
      nvs.read("color_sensor","green_s", 250), 
      nvs.read("color_sensor","green_v", 175), 
    },
    {"blue", 
      nvs.read("color_sensor","blue_h", 214), 
      nvs.read("color_sensor","blue_s", 312), 
      nvs.read("color_sensor","blue_v", 180), 
    },
    {"magenta", 
      nvs.read("color_sensor","magenta_h", 260), 
      nvs.read("color_sensor","magenta_s", 170), 
      nvs.read("color_sensor","magenta_v", 135),
    },
  }
  
  local gain = nvs.read("color_sensor","gain", 1) -- default 2x

  assert(apds9960r.color.set_color_table(colors))
  assert(apds9960r.color.set_sv_limits(dh, ds, dv, min_val,max_val))
  assert(apds9960r.color.set_ambient_gain(gain))
end

local color_rgb = {
  ['red'] = {100,0,0},
  ['yellow'] = {50,50,0},
  ['green'] = {0,100,0},
  ['blue'] = {0,0,100},
  ['magenta'] = {50,0,50},
}
--- Named RGB colors.
-- This is a table where the key is one of 'red', 'yellow', 'green', 'blue'
-- or 'magenta', and the value is a three-element array with the color's
-- RGB components.
M.color_rgb = color_rgb 


--- The native C firmware module.
-- This can be used to access low level functionality from `apds9960.color`. FIXME: docs 
M.device = apds9960r.color

--- The callback the color change.
-- This is a callback list attached to the color sensor, see @{cb_list}.
-- The callback will be called with `(color, h, s, v)` when a color change 
-- is detected  
-- `* color`: one of "red", "yellow", "green", "blue", "magenta", "black", 
-- "white", "unknown"  
-- `* h`: 0..360  
-- `* s,v`: 0..255  
-- @usage local local color = require'color'
-- color.color_cb.append( function (color, h, s, v) print(color, h, s, v) end )
-- color.enable(true)
M.color_cb = require'cb_list'.get_list()
apds9960r.color.set_color_callback(M.color_cb.call)

--- The callback for the RGBA dump.
-- This is a callback list attached to the color sensor, see @{cb_list}. 
-- The callback will be called with `(r,g,b,a,h,s,v)`  
-- * `r,g,b,a` : 16 bits    
-- `* h`: 0..360  
-- `* s,v`: 0..255  
-- @usage local local color = require'color'
-- color.continuous.cb.append( function (...) print('color', ...) end )
-- color.enable(true)
M.rgb_cb = require'cb_list'.get_list()
apds9960r.color.set_rgb_callback(M.rgb_cb.call)

--power on led
local led_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_pin)

--- Enables the callbacks.
-- When enabled, the driver will trigger @{color_cb} and @{rgb_cb}.  
-- @tparam boolean on true value to enable, false value to disable.
-- @tparam[opt=200] integer period Sampling period in ms, if omitted is 
-- read from `nvs.read("color_sensor","period")`. 
M.enable = function (on, period)
  if on then
    pio.pin.sethigh(led_pin)
    period = period or nvs.read("color_sensor","period", 200) or 200
    apds9960r.color.enable(period)
  else
    apds9960r.color.enable(false)
    pio.pin.setlow(led_pin)
  end
end

return M