#!/usr/bin/tclsh

# Description
# -----------
# This Tcl script will create Vitis workspace with software applications for each of the
# exported hardware designs in the ../Vivado directory.

# Test applications
# ------------------------
# This script will then look into the ../Vivado directory and search for exported hardware designs
# (.xsa files within Vivado projects). For each exported hardware design, the script will generate
# the Echo Server software application. It will then modify the "main.c" source file from the
# application and copy the sources from the common/src directory.

# Set the Vivado directories containing the Vivado projects
set vivado_dirs {"../Vivado"}
# Set the application postfix
set app_postfix "_echo_server"

# Returns true if str contains substr
proc str_contains {str substr} {
  if {[string first $substr $str] == -1} {
    return 0
  } else {
    return 1
  }
}

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

# Creates the board.h file that defines the board name
proc create_board_h {board_name target_dir} {
  # Xilinx Vitis install directory to get the version number
  set vitis_dir $::env(XILINX_VITIS)
  set vitis_ver [lindex [file split $vitis_dir] end]
  # Create the file
  set fd [open "${target_dir}/board.h" "w"]
  puts $fd "/* This file is automatically generated */"
  puts $fd "#ifndef BOARD_H_"
  puts $fd "#define BOARD_H_"
  puts $fd "#define BOARD_NAME \"[string toupper $board_name]\""
  puts $fd "#define VITIS_VERSION \"$vitis_ver\""
  puts $fd "#define BOARD_[string toupper $board_name] 1"
  puts $fd "#endif"
  close $fd
}

# Returns list of Vivado projects in the given directory
proc get_vivado_projects {vivado_dir} {
  # Create the empty list
  set vivado_proj_list {}
  # Make a list of all subdirectories in Vivado directory
  foreach {vivado_proj_dir} [glob -type d "${vivado_dir}/*"] {
    # Get the vivado project name from the project directory name
    set vivado_proj [lindex [split $vivado_proj_dir /] end]
    # Ignore directories returned by glob that don't contain an underscore
    if { ([string first "_" $vivado_proj] == -1) } {
      continue
    }
    # Add the Vivado project to the list
    lappend vivado_proj_list $vivado_proj
  }
  return $vivado_proj_list
}

