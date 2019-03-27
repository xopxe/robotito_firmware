local omni=require('omni')
local apds = assert(require('apds9960')) -- init apsd

local ms = 50  -- period of distance measurements
local thershold = 251
local histeresis = 3

local N_SENSORS = 6
local W_ROTATE = 0.008

local MAX_TICS_TIMEOUT_SEARCH = 0.5 * 1000 / ms -- 1 seg
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
-- s,v: 0..255
-- color: one of "red", "yellow", "green", "cyan", "blue", "magenta"
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

local xdot = 0
local ydot = 0
local w = 0
local cur_wdot = 0

-- states
local STOP = {"STOP"}
local INIT = {"INIT"}
local ROTATE = {"ROTATE"}
local BACK = {"BACK"}
local PAN = {"PAN"}
local H_OFF = {"H_OFF"}
local H_ALIGN = {"H_ALIGN"}
local H_GO = {"H_GO"}
local H_SEARCH = {"H_SEARCH"}
local S_PAN_60 = {"S_PAN_60"}
local S_FIND_MAX_MIN = {"S_FIND_MAX_MIN"}
local S_BACK = {"S_BACK"}
local SS_START = {"SS_START"}
local SS_END = {"SS_END"}

-- machine state
local a_state = STOP
local s_state = S_PAN_60
local h_state = H_OFF

local tics_timeout_search  = 0

local init_h_search = function()
  for i=1,N_SENSORS do
    sensors_min_read[i] = 1 -- max value norm
    state_sensors_read[i] = SS_START
  end
  s_state = S_PAN_60
  a_state = STOP
  w = W_ROTATE -- not oposite rotate direction respect to the initial rotation in the align state
  tics_timeout_search = 0
  omni.drive(0,0,w)
end

-- callback for distC.get_dist_thresh
-- will be called when the robot is over threshold high
local dump_dist = function(b)
    if b then
      -- init_h_search()
      -- h_state = H_SEARCH
      w = 0
      h_tate = H_ALIGN
      a_state = STOP
      -- a_state = STOP
      omni.drive(0,0,w)
    else
      h_state = H_OFF
      xdot = 0
      ydot = 0
      w = 0
      omni.drive(0,0,0)
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

local sin60 = math.sqrt(3)/2
local sin30 = 1/2

-- sensor index to follow
local id_max_ds = -1

-- search behavior vars
local max_tics = 1
local cur_tics = 0

local xdot = 0
local ydot = 0

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
  for i = 1,N_SENSORS do
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
  w = 0 -- follow
end

local tic = 0

local dmin = 80
local dmax = 600
local d_range = dmax - dmin
local d_last = 0
local act_d = {0, 0, 0, 0, 0, 0}

-- global, curren position in the sensor readings history window
local current_wp = 0

local id_align = 1
local autonomous = true


local norm_d = {0, 0, 0, 0, 0, 0} -- global to debug

