--dofile('robotito.lua')

local omni=require('omni')

-- init apsd
local apds = assert(require('apds9960'))

local min_sat = 50
local min_val = 20
local max_val = 200

local colors = {
  {"red", 0, 60},
  {"yellow", 60, 120},
  {"green", 120, 180},
  {"cyan", 180, 240},
  {"blue", 240, 300},
  {"magenta", 300, 360},
}

assert(apds.init())
local distC = apds.proximity
assert(distC.enable())

local color = apds.color
assert(color.set_color_table(colors))
assert(color.set_sv_limits(min_sat,min_val,max_val))
assert(color.enable())

local last_color = "none"

-- callback for get_change
-- will be called with (color, s, v)
-- color: one of "red", "yellow", "green", "cyan", "blue", "magenta"
-- s,v: 0..255
local dump_color_change = function(c, s, v)
  last_color = c
end


--power on led
local led_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_pin)
pio.pin.sethigh(led_pin)

-- enable raw color monitoring, enable hsv mode
--color.get_continuous(ms, dump_rgb, true)

-- enable color change monitoring, enable hsv mode
color.get_change(ms, dump_color_change)

local ms = 100  -- period of distance measurements
local thershold = threshold or 251
local histeresis = histeresis or 3

local xdot = 0
local ydot = 0
local w = 0

-- states
local NEAR = {0}
local GOTO = {1}
local STOP = {2}
local INIT = {3}
local ROTATE = {4}
local PAN = {5}
local BACK = {6}
local OFF = {7}

-- machine state
local state = STOP

-- callback for distC.get_dist_thresh
-- will be called when the robot is over threshold high
local dump_dist = function(b)
    if b then
      state = NEAR
    else
      state = OFF
      xdot = 0
      ydot = 0
      w = 0
    end
end

-- enable distC change monitoring
distC.get_dist_thresh(ms, thershold, histeresis, dump_dist)

-- end init apsd
-- { {xshutpin, [newadddr]}, ... }
local sensors = {
 {16},
 {17},
 {2},
 {14},
 {12},
 {13},
}

local vlring=require('vl53ring')
assert(vlring.init(sensors))

-- faster, less precise measuremente
vlring.set_measurement_timing_budget(5000);

local ledpin = pio.GPIO19
local n_pins = 24

local max_bright = 70
local led_ring_colors = {
 {max_bright, 0, 0},
 {max_bright/2, max_bright/2, 0},
 {0, max_bright, 0},
 {0, max_bright/2, max_bright/2},
 {0, 0, max_bright},
 {max_bright/2, 0, max_bright/2},
}

local first_led = {0, 20, 16, 12, 8, 4}

local neo = neopixel.attach(neopixel.WS2812B, ledpin, n_pins)

local enabled = false

local button = sensor.attach("PUSH_SWITCH", pio.GPIO0)

local WIN_SIZE = 3
local N_SENSORS = 6

-- sensor index to follow
local id_max_ds = -1

-- search behavior vars
local max_tics = 1
local cur_tics = 0
local cur_wdot = 0

local sin60 = math.sqrt(3)/2
local sin30 = 1/2

local dmin = 80
local dmax = 600

local vmin = 50
local vmax = 500

local norm_x = 2 / math.sqrt(3)
local norm_y = 2

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

local d={0, 0, 0, 0, 0, 0}
local act_d={0, 0, 0, 0, 0, 0}

