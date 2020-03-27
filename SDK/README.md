SDK Project files
=================

### Depreciation note

Starting with version 2019.2 of the Xilinx tools, the SDK was made part of the Vitis
unified software platform. We are currently migrating our standalone applications
to the Vitis software. Until the migration is completed, the sources in this repository
can still be used with the Xilinx SDK version 2019.1 if so desired. In other words,
the Vivado projects can be built with Vivado 2019.2, then exported to SDK 2019.1. The
export process must be done by Tcl script, because the Vivado 2019.2 GUI Hardware 
Export option generates a .XSA file, while the SDK expects a .HDF file.

To export a Vivado 2019.2 project for SDK 2019.1, first open the project in Vivado
and generate the bitstream. Once the bitstream generation is complete, open the Tcl
console tab in Vivado then copy-and-paste the following Tcl commands:

```
set proj_path [get_property DIRECTORY [current_project]]
set proj_name [get_property NAME [current_project]]
set top_module_name [get_property top [current_fileset]]
set bit_filename [lindex [glob -dir "${proj_path}/${proj_name}.runs/impl_1" *.bit] 0]
set export_dir "${proj_path}/${proj_name}.sdk"
set hwdef_filename "${proj_path}/${proj_name}.runs/impl_1/$top_module_name.hwdef"
set bit_filename "${proj_path}/${proj_name}.runs/impl_1/$top_module_name.bit"
set mmi_filename "${proj_path}/${proj_name}.runs/impl_1/$top_module_name.mmi"
file mkdir $export_dir
write_sysdef -force -hwdef $hwdef_filename -bitfile $bit_filename -meminfo $mmi_filename $export_dir/$top_module_name.hdf
```

Note that the .HDF file is generated regardless of the warning message 
`WARNING: [Common 17-210] 'write_sysdef' is deprecated.`.

Those Tcl commands will create a .sdk directory within the project directory, and then
generate a .hdf file in that directory. The `build-sdk.tcl` script can then be run from
the SDK directory to build the SDK workspace (see the following instructions).

### How to build the SDK workspace

In order to make use of these source files, you must first generate
the Vivado project hardware design (the bitstream) and export the design
to SDK. Check the `Vivado` folder for instructions on doing this from Vivado.

Once the bitstream is generated and exported to SDK, then you can build the
SDK workspace using the provided `build-sdk.tcl` script.

### Scripted build

The SDK directory contains a `build-sdk.tcl` script which can be run to automatically
generate the SDK workspace. Windows users can run the `build-sdk.bat` file which
launches the Tcl script. Linux users must use the following commands to run the build
script:
```
cd <path-to-repo>/SDK
/<path-to-xilinx-tools>/SDK/2019.1/bin/xsdk -batch -source build-sdk.tcl
```

The build script does three things:
1. Generates a lwIP Echo Server example application for each exported Vivado design
that is found in the ../Vivado directory. Most users will only have one exported
Vivado design.
2. Modifies the "main.c" source file from the application.
3. Copies the sources from the "common/src" directory into the application.

### Run the application

1. Open Xilinx SDK.
2. Power up your hardware platform and ensure that the JTAG is
connected properly.
3. Select Xilinx Tools->Program FPGA. You only have to do this
once, each time you power up your hardware platform.
4. Select Run->Run to run your application. You can modify the code
and click Run as many times as you like, without going through
the other steps.

### lwIP Echo Server

The lwIP echo server application is used here to simplify testing the design. We run the
echo server on the carrier board's onboard Ethernet port, which allows
us to use only one PC to send and receive packets over the "tapped" link. To test
this application, you must make the following connections:

* Carrier board's on-board Ethernet connector to PORT1 of the Ethernet FMC
* PORT0 of the Ethernet FMC to your PC's Ethernet port or a network router

Now when the application is running, you will be able to send packets from your PC
through PORT0, out of PORT1, into the carrier board's Ethernet port, from which point they
will be echoed by the echo server and come back through the same path to your PC.

