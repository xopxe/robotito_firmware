local ahsm = require 'ahsm'
local color = require('color')
local ledr = require 'led_ring'
local omni = require 'omni'

local VEL_CMD = 'speed'
local NVS_WRITE = 'nvswrite'
local DO_STEP = 'step'
local DO_TURN = 'turn'
local LIGHT_SWITCHER = 'switcher'
local LIGHT_MODE = 'mode' --white/color

local e_msg = { _name="WIFI_MESSAGE", cmd = nil,}
local e_fin = { _name="FINCONTROL", }

--local offset_led = 2

local id_local = -1
local lights_on = false
local white_on = false

local step_info = {
  ['N'] = {
    ['dir'] = math.pi/2, ['color'] = 'green'
  },
  ['S'] = {
    ['dir'] = 3*math.pi/2, ['color'] = 'red'
  },
  ['E'] = {
    ['dir'] = 0, ['color'] = 'yellow'
  },
  ['W'] = {
    ['dir'] = math.pi, ['color'] = 'blue'
  }
}

for coord, t in pairs(step_info) do
  local rgb = color.color_rgb[t['color']]

  t.r, t.g, t.b = rgb[1], rgb[2], rgb[3]
  t.x = math.cos(t.dir)
  t.y = math.sin(t.dir)
  t.led = math.floor(ledr.n_leds*t.dir/(2*math.pi))
end

local function paint_leds_empty ()
  ledr.set_all(0, 0, 0)
  for coord, t in pairs(step_info) do
    if white_on then
      ledr.set_arc(t.led, 1, 20, 20, 20)
    else
      ledr.set_arc(t.led, 1, t.r, t.g, t.b)
    end
  end
  --ledr.update()
end

local s_remote_control = ahsm.state {
  entry = function()
    paint_leds_empty()
    if lights_on then
      ledr.update()
    else
      ledr.clear()
    end
  end,
}

local function split(s, delimiter)
  local result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match)
  end
  return result
end

local t_command = ahsm.transition {
  src = s_remote_control, tgt = s_remote_control,
  events = { e_msg },
  timeout = 5.0,
  effect = function (ev)
    if (ev == e_msg) then
      local data = ev.data
      if data[1] == VEL_CMD then
        if #data == 5 then
          local xdot = data[2]
          local ydot = data[3]
          local w = data[4]
          robot.omni.drive(xdot,ydot,w)
        end

      elseif data[1] == NVS_WRITE then
        if #data == 5 then
          local namespace = data[2]
          local variable = data[3]
          local value = data[4]
          local type = data[5]
          if type=='number' then value=tonumber(value) end
          if type=='nil' then value=nil end
          nvs.write(namespace, variable, value)
        end

      elseif data[1] == DO_STEP then
        if #data == 5 then
          local coord = data[2]
          local dt = data[3]
          local v = data[4]
          local id = data[5]

          local t = step_info[coord]

          if id_local ~= id then --havent read this message
            id_local = id
            if lights_on then
		if white_on then
			ledr.set_arc(t.led -2, 5, 20, 20, 20, true)
		else
			ledr.set_arc(t.led -2, 5, t.r, t.g, t.b, true)
		end
            end
            robot.omni.drive(v*t.x, v*t.y, 0)
            tmr.sleepms(math.floor(1000*dt))
            robot.omni.drive(0,0,0)
          end
        end

      elseif data[1] == DO_TURN then
        if #data == 5 then
          local dir = data[2]
          local dt = data[3]
          local v = data[4]*5
          local id = data[5]

          if id_local ~= id then
            id_local = id
            local w = v; -- I asume that we turn left
            if dir == 'R' then w = -v end
            robot.omni.drive(0,0,w)
            tmr.sleepms(math.floor(1000*dt))
            robot.omni.drive(0,0,0)
          end
        end

      elseif data[1] == LIGHT_SWITCHER then
        if #data == 2 then
          lights_on = (data[2] == 'on')         
        end

      elseif data[1] == LIGHT_MODE then
        if #data == 2 then
          white_on = (data[2] == 'white')
        end

      else
        robot.hsm.queue_event(e_fin)
      end

    end
  end
}

local event_message = function(data,ip,port)
  data = split(data, '*')
  e_msg.data = data
  robot.hsm.queue_event(e_msg)
end

-- root state
local remote = ahsm.state {
  events =  { WIFIMESSAGE = e_msg, FINCONTROL = e_fin },
  states = { REMOTECONTROL=s_remote_control},
  transitions = { COMMAND=t_command},
  initial = s_remote_control,
  entry = function()
    robot.wifi_net.cb.append(event_message)
  end,
  exit = function()
    robot.wifi_net.cb.remove(event_message)
  end,
}

return remote
