# robotito: microcontrolled robotic platform for research.

This is user level environment for developping for the [robotito](https://github.com/xopxe/Lua-RTOS-ESP32/tree/robotito) platform.

This allows to write Lua scripts to define the robot's behaviour.

## Features

The system comprises:

* A set of libraries for controlling the robot, it's sensors and UI
* A networking library
* A non-volatile flash system for configuring the robot
* [A hierarchical state machine (ahsm)](https://github.com/xopxe/ahsm)

## Documentation

There is API documentation in the `doc/` folder.

Other references of interest are the [ahsm](https://github.com/xopxe/ahsm) API, and the [underlying firmware's](https://github.com/whitecatboard/Lua-RTOS-ESP32/wiki)  Lua API for low level calls such as timers and threads.

The configuration non-volatile variables are listed in the [nvs_parameters.md](nvs_parameters.md) file. Theres also a online [spreadsheet](https://docs.google.com/spreadsheets/d/1eL5GefRWNlg14SHvchfIQYr1zQamI9k9hRciox3Rq5k/edit?usp=sharing) avalialble.

## Installation

After you have you robotito correctly setup and connected, use the `update.sh` script to copy the environment to the robot. 

This script depends on the `wcc`tool being installed to be ablo to copy files to the robot. Look [here](https://github.com/whitecatboard/Lua-RTOS-ESP32#method-1-get-a-precompiled-firmware) for instructions on installing it. 

Also, this script creates a `lastrun` file used to timestamp the last update and only upload modified files. If you want to force copying everything again (for example because you connected another robot), just remove `lastrun` and execute `update.sh` again. 

Alternativelly, the `update.sh` will also create an filesystem image in the `fs/` folder. This can be flashed with the native toolchain, doing `export FS_ROOT_PATH=robotito/firmware/fs; make flashfs`.

## Getting started

We provide several test programs in the `source/tests`directory. You can run them either manually, or leave them configured to be run automatically on robot boot-up.

To run a test script manually, connect to the robot through the usb link using a serial console, like picocom:

```
$ picocom --baud 115200 /dev/ttyUSB0
``` 
and load the script using the Lua console:
```
/ > loadfile 'test_omni.lua'
```

To configure the the robot to autorun, you must set the appropiate configuration variable:

```
/ > nvs.write('autorun', 'main', 'test_led_ring.lua')
```
This will cause the `test_led_ring.lua` script to be run every time the robot is booted-up.

You can also set a program to be run only once at bootup (it will reset the variable on first run, so it will no run again on reboot). For example, this can be useful for running `calibrate_color.lua`,  a helper script that calibrates the color sensor and writes calibration data to non-volatile variables. This should be done once when the robot is setup in a new environment or the color marks are changed:

```
/ > nvs.write('autorun', 'runonce', 'calibrate_color.lua')
```

To deploy new scripts you can copy them manually using `wcc`, or modify the `update.sh` script to do it automatically. When editing `update.sh`, remember that you must add two paramaters: the filepath on your PC from where the file will be read, and a filepath on the robot, where the file will be written.

## Using ahsm

To run an application developped as an ahsm state machine, you must setup the state machine loader to be run at startup, and configure the state machine you want to run:

```
/ > nvs.write('autorun', 'main', 'main_ahsm.lua')
/ > nvs.write('ahsm', 'root', 'states.colorway')
```

The `states/colorway.lua`program moves the robot in a direction indicated by color patches on the floor.

## License

See LICENSE.


## Who?

mina@fing.edu.uy

Grupo MINA - Facultad de Ingeniería - Universidad de la República
