local rfsm = require("rfsm")
-- require("fsmdbg")

local omni=require('omni')

local apds = assert(require('apds9960'))

local ms = 100

local min_sat = 50
local min_val = 20
local max_val = 200

local colors = {
  {"red", 0, 60},
  {"yellow", 60, 120},
  {"green", 120, 180},
  {"cyan", 180, 240},
  {"blue", 240, 300},
  {"magenta", 300, 360},
}

assert(apds.init())

local color = apds.color
assert(color.set_color_table(colors))
assert(color.set_sv_limits(min_sat,min_val,max_val))
assert(color.enable())

local last_color = "none"

local W_ROTATE = 0.008

local enable_motors = function()
  omni.set_enable()
  omni.drive(0,0,W_ROTATE)
end

local disable_motors = function()
  omni.drive(0,0,0)
  omni.set_enable(false)
end

local cur_wdot = W_ROTATE

local simple_templ = rfsm.csta:new{
   idle_hook=function () os.execute("sleep 0.1") end,

   color_st = rfsm.sista:new{},

   rfsm.trans:new{ src='color_st', tgt='color_st', events={ 'red' }, effect=function () cur_wdot = cur_wdot + 0.01; omni.drive(0,0,cur_wdot); print("r:" , cur_wdot) end },
   rfsm.trans:new{ src='color_st', tgt='color_st', events={ 'green' }, effect=function () cur_wdot = cur_wdot - 0.01; omni.drive(0,0,cur_wdot); print("g:" , cur_wdot) end },
   rfsm.trans:new{ src='initial', tgt='color_st', effect = enable_motors}
}

local fsm = rfsm.init(simple_templ, "simple_test")

-- callback for get_change
-- will be called with (color, s, v)
-- color: one of "red", "yellow", "green", "cyan", "blue", "magenta"
-- s,v: 0..255
local dump_color_change = function(c, s, v)
  rfsm.send_events(fsm, c)
  last_color = c
end

-- enable color change monitoring, enable hsv mode
color.get_change(ms, dump_color_change)

-- local rfsm2uml = require("rfsm2uml")
-- rfsm2uml.rfsm2uml(fsm, 'png', "fsm.png", "Figure caption")

--power on led
local led_pin = pio.GPIO32
pio.pin.setdir(pio.OUTPUT, led_pin)
pio.pin.sethigh(led_pin)

-- local b = true
while 1 do
--   dump_dist(b)
--   b = not b
  idle = rfsm.step(fsm, 10)
  tmr.sleepms(100)
  print(cur_wdot)
end

-- rfsm.run()
