# Move the bitstream to the project root folder, and rename it to the project name
# (Vivado names the bitstream after the top module, not the project name.)
# We assume the script is run from the implementation folder
# This script is meant to be run as a -post script for the generate_bitsteam command.
set proj_name [get_property NAME [current_project]]
set proj_dir [get_property DIRECTORY [current_project]]
set top_name [get_property top [current_fileset]]
set current_folder [pwd]

file rename -force "${top_name}.bit" "${proj_dir}/${proj_name}.bit"
puts "Moved bitstream from $current_folder/${top_name}.bit to ${proj_dir}/${proj_name}.bit"