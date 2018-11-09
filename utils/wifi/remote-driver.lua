-----------------------------------------------------------------------------
-- UDP sample: echo protocol server
-- LuaSocket sample files
-- Author: Diego Nehab
-----------------------------------------------------------------------------
local socket = require("__socket")
local omni=require('omni')

local apds = assert(require('apds9960'))
local ledpin = pio.GPIO19
local n_pins = 24
local led_pow = 10

local min_sat = 60
local min_val = 40
local max_val = 270

local colors = {
  -- {"orange", 12, 17}, -- 12
  {"yellow", 22, 65},
  {"green", 159, 180},
  {"blue", 209, 215}, -- 210
  {"rose", 255, 300}, -- 265
  {"red", 351 , 359}, -- 353

  -- {"violet", 221, 240},
}

assert(apds.init())
local distC = apds.proximity
assert(distC.enable())

local color = apds.color
assert(color.set_color_table(colors))
assert(color.set_sv_limits(min_sat,min_val,max_val))
assert(color.enable())

local ms_laser = 100  -- period of distance measurements
local ms_color = 100  -- period of color measurements

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

local xdot = 0
local ydot = 0
local w = 0

local N_SENSORS = 6

local act_d = {0, 0, 0, 0, 0, 0}

-- local neo = neopixel.attach(neopixel.WS2812B, ledpin, n_pins)
local led_const = require('led_ring')
local neo = led_const(pio.GPIO19, 24, 50)

local update_led_ring = function(intensity)
  neo.clear()
  for i = 1,N_SENSORS do
    neo.set_segment(i, (intensity[i] ~= 0))
  end
end -- update_led_ring
-- end neo led ring

local VEL_CMD = 'speed'
local COLOR_CMD = 'color'
local LASER_CMD = 'laser'
local GET_PARAM = 'get_param'
local SET_PARAM = 'set_param'

local host = "192.168.4.1"
local ip_broadcast =  "192.168.4.255"

local ip
local port = 2018

print("Binding to host '" ..host.. "' and port " ..port.. "...")
local udp = assert(socket.udp())
udp:setoption('broadcast', true)
assert(udp:setsockname(host, port))
-- assert(udp:settimeout(5))

ip, port = udp:getsockname()
assert(ip, port)

print("Waiting packets on " .. ip .. ":" .. port .. "... OK")

-- global, store history distance values to compute low pass filter

local WIN_SIZE = 3

local sensors_win = {}          -- create sensors readings matrix
for i=1,N_SENSORS do
  sensors_win[i] = {}     -- create a new row
  for j=1,WIN_SIZE do
    sensors_win[i][j] = 0.0
  end
end

-- global, curren position in the sensor readings history window
local current_wp = 0

local median = function (numlist)
    if type(numlist) ~= 'table' then return numlist end
    table.sort(numlist)
    if #numlist %2 == 0 then return (numlist[#numlist/2] + numlist[#numlist/2+1]) / 2 end
    return numlist[math.ceil(#numlist/2)]
end

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

local DELIMITER = '*'
-- the callback will be called with all sensor readings
local dist_callback= function(d1, d2, d3, d4, d5, d6)
  local alpha_lpf = 1 -- low pass filter update parameter
  local act_ori={d1, d2, d3, d4, d5, d6}
  -- apply distance data filter and update LEDs ring
  for i = 1,N_SENSORS do
    sensors_win[i][current_wp] = act_ori[i] -- MKS units convetion on client
    act_d[i] = act_d[i] + alpha_lpf*(median(sensors_win[i])-act_d[i])
  end

  current_wp = (current_wp + 1) % WIN_SIZE
  -- send laser measurements update
  local sens_str = LASER_CMD .. implode(DELIMITER, act_ori) -- act_d
  -- send laser measurements update
  udp:sendto(sens_str, ip_broadcast, port)
end

dump_rgb = function(r,g,b,a,h,s,v, c)
  -- send color measurements update
  local sens_str = COLOR_CMD .. DELIMITER .. r .. DELIMITER .. g .. DELIMITER .. b .. DELIMITER .. a .. DELIMITER .. h .. DELIMITER .. s .. DELIMITER .. v .. DELIMITER .. c
  udp:sendto(sens_str, ip_broadcast, port)
end

function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local leds_on = {0, 1, 0, 0, 0, 0}
update_led_ring(leds_on)

omni.set_enable()
local enable = true

--power on led
local led_color_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_color_pin)
pio.pin.sethigh(led_color_pin)


vlring.get_continuous(ms_laser, dist_callback)

-- enable raw color monitoring, enable hsv mode
color.get_continuous(ms_color, dump_rgb, true)

thread.start(function()
  local dgram, cmd
  local ip_remote

  while 1 do
  	dgram, ip_remote, port = assert(udp:receivefrom())
  	if dgram then
  		-- print("Echoing '" .. dgram .. "' to " .. ip .. ":" .. port)
      cmd = split(dgram, '*')
      if cmd[1] == VEL_CMD then
        if #cmd == 5 then
          xdot = cmd[2]
          ydot = cmd[3]
          w = cmd[4]

          local nxt_enable = not (xdot==0 and ydot==0 and w ==0)
          if nxt_enable ~= enable then
            enable = nxt_enable
            -- omni.set_enable(enable)
          end
          omni.drive(xdot,ydot,w)
          udp:sendto('[INFO] Speed command received (' .. xdot .. ', ' .. ydot .. ')', ip, port)
        else
          udp:sendto('[ERROR] Malformed command.', ip, port)
        end
      elseif cmd[1] == SET_PARAM then
        if #cmd == 4 then
          namespace = cmd[2]
          parameter = cmd[3]
          value = cmd[4]
          nvs.write(namespace, parameter, value)
          udp:sendto('[INFO] Set parameter command received (' .. namespace .. ', ' .. parameter .. ', ' .. value .. ')', ip, port)
        else
          udp:sendto('[ERROR] Malformed command.', ip, port)
        end
      elseif cmd[1] == GET_PARAM then
        if #cmd == 3 then
          namespace = cmd[2]
          parameter = cmd[3]
          value = nvs.read(namespace, parameter)
          udp:sendto('[INFO] Get parameter command received (' .. namespace .. ', ' .. parameter .. ', ' .. value .. ')', ip, port)
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
end)
