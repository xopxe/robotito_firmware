project = "robotito firmware"
description = "microcontrolled robotic platform for research."
dir='doc/'
format = 'markdown'

readme = "README.md"
file = {
    "arquitectura/modules/robot.lua", 
    "arquitectura/modules/apds.lua",
    "arquitectura/modules/laser_ring.lua", 
    "arquitectura/modules/omni.lua", 
    "arquitectura/modules/led_ring.lua", 
    "arquitectura/modules/cb_list.lua", 
}
examples={
    "test/modules_tests/test_color.lua", 
    "test/modules_tests/test_distc.lua", 
    "test/modules_tests/test_laser_ring.lua",
    "test/modules_tests/test_led_ring.lua",
}


