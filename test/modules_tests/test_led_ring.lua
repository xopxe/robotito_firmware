--- Test laser ring.

local ledr = require 'led_ring'

local floor, cos, pi = math.floor, math.cos, math.pi

for c=1, 3 do
  local color={0,0,0}
  color[c]=100
  for i=1, 24 do
    ledr.set_led(i, color[1], color[2], color[3], true)
    tmr.delayms(50)
  end
end

tmr.delayms(500)
ledr.clear()
local length, c1, c2, c3
for i=1, 24*3 do
  c1 = 50+floor(50*math.cos(2*pi*i/24))
  c2 = 50+floor(-50*cos(2*pi*(i+8)/24))
  c3 = 50+floor(50*cos(2*pi*(i+16)/24))
  ledr.set_all(c3,c1,c2)
  length = 10+floor(7*cos(pi*i/24))
  ledr.set_arc(i, -length, c1, c2, c3)
  ledr.update()
  tmr.delayms(50)
end

tmr.delayms(500)
ledr.clear()
for i=1,6 do
  ledr.set_segment(i, true, nil, nil, true)
  tmr.delayms(200)
end

