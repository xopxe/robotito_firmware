local robot_id = 0

-- NAMESPACES
local ROBOT = "robot"
local AUTORUN = "autorun"
local COLOR = "color"
local LASER = "laser"
local LED_RING = "led_ring"
local AHSM = "ahsm"
local OMNI = "omni"
local PROXIMITY = "proximity"
local WIFI = "wfi"

-- PARAMETERS
nvs.write(ROBOT,"id", robot_id)
nvs.write(AUTORUN,"runonce", nil)
nvs.write(AUTORUN,"main", "main_ahsm.lua")
nvs.write(COLOR,"min_sat", 24)
nvs.write(COLOR,"min_val", 40)
nvs.write(COLOR,"max_val", 270)
nvs.write(COLOR,"red_h", 348)
nvs.write(COLOR,"red_s", 170)
nvs.write(COLOR,"red_v", 135)
nvs.write(COLOR,"yellow_h", 70)
nvs.write(COLOR,"yellow_s", 226)
nvs.write(COLOR,"yellow_v", 228)
nvs.write(COLOR,"green_h", 181)
nvs.write(COLOR,"green_s", 250)
nvs.write(COLOR,"green_v", 175)
nvs.write(COLOR,"blue_h", 214)
nvs.write(COLOR,"blue_s", 312)
nvs.write(COLOR,"blue_v", 180)
nvs.write(COLOR,"magenta_h", 260)
nvs.write(COLOR,"magenta_s", 170)
nvs.write(COLOR,"magenta_v", 135)
nvs.write(COLOR,"gain", 1)
nvs.write(COLOR,"period", 100)
nvs.write(COLOR,"max_vel", 0.05)
nvs.write(LASER,"time_budget", 5000)
nvs.write(LASER,"dmin", 80)
nvs.write(LASER,"dmax", 600)
nvs.write(LASER,"period", 100)
nvs.write(LED_RING,"power", 20)
nvs.write(AHSM,"debugger", nil)
nvs.write(AHSM,"root", "onremoteoff")
nvs.write(AHSM,"timestep", 10)
nvs.write(OMNI,"maxpower", 80)
nvs.write(OMNI,"kf", 90/1080)
nvs.write(OMNI,"kp", 0.01)
nvs.write(OMNI,"ki", 0.05)
nvs.write(OMNI,"kd", 0)
nvs.write(PROXIMITY,"period", 100)
nvs.write(PROXIMITY,"threshold", 250)
nvs.write(PROXIMITY,"hysteresis", 3)
nvs.write("wfi","mode", "none")
nvs.write("wfi","ssid", "robotitoG")
nvs.write("wfi","passwd", "robotito")
nvs.write("wfi","channel", 0)
nvs.write("wfi","udp_port", 2018)
nvs.write("wfi","broadcast", "255,255,255,255")
nvs.write("wfi","udp_announce_port", 2018)
nvs.write("wfi","udp_announce_interval", 10)
nvs.write("wfi","receive_timeout", -1)
