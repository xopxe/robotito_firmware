local M = {
  proximity = {},
  gesture = {},
  light = {},
}

-- APDS-9960 I2C address --
local APDS9960_I2C_ADDR = 0x39

local wire = require('wire') (APDS9960_I2C_ADDR)
local read_data_byte = wire.read_data_byte
local write_data_byte = wire.write_data_byte
local read_word = wire.read_word

-- Debug --
--unused DEBUG = 0

--[[unused
-- Gesture parameters --
GESTURE_THRESHOLD_OUT = 10
GESTURE_SENSITIVITY_1 = 50
GESTURE_SENSITIVITY_2 = 20
--]]

-- Acceptable device IDs --
local APDS9960_ID_1 = 0xAB
local APDS9960_ID_2 = 0x9C 

-- Misc parameters --
--unused local FIFO_PAUSE_TIME = 30      -- Wait period (ms) between FIFO reads

-- APDS-9960 register addresses --
local APDS9960_ENABLE = 0x80
local APDS9960_ATIME = 0x81
local APDS9960_WTIME = 0x83
local APDS9960_AILTL = 0x84
local APDS9960_AILTH = 0x85
local APDS9960_AIHTL = 0x86
local APDS9960_AIHTH = 0x87
local APDS9960_PILT = 0x89
local APDS9960_PIHT = 0x8B
local APDS9960_PERS = 0x8C
local APDS9960_CONFIG1 = 0x8D
local APDS9960_PPULSE = 0x8E
local APDS9960_CONTROL = 0x8F
local APDS9960_CONFIG2 = 0x90
local APDS9960_ID = 0x92
--unused local APDS9960_STATUS = 0x93
local APDS9960_CDATAL = 0x94
local APDS9960_CDATAH = 0x95
local APDS9960_RDATAL = 0x96
local APDS9960_RDATAH = 0x97
local APDS9960_GDATAL = 0x98
local APDS9960_GDATAH = 0x99
local APDS9960_BDATAL = 0x9A
local APDS9960_BDATAH = 0x9B
local APDS9960_PDATA = 0x9C
local APDS9960_POFFSET_UR = 0x9D
local APDS9960_POFFSET_DL = 0x9E
local APDS9960_CONFIG3 = 0x9F
local APDS9960_GPENTH = 0xA0
local APDS9960_GEXTH = 0xA1
local APDS9960_GCONF1 = 0xA2
local APDS9960_GCONF2 = 0xA3
local APDS9960_GOFFSET_U = 0xA4
local APDS9960_GOFFSET_D = 0xA5
local APDS9960_GOFFSET_L = 0xA7
local APDS9960_GOFFSET_R = 0xA9
local APDS9960_GPULSE = 0xA6
local APDS9960_GCONF3 = 0xAA
local APDS9960_GCONF4 = 0xAB
--unused local APDS9960_GFLVL = 0xAE
--unused local APDS9960_GSTATUS = 0xAF
--unused local APDS9960_IFORCE = 0xE4
--unused local APDS9960_PICLEAR = 0xE5
--unused local APDS9960_CICLEAR = 0xE6
--unused local APDS9960_AICLEAR = 0xE7
--unused local APDS9960_GFIFO_U = 0xFC
--unused local APDS9960_GFIFO_D = 0xFD
--unused local APDS9960_GFIFO_L = 0xFE
--unused local APDS9960_GFIFO_R = 0xFF

-- Bit fields --
--unused local APDS9960_PON = 1
--unused local APDS9960_AEN = 2
--unused local APDS9960_PEN = 4
--unused local APDS9960_WEN = 8
--unused local APSD9960_AIEN = 16
--unused local APDS9960_PIEN = 32
--unused local APDS9960_GEN =  64
--unused local APDS9960_GVALID = 1


-- Acceptable parameters for setMode --
local POWER = 0
local AMBIENT_LIGHT = 1
local PROXIMITY = 2
--unused local WAIT = 3
--unused local AMBIENT_LIGHT_INT = 4
--unused local PROXIMITY_INT = 5
--unused local GESTURE = 6
local ALL = 7



--[[unused
-- LED Boost values --
LED_BOOST_100 = 0
LED_BOOST_150 = 1
LED_BOOST_200 = 2
LED_BOOST_300 = 3    
--]]

