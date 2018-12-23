local color = require('color')
local ledr = require 'led_ring'
ledr.set_power(10)

local uart_write, uart_CONSOLE = uart.write, uart.CONSOLE

local colors = {
  ["red"] = {255,0,0}, 
  ["yellow"] = {127,127,0}, 
  ["green"] = {0,255,0}, 
  ["blue"] = {0,0,255}, 
  ["magenta"] = {127,0,127}, 
  ["black"] = {0,0,0}, 
  ["white"] = {255,255,255}, 
  ["unknown"] = {0,0,0}, 
}

local color_change_cb = function(name, h, s, v)
  print('COLOR:'..tostring(name), 'hsv:', h, s, v)
  local color = colors[name]
  ledr.set_all(color[1], color[2], color[3], true)
end

if color.light then 
  color.light(true) --power on led
end

color.color_cb.append(color_change_cb)

print('Start color monitoring')
color.enable(true)

while true do
  tmr.sleep(1)
end