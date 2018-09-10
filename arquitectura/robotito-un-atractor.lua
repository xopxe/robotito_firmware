--dofile('robotito.lua')

-- { {xshutpin, [newadddr]}, ... }
local sensors = {
 {16},
 {17},
 {4},
 {14},
 {12},
 {13},
}
local omni_conf = {5.0, 27,26, 33,25, 23,18}

local ledpin = pio.GPIO19
local n_pins = 24

local max_bright = 70
local colors = {
 {max_bright, 0, 0},
 {max_bright/2, max_bright/2, 0},
 {0, max_bright, 0},
 {0, max_bright/2, max_bright/2},
 {0, 0, max_bright},
 {max_bright/2, 0, max_bright/2},
}

local first_led = {0, 20, 16, 12, 8, 4}

neo = neo or neopixel.attach(neopixel.WS2812B, ledpin, n_pins)

local ms = ms or 100  -- period of distance measurements

local enabled = false

local vlring=require('vl53ring')
assert(vlring.init(sensors))
-- faster, less precise measuremente
vlring.set_measurement_timing_budget(20000);


local omni=require('omni_hbridge')
assert(omni.init(table.unpack(omni_conf)))

button = sensor.attach("PUSH_SWITCH", pio.GPIO0)

WIN_SIZE = 5
N_SENSORS = 6

local sin60 = math.sqrt(3)/2
local sin30 = 1/2

local dmin = 50
local dmax = 400

local vmin = 50
local vmax = 500

local norm_x = 100 / math.sqrt(3)
local norm_y = 100

local d_range = dmax - dmin
local k_cuad = -1 / d_range^2

local floor = math.floor

-- evalua la funcion de una recta en x dado dos puntos (x1, y1) y (x2, y2)
local line = function(x1, y1, x2, y2, x)
	local y = (y2-y1)/(x2-x1)*(x-x1)+y1
  return y
end

