local WHEEL_DIAMETER   = 0.038   --m
local ROBOT_RADIUS = 0.0675 --m

--WHEEL_PERIMETER = WHEEL_DIAMETER*3.141592654
local ENC_CPR = 12  --counts per revolution
local MOTOR_REDUCTION = 50
local TICS_PER_REVOLUTION = ENC_CPR*MOTOR_REDUCTION
local RAD_PER_TICK = 2*math.pi / TICS_PER_REVOLUTION

local MAX_SPEED_POWER = 90 -- power % at which MAX_SPEED_TICS value is obtained
local MAX_SPEED_TICS = 1080 --tics/s at MAX_SPEED_POWER

local MAX_SPEED_RAD = MAX_SPEED_TICS * RAD_PER_TICK  -- rad/s
local MAX_SPEED_LIN = MAX_SPEED_RAD * WHEEL_DIAMETER / 2 -- m/s

-- forward feed parameter
local KF = MAX_SPEED_POWER / TICS_PER_REVOLUTION

local omni = require('omni_hbridge')

local KP = 0.1     --0.1/ENC_CPR

-- initialize with tobot radius and drivers' pins
--omni.init(5.0, 27,26,39,37, 33,25,38,36, 23,18,34,35)
--omni.init(5.0, 26,27,39,37, 25,33,38,36, 18,23,34,35)
omni.init(ROBOT_RADIUS, 27,26,37,39, 33,25,36,38, 23,18,35,34)
omni.set_pid(KP, 0.05, 0.0, KF)
omni.set_set_rad_per_tick(RAD_PER_TICK)
omni.set_set_wheel_diameter(WHEEL_DIAMETER)
omni.set_max_output(80.0)


return omni