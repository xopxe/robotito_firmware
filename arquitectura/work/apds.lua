local M = {}

local height_period = 50 -- period of distance measurements
local height_threshold = 250
local height_histeresis = 3

M.omni = nil

M.apds = assert(require('apds9960'))

local proximity_cb_list = require'cb_list'.get_list()

M.proximity_cb_list = proximity_cb_list --list of callbacks for distance sensor

M.color_cb_list = require'cb_list'.get_list --list of callbacks for color sensor

M.cw_dist = function(b)
  if b then
    M.omni.drive(0,0,2)
  else
    M.omni.drive(0,0,0)
  end
end

M.init = function()
  assert(M.apds.init())
  assert(M.apds.proximity.enable())
  M.apds.proximity.get_dist_thresh(height_period, height_threshold, height_histeresis, proximity_cb_list.call)
end

return M