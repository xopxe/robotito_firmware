#!/bin/bash

MODULES_DIR="arquitectura/Modules"
UTILS_DIR="utils"

wcc -p /dev/ttyUSB0 -up $MODULES_DIR/fsm_align.lua fsm_align.lua
wcc -p /dev/ttyUSB0 -up $MODULES_DIR/fsm_find_farest_object.lua fsm_find_farest_object.lua
wcc -p /dev/ttyUSB0 -up $MODULES_DIR/fsm_on_off.lua fsm_on_off.lua
wcc -p /dev/ttyUSB0 -up $MODULES_DIR/laser_ring.lua laser_ring.lua
wcc -p /dev/ttyUSB0 -up $MODULES_DIR/led_ring.lua led_ring.lua
wcc -p /dev/ttyUSB0 -up $MODULES_DIR/main.lua main.lua
wcc -p /dev/ttyUSB0 -up $MODULES_DIR/robot.lua robot.lua
wcc -p /dev/ttyUSB0 -up $UTILS_DIR/autorun.lua autorun.lua

echo Modules Updated