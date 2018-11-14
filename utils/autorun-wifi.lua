net.wf.setup(
  net.wf.mode.AP,
--  "manuela",
  "robotito-7",
  "robotito",
  --net.packip(192,168,2,1), net.packip(255,255,255,0),
  -- net.wf.powersave.MODEM
  net.wf.powersave.NONE, -- default
  7 -- channel
)

net.wf.start()

--net.stat()

-- dofile("remote-driver.lua")

dofile('robotito.lua')
-- dofile("echosrvr.lua")