-- Default values --
local DEFAULT_ATIME = 219     -- 103ms
local DEFAULT_WTIME = 246     -- 27ms
local DEFAULT_PROX_PPULSE = 0x87    -- 16us, 8 pulses
--unused local DEFAULT_GESTURE_PPULSE = 0x89    -- 16us, 10 pulses
local DEFAULT_POFFSET_UR = 0       -- 0 offset
local DEFAULT_POFFSET_DL = 0       -- 0 offset      
local DEFAULT_CONFIG1 = 0x60    -- No 12x wait (WTIME) factor
local DEFAULT_LDRIVE = 'LED_DRIVE_100MA'
local DEFAULT_PGAIN = 'PGAIN_4X'
local DEFAULT_AGAIN = 'AGAIN_4X'
local DEFAULT_PILT = 0       -- Low proximity threshold
local DEFAULT_PIHT = 255      -- High proximity threshold
local DEFAULT_AILT = 0xFFFF  -- Force interrupt for calibration
local DEFAULT_AIHT = 0
local DEFAULT_PERS = 0x11    -- 2 consecutive prox or ALS for int.
local DEFAULT_CONFIG2 = 0x01    -- No saturation interrupts or LED boost  
local DEFAULT_CONFIG3 = 0       -- Enable all photodiodes, no SAI
local DEFAULT_GPENTH = 40      -- Threshold for entering gesture mode
local DEFAULT_GEXTH = 30      -- Threshold for exiting gesture mode    
local DEFAULT_GCONF1 = 0x40    -- 4 gesture events for int., 1 for exit
local DEFAULT_GGAIN = 'GGAIN_4X'
local DEFAULT_GLDRIVE = 'LED_DRIVE_100MA'
local DEFAULT_GWTIME = 'WTIME_2_8MS'
local DEFAULT_GOFFSET = 0       -- No offset scaling for gesture mode
local DEFAULT_GPULSE = 0xC9    -- 32us, 10 pulses
local DEFAULT_GCONF3 = 0       -- All photodiodes active during gesture
local DEFAULT_GIEN = 0       -- Disable gesture interrupts


local i2c_bus

-- @brief Reads and returns the contents of the ENABLE register
-- @return Contents of the ENABLE register. nil on error
local function get_mode()
  -- Read current ENABLE register
  return read_data_byte(APDS9960_ENABLE)
end -- get_mode

-- @brief Enables or disables a feature in the APDS-9960
-- @param[in] mode which feature to enable
-- @param[in] enable true or false
-- @return True if operation success. False otherwise.
local function set_mode(mode, enable)
  -- Read current ENABLE register
  local reg_val = get_mode()
  if not reg_val then
    return false
  end

  -- Change bit(s) in ENABLE register
  if mode >= 0 and mode <= 6 then
    if enable then
      reg_val = reg_val | (1 << mode)
    else
      reg_val = reg_val & ~(1 << mode)
    end
  else 
    if mode == ALL then
      if enable then
        reg_val = 0x7F
      else
        reg_val = 0x00
      end
    end
  end

  -- Write value back to ENABLE register
  if not write_data_byte(APDS9960_ENABLE, reg_val) then
    return false
  end

  return true
end -- set_mode

-- @brief Turns gesture-related interrupts on or off
-- @param[in] enable 1 to enable interrupts, 0 to turn them off
-- @return True if operation successful. False otherwise.
local function set_gesture_int_enable(enable)
  -- Read value from GCONF4 register
  local val = read_data_byte(APDS9960_GCONF4)
  if not val then
    return false
  end

  -- Set bits in register to given value
  enable = enable & 0x1 -- 0b00000001
  enable = enable << 1
  val = val & 0xFD -- 0b11111101;
  val = val | enable

  -- Write register value back into GCONF4 register
  return write_data_byte(APDS9960_GCONF4, val)
end -- set_gesture_int_enable

-- @brief Turns proximity interrupts on or off
-- @param[in] enable 1 to enable interrupts, 0 to turn them off
-- @return True if operation successful. False otherwise.
local function set_proximity_int_enable(enable)
  -- Read value from ENABLE register
  local val = read_data_byte(APDS9960_ENABLE)
  if not val then
    return false
  end

  -- Set bits in register to given value
  --[[
  enable = enable & 0x1 --0b00000001
  enable = enable << 5
  val = val & 0xDF --0b1101 1111
  val = val | enable
  --]]
  val = val & 0xDF --0b1101 1111
  if enable then
    val = val | (0x01 << 5)
  end
  

  -- Write register value back into ENABLE register
  if not write_data_byte(APDS9960_ENABLE, val) then
    return false
  end

  return true
