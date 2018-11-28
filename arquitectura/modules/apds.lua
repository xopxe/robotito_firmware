--- Module for the apds9960 color/distance/gesture sensor. 
-- @module apds
-- @alias M
local M = {}

local led_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_pin)

local apds9960 = assert(require('apds9960'))

M.proximity = {}
--- The native C firmware module.
-- This can be used to access low level functionality from `apds9969.proximity`. FIXME: docs 
M.proximity.device = apds9960.proximity

M.proximity.threshold = {}

--- The callback module for the proximity sensor.
-- This is a callback list attached to the distance sensor, see @{cb_list}.
--This call triggers on threshold crossing, see @{M.proximity.threshold.enable}. The parameter of the callback is a boolean which is true when the object is close.
-- @usage local local apds = require'apds'
--apds.proximity.threshold.cb.append( function (v) print("close:", v) end )
-- @param v true if distance is greater than threshold, false otherwise.
M.proximity.threshold.cb = require'cb_list'.get_list()

--- Enables the proximity threshold callback.
-- See @{M.proximity.threshold.cb}. The period in ms to use is read from `nvs.read("proximity_sensor","period")` (deafults to 100), the threshold is is read from `nvs.read("proximity_sensor","threshold")` (deafults to 250) and the hysteresis is read from `nvs.read("proximity_sensor","hysteresis")` (deafults to 3). 
--@param on true value to enable, false value to disable.
M.proximity.threshold.enable = function (on)
  if on then
    local period = nvs.read("proximity_sensor","period", 100) or 100
    local threshold = nvs.read("proximity_sensor","threshold", 250) or 250
    local hysteresis = nvs.read("proximity_sensor","hysteresis", 3) or 3
    apds9960.proximity.get_dist_thresh(period, threshold, hysteresis,
      M.proximity.threshold.cb.call)
  else
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
-- See @{M.color.change.cb}. The period in ms to use is read from `nvs.read("color_sensor","period")`, deafults to 100. 
--@param on true value to enable, false value to disable.
M.color.change.enable = function (on)
  if on then
    local period = nvs.read("color_sensor","period", 100) or 100
    apds9960.color.get_change(period, M.color.change.cb.call)
  else
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
--@param on true value to enable, false value to disable.
--@param hsv true to set HSV mode (see @{M.color.continuous.cb})
M.color.continuous.enable = function (on, hsv)
  if on then
    local period = nvs.read("color_sensor","period", 100) or 100
    apds9960.color.get_continuous(period, M.color.continuous.cb.call, hsv)
  else
    apds9960.color.get_continuous(nil)
  end
end


--- Initialization.
-- This configures and starts the sensors.  
-- The color sensor is configured with a color table. TODO docs.
M.init = function()
  local min_sat = nvs.read("color_sensor","min_sat")
  local min_val = nvs.read("color_sensor","min_val")
  local max_val = nvs.read("color_sensor","max_val")

  local colors = {
    {"red", 
      nvs.read("color_sensor","min_h_red"), 
      nvs.read("color_sensor","max_h_red"),
    },
    {"yellow", 
      nvs.read("color_sensor","min_h_yellow"), 
      nvs.read("color_sensor","max_h_yellow"),
    },
    {"green", 
      nvs.read("color_sensor","min_h_green"), 
      nvs.read("color_sensor","max_h_green"),
    },
    {"blue", 
      nvs.read("color_sensor","min_h_blue"), 
      nvs.read("color_sensor","max_h_blue"),
    },
    {"magenta", 
      nvs.read("color_sensor","min_h_magenta"), 
      nvs.read("color_sensor","max_h_magenta"),
    },
  }

  assert(apds9960.init())
  assert(apds9960.proximity.enable())
  assert(apds9960.color.enable())

  assert(apds9960.color.set_color_table(colors))
  assert(apds9960.color.set_sv_limits(min_sat,min_val,max_val))

  --M.proximity.threshold.enable(true)
  --M.color.change.enable(true)
end

return M