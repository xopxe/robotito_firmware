--- Test ahsm state machine.
-- On and Off states, controlled by the floor proximity sensor.
-- When On, there's a led semaphor cycling trough colors.

robot = require 'robot'
local ahsm = require 'ahsm'
ahsm.get_time = os.gettime

local debugger = require 'debug_plain'
ahsm.debug = debugger.out

local hsm

-- root state, embeds On/Off machine and initialization code
local root = require 'states.test'

-- start machine
hsm = ahsm.init( root ) 
robot.hsm = hsm

-- We must keep looping for reacting to state timeouts
thread.start( function()
    while true do 
      hsm.loop()
      tmr.sleepms(10)
    end
  end)