end -- end set_proximity_int_enable


-- @brief Turns ambient light interrupts on or off
-- @param[in] true or false to enable to enable or disable interrupts
-- @return True if operation successful. False otherwise.
local function set_ambient_light_int_enable(enable)
  -- Read value from ENABLE register
  local val = read_data_byte(APDS9960_ENABLE)
  if not val then
    return false
  end

  -- Set bits in register to given value 
  --[[
  enable = enable & 0x01 -- 0b00000001
  enable = enable << 4
  val = val & 0xEF -- 0b11101111;
  val = val | enable;
  --]]
  val = val & 0xEF -- 0b11101111
  if enable then
    val = val | (0x01 << 4)
  end

  -- Write register value back into ENABLE register
  return write_data_byte(APDS9960_ENABLE, val)
end -- set_ambient_light_int_enable

-- Turn the APDS-9960 on
-- @return True if operation successful. False otherwise.
function M.enable_power()
  return set_mode(POWER, true)
end


function M.init()
  -- Initialize I2C --
  local I2C_K_Hz = 400
  i2c_bus = i2c.attach(i2c.I2C0, i2c.MASTER, I2C_K_Hz * 1000)

  -- Read ID register and check against known values for APDS-9960
  local id = read_data_byte(APDS9960_ID)
  if not id then
    return false, "Reading sensor ID"
  end

  if not (id == APDS9960_ID_1) or (id == APDS9960_ID_2) then
    return false, "Invalid ID (" .. tostring(id) .. ")."
  end

  -- Set ENABLE register to 0 (disable all features)
  if not set_mode(ALL, false) then
    return false, "Disabling all features"
  end

  -- Set default values for ambient light and proximity registers
  if not write_data_byte(APDS9960_ATIME, DEFAULT_ATIME) then
    return false, "Setting ambient light and proximity registers"
  end
  if not write_data_byte(APDS9960_WTIME, DEFAULT_WTIME) then
    return false, "Something APDS9960_WTIME"
  end
  if not write_data_byte(APDS9960_PPULSE, DEFAULT_PROX_PPULSE) then
    return false, "Something APDS9960_PPULSE"
  end
  if not write_data_byte(APDS9960_POFFSET_UR, DEFAULT_POFFSET_UR) then
    return false, "Something APDS9960_POFFSET_UR"
  end
  if not write_data_byte(APDS9960_POFFSET_DL, DEFAULT_POFFSET_DL) then
    return false, "Something APDS9960_POFFSET_DL"
  end
  if not write_data_byte(APDS9960_CONFIG1, DEFAULT_CONFIG1) then
    return false, "Something APDS9960_CONFIG1"
  end
  if not M.set_LED_drive(DEFAULT_LDRIVE) then
    return false, "Setting LED drive"
  end
  if not M.proximity.set_gain(DEFAULT_PGAIN) then
    return false, "Setting proximity gain"
  end
  if not M.set_ambient_light_gain(DEFAULT_AGAIN) then
    return false, "Setting ambient light gain"
  end
  if not M.set_prox_int_low_thresh(DEFAULT_PILT) then
    return false, "Setting proximity int low threshold"
  end
  if not M.set_prox_int_high_thresh(DEFAULT_PIHT) then
    return false, "Setting proximity int high threshold"
  end
  if not M.set_light_int_low_threshold(DEFAULT_AILT) then
    return false, "Setting light int low threshold"
  end
  if not M.set_light_int_high_threshold(DEFAULT_AIHT) then
    return false, "Setting light int high threshold"
  end
  if not write_data_byte(APDS9960_PERS, DEFAULT_PERS) then
    return false, "Setting APDS9960_PERS"
  end
  if not write_data_byte(APDS9960_CONFIG2, DEFAULT_CONFIG2) then
    return false, "Setting APDS9960_CONFIG2"
  end
  if not write_data_byte(APDS9960_CONFIG3, DEFAULT_CONFIG3) then
    return false, "Setting APDS9960_CONFIG3"
  end
  -- Set default values for gesture sense registers --
  if not M.set_gesture_enter_thresh(DEFAULT_GPENTH) then
    return false, "Setting gesture enter threshold"
  end
  if not M.set_gesture_exit_thresh(DEFAULT_GEXTH) then
    return false, "Setting gesture exit threshold"
  end
  if not write_data_byte(APDS9960_GCONF1, DEFAULT_GCONF1) then
    return false, "Setting APDS9960_GCONF1"
  end
  if not M.gesture.set_gain(DEFAULT_GGAIN) then
    return false, "Setting gesture gain"
  end
  if not M.gesture.set_LED_drive(DEFAULT_GLDRIVE) then
    return false, "Setting gesture LED drive"
  end
  if not M.gesture.set_wait_time(DEFAULT_GWTIME) then
    return false, "Setting gesture wait time"
  end
  if not write_data_byte(APDS9960_GOFFSET_U, DEFAULT_GOFFSET) then
    return false, "Setting APDS9960_GOFFSET_U"
  end
  if not write_data_byte(APDS9960_GOFFSET_D, DEFAULT_GOFFSET) then
    return false, "Setting APDS9960_GOFFSET_D"
  end
  if not write_data_byte(APDS9960_GOFFSET_L, DEFAULT_GOFFSET) then
    return false, "Setting APDS9960_GOFFSET_L"
  end
  if not write_data_byte(APDS9960_GOFFSET_R, DEFAULT_GOFFSET) then
    return false, "Setting APDS9960_GOFFSET_R"
  end
  if not write_data_byte(APDS9960_GPULSE, DEFAULT_GPULSE) then
    return false, "Setting APDS9960_GPULSE"
  end
  if not write_data_byte(APDS9960_GCONF3, DEFAULT_GCONF3) then
    return false, "Setting APDS9960_GCONF3"
  end
  if not set_gesture_int_enable(DEFAULT_GIEN) then
    return false, "Setting gesture int enable"
  end

  return true