-- the callback will be called with all sensor readings
local dist_callback= function(d1, d2, d3, d4, d5, d6)
  local alpha_lpf = 0.9 -- low pass filter update parameter
  local FIXED_VEL = 0.1
  local W_ROTATE = 0.008

  local TOPE_MAX_TICS = 15
  local INC_TIC_ARC_SEARCH = 1
  local MAX_SEARCH_DIR_CHANGE = 10
  local MASK_ON_SENSORS = {true, true, true, true, true, true}

  act_d={d1, d2, d3, d4, d5, d6}
   --print('dist:', d1, d2, d3, d4, d5, d6)
  xdot = 0
  ydot = 0

  -- apply distance data filter and update LEDs ring
  for i = 1,N_SENSORS do
    --last_d[i] = last_d[i] + alpha_lpf*(median(sensors_win[i])-last_d[i])

    if act_d[i]<dmin or act_d[i]>dmax or (not MASK_ON_SENSORS[i]) then
      d[i]=0
      for j = 0, 3 do
          neo:setPixel(first_led[i]+j, 0,0,0)
      end
      neo:update()
    else
      --d[i]=dmax-d[i]
      -- d[i] = vel_from_dist(d[i])   -- 0..1
      d[i] = vel_from_dist(act_d[i])   -- 0..1
      -- d[i] = 0.25 -- vel_on_off
      local color = {
        floor(d[i]*led_ring_colors[i][1]),
        floor(d[i]*led_ring_colors[i][2]),
        floor(d[i]*led_ring_colors[i][3])
      }
      for j = 0, 3 do
        neo:setPixel(first_led[i]+j, table.unpack(color))
      end
      neo:update()
    end
  end

  if state == NEAR then
    id_max_ds = indexsort(d)
    if d[id_max_ds] > 0  then
      state = GOTO
      cur_tics = 0
      cur_wdot = 0
      xdot = 0
      ydot = 0
      w = 0 -- stop
      d_last = d[id_max_ds]

      MASK_ON_SENSORS = {true, true, true, true, true, true}
    else
      w = W_ROTATE
    end
 elseif state == GOTO then -- find object
    if act_d[id_max_ds]<dmin  then
      state = NEAR
      xdot = 0
      ydot = 0
      w = 0 -- stop
      MASK_ON_SENSORS [id_max_ds] = false -- sensor inhibition
      print ('find new object. use color: ', last_color)
    elseif act_d[id_max_ds]>dmax or d_last < d[id_max_ds] then
      state = SEARCH
      -- state = NEAR
      xdot = 0
      ydot = 0
      cur_wdot = W_ROTATE
      w = cur_wdot 
    else
      d_last = d[id_max_ds]
      d={0, 0, 0, 0, 0, 0}
      d[id_max_ds] = 1
      xdot = (d[3]+d[2]-d[6]-d[5])* sin60 * norm_x
      ydot = ((-d[3]-d[5]+d[2]+d[6])/2 - d[4] + d[1] ) * norm_y
      if (xdot ~= 0 and ydot ~= 0 ) then
        local ang = math.atan(ydot, xdot)
        xdot = math.cos(ang)*FIXED_VEL
        ydot = math.sin(ang)*FIXED_VEL
      elseif xdot ~= 0 then
          if xdot>0 then
            xdot = FIXED_VEL
          else
            xdot = -FIXED_VEL
          end
      else
        -- ydot = math.sign(ydot) * FIXED_VEL
        if ydot>0 then
          ydot = FIXED_VEL
        else
          ydot = -FIXED_VEL
        end
      end
      w = 0 -- follow
    end
  elseif state == SEARCH and d[id_max_ds] == 0 then
    cur_wdot = W_ROTATE
    state = INIT
    w = cur_wdot 
  elseif state == INIT then
    cur_wdot = 0
    state = ROTATE
    w = cur_wdot 
  elseif state == ROTATE then
    if d[id_max_ds] == 0 then
      cur_wdot = -W_ROTATE
    else 
      cur_wdot = W_ROTATE      
    end
    state = PAN
    d_last = d[id_max_ds]
    w = cur_wdot 
  elseif state == PAN then
    if d_last < d[id_max_ds] then
      state = BACK
      cur_wdot = -cur_wdot
      w = cur_wdot 
    end
    d_last = d[id_max_ds]
  elseif state == BACK then
    cur_wdot = 0
    w = 0
    state = GOTO    
  end
  
  omni.drive(xdot,ydot,w)
  -- omni.drive(0,0,0.01)
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
--
-- local w = 3
-- while true do
--     print ('w: ', w)
--     omni.drive(0,0,w)
--     tmr.sleepms(3*1000)
--     w = -w
-- end



--[[
tmr.sleepms(20*1000)

print("off")
vlring.get_continuous(false)
omni.set_enable(false)
--vlring.release()
--]]

while true do
  print(state[1], xdot, ydot, w, '-', 'dist(act_d):', table.unpack(act_d))
  --print(state[1], xdot, ydot, w, '-', 'dist(d..):', table.unpack(d))
  tmr.sleepms(1*1000)
end
