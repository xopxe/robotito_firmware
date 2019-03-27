-- dofile('test_omni_rotar.lua')
m=m or require('omni')

local MAX_ITER = 4
local d=1000
local w = 0.4   --m/s

m.set_enable()

for i=1,MAX_ITER do
  m.drive(0,0,w)
  tmr.sleepms(d)
  m.drive(0,0,-w)
  tmr.sleepms(d)
end

m.set_enable(false)

--m.set_enable();m.raw_write(0,0,45);tmr.sleepms(2000);m.set_enable(false)
