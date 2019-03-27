--- LED ring.
-- All drawing is made to a buffer, and sent to the device with the @{update}
-- call. Also, many drawing functions have an `update` parameter that triggers
-- an immediate update.  
-- Configuration is loaded using `nvs.read("led_ring", parameter)` calls, where the
-- available parameters are:  
--  
--* `"power"` max power to use, in the 0..100% range. Defaults to 20. Also can 
-- be changed at runtime calling @{set_power}
--
-- @module led_ring
-- @alias M
local M = {}

--- Number of LEDs in ring.
M.n_leds = 24

local max_power = 100

local function led_to_index (i)
  if i<16 then 
    return 15-i
  else
    return 39-i
  end
end

local function pow_to_byte (r, g, b)
  r = (r and r * 255 // 100) or 0
  g = (g and g * 255 // 100) or 0
  b = (b and b * 255 // 100) or 0
  return r, g, b
end




local ledpin = pio.GPIO19
local segment_length  -- setup in M.set_power

local neo = neopixel.attach(neopixel.WS2812B, ledpin, M.n_leds)

local colors  -- setup in M.set_power

--- Set maximum power
--@tparam integer power In the 0..100% range
M.set_power = function( power )
  colors = {
    {power, 0, 0},
    {power//2, power//2, 0},
    {0, power, 0},
    {0, power//2, power//2},
    {0, 0, power},
    {power//2, 0, power//2},
  }
  segment_length = (M.n_leds // #colors)
  max_power = power
end

--- Sets a LED to a specified color.
-- @param led Index in the 1..24 range
-- @tparam[opt=0] integer r red value in the 0..100% range.
-- @tparam[opt=0] integer g green value in the 0..100% range.
-- @tparam[opt=0] integer b blue value in the 0..100% range.
-- @tparam[opt=false] boolean update writes the buffer to the device
M.set_led = function (led, r, g, b, update)
  r, g, b = pow_to_byte(r, g, b)
  neo:setPixel(led_to_index(led), r, g, b)
  if update then neo:update() end
end

--- Controls a segment.
-- The 6 segments can be assigned a color.
-- @param segment Index in the 1..6 range.
-- @tparam[opt=0] ?integer|boolean r red value in the 0..100% range.
-- If r is true then a  predefined r,g,b color will be used. If false, the
-- segment will be switched off.
-- @tparam[opt=0] integer g green value in the 0..100% range.
-- @tparam[opt=0] integer b blue value in the 0..100% range.
-- @tparam[opt=false] boolean update writes the buffer to the device
M.set_segment = function (segment, r, g, b, update)
  if r==true then 
    local color = colors[segment]
    r, g, b = color[1], color[2], color[3]
  elseif r==false then
    r, g, b = 0, 0, 0
  end
  M.set_arc((segment-1)*segment_length+1, segment_length, r, g, b, update)
end

--- Controls an arc.
-- Paint a set of consecutive leds.
-- @tparam integer led Index in the 1..24 range.
-- @tparam integer length number of consecutive leds to paint -24..24 range.
-- @tparam[opt=0] integer r red value in the 0..100% range.
-- @tparam[opt=0] integer g green value in the 0..100% range.
-- @tparam[opt=0] integer b blue value in the 0..100% range.
-- @tparam[opt=false] boolean update writes the buffer to the device
M.set_arc = function (led, length, r, g, b, update)
  r, g, b = pow_to_byte(r, g, b)
  local pos = led_to_index(led)
  local first, final
  if length>0 then
    first, final = pos-length+1, pos
  else
    first, final = pos, pos-length-1
  end
  for i = first, final do
    neo:setPixel(i % 24, r, g, b)
  end
  if update then neo:update() end
end

--- Sets all pixels.
-- @tparam[opt=0] integer r red value in the 0..100% range.
-- @tparam[opt=0] integer g green value in the 0..100% range.
-- @tparam[opt=0] integer b blue value in the 0..100% range.
-- @tparam[opt=false] boolean update writes the buffer to the device
M.set_all = function (r, g, b, update)
  r = r or 0
  g = g or 0
  b = b or 0
  for i=0, M.n_leds-1 do
    neo:setPixel(i, r, g, b)
  end
  if update then neo:update() end
end

--- Clear all pixels.
-- Powers down all the pixels.
M.clear = function ()
  M.set_all(0, 0, 0, true)
end

--- Sends the pixel buffer to the device.
M.update = function()
  neo:update()
end

M.set_power( nvs.read("led_ring","power", 20) or 20 )

return M
