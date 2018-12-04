--- Test omni.
-- Led ring is attached to encoders.

local omni = require('omni')
local ledr = require 'led_ring'
ledr.init(50)

local dt = 2000   --ms
local v  = 0.05   --m/s

local pos = { 1, 1, 1 }
local feedback_encoders = function (encoder, dir, counter)
  -- print("encoder: " .. encoder,"direction: "..dir,"counter: "..counter)

  ledr.set_led(pos[encoder], 0, 0, 0)
  pos[encoder] = counter % ledr.n_leds + 1

  local leds = {}
  for i=1, 3 do 
    leds[pos[i]] = leds[pos[i]] or {0, 0, 0}
    leds[pos[i]][i] = 255
  end
  for i, color in pairs(leds) do
    ledr.set_led(i, color[1], color[2], color[3])
  end
  ledr.update()
end
ledr.set_led(1, 255, 255, 255)
ledr.update()

omni.encoder.cb.append(feedback_encoders)
omni.encoder.enable(true)
omni.enable(true)

omni.drive(v,0,0)
tmr.sleepms(dt)
omni.drive(0,v,0)
tmr.sleepms(dt)
omni.drive(-v,0,0)
tmr.sleepms(dt)
omni.drive(0,-v,0)
tmr.sleepms(dt)

omni.enable(false)

