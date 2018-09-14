local M = {}

local omni=require('omni')
local apds = assert(require('apds9960'))
local laser_ring = require('laser_ring')


M.omni = omni
M.color = apds.color
M.height = apds.proximity
M.laser_ring = laser_ring

M.init = function()
  
  assert(apds.init())
  assert(apds.proximity.enable())
  laser_ring.init()
  omni.set_enable()
  
end


return M