--dofile('test_encoders.lua')

function callback0(dir, counter, button)
   print("0 direction: "..dir..", counter: "..counter..", button: "..button)
end
-- function callback1(dir, counter, button)
--    print("1 direction: "..dir..", counter: "..counter..", button: "..button)
-- end
-- function callback2(dir, counter, button)
--    print("2 direction: "..dir..", counter: "..counter..", button: "..button)
-- end

-- Attach an encoder with A=pio.GPIO26, B=pio.GPIO14, SW=pio.GPIO21.
-- Using a calback for get the encoder changes.
enc0 = encoder.attach(pio.GPIO39, pio.GPIO37, 0, callback0)
-- enc1 = encoder.attach(pio.GPIO38, pio.GPIO36, 0, callback1)
-- enc2 = encoder.attach(pio.GPIO34, pio.GPIO35, 0, callback2)





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
