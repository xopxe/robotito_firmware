local ahsm = require 'ahsm'

local VEL_CMD = 'speed'
local NVS_WRITE = 'nvswrite'
local DO_STEP = 'step'
local DO_TURN = 'turn'

local e_msg = { _name="WIFI_MESSAGE", cmd = nil,}
local e_fin = { _name="FINCONTROL", }

local offset_led = 2

local s_remote_control = ahsm.state {
  entry = function()
    robot.led_ring.clear()
    robot.led_ring.set_led((offset_led + 5)%24, 0,50,0 , true)
    robot.led_ring.set_led((offset_led + 6)%24, 0,50,0 , true)
    robot.led_ring.set_led((offset_led + 7)%24, 0,50,0 , true)
  end,
  exit = function()
    robot.led_ring.clear()
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
        if #data == 4 then
          local dir = data[2]
          local dt = data[3]
          local v = data[4]
          local xdot, ydot = 0, 0
          if dir=='N' then ydot=v
          elseif dir=='S' then ydot=-v
          elseif dir=='E' then xdot=v
          elseif dir=='W' then xdot=-v end
          robot.omni.drive(xdot,ydot,0)
          tmr.sleepms( math.floor(1000*dt) )
          robot.omni.drive(0,0,0)
        end
      elseif data[1] == DO_TURN then
        if #data == 4 then
          local dir = data[2]
          local dt = data[3]
          local v = data[4]
          local w = v; -- I asume that we turn left
          if dir=='R' then ydot=-v end
          robot.omni.drive(0,0,w)
          tmr.sleepms( math.floor(1000*dt) )
          robot.omni.drive(0,0,0)
        end
      else
        robot.hsm.queue_event(e_fin)
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
