--- Robot module.
-- This is the main module for the robot. Contains all the services available.
-- @module robot
-- @alias M


local M = {}

local omni=require('omni')
local apds = assert(require('apds9960'))
local laser_ring = require('laser_ring')

--- Omni platform.
M.omni = omni
--- Color sensor. This points to @{apds}.color
M.color = apds.color
--- Proximity sensor. This points to @{apds}.proximity
M.height = apds.proximity
--- Distance sensor ring. This points to @{laser_ring}
M.laser_ring = laser_ring
--- LED ring. This points to @{led_ring}
M.led_ring = require'led_ring'(pio.GPIO19, 24, 50)

M.init = function()
  
  assert(apds.init())
  assert(apds.proximity.enable())
  laser_ring.init()
  omni.set_enable()
  
end


return M