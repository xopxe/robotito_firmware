--- Robot module.
-- This is the main module for the robot. Contains all the services available.
-- All the services are already initalized uing data stored in non-volatile 
-- storage. Check each module's documentaion to see the used variables.
-- @module robot
-- @alias M
local M = {}

--- Unique ID of the robot.
-- Read from nvs.read("robot","id").
M.id = nvs.read("robot","id")


--- Omni platform. This points to @{omni}
M.omni = require('omni')
--- Color sensor. This points to @{apds}.color
M.color = require('apds9960').color
--- Proximity sensor. This points to @{apds}.proximity
M.height = require('apds9960').proximity
--- Distance sensor ring. This points to @{laser_ring}
M.laser_ring = require('laser_ring')
--- LED ring. This points to @{led_ring}
M.led_ring = require'led_ring'
--- WiFi network susbsystem. This points to @{wifi_net}
M.wifi_net = require('wifi_net')

M.init = function()

  M.apds.init()
  M.laser_ring.init()
  M.omni.set_enable()
  M.wifi_net.init()

end

return M