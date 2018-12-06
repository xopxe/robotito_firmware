--- Range sensor ring module.
-- @module laser_ring
-- @alias M
local M = {}

local vlring=require('vl53ring')

local table_sort = table.sort

--CONSTANTS
local N_SENSORS = 6
local N_SENSORS_2= N_SENSORS/2
assert(N_SENSORS %2 == 0, 'median optimized for par N_SENSORS')
local WIN_SIZE = 3  -- store history distance values to compute low pass filter
local alpha_lpf = 1 -- low pass filter update parameter

--[[ this moved inside M.init() to free this from memory after use
-- { {xshutpin, [newadddr]}, ... }
local sensors = {{16}, {17}, {2}, {14},{12}, {13}}
--]]

-- VARIABLES
local norm_d = {0, 0, 0, 0, 0, 0}       -- normalized measurements
local previous_d = {0, 0, 0, 0, 0, 0}   -- previous norm_d
local raw_d = {0, 0, 0, 0, 0, 0}

do
  local angles = {6}
  local intersensor = 2*math.pi/N_SENSORS 
  for i = 1, N_SENSORS do
    angles[i] = math.pi/6 + (i-1)*intersensor
  end
--- Sensor angles.
-- The angles at which each one sensors point. It's and array indexed byt the 
-- sensor number 1..6 --FIXME
  M.sensor_angles = angles
end

--- Minimum range for normalization in mm.
-- See @{norm_d}. Initialized from `nvs.read("laser_range","dmin")`, 
-- defaults to 80.
M.dmin = nvs.read("laser_range","dmin", 80) or 80
local dmin = M.dmin

--- Maximum range for normalization in mm.
-- See @{norm_d}. Initialized from `nvs.read("laser_range","dmax")`, 
-- defaults to 600.
M.dmax = nvs.read("laser_range","dmax", 600) or 600
local dmax = M.dmax

--- The last reading, in raw form.
-- It's an array with length 6, with measures in mm. This is not affected
-- by the @{dmin} and @{dmax} settings.
M.raw_d = raw_d

--- The last reading, normalized.
-- It's an array with length 6. The distances are normalized to 0.0..100.0
-- in the @{dmin}..@{dmax} range, and clipped to 0 or 100 when outside this
-- range. For these values to
-- be upgdated, you must register and enable a callback (see @{get_reading_cb}
-- and @{get_filtering_cb}).
M.norm_d = norm_d

--- The previous reading, normalized.
-- It's a copy of @{norm_d} from previous cycle.
M.previous_d = previous_d

local function get_interpolator(x1, y1, x2, y2)
  local p = (y2-y1)/(x2-x1)
  return function (x)
    return p*(x-x1)+y1
  end
end
local normalize_d = get_interpolator(M.dmin, 0, M.dmax, 100)

--- The callback module for the range sensor ring.
-- This is a callback list attached to the range sensor, see @{cb_list}.
M.cb = require'cb_list'.get_list()

--- Factory for a linear range callback.
-- The output is written to @{norm_d}
-- @usage local laser=require('laser_ring')
--laser.cb.append(laser.get_reading_cb())
M.get_reading_cb = function ()
  local dist_callback = function(d1,d2,d3,d4,d5,d6)
    --uart.write(uart.CONSOLE, '!get_reading_cb callback\r\n')
    local laser_data = {d1,d2,d3,d4,d5,d6}
    for i = 1,N_SENSORS do
      previous_d[i] = norm_d[i]
      local d = laser_data[i]
      raw_d[i] = d
      if d < dmin then
        norm_d[i] = 0
      elseif d > dmax then
        norm_d[i] = 100        
      else
        norm_d[i] = normalize_d(d)   -- 0..100
      end
    end
  end
  return dist_callback
end

--[[
local median = function (numlist)
  if type(numlist) ~= 'table' then return numlist end
  table.sort(numlist)
  if #numlist %2 == 0 then return (numlist[#numlist/2] + numlist[#numlist/2+1]) / 2 end
  return numlist[math.ceil(#numlist/2)]
end
--]]
-- version optimizada para #numlist == N_SENSORS
local median = function (numlist)
  table_sort(numlist)
  return (numlist[N_SENSORS_2] + numlist[N_SENSORS_2]) / 2
end

--- Factory for a filtering range callback.
-- The output is written to @{norm_d}
-- @usage local laser=require('laser_ring')
--laser.cb.append(laser.get_filtering_cb())
M.get_filtering_cb = function ()
  local sensors_win = {}            -- create sensors readings matrix
  local current_wp = 0              -- global, curren position in the sensor readings history window
  local act_d = {0, 0, 0, 0, 0, 0}  -- measures filtered 

  -- init sensors window
  for i=1,N_SENSORS do
    sensors_win[i] = {WIN_SIZE}     -- create a new row
    for j=1,WIN_SIZE do
      sensors_win[i][j] = 0
    end
  end

  local dist_callback_filter = function(d1,d2,d3,d4,d5,d6)
    local laser_data = {d1,d2,d3,d4,d5,d6}
    for i = 1,N_SENSORS do
      previous_d[i] = norm_d[i]
      local d = laser_data[i]
      raw_d[i] = d
      sensors_win[i][current_wp] = d
      local act = act_d[i]
      act = act + alpha_lpf*(median(sensors_win[i])-act)
      act_d[i] = act
      if act < dmin then
        norm_d[i] = 0
      elseif act > dmax then
        norm_d[i] = 100        
      else
        norm_d[i] = normalize_d(act)   -- 0..100
      end
    end
    current_wp = (current_wp + 1) % WIN_SIZE
  end
  return dist_callback_filter
end

--- Enables the range monitoring callback. 
-- See @{cb}. The period in ms to use is read from `nvs.read("laser_range","period")`, deafults to 100.  
--@param on true value to enable, false value to disable.
M.enable = function (on)
  if on then
    local period = nvs.read("laser_range","period", 100) or 100
    vlring.get_continuous(period, M.cb.call)
  else
    vlring.get_continuous(nil)
  end
end

--- Initialization.
-- This configures and starts the sensors. The timing budget for the measurement
-- is read from `nvs.read("laser_range","time_budget")`, defaults to 5000.
M.init = function()
  -- { {xshutpin, [newadddr]}, ... }
  --local sensors = { {16}, {17}, {2}, {14}, {12}, {13} }
  local sensors = { {13}, {16}, {17}, {2}, {14}, {12} }
  vlring.init(sensors)
  local time_budget = nvs.read("laser_range","time_budget", 5000) or 5000
  vlring.set_measurement_timing_budget(time_budget) 
end

return M