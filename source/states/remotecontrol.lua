local ahsm = require 'ahsm'
local color = require('color')
local ledr = require 'led_ring'
local omni = require 'omni'

local VEL_CMD = 'speed'
local NVS_WRITE = 'nvswrite'
local DO_STEP = 'step'
local DO_TURN = 'turn'
local LIGHT_SWITCHER = 'switcher'
local LIGHT_MODE = 'mode'
local TURN_360 = 'turn360'
local DANCE = 'dance'


local e_msg = { _name="WIFI_MESSAGE", cmd = nil,}
local e_fin = { _name="FINCONTROL", }



-----

local using_joystick = false
local id_local = -1
local lights_on = false
local white_on = false

local step_info = {
  ['N'] = {
    ['dir'] = math.pi/2, ['color'] = 'green'
  },
  ['E'] = {
    ['dir'] = 0, ['color'] = 'yellow'
  },
  ['S'] = {
    ['dir'] = 3*math.pi/2, ['color'] = 'red'
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
end


-----


local part = {}
for i = 1,24 do
	part[i] = i*math.floor(100/24)
end

local baile = {}

baile[1] = function()
	local w = 0.9
	local dt = 70
	omni.drive(0,0,w)
	for i=1,24 do
		ledr.set_led(i, part[i], 0, part[25-i], true)
		tmr.sleepms(dt)	
	end
	for i=1,24 do
		ledr.set_led(i, part[25-i], part[i], 0, true)
		tmr.sleepms(dt)	
	end
	for i=1,24 do
		ledr.set_led(i, 0, part[25-i], part[i], true)
		tmr.sleepms(dt)	
	end
	ledr.clear()
	omni.drive(0,0,0)
end

baile[2] = function()
	local v = 0.08
	local dt = 400
	for i=1,4 do
		for coord, t in pairs(step_info) do
			ledr.set_all(10,10,10,true)
			ledr.set_arc(t.led -2, 5, t.r, t.g, t.b, true)
			omni.drive(v*t.x,v*t.y,0)
			tmr.sleepms(400)
			ledr.clear()
			
		end
	end
	omni.drive(0,0,0)
	for coord, t in pairs(step_info) do
		ledr.set_arc(t.led -2, 5, t.r, t.g, t.b, true)
	end
	tmr.sleepms(1000)
	ledr.clear()
end

baile[3] = function()
	local w = 0.9
	local dt = 20
	local on = true
	
	for j=1,6 do
		omni.drive(0,0,w)
		for i=1,24 do
			if on then
				ledr.set_led(i, 0, part[i], part[25-i], true)
			else
				--ledr.set_led(25-i, 0, 0, 0, true)
				ledr.set_led(25-i, part[25-i], part[i], 0, true)
			end
			tmr.sleepms(dt)	
		end
		w = -w
		on = not on
	end
	omni.drive(0,0,0)
	for i=1,24 do
		ledr.set_led(i, part[i], 0, part[25-i], true)
	end
	tmr.sleepms(1500)
	ledr.clear()

end

baile[4] = function()
	local v = 0.07
	local dt = 20

	for j=1,4 do
		omni.drive(v,0,0)
		for i=1,24 do
			ledr.set_all(i, part[25-i], part[i], 0, true)
			tmr.sleepms(dt)	
		end
		omni.drive(v*math.cos(2*math.pi/3),v*math.sin(2*math.pi/3),0)
		for i=1,24 do
			ledr.set_all(i, 0, part[25-i], part[i], true)
			tmr.sleepms(dt)	
		end
		omni.drive(v*math.cos(4*math.pi/3),v*math.sin(4*math.pi/3),0)
		for i=1,24 do
			ledr.set_all(i, part[i], 0, part[25-i], true)
			tmr.sleepms(dt)	
		end
	end
	omni.drive(0,0,0)
	ledr.clear()
	
end

baile[5] = function()
	local dt = 40
	local rbow = {}
	rbow[1] = {['r']=100, ['g']=0, ['b']=0}
	rbow[2] = {['r']=100, ['g']=54, ['b']=0}
	rbow[3] = {['r']=100, ['g']=94, ['b']=0}
	rbow[4] = {['r']=0, ['g']=100, ['b']=0}
	rbow[5] = {['r']=0, ['g']=0, ['b']=100}
	rbow[6] = {['r']=77, ['g']=0, ['b']=100}

	for j=1,150 do
		for i=1,24 do
			local k = (i+j)%6+1
			ledr.set_led(i, rbow[k].r, rbow[k].g, rbow[k].b)
		end
		ledr.update()
		tmr.sleepms(dt)
	end
	ledr.clear()
end





-----


local s_remote_control = ahsm.state {
	entry = function()
		paint_leds_empty()
		if lights_on then
			ledr.update()
		else
			ledr.clear()
		end
	end
}


local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end



-----




local t_command = ahsm.transition {
	src = s_remote_control, tgt = s_remote_control,
	events = { e_msg },
	--timeout = 5.0,
	effect = function (ev)
		if (ev == e_msg) then
			local data = ev.data

			if data[1] == VEL_CMD and #data == 5 then ----

				local xdot = data[2]
				local ydot = data[3]
				local w = data[4]
				robot.omni.drive(xdot,ydot,w)

			elseif data[1] == NVS_WRITE and #data == 5 then ----

				local namespace = data[2]
				local variable = data[3]
				local value = data[4]
				local type = data[5]
				if type=='number' then
					value=tonumber(value)
				end
				if type=='nil' then
					value=nil
				end
				nvs.write(namespace, variable, value)

			elseif data[1] == DO_STEP and #data == 5 then ----

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

			elseif data[1] == DO_TURN and #data == 5 then ----

				local dir = data[2]
				local dt = data[3]
				local v = data[4]*5
				local id = data[5]

				if id_local ~= id then
					id_local = id
					local w = v; -- I asume that we turn left
					if dir == 'R' then 
						w = -v
					end
					robot.omni.drive(0,0,w)
					tmr.sleepms(math.floor(1000*dt))
					robot.omni.drive(0,0,0)
				end

			elseif data[1] == LIGHT_SWITCHER and #data == 2 then ----

				lights_on = (data[2] == 'on')

			elseif data[1] == LIGHT_MODE and #data == 2 then ----

				white_on = (data[2] == 'white')

			elseif data[1] == TURN_360 and #data == 3 then ----

				local dt = math.floor(data[2]) --in seconds
				local id = data[3]
				
				print('dt:', dt)

				if id_local ~= id then
					id_local = id
					local w = 2*(math.pi)/dt
					if w < 1.4 then				
						--omni.drive(0,0,w)
						--tmr.sleepms(1000*dt)
						--omni.drive(0,0,0)
					end
				end

			elseif data[1] == DANCE and #data == 3 then ----

				local id = data[3]

				if id_local ~= id then
					id_local = id
					baile[data[2]+1]()
				end

			end ----

		else
			robot.hsm.queue_event(e_fin)
		end
	end
}



-----


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
