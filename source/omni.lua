--- Omnidirectional platform.
-- Configuration is loaded using `nvs.read("omni", parameter)` calls, where the
-- available parameters are:
--
--* `"maxpower"` Limits the maximum power output of the motors as percentage.
-- Defaults to 80.0
--
--* `"kf"` Feed-forward parameter of the motor control in (power% / (tics/s) ).
-- Defaults to 90/1080
--
--* `"kp"` P parameter of the PID control. Defaults to 0.01
--
--* `"ki"` I parameter of the PID control. Defaults to 0.05
--
--* `"kd"` D parameter of the PID control. Defaults to 0.0
-- @module omni
-- @alias M
local omni = {}

local device = require('omni_hbridge')

do
  local WHEEL_DIAMETER = 0.038   --m
  local ROBOT_RADIUS = 0.0675 --m

--WHEEL_PERIMETER = WHEEL_DIAMETER*3.141592654
  local ENC_CPR = 3--12  --counts per revolution
  local MOTOR_REDUCTION = 50
  local TICS_PER_REVOLUTION = ENC_CPR*MOTOR_REDUCTION
  local RAD_PER_TICK = 2*math.pi / TICS_PER_REVOLUTION

  local MAX_SPEED_POWER = 90 -- power % at which MAX_SPEED_TICS is obtained
  local MAX_SPEED_TICS = 1080 --tics/s at MAX_SPEED_POWER

  local MAX_SPEED_RAD = MAX_SPEED_TICS * RAD_PER_TICK  -- rad/s
  local MAX_SPEED_LIN = MAX_SPEED_RAD * WHEEL_DIAMETER / 2 -- m/s

-- forward feed parameter
  local KF = MAX_SPEED_POWER / MAX_SPEED_TICS
  KF = nvs.read("omni","kf", KF) or KF
  local KP = nvs.read("omni","kp", 0.01) or 0.01
  local KI = nvs.read("omni","ki", 0.05) or 0.05
  local KD = nvs.read("omni","kd", 0.0) or 0.0

-- initialize with robot radius and drivers' pins
  device.init(ROBOT_RADIUS, 27,26,37,39, 23,18,35,34, 33,25,36,38)
  device.set_pid(KP, KI, KD, KF)
  device.set_set_rad_per_tick(RAD_PER_TICK)
  device.set_set_wheel_diameter(WHEEL_DIAMETER)

  local function get_interpolator(x1, y1, x2, y2)
    local p = (y2-y1)/(x2-x1)
    return function (x)
      return p*(x-x1)+y1
    end
  end
  local normalize = get_interpolator(0, 0, MAX_SPEED_POWER, MAX_SPEED_LIN)

  local max = nvs.read('omni', 'maxpower', 80.0) or 80
  device.set_max_output(max)

  --- Estimated maximum speed in m/s.
  -- This is computed from the maxpower setting.
  omni.max_speed = normalize(max)
end

local function odom_publicator(x,y,phi,x_dot,y_dot,phi_dot)
  uart.write(uart.CONSOLE, "odometry (x,y,phi): " .. tostring(x) .. " " .. tostring(y) .. " " .. tostring(phi) .. " " .. tostring(x_dot) .. " " .. tostring(y_dot) .. " " .. tostring(phi_dot) .. "\n\r" )
end

--- The callback module for the odometry.
-- @tparam callback function name
-- @tparam integer factor that is multiplied by 0.05s to determine the odometer check period. Must be greater than 1.
-- @tparam float X_0
-- @tparam float Y_0
-- @tparam float Phi_0
device.set_odometry_callback(odom_publicator,10,0,0,0)


local cont_enables = 0

--- The native C firmware module.
-- This can be used to access low level functionality from `omni_hbridge`. FIXME: docs
omni.device = device

--- Move the robot.
-- @function drive
-- @tparam number x_dot velocity on the x axis, in m/s
-- @tparam number y_dot velocity on the y axis, in m/s
-- @tparam number w_dot rotation angular velocity, in rad/s
-- @tparam[opt=0] number phi rotation of the xy axis, in rad. Defaults to 0
omni.drive = device.drive

--- Enable/disable motors.
-- @function enable
-- @tparam[opt=true] boolean on if true value or omitted, power up.
-- If false value then power down.
omni.enable = device.set_enable

omni.encoder = {}

--- The callback module for the encoders.
-- This is a callback list attached to the motor encoders, see @{cb_list}.
-- This call triggers when wheels rotate.
-- @usage local local omni = require 'omni'
--omni.encoder.cb.append( function (id, dir, count) print(id, count) end )
-- @tparam integer id the wheel identifier, in the 1..3 range
-- @tparam integer dir either 1 or -1, indicating the direction of the rotation
-- @tparam integer count a rotation counter in encoder ticks.
omni.encoder.cb = require'cb_list'.get_list()

--- Enables the encoder callback.
-- When enabled, wheel movement will trigger @{omni.encoder.cb}.
-- @tparam boolean on true value to enable, false value to disable.
omni.encoder.enable = function (on)
  if on and cont_enables == 0 then
    device.set_encoder_callback(omni.encoder.cb.call)
  elseif (not on) and cont_enables == 1 then
    device.set_encoder_callback(nil)
  end

  if on then
    cont_enables = cont_enables + 1
  end

  if (not on) and cont_enables ~= 0 then
    cont_enables = cont_enables - 1
  end
end

return omni
