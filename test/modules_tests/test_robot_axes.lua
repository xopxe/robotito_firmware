-- dofile('test_robot_axes.lua')

local omni=require('omni')

local vel = 0.1

omni.set_enable()
omni.drive(vel,0,0)

tmr.sleepms(3*1000)
