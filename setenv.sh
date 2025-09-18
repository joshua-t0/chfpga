#!/usr/bin/env -S echo "Do not invoke this script directly - instead, use source"

if ! command -v locate &> /dev/null
then
	echo "Unable to find the 'locate' tool - please sudo apt-get install plocate or similar."
	return
fi

#
# Look for correct Vivado release
#

if ! SETTINGS=$(locate -l1 Vivado/2022.2/settings64.sh)
then
	echo "ERROR: Failed to locate Vivado 2022.2 environment. If you installed it recently, try 'sudo updatedb'."
	return
fi
source $SETTINGS
