--- Test laser ring.

local ledr = require 'led_ring'
ledr.init(50)

for c=1, 3 do
  local color={0,0,0}
  color[c]=50
  for i=1, 24 do
    ledr.set_led(i, color[1], color[2], color[3])
    ledr.update()
    tmr.delayms(50)
  end
end

tmr.delayms(1000)
ledr.clear()
for c=1, 3 do
  local color={0,0,0}
  color[c]=50
  for i=1, 6 do
    ledr.set_segment_rgb(i, color[1], color[2], color[3])
    tmr.delayms(50)
  end
end

tmr.delayms(1000)
ledr.clear()
for i=1,6 do
  ledr.set_segment(i, true)
  tmr.delayms(50)
end