end -- end init


-- @brief Sets the LED drive strength for proximity and ALS
--
-- Value    LED Current
--   0        100 mA
--   1         50 mA
--   2         25 mA
--   3         12.5 mA
-- @param[in] drive the value (0-3) for the LED drive strength
-- @return True if operation successful. False otherwise.
function M.set_LED_drive(drive)
  -- LED Drive values --
  local LED_DRIVE = {
    ['LED_DRIVE_100MA'] = 0,
    ['LED_DRIVE_50MA'] = 1,
    ['LED_DRIVE_25MA'] = 2,
    ['LED_DRIVE_12_5MA'] = 3,
  }
  drive = tonumber(drive) or assert(LED_DRIVE[drive])
  
  -- Read value from CONTROL register --
  local val = read_data_byte(APDS9960_CONTROL)
  if not val then
    return false
  end

  -- Set bits in register to given value
  drive = drive & 0x3 -- 0b0000 0011
  drive = drive << 6
  val = val & 0x3F --0b0011 1111
  val = val | drive

  -- Write register value back into CONTROL register
  if not write_data_byte(APDS9960_CONTROL, val) then
    return false
  end

  return true
end -- set_LED_drive

-- @brief Sets the receiver gain for proximity detection
--
-- Value    Gain
--   0       1x
--   1       2x
--   2       4x
--   3       8x
--
-- @param[in] drive the value (0-3) for the gain
-- @return True if operation successful. False otherwise.
function M.proximity.set_gain(drive)
  -- Proximity Gain (PGAIN) values --
  local PGAIN = {
    ['PGAIN_1X'] = 0,
    ['PGAIN_2X'] = 1,
    ['PGAIN_4X'] = 2,
    ['PGAIN_8X'] = 3,
  }
  drive = tonumber(drive) or assert(PGAIN[drive])
  
  -- Read value from CONTROL register
  local val = read_data_byte(APDS9960_CONTROL)
  if not val then
    return false
  end

  -- Set bits in register to given value
  drive = drive & 0x3 --0b00000011
  drive = drive << 2
  val = val & 0xF3 --0b1111 0011
  val = val | drive

  -- Write register value back into CONTROL register
  if not write_data_byte(APDS9960_CONTROL, val) then
    return false
  end

  return true
end -- set_proximity_gain

-- @brief Starts the proximity sensor on the APDS-9960
-- @param[in] interrupts true to enable hardware external interrupt on proximity
-- @return True if sensor enabled correctly. False on error.
function M.proximity.enable_sensor(interrupts)
  -- Set default gain, LED, interrupts, enable power, and enable sensor
  if not M.proximity.set_gain(DEFAULT_PGAIN) then
    return false, "Setting default gain"
  end
  if not M.set_LED_drive(DEFAULT_LDRIVE) then
    return false, "Setting default LED drive"
  end
  if not set_proximity_int_enable(interrupts) then
    return false, "Setting proximity int enable to "..tostring(interrupts)
  end  
  if not M.enable_power() then
    return false, "Enabling power"
  end
  if not set_mode(PROXIMITY, true) then
    return false, "Setting proximity mode"
  end

  return true
