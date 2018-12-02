--- Robot module.
-- This is the main module for the robot. Contains all the services available.
-- All the services are already initalized uing data stored in non-volatile 
-- storage. Check each module's documentaion to see the used variables.
-- @module robot
-- @alias M
local M = {}

local omni=require('omni')
local apds = assert(require('apds9960'))
local laser_ring = require('laser_ring')
local wifi_net = require('wifi_net')

--- Omni platform. This points to @{omni}
M.omni = omni
--- Color sensor. This points to @{apds}.color
M.color = apds.color
--- Proximity sensor. This points to @{apds}.proximity
M.height = apds.proximity
--- Distance sensor ring. This points to @{laser_ring}
M.laser_ring = laser_ring
--- LED ring. This points to @{led_ring}
M.led_ring = require'led_ring'(pio.GPIO19, 24, 50)

--- Unique ID of the robot.
-- Read from nvs.read("robot","id").
M.id = nvs.read("robot","id")

--- WiFi network susbsystem. This points to @{wifi_net}
M.wifi_net = wifi_net

M.init = function()

  apds.init()
  laser_ring.init()
  omni.set_enable()
  wifi_net.init()

end

return M