local median = function (numlist)
    if type(numlist) ~= 'table' then return numlist end
    table.sort(numlist)
    if #numlist %2 == 0 then return (numlist[#numlist/2] + numlist[#numlist/2+1]) / 2 end
    return numlist[math.ceil(#numlist/2)]
end

local max = function (numlist)
    if type(numlist) ~= 'table' then return numlist end
    table.sort(numlist)
    return numlist[#numlist]
end

local function indexsort(tbl)
  local idx = {}
  for i = 1, #tbl do idx[i] = i end -- build a table of indexes
  -- sort the indexes, but use the values as the sorting criteria
  table.sort(idx, function(a, b) return tbl[a] > tbl[b] end)
  -- return the sorted indexes
  return (table.unpack or unpack)(idx)
end

local vel_lineal_pos = function(dist)
  local vel = line(dmin, 0, dmax, 1, dist)
  return vel
end

local vel_lineal = function(dist)
  local vel = (dmax-dist) / (d_range)
  return vel
end

local vel_cuadratic = function(dist)
  local vel = k_cuad*(dist - dmin)^2 + 1
  return vel
end

--local vel_from_dist = vel_cuadratic
local vel_from_dist = vel_cuadratic

-- the callback will be called with all sensor readings
local dist_callback= function(d1, d2, d3, d4, d5, d6)
  local alpha_lpf = 0.7 -- low pass filter update parameter
  local xdot = 0
  local ydot = 0
  local FIXED_VEL = 0.25
  local TOPE_MAX_TICS = 15

   --print('dist:', d1, d2, d3, d4, d5, d6)
  local act_d={d1, d2, d3, d4, d5, d6}
  local d={0, 0, 0, 0, 0, 0}

  -- apply distance data filter and update LEDs ring
  for i = 1,N_SENSORS do
    -- window filter
    sensors_win[i][current_wp] = act_d[i]
    last_d[i] = last_d[i] + alpha_lpf*(median(sensors_win[i])-last_d[i])

    if last_d[i]<dmin or last_d[i]>dmax then
      d[i]=0
      for j = 0, 3 do
          neo:setPixel(first_led[i]+j, 0,0,0)
      end
      neo:update()
    else
      --d[i]=dmax-d[i]
      -- d[i] = vel_from_dist(d[i])   -- 0..1
      d[i] = vel_from_dist(last_d[i])   -- 0..1
      -- d[i] = 0.25 -- vel_on_off
      local color = {
        floor(d[i]*colors[i][1]),
        floor(d[i]*colors[i][2]),
        floor(d[i]*colors[i][3])
      }
      for j = 0, 3 do
        neo:setPixel(first_led[i]+j, table.unpack(color))
      end
      neo:update()
    end
  end
  current_wp = (current_wp + 1) % WIN_SIZE

  if state == NEAR then
    id_max_ds = indexsort(d)
    if d[id_max_ds] > 0  then
      state = GOTO
      cur_tics = 0
      cur_wdot = 0
      omni.drive(0,0,0) -- stop
    else
      if cur_wdot == 0 then
        max_tics = 1
        cur_wdot = 3
        cur_tics = 0
      end
      if cur_tics >= max_tics then
        if max_tics < TOPE_MAX_TICS then
          max_tics = max_tics + 1
        end
        cur_tics = 0
        cur_wdot = -1 * cur_wdot
      end
      cur_tics = cur_tics + 1
      omni.drive(0,0,cur_wdot) -- rotate
    end
  elseif state == GOTO then
    if last_d[id_max_ds]<dmin  then
      state = NEAR
      omni.drive(0,0,0) -- stop
    elseif last_d[id_max_ds]>dmax  then
      -- TODO state = SEARCH
      state = NEAR
      omni.drive(0,0,0) -- stop
    else
      d={0, 0, 0, 0, 0, 0}
      d[id_max_ds] = FIXED_VEL
      xdot = (d[3]+d[2]-d[6]-d[5])* sin60 * norm_x
      ydot = ((-d[3]-d[5]+d[2]+d[6])/2 - d[4] + d[1] ) *norm_y
      omni.drive(xdot,ydot,0)
    end
  elseif state == SEARCH then
    if d[id_max_ds] == 0 then
      if cur_wdot == 0 then
        max_tics = 1
        cur_wdot = 3
        cur_tics = 0
      end
      if cur_tics >= max_tics then
        max_tics = max_tics * 2
        cur_tics = 0
        cur_wdot = -1 * cur_wdot
      end
      cur_tics = cur_tics + 1
      omni.drive(0,0,cur_wdot) -- rotate
    else
      cur_tics = 0
      cur_wdot = 0
      state = NEAR
    end
  end

  print(state, xdot, ydot, '', 'dist:', table.unpack(d))
end

local function button_callback(data)
  if data.on==0 then return end
  if enabled then
    print("off")
    omni.set_enable(false)
    -- stop monitoring distances
    vlring.get_continuous(false)
    enabled = false
  elseif not enabled then
    print("on")
    omni.set_enable()
    -- start monitoring distances
    vlring.get_continuous(ms, dist_callback)
    enabled = true
  end
end

-- states
NEAR = 0
GOTO = 1
SEARCH = 2

-- machine state
state = NEAR

-- sensor index to follow
id_max_ds = -1

-- search behavior vars
max_tics = 1
cur_tics = 0
cur_wdot = 2

-- global, last distance high level report
last_d={0, 0, 0, 0, 0, 0}

-- global, store history distance values to compute low pass filter
sensors_win = {}          -- create sensors readings matrix
for i=1,N_SENSORS do
  sensors_win[i] = {}     -- create a new row
  for j=1,WIN_SIZE do
    sensors_win[i][j] = 0
  end
end
-- global, curren position in the sensor readings history window
current_wp = 0

button:callback(button_callback)

print("on")
omni.set_enable()
vlring.get_continuous(ms, dist_callback)
-- local readings = {6}
-- while true do
--     for i= 1, #sensors do
--         readings[i] = vlring.get(i)
--     end
--     print (table.unpack(d))
--     tmr.sleepms(100*1000)
-- end




--[[
tmr.sleepms(20*1000)

print("off")
vlring.get_continuous(false)
omni.set_enable(false)
--vlring.release()
--]]
