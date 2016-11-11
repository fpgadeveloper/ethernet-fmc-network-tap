#!/usr/bin/tclsh

# Description
# -----------
# This Tcl script will create an SDK workspace with software applications for each of the
# exported hardware designs in the ../Vivado directory.

# Test applications
# ------------------------
# This script will then look into the ../Vivado directory and search for exported hardware designs
# (.hdf files within Vivado projects). For each exported hardware design, the script will generate
# the Echo Server software application. It will then modify the "main.c" source file from the
# application and copy the sources from the common/src directory.

# Recursive copy function
# Note: Does not overwrite existing files, thus our modified files are untouched.
proc copy-r {{dir .} target_dir} {
  foreach i [lsort [glob -nocomplain -dir $dir *]] {
    # Get the name of the file or directory
    set name [lindex [split $i /] end]
    if {[file type $i] eq {directory}} {
      # If doesn't exist in target, then create it
      set target_subdir ${target_dir}/$name
      if {[file exists $target_subdir] == 0} {
        file mkdir $target_subdir
      }
      # Copy all files contained in this subdirectory
      eval [copy-r $i $target_subdir]
    } else {
      # Copy the file if it doesn't already exist
      if {[file exists ${target_dir}/$name] == 0} {
        file copy $i $target_dir
      }
    }
  }
} ;# RS

# Add a hardware design to the SDK workspace
proc add_hw_to_sdk {vivado_folder} {
  set hdf_filename [lindex [glob -dir ../Vivado/$vivado_folder/$vivado_folder.sdk *.hdf] 0]
  set hdf_filename_only [lindex [split $hdf_filename /] end]
  set top_module_name [lindex [split $hdf_filename_only .] 0]
  set hw_project_name ${top_module_name}_hw_platform_0
  # If the hw project does not already exist in the SDK workspace, then create it
  if {[file exists "$hw_project_name"] == 0} {
    createhw -name ${hw_project_name} -hwspec $hdf_filename
  }
  return $hw_project_name
}

# Get the first processor name from a hardware design
# We use the "getperipherals" command to get the name of the processor that
# in the design. Below is an example of the output of "getperipherals":
# ================================================================================
# 
#               IP INSTANCE   VERSION                   TYPE           IP TYPE
# ================================================================================
# 
#            axi_ethernet_0       7.0           axi_ethernet        PERIPHERAL
#       axi_ethernet_0_fifo       4.1          axi_fifo_mm_s        PERIPHERAL
#           gmii_to_rgmii_0       4.0          gmii_to_rgmii        PERIPHERAL
#      processing_system7_0       5.5     processing_system7
#          ps7_0_axi_periph       2.1       axi_interconnect               BUS
#              ref_clk_fsel       1.1             xlconstant        PERIPHERAL
#                ref_clk_oe       1.1             xlconstant        PERIPHERAL
#                 ps7_pmu_0    1.00.a                ps7_pmu        PERIPHERAL
#                ps7_qspi_0    1.00.a               ps7_qspi        PERIPHERAL
#         ps7_qspi_linear_0    1.00.a        ps7_qspi_linear      MEMORY_CNTLR
#    ps7_axi_interconnect_0    1.00.a   ps7_axi_interconnect               BUS
#            ps7_cortexa9_0       5.2           ps7_cortexa9         PROCESSOR
#            ps7_cortexa9_1       5.2           ps7_cortexa9         PROCESSOR
#                 ps7_ddr_0    1.00.a                ps7_ddr      MEMORY_CNTLR
#            ps7_ethernet_0    1.00.a           ps7_ethernet        PERIPHERAL
#            ps7_ethernet_1    1.00.a           ps7_ethernet        PERIPHERAL
#                 ps7_usb_0    1.00.a                ps7_usb        PERIPHERAL
#                  ps7_sd_0    1.00.a               ps7_sdio        PERIPHERAL
#                  ps7_sd_1    1.00.a               ps7_sdio        PERIPHERAL
proc get_processor_name {hw_project_name} {
  set periphs [getperipherals $hw_project_name]
  # For each line of the peripherals table
  foreach line [split $periphs "\n"] {
    set values [regexp -all -inline {\S+} $line]
    # If the last column is "PROCESSOR", then get the "IP INSTANCE" name (1st col)
    if {[lindex $values end] == "PROCESSOR"} {
      return [lindex $values 0]
    }
  }
  return ""
}

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
    puts $fp $line
    # Add the include statement
    if {[string first "#include \"xparameters.h\"" $line] >= 0} {
      puts $fp "#include \"nettap.h\""
    }
    # Add the function call
    if {[string first "print_ip_settings(&" $line] >= 0} {
      puts $fp "  nettap_init();"
    }
  }
  close $fp
}

# Creates SDK workspace for a project
proc create_sdk_ws {} {
  # First make sure there is at least one exported Vivado project
  set exported_projects 0
  foreach {vivado_proj} [glob -type d "../Vivado/*"] {
    # Use only the vivado folder name
    set vivado_folder [lindex [split $vivado_proj /] end]
    # If the hardware has been exported for SDK
    if {[file exists "../Vivado/$vivado_folder/${vivado_folder}.sdk"] == 1} {
      set exported_projects [expr {$exported_projects+1}]
    }
  }
  
  # If no projects then exit
  if {$exported_projects == 0} {
    puts "### There are no exported Vivado projects in the ../Vivado directory ###"
    puts "You must build and export a Vivado project before building the SDK workspace."
    exit
  }

  puts "There were $exported_projects exported project(s) found in the ../Vivado directory."
  puts "Creating SDK workspace."
  
  # Set the workspace directory
  setws [pwd]
  
  # Get list of Vivado projects (hardware designs) and add them to SDK workspace
  foreach {vivado_proj} [glob -type d "../Vivado/*"] {
    # Get the vivado folder name
    set vivado_folder [lindex [split $vivado_proj /] end]
    # Get the name of the board
    set board_name [string map {_network_tap ""} $vivado_folder]
    # If the application has already been created, then skip
    if {[file exists "${board_name}_echo_server"] == 1} {
      puts "Application already exists for Vivado project $vivado_folder."
    # If the hardware has been exported for SDK, then create an application for it
    } elseif {[file exists "../Vivado/$vivado_folder/${vivado_folder}.sdk"] == 1} {
      puts "Creating application for Vivado project $vivado_folder."
      set hw_project_name [add_hw_to_sdk $vivado_folder]
      # Generate the echo server example application
      createapp -name ${board_name}_echo_server \
        -app {lwIP Echo Server} \
        -proc [get_processor_name $hw_project_name] \
        -hwproject ${hw_project_name} \
        -os standalone
      # Copy common sources into the application
      copy-r "common/src" "${board_name}_echo_server/src"
      # Modify the "main.c" file
      modify_echo_server ${board_name}_echo_server
    } else {
      puts "Vivado project $vivado_folder not exported."
    }
  }

  # Build all
  puts "Building all."
  projects -build
}

# Create the SDK workspace
puts "Creating the SDK workspace"
create_sdk_ws

exit
