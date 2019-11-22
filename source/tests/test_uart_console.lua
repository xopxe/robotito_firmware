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
    print(data)
    data = split(data, '*')
    if data[1] == VEL_CMD then
      if #data == 5 then
        local xdot = data[2]
        print(xdot)
        local ydot = data[3]
        print(ydot)
        local w = data[4]
        print(w)
        robot.omni.drive(xdot,ydot,w)
      end
    end
  end
end
