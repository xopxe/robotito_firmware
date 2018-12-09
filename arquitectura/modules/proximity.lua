--- Downward facing proximity sensor. 
-- This modeule is used to detect when the robot is picked up.
-- @module proximity
-- @alias M
local M = {}

local apds9960 = assert(require('apds9960'))
assert(apds9960.init())

--- The native C firmware module.
-- This can be used to access low level functionality from `apds9969.proximity`. FIXME: docs 
M.device = apds9960.proximity

M.threshold = {}

--- The callback module for the proximity sensor.
-- This is a callback list attached to the proximity sensor, see @{cb_list}.
-- This call triggers on threshold crossing, see @{M.threshold.enable}.
-- The parameter of the callback is a boolean which is true when the object is close.
-- @usage local local proximity = require 'proximity'
--proximity.threshold.cb.append( function (v) print("close:", v) end )
-- @param v true if distance is greater than threshold, false otherwise.
M.threshold.cb = require'cb_list'.get_list()

--- Enables the proximity threshold callback.
-- When enabled, proximity changes will trigger @{M.threshold.cb}. 
-- @param on true value to enable, false value to disable.
-- @param period Sampling period in ms, if omitted is read from 
-- `nvs.read("proximity_sensor","period")`, defaults to 100. 
-- @param threshold proximity reference value, if omitted is read from 
-- `nvs.read("proximity_sensor","threshold")` (defaults to 250, about 2cm) 
-- @param hysteresis if omitted is read from `nvs.read("proximity_sensor","hysteresis")` 
-- (defaults to 3)
M.threshold.enable = function (on, period, threshold, hysteresis)
  if on then
    period = period or nvs.read("proximity_sensor","period", 100) or 100
    threshold = threshold or nvs.read("proximity_sensor","threshold", 250) or 250
    hysteresis = hysteresis or nvs.read("proximity_sensor","hysteresis", 3) or 3
    apds9960.proximity.get_dist_thresh(period, threshold, hysteresis,
      M.proximity.threshold.cb.call)
    apds9960.proximity.enable(true)
  else
    apds9960.proximity.enable(false)
    apds9960.proximity.get_dist_thresh(nil)
  end
end

return M