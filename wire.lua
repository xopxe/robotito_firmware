return function (device_addr, freq)
  
  local M = {}
  
  local DEFAULT_I2C_K_Hz = 400

  -- Initialize I2C --
  local i2c_bus = i2c.attach(i2c.I2C0, i2c.MASTER, (freq or DEFAULT_I2C_K_Hz)*1000)

  -- INICIA DEVICE_ADDR
  local DEVICE_ADDR = device_addr

  -- @brief Reads a single byte from the I2C device and specified register
  --
  -- @param[in] reg the register to read from
  -- @return value on success or nil on error

  -- TODO: Capturar excepciones de escritura y lectura de i2c
  local function read_data_byte(reg)
    local val
    try {
      function()
        -- Indicate which register we want to read from --
        i2c_bus:start()
        i2c_bus:address(DEVICE_ADDR, false)
        i2c_bus:write(reg)
        i2c_bus:start()
        i2c_bus:address(DEVICE_ADDR, true)
        val = i2c_bus:read()
        i2c_bus:stop()
      end, 
      function()
        val=nil
      end
    }
    return val
  end -- read_data_byte
  M.read_data_byte = read_data_byte

  function M.write_data_byte(reg, val)
    local success
    try {
      function()
        i2c_bus:start()
        i2c_bus:address(DEVICE_ADDR, false)
        i2c_bus:write(reg, val) -- Indicate which register we want to write to and the value
        i2c_bus:stop()
        success=true
      end,
    }
    return success
  end -- write_data_byte

  function M.read_word(rlow, rhigh)
    local val
    try {
      function()
        -- Read value from clear channel, low byte register
        local val_l = read_data_byte(DEVICE_ADDR, rlow)
        -- Read value from clear channel, high byte register
        local val_h = read_data_byte(DEVICE_ADDR, rhigh)
        
        if not val_l or not val_h then
          return
        end
        val = val_l + (val_h << 8)
      end, 
      function()
        val=nil
      end
    }
 
    return val
  end

  return M

end


