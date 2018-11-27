--- LED ring.
-- @module led_ring
-- @alias M

local F = function ( ledpin, n_leds, pow )
  local M = {}

  M.power = pow or 20
  
  local colors = {
    {M.power, 0, 0},
    {0, M.power, 0},
    {0, 0, M.power},
    {M.power//2, M.power//2, 0},
    {0, M.power//2, M.power//2},
    {M.power//2, 0, M.power//2},
  }
  
  local colors_message = {
    {M.power, 0, 0}, -- NO OBJECT
    {0, M.power, 0},
    {0, 0, M.power},
  }
  
  local first_led = {8, 4, 0, 20, 16, 12}
  local segment_length = (n_leds // #colors) - 2

  local glow_id = nil
  local glow_power = 0
  local glow_direction = 5
  local glow_color = {1, 0, 0}

  local turning_blink_state = false
  local turning_blink_pixel = 0
  local turning_blink_direction = 1
  local turning_blink_color = {M.power, 0, 0}

  local neo = neopixel.attach(neopixel.WS2812B, ledpin, n_leds)

  M.set_color_table = function (c, f)
    colors = c
    first_led = f
    segment_length = (n_leds // #colors) - 2
  end

  M.clear = function ()
    for i=0, n_leds-1 do
      neo:setPixel(i, 0, 0, 0)
    end
    neo:update()
  end

  M.set_segment = function (segment, enable)
    local first = first_led[segment]
    local r, g, b = 0, 0, 0
    if enable then
      r, g, b = table.unpack(colors[segment])
    end
    for i = first, first + segment_length-1 do
      local ind = i % 24
      neo:setPixel(ind, r, g, b)
    end
    neo:update()
  end
  
  M.set_led = function (led, r, g, b, enable)
    if enable then
      neo:setPixel(led, r, g, b)
    else
      neo:setPixel(led, 0,0,0)
    end
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

  return M
end

return F