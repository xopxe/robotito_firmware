--- Tool for calibrating the color sensor.
-- Start holding the robot in your hands (not on the floor).
-- This program will first shortly display all the colors that
-- will be calibrated (red, yellow, green, blue, and magenta).
-- Then it will display a color, and you will have to place the
-- robot over a patch of the same color. When a color is detected,
-- The robor will briefly flash the leds and display the next color.
-- Pick up the robot, and place it over the new patch. Repeat until
-- all colors are calibrated,
--
-- When all colors are calibrated, the programs ends. The
-- calibration data will be writen to nvs system (see @{color}).
-- The new calibration data will be used after reboot.
--
-- A practical way of using the clibrator is setting up as to runconce:
-- `nvs.write('autorun', 'runonce', 'calibrate_color.lua')
-- This will run the calibrator once after a reboot, and then resume
-- normal operation afer a subsequent reboot.

local hsv_stable_count = 5  --number of identical readings to claim a color
local colors = {'red','yellow','green','blue','magenta'}

local color = require('color')
local prox = require('proximity')
local ledr = require('led_ring')
local ahsm = require('ahsm')
ahsm.get_time = os.gettime
local debugger = require 'debug_plain'
--ahsm.debug = debugger.out

local SECURITY_V = 5

local hsm

local n_colors = #colors

for i=1, n_colors do
  local name = colors[i]
  local clr = {
    name = name,
    r = color.color_rgb[name][1],
    g = color.color_rgb[name][2],
    b = color.color_rgb[name][3],
  }
  colors[i] = clr
end

local function welcome ()
  print'We will calibrate the following colors:'
  for i=1, n_colors do
    local clr = colors[i]
    print (i, clr.name)
    ledr.set_arc((i-1)*n_colors+1, ledr.n_leds//n_colors, clr.r, clr.g, clr.b, true)
    tmr.delayms(200)
  end
  tmr.delayms(500)
end

local e_proximity = { _name="FLOOR" }
local e_stable = { _name="STABLE" }

-- callback for proximity sensor, emits events for state machine
local floor_event = function( v )
  if v then
    hsm.queue_event(e_proximity)
  end
end

local cr, cg, cb, ch, cs, cv
local hsv_count = 0 --number of equal h,s,v readings
local color_event = function(r, g, b, a, h, s, v)
  --print('rgba:', r, g, b, a, 'hsv:', h, s, v)
  if h==ch and s==cs and v==cv then
    hsv_count = hsv_count+1
    if hsv_count == hsv_stable_count then
      hsm.queue_event(e_stable)
    end
  else
    cr, cg, cb = r//255, g//255, b//255
    ch, cs, cv = h, s, v
    hsv_count = 0
  end
end

local function create_calibrator (clr)
  local e_calibrated = {}
  local s_wait_prox = ahsm.state {
    _name = 's_wait_prox',
    entry = function () print'wating for proximity...' end,
  }
  local s_wait_stable = ahsm.state {
    _name = 's_wait_stable',
    entry = function ()
      print'wating for stable color...'
    end,
  }
  local s_capture_calibration = ahsm.state {
    _name = 's_capture',
    entry = function ()
      if (cv < nvs.read('color','min_val',40)) then
        nvs.write('color','min_val', cv-SECURITY_V)
      end
      print ('capturing', clr.name, ch, cs, cv)
      nvs.write('color', clr.name..'_h', ch)
      nvs.write('color', clr.name..'_s', cs)
      nvs.write('color', clr.name..'_v', cv)
      print('CR:', cr)
      print('CG:', cg)
      print('CB:', cb)
      ledr.set_all(cr, cg, cb, true)
      tmr.delayms(500)
    end,
    doo = function ()
      hsm.queue_event(e_calibrated)
    end,
  }
  local t_proximity = ahsm.transition {
    src = s_wait_prox, tgt = s_wait_stable,
    events = {e_proximity},
  }
  local t_stable = ahsm.transition {
    src = s_wait_stable, tgt = s_capture_calibration,
    events = {e_stable},
  }
  local s_calibrator = ahsm.state {
    _name = 's_calib_'..clr.name,
    events = {calibrated = e_calibrated},
    entry = function ()
      print('calibrating color:', clr.name)
      ledr.set_all(clr.r, clr.g, clr.b, true)
    end,
    exit = function () print('done calibrating color:', clr.name) end,
    states = {s_wait_prox, s_wait_stable, s_capture_calibration},
    transitions = {t_proximity, t_stable},
    initial = s_wait_prox,
  }
  return s_calibrator
end


local states = {}
for i=1, n_colors do
  local s_calibrator = create_calibrator(colors[i])
  states[i] = s_calibrator
end
local transitions = {}
for i=1, n_colors-1 do
  local t_calibrator = ahsm.transition{
    _name = 't_to_'..colors[i+1].name,
    src = states[i], tgt = states[i+1],
    events = {states[i].events.calibrated}
  }
  transitions[i] = t_calibrator
end
states[#states+1] = ahsm.state {
  _name = 'calib_done',
  entry = function ()
    print 'Finished calibrating'
    ledr.clear()
    prox.enable(false)
    prox.cb.remove(floor_event)
    color.enable(false)
    color.rgb_cb.remove(color_event)
  end,
}
transitions[#transitions+1] = ahsm.transition {
  _name = 'finished',
  src = states[#states-1], tgt = states[#states],
  events = {states[#states-1].events.calibrated}
}

local s_root = ahsm.state {
  entry = function ()
    ledr.clear()
    welcome()
    prox.cb.append(floor_event)
    prox.enable(true)
    color.rgb_cb.append(color_event)
    color.enable(true)
  end,
  states = states,
  transitions = transitions,
  initial = states[1],
}


hsm = ahsm.init( s_root )
thread.start( function()
    while true do
      hsm.loop()
      tmr.sleepms(10)
    end
  end)
