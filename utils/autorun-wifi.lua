net.wf.setup(
  net.wf.mode.AP,
--  "manuela",
  "robotito-5",
  "robotito",
  --net.packip(192,168,2,1), net.packip(255,255,255,0),
  net.wf.powersave.MODEM -- default net.wf.powersave.NONE
)

net.wf.start()

--net.stat()

-- dofile("remote-driver.lua")

dofile('robotito.lua')
-- dofile("echosrvr.lua")
