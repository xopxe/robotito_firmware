if not nvs.read("robot", "behavior") then 
  dofile("init_params_nvs.lua")
end

net.wf.setup(
  net.wf.mode.AP,
--  "manuela",
  nvs.read("wifi","ssid"),
  nvs.read("wifi","passwd"),
  --net.packip(192,168,2,1), net.packip(255,255,255,0),
  -- net.wf.powersave.MODEM
  net.wf.powersave.NONE, -- default
  nvs.read("wifi","channel") -- channel
)

net.wf.start()

--net.stat()

-- dofile("remote-driver.lua")

dofile(nvs.read("robot", "behavior"))

-- dofile("echosrvr.lua")
