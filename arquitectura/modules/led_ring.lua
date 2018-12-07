--- LED ring.
-- Configuration is loaded using `nvs.read("led_ring", parameter)` calls, where the
-- available parameters are:  
--  
--* `"power"` max power to use, in the 0..255 range. Defaults to 20
--
-- @module led_ring
-- @alias M
local M = {}

--- Number of LEDs in ring.
M.n_leds = 24

local ledpin = pio.GPIO19
local first_led = {8, 4, 0, 20, 16, 12}
local segment_length  -- setup in M.set_power

local neo = neopixel.attach(neopixel.WS2812B, ledpin, M.n_leds)

local colors  -- setup in M.set_power

M.set_color_table = function (c, f)
  colors = c
  first_led = f or first_led
  segment_length = (M.n_leds // #colors) - 2
end

--- Set maximum power
--@param power In the 0..255 range
M.set_power = function( power )
  local c = {
    {power, 0, 0},
    {0, power, 0},
    {0, 0, power},
    {power//2, power//2, 0},
    {0, power//2, power//2},
    {power//2, 0, power//2},
  }
  M.set_color_table(c)
end

--- Sets all pixels.
--  This call is not limited by the power settings.
-- @param r red value in the 0..255 range. Defaults to 0.
-- @param g green value in the 0..255 range. Defaults to 0.
-- @param b blue value in the 0..255 range. Defaults to 0.
M.clear = function (r, g, b)
  r = r or 0
  g = g or 0
  b = b or 0
  for i=0, M.n_leds-1 do
    neo:setPixel(i, r, g, b)
  end
  neo:update()
end

--- Sets a LED to a specified color.
-- The values will not be applied until @{update} is called. This call
-- is not limited by the power settings.
-- @param led Index in the 1..24 range
-- @param r red value in the 0..255 range. Defaults to 0.
-- @param g green value in the 0..255 range. Defaults to 0.
-- @param b blue value in the 0..255 range. Defaults to 0.
M.set_led = function (led, r, g, b)
  r = r or 0
  g = g or 0
  b = b or 0
  neo:setPixel(led-1, r, g, b)
  --neo:update()
end

--- Controls a segment.
-- The 6 segment have a predefined color assigned.
--@param segment Index in the 1..6 range.
--@param enable true value to enable, false to disable.
M.set_segment = function (segment, enable)
  local first = first_led[segment]
  local r, g, b = 0, 0, 0
  if enable then
    local color = colors[segment]
    r, g, b = color[1], color[2], color[3]
  end
  for i = first, first + segment_length-1 do
    local ind = i % 24
    neo:setPixel(ind, r, g, b)
  end
  neo:update()
end

--- Controls a segment.
-- The 6 segments can be assigned a color.
-- @param segment Index in the 1..6 range.
-- @param r red value in the 0..255 range. Defaults to 0.
-- @param g green value in the 0..255 range. Defaults to 0.
-- @param b blue value in the 0..255 range. Defaults to 0.
M.set_segment_rgb = function (segment, r, g, b)
  local first = first_led[segment]
  for i = first, first + segment_length-1 do
    local ind = i % 24
    neo:setPixel(ind, r, g, b)
  end
  neo:update()
end

--- Sends the pixel data to the device.
-- This is to be used with  @{set_led}.
M.update = function ()
  neo:update()
end

M.set_power( nvs.read("led_ring","power", 20)

return M
