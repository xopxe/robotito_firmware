local ahsm = require("ahsm")
local robot = require("robot")

local fsm



--[[
rfsm_timeevent.set_gettime_hook(function()
  return  os.gettime(true)
end)
--]]

local ROTATION_SPEED = 0.008
local w_rotate = 0

local set_w = function(w)
  w_rotate = w
  robot.omni.drive(0,0,w_rotate)
end

local invert_w = function()
  w_rotate = -w_rotate
  robot.omni.drive(0,0,w_rotate)
end

local TIMEOUT_LIMIT = 1.5
local TIMEOUT_INC = 0.25
local TIMEOUT_INIT = 0.25


local last_min = 9000
local DELTA = 5

local TIMEOUT_SEARCH_60 = 3

local event_mt = {__tostring =function(v) return v.name end}
local e_no_object = {name="e_no_object"}
setmetatable(e_no_object, event_mt)
local e_object = {name="e_object"}
setmetatable(e_object, event_mt)
local e_min_found = {name="e_min_found"}
setmetatable(e_min_found, event_mt)
local e_to_buscar = {name="e_to_buscar"}
setmetatable(e_to_buscar, event_mt)
local e_continue_panning = {name="e_continue_panning"}
setmetatable(e_continue_panning, event_mt)
local e_end_object = {name="e_end_object"}
setmetatable(e_end_object, event_mt)


local t_init_to_izq_no_obj 
local t_izq_no_to_der
local t_to_der
local t_to_der_2
local t_der_no_to_izq
local t_to_izq
local t_to_izq_2
local t_izq_no_to_stop
local t_der_no_to_stop
local t_buscar_min_to_ajuste
local t_ajuste_to_going
--[[


local t_izq_no_to_buscar_min
local t_der_no_to_buscar_min




--]]


local init_s = ahsm.state{entry=function() t_izq_no_to_der.timeout = TIMEOUT_INIT; end,}
local izq_no_obj_s = ahsm.state{entry=function() set_w(ROTATION_SPEED) end,}
local der_no_obj_s = ahsm.state{entry=invert_w,}

local izq_to_der_s = ahsm.state{doo=function()
    if (robot.background.dist_align > 0) then
      robot.fsm.send_event(e_to_buscar)
    else
      robot.fsm.send_event(e_continue_panning)
    end
    return true
  end}

local der_to_izq_s = ahsm.state{doo=function()
    if (robot.background.dist_align > 0) then
      robot.fsm.send_event(e_to_buscar)
    else
      robot.fsm.send_event(e_continue_panning)
    end
    return true
  end}

local buscar_min_s = ahsm.state{
  entry = function() last_min = 9000 end,
  doo=function()
    if ((robot.background.dist_align ~= 0) and (robot.background.dist_align < last_min)) then
      last_min = robot.background.dist_align
    end
    return true
  end
}

local stop_s = ahsm.state{entry=function()
    set_w(0.0); robot.led_ring.print_message(1); print("STOP, OBJECT NOT FOUND")
  end,}

local ajuste_s = ahsm.state{entry=invert_w,
    doo=function()
    if ((robot.background.dist_align <= last_min + DELTA) and (robot.background.dist_align >= DELTA)) then
      robot.fsm.send_event(e_min_found)
      set_w(0,0)
    end
    return true
  end}--invert_w();

local going_s = ahsm.state{entry=function()
    print("GOING TO OBJECT")
    set_w(0.0)
    --[[
    if (e_background.direction ~= 0)then
      compute_velocity()
      robot.omni.drive(xdot,ydot,curr_w)
    end
    --]]
  end,}



t_init_to_izq_no_obj = ahsm.transition{
  src= init_s,
  tgt= izq_no_obj_s,
  events={ e_no_object },
}

t_izq_no_to_der = ahsm.transition{
  src= izq_no_obj_s,
  tgt= izq_to_der_s,
  events={},
  timeout = TIMEOUT_INIT,
}

t_to_der = ahsm.transition{
  src= izq_to_der_s,
  tgt= buscar_min_s,
  events={e_to_buscar},
}

t_to_der_2 = ahsm.transition{
  src= izq_to_der_s,
  tgt= der_no_obj_s,
  events={e_continue_panning},
  effect = function()t_der_no_to_izq.timeout = t_izq_no_to_der.timeout + TIMEOUT_INC end,
}

t_der_no_to_izq = ahsm.transition{
  src= der_no_obj_s,
  tgt= der_to_izq_s,
  events={},
  timeout = TIMEOUT_INIT,
}

t_to_izq = ahsm.transition{
  src= der_to_izq_s,
  tgt= buscar_min_s,
  events={e_to_buscar},
}

t_to_izq_2 = ahsm.transition{
  src= der_to_izq_s,
  tgt= izq_no_obj_s,
  events={e_continue_panning},
  effect = function()t_izq_no_to_der.timeout = t_der_no_to_izq.timeout + TIMEOUT_INC end,
}

t_izq_no_to_stop = ahsm.transition{
  src= izq_no_obj_s,
  tgt= stop_s,
  events={izq_no_obj_s.EV_DONE},
  guard = function() return (t_izq_no_to_der.timeout > TIMEOUT_LIMIT) end,
}

t_der_no_to_stop = ahsm.transition{
  src= der_no_obj_s,
  tgt= stop_s,
  events={der_no_obj_s.EV_DONE},
  guard = function() return (t_izq_no_to_der.timeout > TIMEOUT_LIMIT) end,
}

t_buscar_min_to_ajuste = ahsm.transition{
  src= buscar_min_s,
  tgt= ajuste_s,
  events={e_end_object},
}

t_ajuste_to_going = ahsm.transition{
  src= ajuste_s,
  tgt= going_s,
  events={e_min_found},
}

fsm = ahsm.state {
  events = {EV_NO_OBJECT = e_no_object,
    EV_OBJECT = e_object,
    EV_MIN_FOUND = e_min_found,
    EV_CONT_PAN = e_continue_panning,
    EV_TO_SEARCH = e_to_buscar,
    EV_END_OBJECT = e_end_object},
  states = {  init = init_s,
    izq_no_obj = izq_no_obj_s,
    der_no_obj = der_no_obj_s,
    izq_to_der = izq_to_der_s,
    der_to_izq = der_to_izq_s,
    stop = stop_s,
    buscar_min = buscar_min_s,
    ajuste = ajuste_s,
    going = going_s},
  transitions = { 
    t_init_to_izq_no_obj,
    t_izq_no_to_der,
    t_to_der,
    t_to_der_2,
    t_to_izq,
    t_to_izq_2,
    t_der_no_to_izq,
    t_izq_no_to_stop,
    t_der_no_to_stop,
    t_buscar_min_to_ajuste,
    t_ajuste_to_going
    --[[
    
    t_der_no_to_buscar_min,
    t_izq_no_to_buscar_min,
    
    

    

    --]]
  },
  initial = init_s,
}

return fsm