end -- end enable_proximity_sensor

-- @brief Reads the proximity level as an 8-bit value
-- @param[out] val value of the proximity sensor.
-- @return True if operation successful. False otherwise.
function M.proximity.read()
  return read_data_byte(APDS9960_PDATA)
end -- 


-- @brief Sets the lower threshold for proximity detection
-- @param[in] threshold the lower proximity threshold
-- @return True if operation successful. False otherwise.
function M.proximity.set_int_low_thresh(threshold)
  return write_data_byte(APDS9960_PILT, threshold) 
end -- set_prox_int_low_thresh

-- @brief Sets the high threshold for proximity detection
-- @param[in] threshold the high proximity threshold
-- @return True if operation successful. False otherwise.
function M.proximity.set_int_high_thresh(threshold)
  return write_data_byte(APDS9960_PIHT, threshold) 
end -- set_prox_int_high_thresh


-- @brief Starts the light (R/G/B/Ambient) sensor on the APDS-9960
-- @param[in] interrupts true to enable hardware interrupt on high or low light
-- @return True if sensor enabled correctly. False on error.
function M.light.enable_sensor(interrupts)
  -- Set default gain, interrupts, enable power, and enable sensor
  if not M.set_ambient_light_gain(DEFAULT_AGAIN) then
    return false
  end
  if not set_ambient_light_int_enable(interrupts) then
    return false, "Enabling ambient light int to " .. tostring(interrupts)
  end
  if not M.enable_power() then
    return false, "Enabling power"
  end

  return set_mode(AMBIENT_LIGHT, true)
end


-- @brief Sets the receiver gain for the ambient light sensor (ALS)
-- Value    Gain
--   0        1x
--   1        4x
--   2       16x
--   3       64x
-- @param[in] drive the value (0-3) for the gain
-- @return True if operation successful. False otherwise.
function M.light.set_ambient_gain(drive)
  -- ALS Gain (AGAIN) values --
  local AGAIN = {
    ['AGAIN_1X'] = 0,
    ['AGAIN_4X'] = 1,
    ['AGAIN_16X'] = 2,
    ['AGAIN_64X'] = 3,
  }
  drive = tonumber(drive) or assert(AGAIN[drive])

  
  -- Read value from CONTROL register --
  local val = read_data_byte(APDS9960_CONTROL)
  if not val then
    return false;
  end

  -- Set bits in register to given value
  drive = drive & 0x3 --0b00000011;
  val = val & 0xFC --0b1111 1100;
  val = val | drive;

  -- Write register value back into CONTROL register
  return write_data_byte(APDS9960_CONTROL, val)
end


-- @brief Sets the low threshold for ambient light interrupts
-- @param[in] threshold low threshold value for interrupt to trigger
-- @return True if operation successful. False otherwise.
function M.light.set_int_low_threshold(threshold)
  -- Break 16-bit threshold into 2 8-bit values
  local val_low = threshold & 0x00FF
  local val_high = (threshold & 0xFF00) >> 8

  -- Write low byte
  if not write_data_byte(APDS9960_AILTL, val_low) then
    return false
  end

  -- Write high byte
  return write_data_byte(APDS9960_AILTH, val_high)
end -- end set_light_int_low_threshold

-- @brief Sets the high threshold for ambient light interrupts
-- @param[in] threshold high threshold value for interrupt to trigger
-- @return True if operation successful. False otherwise.
function M.light.set_int_high_threshold(threshold)
  -- Break 16-bit threshold into 2 8-bit values
  local val_low = threshold & 0xFF
  local val_high = (threshold & 0xFF00) >> 8

  -- Write low byte
  if not write_data_byte(APDS9960_AIHTL, val_low) then
    return false
  end

  -- Write high byte
  return write_data_byte(APDS9960_AIHTH, val_high)
end -- set_light_int_high_threshold

-- @brief Reads the ambient (clear) light level as a 16-bit value
-- @param[out] val value of the light sensor.
-- @return True if operation successful. False otherwise.
function M.light.read_ambient()
  -- Read value from clear channel, low and high byte registers
  return read_word(APDS9960_CDATAL, APDS9960_CDATAH)
end

function M.light.read_red()
  -- Read value from clear channel, low and high byte registers
  return read_word(APDS9960_RDATAL, APDS9960_RDATAH)
end