# Creates Vitis workspace for a project
proc create_vitis_ws {vivado_dirs} {
  global app_postfix
  # First make sure there is at least one exported Vivado project
  set exported_projects 0
  set xsa_files {}
  # For each of the Vivado dirs
  foreach {vivado_dir} $vivado_dirs {
    # Check each Vivado project for export files
    foreach {vivado_folder} [get_vivado_projects $vivado_dir] {
      # If the hardware has been exported for Vitis
      if {[file exists "$vivado_dir/$vivado_folder/${vivado_folder}_wrapper.xsa"] == 1} {
        set exported_projects [expr {$exported_projects+1}]
        lappend xsa_files "$vivado_dir/$vivado_folder/${vivado_folder}_wrapper.xsa"
        puts "Exported here: $vivado_dir/$vivado_folder/${vivado_folder}_wrapper.xsa"
      }
    }
  }
  
  # If no projects then exit
  if {$exported_projects == 0} {
    puts "### There are no exported Vivado projects ###"
    puts "You must build and export a Vivado project before building the Vitis workspace."
    exit
  }

  puts "There were $exported_projects exported project(s) found."
  puts "Creating Vitis workspace."
  
  # Create "boot" directory if it doesn't already exist
  if {[file exists "./boot"] == 0} {
    file mkdir "./boot"
  }
  
  # Set the workspace directory
  set vitis_dir [pwd]
  setws $vitis_dir
  
  # Add each exported Vivado project to Vitis workspace
  foreach {xsa_file} $xsa_files {
    # Get the name of the board
    set board_name [string map {_net_tap ""} [lindex [split $xsa_file "/"] end-1]]
    set xsa_filename_only [lindex [split $xsa_file /] end]
    set hw_project_name [lindex [split $xsa_filename_only .] 0]
    # Create the application name
    set app_name "${board_name}$app_postfix"
    # If the application has already been created, then skip
    if {[file exists "$app_name"] == 1} {
      puts "Application already exists for Vivado project $app_name."
      continue
    }
    # Create the platform for this Vivado project
    puts "Creating Platform for $xsa_filename_only."
    platform create -name ${hw_project_name} -hw ${xsa_file}
    platform write
    set proc_instance [get_processor_name ${xsa_file}]
    # Microblaze and Zynq ARM are 32-bit, ZynqMP ARM are 64-bit processors
    if {[str_contains $proc_instance "psu_cortex"]} {
      set arch_bit "64-bit"
    } else {
      set arch_bit "32-bit"
    }
    # Create a standalone domain
    domain create -name {standalone_domain} \
      -display-name "standalone on $proc_instance" \
      -os {standalone} \
      -proc $proc_instance \
      -runtime {cpp} \
      -arch $arch_bit \
      -support-app {lwip_echo_server}
    platform write
    platform active ${hw_project_name}
    # Enable the FSBL for Zynq
    if {[str_contains $proc_instance "ps7_cortex"]} {
      domain active {zynq_fsbl}
    # Enable the FSBL for ZynqMP
    } elseif {[str_contains $proc_instance "psu_cortex"]} {
      domain active {zynqmp_fsbl}
    }
    domain active {standalone_domain}
    platform generate
    # Generate the example application
    puts "Creating application $app_name."
    app create -name $app_name \
      -template {lwIP Echo Server} \
      -platform ${hw_project_name} \
      -domain {standalone_domain}
    # Copy common sources into the application
    copy-r "common/src" "${app_name}/src"
    # Modify the "main.c" file
    modify_echo_server ${app_name}
    # Create the board.h file
    set underscore_index [string first "_" $board_name]
    if {$underscore_index == -1} {
      set board_name_only $board_name
    } else {
      set board_name_only [string replace $board_name $underscore_index end ""]
    }
    create_board_h $board_name_only "${app_name}/src"
    # Build the application
    puts "Building application $app_name."
    app build -name $app_name
    puts "Building system ${app_name}_system."
    sysproj build -name ${app_name}_system
    
    # Create or copy the boot file
    # Make sure the application has been compiled
    if {[file exists "./${app_name}/Debug/${app_name}.elf"] == 0} {
      puts "Application ${app_name} FAILED to compile."
      continue
    }
    
    # If all required files exist, then generate boot files
    # Create directory for the boot file if it doesn't already exist
    if {[file exists "./boot/$board_name"] == 0} {
      file mkdir "./boot/$board_name"
    }
	
    # For Microblaze designs
    if {[str_contains $proc_instance "microblaze"]} {
      puts "No boot file will be generated for Microblaze designs."
    # For Zynq and Zynq MP designs
    } else {
      puts "Copying the BOOT.BIN file to the ./boot/${board_name} directory."
      # Copy the already generated BOOT.bin file
      set bootbin_file "./${app_name}_system/Debug/sd_card/BOOT.bin"
      if {[file exists $bootbin_file] == 1} {
        file copy -force $bootbin_file "./boot/${board_name}"
      } else {
        puts "No BOOT.bin file for ${app_name}."
      }
    }
  }
}
  
# Checks all applications
proc check_apps {} {
  global app_postfix
  # Set the workspace directory
  setws [pwd]
  puts "Checking build status of all applications:"
  # Get list of applications
  foreach {app_dir} [glob -type d "./*$app_postfix"] {
    # Get the app name
    set app_name [lindex [split $app_dir /] end]
    if {[file exists "$app_dir/Debug/${app_name}.elf"] == 1} {
      puts "  ${app_name} was built successfully"
    } else {
      puts "  ERROR: ${app_name} failed to build"
    }
  }
}
  

# Create the Vitis workspace
puts "Creating the Vitis workspace"
create_vitis_ws $vivado_dirs
check_apps

exit
