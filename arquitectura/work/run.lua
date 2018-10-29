local ahsm = require 'ahsm'
ahsm.get_time = assert(os.gettime)
ahsm.debug = print

local robot = require 'robot'
robot.init()
robot.omni.set_enable()

-- get parameters
local filename = 'fsm_goto.lua'

-- load hsm
local root = assert(dofile(filename))
local hsm = ahsm.init( root )  -- create fsm from root composite state
robot.fsm = hsm

-- run hsm
repeat
  local next_t = hsm.loop()
until false --next_t