-- the callback will be called with all sensor readings
local dist_callback= function(d1, d2, d3, d4, d5, d6)
  local alpha_lpf = 1 -- low pass filter update parameter
  local TOL_APROACH = 0.001
  local MASK_ON_SENSORS = {true, true, true, true, true, true}
  local MAX_TICS_TIMEOUT_TELEOP = 5 * 1000 / ms -- 5 seg

  act_ori={d1, d2, d3, d4, d5, d6}
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
    tics_timeout_teleop = tics_timeout_teleop  + 1
    if tics_timeout_teleop >= MAX_TICS_TIMEOUT_TELEOP then
      tics_timeout_teleop = 0
      autonomous = true
    end
    return
  end

  if h_state == H_SEARCH then
    if s_state == S_PAN_60 then
      local sensors_ready = 0

      tics_timeout_search = tics_timeout_search + 1
      for i=1,N_SENSORS do
        if sensors_min_read[i] > norm_d[i] and norm_d[i] > 0 then -- and  state_sensors_read[i] == SS_START then
          sensors_min_read[i] = norm_d[i]
        else
          state_sensors_read[i] = SS_END
        end
        if state_sensors_read[i] == SS_END then
          sensors_ready = sensors_ready + 1
        end
      end

      -- if (sensors_ready == N_SENSORS) then -- tienen el problema que un sensor se queda con el objeto que encuentra primero pero ... probar
      if tics_timeout_search >= MAX_TICS_TIMEOUT_SEARCH then
        s_state = S_FIND_MAX_MIN
        id_align = indexsort(sensors_min_read)
        d_last = norm_d[id_align] --sensors_min_read[id_align]
        w = -w
        omni.drive(0,0,w)
      end
    elseif s_state == S_FIND_MAX_MIN then
      -- if (norm_d[id_align] + TOL_APROACH) > d_last and norm_d[id_align] > 0 then
      if norm_d[id_align] > 0 then
        s_state = S_BACK
        w = -w
        omni.drive(0,0,w)
      end

    elseif s_state == S_BACK then
      w = 0
      h_state = H_ALIGN
      a_state = INIT
      -- a_state = STOP
      omni.drive(0,0,w)
      -- h_state = H_GO
      d_last = norm_d[id_align]
    end
    -- id_align = indexsort(norm_d)
    -- if id_align > 0 and norm_d[id_align] ~= 0 then
    --   a_state = STOP
    --   h_state = H_ALIGN
    --   w = 0find_
    --   xdot = 0
    --   ydot = 0
    -- end
    -- omni.drive(0,0,w)
  elseif h_state == H_ALIGN then
    -- execute alingn state machine
    -- if norm_d[id_align] == 0 then
    --   w = -W_ROTATE -- oposite rotate direction respect to the initial rotation in the align state
    --   init_h_search()
    --   h_state = H_SEARCH
    -- elseif a_state == STOP then
    if a_state == STOP then
      w = W_ROTATE
      a_state = INIT
    elseif a_state == INIT then
      w = 0
      a_state = ROTATE
    elseif a_state == ROTATE then
      if norm_d[id_align] == 0 then
        w = -W_ROTATE
      else
        w = W_ROTATE
      end
      a_state = PAN
      d_last = norm_d[id_align]
    elseif a_state == PAN then
      -- if (d_last - norm_d[id_align]) < TOL_APROACH then
      if d_last  >  norm_d[id_align] then
        a_state = BACK
        w = -w
      end
      d_last = norm_d[id_align]
    elseif a_state == BACK then
      w = 0
      a_state = STOP
      h_state = H_GO
    end
    omni.drive(0,0,w)
    d_last = norm_d[id_align]
  elseif h_state == H_GO then
    if norm_d[id_align] == 0 then
      -- init_h_search()
      -- h_state = H_SEARCH
      w = 0
      h_state = H_ALIGN
      a_state = INIT
      -- a_state = STOP
      omni.drive(0,0,w)
    elseif ((d_last - norm_d[id_align]) < TOL_APROACH) then
      h_state = H_ALIGN
      a_state = STOP
      w = 0
      xdot = 0
      ydot = 0
    else
      local MAX_VEL = 0.2
      local MIN_VEL = 0.01
      foo = {0, 0, 0, 0, 0, 0}
      foo[id_align] = line(1, MAX_VEL, 0, 0, norm_d[id_align])
      if foo[id_align] < MIN_VEL then foo[id_align] = MIN_VEL end -- lineal with step
      compute_velocity(foo)
    end
    d_last = norm_d[id_align]
    omni.drive(xdot,ydot,w)
  end
  tic = tic + 1

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
--]]

local time = 0
while true do
  -- print('hz: ', tic/time, xdot, ydot, w, '-', 'dist(act_d):', table.unpack(act_d))
  if id_align>0 then
    -- print(h_state[1], s_state[1], a_state[1], 'd_align: ', norm_d[id_align], 'drive: ', xdot, ydot, w ) --, '-', 'dist(d..):', table.unpack(d))
    print(h_state[1], s_state[1], a_state[1], 'id_align: ', id_align, 'd_align: ', norm_d[id_align], 'd_last: ', d_last) --, '-', 'dist(d..):', table.unpack(d))
  else
    print(h_state[1], s_state[1], a_state[1], xdot, ydot, w) --, '-', 'dist(d..):', table.unpack(d))
  end
  tmr.sleepms(500)
  time = time + 1
end

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local VEL_CMD = 'speed'

local socket = require("__socket")
host = host or "192.168.4.1"
port = port or 2018
if arg then
    host = arg[1] or host
    port = arg[2] or port
end
print("Binding to host '" ..host.. "' and port " ..port.. "...")
udp = assert(socket.udp())
assert(udp:setsockname(host, port))
-- assert(udp:settimeout(5))
ip, port = udp:getsockname()
assert(ip, port)
print("Waiting packets on " .. ip .. ":" .. port .. "...")
while 1 do
	dgram, ip, port = assert(udp:receivefrom())
	if dgram then
		print("Echoing '" .. dgram .. "' to " .. ip .. ":" .. port)
    cmd = split(dgram, '*')
    if cmd[1] == VEL_CMD then
      if #cmd == 5 then
        autonomous = false
        xdot = cmd[2]
        ydot = cmd[3]
        w = cmd[4]
        omni.drive(xdot,ydot,w)
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
