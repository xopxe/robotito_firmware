local host = "192.168.4.1"
local ip
local ip_broadcast =  "192.168.4.255"
local port = 2018

local socket = require("__socket")
local udp = assert(socket.udp())
local DELIMITER = '*'
local COLOR_CMD = 'color'
local GET_PARAM = 'get_param'
local SET_PARAM = 'set_param'

local tics_timeout_teleop = 0
local autonomous = true

local apds = assert(require('apds9960'))
local ledpin = pio.GPIO19
local n_pins = 24
local led_pow = 10

local min_sat = 60
local min_val = 33
local max_val = 270

local colors = {
  -- robotito 5, 2, 0
  -- {"orange", 12, 17}, -- 12
  {"yellow", 45, 62},   --53-55,  46 - 48, 61 ;: todos
  {"green", 159, 185}, -- 162-164, 183, x  ;: todos 159, 185
  {"blue", 208, 216}, -- 208-210, 212 - 213, x ;: todos 208, 216
  {"rose", 250, 271}, -- 264 - 268, 257, 250  ;: todos 250, 271
  {"red", 351 , 353}, -- 355 - 357, 343 - 346, x ;: todos 343 , 359

  -- {"violet", 221, 240},
}

local offset_led = 2    -- robotito 5 (20), robotito 1,3, 8 (2), robotito 2 (5), robotito 0 (8)

assert(apds.init())
local distC = apds.proximity
assert(distC.enable())

local color = apds.color
assert(color.set_color_table(colors))
assert(color.set_sv_limits(min_sat,min_val,max_val))
assert(color.enable())

local led_const = require('led_ring')
local neo = led_const(ledpin, n_pins, led_pow)

local m = require('omni')

local global_enable = true
local local_enable = false
m.set_enable(global_enable and local_enable)

local ms_dist = 200
local ms_color = 80
local thershold = 251
local histeresis = 3

local H_OFF = {"H_OFF"}
local H_ON = {"H_ON"}
local h_state = H_OFF

local last_color = "NONE"
local tics_same_color = 0
local TICS_NEW_COLOR = 4

local x_dot = 0
local y_dot = 0
local w = 0

-- callback for distC.get_dist_thresh
-- will be called when the robot is over threshold high
local dump_dist = function(b)
      if b then
        last_color = "NONE"
        tics_same_color = 0
        h_state = H_ON
        local_enable = true
      else
        x_dot = 0
        y_dot = 0
        w = 0
        local_enable = false
        m.set_enable(local_enable and global_enable)
        m.drive(x_dot,y_dot,w)
        h_state = H_OFF
        turn_all_leds(0,0,0)
      end
end

-- enable distC change monitoring
distC.get_dist_thresh(ms_dist, thershold, histeresis, dump_dist)

function turn_all_leds(r,g,b)
  if (r + g + b) == 0 then  -- draw axis
    neo.clear()
    neo.set_led(offset_led, 50,0,0, true)
    neo.set_led((offset_led + 6)%24, 0,50,0 , true)
    neo.set_led((offset_led + 12)%24, 0,0,50 , true)
    neo.set_led((offset_led + 18)%24,160 , 100, 0, true)
    -- robotito 1
    -- neo.set_led(2, 50,0,0, true)
    -- neo.set_led(8,0,50,0 , true)
    -- neo.set_led(14, 0,0,50 , true)
    -- neo.set_led(20,160 , 100, 0, true)
  else
    for pixel= offset_led, offset_led+24, 6 do
      neo.set_led((pixel+2)%24, r, g, b, true)
      neo.set_led((pixel+3)%24, r, g, b, true)
    end
  end
end

