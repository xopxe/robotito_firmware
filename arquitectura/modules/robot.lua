--- Robot module.
-- This is the main module for the robot. Contains all the services available.
-- All the services are already initalized using data stored in non-volatile 
-- storage. Check each module's documentaion to see the used variables.
-- @module robot
-- @alias M
local M = {}

--- Unique ID of the robot.
-- Read from nvs.read("robot","id").
M.id = nvs.read("robot","id", 0)


--- Omni platform. This points to @{omni}
M.omni = require('omni')
M.omni.enable()

--- Downward facing apds sensor. This points to @{apds}
M.apds = require('apds')

--- Color sensor. This points to @{apds}.color
M.color = M.apds.color

--- Proximity sensor. This points to @{apds}.proximity
M.floor = M.apds.proximity

--- Distance sensor ring. This points to @{laser_ring}
M.laser_ring = require('laser_ring')

--- UI LED ring. This points to @{led_ring}
M.led_ring = require'led_ring'

--- WiFi network susbsystem. This points to @{wifi_net}
M.wifi_net = require('wifi_net')
M.wifi_net.init()


return M