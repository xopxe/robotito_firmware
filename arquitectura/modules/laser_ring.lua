local M = {}

local vlring=require('vl53ring')

--CONSTANTS
local N_SENSORS = 6
local WIN_SIZE = 3            -- global, store history distance values to compute low pass filter
local dmin = 80
local dmax = 600
local alpha_lpf = 1           -- low pass filter update parameter
local MASK_ON_SENSORS = {true, true, true, true, true, true}
local rate = 50               -- actualization rate in seconds

M.no_object = nil
M.find_object = nil
M.loosing_object = nil

local sensors = {             -- sensors ports
   {16},
   {17},
   {2},
   {14},
   {12},
   {13},
  }

-- VARIABLES
local sensors_win = {}                  -- create sensors readings matrix
local current_wp = 0                    -- global, curren position in the sensor readings history window
local act_d = {0, 0, 0, 0, 0, 0}        -- measures filtered 
local norm_d = {0, 0, 0, 0, 0, 0}       -- normalized measurements
local previous_d = {0, 0, 0, 0, 0, 0}   -- previous norm_d
local id_align = 1                      -- sensor used to align the robot


local median = function (numlist)
    if type(numlist) ~= 'table' then return numlist end
    table.sort(numlist)
    if #numlist %2 == 0 then return (numlist[#numlist/2] + numlist[#numlist/2+1]) / 2 end
    return numlist[math.ceil(#numlist/2)]
end

local line = function(x1, y1, x2, y2, x)  -- evalua la funcion de una recta en x dado dos puntos (x1, y1) y (x2, y2)
	local y = (y2-y1)/(x2-x1)*(x-x1)+y1
  return y
end


local dist_callback = function(d1,d2,d3,d4,d5,d6)
    local laser_data = {d1,d2,d3,d4,d5,d6}
    for i = 1,N_SENSORS do
    sensors_win[i][current_wp] = laser_data[i]
    act_d[i] = act_d[i] + alpha_lpf*(median(sensors_win[i])-act_d[i])
    previous_d[i] = norm_d[i]
    if act_d[i] > dmin and act_d[i] < dmax and MASK_ON_SENSORS[i] then
      norm_d[i] = line(dmin, 0, dmax, 1, act_d[i])   -- 0..1
    else
      norm_d[i] = 0
    end
  end
  current_wp = (current_wp + 1) % WIN_SIZE
  
  if (M.no_object) then
    M.no_object(norm_d, id_align)
  end

  if (M.find_object) then
    M.find_object(norm_d, id_align)
  end
  
  if (M.loosing_object) then
    M.loosing_object(norm_d, id_align, previous_d)
  end
  
end


M.init = function(events_lists)
  
  vlring.init(sensors)
  
  -- init sensors window
  for i=1,N_SENSORS do
    sensors_win[i] = {}     -- create a new row
    for j=1,WIN_SIZE do
      sensors_win[i][j] = 0
    end
  end
  
  vlring.set_measurement_timing_budget(5000)
  
  vlring.get_continuous(rate, dist_callback)
  
end

return M