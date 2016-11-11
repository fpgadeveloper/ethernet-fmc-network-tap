SDK Project files
=================

### How to build the SDK workspace

In order to make use of these source files, you must first generate
the Vivado project hardware design (the bitstream) and export the design
to SDK. Check the `Vivado` folder for instructions on doing this from Vivado.

Once the bitstream is generated and exported to SDK, then you can build the
SDK workspace using the provided `build-sdk.tcl` script.

### Scripted build

The SDK directory contains a `build-sdk.tcl` script which can be run to automatically
generate the SDK workspace. Windows users can run the `build-sdk.bat` file which
launches the Tcl script.

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
echo server on the ZedBoard's onboard Ethernet port (connected to GEM0), which allows
us to use only one PC to send and receive packets over the "tapped" link. To test
this application, you must make the following connections:

* ZedBoard's on-board Ethernet connector to PORT1 of the Ethernet FMC
* PORT0 of the Ethernet FMC to your PC's Ethernet port

Now when the application is running, you will be able to send packets from your PC
through PORT0, out of PORT1, into the ZedBoard's Ethernet port, from which point they
will be echoed by the echo server and come back through the same path to your PC.
