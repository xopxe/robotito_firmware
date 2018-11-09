#!/bin/bash

# File updated after each run of this script.
# Only the files newer than this file are copied to de destination
TMP_FILE=lastrun

# Information about origin files and dirs
MODULES_DIR="arquitectura/modules"
MODULES_AHSM_DIR="arquitectura"
WORK_DIR="arquitectura/work"
UTILS_DIR="utils"
AHSM_DIR="../ahsm"

# Array of source files
declare -a LOCAL_FILES=(
$AHSM_DIR/ahsm.lua
$WORK_DIR/cb_list.lua
$WORK_DIR/laser_ring.lua
$WORK_DIR/led_ring.lua
$WORK_DIR/run.lua
$WORK_DIR/omni.lua
$WORK_DIR/robot.lua
$WORK_DIR/fsm_on_off.lua
$WORK_DIR/apds.lua
$UTILS_DIR/autorun.lua
)

# Array of destination files
declare -a REMOTE_FILES=(
ahsm.lua
cb_list.lua
laser_ring.lua
led_ring.lua
main.lua
omni.lua
robot.lua
fsm_on_off.lua
apds.lua
autorun.lua
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
