--- LED ring.
-- @module led_ring
-- @alias M
local M = {}

local ledpin = pio.GPIO19
local n_leds = 24
local first_led = {8, 4, 0, 20, 16, 12}
local segment_length  -- setup in M.set_power

local neo = neopixel.attach(neopixel.WS2812B, ledpin, n_leds)

local colors  -- setup in M.set_power
local colors_message  -- setup in M.set_power

local glow_id = nil
local glow_power = 0
local glow_direction = 5
local glow_color = {1, 0, 0}

local turning_blink_state = false
local turning_blink_pixel = 0
local turning_blink_direction = 1
local turning_blink_color -- setup in M.set_power


M.set_color_table = function (c, f)
  colors = c
  first_led = f or first_led
  segment_length = (n_leds // #colors) - 2
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
  colors_message = {
    {power, 0, 0}, -- NO OBJECT
    {0, power, 0},
    {0, 0, power},
  }
  turning_blink_color = {power, 0, 0}
end

--- Switch off all pixels.
M.clear = function ()
  for i=0, n_leds-1 do
    neo:setPixel(i, 0, 0, 0)
  end
  neo:update()
end

--- Controls a segment.
-- The 6 segment have predefined color from colors table.
--@param segment Index in the 1..6 range.
--@enable true value to enable, false to disable.
M.set_segment = function (segment, enable)
  local first = first_led[segment]
  local r, g, b = 0, 0, 0
  if enable then
    r, g, b = colors[1], colors[2], colors[3]
  end
  for i = first, first + segment_length-1 do
    local ind = i % 24
    print ('>>>', ind, r, g, b)
    neo:setPixel(ind, r, g, b)
  end
  neo:update()
end

--- Controls a segment.
-- The 6 segments can be assigned a color.
--@param segment Index in the 1..6 range.
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

--- Sends the pixel data to the device.
-- This is to be used with  @{set_led}.
M.update = function ()
  neo:update()
end


M.print_message = function(color_num)
  local r, g, b = table.unpack(colors_message[color_num])
  for i = 1, n_leds do
    neo:setPixel(i-1, r, g, b)
  end
  neo:update()
  for i = 1 , 6 do
    M.set_segment(i, false)
  end
end

--- Initialization.
-- This configures the LED ring.
--@param power max power to use, in the 0..255 range. If nor provided, will 
--be read from `nvs.read("led_ring","power")`, defaults to 20.
M.init = function (power)
  M.set_power( power or nvs.read("led_ring","power", 20) or 20 )
end


return M
