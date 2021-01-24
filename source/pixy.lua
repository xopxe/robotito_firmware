--- Pixy2 camera module.
-- Configuration is loaded using `nvs.read("pixy", parameter)` calls, where the
-- available parameters are:
--
--* `"block_period"` The blocks time step in ms, defaults to 50.
--* `"line_period"` The lines time step in ms, defaults to 50.
--* `"vector_active"` enables vector detecton, defaults to `true`.
--* `"intersects_active"` enables intersection detecton, defaults to `true`.
--* `"bars_active"` enables barcode detecton, defaults to `true`.
--
-- @module pixy
-- @alias M
local M = {}

local pixy = assert(require 'pixy2')

--- The native C firmware module.
-- This can be used to access low level functionality from `pixy2`. FIXME: docs 
M.device = pixy

--- The callback the contiguous color block detection.
-- This is a callback list attached to the camera sensor, see @{cb_list}.
-- The callback will be called with an array of detected blocks, where each block
-- is a table with the following fields:
--
-- * `x`: the x location of the center of the block. The value ranges between 0 and frameWidth (315). 
-- * `y`: the y location of the center of the block. The value ranges between 0 and frameHeight (207)
-- * `width`: the width of the block. The value ranges between 0 and frameWidth (316)
-- * `height`: the height of the block. The value ranges between 0 and frameHeight (208) 
-- * `angle`: the angle of color-code in degrees. The value ranges between -180 and 180. If the block is a regular signature (not a color-code), the angle value will be 0
-- * `index`: the tracking index of the block. When Pixy2 detects a new block, it will add it to a table of blocks that it is currently tracking and assign it a tracking index. It will then attempt to find the block (and every block in the table) in the next frame by finding its best match. Each block index will be kept for that block until it either leaves Pixy2's field-of-view, or Pixy2 can no longer find the object in subsequent frames (because of occlusion, lack of lighting, etc.)
-- * `age`: the number of frames a given block has been tracked. When the age reaches 255, it remains at 255
--
-- @usage local local pixy = require'pixy'
-- pixy.line_cb.append( function (blocks) print(#(blocks or {})) end )
-- pixy.enable(true)
M.block_cb = require'cb_list'.get_list()
pixy.ccc.set_blocks_callback(M.block_cb.call)

--- The callback the line feature detection.
-- This is a callback list attached to the camera sensor, see @{cb_list}.
-- The callback will be called with three parameters `(vector, intersects, bars)`. If the detection for some category is disabled through `nvs` parameters, the return is `nil`.
-- The `vector` is the detected main vector (might be `nil` if none detected). When found is a table with the following fields:
--
-- * `x0, x1`: x locations of tail and head (arrow end)  of the Vector or line. The value ranges between 0 and frameHeight (79)
-- * `y0, y1`: y locations of tail and head (arrow end)  of the Vector or line. The value ranges between 0 and frameWidth (52). 
-- * `index`: the tracking index of the Vector. When Pixy2 detects a new line, it will add it to a table of lines that it is currently tracking. It will then attempt to find the line (and every line in the table) in the next frame by finding its best match. Each line index will be kept for that line until the line either leaves Pixy2's field-of-view, or Pixy2 can no longer find the line in subsequent frames (because of occlusion, lack of lighting, etc.) 
--
-- The `intersects` parameter is an array with the intersections on the vector. Each intersection is a table with the following fields:
--
-- * `x, y`: coordinates of the intersection. The range is 0..79, 0..52
-- * `int_lines`: an array with lines on the intersection, where each line is a table with a tracking `index` and and `angle` fields.
--
-- The `bars` parameter is an array with the detected barcodes. Each detected barcode is a table with the following fieds:
--
-- * `x,y`: coordinates of the barcode. The range is 0..79, 0..52
-- * `code`: value of the code. The range is 0..15
--
-- @usage local local pixy = require'pixy'
-- pixy.line_cb.append( function (vector, intersects, bars) 
--   print( #(bars or {}) ) 
-- end )
-- pixy.enable(true)
M.line_cb = require'cb_list'.get_list()
pixy.line.set_lines_callback(M.line_cb.call)

local enables = 0

--- Enables the callbacks.
-- When enabled, the driver will trigger @{block_cb} and @{line_cb}.  
-- To correctly handle multiple users of the module, please balance enables and 
-- disables: if you enable, disable when you stop neededing it.
-- @tparam boolean on true value to enable, false value to disable.
-- @tparam[opt=50] integer block_period Sampling period in ms for the block detection, 
-- if omitted is read from `nvs.read("pixy","block_period")`.
-- @tparam[opt=50] integer line_period Sampling period in ms for the line detection, 
-- if omitted is read from `nvs.read("pixy","line_period")`.
M.enable = function (on, block_period, line_period)
  if on and enables==0 then
    block_period = block_period or nvs.read("pixy","block_step", 50)
    line_period = line_period or nvs.read("pixy","line_step", 50)
    pixy.ccc.enable(block_period)
    pixy.line.enable(
      line_period, 
      nvs.read("pixy","vector_active", true), 
      nvs.read("pixy","intersects_active", true), 
      nvs.read("pixy","bars_active", true)
    )
  elseif not on and enables==1 then
    pixy.ccc.enable(false)
    pixy.line.enable(false)
  end
  if on then
    enables=enables+1
  elseif enables>0 then
    enables=enables-1
  end
end

return M