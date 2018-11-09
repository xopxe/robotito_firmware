local M = {}

M.get_list = function ()
  local cbs = { n = 0 }
  cbs.append = function (cbs, cb)
    cbs[#cbs+1] = cb
    cbs.n = #cbs
  end
  cbs.remove = function (cbs, cb)
    for i = 1, #cbs do 
      if cbs[i] == cb then table.remove(cbs, i) end
    end
    cbs.n = #cbs
  end
  cbs.call = function (...)
    for i = 1, cbs.n do 
      cbs[i](...)
    end
  end
  setmetatable (cbs, { __call = cbs.call })
  return cbs
end

return M