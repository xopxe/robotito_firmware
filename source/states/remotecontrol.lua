local ahsm = require 'ahsm'

local VEL_CMD = 'speed'

local e_msg = { _name="WIFI_MESSAGE", xdot = nil, ydot = nil, w = nil, }

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

local behavior_name = nvs.read("ahsm", "behavior", nil) or nil
print('behavior loading:', behavior_name)

local s_behavior = ahsm.state{
  entry = function()
    print("NO BEHAVIOR .... please load one")
  end
}

if (behavior_name ~= nil) then
  s_behavior = require( behavior_name )
end


function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local t_command = ahsm.transition {
  src = s_remote_control, tgt = s_remote_control,
  events = { e_msg },
  effect = function (ev)
    robot.omni.drive(ev.xdot,ev.ydot,ev.w)
  end
}

local t_timeout = ahsm.transition {
  src = s_remote_control, tgt = s_behavior,
  timeout = 3.0,
}

local t_behavior_to_command = ahsm.transition {
  src = s_behavior, tgt = s_remote_control,
  events = { e_msg },
  effect = function (ev)
    robot.omni.drive(ev.xdot,ev.ydot,ev.w)
  end
}

local event_message = function(data,ip,port)
  local data = split(data, '*')
  if data[1] == VEL_CMD then
    if #data == 5 then
        e_msg.xdot = data[2]
        e_msg.ydot = data[3]
        e_msg.w = data[4]
        robot.hsm.queue_event(e_msg)
    else
      msg = '[ERROR] Malformed command.'
    end
    -- TODO WIFI SEND msg
  end
end

-- root state
local remote = ahsm.state {
  events =  { WIFIMESSAGE = e_msg },
  states = { REMOTECONTROL=s_remote_control, BEHAVIOUR=s_behavior },
  transitions = { TIMEOUT=t_timeout, COMMAND=t_command, BEHAVTOCOMMD=t_behavior_to_command},
  initial = s_behavior,
  entry = function()
    robot.wifi_net.cb.append(event_message)
    robot.omni.enable(true)
  end,
  exit = function()
    robot.omni.enable(false)
    robot.wifi_net.cb.remove(event_message)
  end,
}

return remote
