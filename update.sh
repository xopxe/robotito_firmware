#!/bin/bash

# File updated after each run of this script.
# Only the files newer than this file are copied to de destination
TMP_FILE=lastrun

# Information about origin files and dirs
MODULES_DIR="arquitectura/modules"
MODULES_AHSM_DIR="arquitectura/modules/states"
UTILS_DIR="utils"
AHSM_DIR="../ahsm"
TEST_DIR="test/modules_tests"

# Array of source files
declare -a LOCAL_FILES=(
$AHSM_DIR/ahsm.lua
$AHSM_DIR/tools/debug_plain.lua
$MODULES_DIR/autorun.lua
$MODULES_DIR/cb_list.lua
$MODULES_DIR/color.lua
$MODULES_DIR/laser_ring.lua
$MODULES_DIR/led_ring.lua
$MODULES_DIR/main_ahsm.lua
$MODULES_DIR/omni.lua
$MODULES_DIR/proximity.lua
$MODULES_DIR/robot.lua
$MODULES_DIR/wifi_net.lua
$MODULES_AHSM_DIR/test.lua
$TEST_DIR/test_color_display.lua
$TEST_DIR/test_laser_ring.lua
$TEST_DIR/test_omni.lua
$TEST_DIR/test_wifi.lua
$TEST_DIR/test_ahsm.lua
$TEST_DIR/test_color.lua
$TEST_DIR/test_led_ring.lua
$TEST_DIR/test_proximity.lua
)

# Array of destination files
declare -a REMOTE_FILES=(
ahsm.lua
debug_plain.lua
autorun.lua
cb_list.lua
color.lua
laser_ring.lua
led_ring.lua
main_ahsm.lua
omni.lua
proximity.lua
robot.lua
wifi_net.lua
states/test.lua
test_color_display.lua
test_laser_ring.lua
test_omni.lua
test_wifi.lua
test_ahsm.lua
test_color.lua
test_led_ring.lua
test_proximity.lua
)


# Check if the number of source and destination files are the same
if [ ${#LOCAL_FILES[@]} -ne ${#REMOTE_FILES[@]} ]; then
	echo; echo THE NUMBER OF SOURCE AND DESTINATION FILES DOES NOT MATCH; echo
	exit 1
fi

LENGTH=${#LOCAL_FILES[@]}
LENGTH=$((--LENGTH))


if [ ! -f $TMP_FILE ]; then

	echo;echo;echo FIRST TIME. ALL FILES WILL BE COPIED; echo;echo

	for i in `seq 0 $LENGTH`; do
		echo Copying ${LOCAL_FILES[$i]} ........
		wcc -p /dev/ttyUSB0 -up ${LOCAL_FILES[$i]} ${REMOTE_FILES[$i]}
		echo; echo
	done

else

	for i in `seq 0 $LENGTH`; do

		if [ ${LOCAL_FILES[$i]} -nt $TMP_FILE ]; then

			echo
			echo FILE ${LOCAL_FILES[$i]} WAS MODIFIED SINCE LAST RUN OF THIS SCRIPT, IT WILL BE COPIED
			wcc -p /dev/ttyUSB0 -up ${LOCAL_FILES[$i]} ${REMOTE_FILES[$i]}
			echo

		fi
	done
	
fi

touch $TMP_FILE

echo Modules Updated
