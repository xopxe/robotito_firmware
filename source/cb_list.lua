--- List of functions to be used as callback.
-- When you have an API that offers a callback, but it must
-- be used from many places. You register this as callback,
-- and then anyone can add itself to the list of callees.
-- @module cb_list
-- @usage local cb_list = require'cb_list'.get_list()
-- some_lib.some_register_callback(cb_list.call)
-- cb_list.append( function() print "call!" end )
-- @alias M

local M = {}

M.get_list = function ()
  local cb = { n = 0 }
  --- Append a function to the list of callbacks.
  -- The function will be called with the parameters provided to the callback. 
  -- @tparam function f a function to be called.
  cb.append = function (f)
    cb[#cb+1] = f
    cb.n = #cb
  end
  --- Remove a function from the list of callbacks.
  -- The function will be called with the parameters provided to the callback. 
  -- @tparam function f the function to be removed.
  cb.remove = function (f)
    for i = 1, #cb do 
      if cb[i] == f then table.remove(cb, i) end
    end
    cb.n = #cb
  end
  --- The function to be passed to the API requesting a callback function.
  -- Invoking this function will call all the functions registered using @{append}
  -- @param ... parameters will be passed to each function. Returns will be ignored.
  cb.call = function (...)
    for i = 1, cb.n do 
      cb[i](...)
    end
  end
  --setmetatable (cbs, { __call = cbs.call })
  return cb
end

return M