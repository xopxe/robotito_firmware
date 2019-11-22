--- Robot module.
-- This is the main module for the robot. Contains all the services available.
-- All the services are already initalized using data stored in non-volatile
-- storage. Check each module's documentaion to see the used variables.
-- @module robot
-- @alias M
local M = {}

function implode(delimiter, list)
  local len = #list
  if len == 0 then
    return ""
  end
  local string = list[1]
  for i = 2, len do
    string = string .. delimiter .. list[i]
  end
  return string
end

local LASER_CMD = 'laser'
local COLOR_CMD = 'color'
local DELIMITER = '*'

M.hsm = nil

--- Unique ID of the robot.
-- Read from `nvs.read("robot","id")`, defaults to 0.
M.id = nvs.read("robot","id", 0) or 0

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


local filter = nvs.read("laser", "filter", nil) or nil
print('filter loading:', filter)

local measure_cb = M.laser_ring.get_reading_cb()
if (filter == "filter") then
  measure_cb = M.laser_ring.get_filtering_cb()
end


local laser_ring_publisher = function (d1,d2,d3,d4,d5,d6)
  measure_cb(d1,d2,d3,d4,d5,d6)
  local sens_str = nil
  if (filter == nil) then
    sens_str = LASER_CMD .. DELIMITER .. implode(DELIMITER, M.laser_ring.raw_d)
  else
    sens_str = LASER_CMD .. DELIMITER .. implode(DELIMITER, M.laser_ring.norm_d)
  end
  M.wifi_net.broadcast(sens_str)
end

local color_cb = function(color_name, h, s, v)
  local color_str = COLOR_CMD .. DELIMITER .. color_name .. DELIMITER .. h .. DELIMITER .. s .. DELIMITER .. v
  M.wifi_net.broadcast(color_str)
end



M.laser_ring.cb.append(laser_ring_publisher)
M.color.color_cb.append(color_cb)

--M.laser_ring.enable(true)
--M.color.enable(true)

print 'Robot started:'
thread.list(false, false, true)

return M
