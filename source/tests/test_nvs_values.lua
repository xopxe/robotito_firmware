--- Test NVS

local aux

local checks = {{"robot","id","8"},
                {"autorun", "main", "main_ahsm.lua"},
                {"autorun", "runonce", nil},
                {"ahsm", "root", "states.ciceaapp"},
                {"wifi","mode", "ap"},
                {"ciceaapp","behavior", "states.color"}}


local function print_nav_value(name, param, val)
    nvs.write(name, param, val)
    local aux = val
    if (val == nil) then
      aux = "nil"
    end
    print('New Parameter: Namespace '..name..' Parameter '..param..' Value '..aux..'.')
    tmr.sleepms(2000)
end


for i, elem in pairs(checks) do
  print_nav_value(elem[1], elem[2], elem[3])
end
