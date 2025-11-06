# Move the bitstream to the project root folder, and rename it to the project name
# (Vivado names the bitstream after the top module, not the project name.)
# We assume the script is run from the implementation folder, which is 2 levels down from the project folder.
# We also assume that the project name is the same as the project folder name.
# This script is meant to be run as a -post script for the generate_bitsteam command.
# It seems that [current_project] is a temporary project, not the original one, so we cant use its name and path properties.
# Newer versions of Vivado might have parent_project and parent_project_path properties.
set proj_dir [file normalize "../../"]
# set proj_name [get_property parent_project_name [current_project]]
set proj_name [file tail $proj_dir]
set top_name [get_property top [current_fileset]]
set current_folder [pwd]
puts "Moving bitstream from $current_folder/${top_name}.bit to ${proj_dir}/${proj_name}.bit"
file rename -force "${top_name}.bit" "${proj_dir}/${proj_name}.bit"
