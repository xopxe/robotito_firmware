--- Autorun script.
-- The first program to run, used to boot the whole system. Configuration 
-- is loaded using `nvs.read("autorun", parameter)` calls, where the
-- available parameters are:  
--  
--* `"main"` The program to run. Some options are `"main_ahsm.lua"`, 
-- `"test_omni.lua"`, `"test_wifi.lua"`, etc.
-- @script autorun

print("Booting robotito, looking into nvs('autorun', 'main')")

local main = nvs.read("autorun", "main", nil)

if main then 
  print("Main program:", main)
  dofile(main)
else
  print ("No main program set.")
end