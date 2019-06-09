
local M = {}

M.out = function(string)
  sens_str = "state*" .. string
  robot.wifi_net.broadcast(sens_str)
end


return M
