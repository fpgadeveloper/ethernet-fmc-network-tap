ethernet-fmc-network-tap
========================

Hackable FPGA based network tap based on the [ZedBoard](http://zedboard.org "ZedBoard") and the [Quad Gigabit Ethernet FMC](http://ethernetfmc.com "Ethernet FMC").

### Supported boards

* Zynq-7000 [ZedBoard](http://zedboard.org "ZedBoard")
  * LPC connector (use zedboard.xdc)

### Description

This project will implement an FPGA based network tap which could be used to "listen" to the communications passing over
an Ethernet cable. It is a work that is still under development.

![Block diagram](http://www.fpgadeveloper.com/wp-content/uploads/2015/12/fpga_network_tap_4.jpg "FPGA Network Tap")

The design in it's present state implements a pass-through between PORT0 and PORT1 of the Ethernet FMC.
The pass-through is fully functional and can be tested by connecting ports 0 and 1 to separate Ethernet
devices.

### Requirements

* Vivado 2016.4
* [Ethernet FMC](http://ethernetfmc.com "Ethernet FMC")
* One of the above listed evaluation boards

### Build instructions

To use the sources in this repository, please follow these steps:

1. Download the repo as a zip file and extract the files to a directory
   on your hard drive --OR-- Git users: clone the repo to your hard drive
2. Open Windows Explorer, browse to the repo files on your hard drive.
3. In the Vivado directory, you will find multiple batch files (*.bat).
   Double click on the batch file that is appropriate to your hardware,
   for example, double-click `build-zedboard.bat` if you are using the ZedBoard.
   This will generate a Vivado project for your hardware platform.
4. Run Vivado and open the project that was just created.
5. Click Generate bitstream.
6. When the bitstream is successfully generated, select `File->Export->Export Hardware`.
   In the window that opens, tick "Include bitstream" and "Local to project".
7. Return to Windows Explorer and browse to the SDK directory in the repo.
8. Double click the `build-sdk.bat` batch file. The batch file will run the
   `build-sdk.tcl` script and build the SDK workspace containing the hardware
   design and the software application.
9. Run Xilinx SDK (DO NOT use the Launch SDK option from Vivado) and select the workspace to be the SDK directory of the repo.
10. Select `Project->Build automatically`.
11. Connect and power up the hardware.
12. Open a Putty terminal to view the UART output.
13. In the SDK, select `Xilinx Tools->Program FPGA`.
14. Right-click on the application and select `Run As->Launch on Hardware (System Debugger)`

### Tutorials

The following tutorials explain the workings of the network tap:

* [FPGA Network Tap: Designing the Ethernet pass through](http://www.fpgadeveloper.com/2015/12/fpga-network-tap-designing-ethernet-pass-through.html "FPGA Network Tap: Designing the Ethernet pass through")

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

### License

Feel free to modify the code for your specific application.

### About us

This project was developed by [Opsero Inc.](http://opsero.com "Opsero Inc."),
a tight-knit team of FPGA experts delivering FPGA products and design services to start-ups and tech companies. 
Follow our blog, [FPGA Developer](http://www.fpgadeveloper.com "FPGA Developer"), for news, tutorials and
updates on the awesome projects we work on.