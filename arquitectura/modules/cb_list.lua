--- List of functions to be used as callback.
-- When you have an API that offers a callback, but it must
-- be used from many places. You register this as callback,
-- and then anyone can add itself to the list of callees.
-- @module cb_list
-- @usage local cb_list = require'cb_list'.get_list() --list of callbacks for readings
-- some_lib.some_register_callback(cb_list.call)
-- cb_list.append( function() print "call!" end )
-- @alias M

local M = {}

M.get_list = function ()
  local cbs = { n = 0 }
  --- Append a function to the list of callbacks.
  -- The function will be called with the parameters provided to the callback. 
  -- @param cb a function to be called.
  cbs.append = function (cb)
    cbs[#cbs+1] = cb
    cbs.n = #cbs
  end
  --- Remove a function from the list of callbacks.
  -- The function will be called with the parameters provided to the callback. 
  -- @param cb the function to be removed.
  cbs.remove = function (cb)
    for i = 1, #cbs do 
      if cbs[i] == cb then table.remove(cbs, i) end
    end
    cbs.n = #cbs
  end
  --- The function to passed to the API requesting a callback function.
  -- Invoking this function will call all the functions registered using @{append}
  -- @param ... parameters will be passed to each function. Returns will be ignored.
  cbs.call = function (...)
    for i = 1, cbs.n do 
      cbs[i](...)
    end
  end
  --setmetatable (cbs, { __call = cbs.call })
  return cbs
end

return M