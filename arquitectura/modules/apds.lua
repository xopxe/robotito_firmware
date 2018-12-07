--- Module for the apds9960 color/proximity/gesture sensor. 
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
-- @module apds
-- @alias M
local M = {}

local led_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_pin)

local apds9960 = assert(require('apds9960'))

local refcount_color_cb = 0

M.proximity = {}
--- The native C firmware module.
-- This can be used to access low level functionality from `apds9969.proximity`. FIXME: docs 
M.proximity.device = apds9960.proximity

M.proximity.threshold = {}

--- The callback module for the proximity sensor.
-- This is a callback list attached to the proximity sensor, see @{cb_list}.
-- This call triggers on threshold crossing, see @{M.proximity.threshold.enable}.
-- The parameter of the callback is a boolean which is true when the object is close.
-- @usage local local apds = require 'apds'
--apds.proximity.threshold.cb.append( function (v) print("close:", v) end )
-- @param v true if distance is greater than threshold, false otherwise.
M.proximity.threshold.cb = require'cb_list'.get_list()

--- Enables the proximity threshold callback.
-- When enabled, proximity changes will trigger @{M.proximity.threshold.cb}. 
-- @param on true value to enable, false value to disable.
-- @param period Sampling period in ms, if omitted is read from 
-- `nvs.read("proximity_sensor","period")`, deafults to 100. 
-- @param threshold proximity reference value, if omitted is read from 
-- `nvs.read("proximity_sensor","threshold")` (deafults to 250, about 2cm) 
-- @param hysteresis if omitted is read from `nvs.read("proximity_sensor","hysteresis")` 
-- (deafults to 3)
M.proximity.threshold.enable = function (on, period, threshold, hysteresis)
  if on then
    period = period or nvs.read("proximity_sensor","period", 100) or 100
    threshold = threshold or nvs.read("proximity_sensor","threshold", 250) or 250
    hysteresis = hysteresis or nvs.read("proximity_sensor","hysteresis", 3) or 3
    apds9960.proximity.get_dist_thresh(period, threshold, hysteresis,
      M.proximity.threshold.cb.call)
    apds9960.color.enable(true)
  else
    apds9960.color.enable(false)
    apds9960.proximity.get_dist_thresh(nil)
  end
end


M.color = {}

--- The native C firmware module.
-- This can be used to access low level functionality from `apds9969.color`. FIXME: docs 
M.color.device = apds9960.color

--- Control the LED light for the color sensor.
-- @param on true to switch on, false to switch off.
M.color.light = function (on)
  if on then pio.pin.sethigh(led_pin)
  else pio.pin.setlow(led_pin) end
end

M.color.change = {}

--- The callback module for the color change sensor.
-- This is a callback list attached to the color sensor, see @{cb_list}.
-- The callback will be called with `(color, s, v)`  
-- `* color`: one of "red", "yellow", "green", "blue", "magenta", "black", 
-- "white", "unknown"  
-- `* s,v`: 0..255  
-- @usage local local apds = require'apds'
--apds.color.change.cb.append( function (color, s, v) print(color, s, v) end )
M.color.change.cb = require'cb_list'.get_list()

--- Enables the color change callback.
-- When enabled, color changes will trigger @{M.color.change.cb}.  
-- @param on true value to enable, false value to disable.
-- @param period Sampling period in ms, if omitted is read from 
-- `nvs.read("color_sensor","period")`, deafults to 100. 
M.color.change.enable = function (on, period)
  if on then
    period = period or nvs.read("color_sensor","period", 100) or 100
    apds9960.color.get_change(period, M.color.change.cb.call)
    if refcount_color_cb == 0 then 
      apds9960.proximity.enable(true)
    end
    refcount_color_cb = refcount_color_cb + 1
  else
    refcount_color_cb = refcount_color_cb - 1
    if refcount_color_cb == 0 then 
      apds9960.proximity.enable(false)
    end
    apds9960.color.get_change(nil)
  end
end

M.color.continuous = {}

--- The callback module for the color monitoring sensor.
-- This is a callback list attached to the color sensor, see @{cb_list}. 
-- The callback will be called with `(r,g,b,a [,h,s,v, color])`  
-- hsv will be provided if HSV mode enabled (see @{M.color.continuous.enable})  
-- * `r,g,b,a` : 16 bits  
-- * `h`: 0..360  
-- * `s,v`: 0..255  
-- * `color`: one of "red", "yellow", "green", "blue", "magenta", "black", 
-- "white", "unknown" 
-- @usage local local apds = require'apds'
--apds.color.continuous.cb.append( function (r, g, b, a) print(r, g, b, a) end )
M.color.continuous.cb = require'cb_list'.get_list()

--- Enables the color monitoring callback. 
-- See @{M.color.continuous.cb}. The period in ms to use is read from `nvs.read("color_sensor","period")`, deafults to 100.  
-- @param on true value to enable, false value to disable.
-- @param hsv true to set HSV mode (see @{M.color.continuous.cb})
M.color.continuous.enable = function (on, hsv)
  if on then
    local period = nvs.read("color_sensor","period", 100) or 100
    apds9960.color.get_continuous(period, M.color.continuous.cb.call, hsv)
    if refcount_color_cb == 0 then 
      apds9960.proximity.enable(true)
    end
    refcount_color_cb = refcount_color_cb + 1
  else
    refcount_color_cb = refcount_color_cb - 1
    if refcount_color_cb == 0 then 
      apds9960.proximity.enable(false)
    end
    apds9960.color.get_continuous(nil)
  end
end


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

  assert(apds9960.init())
  assert(apds9960.color.set_color_table(colors))
  assert(apds9960.color.set_sv_limits(min_sat,min_val,max_val))
end

return M