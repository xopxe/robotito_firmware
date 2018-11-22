local robot_id = 7

nvs.write("robot","id", robot_id)
nvs.write("robot","behavior", "robotito.lua")

nvs.write("wifi","ssid", "robotito-" .. robot_id)
nvs.write("wifi","passwd", "robotito")
nvs.write("wifi","channel", robot_id)

nvs.write("color_sensor","min_sat", 24)
nvs.write("color_sensor","min_val", 40)
nvs.write("color_sensor","max_val", 270)
nvs.write("color_sensor","min_h_yellow", 22)
nvs.write("color_sensor","max_h_yellow", 65)
nvs.write("color_sensor","min_h_green", 159)
nvs.write("color_sensor","max_h_green", 180)
nvs.write("color_sensor","min_h_blue", 209)
nvs.write("color_sensor","max_h_blue", 215)
nvs.write("color_sensor","min_h_magenta", 255)
nvs.write("color_sensor","max_h_magenta", 300)
nvs.write("color_sensor","min_h_red", 351)
nvs.write("color_sensor","max_h_red", 359)
