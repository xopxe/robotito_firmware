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

local vel_nvs = nvs.read("color", "max_vel", 0.1) or 0.1

local e_color = {
  ['yellow'] = {vel = vel_nvs/2, dir = 0.0},
  ['blue'] = {vel = vel_nvs/2, dir = math.pi},
  ['green'] = {vel = vel_nvs/2, dir = math.pi/2},
  ['red'] = {vel = vel_nvs/2, dir = 3*math.pi/2},
  ['magenta'] = {vel = vel_nvs*5},
}


local ahsm = require 'ahsm'
local color = require('color')
local ledr = require 'led_ring'

--preproccess events
for c, e in pairs(e_color) do
  local rgb = color.color_rgb[c]
  e.r, e.g, e.b = rgb[1], rgb[2], rgb[3]
  if (e.dir == nil) then
    e.x = 0.0
    e.y = 0.0
    e.w = e.vel
  else
    e.x = e.vel*math.cos(e.dir)
    e.y = e.vel*math.sin(e.dir)
    e.w = 0.0
    e.led = math.floor(ledr.n_leds*e.dir/(2*math.pi))
  end
  e._name = "e_"..c
end

local produce_color_event = function(name)
  robot.hsm.queue_event(e_color[name])
end

local s_main = ahsm.state {
}

local function paint_leds_empty ()
  ledr.set_all(0, 0, 0)
  for c, e in pairs(e_color) do
    if (e.dir ~= nil) then
      ledr.set_arc(e.led, 1, e.r, e.g, e.b)
    end
    --print ('ARC', c, e.led, e.r, e.g, e.b)
  end
  ledr.update()
end

local transitions_color = {}
for c, e in pairs(e_color) do
  local t_change = ahsm.transition {
    src = s_main, tgt = s_main,
    events = {e},
    effect = function (ev)
      --print ('!', c, ev.x, ev.y, ev.r, ev.g, ev.b)
      robot.omni.drive(ev.x, ev.y, ev.w)
      paint_leds_empty()
      if (e.dir == nil) then
        ledr.set_all( e.r, e.g, e.b)
      else
        ledr.set_arc(e.led-2, 5, e.r, e.g, e.b)
      end
      ledr.update()
    end
  }
  transitions_color['t_'..c] = t_change
end

local s_color = ahsm.state {
  events =  e_color,
  states = { COLOR=s_main },
  transitions = transitions_color,
  initial = s_main,
  entry = function ()
    ledr.clear()
    robot.omni.drive(0, 0, 0)
    paint_leds_empty()
    color.color_cb.append(produce_color_event)
    s_color.enable(true) -- only enable (no dis. because it could be used by others)
  end,
  exit = function ()
    ledr.clear()
    robot.omni.drive(0, 0, 0)
    s_color.enable(false)
    color.color_cb.remove(produce_color_event)
  end,
}

return s_color
