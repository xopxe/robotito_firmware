--- Robot module.
-- This is the main module for the robot. Contains all the services available.
-- All the services are already initalized using data stored in non-volatile 
-- storage. Check each module's documentaion to see the used variables.
-- @module robot
-- @alias M
local M = {}

--- Unique ID of the robot.
-- Read from `nvs.read("robot","id")`, defaults to 0.
M.id = nvs.read("robot","id", 0)

--- @{omni}-directional mobility platform.
M.omni = require('omni')
M.omni.enable()

--- Downard facing @{color} sensor.
M.color = require('color')

--- Downard facing @{proximity} sensor. 
M.floor = require('proximity')

--- Distance sensor ring. This points to @{laser_ring}
M.laser_ring = require('laser_ring')

--- UI LED ring. This points to @{led_ring}
M.led_ring = require'led_ring'

--- WiFi UDP network susbsystem. This points to @{wifi_net}
M.wifi_net = require('wifi_net')
M.wifi_net.init()


return M