function M.light.read_blue()
  -- Read value from clear channel, low and high byte registers
  return read_word(APDS9960_BDATAL, APDS9960_BDATAH)
end

function M.light.read_green()
  -- Read value from clear channel, low and high byte registers
  return read_word(APDS9960_GDATAL, APDS9960_GDATAH)
end


-- @brief Sets the entry proximity threshold for gesture sensing
-- @param[in] threshold proximity value needed to start gesture mode
-- @return True if operation successful. False otherwise.
function M.gesture.set_enter_thresh(threshold)
  return write_data_byte(APDS9960_GPENTH, threshold)
end -- end set_gesture_enter_thresh

-- @brief Sets the exit proximity threshold for gesture sensing
-- @param[in] threshold proximity value needed to end gesture mode
-- @return True if operation successful. False otherwise.
function M.gesture.set_exit_thresh(threshold)
  return write_data_byte(APDS9960_GEXTH, threshold)
end -- end set_gesture_exit_thresh

-- @brief Sets the gain of the photodiode during gesture mode
-- Value    Gain
--   0       1x
--   1       2x
--   2       4x
--   3       8x
-- @param[in] gain the value for the photodiode gain
-- @return True if operation successful. False otherwise.
function M.gesture.set_gain(gain)
  -- Gesture Gain (GGAIN) values --
  local GGAIN = {
    ['GGAIN_1X'] = 0,
    ['GGAIN_2X'] = 1,
    ['GGAIN_4X'] = 2,
    ['GGAIN_8X'] = 3,
  }
  gain = tonumber(gain) or assert(GGAIN[gain])
  
  local val = read_data_byte(APDS9960_GCONF2)
  if not val then
    return false
  end

  -- Set bits in register to given value
  gain = gain & 0x3 --0b0000 0011;
  gain = gain << 5
  val = val & 0x9F -- 0b1001 1111;
  val = val | gain

  -- Write register value back into GCONF2 register
  return write_data_byte(APDS9960_GCONF2, val)
end -- end set_gesture_gain

-- @brief Sets the LED drive current during gesture mode
-- Value    LED Current
--   0        100 mA
--   1         50 mA
--   2         25 mA
--   3         12.5 mA
-- @param[in] drive the value for the LED drive current
-- @return True if operation successful. False otherwise.
function M.gesture.set_LED_drive(drive)
  -- LED Drive values --
  local LED_DRIVE = {
    ['LED_DRIVE_100MA'] = 0,
    ['LED_DRIVE_50MA'] = 1,
    ['LED_DRIVE_25MA'] = 2,
    ['LED_DRIVE_12_5MA'] = 3,
  }
  drive = tonumber(drive) or assert(LED_DRIVE[drive])

  -- Read value from GCONF2 register
  local val = read_data_byte(APDS9960_GCONF2)
  if not val then
    return false
  end

  -- Set bits in register to given value
  drive = drive & 0x3 -- 0b00000011;
  drive = drive << 3
  val = val & 0xE7 -- 0b1110 0111
  val = val | drive

  -- Write register value back into GCONF2 register
  return write_data_byte(APDS9960_GCONF2, val)
end -- end set_gesture_LED_drive

-- @brief Sets the time in low power mode between gesture detections
-- Value    Wait time
--   0          0 ms
--   1          2.8 ms
--   2          5.6 ms
--   3          8.4 ms
--   4         14.0 ms
--   5         22.4 ms
--   6         30.8 ms
--   7         39.2 ms
-- @param[in] the value for the wait time
-- @return True if operation successful. False otherwise.
function M.gesture.set_wait_time(time)  
  -- Gesture wait time values --
  local WTIME = {
    ['WTIME_0MS'] = 0,
    ['WTIME_2_8MS'] = 1,
    ['WTIME_5_6MS'] = 2,
    ['WTIME_8_4MS'] = 3,
    ['WTIME_14_0MS'] = 4,
    ['WTIME_22_4MS'] = 5,
    ['WTIME_30_8MS'] = 6,
    ['WTIME_39_2MS'] = 7,
  }
  time = tonumber(drive) or assert(WTIME[time])

  -- Read value from GCONF2 register
  local val = read_data_byte(APDS9960_GCONF2)
  if not val then
    return false
  end

  -- Set bits in register to given value
  time = time & 0x07 --0b00000111;
  val = val & 0xF8 --0b11111000
  val = val | time

  -- Write register value back into GCONF2 register
  return write_data_byte(APDS9960_GCONF2, val)
end

return M
