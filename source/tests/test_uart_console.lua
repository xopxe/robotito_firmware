local uart_write, uart_CONSOLE = uart.write, uart.CONSOLE

local robot = require 'robot'
local VEL_CMD = 'speed'

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

robot.omni.enable(true)

while true do
  local data = uart.read(uart.CONSOLE, "*l", 500)
  if(data ~= nil) then
  	print('LEIDO: ', data)
  	data = split(data, '*')
  	if data[1] == VEL_CMD then
    		if #data == 5 then
      			local xdot = data[2]
      			local ydot = data[3]
     			  local w = data[4]
      			robot.omni.drive(xdot,ydot,w)
    		end
  	end
  end
end


--robot.omni.drive(0.1,0,0)
--speed*0*0*0*0
