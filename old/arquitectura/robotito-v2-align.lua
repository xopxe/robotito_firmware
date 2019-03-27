local omni=require('omni')
local apds = assert(require('apds9960')) -- init apsd

local ms = 50  -- period of distance measurements
local thershold = 251
local histeresis = 3

local N_SENSORS = 6
local W_ROTATE = 0.008

local MAX_TICS_TIMEOUT_SEARCH = 1.4 * 1000 / ms
local MAX_TICS_TIMEOUT_WAIT = 2 * 1000 / ms

-- global, store history distance values to compute low pass filter
local WIN_SIZE = 3

local sensors_win = {}          -- create sensors readings matrix
local sensors_min_read = {}
local state_sensors_read = {}

for i=1,N_SENSORS do
  sensors_win[i] = {}     -- create a new row
  for j=1,WIN_SIZE do
    sensors_win[i][j] = 0
  end
end

assert(apds.init())
local distC = apds.proximity
assert(distC.enable())

--power on led
local led_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_pin)
pio.pin.sethigh(led_pin)

local xdot = 0
local ydot = 0
local cur_w = 0

local autonomous = true

-- states
local STOP = {"STOP"}
local INIT = {"INIT"}
local BACK = {"BACK"}
local PAN = {"PAN"}
local H_OFF = {"H_OFF"}
local H_WAIT = {"H_WAIT"}
local H_ALIGN = {"H_ALIGN"}
local H_GO = {"H_GO"}
local H_SEARCH = {"H_SEARCH"}
local H_DEBUG = {"H_DEBUG"}

local S_PAN_60 = {"S_PAN_60"}
local S_FIND_MAX_MIN = {"S_FIND_MAX_MIN"}
local S_BACK = {"S_BACK"}
local SS_START = {"SS_START"}

-- machine state
local a_state = STOP
local s_state = S_PAN_60
local h_state = H_OFF

local tics_timeout_search  = 0
local tics_timeout_wait  = 0
local tics_timeout_teleop = 0

local init_h_search = function()
  for i=1,N_SENSORS do
    sensors_min_read[i] = 0 -- 0, centinela, max value norm
    state_sensors_read[i] = SS_START
  end
  s_state = S_PAN_60
  a_state = STOP
  cur_w = -W_ROTATE -- not oposite rotate direction respect to the initial rotation in the align state
  xdot = 0
  ydot = 0
  tics_timeout_search = 0
  omni.drive(xdot,ydot,cur_w)
end

-- callback for distC.get_dist_thresh
-- will be called when the robot is over threshold high
local dump_dist = function(b)
    if autonomous then
      if b then
        tics_timeout_wait = 0
        h_state = H_WAIT
      else
        h_state = H_OFF
        xdot = 0
        ydot = 0
        cur_w = 0
        omni.drive(xdot,ydot,cur_w)
      end
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
local max_bright = 40

local led_ring_colors = {
 {max_bright, 0, 0},
 {max_bright/2, max_bright/2, 0},
 {0, max_bright, 0},
 {0, max_bright/2, max_bright/2},
 {0, 0, max_bright},
 {max_bright/2, 0, max_bright/2},
}

local led_const = require('led_ring')

local neo = led_const(ledpin, n_pins, max_bright)

local enabled = false

local button = sensor.attach("PUSH_SWITCH", pio.GPIO0)

local sin60 = math.sqrt(3)/2
local sin30 = 1/2

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

local update_led_ring = function(intensity)
--[[  for i = 1,N_SENSORS do
    local color = {
      math.floor(intensity[i]*led_ring_colors[i][1]),
      math.floor(intensity[i]*led_ring_colors[i][2]),
      math.floor(intensity[i]*led_ring_colors[i][3])
    }
    for j = 0, 3 do
      neo:setPixel(first_led[i]+j, table.unpack(color))
    end
  end
  neo:update()
--]]
    neo.clear()
  for i = 1,N_SENSORS do
    neo.set_segment(i, (intensity[i] ~= 0))
  end
end -- update_led_ring

local compute_velocity = function(dist)
  local FIXED_VEL = 0.1

  xdot = (dist[3]+dist[2]-dist[6]-dist[5])* sin60
  ydot = (-dist[3]-dist[5]+dist[2]+dist[6])/2 - dist[4] + dist[1]
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
  cur_w = 0 -- follow
end

local tic = 0

local dmin = 80
local dmax = 600
local d_last = 0
local act_d = {0, 0, 0, 0, 0, 0}

-- global, curren position in the sensor readings history window
local current_wp = 0

local id_align = 1
local norm_d = {0, 0, 0, 0, 0, 0}

local see_far_object = function (idx)
    return act_d[idx]<7999 and act_d[idx]>=dmax
end

local norm_d_with_far = function (idx)
  local result
  if see_far_object(idx) then
    result = 1
  else
    result = norm_d[id_align]
  end
  return result
