-----------------------------------------------------------------------------
-- UDP sample: echo protocol server
-- LuaSocket sample files
-- Author: Diego Nehab
-----------------------------------------------------------------------------
local socket = require("__socket")
local omni=require('omni')

local table, print, math, type = table, print, math, type

local ms = 200  -- period of distance measurements

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

local xdot = 0
local ydot = 0
local w = 0

local N_SENSORS = 6

local dmin = 80
local dmax = 600
--local d_range = dmax - dmin
--local d_last = 0
local act_d = {0, 0, 0, 0, 0, 0}

local VEL_CMD = 'speed'

local ip = "192.168.4.1"
local port = 2018
local has_remote_cliente = false

print("Binding to host '" ..ip.. "' and port " ..port.. "...")
local udp = assert(socket.udp())
assert(udp:setsockname(ip, port))
-- assert(udp:settimeout(5))
ip, port = udp:getsockname()
assert(ip, port)
print("Waiting packets on " .. ip .. ":" .. port .. "...")

-- global, store history distance values to compute low pass filter

local WIN_SIZE = 3

local sensors_win = {}          -- create sensors readings matrix
for i=1,N_SENSORS do
  sensors_win[i] = {}     -- create a new row
  for j=1,WIN_SIZE do
    sensors_win[i][j] = 0
  end
end

-- global, curren position in the sensor readings history window
local current_wp = 0

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

--[[
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
--]]

local function implode(delimiter, list)
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

-- the callback will be called with all sensor readings
local dist_callback= function(d1, d2, d3, d4, d5, d6)
  local alpha_lpf = 1 -- low pass filter update parameter
  local MASK_ON_SENSORS = {true, true, true, true, true, true}
  local act_ori={d1, d2, d3, d4, d5, d6}
  local norm_d = {0, 0, 0, 0, 0, 0}
  -- apply distance data filter and update LEDs ring
  for i = 1,N_SENSORS do
    sensors_win[i][current_wp] = act_ori[i]
    act_d[i] = act_d[i] + alpha_lpf*(median(sensors_win[i])-act_d[i])
    if act_d[i] > dmin and act_d[i] < dmax and MASK_ON_SENSORS[i] then
      norm_d[i] = line(dmin, 0, dmax, 1, act_d[i])   -- 0..1}
    else
      norm_d[i] = 0
    end
  end
  current_wp = (current_wp + 1) % WIN_SIZE
  if has_remote_cliente then
    -- sens_str = implode('*', norm_d)
    local sens_str = implode('*', act_d)
    udp:sendto(sens_str, ip, port)
  end
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end


omni.set_enable()
vlring.get_continuous(ms, dist_callback)

thread.start(function()
  local dgram, enable
  while 1 do
  	dgram, ip, port = assert(udp:receivefrom())
  	if dgram then
  		print("Echoing '" .. dgram .. "' to " .. ip .. ":" .. port)
      local cmd = split(dgram, '*')
      if cmd[1] == VEL_CMD then
        if #cmd == 5 then
          --autonomous = false
          has_remote_cliente = true
          xdot = cmd[2]
          ydot = cmd[3]
          w = cmd[4]
          omni.drive(xdot,ydot,w)
          local nxt_enable = not (xdot==0 and ydot==0 and w ==0)
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
end)
