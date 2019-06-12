--- Autorun script.
-- The first program to run, used to boot the whole system. Configuration 
-- is loaded using `nvs.read("autorun", parameter)` calls, where the
-- available parameters are:  
--  
--* `"runonce"` A program to execute only once. This parameter is set to nil
-- just before running. This can be used to run calibration tools, like
-- `"calibrate_color.lua"`  
--  
--* `"main"` The program to run. Some examples are `"main_ahsm.lua"`, 
-- `"test_omni.lua"`, `"test_wifi.lua"`, etc.
-- @script autorun

print("Booting robotito")

print("Looking for a run-once program into nvs('autorun', 'runonce')")
local runonce = nvs.read("autorun", "runonce", nil)
if runonce then 
  print("Run-once program:", runonce)
  nvs.write("autorun", "runonce", nil)
  dofile(runonce)
else
  print ("No run-once program set.")

  print("Looking for a main program into nvs('autorun', 'main')")
  local main = nvs.read("autorun", "main", nil)
  if main then 
    print("Main program:", main)
    dofile(main)
  else
    print ("No main program set.")
  end
end

