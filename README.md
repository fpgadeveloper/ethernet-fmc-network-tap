ethernet-fmc-network-tap
========================

Hackable FPGA based network tap that uses the [Quad Gigabit Ethernet FMC](http://ethernetfmc.com "Ethernet FMC").

## Requirements

This project is designed for version 2019.2 of the Xilinx tools (Vivado/Vitis/PetaLinux). If you are using an older version of the 
Xilinx tools, then refer to the [release tags](https://github.com/fpgadeveloper/ethernet-fmc-network-tap/releases "releases")
to find the version of this repository that matches your version of the tools.

* Vivado 2019.2
* Vitis 2019.2
* [Ethernet FMC](http://ethernetfmc.com "Ethernet FMC")
* One of the below listed evaluation boards

## Supported boards

* Zynq-7000 [ZedBoard](http://zedboard.org "ZedBoard")
  * LPC connector
* Zynq UltraScale+ [ZCU102 Evaluation board](http://www.xilinx.com/products/silicon-devices/soc/zynq-ultrascale-mpsoc.html "ZCU102 Evaluation board")
  * HPC0 connector

## Description

This project will implement an FPGA based network tap which could be used to "listen" to the communications passing over
an Ethernet cable. It is a work that is still under development.

![Block diagram](http://www.fpgadeveloper.com/wp-content/uploads/2015/12/fpga_network_tap_4.jpg "FPGA Network Tap")

The design in it's present state implements a pass-through between PORT0 and PORT1 of the Ethernet FMC.
The pass-through is fully functional and can be tested by connecting ports 0 and 1 to separate Ethernet
devices.

## Build instructions

To use the sources in this repository, please follow these steps:

### Windows users

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
7. Return to Windows Explorer and browse to the Vitis directory in the repo.
8. Double click the `build-vitis.bat` batch file. The batch file will run the
   `build-vitis.tcl` script and build the Vitis workspace containing the hardware
   design and the software application.
9. Run Xilinx Vitis and select the workspace to be the Vitis directory of the repo.
10. Connect and power up the hardware.
11. Open a Putty terminal to view the UART output.
12. In Vitis, select `Xilinx Tools->Program FPGA`.
13. Right-click on the application and select `Run As->Launch on Hardware (Single Application Debug)`

### Linux users

1. Download the repo as a zip file and extract the files to a directory
   on your hard drive --OR-- Git users: clone the repo to your hard drive
2. Launch the Vivado GUI.
3. Open the Tcl console from the Vivado welcome page. In the console, `cd` to the repo files
   on your hard drive and into the Vivado subdirectory. For example: `cd /media/projects/ethernet-fmc-network-tap/Vivado`.
3. In the Vivado subdirectory, you will find multiple Tcl files. To list them, type `exec ls {*}[glob *.tcl]`.
   Determine the Tcl script for the example project that you would like to generate (for example: `build-zedboard.tcl`), 
   then `source` the script in the Tcl console: For example: `source build-zedboard.tcl`
4. Vivado will run the script and generate the project. When it's finished, click Generate bitstream.
5. When the bitstream is successfully generated, select `File->Export->Export Hardware`.
   In the window that opens, tick "Include bitstream" and "Local to project".
6. To build the Vitis workspace, open a Linux command terminal and `cd` to the Vitis directory in the repo.
7. The Vitis directory contains the `build-vitis.tcl` script that will build the Vitis workspace containing the hardware design and
   the software application. Run the build script by typing the following command: 
   `<path-of-xilinx-vitis>/bin/xsct build-vitis.tcl`. Note that you must replace `<path-of-xilinx-vitis>` with the 
   actual path to your Xilinx Vitis installation.
8. Run Xilinx Vitis and select the workspace to be the Vitis subdirectory of the 
   repo.
9. Connect and power up the hardware.
10. Open a Putty terminal to view the UART output.
11. In Vitis, select `Xilinx Tools->Program FPGA`.
12. Right-click on the application and select `Run As->Launch on Hardware (Single Application Debug)`

## Tutorials

The following tutorials explain the workings of the network tap:

* [FPGA Network Tap: Designing the Ethernet pass through](http://www.fpgadeveloper.com/2015/12/fpga-network-tap-designing-ethernet-pass-through.html "FPGA Network Tap: Designing the Ethernet pass through")

## lwIP Echo Server

The lwIP echo server application is used here to simplify testing the design. We run the
echo server on the carrier board's onboard Ethernet port, which allows
us to use only one PC to send and receive packets over the "tapped" link. To test
this application, you must make the following connections:

* Carrier board's on-board Ethernet connector to PORT1 of the Ethernet FMC
* PORT0 of the Ethernet FMC to your PC's Ethernet port or a network router

Now when the application is running, you will be able to send packets from your PC
through PORT0, out of PORT1, into the carrier board's Ethernet port, from which point they
will be echoed by the echo server and come back through the same path to your PC.

## Troubleshooting

Check the following if the project fails to build or generate a bitstream:

### 1. Are you using the correct version of Vivado for this version of the repository?
Check the version specified in the Requirements section of this readme file. Note that this project is regularly maintained to the latest
version of Vivado and you may have to refer to an earlier commit of this repo if you are using an older version of Vivado.

### 2. Did you follow the Build instructions in this readme file?
All the projects in the repo are built, synthesised and implemented to a bitstream before being committed, so if you follow the
instructions, there should not be any build issues.

### 3. Did you copy/clone the repo into a short directory structure?
Vivado doesn't cope well with long directory structures, so copy/clone the repo into a short directory structure such as
`C:\projects\`. When working in long directory structures, you can get errors relating to missing files, particularly files 
that are normally generated by Vivado (FIFOs, etc).

## Contribute

We encourage contribution to these projects. If you spot issues or you want to add designs for other platforms, please
make a pull request.

## About us

This project was developed by [Opsero Inc.](http://opsero.com "Opsero Inc."),
a tight-knit team of FPGA experts delivering FPGA products and design services to start-ups and tech companies. 
Follow our blog, [FPGA Developer](http://www.fpgadeveloper.com "FPGA Developer"), for news, tutorials and
updates on the awesome projects we work on.