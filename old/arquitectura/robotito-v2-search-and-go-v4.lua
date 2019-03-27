local omni=require('omni')
local apds = assert(require('apds9960')) -- init apsd

local ms = 50  -- period of distance measurements
local thershold = 251
local histeresis = 3

local N_SENSORS = 6
local W_ROTATE = 0.008

local MAX_TICS_TIMEOUT_SEARCH = 1 * 1000 / ms -- 1.5 seg
local MAX_TICS_TIMEOUT_WAIT = 2 * 1000 / ms -- 2 seg

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

local autonomous = true

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

-- local w = 0

-- states
local STOP = {"STOP"}
local INIT = {"INIT"}
local ROTATE = {"ROTATE"}
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
local tics_timeout_a_init = 0
local tics_timeout_teleop = 0

local init_h_search = function()
  for i=1,N_SENSORS do
    sensors_min_read[i] = 1 -- 1, centinela, max value norm
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
      if b then
        if autonomous then
          tics_timeout_wait = 0
          h_state = H_WAIT
        end
      else
        h_state = H_OFF
        xdot = 0
        ydot = 0
        cur_w = 0
        omni.drive(xdot,ydot,cur_w)
      end
end

-- enable distC change monitoring
distC.get_dist_thresh(4*ms, thershold, histeresis, dump_dist)

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
local max_bright = 50
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

