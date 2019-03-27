--- Use color patches to select movement direction.
-- The robot will move in the direction indicated by the led lights when 
-- detects a color patch on the floor of the same color. If you pick the
-- robot up it powers down.  
--  
-- This is a state machine to be run using @{main_ahsm}. For this set
-- `nvs.write("ahsm", "root", "states.colorway")` and then run `dofile'main_ahsm.lua'`, 
-- or simply set `nvs.write("autorun", "main", "main_ahsm.lua")` for autorun.
-- @hsm colorway.lua

-- color events
local e_color = {
  ['yellow'] = {vel = 0.1, dir = 0.0},
  ['blue'] = {vel = 0.1, dir = math.pi},
  ['green'] = {vel = 0.1, dir = math.pi/2},
  ['red'] = {vel = 0.1, dir = 3*math.pi/2},
}

local ahsm = require 'ahsm'
local color = require('color')
local ledr = require 'led_ring'

local onoff = require 'states.onoff'

--preproccess events
for c, e in pairs(e_color) do
  local rgb = color.color_rgb[c]
  e.r, e.g, e.b = rgb[1], rgb[2], rgb[3]
  e.x = e.vel*math.cos(e.dir)
  e.y = e.vel*math.sin(e.dir)
  e.led = math.floor(ledr.n_leds*e.dir/(2*math.pi))
  e._name = "e_"..c
end

local produce_color_event = function(name)
  robot.hsm.queue_event(e_color[name])
end

local s_main = ahsm.state {
}
local transitions = {}
for c, e in pairs(e_color) do
  local t_change = ahsm.transition {
    src = s_main, tgt = s_main,
    events = {e},
    effect = function (ev)
      --print ('!', c, ev.x, ev.y, ev.r, ev.g, ev.b)
      robot.omni.drive(ev.x, ev.y, 0.0)
      ledr.set_all(0, 0, 0)
      for ci, e in pairs(e_color) do
        --print ('ARC', c, e.led, e.r, e.g, e.b)
        if ci == c then
          ledr.set_arc(e.led-2, 5, e.r, e.g, e.b)
        else
          ledr.set_arc(e.led, 1, e.r, e.g, e.b)
        end
      end
      ledr.update()
    end
  }
  transitions['t_'..c] = t_change
end
local s_on = onoff.states.ON
local s_off = onoff.states.OFF

local function paint_leds_empty ()
  ledr.set_all(0, 0, 0)
  for c, e in pairs(e_color) do
    --print ('ARC', c, e.led, e.r, e.g, e.b)
    ledr.set_arc(e.led, 1, e.r, e.g, e.b)
  end
  ledr.update()
end

s_off.entry = function ()
  paint_leds_empty()
end

s_on.entry = function ()
  paint_leds_empty()
  robot.omni.drive(0, 0, 0.0)
  robot.omni.enable(true)
  color.color_cb.append(produce_color_event)
  color.enable(true) -- only enable (no dis. because it could be used by others)
end
s_on.exit = function ()
  robot.omni.enable(false)
  color.enable(false)
  color.color_cb.remove(produce_color_event)
end
s_on.states = { s_main }
s_on.transitions = transitions
s_on.initial = s_main

return onoff