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
-- @module color
-- @alias M
local M = {}

-- Configure apds9960 color sensor
local apds9960 = require('apds9960robotitorobotito')
assert(apds9960.init())
do
  local min_sat = nvs.read("color_sensor","min_sat", 24)
  local min_val = nvs.read("color_sensor","min_val", 40)
  local max_val = nvs.read("color_sensor","max_val", 270)

  local colors = {
    {"red", 
      nvs.read("color_sensor","min_h_red", 351), 
      nvs.read("color_sensor","max_h_red", 359),
    },
    {"yellow", 
      nvs.read("color_sensor","min_h_yellow", 22), 
      nvs.read("color_sensor","max_h_yellow", 65),
    },
    {"green", 
      nvs.read("color_sensor","min_h_green", 159), 
      nvs.read("color_sensor","max_h_green", 180),
    },
    {"blue", 
      nvs.read("color_sensor","min_h_blue", 209), 
      nvs.read("color_sensor","max_h_blue", 215),
    },
    {"magenta", 
      nvs.read("color_sensor","min_h_magenta", 255), 
      nvs.read("color_sensor","max_h_magenta", 300),
    },
  }

  assert(apds9960.color.set_color_table(colors))
  assert(apds9960.color.set_sv_limits(min_sat,min_val,max_val))
end

--- The native C firmware module.
-- This can be used to access low level functionality from `apds9960.color`. FIXME: docs 
M.device = apds9960.color

--- The callback the color change.
-- This is a callback list attached to the color sensor, see @{cb_list}.
-- The callback will be called with `(color, s, v)`  
-- `* color`: one of "red", "yellow", "green", "blue", "magenta", "black", 
-- "white", "unknown"  
-- `* s,v`: 0..255  
-- @usage local local color = require'color'
--color.color_cb.append( function (color, s, v) print(color, s, v) end )
M.color_cb = require'cb_list'.get_list()
apds9960.color.set_color_callback(M.color_cb.call)

--- The callback for the RGBA dump.
-- This is a callback list attached to the color sensor, see @{cb_list}. 
-- The callback will be called with `(r,g,b,a)`  
-- * `r,g,b,a` : 16 bits  
-- @usage local local color = require'color'
--color.continuous.cb.append( function (r, g, b, a) print(r, g, b, a) end )
M.rgb_cb = require'cb_list'.get_list()
apds9960.color.set_rgb_callback(M.rgb_cb.call)

--- Enables the callbacks.
-- When enabled, the driver will trigger @{color_cb} and @{rgb_cb}.  
-- @param on true value to enable, false value to disable.
-- @param period Sampling period in ms, if omitted is read from 
-- `nvs.read("color_sensor","period")`, deafults to 500. 
M.enable = function (on, period)
  if on then
    period = period or nvs.read("color_sensor","period", 500)
    apds9960.color.enable(true)
  else
    apds9960.color.enable(false)
  end
end

return M