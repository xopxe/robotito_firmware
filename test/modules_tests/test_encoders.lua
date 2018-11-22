--dofile('test_encoders.lua')

local ledpin = pio.GPIO19
local n_pins = 24
local led_pow = 10

local led_const = require('led_ring')
local neo = led_const(ledpin, n_pins, led_pow)

local MIN_RGB = 255

local current_led = 0

function feedback_encoders(encoder, dir, counter)
  local color = MIN_RGB + counter
  -- print("encoder: " .. encoder .. ", direction: "..dir..", counter: "..counter..", button: "..button)
  uart.write(uart.CONSOLE, "encoder: " .. encoder .. ", direction: "..dir..", counter: "..counter .. "color: " .. color .. '\r\n')

  current_led = (current_led + dir)%n_pins
  neo.set_led(offset_led, 255,0,0, true)
  -- if color>255 then color = 255 end
  --
  -- if encoder == 0 then
  --   neo.set_led(offset_led, red,0,0, true)
  -- elseif encoder == 1 then
  --   neo.set_led(offset_led, 0,color,0, true)
  -- elseif encoder == 2 then
  --   neo.set_led(offset_led, 0,0,color, true)
  -- end
end

function callback0(dir, counter, button)
  feedback_encoders(0, dir, counter)
  neo.set_led(0, 255,0,0, true)
end

function callback1(dir, counter, button)
  feedback_encoders(1, dir, counter)
  neo.set_led(1, 255,0,0, true)
end

function callback2(dir, counter, button)
  feedback_encoders(2, dir, counter)
  neo.set_led(2, 255,0,0, true)
end

-- Attach an encoder with A=pio.GPIO26, B=pio.GPIO14, SW=pio.GPIO21.
-- Using a calback for get the encoder changes.
---[[
enc0 = encoder.attach(pio.GPIO39, pio.GPIO37, 0, callback0)
enc1 = encoder.attach(pio.GPIO38, pio.GPIO36, 0, callback1)
enc2 = encoder.attach(pio.GPIO34, pio.GPIO35, 0, callback2)

neo.clear()
neo.set_led(0, 255,0,0, true)
neo.set_led(1, 255,0,0, true)
--]]
--[[
enc0 = encoder.attach(pio.GPIO37, pio.GPIO39, 0, callback0)
enc1 = encoder.attach(pio.GPIO36, pio.GPIO38, 0, callback1)
enc2 = encoder.attach(pio.GPIO35, pio.GPIO34, 0, callback2)
--]]




--[[
s = sensor.attach("REL_ROT_ENCODER", pio.GPIO39, pio.GPIO37, pio.GPIO0)

-- Register a callback. Callback is executed when some sensor property changes.
s:callback(
   function(data)
      if (data.dir == -1) then
         print("ccw, value "..data.val)
      elseif (data.dir == 1) then
         print("cw, value "..data.val)
      end

      if (data.sw == 1) then
         print("sw on")
      elseif (data.sw == 0) then
         print("sw off")
      end
   end
)
--]]
