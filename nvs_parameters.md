# Non volatile storage parameters

To set a values, use `nvs.write (namespace, key, value)` on th console. 
For example, to set the maximum range for the laser rangefinder ring to 55cm, 
call

```lua
nvs.write ('laser', 'dmax', 550)
```

Most of these parameters are read on initialization, so you probably need to
reboot for new values to take effect.

[Spreadsheet format](https://docs.google.com/spreadsheets/d/1eL5GefRWNlg14SHvchfIQYr1zQamI9k9hRciox3Rq5k/edit?usp=sharing)

```
 module          namespace  key                            default                                                                                                                                                                        
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 autorun.lua     autorun    runonce                        nil                   A program to execute only once. This parameter is set to nil just before running. This can be used to run calibration tools, like "calibrate_color.lua"  
                 autorun    main                           nil                   The program to run. Some examples are "main_ahsm.lua", "test_omni.lua", "test_wifi.lua", etc.                                                            
 color.lua       color      min_sat                        24                    If the saturaion is below this, color is 'unknown'                                                                                                       
                 color      min_val                        40                    If the value is below this, color is 'black'                                                                                                             
                 color      max_val                        270                   If the value is above this, color is 'white'                                                                                                             
                 color      red_h,red_s,red_v              348,170,135           Hue range for 'red'                                                                                                                                      
                 color      yellow_h,yellow_s,yellow_v     70,226,228            Hue range for 'yellow'                                                                                                                                   
                 color      green_h,green_s,green_v        181,250,175           Hue range for 'green'                                                                                                                                    
                 color      blue_h,blue_s,blue_v           214,312,180           Hue range for 'blue'                                                                                                                                     
                 color      magenta_h,magenta_s,magenta_v  260,170,135           Hue range for 'magenta'                                                                                                                                  
                 color      gain                           1                     apds9960 light gain parameter                                                                                                                            
                 color      period                         100                   integer period Sampling period in ms                                                                                                                     
 laser_ring.lua  laser      time_budget                    5000                  The timing budget for the measurements                                                                                                                   
                 laser      dmin                           80                    Minimum range for normalization in mm.                                                                                                                   
                 laser      dmax                           600                   Maximum range for normalization in mm.                                                                                                                   
                 laser      period                         100                   Sampling period in ms                                                                                                                                    
 led_ring.lua    led_ring   power                          20                    max power to use, in the 0..100% range.                                                                                                                  
 main_ahsm.lua   ahsm       debugger                       nil                   the debug output system, like ahsm's "debug_plain"                                                                                                       
                 ahsm       root                           "states.test"         a composite state to be used as root for the state machine. This must be the name of library to be required, which will return an ahsm state.            
                 ahsm       timestep                       10                    ime in ms between sweeps to check for timed out transitions.                                                                                             
 omni.lua        omni       maxpower                       80                    Limits the maximum power output of the motors as percentage.                                                                                             
                 omni       kf                             90/1080               Feed-forward parameter of the motor control in (power% / (tics/s) )                                                                                      
                 omni       kp                             0.1                   P parameter of the PID control.                                                                                                                          
                 omni       ki                             0.05                  I parameter of the PID control                                                                                                                           
                 omni       kd                             0                     D parameter of the PID control.                                                                                                                          
 proximity.lua   proximity  period                         100                   Sampling period in ms                                                                                                                                    
                 proximity  threshold                      250                   proximity reference value                                                                                                                                
                 proximity  hysteresis                     3                                                                                                                                                                              
 robot.lua       robot      id                             0                     Serial number. Must be set on installation                                                                                                               
 wifi_net.lua    wifi       mode                           "none"                either 'ap' or 'sta', or 'none'                                                                                                                          
                 wifi       ssid                           "robotito"..robot.id  the wireless network ssid                                                                                                                                
                 wifi       passwd                         robotito              the wireless network password                                                                                                                            
                 wifi       channel                        0                                                                                                                                                                              
                 wifi       udp_port                       2018                  listening port                                                                                                                                           
                 wifi       broadcast                      "255,255,255,255"     target address for the announcements                                                                                                                     
                 wifi       udp_announce_port              2018                  announcement target port                                                                                                                                 
                 wifi       udp_announce_interval          10                    time between announcements (in s), -1 mean disabled.                                                                                                     
                 wifi       receive_timeout                -1                    timeout for udp reads (in sec),  -1 mean disabled                                                                                                        
```
