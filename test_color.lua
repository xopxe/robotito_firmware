local apds9960 = require('apds9960')

apds9960.init()
apds9960.light.enable_sensor(false)

while true do
  local ambient = apds9960.light.read_ambient()
  print( ambient )
end


