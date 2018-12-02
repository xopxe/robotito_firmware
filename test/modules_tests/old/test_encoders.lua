--- Test motor encoders.

local ledr = require 'led_ring'
ledr.init(50)

local pos = { 1, 1, 1 }

local feedback_encoders = function (encoder, dir, counter)
  print("encoder: " .. encoder,"direction: "..dir,"counter: "..counter)

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

local callback1 = function (dir, counter, button)
  feedback_encoders(1, dir, counter)
end

local callback2 = function (dir, counter, button)
  feedback_encoders(2, dir, counter)
end

local callback3 = function (dir, counter, button)
  feedback_encoders(3, dir, counter)
end

enc0 = encoder.attach(pio.GPIO39, pio.GPIO37, 0, callback1)
enc1 = encoder.attach(pio.GPIO38, pio.GPIO36, 0, callback2)
enc2 = encoder.attach(pio.GPIO34, pio.GPIO35, 0, callback3)

ledr.clear()
ledr.set_led(1, 255, 255, 255)
ledr.update()