dump_rgb = function(r,g,b,a,h,s,v, c)
  local MAX_VEL = 0.07
  local MAX_TICS_TIMEOUT_TELEOP = 10 * 1000 / ms_color -- 10 seg

  if not autonomous then
    tics_timeout_teleop = tics_timeout_teleop  + 1
    if tics_timeout_teleop >= MAX_TICS_TIMEOUT_TELEOP then
      tics_timeout_teleop = 0
      x_dot = 0
      y_dot = 0
      w = 0
      local_enable = false
      m.set_enable(local_enable and global_enable)
      m.drive(x_dot,y_dot,w)

      -- TODO: dont return to autonomous
      -- autonomous = true
    end
  elseif h_state == H_ON then
    --print('color', c, 'sv', s, v)
    if last_color == c then
      if tics_same_color < TICS_NEW_COLOR then
        tics_same_color = tics_same_color + 1
      elseif tics_same_color == TICS_NEW_COLOR then
        tics_same_color = tics_same_color + 1 -- last time that run this code
        -- print('new color')
        if c == "red" then
          x_dot = MAX_VEL
          y_dot = 0
          w = 0
          turn_all_leds(50,0,0)
        elseif c == 'blue' then
          x_dot = -MAX_VEL
          y_dot = 0
          w = 0
          turn_all_leds(0,0,50)
        elseif c == 'green' then
          x_dot = 0
          y_dot = MAX_VEL
          w = 0
          turn_all_leds(0,50,0)
        elseif c == 'yellow' then --or c == 'orange'  then
          x_dot = 0
          y_dot = -MAX_VEL
          w = 0
          -- turn_all_leds(255,0,140) -- violet
          -- turn_all_leds(255,70,0) -- orange
          turn_all_leds(160,100,0) -- yellow
        -- else
        --   turn_all_leds(0,0,0)
        elseif c == 'rose' then
          x_dot = 0
          y_dot = 0
          w = 0.5
          turn_all_leds(255,0,140) -- violet
        end
        m.set_enable(local_enable and global_enable)
        m.drive(x_dot,y_dot,w)
      end
    else
      last_color = c
      tics_same_color = 0
    end
    -- neo.clear()
  end

  local sens_str = COLOR_CMD .. DELIMITER .. tostring(r) .. DELIMITER .. tostring(g) .. DELIMITER .. tostring(b) .. DELIMITER .. tostring(a) .. DELIMITER .. tostring(h) .. DELIMITER .. tostring(s) .. DELIMITER .. tostring(v) .. DELIMITER .. c
  udp:sendto(sens_str, ip_broadcast, port)
  -- print('ambient:', a, 'rgb:', r, g, b,'hsv:', h, s, v, 'name:', name)
end

-- callback for color.get_continuous
-- will be called with (r,g,b,a [,h,s,v])
-- hsv will be provided if enabled on color.get_continuous
-- r,g,b,a : 16 bits
-- h: 0..360
-- s,v: 0..255

--power on led
local led_color_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_color_pin)
pio.pin.sethigh(led_color_pin)

-- enable raw color monitoring, enable hsv mode
color.get_continuous(ms_color, dump_rgb, true)

-- enable color change monitoring, enable hsv mode
-- color.get_change(ms, change_direction)

print("ready to playt with colors")

function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local VEL_CMD = 'speed'

print("Binding to host '" .. tostring(host) .. "' and port " .. tostring(port) .. "...")

udp:setoption('broadcast', true)
assert(udp:setsockname(host, port))
-- assert(udp:settimeout(5))
ip, port = udp:getsockname()
assert(ip, port)
print("Waiting packets on " .. tostring(ip) .. ":" .. tostring(port) .. "...")

turn_all_leds(0,0,0)

thread.start(function()
  local cmd
  local dgram
  local msg
  local namespace, parameter, value

  while 1 do
  	dgram, ip, port = udp:receivefrom()
  	if dgram then
  		-- print("Echoing '" .. dgram .. "' to " .. ip .. ":" .. port)
      cmd = split(dgram, '*')

      if cmd[1] == VEL_CMD then
        if #cmd == 5 then
          autonomous = false
          neo.clear()
          neo.set_led((offset_led + 5)%24, 0,50,0 , true)
          neo.set_led((offset_led + 6)%24, 0,50,0 , true)
          neo.set_led((offset_led + 7)%24, 0,50,0 , true)

          tics_timeout_teleop = 0
          x_dot = cmd[2]
          y_dot = cmd[3]
          w = cmd[4]
          local_enable = not (x_dot==0 and y_dot==0 and w ==0)
          m.set_enable(local_enable and global_enable)
          m.drive(x_dot,y_dot,w)
          msg = '[INFO] Speed command received (' .. tostring(x_dot) .. ', ' .. tostring(y_dot) .. ')'
        else
          msg = '[ERROR] Malformed command.'
        end
      elseif cmd[1] == SET_PARAM then
        if #cmd == 4 then
          namespace = cmd[2]
          parameter = cmd[3]
          value = cmd[4]
          nvs.write(namespace, parameter, value)
          if namespace == 'motors' and parameter == 'enable' then
            global_enable = value == 'true'
            m.set_enable(global_enable and local_enable)
          end
          msg = '[INFO] Set parameter command received (' .. tostring(namespace) .. ', ' .. tostring(parameter) .. ', ' .. tostring(value) .. ')'
        else
          msg = '[ERROR] Malformed command.'
        end
      elseif cmd[1] == GET_PARAM then
        if #cmd == 3 then
          namespace = cmd[2]
          parameter = string.gsub(cmd[3], "\n", "")
          -- print(parameter, '....', namespace)

          value = nvs.read(namespace, parameter, 'key not found')
          msg = '[INFO] Get parameter command received (' .. tostring(namespace) .. ', ' .. tostring(parameter) .. ', ' .. tostring(value) .. ')'
        else
          msg = '[ERROR] Malformed command.'
        end
      else
        msg = '[ERROR] Unknown command: ' .. cmd[1]
      end
      -- print(msg)
      udp:sendto(msg, ip_broadcast, port)
    end -- if dgram
  end -- while true
end) --end thread
