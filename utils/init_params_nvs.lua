local robot_id = 7  

if nvs.read('robot', 'id', nil) ~= nil then 
  nvs.write("robot","id", robot_id)
--nvs.write("robot","behavior", "robotito.lua")

  nvs.write("wifi","ssid", "robotito" .. robot_id)
  nvs.write("wifi","passwd", "robotito")
end