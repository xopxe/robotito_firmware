project = "robotito firmware"
description = "microcontrolled robotic platform for research."
dir='doc/'
format = 'markdown'
new_type("hsm","State Machines", true)

file = {
  "source/robot.lua", 
  "source/omni.lua", 
  "source/color.lua",
  "source/proximity.lua",
  "source/laser_ring.lua", 
  "source/pixy.lua", 
  "source/led_ring.lua", 
  "source/cb_list.lua", 
  "source/wifi_net.lua", 
  "source/autorun.lua", 
  "source/main_ahsm.lua", 
  "source/tests/states/test.lua",
  "source/states/onoff.lua",
  "source/states/colorway.lua",
}
examples={
  "source/tests/test_color.lua", 
  "source/tests/test_proximity.lua", 
  "source/tests/test_laser_ring.lua",
  "source/tests/test_led_ring.lua",
  "source/tests/test_wifi.lua",
  "source/tests/test_omni.lua",
  "source/tests/test_ahsm.lua",
  "source/tests/calibrate_color.lua",
}
topics = {
  "README.md", 
	"nvs_parameters.md", 
}