-- the callback will be called with all sensor readings
local dist_callback= function(d1, d2, d3, d4, d5, d6)
  local norm_d = {0, 0, 0, 0, 0, 0}
  local alpha_lpf = 1 -- low pass filter update parameter
  local MASK_ON_SENSORS = {true, true, true, true, true, true}
  -- local MASK_ON_SENSORS = {true, false, false, false, false, false}
  local MAX_TICS_TIMEOUT_TELEOP = 10 * 1000 / ms -- 10 seg
  local MAX_TICS_TIMEOUT_A_INIT = 3 -- 3 ms
  local act_ori={d1, d2, d3, d4, d5, d6}

  local filters_on = false

  -- apply distance data filter and update LEDs ring
  for i = 1,N_SENSORS do
    if filters_on then
      sensors_win[i][current_wp] = act_ori[i]
      act_d[i] = act_d[i] + alpha_lpf*(median(sensors_win[i])-act_d[i])
    else
      act_d[i] = act_ori[i]
    end

    if act_d[i] > dmin and act_d[i] < dmax and MASK_ON_SENSORS[i] then
      norm_d[i] = line(dmin, 0, dmax, 1, act_d[i])   -- 0..1
    else
      norm_d[i] = 0
    end
  end

  current_wp = (current_wp + 1) % WIN_SIZE

  if not autonomous then
    norm_d={0, 1, 0, 0, 0, 0} -- switch on ahead leds only

    tics_timeout_teleop = tics_timeout_teleop  + 1
    if tics_timeout_teleop >= MAX_TICS_TIMEOUT_TELEOP then
      tics_timeout_teleop = 0
      xdot = 0
      ydot = 0
      cur_w = 0
      omni.drive(xdot,ydot,cur_w)
      -- TODO: dont return to autonomous
      -- autonomous = true
    end
  else
    if h_state == H_WAIT then
      tics_timeout_wait = tics_timeout_wait + 1
      if tics_timeout_wait >= MAX_TICS_TIMEOUT_WAIT then
        -- h_state = H_ALIGN
        -- a_state = STOP
        h_state = H_SEARCH
        init_h_search()
        a_state = STOP
        cur_w = -W_ROTATE -- oposite rotate direction respect to the initial rotation in the align state
      end
    elseif h_state == H_SEARCH then
      tics_timeout_search = tics_timeout_search + 1
      if s_state == S_PAN_60 then
        for i=1,N_SENSORS do
          if sensors_min_read[i] > norm_d[i] and norm_d[i] ~=0 then -- and  state_sensors_read[i] == SS_START then
            sensors_min_read[i] = norm_d[i]
          -- else
          --   state_sensors_read[i] = SS_END
          -- end
          -- if state_sensors_read[i] == SS_END then
          --   sensors_ready = sensors_ready + 1
          end
        end

        -- if (sensors_ready == N_SENSORS) then -- tienen el problema que un sensor se queda con el objeto que encuentra primero pero ... probar
        if tics_timeout_search >= MAX_TICS_TIMEOUT_SEARCH then
          for i=1,N_SENSORS do
            if sensors_min_read[i] == 1 then -- do not find any object
              sensors_min_read[i] = 0 -- do not find in indexsort!
            end
          end
          id_align = indexsort(sensors_min_read)
          -- print("max:", norm_d[id_align], "id: ", id_align)
          if sensors_min_read[id_align] == 0 then -- do not find any object
            init_h_search()
            h_state = H_SEARCH
            cur_w = -W_ROTATE -- oposite rotate direction respect to the initial rotation in the align state
          else
            d_last = norm_d[id_align] --sensors_min_read[id_align]
            s_state = S_FIND_MAX_MIN
            tics_timeout_search = 0 -- timeout to find the object again
            cur_w = -cur_w
          end
        end
      elseif s_state == S_FIND_MAX_MIN then
        -- if (norm_d[id_align] + TOL_APROACH) > d_last and norm_d[id_align] > 0 then
        local TOL_MIN_ALIGN = 0.005
        if tics_timeout_search >= MAX_TICS_TIMEOUT_SEARCH then -- search for a new object
          -- init_h_search()
          -- h_state = H_SEARCH
          -- cur_w = -W_ROTATE -- oposite rotate direction respect to the initial rotation in the align state
          -- TODO: debug
          if autonomous then
            tics_timeout_wait = 0
            cur_w = 0
            h_state = H_WAIT
          end

        elseif norm_d[id_align] < (sensors_min_read[id_align] + TOL_MIN_ALIGN) and norm_d[id_align] ~= 0 then
          cur_w = 0
          h_state = H_GO
          -- d_last = norm_d[id_align]
          -- s_state = S_BACK
          -- cur_w = -cur_w
          -- a_state = PAN
          -- h_state = H_ALIGN
          -- d_last = norm_d[id_align]
        end
      elseif s_state == S_BACK then
        cur_w = 0
        -- h_state = H_ALIGN
        a_state = STOP
        -- a_state = INIT
        h_state = H_GO
        d_last = norm_d[id_align]
      end
      omni.drive(0,0,cur_w)
    elseif h_state == H_ALIGN then
      -- execute alingn state machine
      -- if norm_d[id_align] == 0 then
      --   -- cur_w = -W_ROTATE -- oposite rotate direction respect to the initial rotation in the align state
      --   h_state = H_DEBUG
      --   cur_w = 0
        -- h_state = H_SEARCH
        -- init_h_search()
      if a_state == STOP then
        cur_w = W_ROTATE
        a_state = INIT
        tics_timeout_a_init = 0
      elseif a_state == INIT then
        if tics_timeout_a_init >= MAX_TICS_TIMEOUT_A_INIT or norm_d[id_align] ~= 0 then
          cur_w = 0
          a_state = ROTATE
        else
          tics_timeout_a_init = tics_timeout_a_init + 1
        end
      elseif a_state == ROTATE then
        if norm_d[id_align] == 0 then
          cur_w = -W_ROTATE
        else
          cur_w = W_ROTATE
        end
        a_state = PAN
        d_last = norm_d[id_align]
      elseif a_state == PAN then
        if d_last < norm_d[id_align] then
          a_state = BACK
          cur_w = -cur_w
        end
        d_last = norm_d[id_align]
      elseif a_state == BACK then
        cur_w = 0
        a_state = STOP
        -- h_state = H_GO
        h_state = H_DEBUG
      end
      omni.drive(0,0,cur_w)
      d_last = norm_d[id_align]
    elseif h_state == H_GO then
      if norm_d[id_align] == 0 then
        h_state = H_SEARCH
        init_h_search()
      -- elseif ((d_last - norm_d[id_align]) < TOL_APROACH) then
      --   h_state = H_ALIGN
      --   a_state = STOP
      --   cur_w = 0
      --   xdot = 0
      --   ydot = 0
      else
        local MAX_VEL = 0.2
        local MIN_VEL = 0.01
        local foo = {0, 0, 0, 0, 0, 0}
        foo[id_align] = line(1, MAX_VEL, 0, 0, norm_d[id_align])
        if foo[id_align] < MIN_VEL then foo[id_align] = MIN_VEL end -- lineal with step
        compute_velocity(foo)
      end
      d_last = norm_d[id_align]
      omni.drive(xdot,ydot,cur_w)
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
    -- los leds reflean distancia aun si es menor a dmin
    for i = 1,N_SENSORS do
      if act_d[i] > dmax then
        norm_d[i] = 0
      else
        norm_d[i] = line(0, 0, dmax, 1, act_d[i])   -- 0..1
      end
    end
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
local udp
local ip
local dgram

print("Binding to host '" ..host.. "' and port " ..port.. "...")
udp = assert(socket.udp())
assert(udp:setsockname(host, port))
-- assert(udp:settimeout(5))
ip, port = udp:getsockname()
assert(ip, port)
print("Waiting packets on " .. ip .. ":" .. port .. "...")

thread.start(function()
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
