local M = {}

local omni=require('omni')
local apds = assert(require('apds9960'))
local laser_ring = require('laser_ring')
local led_ring = require'led_ring'(pio.GPIO19, 24, 50)

M.omni = omni
M.color = apds.color
M.height = apds.proximity
M.laser_ring = laser_ring
M.led_ring = led_ring

M.init = function()

  assert(apds.init())
  assert(apds.proximity.enable())

  laser_ring.init()  --init(true)
  laser_ring.cb_list.add( laser_ring.get_reading_cb() )

  omni.set_enable()

end


return M