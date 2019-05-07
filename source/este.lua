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
local LIST_MAINS = 'list_mains'

local tics_timeout_teleop = 0
local autonomous = true

local m = require('omni')

local global_enable = true
local local_enable = false
m.enable(global_enable and local_enable)

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

function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local VEL_CMD = 'speed'

net.wf.setup(
  net.wf.mode.AP,
  "robotito-ls-dev",
  "12345678",
  --net.packip(192,168,2,1), net.packip(255,255,255,0),
  -- net.wf.powersave.MODEM
  net.wf.powersave.NONE, -- default
  6 -- channel
)

net.wf.start()

print("Binding to host '" .. tostring(host) .. "' and port " .. tostring(port) .. "...")

udp:setoption('broadcast', true)
assert(udp:setsockname(host, port))
-- assert(udp:settimeout(5))
ip, port = udp:getsockname()
assert(ip, port)
print("Waiting packets on " .. tostring(ip) .. ":" .. tostring(port) .. "...")

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
      elseif cmd[1] == LIST_MAINS then
        if #cmd == 2 then
          msg = '[INFO] List Main command received.\n' .. os.ls(".")
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
