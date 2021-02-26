#!/usr/bin/tclsh

# Description
# -----------
# This Tcl script will create Vitis workspace with software applications for each of the
# exported hardware designs in the ../Vivado directory.

# Set the Vivado directories containing the Vivado projects
set vivado_dirs_rel [list "../Vivado"]
set vivado_dirs {}
foreach d $vivado_dirs_rel {
  set d_abs [file join [pwd] $d]
  append vivado_dirs [file normalize $d_abs] " "
}

# Set the application postfix
# Applications will be named using the app_postfix appended to the board name
set app_postfix "_echo_server"

# Specify the postfix on the Vivado projects so that the workspace builder can find them
set vivado_postfix "_net_tap"

# Set the app template used to create the application
set support_app "lwip_echo_server"
set template_app "lwIP Echo Server"

# Microblaze designs: Generate combined .bit and .elf file
set mb_combine_bit_elf 0

# Modify the "main.c" file of the echo server app
proc modify_echo_server {app_name} {
  puts "Modifying $app_name"
  # Open the file for reading
  set fp [open "$app_name/src/main.c" r]
  set file_data [read $fp]
  close $fp
  # Open the same file for writing
  set fp [open "$app_name/src/main.c" w]
  # Process data file
  set data [split $file_data "\n"]
  foreach line $data {
    # Write the file back with additional lines
    # and replace PLATFORM_EMAC_BASEADDR with GEM_FOR_LWIP
    set rep_line [string map {PLATFORM_EMAC_BASEADDR "GEM_FOR_LWIP"} $line]
    puts $fp $rep_line
    # Add the include statement
    if {[string first "#include \"xparameters.h\"" $line] >= 0} {
      puts $fp "#include \"nettap.h\""
    }
    # Add the function call
    if {[string first "init_platform(" $line] >= 0} {
      puts $fp "  nettap_init();"
    }
  }
  close $fp
}

# ----------------------------------------------------------------------------------------------
# Custom modifications functions
# ----------------------------------------------------------------------------------------------
# Use these functions to make custom changes to the platform or standard application template 
# such as modifying files or copying sources into the platform/application.
# These functions are called after creating the platform/application and before build.

proc custom_platform_mods {platform_name} {
  # No platform mods required
}

proc custom_app_mods {platform_name app_name} {
  # Copy common sources into the application
  copy-r "common/src" "${app_name}/src"
  modify_echo_server $app_name
}

# Call the workspace builder script
source tcl/workspace.tcl

