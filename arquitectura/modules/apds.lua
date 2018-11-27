--- Module for the apds9960 color/distance/gesture sensor. 
-- @module apds
-- @alias M


local M = {}

local apds9960 = assert(require('apds9960'))

M.proximity = {}
--- The native C firmware module.
-- This can be used to access low level functionality from `apds9969.proximity`. FIXME: docs 
M.proximity.device = apds9960.proximity
--- Period of proximity measures in ms. Applied on @{M.proximity.threshold.enable}
M.proximity.period = 50 
--- Threshold for triggering @{M.proximity.threshold.cb}. Applied on @{M.proximity.threshold.enable}
M.proximity.thresh = 250
--- Hysteresis for triggering @{M.proximity.threshold.cb}. Applied on @{M.proximity.threshold.enable}
M.proximity.hysteresis = 3


M.proximity.threshold = {}

--- The callback module for the proximity sensor.
-- This is a callback list attached to the distance sensor, see @{cb_list}.
--This call triggers on threshold crossing, see @{M.proximity.thresh} and
-- @{M.proximity.hysteresis}
-- @usage local local apds = require'apds'
--apds.proximity.threshold.cb.append( function (v) print("greater:", v) end )
-- @param v true if distance is greater than threshold, false otherwise.
M.proximity.threshold.cb = require'cb_list'.get_list()

--- Enables the proximity threshold callback.
--@param mode true value to enable, false value to disable.
M.proximity.threshold.enable = function (mode)
  if mode then
    apds9960.proximity.get_dist_thresh(M.proximity.period, M.proximity.thresh, 
      M.proximity.histeresis, M.proximity.threshold.cb.call)
  else
    apds9960.proximity.get_dist_thresh(nil)
  end
end


M.color = {}

--- The native C firmware module.
-- This can be used to access low level functionality from `apds9969.color`. FIXME: docs 
M.color.device = apds9960.color

--- Period of color measures in ms. Applied on @{M.color.change.enable}
M.color.period = 50 

M.color.change = {}

--- The callback module for the color change sensor.
-- This is a callback list attached to the color sensor, see @{cb_list}.
-- @usage local local apds = require'apds'
--apds.color.change.cb.append( function (color, s, v) print(color, s, v) end )
M.color.change.cb = require'cb_list'.get_list

--- Enables the proximity threshold callback.
--@param mode true value to enable, false value to disable.
M.color.change.enable = function (mode)
  if mode then
    apds9960.color.get_change(M.color.period, M.color.change.cb.call)
  else
    apds9960.color.get_change(nil)
  end
end


--- Initialization.
-- This configures and starts the sensors.
M.init = function()
  assert(M.apds.init())
  assert(M.apds.proximity.enable())
  assert(M.apds.color.enable())

  --M.proximity.threshold.enable(true)
  --M.color.change.enable(true)
end

return M