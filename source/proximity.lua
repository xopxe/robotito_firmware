--- Downward facing proximity sensor.
-- This modeule is used to detect when the robot is picked up.
-- @module proximity
-- @alias M
local M = {}

local apds9960r = assert(require('apds9960'))
assert(apds9960r.init())
assert(apds9960r.enable_power())

local cont_enables = 0

--- The native C firmware module.
-- This can be used to access low level functionality from `apds9969.proximity`. FIXME: docs
M.device = apds9960r.proximity

--- The callback module for the proximity sensor.
-- This is a callback list attached to the proximity sensor, see @{cb_list}.
-- This call triggers on threshold crossing, see @{enable}.
-- The parameter of the callback is a boolean which is true when the object is close.
-- @usage local local proximity = require 'proximity'
--proximity.cb.append( function (v) print("too close:", v) end )
M.cb = require'cb_list'.get_list()
apds9960r.proximity.set_callback(M.cb.call)

--- Enables the proximity callback.
-- When enabled, proximity changes will trigger @{cb}.
-- @tparam boolean on true value to enable, false value to disable.
-- @tparam[opt=100] integer period Sampling period in ms, if omitted is read
-- from `nvs.read("proximity","period")`.
-- @tparam[opt=250] integer threshold proximity reference value, if omitted is
-- read from `nvs.read("proximity","threshold")`
-- @tparam[opt=3] integer hysteresis if omitted is read from
-- `nvs.read("proximity","hysteresis")`
M.enable = function (on, period, threshold, hysteresis)
  if on and cont_enables == 0 then

    period = period or nvs.read("proximity","period", 100) or 100
    threshold = threshold or nvs.read("proximity","threshold", 250) or 250
    hysteresis = hysteresis or nvs.read("proximity","hysteresis", 3) or 3

    assert(apds9960r.proximity.enable(period, threshold, hysteresis))

  elseif (not on) and cont_enables == 1 then
    assert(apds9960r.proximity.enable(nil))
  end

  if on then
    cont_enables = cont_enables + 1
  end

  if (not on) and cont_enables ~= 0 then
    cont_enables = cont_enables - 1
  end
end

return M