end
-- the callback will be called with all sensor readings
local dist_callback= function(d1, d2, d3, d4, d5, d6)
  local alpha_lpf = 1 -- low pass filter update parameter
  local MASK_ON_SENSORS = {true, true, true, true, true, true}
  -- local MASK_ON_SENSORS = {true, false, false, false, false, false}
  local act_ori={d1, d2, d3, d4, d5, d6}

  -- apply distance data filter and update LEDs ring
  for i = 1,N_SENSORS do
    sensors_win[i][current_wp] = act_ori[i]
    act_d[i] = act_d[i] + alpha_lpf*(median(sensors_win[i])-act_d[i])
    if act_d[i] > dmin and act_d[i] < dmax and MASK_ON_SENSORS[i] then
      norm_d[i] = line(dmin, 0, dmax, 1, act_d[i])   -- 0..1
    else
      norm_d[i] = 0
    end
  end
  current_wp = (current_wp + 1) % WIN_SIZE


  if not autonomous then
    norm_d={0, 1, 0, 0, 0, 0} -- switch on ahead leds only

    -- TODO: dont return to autonomous
    -- tics_timeout_teleop = tics_timeout_teleop  + 1
    -- if tics_timeout_teleop >= MAX_TICS_TIMEOUT_TELEOP then
    --   tics_timeout_teleop = 0
    --   autonomous = true
    -- end
  else
    if h_state == H_WAIT then
      tics_timeout_wait = tics_timeout_wait + 1
      if tics_timeout_wait >= MAX_TICS_TIMEOUT_WAIT then
        h_state = H_ALIGN
        a_state = STOP
      end
    elseif h_state == H_ALIGN then
      if a_state == STOP then
        cur_w = W_ROTATE
        a_state = INIT
      elseif a_state == INIT then
        if (d_last == 0 and norm_d[id_align] == 0) or (norm_d[id_align] > d_last) then
          cur_w = -cur_w
        end
        if norm_d[id_align] ~= 0 then
          a_state = PAN
        end
      elseif a_state == PAN then
        if d_last < norm_d[id_align] then
          a_state = BACK
          cur_w = -cur_w
        end
      elseif a_state == BACK then
        cur_w = 0
        a_state = STOP
        h_state = H_DEBUG
        -- h_state = H_DEBUG
      end
      omni.drive(0,0,cur_w)
      d_last = norm_d[id_align]
      -- if norm_d[id_align] ~= 0 then
      --   d_last = norm_d[id_align]
      -- end
    elseif h_state == H_DEBUG then
      -- if norm_d[id_align] == 0 then
      --   id_align = 1 -- indexsort(norm_d)
      --   h_state = H_ALIGN
      --   a_state = STOP
      -- end
      if norm_d[id_align] == 0 then
        h_state = H_SEARCH
        init_h_search()
      end
    end
    tic = tic + 1
  end -- not autonomous

  update_led_ring(norm_d)
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
-- --]]
-- local time = 0
-- while true do
--   -- print('hz: ', tic/time, xdot, ydot, w, '-', 'dist(act_d):', table.unpack(act_d))
--   if id_align>0 then
--     -- print(h_state[1], s_state[1], a_state[1], 'd_align: ', norm_d[id_align], 'drive: ', xdot, ydot, w ) --, '-', 'dist(d..):', table.unpack(d))
--     print(h_state[1], s_state[1], a_state[1], 'id_align: ', id_align, 'd_align: ', norm_d[id_align], 'd_last: ', d_last) --, '-', 'dist(d..):', table.unpack(d))
--   else
--     print(h_state[1], s_state[1], a_state[1], xdot, ydot, w) --, '-', 'dist(d..):', table.unpack(d))
--   end
--   tmr.sleepms(500)
--   time = time + 1
-- end

-- -- TODO: OJO WHILE TRUE
-- while true do
--   tmr.sleepms(1000)
--   print(".")
-- end

function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local VEL_CMD = 'speed'

local socket = require("__socket")
local host = "192.168.4.1"
local port = 2018
local has_remote_cliente = false

print("Binding to host '" ..host.. "' and port " ..port.. "...")
local udp = assert(socket.udp())
assert(udp:setsockname(host, port))
-- assert(udp:settimeout(5))
local ip

ip, port = udp:getsockname()
assert(ip, port)
print("Waiting packets on " .. ip .. ":" .. port .. "...")

thread.start(function()
  local dgram
  local cmd
  local enable = false

  while 1 do
  	dgram, ip, port = assert(udp:receivefrom())
  	if dgram then
  		print("Echoing '" .. dgram .. "' to " .. ip .. ":" .. port)
      cmd = split(dgram, '*')
      if cmd[1] == VEL_CMD then
        if #cmd == 5 then
          autonomous = false
          tics_timeout_teleop = 0
          has_remote_cliente = true
          xdot = cmd[2]
          ydot = cmd[3]
          cur_w = cmd[4]
          omni.drive(xdot,ydot,cur_w)
          local nxt_enable = not (xdot==0 and ydot==0 and cur_w ==0)
          if nxt_enable ~= enable then
            enable = nxt_enable
            omni.set_enable(enable)
          end
          udp:sendto('[INFO] Speed command received (' .. xdot .. ', ' .. ydot .. ')', ip, port)
        else
          udp:sendto('[ERROR] Malformed command.', ip, port)
        end
      else
        udp:sendto('[ERROR] Unknown command: ' .. cmd[1], ip, port)
      end
  	else
      print(ip)
    end
  end
end) --end thread
