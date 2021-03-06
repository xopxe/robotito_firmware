local ahsm = require 'ahsm'

local VEL_CMD = 'speed'

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
      end -- Mas comandos con else if
        if data[1] == 'nvswrite' then
          local namespace = data[2]
          local variable = data[3]
          local value = data[4]
          local type = data[5]
          if type=='number' then value=tonumber(value) end
          if type=='nil' then value=nil end
          nvs.write(namespace, variable, value)
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
