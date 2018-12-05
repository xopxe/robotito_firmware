--- Autorun script.
-- The first program to run, used to boot the whole system. Configuration 
-- is loaded using `nvs.read("autorun", parameter)` calls, where the
-- available parameters are:  
--  
--* `"main"` program to run, defaults to `"main_ahsm.lua"`. Other options are 
-- `"test_omni.lua"`, `"test_wifi.lua"`, etc.
-- @script autorun

print("Booting robotito")

local main = nvs.read("autorun", "main", "main_ahsm.lua")
print("Main program:", main)

dofile(main)